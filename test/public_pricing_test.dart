import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/services/cache_service.dart';
import 'package:houseiana_mobile_app/core/services/lookups_cache.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/core/utils/discount_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records every query map `/api/property-search` is called with, and answers
/// with the live response shapes for the Aswan listing.
class _RecordingApi implements ApiConsumer {
  final List<Map<String, dynamic>> queries = [];

  @override
  Future<dynamic> get(String path,
      {Map<String, dynamic>? queryParameters, CancelToken? cancelToken}) async {
    queries.add(Map<String, dynamic>.from(queryParameters ?? const {}));

    // Details: /api/property-search/{id}
    if (path.startsWith('/api/property-search/')) {
      return {
        'success': true,
        'data': {
          'id': 'aswan-1',
          'title': 'Luxury Nile View Apartment',
          'currency': 'EGP',
          'pricePerNight': 3000,
          'priceWithoutDiscount': 3000,
        },
      };
    }

    // List / grouped: /api/property-search
    const row = {
      'id': 'aswan-1',
      'title': 'Luxury Nile View Apartment',
      'currency': 'EGP',
      'weeklyDiscount': null,
      'smallBookingDiscount': null,
      'discountPercent': 30,
      'pricePerNight': 1400,
      'priceWithoutDiscount': 2000,
    };
    return {
      'success': true,
      'totalCount': 1,
      'properties': [row],
      'propertiesByCountry': [
        {
          'regionId': 16,
          'name': 'Aswan',
          'totalCount': 1,
          'properties': [row],
        }
      ],
      'pagination': {'hasMore': false, 'total': 1, 'totalGroups': 1},
    };
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

Future<PropertyService> _service(_RecordingApi api) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return PropertyService(api, LookupsCache(CacheService(prefs), prefs));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // `/api/property-search` prices personally as soon as it is given a user id:
  // it stacks the platform's "New Listing Discount" on the host's calendar
  // discount (2000 → 1400 → 1120) so the same unit read one price signed in and
  // another signed out — while `/nightly-prices` and `/availability`, which are
  // called without a user id, kept quoting the public price.
  group('guest price surfaces never personalize', () {
    test('the flat search sends no userId', () async {
      final api = _RecordingApi();
      final service = await _service(api);

      await service.searchProperties(PropertySearchParams(page: 1, limit: 20));

      expect(api.queries.single.containsKey('userId'), isFalse);
    });

    test('the grouped (home) search sends no userId', () async {
      final api = _RecordingApi();
      final service = await _service(api);

      await service
          .searchPropertiesGrouped(PropertySearchParams(page: 1, limit: 20));

      expect(api.queries.single.containsKey('userId'), isFalse);
      expect(api.queries.single['isSorted'], 'true');
    });

    test('the details endpoint sends no userId', () async {
      final api = _RecordingApi();
      final service = await _service(api);

      await service.getPropertyById('aswan-1');

      expect(api.queries.single.containsKey('userId'), isFalse);
    });

    test('the public row prices the same for everyone', () async {
      final api = _RecordingApi();
      final service = await _service(api);

      final page = await service.searchProperties(PropertySearchParams());

      final row = page.properties.single;
      expect(row['pricePerNight'], 1400);
      expect(originalNightlyPrice(row), 2000);
      expect(effectiveDiscountPercent(row), 30);
    });
  });

  group('discount badge describes the two prices on screen', () {
    test('the declared total wins over a component discount', () {
      // The personalized row the backend used to return: `smallBookingDiscount`
      // is one component (20%) of the 44% total between 2000 and 1120. Reading
      // the component first printed "-20%" next to a 44%-off price pair.
      expect(
        effectiveDiscountPercent(const {
          'weeklyDiscount': null,
          'smallBookingDiscount': 20,
          'discountPercent': 44,
          'pricePerNight': 1120,
          'priceWithoutDiscount': 2000,
        }),
        44,
      );
    });

    test('a component is still used when no total is declared', () {
      expect(
        effectiveDiscountPercent(const {
          'weeklyDiscount': 15,
          'discountPercent': null,
        }),
        15,
      );
    });
  });
}
