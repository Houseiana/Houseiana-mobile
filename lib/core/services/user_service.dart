import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/network/api/end_points.dart';

/// Handles all user-related API calls to the backend.
/// Routes: /users/*, /booking-manager/*, /api/chat/conversations
class UserService {
  final ApiConsumer _api;

  UserService(this._api);

  // ── Profile ──────────────────────────────────────────────────────────────

  /// GET /users/{id}
  Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final response = await _api.get(EndPoints.userById(userId));
      return _item(response);
    } catch (_) {
      return null;
    }
  }

  // ── Favorites ────────────────────────────────────────────────────────────

  /// GET /users/{userId}/favorites
  Future<List<Map<String, dynamic>>> getFavorites(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _api.get(
        EndPoints.userFavorites(userId),
        queryParameters: {'page': page, 'limit': limit},
      );
      return _list(response);
    } catch (_) {
      return [];
    }
  }

  /// POST /users/favorites
  /// Body: { "userId": "...", "propertyId": "..." }
  /// The backend toggles — if already favourite it removes it.
  Future<bool> toggleFavorite({
    required String userId,
    required String propertyId,
  }) async {
    try {
      await _api.post(
        EndPoints.favorites,
        body: {'userId': userId, 'propertyId': propertyId},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Trips / Bookings ─────────────────────────────────────────────────────

  /// GET /users/{userId}/user-trips?status={status}
  /// [status] values from backend: UPCOMING, PAST, CANCELLED (optional)
  Future<List<Map<String, dynamic>>> getTrips(
    String userId, {
    String? status,
  }) async {
    try {
      final response = await _api.get(
        EndPoints.userTrips(userId),
        queryParameters: {
          if (status != null) 'status': status,
        },
      );
      return _list(response);
    } catch (_) {
      return [];
    }
  }

  /// GET /booking-manager/{id}
  Future<Map<String, dynamic>?> getBookingDetails(String bookingId) async {
    try {
      final response = await _api.get(EndPoints.bookingById(bookingId));
      return _item(response);
    } catch (_) {
      return null;
    }
  }

  /// POST /booking-manager
  Future<Map<String, dynamic>?> createBooking(
      Map<String, dynamic> body) async {
    try {
      final response = await _api.post(EndPoints.createBooking, body: body);
      return _item(response);
    } catch (_) {
      return null;
    }
  }

  // ── Chat ─────────────────────────────────────────────────────────────────

  /// GET /api/chat/conversations?userId={userId}
  Future<List<Map<String, dynamic>>> getConversations(String userId,
      {int page = 1, int limit = 20}) async {
    try {
      final response = await _api.get(
        EndPoints.conversations,
        queryParameters: {'userId': userId, 'page': page, 'limit': limit},
      );
      return _list(response);
    } catch (_) {
      return [];
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Map<String, dynamic>? _item(dynamic response) {
    if (response == null) return null;
    if (response is Map<String, dynamic>) {
      return (response['data'] as Map<String, dynamic>?) ?? response;
    }
    return null;
  }

  List<Map<String, dynamic>> _list(dynamic response) {
    if (response == null) return [];
    dynamic raw = response;
    if (raw is Map) raw = raw['data'] ?? raw['items'] ?? raw;
    if (raw is Map) {
      raw = raw['items'] ?? raw['data'] ?? raw.values.firstWhere(
        (v) => v is List,
        orElse: () => [],
      );
    }
    if (raw is List) return raw.whereType<Map<String, dynamic>>().toList();
    return [];
  }
}
