import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';

/// The colors a theme needs, gathered in one place.
///
/// Both themes are built by [buildTheme] from one of these, so a component
/// styled in one theme can never be left unstyled in the other.
@immutable
class ThemePalette {
  const ThemePalette({
    required this.brightness,
    required this.scaffoldBackground,
    required this.surface,
    required this.elevatedSurface,
    required this.inputFill,
    required this.textPrimary,
    required this.textSecondary,
    required this.hint,
    required this.unselected,
    required this.divider,
    required this.border,
    required this.appBarBackground,
    required this.appBarForeground,
    required this.snackBarBackground,
    required this.snackBarForeground,
    required this.cardElevation,
    this.cardBorder,
  });

  final Brightness brightness;

  /// Page background.
  final Color scaffoldBackground;

  /// Cards and other resting surfaces.
  final Color surface;

  /// Surfaces that float above the page: dialogs, bottom sheets, menus.
  final Color elevatedSurface;

  final Color inputFill;
  final Color textPrimary;
  final Color textSecondary;
  final Color hint;

  /// Unselected tabs / nav items / control tracks.
  final Color unselected;

  final Color divider;

  /// Input and outlined-button borders.
  final Color border;

  final Color appBarBackground;
  final Color appBarForeground;

  /// Snack bars invert the surface in both themes.
  final Color snackBarBackground;
  final Color snackBarForeground;

  final double cardElevation;

  /// Dark cards separate by hairline border instead of a shadow, which is
  /// invisible on a dark background.
  final Color? cardBorder;

  bool get isDark => brightness == Brightness.dark;
}

/// Shared shape/metric constants so both themes stay dimensionally identical.
const double _radiusSm = 8;
const double _radiusMd = 12;
const double _radiusLg = 16;

ThemeData buildTheme(ThemePalette p) {
  final colorScheme = ColorScheme(
    brightness: p.brightness,
    primary: AppColors.primaryColor,
    onPrimary: AppColors.brandCharcoal,
    secondary: p.isDark ? AppColors.secondaryLight : AppColors.secondaryColor,
    onSecondary: AppColors.brandCharcoal,
    error: AppColors.error,
    onError: AppColors.textLight,
    surface: p.surface,
    onSurface: p.textPrimary,
  ).copyWith(
    // Pin the M3 container/outline roles: left unset they fall back to the
    // baseline (purple-tinted) palette, which clashes with the brand yellow.
    surfaceContainerLowest: p.scaffoldBackground,
    surfaceContainerLow: p.surface,
    surfaceContainer: p.elevatedSurface,
    surfaceContainerHigh: p.elevatedSurface,
    surfaceContainerHighest: p.elevatedSurface,
    onSurfaceVariant: p.textSecondary,
    outline: p.border,
    outlineVariant: p.divider,
    inverseSurface: p.snackBarBackground,
    onInverseSurface: p.snackBarForeground,
    surfaceTint: Colors.transparent,
  );

  final borderSide = BorderSide(color: p.border);
  OutlineInputBorder inputBorder(BorderSide side) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radiusSm),
        borderSide: side,
      );

  return ThemeData(
    useMaterial3: true,
    brightness: p.brightness,
    primaryColor: AppColors.primaryColor,
    scaffoldBackgroundColor: p.scaffoldBackground,
    colorScheme: colorScheme,
    canvasColor: p.surface,
    dividerColor: p.divider,

    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: p.appBarBackground,
      foregroundColor: p.appBarForeground,
      surfaceTintColor: Colors.transparent,
      // Status-bar icons must contrast with the page, which is what shows
      // behind the transparent bar in edge-to-edge mode.
      systemOverlayStyle:
          p.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      titleTextStyle: TextStyle(
        color: p.appBarForeground,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),

    cardTheme: CardThemeData(
      elevation: p.cardElevation,
      color: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radiusMd),
        side: p.cardBorder == null
            ? BorderSide.none
            : BorderSide(color: p.cardBorder!),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.brandCharcoal,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusSm),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.textPrimary,
        side: BorderSide(color: p.border),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusSm),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: p.textPrimary),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: inputBorder(borderSide),
      enabledBorder: inputBorder(borderSide),
      focusedBorder: inputBorder(
        const BorderSide(color: AppColors.primaryColor, width: 2),
      ),
      errorBorder: inputBorder(const BorderSide(color: AppColors.error)),
      focusedErrorBorder: inputBorder(
        const BorderSide(color: AppColors.error, width: 2),
      ),
      hintStyle: TextStyle(color: p.hint),
    ),

    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: p.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: p.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: p.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: p.textPrimary,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: p.textPrimary),
      bodyMedium: TextStyle(fontSize: 14, color: p.textSecondary),
    ),

    dividerTheme: DividerThemeData(color: p.divider, thickness: 1),

    iconTheme: IconThemeData(color: p.textPrimary),
    primaryIconTheme: IconThemeData(color: p.textPrimary),

    listTileTheme: ListTileThemeData(
      iconColor: p.textSecondary,
      textColor: p.textPrimary,
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: p.surface,
      selectedItemColor: p.isDark ? AppColors.primaryColor : p.textPrimary,
      unselectedItemColor: p.unselected,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: p.elevatedSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radiusLg),
      ),
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: p.textPrimary,
      ),
      contentTextStyle: TextStyle(fontSize: 14, color: p.textSecondary),
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.elevatedSurface,
      modalBackgroundColor: p.elevatedSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(_radiusLg),
        ),
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.snackBarBackground,
      contentTextStyle: TextStyle(fontSize: 14, color: p.snackBarForeground),
      behavior: SnackBarBehavior.fixed,
    ),

    popupMenuTheme: PopupMenuThemeData(
      color: p.elevatedSurface,
      surfaceTintColor: Colors.transparent,
      textStyle: TextStyle(fontSize: 14, color: p.textPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radiusMd),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: p.elevatedSurface,
      selectedColor: AppColors.primaryColor,
      labelStyle: TextStyle(fontSize: 14, color: p.textPrimary),
      secondaryLabelStyle: const TextStyle(
        fontSize: 14,
        color: AppColors.brandCharcoal,
      ),
      side: BorderSide(color: p.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radiusLg),
      ),
    ),

    tabBarTheme: TabBarThemeData(
      labelColor: p.textPrimary,
      unselectedLabelColor: p.unselected,
      indicatorColor: AppColors.primaryColor,
    ),

    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: AppColors.primaryColor,
      linearTrackColor: p.divider,
      circularTrackColor: Colors.transparent,
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primaryColor
            : p.unselected,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primaryColor.withValues(alpha: 0.38)
            : p.divider,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primaryColor
            : Colors.transparent,
      ),
      checkColor: const WidgetStatePropertyAll(AppColors.brandCharcoal),
      side: BorderSide(color: p.unselected),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primaryColor
            : p.unselected,
      ),
    ),

    datePickerTheme: DatePickerThemeData(
      backgroundColor: p.elevatedSurface,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: p.surface,
      headerForegroundColor: p.textPrimary,
      todayForegroundColor: const WidgetStatePropertyAll(
        AppColors.primaryColor,
      ),
      dayForegroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.brandCharcoal
            : p.textPrimary,
      ),
      dayBackgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primaryColor
            : Colors.transparent,
      ),
      rangeSelectionBackgroundColor:
          AppColors.primaryColor.withValues(alpha: 0.2),
      rangePickerBackgroundColor: p.elevatedSurface,
      rangePickerHeaderBackgroundColor: p.surface,
      rangePickerHeaderForegroundColor: p.textPrimary,
    ),

    timePickerTheme: TimePickerThemeData(
      backgroundColor: p.elevatedSurface,
      dialBackgroundColor: p.surface,
      hourMinuteColor: p.inputFill,
      hourMinuteTextColor: p.textPrimary,
    ),
  );
}
