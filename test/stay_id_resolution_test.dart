import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/services/cache_service.dart';
import 'package:houseiana_mobile_app/core/services/favorites_notifier.dart';
import 'package:houseiana_mobile_app/core/services/lookups_cache.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `UserService.resolveStayEntityId` answers "which stay does this booking
/// review?" — the hotel id for a hotel stay, the property id otherwise. The
/// trips row does not always carry it, so the booking DTO is the second
/// source; these tests pin when each one is consulted.
class _BookingApi implements ApiConsumer {
  final Map<String, dynamic>? Function() booking;
  final List<String> gets = [];

  _BookingApi(this.booking);

  @override
  Future<dynamic> get(String path,
      {Map<String, dynamic>? queryParameters, CancelToken? cancelToken}) async {
    gets.add(path);
    final row = booking();
    if (row == null) throw DioException(requestOptions: RequestOptions(path: path));
    return {'data': row};
  }

  @override
  Future<dynamic> post(String path,
          {Map<String, dynamic>? body,
          bool formDataIsEnabled = false,
          Map<String, dynamic>? queryParameters,
          CancelToken? cancelToken}) =>
      throw UnimplementedError();

  @override
  Future<dynamic> put(String path,
          {Map<String, dynamic>? body, Map<String, dynamic>? queryParameters}) =>
      throw UnimplementedError();

  @override
  Future<dynamic> patch(String path,
          {Map<String, dynamic>? body, Map<String, dynamic>? queryParameters}) =>
      throw UnimplementedError();

  @override
  Future<dynamic> delete(String path,
          {Map<String, dynamic>? body, Map<String, dynamic>? queryParameters}) =>
      throw UnimplementedError();
}

Future<UserService> _service(_BookingApi api) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final cache = CacheService(prefs);
  return UserService(api, cache, LookupsCache(cache, prefs), FavoritesNotifier());
}

const _hotelUuid = '4d1f8935-2d4d-4a66-bf1c-8be1aab1319a';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a uuid-shaped candidate is used as is, with no extra request',
      () async {
    final api = _BookingApi(() => null);
    final service = await _service(api);

    final id = await service.resolveStayEntityId(
      bookingId: 'b-1',
      isHotel: true,
      localId: _hotelUuid,
    );

    expect(id, _hotelUuid);
    expect(api.gets, isEmpty, reason: 'the row already answered the question');
  });

  test('a property stay never pays for a booking lookup', () async {
    final api = _BookingApi(() => null);
    final service = await _service(api);

    final id = await service.resolveStayEntityId(
      bookingId: 'b-2',
      isHotel: false,
      localId: 'p-1',
    );

    expect(id, 'p-1');
    expect(api.gets, isEmpty);
  });

  test('a hotel row with no id at all falls back to the booking', () async {
    final api = _BookingApi(() => {
          'id': 'b-3',
          'hotelId': _hotelUuid,
          'bookingType': 'HOTEL',
          'checkInDate': '2026-08-27T00:00:00Z',
          'checkOutDate': '2026-08-28T00:00:00Z',
        });
    final service = await _service(api);

    final id = await service.resolveStayEntityId(
      bookingId: 'b-3',
      isHotel: true,
    );

    expect(id, _hotelUuid);
    expect(api.gets.single, '/booking-manager/b-3');
  });

  test('a booking code is not accepted as a hotel id', () async {
    // `/api/hotels/{hotelId}/reviews/create` declares a uuid; posting
    // `HB-D66CA676` there would 404 after the guest wrote the whole review.
    final api = _BookingApi(() => {
          'id': 'b-4',
          'hotel': {'id': _hotelUuid},
          'bookingType': 'HOTEL',
          'checkInDate': '2026-08-27T00:00:00Z',
          'checkOutDate': '2026-08-28T00:00:00Z',
        });
    final service = await _service(api);

    final id = await service.resolveStayEntityId(
      bookingId: 'b-4',
      isHotel: true,
      localId: 'HB-D66CA676',
    );

    expect(id, _hotelUuid);
    expect(api.gets.single, '/booking-manager/b-4');
  });

  test('a failed lookup keeps the candidate rather than losing it', () async {
    final api = _BookingApi(() => null);
    final service = await _service(api);

    final id = await service.resolveStayEntityId(
      bookingId: 'b-5',
      isHotel: true,
      localId: 'HB-D66CA676',
    );

    expect(id, 'HB-D66CA676');
    expect(api.gets.single, '/booking-manager/b-5');
  });

  test('nothing anywhere resolves to nothing', () async {
    final api = _BookingApi(() => null);
    final service = await _service(api);

    final id = await service.resolveStayEntityId(
      bookingId: 'b-6',
      isHotel: true,
    );

    expect(id, '');
  });
}
