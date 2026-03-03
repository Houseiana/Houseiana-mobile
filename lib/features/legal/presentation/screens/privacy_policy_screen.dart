import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';

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
        title: const Text(
          'Privacy Policy',
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
              'Privacy Policy',
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
              title: 'Introduction',
              content: 'Welcome to Houseiana. We respect your privacy and are committed to protecting your personal data. This privacy policy will inform you about how we look after your personal data when you visit our website or use our mobile application and tell you about your privacy rights and how the law protects you.',
            ),

            _buildSection(
              title: 'Information We Collect',
              content: 'We may collect, use, store and transfer different kinds of personal data about you which we have grouped together as follows:',
            ),

            _buildSubSection(
              title: 'Identity Data',
              content: 'First name, last name, username, date of birth, and gender.',
            ),

            _buildSubSection(
              title: 'Contact Data',
              content: 'Billing address, email address, and telephone numbers.',
            ),

            _buildSubSection(
              title: 'Financial Data',
              content: 'Bank account and payment card details.',
            ),

            _buildSubSection(
              title: 'Transaction Data',
              content: 'Details about payments to and from you and other details of bookings you have made.',
            ),

            _buildSubSection(
              title: 'Technical Data',
              content: 'IP address, browser type and version, time zone setting, browser plug-in types, operating system and platform.',
            ),

            _buildSubSection(
              title: 'Profile Data',
              content: 'Username, purchases made, interests, preferences, feedback, and survey responses.',
            ),

            _buildSubSection(
              title: 'Usage Data',
              content: 'Information about how you use our website and services.',
            ),

            _buildSubSection(
              title: 'Marketing Data',
              content: 'Your preferences in receiving marketing from us and your communication preferences.',
            ),

            _buildSection(
              title: 'How We Use Your Information',
              content: 'We will only use your personal data when the law allows us to. Most commonly, we will use your personal data in the following circumstances:\n\n• To register you as a new customer\n• To process and deliver your bookings\n• To manage payments, fees and charges\n• To communicate with you about your bookings\n• To manage our relationship with you\n• To improve our website and services\n• To deliver relevant content and advertisements\n• To comply with legal obligations',
            ),

            _buildSection(
              title: 'Data Security',
              content: 'We have put in place appropriate security measures to prevent your personal data from being accidentally lost, used or accessed in an unauthorized way, altered or disclosed. In addition, we limit access to your personal data to those employees, agents, contractors and other third parties who have a business need to know.',
            ),

            _buildSection(
              title: 'Data Retention',
              content: 'We will only retain your personal data for as long as necessary to fulfil the purposes we collected it for, including for the purposes of satisfying any legal, accounting, or reporting requirements.',
            ),

            _buildSection(
              title: 'Your Legal Rights',
              content: 'Under certain circumstances, you have rights under data protection laws in relation to your personal data, including the right to:\n\n• Request access to your personal data\n• Request correction of your personal data\n• Request erasure of your personal data\n• Object to processing of your personal data\n• Request restriction of processing your personal data\n• Request transfer of your personal data\n• Right to withdraw consent',
            ),

            _buildSection(
              title: 'Third-Party Links',
              content: 'Our website may include links to third-party websites, plug-ins and applications. Clicking on those links or enabling those connections may allow third parties to collect or share data about you. We do not control these third-party websites and are not responsible for their privacy statements.',
            ),

            _buildSection(
              title: 'International Transfers',
              content: 'We may transfer your personal data outside of Qatar. Whenever we transfer your personal data out of Qatar, we ensure a similar degree of protection is afforded to it by ensuring appropriate safeguards are implemented.',
            ),

            _buildSection(
              title: 'Changes to This Privacy Policy',
              content: 'We may update our privacy policy from time to time. We will notify you of any changes by posting the new privacy policy on this page and updating the "Last updated" date.',
            ),

            _buildSection(
              title: 'Contact Us',
              content: 'If you have any questions about this privacy policy or our privacy practices, please contact us:\n\nEmail: privacy@houseiana.com\nPhone: +974 1234 5678\nAddress: Doha, Qatar',
            ),

            const SizedBox(height: 32),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Download privacy data
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
                  'Download My Data',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/contact-support');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.charcoal,
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Contact Privacy Team'),
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
