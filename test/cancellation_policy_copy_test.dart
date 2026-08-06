import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/widgets/things_to_know_widget.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

/// The free-cancellation window counts back from **check-in**, never from the
/// booking date. The old copy ("Free cancellation for 5 days" / "إلغاء مجاني
/// لمدة 5 أيام") read as five days after booking — these tests pin the wording
/// that says which end of the stay the window hangs off.

Future<void> _pumpPolicyTab(
  WidgetTester tester, {
  required String policy,
  DateTime? deadline,
  Locale locale = const Locale('en'),
}) async {
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
        body: ThingsToKnowWidget(
          cancellationPolicy: policy,
          cancellationDeadline: deadline,
          hasCancellationWindow: true,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  // The policy tab is the third of the three "Things to know" tabs.
  await tester.tap(find.byType(Tab).at(2));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the window is stated relative to check-in, not to booking',
      (tester) async {
    await _pumpPolicyTab(
      tester,
      policy: 'Free cancellation until 5 days before check-in',
    );

    expect(find.text('Free cancellation until 5 days before check-in'),
        findsOneWidget);
    expect(find.text('After that deadline, cancelling is non-refundable.'),
        findsOneWidget);
  });

  testWidgets('Arabic states the window relative to check-in', (tester) async {
    await _pumpPolicyTab(
      tester,
      policy: 'إلغاء مجاني حتى 5 أيام قبل تسجيل الوصول',
      locale: const Locale('ar'),
    );

    expect(find.text('إلغاء مجاني حتى 5 أيام قبل تسجيل الوصول'), findsOneWidget);
    expect(find.text('بعد هذا الموعد، لن يتم استرداد أي مبلغ في حال الإلغاء.'),
        findsOneWidget);
  });

  testWidgets('a picked stay spells the deadline out as a date',
      (tester) async {
    await _pumpPolicyTab(
      tester,
      policy: 'Free cancellation until 5 days before check-in',
      deadline: DateTime(2026, 9, 12),
    );

    expect(find.text('For your dates: cancel for free until September 12, 2026'),
        findsOneWidget);
  });

  testWidgets('no deadline line before the guest picks dates', (tester) async {
    await _pumpPolicyTab(
      tester,
      policy: 'Free cancellation until 5 days before check-in',
    );

    expect(find.textContaining('For your dates'), findsNothing,
        reason: 'without a check-in date there is no deadline to name');
  });
}
