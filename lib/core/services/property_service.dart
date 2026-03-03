import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/network/api/end_points.dart';

/// Handles all property-related API calls to the backend.
/// Endpoint base: /api/property-search
class PropertyService {
  final ApiConsumer _api;

  PropertyService(this._api);

  /// Fetch a paginated/filtered list of properties.
  /// [location]  - city / area text filter
  /// [checkIn]   - ISO date string e.g. "2026-03-10"
  /// [checkOut]  - ISO date string e.g. "2026-03-15"
  /// [guests]    - number of guests
  /// [page]      - page number (default 1)
  /// [limit]     - items per page (default 20)
  /// [userId]    - Clerk user ID (used to determine favourited status)
  Future<List<Map<String, dynamic>>> getProperties({
    String? location,
    String? checkIn,
    String? checkOut,
    int? guests,
    int page = 1,
    int limit = 20,
    String? userId,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (location != null && location.isNotEmpty) 'location': location,
      if (checkIn != null) 'checkIn': checkIn,
      if (checkOut != null) 'checkOut': checkOut,
      if (guests != null) 'guests': guests,
      if (userId != null) 'userId': userId,
    };

    try {
      final response = await _api.get(
        EndPoints.propertySearch,
        queryParameters: query,
      );
      return _parseList(response);
    } catch (_) {
      return [];
    }
  }

  /// Fetch full details for a single property.
  Future<Map<String, dynamic>?> getPropertyById(
    String id, {
    String? userId,
    String? checkIn,
    String? checkOut,
  }) async {
    try {
      final response = await _api.get(
        EndPoints.propertyDetails(id),
        queryParameters: {
          if (userId != null) 'userId': userId,
          if (checkIn != null) 'checkIn': checkIn,
          if (checkOut != null) 'checkOut': checkOut,
        },
      );
      return _parseItem(response);
    } catch (_) {
      return null;
    }
  }

  /// Fetch ratings/reviews for a property.
  Future<List<Map<String, dynamic>>> getRatings(String propertyId) async {
    try {
      final response = await _api.get(EndPoints.propertyRatings(propertyId));
      return _parseList(response);
    } catch (_) {
      return [];
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _parseList(dynamic response) {
    if (response == null) return [];

    // Backend wraps results in { "data": [...] } or { "data": { "items": [...] } }
    dynamic raw = response;
    if (raw is Map) {
      raw = raw['data'] ?? raw['items'] ?? raw;
    }
    if (raw is Map) {
      raw = raw['items'] ?? raw['data'] ?? raw.values.firstWhere(
        (v) => v is List,
        orElse: () => [],
      );
    }
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  Map<String, dynamic>? _parseItem(dynamic response) {
    if (response == null) return null;
    if (response is Map<String, dynamic>) {
      return (response['data'] as Map<String, dynamic>?) ?? response;
    }
    return null;
  }
}
