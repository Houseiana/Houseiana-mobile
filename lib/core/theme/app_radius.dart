import 'package:flutter/material.dart';

/// Unified border radius system for consistent design
class AppRadius {
  AppRadius._();

  // Border radius values
  static const double none = 0.0;
  static const double xs = 4.0;    // Micro elements (badges, small tags)
  static const double sm = 6.0;    // Small elements (chips, small buttons)
  static const double md = 8.0;    // Medium elements (inputs, small cards)
  static const double lg = 12.0;   // Large elements (cards, buttons, inputs)
  static const double xl = 16.0;   // Extra large elements (large cards, sheets)
  static const double xxl = 20.0;  // Double extra large (modals, dialogs)
  static const double xxxl = 24.0; // Triple extra large (bottom sheets)
  static const double full = 999.0; // Full round (avatars, FABs)

  // Specific radius for common use cases
  static const double buttonRadius = lg;         // 12dp - buttons
  static const double cardRadius = xl;           // 16dp - cards
  static const double inputRadius = md;          // 8dp - input fields
  static const double chipRadius = full;          // pill shape - chips
  static const double badgeRadius = xs;          // 4dp - badges
  static const double avatarRadius = full;       // circular - avatars
  static const double bottomSheetRadius = xxl;   // 20dp - bottom sheets
  static const double searchBarRadius = 40.0;    // pill shape - search bars
  static const double containerRadius = lg;      // 12dp - containers

  // BorderRadius helpers
  static const BorderRadius radiusNone = BorderRadius.all(radiusAllnone);
  static const BorderRadius radiusXs = BorderRadius.all(radiusAllxs);
  static const BorderRadius radiusSm = BorderRadius.all(radiusAllsm);
  static const BorderRadius radiusMd = BorderRadius.all(radiusAllmd);
  static const BorderRadius radiusLg = BorderRadius.all(radiusAlllg);
  static const BorderRadius radiusXl = BorderRadius.all(radiusAllxl);
  static const BorderRadius radiusXxl = BorderRadius.all(radiusAllxxl);
  static const BorderRadius radiusXxxl = BorderRadius.all(radiusAllxxxl);
  static const BorderRadius radiusFull = BorderRadius.all(radiusAllfull);

  // Specific BorderRadius
  static const BorderRadius buttonRadiusAll = BorderRadius.all(radiusAlllg);
  static const BorderRadius cardRadiusAll = BorderRadius.all(radiusAllxl);
  static const BorderRadius inputRadiusAll = BorderRadius.all(radiusAllmd);
  static const BorderRadius chipRadiusAll = BorderRadius.all(radiusAllfull);
  static const BorderRadius badgeRadiusAll = BorderRadius.all(radiusAllxs);
  static const BorderRadius bottomSheetRadiusAll = BorderRadius.all(radiusAllxxl);
  static const BorderRadius searchBarRadiusAll = BorderRadius.all(radiusAllsearchBar);

  // BorderRadius.all shortcuts
  static const Radius radiusAllnone = Radius.circular(none);
  static const Radius radiusAllxs = Radius.circular(xs);
  static const Radius radiusAllsm = Radius.circular(sm);
  static const Radius radiusAllmd = Radius.circular(md);
  static const Radius radiusAlllg = Radius.circular(lg);
  static const Radius radiusAllxl = Radius.circular(xl);
  static const Radius radiusAllxxl = Radius.circular(xxl);
  static const Radius radiusAllxxxl = Radius.circular(xxxl);
  static const Radius radiusAllfull = Radius.circular(full);
  static const Radius radiusAllsearchBar = Radius.circular(searchBarRadius);

  // Vertical radius (top only for cards)
  static BorderRadius cardTopRadius = const BorderRadius.vertical(
    top: radiusAllxl,
    bottom: Radius.zero,
  );

  static BorderRadius buttonTopRadius = const BorderRadius.vertical(
    top: radiusAlllg,
    bottom: Radius.zero,
  );

  static BorderRadius bottomSheetTopRadius = const BorderRadius.vertical(
    top: radiusAllxxl,
    bottom: Radius.zero,
  );
}
