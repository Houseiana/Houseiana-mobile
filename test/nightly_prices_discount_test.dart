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
import 'package:houseiana_mobile_app/features/property_details/presentation/screens/nightly_prices_calendar_screen.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mirrors the live `/api/property-search/{id}/nightly-prices` contract:
/// page 1 = January of the current year, 12 pages total, `discountedPrice` +
/// `discountPercent` set on discounted nights only.
class _FakeApi implements ApiConsumer {
  final int discountMonth;
  final Set<int> discountDays;

  /// When false the `/availability` call fails, which is how the footer falls
  /// back to the nights-only total summed from the grid.
  final bool serveAvailability;

  _FakeApi({
    required this.discountMonth,
    required this.discountDays,
    this.serveAvailability = false,
  });

  @override
  Future<dynamic> get(String path,
      {Map<String, dynamic>? queryParameters, CancelToken? cancelToken}) async {
    if (path.endsWith('/booked-dates')) {
      return {'booked_Ranges': []};
    }
    if (path.endsWith('/availability')) {
      if (!serveAvailability) throw UnimplementedError('GET $path');
      // A 2-night discounted stay: 2 × 2000 listed, 2 × 1500 charged.
      return {
        'success': true,
        'isAvailable': true,
        'currency': 'EGP',
        'nights': 2,
        'pricePerNight': 2000,
        'subtotal': 3000,
        'cleaningFee': 35,
        'serviceFee': 300,
        'discount': 1000,
        'totalPrice': 3335,
      };
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

Future<void> _pumpCalendar(WidgetTester tester,
    {required Locale locale, bool serveAvailability = false}) async {
  final now = DateTime.now();
  // Discount a future window inside the currently displayed (left) month so
  // none of the discounted days are filtered out as past.
  final lastDay = DateTime(now.year, now.month + 1, 0).day;
  final discountDays = <int>{
    for (var d = now.day; d <= lastDay && d < now.day + 5; d++) d,
  };

  final api = _FakeApi(
    discountMonth: now.month,
    discountDays: discountDays,
    serveAvailability: serveAvailability,
  );
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final service =
      PropertyService(api, LookupsCache(CacheService(prefs), prefs));

  // The delegate decodes the ~130KB translation file on a background isolate,
  // which pumpAndSettle can't drive — warm the static cache first.
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
      home: BlocProvider(
        create: (_) => NightlyPricesCubit(service, 'test-property'),
        child: const NightlyPricesCalendarScreen(currency: 'EGP'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'guest date-selection calendar shows -25% badge, struck-through original '
      'and discounted nightly price (phone size, en)', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpCalendar(tester, locale: const Locale('en'));

    expect(find.text('-25%'), findsWidgets,
        reason: 'discount badge should render on discounted nights');
    expect(find.text('1.5K'), findsWidgets,
        reason: 'discounted nightly amount should render (compact format)');
    expect(find.text('2K'), findsWidgets,
        reason: 'original price should render struck through (compact format)');

    // Select a fully discounted 3-night range (today+1 .. today+4) and check
    // the footer stay total shows the struck-through original + discounted
    // totals: 3 × 2000 = 6,000 vs 3 × 1500 = 4,500. Skipped in the last few
    // days of a month, where the discounted window no longer fits before the
    // month boundary.
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    if (now.day + 4 <= lastDay) {
      await tester.tap(find.text('${now.day + 1}').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('${now.day + 4}').first);
      await tester.pumpAndSettle();

      expect(find.text('EGP 6,000'), findsOneWidget,
          reason: 'footer should show the pre-discount stay total');
      expect(find.text('EGP 4,500'), findsOneWidget,
          reason: 'footer should show the discounted stay total');
    }
  });

  testWidgets(
      'selecting a range shows the availability breakdown — cleaning and '
      'service fees included — instead of the nights-only total',
      (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    if (now.day + 3 > lastDay) return; // range doesn't fit before month end

    await _pumpCalendar(tester,
        locale: const Locale('en'), serveAvailability: true);

    await tester.tap(find.text('${now.day + 1}').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('${now.day + 3}').first);
    await tester.pumpAndSettle();

    expect(find.text('Service fee'), findsOneWidget,
        reason: 'the fee only exists in the availability quote');
    expect(find.text('EGP 300'), findsOneWidget);
    expect(find.text('Cleaning fee'), findsOneWidget);
    expect(find.text('EGP 35'), findsOneWidget);
    expect(find.text('- EGP 1000'), findsOneWidget);
    expect(find.text('EGP 3335'), findsOneWidget,
        reason: 'total = subtotal + fees, straight from the quote');
    expect(find.textContaining('Approximate prices'), findsNothing,
        reason: 'the per-night note would contradict the real quote');
  });

  testWidgets('discount badge renders on phone size in Arabic (RTL)',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpCalendar(tester, locale: const Locale('ar'));

    expect(find.text('-25%'), findsWidgets,
        reason: 'discount badge should render on discounted nights');
  });
}
