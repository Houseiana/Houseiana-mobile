import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/theme/app_radius.dart';
import 'package:houseiana_mobile_app/core/theme/app_spacing.dart';

/// Enhanced theme configuration with unified design system
class AppTheme {
  AppTheme._();

  /// Light theme
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primaryColor,
      scaffoldBackgroundColor: AppColors.scaffoldBackground,
      
      // Color scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryColor,
        secondary: AppColors.secondaryColor,
        surface: AppColors.cardBackground,
        error: AppColors.error,
        onPrimary: AppColors.charcoal,
        onSecondary: AppColors.textLight,
        onSurface: AppColors.charcoal,
        onError: AppColors.textLight,
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.textLight,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textLight,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textLight,
          size: 24,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadiusAll,
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: AppColors.charcoal,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonRadiusAll,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          minimumSize: const Size(0, 50),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.charcoal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonRadiusAll,
          ),
          side: const BorderSide(color: AppColors.neutral200, width: 1.5),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          minimumSize: const Size(0, 50),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.inputRadiusAll,
          borderSide: const BorderSide(color: AppColors.neutral200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadiusAll,
          borderSide: const BorderSide(color: AppColors.neutral200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadiusAll,
          borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadiusAll,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadiusAll,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.neutral400,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        errorStyle: GoogleFonts.inter(
          color: AppColors.error,
          fontSize: 12,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.cardBackground,
        selectedItemColor: AppColors.charcoal,
        unselectedItemColor: AppColors.neutral400,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.neutral100,
        selectedColor: AppColors.primaryColor,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.chipRadiusAll,
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.charcoal,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.buttonRadiusAll,
        ),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.charcoal,
        contentTextStyle: GoogleFonts.inter(
          color: AppColors.textLight,
          fontSize: 14,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusMd,
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardBackground,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusXxl,
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.charcoal,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.cardBackground,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
        ),
        modalBackgroundColor: AppColors.cardBackground,
        modalElevation: 8,

      ),

      // Text Theme with Inter font
      textTheme: TextTheme(
        // Display styles
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),

        // Headline styles
        headlineLarge: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),

        // Title styles
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),

        // Body styles
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          height: 1.4,
        ),

        // Label styles
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.charcoal,
        size: 24,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryColor,
        linearTrackColor: AppColors.neutral200,
        circularTrackColor: AppColors.neutral200,
      ),
    );
  }

  /// Dark theme
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryLight,
      scaffoldBackgroundColor: AppColors.darkBackground,
      
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryLight,
        secondary: AppColors.secondaryLight,
        surface: Color(0xFF1E1E1E),
        error: AppColors.error,
        onPrimary: AppColors.charcoal,
        onSecondary: AppColors.textLight,
        onSurface: AppColors.textLight,
        onError: AppColors.textLight,
      ),

      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: AppColors.textLight,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textLight,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadiusAll,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.charcoal,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonRadiusAll,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          minimumSize: const Size(0, 50),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.inputRadiusAll,
          borderSide: const BorderSide(color: Color(0xFF424242)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadiusAll,
          borderSide: const BorderSide(color: Color(0xFF424242)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadiusAll,
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        hintStyle: GoogleFonts.inter(
          color: Colors.grey,
          fontSize: 14,
        ),
      ),

      textTheme: TextTheme(
        headlineLarge: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textLight,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textLight,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textLight,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textLight,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: AppColors.textLight,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.grey,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFF424242),
        thickness: 1,
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: Colors.grey,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
