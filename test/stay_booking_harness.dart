import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/services/cache_service.dart';
import 'package:houseiana_mobile_app/core/services/lookups_cache.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/cubit/nightly_prices_cubit.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/widgets/price_details_section.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Test harness for the booking section on the property details screen — the
/// dates box, the calendar that opens inside it, and the price breakdown.
///
/// The section drives everything through [NightlyPricesCubit], so the tests go
/// through the same door a guest does: open the calendar, tap two days, read
/// the rows. Nothing is injected past the API boundary.

/// Mirrors the live `/api/property-search/{id}/nightly-prices` contract:
/// page 1 = January of the current year, 12 pages total, `discountedPrice` +
/// `discountPercent` set on discounted nights only.
class FakeStayApi implements ApiConsumer {
  final int discountMonth;
  final Set<int> discountDays;

  /// `/availability` response. When null the call fails, which is how the
  /// section falls back to the nights-only total summed from the grid.
  final Map<String, dynamic>? availability;

  FakeStayApi({
    this.discountMonth = 0,
    this.discountDays = const {},
    this.availability,
  });

  @override
  Future<dynamic> get(String path,
      {Map<String, dynamic>? queryParameters, CancelToken? cancelToken}) async {
    if (path.endsWith('/booked-dates')) {
      return {'booked_Ranges': []};
    }
    if (path.endsWith('/availability')) {
      final avail = availability;
      if (avail == null) throw UnimplementedError('GET $path');
      return avail;
    }
    if (path.endsWith('/nightly-prices')) {
      final page = (queryParameters?['page'] as num? ?? 1).toInt();
      final year = DateTime.now().year;
      final month = page; // page 1 = January (matches production)
      final daysInMonth = DateTime(year, month + 1, 0).day;
      final data = List.generate(daysInMonth, (i) {
        final day = i + 1;
        final discounted = month == discountMonth && discountDays.contains(day);
        return {
          'date':
              '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
          'price': 2000,
          'isSpecialPrice': false,
          'discountPercent': discounted ? 25 : null,
          'discountedPrice': discounted ? 1500 : null,
        };
      });
      return {
        'success': true,
        'data': data,
        'page': page,
        'totalPages': 12,
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

/// Days of the current month that [FakeStayApi] should discount: a future
/// window inside the displayed month, so none of them is filtered out as past.
Set<int> futureDiscountDays({int length = 5}) {
  final now = DateTime.now();
  final lastDay = DateTime(now.year, now.month + 1, 0).day;
  return {
    for (var d = now.day; d <= lastDay && d < now.day + length; d++) d,
  };
}

Future<void> pumpStaySection(
  WidgetTester tester, {
  required FakeStayApi api,
  Locale locale = const Locale('en'),
  int? minNights,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final service =
      PropertyService(api, LookupsCache(CacheService(prefs), prefs));

  // The delegate decodes the ~130KB translation file on a background isolate,
  // which pumpAndSettle can't drive — warm the static cache first so the
  // delegate resolves within the pumped frames.
  await tester.runAsync(
      () => AppLocalizations.load(AppLocale.fromCode(locale.languageCode)));

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: SingleChildScrollView(
          child: BlocProvider(
            create: (_) => NightlyPricesCubit(service, 'test-property'),
            child: PriceDetailsSection(
              currency: 'EGP',
              minNights: minNights,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Taps the check-in half, which is how the calendar opens on the details page.
Future<void> openStayCalendar(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('stayField.checkIn')));
  await tester.pumpAndSettle();
}

/// Picks `checkIn`..`checkOut` by day-of-month in the displayed month. The
/// calendar must already be open.
Future<void> tapStayDays(
    WidgetTester tester, int checkInDay, int checkOutDay) async {
  await tester.tap(find.text('$checkInDay').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('$checkOutDay').first);
  await tester.pumpAndSettle();
}

/// Picks any valid 2-night stay, rolling into next month when today is too
/// close to the month boundary for the range to fit — so the assertions that
/// follow always run instead of silently skipping at the end of a month.
Future<void> selectTwoNightStay(WidgetTester tester) async {
  await openStayCalendar(tester);
  final now = DateTime.now();
  final lastDay = DateTime(now.year, now.month + 1, 0).day;
  if (now.day + 3 <= lastDay) {
    await tapStayDays(tester, now.day + 1, now.day + 3);
    return;
  }
  // Second IconButton in the panel = next month, in both LTR and RTL.
  await tester.tap(find.byType(IconButton).at(1));
  await tester.pumpAndSettle();
  await tapStayDays(tester, 2, 4);
}
