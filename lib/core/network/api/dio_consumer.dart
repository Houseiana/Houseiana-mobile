import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/network/api/end_points.dart';
import 'package:houseiana_mobile_app/core/constants/errors/exception_model.dart';
import 'package:houseiana_mobile_app/core/constants/errors/exceptions.dart';
import 'package:houseiana_mobile_app/core/network/api/status_code.dart';

class DioConsumer implements ApiConsumer {
  final Dio client;
  final String? authToken;

  DioConsumer({required this.client, this.authToken}) {
    client.options
      ..baseUrl = EndPoints.baseUrl
      ..responseType = ResponseType.json
      ..sendTimeout = const Duration(seconds: 30)
      ..receiveTimeout = const Duration(seconds: 30)
      ..connectTimeout = const Duration(seconds: 30);

    // Attach auth token if provided.
    if (authToken != null && authToken!.isNotEmpty) {
      client.options.headers['Authorization'] = 'Bearer $authToken';
    }

    client.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
      logPrint: (Object object) {
        debugPrint(object.toString());
      },
    ));
  }

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await client.get(
        path,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioException(e);
    }
  }

  @override
  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool formDataIsEnabled = false,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await client.post(
        path,
        data: formDataIsEnabled ? FormData.fromMap(body ?? {}) : body,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioException(e);
    }
  }

  @override
  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await client.put(
        path,
        data: body,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioException(e);
    }
  }

  @override
  Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await client.patch(
        path,
        data: body,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioException(e);
    }
  }

  @override
  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await client.delete(
        path,
        data: body,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioException(e);
    }
  }

  Never _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw const ServerException(
          exceptionModel: ExceptionModel(
            statusCode: StatusCode.requestTimeout,
            message: 'Connection timeout',
          ),
        );
      case DioExceptionType.badResponse:
        throw ServerException(
          exceptionModel: ExceptionModel(
            statusCode: e.response?.statusCode ?? 0,
            message: _messageFromResponse(e),
          ),
        );
      case DioExceptionType.cancel:
        throw const ServerException(
          exceptionModel: ExceptionModel(
            statusCode: 0,
            message: 'Request cancelled',
          ),
        );
      default:
        throw const ServerException(
          exceptionModel: ExceptionModel(
            statusCode: 0,
            message: 'Unexpected error occurred',
          ),
        );
    }
  }

  /// Safely derives a human-readable message from an error response.
  ///
  /// The backend can return a JSON object, an empty body (e.g. on 401), or a
  /// plain string. The previous implementation did `data['message']`
  /// unconditionally, which threw `type 'String' is not a subtype of type
  /// 'int' of 'index'` whenever [data] was not a Map — masking the real error.
  String _messageFromResponse(DioException e) {
    final status = e.response?.statusCode ?? 0;
    final data = e.response?.data;

    if (data is Map) {
      final msg = data['message'] ?? data['error'] ?? data['title'];
      if (msg != null && msg.toString().trim().isNotEmpty) {
        return msg.toString();
      }
    } else if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    if (status == 401) {
      return 'Your session has expired. Please sign in again.';
    }
    if (status == 403) {
      return 'You are not allowed to perform this action.';
    }
    return 'Server error occurred';
  }
}
