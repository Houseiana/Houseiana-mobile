import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/shared/widgets/common/enhanced_buttons.dart';

/// A filled *neutral* call-to-action has to read as a button on the surface it
/// sits on. `AppColors.brandCharcoal` is the exact value of the dark-mode
/// `cardBackground`, so the charcoal buttons inside the host calendar's
/// "Manage dates" sheet ("Block this date", "Apply X% discount") painted
/// charcoal-on-charcoal and looked like plain lines of text.
///
/// `ctaBackground` / `ctaForeground` invert in dark mode instead. These tests
/// pin that they keep a real plate under them, disabled included.

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  tearDown(() => AppColors.setDark(false));

  test('the CTA fill stands off every surface it sits on — dark', () {
    AppColors.setDark(true);
    for (final surface in [
      AppColors.cardBackground,
      AppColors.scaffoldBackground,
      AppColors.ghostWhite,
    ]) {
      expect(_contrast(AppColors.ctaBackground, surface), greaterThan(3.0));
    }
  });

  test('the CTA fill stands off every surface it sits on — light', () {
    AppColors.setDark(false);
    for (final surface in [
      AppColors.cardBackground,
      AppColors.scaffoldBackground,
      AppColors.ghostWhite,
    ]) {
      expect(_contrast(AppColors.ctaBackground, surface), greaterThan(3.0));
    }
  });

  test('the CTA label reads on its own fill in both themes', () {
    for (final dark in [false, true]) {
      AppColors.setDark(dark);
      expect(
        _contrast(AppColors.ctaForeground, AppColors.ctaBackground),
        greaterThan(4.5),
      );
    }
  });

  testWidgets('a disabled PrimaryButton keeps a visible plate', (tester) async {
    AppColors.setDark(true);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: AppColors.cardBackground,
          body: Center(
            child: PrimaryButton(
              text: 'Apply 0% discount',
              backgroundColor: AppColors.ctaBackground,
              textColor: AppColors.ctaForeground,
              onPressed: null,
            ),
          ),
        ),
      ),
    );

    final box = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(PrimaryButton),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final fill = (box.decoration! as BoxDecoration).color!;

    // Dimmed…
    expect(fill.a, lessThan(1.0));
    // …but still a plate the eye separates from the sheet behind it.
    expect(
      _contrast(
        Color.alphaBlend(fill, AppColors.cardBackground),
        AppColors.cardBackground,
      ),
      greaterThan(1.6),
    );
  });
}
