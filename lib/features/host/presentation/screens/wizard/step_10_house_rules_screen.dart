import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/features/host/cubit/listing_wizard_cubit.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class Step10HouseRulesScreen extends StatefulWidget {
  const Step10HouseRulesScreen({super.key});

  @override
  State<Step10HouseRulesScreen> createState() => _Step10HouseRulesScreenState();
}

class _Step10HouseRulesScreenState extends State<Step10HouseRulesScreen> {
  final List<String> _times = [
    '12:00 PM', '01:00 PM', '02:00 PM', '03:00 PM', '04:00 PM', '05:00 PM',
    '06:00 PM', '07:00 PM', '08:00 PM', '09:00 PM', '10:00 PM', '11:00 PM',
    '12:00 AM', '01:00 AM', '02:00 AM', '03:00 AM', '04:00 AM', '05:00 AM',
    '06:00 AM', '07:00 AM', '08:00 AM', '09:00 AM', '10:00 AM', '11:00 AM',
  ];

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
            context.tr('wizard.setRules'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 24),
          _buildRuleTile(
            icon: Icons.pets_outlined,
            title: context.tr('wizard.petsAllowed'),
            value: data.allowPets ?? false,
            onChanged: (v) => cubit.updateStepData({'allowPets': v}),
          ),
          const SizedBox(height: 12),
          _buildRuleTile(
            icon: Icons.smoking_rooms_outlined,
            title: context.tr('wizard.smokingAllowed'),
            value: data.allowSmoking ?? false,
            onChanged: (v) => cubit.updateStepData({'allowSmoking': v}),
          ),
          const SizedBox(height: 12),
          _buildRuleTile(
            icon: Icons.celebration_outlined,
            title: context.tr('wizard.eventsAllowed'),
            value: data.allowEvents ?? false,
            onChanged: (v) => cubit.updateStepData({'allowEvents': v}),
          ),
          const SizedBox(height: 12),
          _buildRuleTile(
            icon: Icons.person_add_outlined,
            title: context.tr('wizard.guestVisitorsAllowed'),
            value: data.allowGuests ?? true,
            onChanged: (v) => cubit.updateStepData({'allowGuests': v}),
          ),
          const SizedBox(height: 12),
          _buildRuleTile(
            icon: Icons.favorite_border_outlined,
            title: context.tr('wizard.marriedOnly'),
            value: data.marriedCouplesOnly ?? false,
            onChanged: (v) => cubit.updateStepData({'marriedCouplesOnly': v}),
          ),
          const SizedBox(height: 32),
          Text(
            context.tr('wizard.checkInOutTimes'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('wizard.checkInAfter'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _buildTimeDropdown(
                      value: data.checkInTime ?? '03:00 PM',
                      onChanged: (v) => cubit.updateStepData({'checkInTime': v}),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('wizard.checkoutBefore'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _buildTimeDropdown(
                      value: data.checkOutTime ?? '11:00 AM',
                      onChanged: (v) => cubit.updateStepData({'checkOutTime': v}),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRuleTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.neutral600, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.charcoal,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.amber, // As per screenshot
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDropdown({
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.neutral600),
          items: _times.map((time) {
            return DropdownMenuItem(
              value: time,
              child: Text(time, style: const TextStyle(fontSize: 15)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
