import 'package:dio/dio.dart';
import 'package:houseiana_mobile_app/core/config/app_config.dart';
import 'package:houseiana_mobile_app/core/constants/errors/exception_model.dart';
import 'package:houseiana_mobile_app/core/constants/errors/exceptions.dart';
import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/network/api/end_points.dart';

class ChatService {
  final ApiConsumer _api;
  final Dio _dio;

  ChatService(this._api, {Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
          baseUrl: AppConfig.backendApiUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ));

  Future<List<Map<String, dynamic>>> getConversations(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.get(
      EndPoints.conversations,
      queryParameters: {'userId': userId, 'page': page, 'limit': limit},
    );
    return _list(response);
  }

  Future<Map<String, dynamic>?> getConversation(String conversationId) async {
    final response = await _api.get('/api/chat/conversations/$conversationId');
    return response;
  }

  Future<Map<String, dynamic>?> createConversation({
    required String propertyId,
    required String hostId,
    required String guestId,
    String? initialMessage,
  }) async {
    final response = await _api.post(
      '/api/chat/conversations',
      body: {
        'propertyId': propertyId,
        'hostId': hostId,
        'guestId': guestId,
        if (initialMessage != null) 'initialMessage': initialMessage,
      },
    );
    return response;
  }

  Future<List<Map<String, dynamic>>> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _dio.get(
        '/api/chat/conversations/$conversationId/messages',
        queryParameters: {'page': page, 'limit': limit},
      );
      return _list(response.data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Map<String, dynamic>?> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    String contentType = 'TEXT',
  }) async {
    final response = await _api.post(
      '/api/chat/conversations/$conversationId/messages',
      body: {
        'senderId': senderId,
        'content': content,
        'contentType': contentType,
      },
    );
    return response;
  }

  Future<bool> markMessageAsRead({
    required String conversationId,
    required String messageId,
  }) async {
    await _api.patch(
        '/api/chat/conversations/$conversationId/messages/$messageId/read');
    return true;
  }

  List<Map<String, dynamic>> _list(dynamic response) {
    if (response == null) return [];
    dynamic raw = response;
    if (raw is Map) raw = raw['data'] ?? raw['items'] ?? raw;
    if (raw is Map) {
      raw = raw['items'] ??
          raw['messages'] ??
          raw['data'] ??
          raw.values.firstWhere(
            (value) => value is List,
            orElse: () => [],
          );
    }
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
    return ServerException(
      exceptionModel: ExceptionModel(
          statusCode: e.response?.statusCode ?? 0, message: message),
    );
  }
}
