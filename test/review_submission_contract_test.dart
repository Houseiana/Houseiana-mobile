import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:houseiana_mobile_app/core/services/ratings_service.dart';

/// Guards the exact body `POST /api/ratings/property-by-guest` accepts.
///
/// Every review submission used to fail: the app sent the UI's `double` rating,
/// and the API answered
/// `400 "The JSON value could not be converted to System.Int32. Path: $.rating"`.
/// It also sent `userId` where the DTO declares `guestId`, plus a `bookingId`
/// the contract has no field for. These tests pin the shape so the same class of
/// mismatch cannot come back silently.
class _RecordingServer {
  _RecordingServer._(this._server, this._body) {
    _server.listen((request) async {
      lastPath = request.uri.path;
      lastBody = jsonDecode(await utf8.decoder.bind(request).join());
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(_body));
      await request.response.close();
    });
  }

  static Future<_RecordingServer> start({
    Map<String, dynamic> body = const {'success': true, 'reviewId': 'r1'},
  }) async =>
      _RecordingServer._(
        await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
        body,
      );

  final HttpServer _server;
  final Map<String, dynamic> _body;

  String? lastPath;
  dynamic lastBody;

  String get baseUrl => 'http://${_server.address.host}:${_server.port}';

  Future<void> close() => _server.close(force: true);
}

RatingsService _serviceFor(String baseUrl) =>
    RatingsService(dio: Dio(BaseOptions(baseUrl: baseUrl)));

void main() {
  test('sends guestId, an INT rating and no bookingId', () async {
    final server = await _RecordingServer.start();
    addTearDown(server.close);

    final result = await _serviceFor(server.baseUrl).submitReview(
      guestId: 'user_123',
      propertyId: 'prop_456',
      rating: 5,
      comment: 'Great stay',
    );

    expect(result['success'], isTrue);
    expect(server.lastPath, '/api/ratings/property-by-guest');

    final body = server.lastBody as Map<String, dynamic>;
    expect(body['guestId'], 'user_123');
    expect(body['propertyId'], 'prop_456');
    expect(body['comment'], 'Great stay');

    // The whole bug in one assertion: 5, never 5.0.
    expect(body['rating'], isA<int>());
    expect(body['rating'], 5);

    // Keys the DTO does not declare must not be sent.
    expect(body.containsKey('userId'), isFalse);
    expect(body.containsKey('bookingId'), isFalse);
    expect(body.containsKey('categories'), isFalse);
  });

  test('clamps a rating outside the DTO range instead of letting the API 400',
      () async {
    final server = await _RecordingServer.start();
    addTearDown(server.close);

    // The web's review dialog offers a 1-10 scale; the API caps at 5.
    await _serviceFor(server.baseUrl).submitReview(
      guestId: 'u',
      propertyId: 'p',
      rating: 10,
      comment: 'c',
    );
    expect((server.lastBody as Map)['rating'], 5);

    await _serviceFor(server.baseUrl).submitReview(
      guestId: 'u',
      propertyId: 'p',
      rating: 0,
      comment: 'c',
    );
    expect((server.lastBody as Map)['rating'], 1);
  });

  test('omits the six category scores when they were not collected', () async {
    final server = await _RecordingServer.start();
    addTearDown(server.close);

    await _serviceFor(server.baseUrl).submitReview(
      guestId: 'u',
      propertyId: 'p',
      rating: 4,
      comment: 'c',
    );

    final body = server.lastBody as Map<String, dynamic>;
    for (final key in const [
      'cleanliness',
      'accuracy',
      'checkIn',
      'communication',
      'location',
      'value',
    ]) {
      expect(body.containsKey(key), isFalse, reason: '$key must be omitted');
    }
  });

  test('sends the category scores when they are collected', () async {
    final server = await _RecordingServer.start();
    addTearDown(server.close);

    await _serviceFor(server.baseUrl).submitReview(
      guestId: 'u',
      propertyId: 'p',
      rating: 4,
      comment: 'c',
      cleanliness: 5,
      accuracy: 4,
      checkIn: 5,
      communication: 4,
      location: 5,
      value: 3,
    );

    final body = server.lastBody as Map<String, dynamic>;
    expect(body['cleanliness'], 5);
    expect(body['value'], 3);
  });

  test('surfaces the validation detail, not just the generic message',
      () async {
    // What the API really answers on a bad body — the useful part is in
    // `errors`, and reporting only `message` left the guest with
    // "One or more fields are invalid." and no idea what to do.
    final server = await _RecordingServer.start(body: {
      'success': false,
      'statusCode': 400,
      'message': 'One or more fields are invalid.',
      'errors': ['The dto field is required.'],
    });
    addTearDown(server.close);

    final result = await _serviceFor(server.baseUrl).submitReview(
      guestId: 'u',
      propertyId: 'p',
      rating: 3,
      comment: 'c',
    );

    expect(result['success'], isFalse);
    expect(result['message'], contains('The dto field is required.'));
  });
}
