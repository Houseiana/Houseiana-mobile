import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Replays requests that failed because the backend was not reachable *yet*.
///
/// The production API runs on Azure Container Apps with scale-to-zero: after an
/// idle period the first request pays a cold start (measured ~31s to first
/// byte) while every request after it answers in well under a second. A single
/// slow request used to blow the receive timeout and surface as a hard failure
/// — the search tab stuck on its skeleton — even though the container was up
/// by the time the error was thrown.
///
/// Only *safe* replays are made:
/// - `GET`/`HEAD` — idempotent, so replaying can never double-book anything.
/// - any other method on `connectionTimeout` — the connection was never
///   established, so the server provably never saw the request.
///
/// The replay runs on a bare Dio (no interceptors → no recursion). The original
/// [RequestOptions] already carry the headers the earlier interceptors applied
/// (`Authorization`, `lang`), and `uri` is fully serialized, so the replay is
/// byte-identical to the request that failed.
class RetryInterceptor extends Interceptor {
  const RetryInterceptor();

  /// Failures that mean "the server didn't answer", as opposed to an answer we
  /// didn't like (a 4xx/5xx is never retried — it would just fail again).
  static const Set<DioExceptionType> _retryableTypes = {
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionError,
  };

  /// Backoff before each replay. Short — the point is to let the container
  /// finish booting, and it is already booting by the time we get here.
  static const List<Duration> _backoff = [
    Duration(milliseconds: 600),
    Duration(seconds: 2),
  ];

  /// Timeout failures are expensive (each attempt burns the full receive
  /// timeout), so they get a single replay; connection failures fail fast and
  /// can afford two.
  int _maxAttempts(DioExceptionType type) =>
      type == DioExceptionType.receiveTimeout ||
              type == DioExceptionType.sendTimeout
          ? 1
          : 2;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_isRetryable(err)) return handler.next(err);

    final attempts = _maxAttempts(err.type);
    var lastError = err;

    for (var attempt = 0; attempt < attempts; attempt++) {
      if (_isCancelled(err)) return handler.next(lastError);
      await Future<void>.delayed(_backoff[attempt.clamp(0, _backoff.length - 1)]);
      if (_isCancelled(err)) return handler.next(lastError);

      if (kDebugMode) {
        debugPrint('RETRY[${attempt + 1}/$attempts] => PATH: '
            '${err.requestOptions.path} (${err.type.name})');
      }

      try {
        return handler.resolve(await _replay(err.requestOptions));
      } on DioException catch (e) {
        lastError = e;
        // A cancelled or non-transient failure is final — stop replaying.
        if (e.type == DioExceptionType.cancel || !_isRetryable(e)) {
          return handler.next(e);
        }
      } catch (_) {
        return handler.next(lastError);
      }
    }

    handler.next(lastError);
  }

  bool _isRetryable(DioException err) {
    if (!_retryableTypes.contains(err.type)) return false;
    if (_isCancelled(err)) return false;
    // A FormData body is a one-shot stream; replaying it would send a
    // truncated (or empty) payload.
    if (err.requestOptions.data is FormData) return false;

    final method = err.requestOptions.method.toUpperCase();
    if (method == 'GET' || method == 'HEAD') return true;
    // Non-idempotent verbs: only safe when the connection never opened.
    return err.type == DioExceptionType.connectionTimeout;
  }

  bool _isCancelled(DioException err) =>
      err.requestOptions.cancelToken?.isCancelled ?? false;

  /// Re-sends the failed request on an interceptor-free client, carrying over
  /// the original timeouts (a bare Dio has none, and a stalled replay would
  /// otherwise hang the caller forever) and its cancel token.
  Future<Response<dynamic>> _replay(RequestOptions o) {
    return Dio(
      BaseOptions(
        connectTimeout: o.connectTimeout,
        receiveTimeout: o.receiveTimeout,
        sendTimeout: o.sendTimeout,
      ),
    ).request<dynamic>(
      // Absolute URI: query parameters are already serialized with the
      // original list format (amenities=1&amenities=2).
      o.uri.toString(),
      data: o.data,
      cancelToken: o.cancelToken,
      options: Options(
        method: o.method,
        headers: o.headers,
        contentType: o.contentType,
        responseType: o.responseType,
      ),
    );
  }
}
