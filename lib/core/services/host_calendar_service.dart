import 'package:dio/dio.dart';
import 'package:houseiana_mobile_app/core/config/app_config.dart';
import 'package:houseiana_mobile_app/core/constants/errors/exceptions.dart';

/// Service for host calendar and availability management.
class HostCalendarService {
  final Dio _dio;

  HostCalendarService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.backendApiUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
            ));

  /// GET /api/properties/{propertyId}/calendar
  /// Fetches the availability calendar for a property.
  Future<Map<String, dynamic>?> getAvailabilityCalendar(
    String propertyId, {
    int year = 2026,
    int? month,
  }) async {
    try {
      final response = await _dio.get(
        '/api/properties/$propertyId/calendar',
        queryParameters: {
          'year': year,
          if (month != null) 'month': month,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// PUT /api/properties/{propertyId}/calendar
  /// Updates blocked dates for a property.
  Future<Map<String, dynamic>> updateBlockedDates({
    required String propertyId,
    required List<String> blockedDates,
    required String hostId,
  }) async {
    try {
      final response = await _dio.put(
        '/api/properties/$propertyId/calendar',
        data: {
          'propertyId': propertyId,
          'hostId': hostId,
          'blockedDates': blockedDates,
        },
      );

      final data = response.data;
      if (data['success'] == true) {
        return {'success': true, 'message': 'Calendar updated successfully'};
      }
      return {
        'success': false,
        'message': data['message']?.toString() ?? 'Failed to update calendar',
      };
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// POST /api/properties/{propertyId}/calendar/unblock
  /// Unblocks specific dates.
  Future<Map<String, dynamic>> unblockDates({
    required String propertyId,
    required List<String> datesToUnblock,
    required String hostId,
  }) async {
    try {
      final response = await _dio.post(
        '/api/properties/$propertyId/calendar/unblock',
        data: {
          'propertyId': propertyId,
          'datesToUnblock': datesToUnblock,
          'hostId': hostId,
        },
      );

      final data = response.data;
      if (data['success'] == true) {
        return {'success': true, 'message': 'Dates unblocked successfully'};
      }
      return {
        'success': false,
        'message': data['message']?.toString() ?? 'Failed to unblock dates',
      };
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// GET /api/properties/{propertyId}/bookings
  /// Fetches bookings for the calendar view.
  Future<List<Map<String, dynamic>>> getPropertyBookings(
    String propertyId, {
    int? year,
    int? month,
  }) async {
    try {
      final response = await _dio.get(
        '/api/properties/$propertyId/bookings',
        queryParameters: {
          if (year != null) 'year': year,
          if (month != null) 'month': month,
        },
      );
      return _list(response.data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _list(dynamic data) {
    if (data == null) return [];
    dynamic raw = data;
    if (raw is Map) raw = raw['data'] ?? raw['bookings'] ?? raw;
    if (raw is List) return raw.whereType<Map<String, dynamic>>().toList();
    return [];
  }

  ServerException _mapError(DioException e) {
    String message = 'Calendar error';
    if (e.response != null) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        message = data['message']?.toString() ??
            data['error']?.toString() ??
            'Calendar error';
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
          message = e.message ?? 'Calendar error';
      }
    }
    return ServerException.msg(message);
  }

  Map<String, dynamic> _handleError(DioException e) {
    String message = 'Failed to update calendar';
    if (e.response?.data is Map<String, dynamic>) {
      message = e.response?.data['message']?.toString() ?? message;
    }
    return {'success': false, 'message': message};
  }
}
