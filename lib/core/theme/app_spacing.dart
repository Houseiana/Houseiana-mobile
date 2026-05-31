import 'package:flutter/material.dart';

/// Unified spacing system for consistent design across the app
class AppSpacing {
  AppSpacing._();

  // Base spacing unit (4dp grid system)
  static const double unit = 4.0;

  // Spacing values
  static const double xxs = 2.0;   // 2dp - micro spacing
  static const double xs = 4.0;    // 4dp - extra small
  static const double sm = 8.0;    // 8dp - small
  static const double md = 12.0;   // 12dp - medium
  static const double lg = 16.0;   // 16dp - large
  static const double xl = 20.0;   // 20dp - extra large
  static const double xxl = 24.0;  // 24dp - double extra large
  static const double xxxl = 32.0;  // 32dp - triple extra large
  static const double huge = 40.0;  // 40dp - huge
  static const double massive = 48.0; // 48dp - massive

  // Specific spacing for common use cases
  static const double screenPadding = 20.0;
  static const double cardPadding = 16.0;
  static const double sectionGap = 24.0;
  static const double itemGap = 12.0;
  static const double iconGap = 8.0;

  // EdgeInsets helpers
  static const EdgeInsets paddingAllXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingAllSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingAllMd = EdgeInsets.all(md);
  static const EdgeInsets paddingAllLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingAllXl = EdgeInsets.all(xl);

  static const EdgeInsets paddingScreen = EdgeInsets.all(screenPadding);
  static const EdgeInsets paddingCard = EdgeInsets.all(cardPadding);

  static const EdgeInsets horizontalScreen = EdgeInsets.symmetric(horizontal: screenPadding);
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);

  static const EdgeInsets verticalScreen = EdgeInsets.symmetric(vertical: screenPadding);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);

  static const EdgeInsets onlyLeftScreen = EdgeInsets.only(left: screenPadding);
  static const EdgeInsets onlyRightScreen = EdgeInsets.only(right: screenPadding);
  static const EdgeInsets onlyTopScreen = EdgeInsets.only(top: screenPadding);
  static const EdgeInsets onlyBottomScreen = EdgeInsets.only(bottom: screenPadding);

  // SizedBox helpers
  static const SizedBox verticalSpaceXs = SizedBox(height: xs);
  static const SizedBox verticalSpaceSm = SizedBox(height: sm);
  static const SizedBox verticalSpaceMd = SizedBox(height: md);
  static const SizedBox verticalSpaceLg = SizedBox(height: lg);
  static const SizedBox verticalSpaceXl = SizedBox(height: xl);
  static const SizedBox verticalSpaceXxl = SizedBox(height: xxl);
  static const SizedBox verticalSpaceXxxl = SizedBox(height: xxxl);

  static const SizedBox horizontalSpaceXs = SizedBox(width: xs);
  static const SizedBox horizontalSpaceSm = SizedBox(width: sm);
  static const SizedBox horizontalSpaceMd = SizedBox(width: md);
  static const SizedBox horizontalSpaceLg = SizedBox(width: lg);
  static const SizedBox horizontalSpaceXl = SizedBox(width: xl);

  static const SizedBox screenVerticalGap = SizedBox(height: screenPadding);
  static const SizedBox cardVerticalGap = SizedBox(height: cardPadding);
  static const SizedBox sectionVerticalGap = SizedBox(height: sectionGap);
  static const SizedBox itemVerticalGap = SizedBox(height: itemGap);
}
