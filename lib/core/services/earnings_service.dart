import 'package:dio/dio.dart';
import 'package:houseiana_mobile_app/core/config/app_config.dart';
import 'package:houseiana_mobile_app/core/constants/errors/exceptions.dart';

/// Service for host earnings and analytics.
/// Routes: /api/earnings/*
class EarningsService {
  final Dio _dio;

  EarningsService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.backendApiUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
            ));

  /// GET /api/earnings?hostId={hostId}
  Future<Map<String, dynamic>> getEarningsSummary(
    String hostId, {
    int? year,
    int? month,
  }) async {
    try {
      final response = await _dio.get(
        '/api/earnings',
        queryParameters: {
          'hostId': hostId,
          if (year != null) 'year': year,
          if (month != null) 'month': month,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// GET /api/earnings/monthly?hostId={hostId}&year={year}
  Future<List<Map<String, dynamic>>> getMonthlyEarnings(
    String hostId, {
    required int year,
  }) async {
    try {
      final response = await _dio.get(
        '/api/earnings/monthly',
        queryParameters: {
          'hostId': hostId,
          'year': year,
        },
      );
      return _list(response.data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// GET /api/earnings/occupancy?hostId={hostId}
  Future<Map<String, dynamic>> getOccupancyRate(
    String hostId, {
    int? year,
    int? month,
  }) async {
    try {
      final response = await _dio.get(
        '/api/earnings/occupancy',
        queryParameters: {
          'hostId': hostId,
          if (year != null) 'year': year,
          if (month != null) 'month': month,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// GET /api/earnings/adr?hostId={hostId}
  Future<Map<String, dynamic>> getAverageDailyRate(
    String hostId, {
    int? year,
    int? month,
  }) async {
    try {
      final response = await _dio.get(
        '/api/earnings/adr',
        queryParameters: {
          'hostId': hostId,
          if (year != null) 'year': year,
          if (month != null) 'month': month,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// GET /api/earnings/transactions?hostId={hostId}
  Future<List<Map<String, dynamic>>> getTransactions(
    String hostId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/api/earnings/transactions',
        queryParameters: {
          'hostId': hostId,
          'page': page,
          'limit': limit,
        },
      );
      return _list(response.data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _list(dynamic data) {
    if (data == null) return [];
    dynamic raw = data;
    if (raw is Map) raw = raw['data'] ?? raw['items'] ?? raw;
    if (raw is List) return raw.whereType<Map<String, dynamic>>().toList();
    return [];
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
