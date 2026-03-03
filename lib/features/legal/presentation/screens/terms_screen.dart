import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
          'Terms & Conditions',
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
              'Terms and Conditions',
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
              title: 'Agreement to Terms',
              content: 'By accessing and using Houseiana, you agree to be bound by these Terms and Conditions and our Privacy Policy. If you do not agree to these terms, please do not use our services.',
            ),

            _buildSection(
              title: 'Use of Services',
              content: 'Houseiana provides an online platform that enables users to list, discover, and book short-term accommodations around the world. You must be at least 18 years old to use our services.',
            ),

            _buildSection(
              title: 'Account Registration',
              content: 'To access certain features of our platform, you must register for an account. You agree to:\n\n• Provide accurate, current, and complete information\n• Maintain and update your information\n• Keep your password secure and confidential\n• Accept responsibility for all activities under your account\n• Notify us immediately of any unauthorized use',
            ),

            _buildSection(
              title: 'Guest Responsibilities',
              content: 'As a guest, you agree to:\n\n• Treat properties with respect and care\n• Follow house rules set by hosts\n• Leave properties in the same condition as you found them\n• Pay all fees and charges on time\n• Comply with all applicable laws and regulations\n• Not exceed the maximum number of guests',
            ),

            _buildSection(
              title: 'Host Responsibilities',
              content: 'As a host, you agree to:\n\n• Provide accurate descriptions and photos of your property\n• Honor confirmed bookings\n• Maintain your property in good condition\n• Comply with all applicable laws and regulations\n• Have proper insurance coverage\n• Pay applicable service fees\n• Respond to booking requests and messages promptly',
            ),

            _buildSection(
              title: 'Booking and Payment',
              content: 'When you make a booking, you agree to pay all charges, including:\n\n• Accommodation fees\n• Service fees\n• Cleaning fees\n• Additional guest fees\n• Applicable taxes\n\nPayment is processed through our secure payment system. We use third-party payment processors and do not store your complete payment information.',
            ),

            _buildSection(
              title: 'Cancellation Policy',
              content: 'Cancellation policies vary by listing and are set by the host. Please review the cancellation policy before booking. Refunds are subject to the applicable cancellation policy.\n\nIn certain circumstances, we may allow cancellations outside the standard policy for events like natural disasters or other extenuating circumstances.',
            ),

            _buildSection(
              title: 'Service Fees',
              content: 'Houseiana charges service fees to both guests and hosts. These fees help cover the costs of running the platform, including customer support, payment processing, and insurance.\n\n• Guest service fee: Typically 10-15% of the booking subtotal\n• Host service fee: Typically 3-5% of the booking subtotal',
            ),

            _buildSection(
              title: 'Reviews and Ratings',
              content: 'After each booking, guests and hosts can leave reviews. Reviews must be:\n\n• Honest and accurate\n• Based on personal experience\n• Respectful and non-discriminatory\n• Free from conflicts of interest\n• Compliant with our content policy\n\nWe reserve the right to remove reviews that violate these guidelines.',
            ),

            _buildSection(
              title: 'Prohibited Activities',
              content: 'You may not:\n\n• Violate any laws or regulations\n• Discriminate against others\n• Post false or misleading information\n• Interfere with or disrupt our services\n• Attempt to gain unauthorized access\n• Use our platform for commercial purposes without authorization\n• Harass, abuse, or harm others\n• Circumvent service fees',
            ),

            _buildSection(
              title: 'Intellectual Property',
              content: 'All content on Houseiana, including text, graphics, logos, images, and software, is our property or that of our licensors and is protected by intellectual property laws. You may not use our content without permission.',
            ),

            _buildSection(
              title: 'Limitation of Liability',
              content: 'To the maximum extent permitted by law, Houseiana and its affiliates shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising out of or related to your use of our services.',
            ),

            _buildSection(
              title: 'Dispute Resolution',
              content: 'Any disputes arising from these terms or your use of our services shall be resolved through binding arbitration in accordance with the laws of Qatar. You waive your right to participate in class action lawsuits.',
            ),

            _buildSection(
              title: 'Changes to Terms',
              content: 'We reserve the right to modify these terms at any time. We will notify you of significant changes by email or through our platform. Your continued use of our services after such changes constitutes acceptance of the new terms.',
            ),

            _buildSection(
              title: 'Termination',
              content: 'We may suspend or terminate your account and access to our services at any time, with or without notice, for any reason, including if you violate these terms.',
            ),

            _buildSection(
              title: 'Governing Law',
              content: 'These terms shall be governed by and construed in accordance with the laws of Qatar, without regard to its conflict of law provisions.',
            ),

            _buildSection(
              title: 'Contact Information',
              content: 'If you have any questions about these Terms and Conditions, please contact us:\n\nEmail: legal@houseiana.com\nPhone: +974 1234 5678\nAddress: Doha, Qatar',
            ),

            const SizedBox(height: 32),

            // Action Buttons
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
                child: const Text(
                  'I Agree',
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
                child: const Text('Contact Legal Team'),
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
      ),
    );
  }
}
