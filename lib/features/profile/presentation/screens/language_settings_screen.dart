import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:houseiana_mobile_app/i18n/locale_cubit.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, AppLocale>(
      builder: (context, currentLocale) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              context.tr('profile.language'),
              style: const TextStyle(
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
                    const Icon(Icons.language, color: AppColors.charcoal, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.tr('profile.languagesInfo'),
                        style: const TextStyle(
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
                  itemCount: AppLocale.values.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final locale = AppLocale.values[index];
                    final isSelected = currentLocale == locale;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      title: Text(
                        locale.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: AppColors.charcoal,
                        ),
                      ),
                      subtitle: Text(
                        locale.code.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.neutral600,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: AppColors.primaryColor,
                            )
                          : null,
                      onTap: isSelected
                          ? null
                          : () => _confirmLanguageChange(context, locale),
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

  Future<void> _confirmLanguageChange(
    BuildContext context,
    AppLocale locale,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          context.tr('profile.changeLanguage'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          context.tr('profile.changeLanguageConfirm', args: {'name': locale.name}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr('profile.change')),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await context.read<LocaleCubit>().switchLocale(locale);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr('profile.languageChangedTo', args: {'name': locale.name}),
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
