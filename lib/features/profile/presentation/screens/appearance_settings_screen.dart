import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/theme/theme_cubit.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

/// Translation key for a [ThemeMode], used by this screen and by the
/// Appearance rows in the profile / account settings screens.
String themeModeLabelKey(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'profile.themeLight';
    case ThemeMode.dark:
      return 'profile.themeDark';
    case ThemeMode.system:
      return 'profile.themeSystem';
  }
}

IconData _themeModeIcon(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return Icons.light_mode_outlined;
    case ThemeMode.dark:
      return Icons.dark_mode_outlined;
    case ThemeMode.system:
      return Icons.brightness_auto_outlined;
  }
}

/// Light / Dark / System picker. Mirrors [LanguageSettingsScreen], minus the
/// confirmation dialog: switching the appearance is instant and reversible,
/// unlike a language change which refetches backend-localized data.
class AppearanceSettingsScreen extends StatelessWidget {
  AppearanceSettingsScreen({super.key});

  static const _modes = [ThemeMode.light, ThemeMode.dark, ThemeMode.system];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, currentMode) {
        return Scaffold(
          backgroundColor: AppColors.cardBackground,
          appBar: AppBar(
            backgroundColor: AppColors.cardBackground,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: AppColors.charcoal),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              context.tr('profile.appearance'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.brightness_6_outlined,
                      color: AppColors.charcoal,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.tr('profile.appearanceInfo'),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _modes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final mode = _modes[index];
                    final isSelected = currentMode == mode;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      leading: Icon(
                        _themeModeIcon(mode),
                        color: AppColors.charcoal,
                      ),
                      title: Text(
                        context.tr(themeModeLabelKey(mode)),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: AppColors.charcoal,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: AppColors.primaryColor,
                            )
                          : null,
                      onTap:
                          isSelected ? null : () => _switchMode(context, mode),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _switchMode(BuildContext context, ThemeMode mode) async {
    final label = context.tr(themeModeLabelKey(mode));
    await context.read<ThemeCubit>().switchMode(mode);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            context.tr('profile.themeChangedTo', args: {'name': label}),
          ),
          backgroundColor: AppColors.success,
        ),
      );
  }
}
