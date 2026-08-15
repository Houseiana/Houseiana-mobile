import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/theme/theme_builder.dart';

/// The light palette. Values come from [AppColorsLight] directly, never from
/// the [AppColors] getters: this theme is built once per process, before the
/// brightness flag is set.
const ThemePalette lightPalette = ThemePalette(
  brightness: Brightness.light,
  scaffoldBackground: AppColorsLight.scaffoldBackground,
  surface: AppColorsLight.cardBackground,
  elevatedSurface: AppColorsLight.cardBackground,
  inputFill: AppColorsLight.cardBackground,
  textPrimary: AppColorsLight.textPrimary,
  textSecondary: AppColorsLight.textSecondary,
  hint: AppColorsLight.textSecondary,
  unselected: AppColorsLight.neutral400,
  divider: AppColorsLight.divider,
  border: AppColorsLight.divider,
  appBarBackground: AppColors.primaryColor,
  appBarForeground: AppColors.brandCharcoal,
  snackBarBackground: AppColors.brandCharcoal,
  snackBarForeground: AppColors.textLight,
  cardElevation: 2,
);

ThemeData lightTheme() => buildTheme(lightPalette);
