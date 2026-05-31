import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';

/// Unified shadow system for consistent design
class AppShadows {
  AppShadows._();

  // Shadow opacity values
  static const double opacitySm = 0.04;
  static const double opacityMd = 0.06;
  static const double opacityLg = 0.08;
  static const double opacityXl = 0.12;

  // Light theme shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: AppColors.shadow.withValues(alpha: opacityMd),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get cardShadowHover => [
        BoxShadow(
          color: AppColors.shadow.withValues(alpha: opacityLg),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get cardShadowLarge => [
        BoxShadow(
          color: AppColors.shadow.withValues(alpha: opacityLg),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: AppColors.shadow.withValues(alpha: opacityMd),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: AppColors.shadow.withValues(alpha: opacitySm),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: AppColors.shadow.withValues(alpha: opacityMd),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get floatingShadow => [
        BoxShadow(
          color: AppColors.shadow.withValues(alpha: opacityLg),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get bottomNavShadow => [
        BoxShadow(
          color: AppColors.shadow.withValues(alpha: opacitySm),
          blurRadius: 16,
          offset: const Offset(0, -4),
        ),
      ];

  static List<BoxShadow> get iconButtonShadow => [
        BoxShadow(
          color: AppColors.shadow.withValues(alpha: opacitySm),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get searchBarShadow => [
        BoxShadow(
          color: AppColors.shadow.withValues(alpha: opacityMd),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ];

  // Chip shadow when selected
  static List<BoxShadow> get chipShadow => [
        BoxShadow(
          color: AppColors.charcoal.withValues(alpha: 0.15),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  // No shadow (flat design)
  static List<BoxShadow> get none => [];
}
