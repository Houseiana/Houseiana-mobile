import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
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
      _logout();
      return handler.next(err);
    }

    // Mint a fresh session JWT (deduped across concurrent 401s) and retry the
    // original request with it. Only sign the user out if a fresh token can't
    // be obtained — i.e. the session is genuinely dead.
    final freshToken = await _refreshToken(sessionId);
    if (freshToken == null || freshToken.isEmpty) {
      _logout();
      return handler.next(err);
    }

    await _userSession.saveAuthToken(freshToken);

    try {
      final response = await _retry(err.requestOptions, freshToken);
      handler.resolve(response);
    } on DioException catch (retryErr) {
      // Retry still failed — surface the real error without looping.
      handler.next(retryErr);
    } catch (_) {
      handler.next(err);
    }
  }

  /// De-duplicates concurrent refreshes: many requests may 401 at once, but we
  /// only want a single call to Clerk; everyone awaits the same future.
  Future<String?>? _refreshFuture;

  Future<String?> _refreshToken(String sessionId) {
    return _refreshFuture ??= _clerkService
        .getSessionToken(sessionId)
        .whenComplete(() => _refreshFuture = null);
  }

  /// Replays the failed request on a bare Dio (no interceptors → no 401 loop)
  /// with the freshly minted token. Uses the absolute URI so the request is
  /// fully self-contained regardless of the original client's base URL.
  Future<Response<dynamic>> _retry(
    RequestOptions requestOptions,
    String token,
  ) async {
    final headers = Map<String, dynamic>.from(requestOptions.headers)
      ..['Authorization'] = 'Bearer $token';
    return Dio().request<dynamic>(
      requestOptions.uri.toString(),
      data: requestOptions.data,
      options: Options(
        method: requestOptions.method,
        headers: headers,
        contentType: requestOptions.contentType,
        responseType: requestOptions.responseType,
      ),
    );
  }

  void _logout() {
    _clerkService.clearSession();
    _userSession.clear();
    // Reset the whole stack to login. `removeUntil((r) => false)` is idempotent
    // here — repeated 401s each collapse to a single `[login]` stack rather
    // than piling up. Screens must dismiss their own dialogs defensively, since
    // this can run while a route is mid-flight.
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      Routes.login,
      (route) => false,
    );
  }
}

final navigatorKey = GlobalKey<NavigatorState>();
