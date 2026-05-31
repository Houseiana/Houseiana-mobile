import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/features/host/cubit/listing_wizard_cubit.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class Step09DiscountsScreen extends StatelessWidget {
  const Step09DiscountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ListingWizardCubit>();
    final data = cubit.state.data;
    
    // Explicit selection logic - checking for presence and value
    final isNewListingDiscountSelected = (data.newListingDiscountPercent ?? 0) >= 1;
    final isWeeklyDiscountSelected = (data.weeklyDiscountPercent ?? 0) >= 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('wizard.discountsInfo'),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1D242B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          _buildDiscountCard(
            title: context.tr('wizard.newListingPromotion'),
            description: context.tr('wizard.newListingDesc'),
            icon: Icons.wb_sunny_outlined,
            percentage: '20%',
            isSelected: isNewListingDiscountSelected,
            onTap: () {
              final newValue = isNewListingDiscountSelected ? 0.0 : 20.0;
              cubit.updateStepData({
                'newListingDiscountPercent': newValue,
              });
            },
          ),

          const SizedBox(height: 20),

          _buildDiscountCard(
            title: context.tr('wizard.weeklyDiscount'),
            description: context.tr('wizard.weeklyDesc'),
            icon: Icons.calendar_today_outlined,
            percentage: '20%',
            isSelected: isWeeklyDiscountSelected,
            onTap: () {
              final newValue = isWeeklyDiscountSelected ? 0.0 : 20.0;
              cubit.updateStepData({
                'weeklyDiscountPercent': newValue,
              });
            },
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDiscountCard({
    required String title,
    required String description,
    required IconData icon,
    required String percentage,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected ? AppColors.primaryColor : const Color(0xFFF0F2F5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryColor.withValues(alpha: 0.1) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? AppColors.primaryColor : const Color(0xFF4B5563),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D242B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryColor.withValues(alpha: 0.1) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    percentage,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.primaryColor : const Color(0xFF1D242B),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.primaryColor : Colors.white,
                    border: Border.all(
                      color: isSelected ? AppColors.primaryColor : const Color(0xFFD1D5DB),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
