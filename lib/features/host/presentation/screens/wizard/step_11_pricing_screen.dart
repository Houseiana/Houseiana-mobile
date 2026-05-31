import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/features/host/cubit/listing_wizard_cubit.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class Step11PricingScreen extends StatefulWidget {
  const Step11PricingScreen({super.key});

  @override
  State<Step11PricingScreen> createState() => _Step11PricingScreenState();
}

class _Step11PricingScreenState extends State<Step11PricingScreen> {
  late final TextEditingController _basePriceController;
  late final TextEditingController _cleaningFeeController;
  late final TextEditingController _electricalFeeController;
  late final TextEditingController _waterFeeController;

  @override
  void initState() {
    super.initState();
    final data = context.read<ListingWizardCubit>().state.data;
    _basePriceController = TextEditingController(
      text: data.basePrice?.toString() ?? '1000',
    );
    _cleaningFeeController = TextEditingController(
      text: data.cleaningFee?.toString() ?? '',
    );
    _electricalFeeController = TextEditingController(
      text: data.electricalFee?.toString() ?? '',
    );
    _waterFeeController = TextEditingController(
      text: data.waterFee?.toString() ?? '',
    );

    // Set default base price if not set
    if (data.basePrice == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ListingWizardCubit>().updateStepData({'basePrice': 1000.0});
      });
    }
    // Set default stars if not set
    if (data.stars == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ListingWizardCubit>().updateStepData({'stars': 5});
      });
    }
  }

  @override
  void dispose() {
    _basePriceController.dispose();
    _cleaningFeeController.dispose();
    _electricalFeeController.dispose();
    _waterFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ListingWizardCubit>();
    final data = cubit.state.data;
    final basePriceError = cubit.state.basePriceError;
    final selectedStars = data.stars ?? 5;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating Section
          Text(
            context.tr('wizard.wizardPricingRatingTitle'),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D242B),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(5, (index) {
              final rating = index + 1;
              final isSelected = selectedStars == rating;
              return InkWell(
                onTap: () {
                  cubit.updateStepData({'stars': rating});
                },
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryColor : const Color(0xFFF0F2F5),
                      width: 1.5,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: AppColors.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ] : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: 18,
                        color: isSelected ? Colors.white : const Color(0xFFD1D5DB),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$rating ${rating > 1 ? context.tr('wizard.wizardPricingStarPlural') : context.tr('wizard.wizardPricingStarSingular')}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : const Color(0xFF1D242B),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 40),

          // Nightly Rate Section
          Text(
            context.tr('wizard.wizardPricingSetYourPrice'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D242B),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: basePriceError != null
                    ? AppColors.error
                    : const Color(0xFFF0F2F5),
                width: basePriceError != null ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  context.tr('wizard.wizardPricingChangeAnytime'),
                  style: const TextStyle(fontSize: 15, color: Color(0xFF5E5E5E)),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      context.tr('wizard.wizardPricingCurrencyCode'),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2F3A45),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IntrinsicWidth(
                      child: TextField(
                        controller: _basePriceController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2F3A45),
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: '0',
                        ),
                        onChanged: (v) {
                          cubit.updateStepData({'basePrice': double.tryParse(v) ?? 0.0});
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  height: 2,
                  width: 160,
                  color: const Color(0xFF2F3A45),
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr('wizard.wizardPricingNightlyRateLabel'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: Color(0xFF2F3A45),
                  ),
                ),
              ],
            ),
          ),
          if (basePriceError != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 16,
                  color: AppColors.error,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    basePriceError,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 32),

          // Fee Section - Vertical Layout
          Text(
            context.tr('wizard.wizardPricingAdditionalFees'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D242B),
            ),
          ),
          const SizedBox(height: 16),
          _buildFeeCard(
            context: context,
            title: context.tr('wizard.wizardPricingCleaningFeeTitle'),
            subtitle: context.tr('wizard.wizardPricingCleaningFeeSubtitle'),
            controller: _cleaningFeeController,
            onChanged: (v) => cubit.updateStepData({'cleaningFee': double.tryParse(v) ?? 0.0}),
          ),
          const SizedBox(height: 16),
          _buildWeekendSurgeCard(context),
          const SizedBox(height: 16),
          _buildFeeCard(
            context: context,
            title: context.tr('wizard.wizardPricingElectricalFeeTitle'),
            subtitle: context.tr('wizard.wizardPricingElectricalFeeSubtitle'),
            controller: _electricalFeeController,
            onChanged: (v) => cubit.updateStepData({'electricalFee': double.tryParse(v) ?? 0.0}),
          ),
          const SizedBox(height: 16),
          _buildFeeCard(
            context: context,
            title: context.tr('wizard.wizardPricingWaterFeeTitle'),
            subtitle: context.tr('wizard.wizardPricingWaterFeeSubtitle'),
            controller: _waterFeeController,
            onChanged: (v) => cubit.updateStepData({'waterFee': double.tryParse(v) ?? 0.0}),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFeeCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required Function(String) onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F2F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D242B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  context.tr('wizard.wizardPricingOptional'),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                context.tr('wizard.wizardPricingCurrencyCode'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2F3A45),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2F3A45),
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 4),
                              hintText: '0',
                            ),
                            onChanged: onChanged,
                          ),
                        ),
                        const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF9CA3AF)),
                      ],
                    ),
                    Container(height: 2, color: const Color(0xFF2F3A45).withValues(alpha: 0.2)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekendSurgeCard(BuildContext context) {
    return Opacity(
      opacity: 0.7,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFCFCFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0F2F5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            context.tr('wizard.wizardPricingWeekendSurgeTitle'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1D242B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D242B),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              context.tr('wizard.wizardPricingSoon'),
                              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr('wizard.wizardPricingWeekendSurgeSubtitle'),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    context.tr('wizard.wizardPricingOptional'),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text(
                  '0',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2F3A45),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2F3A45),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(height: 2, color: const Color(0xFF2F3A45).withValues(alpha: 0.1)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
