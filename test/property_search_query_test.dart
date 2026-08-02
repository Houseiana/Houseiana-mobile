import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/services/cache_service.dart';
import 'package:houseiana_mobile_app/core/services/lookups_cache.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Answers `/api/property-search` with whatever shape a test hands it, and
/// records the query it was called with.
class _ShapeApi implements ApiConsumer {
  final Map<String, dynamic> Function() body;
  final List<Map<String, dynamic>> queries = [];

  _ShapeApi(this.body);

  @override
  Future<dynamic> get(String path,
      {Map<String, dynamic>? queryParameters, CancelToken? cancelToken}) async {
    queries.add(Map<String, dynamic>.from(queryParameters ?? const {}));
    return body();
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

Map<String, dynamic> _row(String id) => {
      'id': id,
      'title': 'Chalet $id',
      'currency': 'EGP',
      'pricePerNight': 3990,
    };

Future<PropertyService> _service(_ShapeApi api) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return PropertyService(api, LookupsCache(CacheService(prefs), prefs));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('village / region scoping', () {
    test('villageId reaches the API and no location is invented', () async {
      final api = _ShapeApi(() => {
            'totalCount': 1,
            'properties': [_row('v-1')],
          });
      final service = await _service(api);

      final page = await service.searchProperties(
        PropertySearchParams(villageId: 512, page: 1, limit: 20),
      );

      expect(api.queries.single['villageId'], 512);
      expect(api.queries.single.containsKey('location'), isFalse);
      expect(page.properties.single['_id'], 'v-1');
      expect(page.total, 1);
    });
  });

  // The search modal hands over `DateTime.toIso8601String()`; every date this
  // app sends the backend elsewhere is a plain calendar day.
  group('dates are sent as calendar days', () {
    test('full ISO timestamps are trimmed', () {
      final query = PropertySearchParams(
        checkIn: '2026-08-05T00:00:00.000',
        checkOut: '2026-08-09T00:00:00.000Z',
      ).toQueryParams();

      expect(query['checkin'], '2026-08-05');
      expect(query['checkout'], '2026-08-09');
    });

    test('day strings pass through untouched, empties are dropped', () {
      final query = PropertySearchParams(checkIn: '2026-08-05', checkOut: '')
          .toQueryParams();

      expect(query['checkin'], '2026-08-05');
      expect(query.containsKey('checkout'), isFalse);
    });
  });

  // An empty results page must mean "the backend matched nothing", never "we
  // read the wrong array out of the payload".
  group('result rows are read by name', () {
    test('an unrelated leading array cannot shadow the results', () async {
      final api = _ShapeApi(() => ({
            // Serialised before `properties` — the old "first list wins" parse
            // returned this and rendered an empty page.
            'appliedFilters': <dynamic>[],
            'totalCount': 2,
            'properties': [_row('a'), _row('b')],
          }));
      final service = await _service(api);

      final page = await service.searchProperties(PropertySearchParams());

      expect(page.properties.map((p) => p['_id']), ['a', 'b']);
    });

    test('a grouped answer to a flat query still renders', () async {
      final api = _ShapeApi(() => ({
            'totalCount': 2,
            'properties': <dynamic>[],
            'propertiesByCountry': [
              {
                'regionId': 16,
                'name': 'Matrouh',
                'properties': [_row('g1'), _row('g2')],
              }
            ],
          }));
      final service = await _service(api);

      final page = await service.searchProperties(PropertySearchParams());

      expect(page.properties.map((p) => p['_id']), ['g1', 'g2']);
    });

    test('a genuinely empty village stays empty', () async {
      final api = _ShapeApi(() => ({
            'totalCount': 0,
            'properties': <dynamic>[],
            'propertiesByCountry': <dynamic>[],
          }));
      final service = await _service(api);

      final page = await service.searchProperties(
        PropertySearchParams(villageId: 999),
      );

      expect(page.properties, isEmpty);
      expect(page.total, 0);
    });
  });
}
