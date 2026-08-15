import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/features/host/cubit/listing_wizard_cubit.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class Step10PolicyScreen extends StatefulWidget {
  Step10PolicyScreen({super.key});

  @override
  State<Step10PolicyScreen> createState() => _Step10PolicyScreenState();
}

class _Step10PolicyScreenState extends State<Step10PolicyScreen> {
  late final TextEditingController _daysController;

  @override
  void initState() {
    super.initState();
    final data = context.read<ListingWizardCubit>().state.data;
    _daysController = TextEditingController(
      text: (data.freeCancellationDays ?? 5).toString(),
    );
  }

  @override
  void dispose() {
    _daysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ListingWizardCubit>();
    final data = cubit.state.data;

    final selectedType = data.cancellationPolicyType ?? 'FLEXIBLE';
    final selectedHours = data.freeCancellationHours ?? 24;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('wizard.choosePolicy'),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 24),

          _buildPolicyCard(
            type: 'FLEXIBLE',
            title: context.tr('wizard.policyFlexible'),
            description: context.tr('wizard.policyFlexibleDesc'),
            icon: Icons.shield_outlined,
            isSelected: selectedType == 'FLEXIBLE',
            onTap: () =>
                cubit.updateStepData({'cancellationPolicyType': 'FLEXIBLE'}),
          ),

          const SizedBox(height: 16),

          _buildPolicyCard(
            type: 'MODERATE',
            title: context.tr('wizard.policyModerate'),
            description: context.tr('wizard.policyModerateDesc'),
            icon: Icons.verified_user_outlined,
            isSelected: selectedType == 'MODERATE',
            onTap: () =>
                cubit.updateStepData({'cancellationPolicyType': 'MODERATE'}),
          ),

          const SizedBox(height: 16),

          _buildPolicyCard(
            type: 'FIXED',
            title: context.tr('wizard.policyFixed'),
            description: context.tr('wizard.policyFixedDesc'),
            icon: Icons.lock_outline,
            isSelected: selectedType == 'FIXED',
            onTap: () =>
                cubit.updateStepData({'cancellationPolicyType': 'FIXED'}),
          ),

          const SizedBox(height: 32),

          // Detail Sections
          if (selectedType == 'FLEXIBLE')
            _buildFlexibleDetails(context, cubit, selectedHours),
          if (selectedType == 'MODERATE') _buildModerateDetails(context, cubit),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPolicyCard({
    required String type,
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.neutral100,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryColor.withValues(alpha: 0.1)
                    : AppColors.ghostWhite,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color:
                    isSelected ? AppColors.primaryColor : AppColors.neutral600,
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.primaryColor
                    : AppColors.cardBackground,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryColor
                      : AppColors.neutral300,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 16,
                      color: AppColors.brandCharcoal,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlexibleDetails(
      BuildContext context, ListingWizardCubit cubit, int selectedHours) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.ghostWhite,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline,
                  size: 18, color: AppColors.primaryColor),
              const SizedBox(width: 8),
              Text(
                context.tr('wizard.selectTimeframe'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTimeframeButton(
                  label: context.tr('wizard.hours24Free'),
                  isSelected: selectedHours == 24,
                  onTap: () =>
                      cubit.updateStepData({'freeCancellationHours': 24}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeframeButton(
                  label: context.tr('wizard.hours48Free'),
                  isSelected: selectedHours == 48,
                  onTap: () =>
                      cubit.updateStepData({'freeCancellationHours': 48}),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModerateDetails(BuildContext context, ListingWizardCubit cubit) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.ghostWhite,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 18, color: AppColors.primaryColor),
              const SizedBox(width: 8),
              Text(
                context.tr('wizard.customModerate'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            context.tr('wizard.daysPriorArrival'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.neutral600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.neutral100),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _daysController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '5',
                    ),
                    onChanged: (v) {
                      cubit.updateStepData(
                          {'freeCancellationDays': int.tryParse(v) ?? 5});
                    },
                  ),
                ),
                Text(
                  context.tr('wizard.days'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('wizard.daysHelp'),
            style: TextStyle(fontSize: 11, color: AppColors.neutral400),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.neutral100,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: AppColors.primaryColor, size: 20),
          ],
        ),
      ),
    );
  }
}
