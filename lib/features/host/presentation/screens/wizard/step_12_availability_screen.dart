import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/features/host/cubit/listing_wizard_cubit.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class Step12AvailabilityScreen extends StatefulWidget {
  const Step12AvailabilityScreen({super.key});

  @override
  State<Step12AvailabilityScreen> createState() =>
      _Step12AvailabilityScreenState();
}

class _Step12AvailabilityScreenState extends State<Step12AvailabilityScreen> {
  final _minNightsController = TextEditingController();
  final _maxNightsController = TextEditingController();
  String _availabilityType = 'flexible';

  @override
  void initState() {
    super.initState();
    final data = context.read<ListingWizardCubit>().state.data;
    if (data.minimumNights != null) {
      _minNightsController.text = data.minimumNights.toString();
    }
    if (data.maximumNights != null) {
      _maxNightsController.text = data.maximumNights.toString();
    }
    _availabilityType = data.availabilityType ?? 'flexible';
  }

  @override
  void dispose() {
    _minNightsController.dispose();
    _maxNightsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ListingWizardCubit>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('wizard.setAvailability'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('wizard.chooseHowGuests'),
            style: const TextStyle(fontSize: 15, color: AppColors.neutral600),
          ),
          const SizedBox(height: 32),
          Text(context.tr('wizard.availabilityType'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _RadioOption(
            title: context.tr('wizard.availFlexible'),
            description: context.tr('wizard.availFlexibleDesc'),
            isSelected: _availabilityType == 'flexible',
            onTap: () {
              setState(() => _availabilityType = 'flexible');
              cubit.updateStepData({'availabilityType': 'flexible'});
            },
          ),
          _RadioOption(
            title: context.tr('wizard.availModerate'),
            description: context.tr('wizard.availModerateDesc'),
            isSelected: _availabilityType == 'moderate',
            onTap: () {
              setState(() => _availabilityType = 'moderate');
              cubit.updateStepData({'availabilityType': 'moderate'});
            },
          ),
          _RadioOption(
            title: context.tr('wizard.availStrict'),
            description: context.tr('wizard.availStrictDesc'),
            isSelected: _availabilityType == 'strict',
            onTap: () {
              setState(() => _availabilityType = 'strict');
              cubit.updateStepData({'availabilityType': 'strict'});
            },
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _minNightsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: context.tr('wizard.minNights'),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (v) =>
                cubit.updateStepData({'minimumNights': int.tryParse(v)}),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _maxNightsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: context.tr('wizard.maxNights'),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (v) =>
                cubit.updateStepData({'maximumNights': int.tryParse(v)}),
          ),
        ],
      ),
    );
  }
}

class _RadioOption extends StatelessWidget {
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _RadioOption({
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color:
                isSelected ? AppColors.primaryColor : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryColor
                      : AppColors.neutral400,
                  width: 2,
                ),
                color: isSelected ? AppColors.primaryColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(description,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.neutral600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
