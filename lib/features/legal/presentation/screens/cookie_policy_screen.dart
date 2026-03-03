import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';

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
        title: const Text(
          'Cookie Policy',
          style: TextStyle(
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
            const Text(
              'Cookie Policy for Houseiana',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Last updated: December 2024',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.neutral600,
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: 'What Are Cookies',
              content: 'Cookies are small text files that are placed on your computer or mobile device when you visit our website. They are widely used to make websites work more efficiently and provide information to the owners of the site.',
            ),

            _buildSection(
              title: 'How We Use Cookies',
              content: 'We use cookies for the following purposes:\n\n• Authentication: To verify your identity and keep you logged in\n• Preferences: To remember your settings and preferences\n• Analytics: To understand how you use our services\n• Advertising: To deliver relevant advertisements\n• Security: To protect against fraudulent activity',
            ),

            _buildSection(
              title: 'Types of Cookies We Use',
              content: '',
            ),

            _buildSubSection(
              title: 'Essential Cookies',
              content: 'These cookies are necessary for the website to function properly. They enable basic functions like page navigation and access to secure areas of the website.',
            ),

            _buildSubSection(
              title: 'Analytics Cookies',
              content: 'These cookies help us understand how visitors interact with our website by collecting and reporting information anonymously.',
            ),

            _buildSubSection(
              title: 'Marketing Cookies',
              content: 'These cookies are used to track visitors across websites to display relevant advertisements and marketing campaigns.',
            ),

            _buildSection(
              title: 'Third-Party Cookies',
              content: 'In addition to our own cookies, we may also use various third-party cookies to report usage statistics of the service and deliver advertisements on and through the service.\n\nThird parties we work with include:\n• Google Analytics\n• Facebook Pixel\n• Advertising partners',
            ),

            _buildSection(
              title: 'Managing Cookies',
              content: 'You can control and/or delete cookies as you wish. You can delete all cookies that are already on your computer and you can set most browsers to prevent them from being placed.\n\nHowever, if you do this, you may have to manually adjust some preferences every time you visit a site and some services and functionalities may not work.',
            ),

            _buildSection(
              title: 'Cookie Settings',
              content: 'You can manage your cookie preferences at any time through your browser settings or by using our cookie consent tool available on our website.',
            ),

            _buildSection(
              title: 'Changes to This Policy',
              content: 'We may update our Cookie Policy from time to time. We will notify you of any changes by posting the new Cookie Policy on this page and updating the "Last updated" date.',
            ),

            _buildSection(
              title: 'Contact Us',
              content: 'If you have any questions about our Cookie Policy, please contact us at:\n\nEmail: privacy@houseiana.com\nPhone: +974 1234 5678\nAddress: Doha, Qatar',
            ),

            const SizedBox(height: 32),

            // Accept Cookies Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Accept cookies
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
                child: const Text(
                  'Accept Cookies',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // Manage preferences
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.charcoal,
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Manage Preferences'),
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
