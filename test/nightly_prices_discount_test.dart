import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'stay_booking_harness.dart';

/// The nightly grid inside the details page: discounted nights carry a `-25%`
/// badge, the struck-through original and the charged amount, and the stay
/// total falls back to the summed nightly prices when `/availability` fails.
void main() {
  testWidgets(
      'inline calendar shows -25% badge, struck-through original '
      'and discounted nightly price (phone size, en)', (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final now = DateTime.now();
    await pumpStaySection(
      tester,
      api: FakeStayApi(
        discountMonth: now.month,
        discountDays: futureDiscountDays(),
      ),
    );
    await openStayCalendar(tester);

    expect(find.text('-25%'), findsWidgets,
        reason: 'discount badge should render on discounted nights');
    expect(find.text('1.5K'), findsWidgets,
        reason: 'discounted nightly amount should render (compact format)');
    expect(find.text('2K'), findsWidgets,
        reason: 'original price should render struck through (compact format)');

    // Select a fully discounted 3-night range (today+1 .. today+4) and check
    // the stay total shows the struck-through original next to the discounted
    // total: 3 × 2000 = 6,000 vs 3 × 1500 = 4,500. `/availability` is not
    // served here, so this is the nights-only fallback. Skipped in the last few
    // days of a month, where the discounted window no longer fits before the
    // month boundary.
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    if (now.day + 4 <= lastDay) {
      await tapStayDays(tester, now.day + 1, now.day + 4);

      expect(find.text('6,000 EGP'), findsOneWidget,
          reason: 'should show the pre-discount stay total');
      expect(find.text('4,500 EGP'), findsOneWidget,
          reason: 'should show the discounted stay total');
    }
  });

  testWidgets(
      'selecting a range shows the availability breakdown — cleaning and '
      'service fees included — instead of the nights-only total',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final now = DateTime.now();
    await pumpStaySection(
      tester,
      api: FakeStayApi(
        discountMonth: now.month,
        discountDays: futureDiscountDays(),
        // A 2-night discounted stay: 2 × 2000 listed, 2 × 1500 charged.
        availability: const {
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
        },
      ),
    );
    await selectTwoNightStay(tester);

    expect(find.text('Service fee'), findsOneWidget,
        reason: 'the fee only exists in the availability quote');
    expect(find.text('300 EGP'), findsOneWidget);
    expect(find.text('Cleaning fee'), findsOneWidget);
    expect(find.text('35 EGP'), findsOneWidget);
    expect(find.text('- 1,000 EGP'), findsOneWidget);
    expect(find.text('3,335 EGP'), findsOneWidget,
        reason: 'total = subtotal + fees, straight from the quote');
    expect(find.textContaining('Approximate prices'), findsNothing,
        reason: 'the per-night note lives in the calendar, which has closed');
  });

  testWidgets('discount badge renders on phone size in Arabic (RTL)',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final now = DateTime.now();
    await pumpStaySection(
      tester,
      api: FakeStayApi(
        discountMonth: now.month,
        discountDays: futureDiscountDays(),
      ),
      locale: const Locale('ar'),
    );
    await openStayCalendar(tester);

    expect(find.text('-25%'), findsWidgets,
        reason: 'discount badge should render on discounted nights');
  });
}
