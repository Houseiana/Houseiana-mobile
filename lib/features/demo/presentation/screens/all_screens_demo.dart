import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';

class AllScreensDemo extends StatelessWidget {
  const AllScreensDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'All 60+ Screens Demo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCategoryHeader('Authentication (7 screens)'),
          _buildScreenButton(context, 'Splash Screen', Routes.splash),
          _buildScreenButton(context, 'Onboarding', Routes.onboarding),
          _buildScreenButton(context, 'Login', Routes.login),
          _buildScreenButton(context, 'Sign Up', Routes.signUp),
          _buildScreenButton(context, 'OTP Verification', Routes.otpVerification),
          _buildScreenButton(context, 'Forgot Password', Routes.forgotPassword),
          _buildScreenButton(context, 'Reset Password', Routes.resetPassword),

          _buildCategoryHeader('Dashboard & Discovery (4 screens)'),
          _buildScreenButton(context, 'Client Dashboard', Routes.dashboard),
          _buildScreenButton(context, 'Discover', Routes.discover),
          _buildScreenButton(context, 'Recommendations', Routes.recommendations),
          _buildScreenButton(context, 'Wishlists', Routes.wishlists),

          _buildCategoryHeader('Property Search (3 screens)'),
          _buildScreenButton(context, 'Search Properties', Routes.searchProperties),
          _buildScreenButton(context, 'Property Details', Routes.propertyDetails),
          _buildScreenButton(context, 'Advanced Filters', Routes.advancedFilters),

          _buildCategoryHeader('Booking Flow (6 screens)'),
          _buildScreenButton(context, 'Date Selection', Routes.dateSelection),
          _buildScreenButton(context, 'Guest Selection', Routes.guestSelection),
          _buildScreenButton(context, 'Booking Request', Routes.bookingRequest),
          _buildScreenButton(context, 'Payment Method', Routes.paymentMethod),
          _buildScreenButton(context, 'Payment', Routes.payment),
          _buildScreenButton(context, 'Booking Confirmation', Routes.bookingConfirmation),

          _buildCategoryHeader('Payment Status (3 screens)'),
          _buildScreenButton(context, 'Payment Pending', Routes.paymentPending),
          _buildScreenButton(context, 'Payment Failed', Routes.paymentFailed),
          _buildScreenButton(context, 'Payment Cancelled', Routes.paymentCancel),

          _buildCategoryHeader('Trips (3 screens)'),
          _buildScreenButton(context, 'All Trips', Routes.trips),
          _buildScreenButton(context, 'Trip Details', Routes.tripDetails),
          _buildScreenButton(context, 'Notifications', Routes.notifications),

          _buildCategoryHeader('Messages (3 screens)'),
          _buildScreenButton(context, 'Conversations', Routes.conversations),
          _buildScreenButton(context, 'Chat Conversation', Routes.chatConversation),
          _buildScreenButton(context, 'Contact Host', Routes.contactHost),

          _buildCategoryHeader('Profile & Settings (11 screens)'),
          _buildScreenButton(context, 'Account Settings', Routes.accountSettings),
          _buildScreenButton(context, 'Notification Settings', Routes.notificationSettings),
          _buildScreenButton(context, 'Privacy Settings', Routes.privacySettings),
          _buildScreenButton(context, 'Language Settings', Routes.languageSettings),
          _buildScreenButton(context, 'Currency Settings', Routes.currencySettings),
          _buildScreenButton(context, 'Payment Methods', Routes.paymentMethods),
          _buildScreenButton(context, 'Saved Addresses', Routes.savedAddresses),
          _buildScreenButton(context, 'Change Password', Routes.changePassword),
          _buildScreenButton(context, 'Personal Information', Routes.personalInformation),
          _buildScreenButton(context, 'KYC Verification', Routes.kycVerification),
          _buildScreenButton(context, 'Profile', Routes.profile),

          _buildCategoryHeader('Host Features (6 screens)'),
          _buildScreenButton(context, 'Become a Host', Routes.becomeHost),
          _buildScreenButton(context, 'List Property', Routes.listProperty),
          _buildScreenButton(context, 'Property Setup', Routes.propertySetup),
          _buildScreenButton(context, 'Pricing Setup', Routes.pricingSetup),
          _buildScreenButton(context, 'Availability Calendar', Routes.availabilityCalendar),
          _buildScreenButton(context, 'Host Dashboard', Routes.hostDashboard),

          _buildCategoryHeader('Support (2 screens)'),
          _buildScreenButton(context, 'Help Center', Routes.helpCenter),
          _buildScreenButton(context, 'Contact Support', Routes.contactSupport),

          _buildCategoryHeader('Legal (3 screens)'),
          _buildScreenButton(context, 'Cookie Policy', Routes.cookiePolicy),
          _buildScreenButton(context, 'Privacy Policy', Routes.privacyPolicy),
          _buildScreenButton(context, 'Terms & Conditions', Routes.terms),

          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: const [
                Icon(Icons.check_circle, color: AppColors.primaryColor, size: 48),
                SizedBox(height: 12),
                Text(
                  '60+ Screens Available!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Tap any button above to navigate to that screen',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.neutral600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.charcoal,
        ),
      ),
    );
  }

  Widget _buildScreenButton(BuildContext context, String title, String route) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushNamed(context, route);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.charcoal,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
