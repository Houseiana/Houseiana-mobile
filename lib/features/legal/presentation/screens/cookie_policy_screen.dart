import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class CookiePolicyScreen extends StatelessWidget {
  const CookiePolicyScreen({super.key});

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
          context.tr('legal.cookieTitle'),
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
              context.tr('legal.cookieHeading'),
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
              title: context.tr('legal.cookieSection1Title'),
              content: context.tr('legal.cookieSection1Content'),
            ),
            _buildSection(
              title: context.tr('legal.cookieSection2Title'),
              content: context.tr('legal.cookieSection2Content'),
            ),
            _buildSection(
              title: context.tr('legal.cookieSection3Title'),
              content: '',
            ),
            for (int i = 1; i <= 3; i++)
              _buildSubSection(
                title: context.tr('legal.cookieSub${i}Title'),
                content: context.tr('legal.cookieSub${i}Content'),
              ),
            for (int i = 4; i <= 8; i++)
              _buildSection(
                title: context.tr('legal.cookieSection${i}Title'),
                content: context.tr('legal.cookieSection${i}Content'),
              ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
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
                  context.tr('legal.acceptCookies'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.charcoal,
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(context.tr('legal.managePreferences')),
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
