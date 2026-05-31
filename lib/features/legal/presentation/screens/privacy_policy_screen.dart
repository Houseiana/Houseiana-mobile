import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('legal.privacyTitle'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('legal.privacyHeading'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('legal.lastUpdated'),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.neutral600,
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: context.tr('legal.privacySection1Title'),
              content: context.tr('legal.privacySection1Content'),
            ),
            _buildSection(
              title: context.tr('legal.privacySection2Title'),
              content: context.tr('legal.privacySection2Content'),
            ),
            for (int i = 1; i <= 8; i++)
              _buildSubSection(
                title: context.tr('legal.privacySub${i}Title'),
                content: context.tr('legal.privacySub${i}Content'),
              ),
            for (int i = 3; i <= 10; i++)
              _buildSection(
                title: context.tr('legal.privacySection${i}Title'),
                content: context.tr('legal.privacySection${i}Content'),
              ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.charcoal,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  context.tr('legal.downloadMyData'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(context, Routes.contactSupport);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.charcoal,
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(context.tr('legal.contactPrivacy')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.neutral600,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.neutral600,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
