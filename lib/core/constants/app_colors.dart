import 'package:flutter/material.dart';

/// Light-mode values for the brightness-aware tokens.
///
/// [lightTheme] references this class directly: both `ThemeData` objects are
/// built once per process (app.dart) — before any brightness flag is set — so
/// they must never read the [AppColors] getters.
class AppColorsLight {
  AppColorsLight._();

  static const Color charcoal = Color(0xFF1D242B);
  static const Color ghostWhite = Color(0xFFF9F9FA);
  static const Color neutral50 = ghostWhite;
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFE5E7EB);
  static const Color neutral300 = Color(0xFFD1D5DB);
  static const Color neutral400 = Color(0xFF9CA3AF);
  static const Color neutral500 = Color(0xFF6B7280);
  static const Color neutral600 = Color(0xFF4B5563);
  static const Color neutral700 = Color(0xFF374151);

  static const Color scaffoldBackground = Color(0xFFF5F5F5);
  static const Color cardBackground = Color(0xFFFFFFFF);

  static const Color ctaBackground = Color(0xFF1D242B);
  static const Color ctaForeground = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

  static const Color divider = Color(0xFFBDBDBD);

  static const Color skeletonBaseColor = Color(0xFFE8E8E8);
  static const Color skeletonHighlightColor = Color(0xFFF5F5F5);
}

/// Dark-mode values for the brightness-aware tokens.
///
/// The neutral ramp keeps the cool blue tint of the brand charcoal (#1D242B)
/// so the brand yellow reads warm against every surface. All text pairings
/// clear WCAG AA against their intended background.
class AppColorsDark {
  AppColorsDark._();

  static const Color charcoal = Color(0xFFF4F6F8);
  static const Color ghostWhite = Color(0xFF232A32);
  static const Color neutral50 = ghostWhite;
  static const Color neutral100 = Color(0xFF262E37);
  static const Color neutral200 = Color(0xFF313A44);
  static const Color neutral300 = Color(0xFF3A4552);
  static const Color neutral400 = Color(0xFF8A95A1);
  static const Color neutral500 = Color(0xFF9AA5B1);
  static const Color neutral600 = Color(0xFFB8C1CB);
  static const Color neutral700 = Color(0xFFCDD5DD);

  static const Color scaffoldBackground = Color(0xFF15181C);
  static const Color cardBackground = Color(0xFF1D242B);

  // The brand charcoal is the exact value of [cardBackground] here, so a dark
  // filled button would vanish into the surface it sits on and read as plain
  // text. The neutral CTA inverts to a near-white plate instead.
  static const Color ctaBackground = Color(0xFFF4F6F8);
  static const Color ctaForeground = Color(0xFF1D242B);

  static const Color textPrimary = Color(0xFFF4F6F8);
  static const Color textSecondary = Color(0xFFA6B0BB);

  static const Color divider = Color(0xFF313A44);

  static const Color skeletonBaseColor = Color(0xFF2C2C2C);
  static const Color skeletonHighlightColor = Color(0xFF383838);
}

/// The app-wide palette.
///
/// Surface / text / neutral tokens are **brightness-aware getters** that read
/// [isDark]; the flag is set from `MaterialApp.builder` in `app.dart` from the
/// resolved theme brightness, so it also covers `ThemeMode.system`.
///
/// Two rules keep this working:
/// * never reference one of the getters inside a `const` expression;
/// * never instantiate an app widget with `const` — a canonicalised const
///   instance is skipped by `Element.updateChild`, so it would keep the colors
///   of the previous theme.
///
/// Brand and status colors stay `const`: they are the same in both themes.
class AppColors {
  AppColors._();

  static bool _dark = false;

  /// Whether the resolved theme is dark. Read by the getters below.
  static bool get isDark => _dark;

  /// Set from `HouseianaApp`'s `MaterialApp.builder` (and from test setUp).
  /// Nothing else should call this.
  static void setDark(bool value) => _dark = value;

  // ---------------------------------------------------------------
  // Brand colors — identical in both themes.
  // ---------------------------------------------------------------
  static const Color bioYellow = Color(0xFFFCC519);
  static const Color primaryColor = bioYellow; // Houseiana brand yellow
  static const Color primaryLight = Color(0xFFFDD835);
  static const Color primaryDark = Color(0xFFF9A825);

  /// The brand charcoal as a *fixed* value. Use this — not [charcoal] — for
  /// anything that must stay dark in both themes: text/icons sitting on the
  /// brand yellow, deliberately dark backgrounds (buttons, chips over photos),
  /// and the splash screen.
  static const Color brandCharcoal = Color(0xFF1D242B);

  static const Color secondaryColor = Color(0xFF26A69A);
  static const Color secondaryLight = Color(0xFF64D8CB);
  static const Color secondaryDark = Color(0xFF00766C);

  // ---------------------------------------------------------------
  // Status colors — identical in both themes.
  // ---------------------------------------------------------------
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);

  /// Discount badges. They sit on property photos, so they never flip.
  static const Color discountRed = Color(0xFFD00416);

  /// Filled wishlist hearts. They sit on photos / white chips.
  static const Color heartRed = Color(0xFFEF4444);

  // ---------------------------------------------------------------
  // Fixed neutrals.
  // ---------------------------------------------------------------
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color shadow = Color(0x1A000000);
  static const Color transparent = Colors.transparent;

  // ---------------------------------------------------------------
  // Brightness-aware tokens.
  // ---------------------------------------------------------------
  static Color get charcoal =>
      _dark ? AppColorsDark.charcoal : AppColorsLight.charcoal;
  static Color get ghostWhite =>
      _dark ? AppColorsDark.ghostWhite : AppColorsLight.ghostWhite;
  static Color get neutral50 =>
      _dark ? AppColorsDark.neutral50 : AppColorsLight.neutral50;
  static Color get neutral100 =>
      _dark ? AppColorsDark.neutral100 : AppColorsLight.neutral100;
  static Color get neutral200 =>
      _dark ? AppColorsDark.neutral200 : AppColorsLight.neutral200;
  static Color get neutral300 =>
      _dark ? AppColorsDark.neutral300 : AppColorsLight.neutral300;
  static Color get neutral400 =>
      _dark ? AppColorsDark.neutral400 : AppColorsLight.neutral400;
  static Color get neutral500 =>
      _dark ? AppColorsDark.neutral500 : AppColorsLight.neutral500;
  static Color get neutral600 =>
      _dark ? AppColorsDark.neutral600 : AppColorsLight.neutral600;
  static Color get neutral700 =>
      _dark ? AppColorsDark.neutral700 : AppColorsLight.neutral700;

  static Color get scaffoldBackground => _dark
      ? AppColorsDark.scaffoldBackground
      : AppColorsLight.scaffoldBackground;
  static Color get cardBackground =>
      _dark ? AppColorsDark.cardBackground : AppColorsLight.cardBackground;

  /// Fill / label of a filled **neutral** call-to-action -- the dark button the
  /// design uses next to the brand-yellow [primaryColor] one (block a date,
  /// edit a listing, contact the host ...).
  ///
  /// Never use [brandCharcoal] for one of these: in dark mode it is the exact
  /// value of [cardBackground], so the button disappears into the card it sits
  /// on and looks like a line of text. This pair inverts instead.
  static Color get ctaBackground =>
      _dark ? AppColorsDark.ctaBackground : AppColorsLight.ctaBackground;
  static Color get ctaForeground =>
      _dark ? AppColorsDark.ctaForeground : AppColorsLight.ctaForeground;

  static Color get textPrimary =>
      _dark ? AppColorsDark.textPrimary : AppColorsLight.textPrimary;
  static Color get textSecondary =>
      _dark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary;

  static Color get divider =>
      _dark ? AppColorsDark.divider : AppColorsLight.divider;

  static Color get skeletonBaseColor => _dark
      ? AppColorsDark.skeletonBaseColor
      : AppColorsLight.skeletonBaseColor;
  static Color get skeletonHighlightColor => _dark
      ? AppColorsDark.skeletonHighlightColor
      : AppColorsLight.skeletonHighlightColor;
}
