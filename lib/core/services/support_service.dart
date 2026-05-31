import 'package:dio/dio.dart';
import 'package:houseiana_mobile_app/core/config/app_config.dart';
import 'package:houseiana_mobile_app/core/constants/errors/exceptions.dart';

/// Service for support tickets.
/// Routes: /api/support/*
class SupportService {
  final Dio _dio;

  SupportService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.backendApiUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
            ));

  /// GET /api/support — list tickets for a user
  Future<List<Map<String, dynamic>>> getTickets(String userId) async {
    try {
      final response = await _dio.get(
        '/api/support',
        queryParameters: {'userId': userId},
      );
      final data = response.data;
      if (data is List) {
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
      if (data is Map) {
        final items = data['data'] ?? data['items'] ?? [];
        if (items is List) {
          return items.map((e) => e as Map<String, dynamic>).toList();
        }
      }
      return [];
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// POST /api/support — create a new ticket
  Future<Map<String, dynamic>> createTicket({
    String? userId,
    required String subject,
    required String message,
    String? category,
    String? contactName,
    String? contactEmail,
    String? priority,
  }) async {
    try {
      final response = await _dio.post(
        '/api/support',
        data: {
          if (userId != null) 'userId': userId,
          if (contactName != null) 'name': contactName,
          if (contactEmail != null) 'email': contactEmail,
          'subject': subject,
          'message': message,
          if (category != null) 'category': category,
          if (priority != null) 'priority': priority,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// GET /api/support/{id} — ticket details
  Future<Map<String, dynamic>> getTicketById(String ticketId) async {
    try {
      final response = await _dio.get('/api/support/$ticketId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  ServerException _mapDioException(DioException e) {
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
}
