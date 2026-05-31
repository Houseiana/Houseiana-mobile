import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/app_strings.dart';
import 'package:houseiana_mobile_app/core/widgets/custom_button.dart';

class NoInternetConnectionWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const NoInternetConnectionWidget({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 80,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              AppStrings.noInternetConnection,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            if (onRetry != null)
              CustomButton(
                text: AppStrings.retry,
                onPressed: onRetry,
                width: 150,
              ),
          ],
        ),
      ),
    );
  }
}
