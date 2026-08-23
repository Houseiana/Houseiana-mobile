import 'package:dio/dio.dart';
import 'package:houseiana_mobile_app/core/constants/errors/exceptions.dart';
import 'package:houseiana_mobile_app/core/network/api/backend_dio.dart';

/// Service for property ratings and reviews.
/// Handles submitting and fetching property reviews.
class RatingsService {
  final Dio _dio;

  RatingsService({Dio? dio}) : _dio = dio ?? buildBackendDio();

  /// GET /api/ratings/property/{propertyId}
  /// Fetches all reviews for a property.
  Future<List<Map<String, dynamic>>> getPropertyRatings(
    String propertyId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/api/ratings/property/$propertyId',
        queryParameters: {'page': page, 'limit': limit},
      );
      return _list(response.data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// GET /api/ratings/property/{propertyId}/summary
  /// Fetches rating summary (average, count per star).
  Future<Map<String, dynamic>?> getRatingSummary(String propertyId) async {
    try {
      final response = await _dio.get('/api/ratings/property/$propertyId/summary');
      return response.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// POST /api/ratings/property-by-guest
  ///
  /// Body is `AddPropertyRatingDto`, and it is stricter than it looks:
  /// * the key is **`guestId`**, not `userId`;
  /// * **`rating` is an `int` 1–5**. Sending the UI's `double` made the API
  ///   answer 400 "The JSON value could not be converted to System.Int32" on
  ///   every single submission — which is why no review ever went through;
  /// * there is **no `bookingId`** and no `categories` array. A review attaches
  ///   to the property, and the six category scores are their own named fields.
  Future<Map<String, dynamic>> submitReview({
    required String guestId,
    required String propertyId,
    required int rating,
    required String comment,
    double? cleanliness,
    double? accuracy,
    double? checkIn,
    double? communication,
    double? location,
    double? value,
  }) async {
    try {
      final response = await _dio.post(
        '/api/ratings/property-by-guest',
        data: {
          'guestId': guestId,
          'propertyId': propertyId,
          // Clamped, not just rounded: the DTO rejects anything outside 1–5.
          'rating': rating.clamp(1, 5),
          'comment': comment,
          if (cleanliness != null) 'cleanliness': cleanliness,
          if (accuracy != null) 'accuracy': accuracy,
          if (checkIn != null) 'checkIn': checkIn,
          if (communication != null) 'communication': communication,
          if (location != null) 'location': location,
          if (value != null) 'value': value,
        },
      );

      final data = response.data;
      if (data['success'] == true || data['reviewId'] != null) {
        return {
          'success': true,
          'message': 'Review submitted successfully',
          'reviewId': data['reviewId']?.toString(),
        };
      }
      // A 200 that still reports success:false gets the same enrichment as the
      // throwing path, so the guest never sees the bare generic line.
      return {'success': false, 'message': _reviewErrorMessage(data)};
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// DELETE /api/ratings/{reviewId}
  /// Deletes a review (only by the author).
  Future<bool> deleteReview(String reviewId) async {
    try {
      await _dio.delete('/api/ratings/$reviewId');
      return true;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _list(dynamic data) {
    if (data == null) return [];
    dynamic raw = data;
    if (raw is Map) raw = raw['data'] ?? raw['items'] ?? raw['reviews'] ?? raw;
    if (raw is List) return raw.whereType<Map<String, dynamic>>().toList();
    return [];
  }

  ServerException _mapError(DioException e) {
    String message = 'Rating error';
    if (e.response != null) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        message = data['message']?.toString() ??
            data['error']?.toString() ??
            'Rating error';
      }
    } else {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
          message = 'Connection timed out';
          break;
        case DioExceptionType.connectionError:
          message = 'No internet connection';
          break;
        default:
          message = e.message ?? 'Rating error';
      }
    }
    return ServerException.msg(message);
  }

  Map<String, dynamic> _handleError(DioException e) =>
      {'success': false, 'message': _reviewErrorMessage(e.response?.data)};

  /// Human reason for a rejected review.
  ///
  /// A validation failure puts the useful part in `errors`; `message` on its own
  /// is only ever "One or more fields are invalid.", which tells the guest
  /// nothing about what to change.
  String _reviewErrorMessage(dynamic data) {
    const fallback = 'Failed to submit review';
    if (data is! Map) return fallback;
    var message = data['message']?.toString() ?? fallback;
    final errors = data['errors'];
    if (errors is List && errors.isNotEmpty) {
      message = '$message ${errors.map((e) => e.toString()).join(' ')}';
    }
    return message;
  }
}
