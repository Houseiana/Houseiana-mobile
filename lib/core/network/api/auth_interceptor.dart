import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/clerk_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';

class AuthInterceptor extends Interceptor {
  final ClerkService _clerkService;
  final UserSession _userSession;

  AuthInterceptor(this._clerkService, this._userSession);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _userSession.authToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    if (kDebugMode) {
      debugPrint('REQUEST[${options.method}] => PATH: ${options.path}');
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _handleUnauthorized(err, handler);
    } else {
      if (kDebugMode) {
        debugPrint(
            'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}');
        debugPrint('ERROR MESSAGE: ${err.message}');
      }
      handler.next(err);
    }
  }

  Future<void> _handleUnauthorized(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final sessionId = _userSession.sessionId;
    if (sessionId == null || sessionId.isEmpty) {
      _navigateToLogin();
      return handler.next(err);
    }

    try {
      final result = await _clerkService.getSession(sessionId);
      if (result == null || result['success'] != true) {
        _navigateToLogin();
        return handler.next(err);
      }
      final response = await _retry(err.requestOptions);
      handler.resolve(response);
    } catch (_) {
      _navigateToLogin();
      handler.next(err);
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final dio = Dio();
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    return dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  void _navigateToLogin() {
    sl<UserSession>().clear();
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      Routes.login,
      (route) => false,
    );
  }
}

final navigatorKey = GlobalKey<NavigatorState>();
