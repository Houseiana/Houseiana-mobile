import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/widgets/price_details_section.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

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

Future<void> _pump(
  WidgetTester tester, {
  Map<String, dynamic>? availability,
  DateTime? checkIn,
  DateTime? checkOut,
  bool isLoading = false,
  Locale locale = const Locale('en'),
}) async {
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
          child: PriceDetailsSection(
            currency: 'EGP',
            checkIn: checkIn,
            checkOut: checkOut,
            availability: availability,
            isLoading: isLoading,
            onPickDates: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the service fee and total from the availability quote',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      availability: _quote,
      checkIn: DateTime(2026, 7, 28),
      checkOut: DateTime(2026, 7, 30),
    );

    expect(find.text('EGP 10500 × 2 nights'), findsOneWidget);
    expect(find.text('EGP 21000'), findsOneWidget);
    expect(find.text('Cleaning fee'), findsOneWidget);
    expect(find.text('Service fee'), findsOneWidget,
        reason: 'the service fee row is the whole point of this section');
    expect(find.text('EGP 2100'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('EGP 23100'), findsOneWidget);
  });

  testWidgets('shows the discount row only when the quote carries one',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // The Aswan listing, 29→31 Jul: 2000/night, 1400 charged on both nights.
    await _pump(
      tester,
      availability: const {
        'isAvailable': true,
        'nights': 2,
        'pricePerNight': 2000,
        'subtotal': 2800,
        'cleaningFee': 35,
        'serviceFee': 280,
        'discount': 1200,
        'totalPrice': 3115,
      },
      checkIn: DateTime(2026, 7, 29),
      checkOut: DateTime(2026, 7, 31),
    );

    expect(find.text('Discount'), findsOneWidget);
    expect(find.text('- EGP 1200'), findsOneWidget);
    expect(find.text('EGP 280'), findsOneWidget);
    expect(find.text('EGP 3115'), findsOneWidget);
    expect(find.text('Platform fee'), findsNothing,
        reason: 'the quote carries no platformCommission');
  });

  testWidgets('asks for dates before showing any amount', (tester) async {
    await _pump(tester);

    expect(
        find.text(
            'Pick your dates to see the full price, including the service fee.'),
        findsOneWidget);
    expect(find.text('Service fee'), findsNothing);
    expect(find.text('Add date'), findsNWidgets(2));
  });

  testWidgets('says so when the dates are not available', (tester) async {
    await _pump(
      tester,
      availability: const {'isAvailable': false},
      checkIn: DateTime(2026, 7, 28),
      checkOut: DateTime(2026, 7, 30),
    );

    expect(find.text('This property is not available for the selected dates.'),
        findsOneWidget);
    expect(find.text('Service fee'), findsNothing);
  });

  testWidgets('renders in Arabic (RTL)', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      availability: _quote,
      checkIn: DateTime(2026, 7, 28),
      checkOut: DateTime(2026, 7, 30),
      locale: const Locale('ar'),
    );

    expect(find.text('رسوم الخدمة'), findsOneWidget);
    expect(find.text('EGP 2100'), findsOneWidget);
    expect(find.text('الإجمالي'), findsOneWidget);
  });
}
