import 'package:dio/dio.dart';
import 'package:houseiana_mobile_app/core/config/app_config.dart';
import 'package:houseiana_mobile_app/core/constants/errors/exceptions.dart';

/// Service for property ratings and reviews.
/// Handles submitting and fetching property reviews.
class RatingsService {
  final Dio _dio;

  RatingsService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.backendApiUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
            ));

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
  /// Submits a review for a completed booking.
  Future<Map<String, dynamic>> submitReview({
    required String bookingId,
    required String propertyId,
    required String userId,
    required double rating,
    required String comment,
    List<String>? categories,
  }) async {
    try {
      final response = await _dio.post(
        '/api/ratings/property-by-guest',
        data: {
          'bookingId': bookingId,
          'propertyId': propertyId,
          'userId': userId,
          'rating': rating,
          'comment': comment,
          if (categories != null) 'categories': categories,
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
      return {
        'success': false,
        'message': data['message']?.toString() ?? 'Failed to submit review',
      };
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

  Map<String, dynamic> _handleError(DioException e) {
    String message = 'Failed to submit review';
    if (e.response?.data is Map<String, dynamic>) {
      message = e.response?.data['message']?.toString() ?? message;
    }
    return {'success': false, 'message': message};
  }
}
