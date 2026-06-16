import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/features/host/cubit/listing_wizard_cubit.dart';
import 'package:houseiana_mobile_app/features/host/cubit/listing_wizard_state.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'dart:io';

class Step13ReviewPublishScreen extends StatelessWidget {
  const Step13ReviewPublishScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // This step owns the SUCCESS path only (errors are shown once by the
    // wizard shell's listener). Fire on the null→set transition so the dialog
    // shows exactly once.
    return BlocListener<ListingWizardCubit, ListingWizardState>(
      listenWhen: (prev, curr) =>
          curr.publishedListingId != null && prev.publishedListingId == null,
      listener: (context, state) => _showSuccessDialog(context),
      child: BlocBuilder<ListingWizardCubit, ListingWizardState>(
        builder: (context, state) {
          final data = state.data;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('wizard.reviewIntro'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D242B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                _buildPreviewCard(context, data),

                const SizedBox(height: 24),

                _buildSectionBox(
                  title: context.tr('wizard.descriptionHeader'),
                  content: data.description ?? context.tr('wizard.noDescription'),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildSectionBox(
                        title: context.tr('wizard.checkInOutHeader'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildIconText(Icons.access_time, context.tr('wizard.inLabel', args: {'time': data.checkInTime ?? '3:00 PM'})),
                            const SizedBox(height: 4),
                            _buildIconText(Icons.access_time, context.tr('wizard.outLabel', args: {'time': data.checkOutTime ?? '11:00 AM'})),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSectionBox(
                        title: context.tr('wizard.cancellationHeader'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildIconText(Icons.cancel_outlined, data.cancellationPolicyType ?? context.tr('wizard.policyFlexible')),
                            const SizedBox(height: 4),
                            Text(
                              context.tr('wizard.freeCancelWithin24'),
                              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                _buildSectionBox(
                  title: context.tr('wizard.bookingHeader'),
                  child: _buildIconText(
                    Icons.bolt,
                    data.instantBook ?? true
                        ? context.tr('wizard.instantBookOn')
                        : context.tr('wizard.instantBookOff'),
                    iconColor: Colors.amber,
                  ),
                ),

                const SizedBox(height: 12),

                _buildSectionBox(
                  title: context.tr('wizard.houseRulesHeader'),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (!(data.allowPets ?? false)) _buildRuleChip(context.tr('wizard.rulePets')),
                      if (!(data.allowSmoking ?? false)) _buildRuleChip(context.tr('wizard.ruleSmoking')),
                      if (!(data.allowEvents ?? false)) _buildRuleChip(context.tr('wizard.ruleEvents')),
                      if (data.allowPets ?? false) _buildRuleChip(context.tr('wizard.rulePets'), allowed: true),
                      if (data.allowSmoking ?? false) _buildRuleChip(context.tr('wizard.ruleSmoking'), allowed: true),
                      if (data.allowEvents ?? false) _buildRuleChip(context.tr('wizard.ruleEvents'), allowed: true),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  context.tr('wizard.whatsNext'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D242B),
                  ),
                ),
                const SizedBox(height: 16),

                _buildNextSteps(context),

                // The publish/finalize action lives in the wizard's bottom
                // navigation bar (web parity) — alongside the Back button — so
                // there is no duplicate in-page button here.
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPreviewCard(BuildContext context, WizardData data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: _buildCoverImage(data.coverPhoto),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        data.title ?? context.tr('wizard.propertyTitleFallback'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1D242B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 4),
                    Text(
                      '${data.city ?? 'Abdin'}, ${data.country ?? 'Egypt'}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                    const Spacer(),
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '${data.stars ?? 3}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  children: [
                    _buildInfoItem(Icons.people_outline, context.tr('wizard.guestsCount', args: {'n': data.maxGuests ?? 4})),
                    _buildInfoItem(Icons.bed, context.tr('wizard.bedroomsCount', args: {'n': data.bedrooms ?? 2})),
                    _buildInfoItem(Icons.bed_outlined, context.tr('wizard.bedsCount', args: {'n': data.beds ?? 2})),
                    _buildInfoItem(Icons.bathtub_outlined, context.tr('wizard.bathroomsCount', args: {'n': data.bathrooms ?? 1})),
                    _buildInfoItem(Icons.square_foot, context.tr('wizard.areaCount', args: {'n': (data.totalArea ?? 25).toInt()})),
                  ],
                ),
                const SizedBox(height: 16),
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: '\$ ',
                        style: TextStyle(fontSize: 14, color: Color(0xFF1D242B), fontWeight: FontWeight.w500),
                      ),
                      TextSpan(
                        text: context.tr('wizard.currencyEgp', args: {'price': data.basePrice?.toStringAsFixed(0) ?? '1000'}),
                        style: const TextStyle(fontSize: 18, color: Color(0xFF1D242B), fontWeight: FontWeight.w800),
                      ),
                      TextSpan(
                        text: context.tr('wizard.perNight'),
                        style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage(String? path) {
    if (path == null || path.isEmpty) {
      return Container(
        height: 220,
        width: double.infinity,
        color: const Color(0xFFF3F4F6),
        child: const Icon(Icons.image_outlined, size: 48, color: Color(0xFF9CA3AF)),
      );
    }
    if (path.startsWith('http')) {
      return Image.network(path, height: 220, width: double.infinity, fit: BoxFit.cover);
    }
    return Image.file(File(path), height: 220, width: double.infinity, fit: BoxFit.cover);
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
      ],
    );
  }

  Widget _buildSectionBox({required String title, String? content, Widget? child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F2F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF9CA3AF),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          if (content != null)
            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1D242B),
                height: 1.5,
              ),
            ),
          if (child != null) child,
        ],
      ),
    );
  }

  Widget _buildIconText(IconData icon, String text, {Color? iconColor}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor ?? const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D242B),
          ),
        ),
      ],
    );
  }

  Widget _buildRuleChip(String label, {bool allowed = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: allowed ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            allowed ? Icons.check : Icons.close,
            size: 12,
            color: allowed ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: allowed ? const Color(0xFF065F46) : const Color(0xFF991B1B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextSteps(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          _buildNextStepCard(
            Icons.check_circle_outline,
            context.tr('wizard.confirmDetails'),
            context.tr('wizard.confirmDetailsDesc'),
          ),
          _buildNextStepCard(
            Icons.calendar_today_outlined,
            context.tr('wizard.setupCalendar'),
            context.tr('wizard.setupCalendarDesc'),
          ),
          _buildNextStepCard(
            Icons.settings_outlined,
            context.tr('wizard.adjustSettings'),
            context.tr('wizard.adjustSettingsDesc'),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepCard(IconData icon, String title, String description) {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F2F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: const Color(0xFF9CA3AF)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D242B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.tr('wizard.propertyPublished'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('wizard.publishedCongrats'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, Routes.hostDashboard);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: const Color(0xFF1D242B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(context.tr('wizard.goToDashboard'), style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
