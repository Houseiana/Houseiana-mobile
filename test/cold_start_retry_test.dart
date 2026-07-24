import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:houseiana_mobile_app/core/network/api/retry_interceptor.dart';

/// Reproduces the production failure: the API scales to zero, so the FIRST
/// request of a session stalls past the receive timeout while the container
/// boots, and every request after it answers immediately.
///
/// The real numbers are ~31s against a 30s timeout; this server stalls its
/// first [stalledRequests] responses well past a deliberately tiny client
/// timeout to keep the test fast.
class _ColdStartServer {
  _ColdStartServer._(this._server, this.stalledRequests) {
    _server.listen((request) async {
      requests.add(request.method);
      if (requests.length <= stalledRequests) {
        // Container still booting: hold the connection open, answer far too late.
        await Future<void>.delayed(const Duration(seconds: 3));
      }
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'ok': true, 'attempt': requests.length}));
      await request.response.close();
    });
  }

  static Future<_ColdStartServer> start({int stalledRequests = 1}) async =>
      _ColdStartServer._(
        await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
        stalledRequests,
      );

  final HttpServer _server;

  /// How many leading requests answer too late to beat the receive timeout.
  final int stalledRequests;

  /// Methods of every request the server actually saw, in order.
  final List<String> requests = [];

  String get baseUrl => 'http://${_server.address.host}:${_server.port}';

  Future<void> close() => _server.close(force: true);
}

Dio _client(String baseUrl) => Dio(BaseOptions(
      baseUrl: baseUrl,
      // Tiny window so a stalled request times out in milliseconds instead of
      // the 45s the app allows.
      connectTimeout: const Duration(milliseconds: 500),
      receiveTimeout: const Duration(milliseconds: 300),
      sendTimeout: const Duration(milliseconds: 500),
    ))
      ..interceptors.add(const RetryInterceptor());

void main() {
  test('a GET that times out on the cold start is replayed and succeeds',
      () async {
    final server = await _ColdStartServer.start(stalledRequests: 1);
    addTearDown(server.close);

    final response =
        await _client(server.baseUrl).get<dynamic>('/api/property-search');

    expect(response.statusCode, 200);
    expect(response.data['ok'], true);
    // Attempt 1 timed out; the replay landed on the now-warm container.
    expect(server.requests, ['GET', 'GET']);
  });

  test('a GET that keeps timing out surfaces the timeout instead of hanging',
      () async {
    final server = await _ColdStartServer.start(stalledRequests: 99);
    addTearDown(server.close);

    await expectLater(
      _client(server.baseUrl).get<dynamic>('/api/property-search'),
      throwsA(isA<DioException>()
          .having((e) => e.type, 'type', DioExceptionType.receiveTimeout)),
    );
    // One original attempt + one replay: the error reaches the caller, which is
    // what drives the screen's retry state instead of an endless skeleton.
    expect(server.requests, ['GET', 'GET']);
  });

  test('a POST is never replayed after a receive timeout', () async {
    // The server may already have processed it — replaying could double-book.
    final server = await _ColdStartServer.start(stalledRequests: 99);
    addTearDown(server.close);

    await expectLater(
      _client(server.baseUrl).post<dynamic>('/booking-manager', data: {'a': 1}),
      throwsA(isA<DioException>()),
    );
    expect(server.requests, ['POST']);
  });

  test('a cancelled request is not replayed', () async {
    final server = await _ColdStartServer.start(stalledRequests: 99);
    addTearDown(server.close);

    final token = CancelToken();
    final future = _client(server.baseUrl)
        .get<dynamic>('/api/property-search', cancelToken: token);
    unawaited(Future<void>.delayed(const Duration(milliseconds: 50))
        .then((_) => token.cancel()));

    await expectLater(future, throwsA(isA<DioException>()));
    expect(server.requests, ['GET']);
  });
}
