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

/// Mirrors the live production contract for one real listing
/// (`Luxury Nile View Apartment`), where the three endpoints disagree:
///
/// * `/api/property-search`            → 1400, was 2000, -30%  (calendar-aware)
/// * `/api/property-search/{id}`       → 3000, was 3000, no discount (stored
///                                       base price, ignores the calendar)
/// * `/api/property-search/{id}/nightly-prices`
///                                     → 2000 a night, 1400 on discounted days
class _FakeApi implements ApiConsumer {
  /// Days of the current month carrying a 30% discount (2000 → 1400).
  final Set<int> discountDays;

  int nightlyPricesCalls = 0;

  _FakeApi({this.discountDays = const {}});

  @override
  Future<dynamic> get(String path,
      {Map<String, dynamic>? queryParameters, CancelToken? cancelToken}) async {
    if (path.endsWith('/nightly-prices')) {
      nightlyPricesCalls++;
      final page = (queryParameters?['page'] as num? ?? 1).toInt();
      final now = DateTime.now();
      final month = page; // page 1 = January (matches production)
      final daysInMonth = DateTime(now.year, month + 1, 0).day;
      return {
        'success': true,
        'data': [
          for (var day = 1; day <= daysInMonth; day++)
            {
              'date': '${now.year}-${month.toString().padLeft(2, '0')}-'
                  '${day.toString().padLeft(2, '0')}',
              'price': 2000,
              'isSpecialPrice': false,
              'discountPercent':
                  month == now.month && discountDays.contains(day) ? 30 : null,
              'discountedPrice':
                  month == now.month && discountDays.contains(day) ? 1400 : null,
            },
        ],
        'page': page,
        'totalPages': 12,
      };
    }
    if (path.startsWith('/api/property-search/')) {
      return {
        'success': true,
        'data': {
          'id': 'aswan-1',
          'title': 'Luxury Nile View Apartment',
          'currency': 'EGP',
          'pricePerNight': 3000,
          'priceWithoutDiscount': 3000,
          'discountPercent': null,
          'weeklyDiscount': null,
          'smallBookingDiscount': null,
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
    test('uses the tapped card row, not the details payload base price',
        () async {
      final api = _FakeApi();
      final cubit = await _cubit(api);

      await cubit.getPropertyDetails('aswan-1', listRow: const {
        'id': 'aswan-1',
        'pricePerNight': 1400,
        'priceWithoutDiscount': 2000,
        'discountPercent': 30,
      });

      final state = cubit.state as PropertyDetailsLoaded;
      expect(state.property.displayPrice, 1400,
          reason: 'the details page must show the price the card showed');
      expect(state.property.priceWithoutDiscount, 2000);
      expect(state.property.effectiveDiscountPercent, 30);
      expect(api.nightlyPricesCalls, 0,
          reason: 'the card row already answers — no extra request');
    });

    test('falls back to the calendar when no card row was passed', () async {
      // Discount today so the window is always upcoming, whatever day it runs.
      final api = _FakeApi(discountDays: {DateTime.now().day});
      final cubit = await _cubit(api);

      await cubit.getPropertyDetails('aswan-1');

      final state = cubit.state as PropertyDetailsLoaded;
      expect(state.property.displayPrice, 1400,
          reason: 'cheapest upcoming night from /nightly-prices');
      expect(state.property.priceWithoutDiscount, 2000);
      expect(state.property.effectiveDiscountPercent, 30);
      expect(api.nightlyPricesCalls, greaterThan(0));
    });

    test('undiscounted calendar keeps its own nightly price and no badge',
        () async {
      final api = _FakeApi();
      final cubit = await _cubit(api);

      await cubit.getPropertyDetails('aswan-1');

      final state = cubit.state as PropertyDetailsLoaded;
      expect(state.property.displayPrice, 2000,
          reason: 'calendar price wins over the stored 3000 base price');
      expect(state.property.priceWithoutDiscount, isNull);
      expect(state.property.effectiveDiscountPercent, 0);
    });
  });

  group('discount badge', () {
    test('follows the backend percentage when it matches the prices', () {
      expect(
        effectiveDiscountPercent(const {
          'pricePerNight': 1400,
          'priceWithoutDiscount': 2000,
          'discountPercent': 30,
        }),
        30,
      );
    });

    test('describes the two prices on screen when the backend disagrees', () {
      // Observed in production: a per-night calendar price discounted further
      // by a listing-level percentage, with the original left at the base.
      // "-20%" beside 2000 → 1120 reads as a bug; the real reduction is 44%.
      expect(
        effectiveDiscountPercent(const {
          'pricePerNight': 1120,
          'priceWithoutDiscount': 2000,
          'discountPercent': 20,
        }),
        44,
      );
    });

    test('stays at zero when there is no reduction', () {
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
