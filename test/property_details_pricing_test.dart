import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/services/cache_service.dart';
import 'package:houseiana_mobile_app/core/services/lookups_cache.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/core/utils/discount_utils.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/cubit/property_details_cubit.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/cubit/property_details_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serves the live `/api/property-search/{id}` shape for the Aswan listing.
class _FakeApi implements ApiConsumer {
  final num pricePerNight;
  final num priceWithoutDiscount;
  final int? discountPercent;

  _FakeApi({
    this.pricePerNight = 3000,
    this.priceWithoutDiscount = 3000,
    this.discountPercent,
  });

  @override
  Future<dynamic> get(String path,
      {Map<String, dynamic>? queryParameters, CancelToken? cancelToken}) async {
    if (path.startsWith('/api/property-search/')) {
      return {
        'success': true,
        'data': {
          'id': 'aswan-1',
          'title': 'Luxury Nile View Apartment',
          'currency': 'EGP',
          'weeklyDiscount': null,
          'smallBookingDiscount': null,
          'discountPercent': discountPercent,
          'pricePerNight': pricePerNight,
          'priceWithoutDiscount': priceWithoutDiscount,
          'instantBook': true,
        },
      };
    }
    throw UnimplementedError('GET $path');
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

Future<PropertyDetailsCubit> _cubit(_FakeApi api) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return PropertyDetailsCubit(
    PropertyService(api, LookupsCache(CacheService(prefs), prefs)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('property details nightly price', () {
    test('shows the details endpoint keys verbatim', () async {
      // The live response for this listing: no discount, 3000 both ways —
      // even though the list row for the same unit says 1400/2000/30.
      final cubit = await _cubit(_FakeApi());

      await cubit.getPropertyDetails('aswan-1');

      final state = cubit.state as PropertyDetailsLoaded;
      expect(state.property.displayPrice, 3000);
      expect(state.property.priceWithoutDiscount, 3000);
      expect(state.property.effectiveDiscountPercent, 0);
    });

    test('renders the discount when the endpoint declares one', () async {
      final cubit = await _cubit(_FakeApi(
        pricePerNight: 1400,
        priceWithoutDiscount: 2000,
        discountPercent: 30,
      ));

      await cubit.getPropertyDetails('aswan-1');

      final state = cubit.state as PropertyDetailsLoaded;
      expect(state.property.displayPrice, 1400);
      expect(state.property.priceWithoutDiscount, 2000);
      expect(state.property.effectiveDiscountPercent, 30);
    });

    test('ignores the tapped card row — the endpoint is the only source',
        () async {
      final cubit = await _cubit(_FakeApi());

      await cubit.getPropertyDetails('aswan-1');

      expect((cubit.state as PropertyDetailsLoaded).property.displayPrice, 3000,
          reason: 'no substitution from the list row is performed');
    });
  });

  group('discount keys', () {
    // The live `/api/property-search` row for the Aswan listing: the three keys
    // are the whole contract — badge, price after discount, price before it.
    const homeRow = <String, dynamic>{
      'weeklyDiscount': null,
      'smallBookingDiscount': null,
      'discountPercent': 30,
      'pricePerNight': 1400,
      'priceWithoutDiscount': 2000,
    };

    test('badge is the API percentage, never derived from the prices', () {
      expect(effectiveDiscountPercent(homeRow), 30);
      expect(originalNightlyPrice(homeRow), 2000,
          reason: 'price before discount, struck through');
    });

    test('a percentage that disagrees with the prices is still shown as-is',
        () {
      expect(
        effectiveDiscountPercent(const {
          'pricePerNight': 1120,
          'priceWithoutDiscount': 2000,
          'discountPercent': 20,
        }),
        20,
        reason: 'the API percentage wins — the app does not recompute it',
      );
    });

    test('stays at zero when the API declares no discount', () {
      expect(
        effectiveDiscountPercent(const {
          'pricePerNight': 2650,
          'priceWithoutDiscount': 2650,
          'discountPercent': null,
        }),
        0,
      );
    });
  });
}
