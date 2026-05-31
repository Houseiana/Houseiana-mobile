import 'package:dio/dio.dart';
import 'package:houseiana_mobile_app/core/config/app_config.dart';
import 'package:houseiana_mobile_app/core/constants/errors/exceptions.dart';

/// Service for admin panel operations.
/// Handles admin-only operations like user management, property review, support tickets.
class AdminService {
  final Dio _dio;

  AdminService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.backendApiUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
            ));

  /// GET /api/admin/dashboard
  /// Fetches admin dashboard statistics.
  Future<Map<String, dynamic>?> getDashboardStats() async {
    try {
      final response = await _dio.get('/api/admin/dashboard');
      return response.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// GET /api/admin/users?page={page}&limit={limit}
  /// Fetches paginated list of users.
  Future<List<Map<String, dynamic>>> getUsers({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final response = await _dio.get(
        '/api/admin/users',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null) 'search': search,
        },
      );
      return _list(response.data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// GET /api/admin/properties?page={page}&limit={limit}
  /// Fetches paginated list of properties for review.
  Future<List<Map<String, dynamic>>> getProperties({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final response = await _dio.get(
        '/api/admin/properties',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null) 'status': status,
        },
      );
      return _list(response.data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// POST /api/admin/properties/{propertyId}/approve
  /// Approves a property listing.
  Future<bool> approveProperty(String propertyId) async {
    try {
      await _dio.post('/api/admin/properties/$propertyId/approve');
      return true;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// POST /api/admin/properties/{propertyId}/reject
  /// Rejects a property listing.
  Future<bool> rejectProperty(String propertyId, {String? reason}) async {
    try {
      await _dio.post(
        '/api/admin/properties/$propertyId/reject',
        data: {'reason': reason},
      );
      return true;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// GET /api/admin/support/tickets?page={page}&limit={limit}
  /// Fetches support tickets.
  Future<List<Map<String, dynamic>>> getSupportTickets({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final response = await _dio.get(
        '/api/admin/support/tickets',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null) 'status': status,
        },
      );
      return _list(response.data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// POST /api/admin/support/tickets/{ticketId}/respond
  /// Responds to a support ticket.
  Future<bool> respondToTicket(String ticketId, String response) async {
    try {
      await _dio.post(
        '/api/admin/support/tickets/$ticketId/respond',
        data: {'response': response},
      );
      return true;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// GET /api/admin/bookings?page={page}&limit={limit}
  /// Fetches all bookings for admin view.
  Future<List<Map<String, dynamic>>> getBookings({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final response = await _dio.get(
        '/api/admin/bookings',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null) 'status': status,
        },
      );
      return _list(response.data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  ServerException _mapError(DioException e) {
    String message = 'Server error';
    if (e.response != null) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        message = data['message']?.toString() ??
            data['error']?.toString() ??
            'Server error';
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
          message = e.message ?? 'Server error';
      }
    }
    return ServerException.msg(message);
  }

  List<Map<String, dynamic>> _list(dynamic data) {
    if (data == null) return [];
    dynamic raw = data;
    if (raw is Map) raw = raw['data'] ?? raw['items'] ?? raw;
    if (raw is List) return raw.whereType<Map<String, dynamic>>().toList();
    return [];
  }
}
