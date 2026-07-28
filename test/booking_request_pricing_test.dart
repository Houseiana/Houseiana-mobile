import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/services/cache_service.dart';
import 'package:houseiana_mobile_app/core/services/favorites_notifier.dart';
import 'package:houseiana_mobile_app/core/services/lookups_cache.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/booking/cubit/booking_cubit.dart';
import 'package:houseiana_mobile_app/features/booking/presentation/screens/booking_request_screen.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Availability payload mirroring the live
/// `/api/property-search/{id}/availability` response for a range whose nights
/// are discounted (250 → 200/night for 3 nights): the subtotal is already
/// discounted and `discount` carries the total savings.
class _FakeApi implements ApiConsumer {
  @override
  Future<dynamic> get(String path,
      {Map<String, dynamic>? queryParameters, CancelToken? cancelToken}) async {
    if (path.endsWith('/availability')) {
      return {
        'success': true,
        'isAvailable': true,
        'currency': 'EGP',
        'nights': 3,
        'pricePerNight': 250,
        'subtotal': 600,
        'cleaningFee': 30,
        'electricalFee': 10,
        'waterFee': 10,
        'serviceFee': 60,
        'discount': 150,
        'discountType': null,
        'totalPrice': 690,
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

void main() {
  testWidgets(
      'price breakdown reflects the selected dates\' discount from the '
      'availability API, not the listing\'s price of today', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    // Pre-warm the JSON translations so the localization delegate resolves
    // from cache during pumpAndSettle — the asset load is real IO, so it must
    // run inside runAsync (it never completes in the fake-async test zone).
    await tester.runAsync(() => AppLocalizations.load(AppLocale.en));

    final api = _FakeApi();
    final cache = CacheService(prefs);
    final lookups = LookupsCache(cache, prefs);
    final propertyService = PropertyService(api, lookups);
    if (sl.isRegistered<PropertyService>()) {
      sl.unregister<PropertyService>();
    }
    sl.registerSingleton<PropertyService>(propertyService);
    addTearDown(() => sl.unregister<PropertyService>());

    final cubit = BookingCubit(
      UserService(api, cache, lookups, FavoritesNotifier()),
      propertyService,
      UserSession(prefs),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [AppLocalizationsDelegate()],
        onGenerateRoute: (settings) => MaterialPageRoute(
          settings: RouteSettings(
            name: settings.name,
            // The listing-level price of today (240) differs from the selected
            // dates' rates on purpose — the breakdown must use the latter.
            arguments: {
              'propertyId': 'test-property',
              'property': <String, dynamic>{
                'currency': 'EGP',
                'pricePerNight': 240,
                'priceWithoutDiscount': 240,
              },
              'price': 240,
              'title': 'Test property',
              'checkIn': '2026-08-01T00:00:00.000',
              'checkOut': '2026-08-04T00:00:00.000',
            },
          ),
          builder: (_) => BlocProvider.value(
            value: cubit,
            child: const BookingRequestScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('750 EGP'), findsOneWidget,
        reason: 'nights row should show the pre-discount subtotal '
            '(availability pricePerNight 250 × 3)');
    expect(find.text('- 150 EGP'), findsOneWidget,
        reason: 'discount row should show the availability discount');
    expect(find.text('690 EGP'), findsWidgets,
        reason: 'total should be the availability totalPrice '
            '(600 + 30 + 60), not 240 × 3 + fees');
    expect(find.text('720 EGP'), findsNothing,
        reason: 'the today-price subtotal (240 × 3) must not be used');
  });
}
