import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/features/host/cubit/listing_wizard_cubit.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class Step04BasicsScreen extends StatefulWidget {
  const Step04BasicsScreen({super.key});

  @override
  State<Step04BasicsScreen> createState() => _Step04BasicsScreenState();
}

class _Step04BasicsScreenState extends State<Step04BasicsScreen> {
  late TextEditingController _areaController;

  @override
  void initState() {
    super.initState();
    final data = context.read<ListingWizardCubit>().state.data;
    _areaController = TextEditingController(text: data.totalArea?.toInt().toString() ?? '25');
  }

  @override
  void dispose() {
    _areaController.dispose();
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
            context.tr('wizard.shareBasics'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 24),
          _buildItem(
            icon: Icons.group_outlined,
            label: context.tr('wizard.guests'),
            subLabel: context.tr('wizard.maxCapacity'),
            value: data.maxGuests ?? 0,
            onDec: () =>
                cubit.updateStepData({'maxGuests': (data.maxGuests ?? 0) - 1}),
            onInc: () =>
                cubit.updateStepData({'maxGuests': (data.maxGuests ?? 0) + 1}),
          ),
          const Divider(height: 32),
          _buildItem(
            icon: Icons.bed_outlined,
            label: context.tr('wizard.bedrooms'),
            subLabel: context.tr('wizard.privateSleepingAreas'),
            value: data.bedrooms ?? 0,
            onDec: () =>
                cubit.updateStepData({'bedrooms': (data.bedrooms ?? 0) - 1}),
            onInc: () =>
                cubit.updateStepData({'bedrooms': (data.bedrooms ?? 0) + 1}),
          ),
          const Divider(height: 32),
          _buildItem(
            icon: Icons.single_bed_outlined,
            label: context.tr('wizard.beds'),
            subLabel: context.tr('wizard.totalSleepingSpots'),
            value: data.beds ?? 0,
            onDec: () => cubit.updateStepData({'beds': (data.beds ?? 0) - 1}),
            onInc: () => cubit.updateStepData({'beds': (data.beds ?? 0) + 1}),
          ),
          const Divider(height: 32),
          _buildItem(
            icon: Icons.bathtub_outlined,
            label: context.tr('wizard.bathrooms'),
            subLabel: context.tr('wizard.toiletsAndShowers'),
            value: data.bathrooms ?? 0,
            onDec: () =>
                cubit.updateStepData({'bathrooms': (data.bathrooms ?? 0) - 1}),
            onInc: () =>
                cubit.updateStepData({'bathrooms': (data.bathrooms ?? 0) + 1}),
          ),
          const Divider(height: 32),
          _buildAreaItem(
            icon: Icons.fullscreen_outlined,
            label: context.tr('wizard.totalArea'),
            subLabel: context.tr('wizard.totalAreaDesc'),
            value: data.totalArea ?? 25.0,
            controller: _areaController,
            onChanged: (v) {
              final val = double.tryParse(v);
              if (val != null) {
                cubit.updateStepData({'totalArea': val});
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String label,
    required String subLabel,
    required int value,
    required VoidCallback onDec,
    required VoidCallback onInc,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.neutral700, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal,
                ),
              ),
              Text(
                subLabel,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.neutral600,
                ),
              ),
            ],
          ),
        ),
        _Counter(value: value, onDec: onDec, onInc: onInc),
      ],
    );
  }

  Widget _buildAreaItem({
    required IconData icon,
    required String label,
    required String subLabel,
    required double value,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.neutral700, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal,
                ),
              ),
              Text(
                subLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: value < 25 || value > 3000 ? Colors.red : AppColors.neutral600,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 90,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.charcoal,
                  ),
                  onChanged: onChanged,
                ),
              ),
              const Text(
                'm²',
                style: TextStyle(fontSize: 13, color: AppColors.neutral700, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Counter extends StatelessWidget {
  final int value;
  final VoidCallback onDec;
  final VoidCallback onInc;

  const _Counter({
    required this.value,
    required this.onDec,
    required this.onInc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: value > 0 ? onDec : null,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: value > 0 ? AppColors.neutral400 : AppColors.neutral200),
            ),
            child: Icon(Icons.remove, size: 20, color: value > 0 ? AppColors.neutral700 : AppColors.neutral300),
          ),
        ),
        Container(
          width: 40,
          alignment: Alignment.center,
          child: Text(
            '$value',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        GestureDetector(
          onTap: onInc,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.neutral400),
            ),
            child: const Icon(Icons.add, size: 20, color: AppColors.neutral700),
          ),
        ),
      ],
    );
  }
}
