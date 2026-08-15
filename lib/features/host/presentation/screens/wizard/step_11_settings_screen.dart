import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/features/host/cubit/listing_wizard_cubit.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class Step11SettingsScreen extends StatefulWidget {
  Step11SettingsScreen({super.key});

  @override
  State<Step11SettingsScreen> createState() => _Step11SettingsScreenState();
}

class _Step11SettingsScreenState extends State<Step11SettingsScreen> {
  late final TextEditingController _primaryPhoneController;
  late final TextEditingController _emergencyPhoneController;

  @override
  void initState() {
    super.initState();
    final data = context.read<ListingWizardCubit>().state.data;
    _primaryPhoneController = TextEditingController(text: data.primaryPhone);
    _emergencyPhoneController =
        TextEditingController(text: data.emergencyPhone);
  }

  @override
  void dispose() {
    _primaryPhoneController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ListingWizardCubit>();
    final data = cubit.state.data;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('wizard.contactInfo'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 16),
          _buildPhoneField(
            context: context,
            label: context.tr('wizard.primaryPhone'),
            description: context.tr('wizard.primaryPhoneDesc'),
            controller: _primaryPhoneController,
            onChanged: (v) => cubit.updateStepData({'primaryPhone': v}),
          ),
          const SizedBox(height: 20),
          _buildPhoneField(
            context: context,
            label: context.tr('wizard.emergencyPhone'),
            description: context.tr('wizard.emergencyPhoneDesc'),
            controller: _emergencyPhoneController,
            onChanged: (v) => cubit.updateStepData({'emergencyPhone': v}),
          ),
          const SizedBox(height: 32),
          Text(
            context.tr('wizard.personalizeExperience'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 16),
          _buildSwitchCard(
            title: context.tr('wizard.instantBook'),
            description: context.tr('wizard.instantBookDesc'),
            value: data.instantBook ?? true,
            onChanged: (v) => cubit.updateStepData({'instantBook': v}),
          ),
          const SizedBox(height: 32),
          Text(
            context.tr('wizard.anyOfThese'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 16),
          _buildSwitchCard(
            title: context.tr('wizard.securityCameras'),
            description: context.tr('wizard.securityCamerasDesc'),
            value: data.hasSecurityCameras ?? false,
            onChanged: (v) => cubit.updateStepData({'hasSecurityCameras': v}),
          ),
          const SizedBox(height: 12),
          _buildSwitchCard(
            title: context.tr('wizard.noiseMonitors'),
            description: context.tr('wizard.noiseMonitorsDesc'),
            value: data.hasNoiseMonitors ?? false,
            onChanged: (v) => cubit.updateStepData({'hasNoiseMonitors': v}),
          ),
          const SizedBox(height: 24),
          _buildDisclosureBox(context),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPhoneField({
    required BuildContext context,
    required String label,
    required String description,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    // Egyptian mobile numbers are 10 digits; restrict input to digits only so
    // the value matches what the backend (and the validation gate) expect.
    final phoneFormatters = <TextInputFormatter>[
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(10),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.phone_outlined, size: 16, color: AppColors.neutral600),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.neutral500,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.neutral100),
          ),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border:
                      Border(right: BorderSide(color: AppColors.neutral100)),
                ),
                child: Row(
                  children: [
                    Text(
                      '+20 Egypt',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.charcoal,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.keyboard_arrow_down,
                        size: 16, color: AppColors.neutral400),
                  ],
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  inputFormatters: phoneFormatters,
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    hintText: context.tr('wizard.enterPhone'),
                    hintStyle:
                        TextStyle(fontSize: 14, color: AppColors.neutral400),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchCard({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral100),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
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
          const SizedBox(width: 16),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDisclosureBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // dark-ok
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFEF3C7)), // dark-ok
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline,
              size: 20, color: Color(0xFFD97706)), // dark-ok
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('wizard.disclosureTitle'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF92400E), // dark-ok
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('wizard.disclosureDesc'),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB45309), // dark-ok
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
