import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/theme/theme_builder.dart';

/// The dark palette. Values come from [AppColorsDark] directly, never from the
/// [AppColors] getters: this theme is built once per process, before the
/// brightness flag is set.
const ThemePalette darkPalette = ThemePalette(
  brightness: Brightness.dark,
  scaffoldBackground: AppColorsDark.scaffoldBackground,
  surface: AppColorsDark.cardBackground,
  elevatedSurface: AppColorsDark.neutral100,
  inputFill: AppColorsDark.neutral100,
  textPrimary: AppColorsDark.textPrimary,
  textSecondary: AppColorsDark.textSecondary,
  hint: AppColorsDark.neutral400,
  unselected: AppColorsDark.neutral400,
  divider: AppColorsDark.divider,
  border: AppColorsDark.neutral300,
  appBarBackground: AppColorsDark.cardBackground,
  appBarForeground: AppColorsDark.textPrimary,
  snackBarBackground: AppColorsDark.textPrimary,
  snackBarForeground: AppColors.brandCharcoal,
  // Dark cards separate by a hairline border; a drop shadow is invisible here.
  cardElevation: 0,
  cardBorder: AppColorsDark.neutral200,
);

ThemeData darkTheme() => buildTheme(darkPalette);
