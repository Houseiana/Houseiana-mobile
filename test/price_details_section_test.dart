import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/widgets/month_calendar_widget.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/widgets/price_details_section.dart';

import 'stay_booking_harness.dart';

/// The live `/property-search/{id}/availability` quote for
/// `فيلا دورين ببرايفت بول` 28→30 Jul 2026 — the stay in the reference web
/// screenshot: 10500 × 2 nights, no cleaning fee, 2100 service fee, 23100 total.
const _quote = <String, dynamic>{
  'success': true,
  'isAvailable': true,
  'currency': 'EGP',
  'nights': 2,
  'pricePerNight': 10500,
  'subtotal': 21000,
  'cleaningFee': 0,
  'electricalFee': 0,
  'waterFee': 0,
  'serviceFee': 2100,
  'discount': null,
  'totalPrice': 23100,
};

void main() {
  testWidgets('the calendar opens inside the details page, not on a new screen',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpStaySection(tester, api: FakeStayApi(availability: _quote));

    expect(find.byType(MonthCalendarWidget), findsNothing,
        reason: 'the calendar stays collapsed until a date field is tapped');

    await openStayCalendar(tester);

    expect(find.byType(MonthCalendarWidget), findsOneWidget);
    expect(find.byType(PriceDetailsSection), findsOneWidget,
        reason: 'the booking section is still on screen — nothing was pushed');
  });

  testWidgets('picking check-in then checkout collapses the calendar again',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpStaySection(tester, api: FakeStayApi(availability: _quote));
    await selectTwoNightStay(tester);

    expect(find.byType(MonthCalendarWidget), findsNothing,
        reason: 'a complete range closes the calendar, same as the web popup');
    expect(find.text('Add date'), findsNothing,
        reason: 'both halves of the dates box now carry a date');
  });

  testWidgets('renders the service fee and total from the availability quote',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpStaySection(tester, api: FakeStayApi(availability: _quote));
    await selectTwoNightStay(tester);

    expect(find.text('10,500 EGP × 2 nights'), findsOneWidget);
    expect(find.text('21,000 EGP'), findsOneWidget);
    expect(find.text('Cleaning fee'), findsOneWidget);
    expect(find.text('Service fee'), findsOneWidget,
        reason: 'the service fee row is the whole point of this section');
    expect(find.text('2,100 EGP'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('23,100 EGP'), findsOneWidget);
  });

  testWidgets('shows the discount row only when the quote carries one',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // The Aswan listing, 29→31 Jul: 2000/night, 1400 charged on both nights.
    await pumpStaySection(
      tester,
      api: FakeStayApi(availability: const {
        'isAvailable': true,
        'nights': 2,
        'pricePerNight': 2000,
        'subtotal': 2800,
        'cleaningFee': 35,
        'serviceFee': 280,
        'discount': 1200,
        'totalPrice': 3115,
      }),
    );
    await selectTwoNightStay(tester);

    expect(find.text('Discount'), findsOneWidget);
    expect(find.text('- 1,200 EGP'), findsOneWidget);
    expect(find.text('280 EGP'), findsOneWidget);
    expect(find.text('3,115 EGP'), findsOneWidget);
    expect(find.text('Platform fee'), findsNothing,
        reason: 'the quote carries no platformCommission');
  });

  testWidgets('asks for dates before showing any amount', (tester) async {
    await pumpStaySection(tester, api: FakeStayApi(availability: _quote));

    expect(
        find.text(
            'Pick your dates to see the full price, including the service fee.'),
        findsOneWidget);
    expect(find.text('Service fee'), findsNothing);
    expect(find.text('Add date'), findsNWidgets(2));
  });

  testWidgets('says so when the dates are not available', (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpStaySection(
      tester,
      api: FakeStayApi(availability: const {'isAvailable': false}),
    );
    await selectTwoNightStay(tester);

    expect(find.text('This property is not available for the selected dates.'),
        findsOneWidget);
    expect(find.text('Service fee'), findsNothing);
  });

  testWidgets('announces the minimum stay up front and warns when short',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpStaySection(
      tester,
      api: FakeStayApi(availability: _quote),
      minNights: 3,
    );

    expect(find.text('Minimum stay: 3 nights'), findsOneWidget,
        reason: 'the guest should know before picking, not at reserve time');

    await selectTwoNightStay(tester);

    expect(
        find.text('You picked 2 nights — this place takes a minimum of 3.'),
        findsOneWidget);
  });

  testWidgets('no minimum-stay notice when the host accepts single nights',
      (tester) async {
    await pumpStaySection(
      tester,
      api: FakeStayApi(availability: _quote),
      minNights: 1,
    );

    expect(find.textContaining('Minimum stay'), findsNothing);
  });

  testWidgets('reassures the guest they are not charged yet', (tester) async {
    await pumpStaySection(tester, api: FakeStayApi(availability: _quote));

    expect(find.text("You won't be charged yet"), findsOneWidget);
  });

  testWidgets('renders in Arabic (RTL)', (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpStaySection(
      tester,
      api: FakeStayApi(availability: _quote),
      locale: const Locale('ar'),
    );
    await selectTwoNightStay(tester);

    expect(find.text('رسوم الخدمة'), findsOneWidget);
    expect(find.text('2,100 EGP'), findsOneWidget);
    expect(find.text('الإجمالي'), findsOneWidget);
  });
}
