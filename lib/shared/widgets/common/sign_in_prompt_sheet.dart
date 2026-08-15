import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

/// Bottom sheet shown when a logged-out guest taps a favorite (heart) button.
/// Explains that signing in is required to save favorites and offers
/// sign-in / create-account actions.
Future<void> showSignInToSaveFavoritesSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.neutral200,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 28),
          Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle),
              child: Icon(Icons.favorite_border,
                  size: 38, color: AppColors.primaryColor)),
          const SizedBox(height: 16),
          Text(context.tr('home.signInToSaveFavorites'),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal)),
          const SizedBox(height: 8),
          Text(context.tr('home.signInToSaveFavoritesDescription'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: AppColors.neutral500, height: 1.5)),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(sheetCtx);
                Navigator.pushNamed(context, Routes.login);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.brandCharcoal,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: Text(context.tr('auth.signIn'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(sheetCtx);
                Navigator.pushNamed(context, Routes.signUp);
              },
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.charcoal,
                  side: BorderSide(color: AppColors.neutral200, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: Text(context.tr('bottomNav.createAccountAction'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    ),
  );
}
