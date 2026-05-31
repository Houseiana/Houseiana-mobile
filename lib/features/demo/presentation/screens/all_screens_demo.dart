import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

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
        title: Text(
          context.tr('wizard.demoTitle'),
          style: const TextStyle(
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
          _buildCategoryHeader(context.tr('wizard.demoCatAuth')),
          _buildScreenButton(context, context.tr('wizard.screenSplash'), Routes.splash),
          _buildScreenButton(context, context.tr('wizard.screenOnboarding'), Routes.onboarding),
          _buildScreenButton(context, context.tr('wizard.screenLogin'), Routes.login),
          _buildScreenButton(context, context.tr('wizard.screenSignUp'), Routes.signUp),
          _buildScreenButton(context, context.tr('wizard.screenOtp'), Routes.otpVerification),
          _buildScreenButton(context, context.tr('wizard.screenForgotPassword'), Routes.forgotPassword),
          _buildScreenButton(context, context.tr('wizard.screenResetPassword'), Routes.resetPassword),

          _buildCategoryHeader(context.tr('wizard.demoCatDashboard')),
          _buildScreenButton(context, context.tr('wizard.screenClientDashboard'), Routes.dashboard),
          _buildScreenButton(context, context.tr('wizard.screenDiscover'), Routes.discover),
          _buildScreenButton(context, context.tr('wizard.screenRecommendations'), Routes.recommendations),
          _buildScreenButton(context, context.tr('wizard.screenWishlists'), Routes.wishlists),

          _buildCategoryHeader(context.tr('wizard.demoCatSearch')),
          _buildScreenButton(context, context.tr('wizard.screenSearchProperties'), Routes.searchProperties),
          _buildScreenButton(context, context.tr('wizard.screenPropertyDetails'), Routes.propertyDetails),
          _buildScreenButton(context, context.tr('wizard.screenAdvancedFilters'), Routes.advancedFilters),

          _buildCategoryHeader(context.tr('wizard.demoCatBooking')),
          _buildScreenButton(context, context.tr('wizard.screenDateSelection'), Routes.dateSelection),
          _buildScreenButton(context, context.tr('wizard.screenGuestSelection'), Routes.guestSelection),
          _buildScreenButton(context, context.tr('wizard.screenBookingRequest'), Routes.bookingRequest),
          _buildScreenButton(context, context.tr('wizard.screenPaymentMethod'), Routes.paymentMethod),
          _buildScreenButton(context, context.tr('wizard.screenPayment'), Routes.payment),
          _buildScreenButton(context, context.tr('wizard.screenBookingConfirmation'), Routes.bookingConfirmation),

          _buildCategoryHeader(context.tr('wizard.demoCatPayment')),
          _buildScreenButton(context, context.tr('wizard.screenPaymentPending'), Routes.paymentPending),
          _buildScreenButton(context, context.tr('wizard.screenPaymentFailed'), Routes.paymentFailed),
          _buildScreenButton(context, context.tr('wizard.screenPaymentCancelled'), Routes.paymentCancel),

          _buildCategoryHeader(context.tr('wizard.demoCatTrips')),
          _buildScreenButton(context, context.tr('wizard.screenAllTrips'), Routes.trips),
          _buildScreenButton(context, context.tr('wizard.screenTripDetails'), Routes.tripDetails),
          _buildScreenButton(context, context.tr('wizard.screenNotifications'), Routes.notifications),

          _buildCategoryHeader(context.tr('wizard.demoCatMessages')),
          _buildScreenButton(context, context.tr('wizard.screenConversations'), Routes.conversations),
          _buildScreenButton(context, context.tr('wizard.screenChatConversation'), Routes.chatConversation),
          _buildScreenButton(context, context.tr('wizard.screenContactHost'), Routes.contactHost),

          _buildCategoryHeader(context.tr('wizard.demoCatProfile')),
          _buildScreenButton(context, context.tr('wizard.screenAccountSettings'), Routes.accountSettings),
          _buildScreenButton(context, context.tr('wizard.screenNotificationSettings'), Routes.notificationSettings),
          _buildScreenButton(context, context.tr('wizard.screenPrivacySettings'), Routes.privacySettings),
          _buildScreenButton(context, context.tr('wizard.screenLanguageSettings'), Routes.languageSettings),
          _buildScreenButton(context, context.tr('wizard.screenCurrencySettings'), Routes.currencySettings),
          _buildScreenButton(context, context.tr('wizard.screenPaymentMethods'), Routes.paymentMethods),
          _buildScreenButton(context, context.tr('wizard.screenSavedAddresses'), Routes.savedAddresses),
          _buildScreenButton(context, context.tr('wizard.screenChangePassword'), Routes.changePassword),
          _buildScreenButton(context, context.tr('wizard.screenPersonalInfo'), Routes.personalInformation),
          _buildScreenButton(context, context.tr('wizard.screenKyc'), Routes.kycVerification),
          _buildScreenButton(context, context.tr('wizard.screenProfile'), Routes.profile),

          _buildCategoryHeader(context.tr('wizard.demoCatHost')),
          _buildScreenButton(context, context.tr('wizard.screenBecomeHost'), Routes.becomeHost),
          _buildScreenButton(context, context.tr('wizard.screenListProperty'), Routes.listProperty),
          _buildScreenButton(context, context.tr('wizard.screenPropertySetup'), Routes.propertySetup),
          _buildScreenButton(context, context.tr('wizard.screenPricingSetup'), Routes.pricingSetup),
          _buildScreenButton(context, context.tr('wizard.screenAvailabilityCalendar'), Routes.availabilityCalendar),
          _buildScreenButton(context, context.tr('wizard.screenHostDashboard'), Routes.hostDashboard),

          _buildCategoryHeader(context.tr('wizard.demoCatSupport')),
          _buildScreenButton(context, context.tr('wizard.screenHelpCenter'), Routes.helpCenter),
          _buildScreenButton(context, context.tr('wizard.screenContactSupport'), Routes.contactSupport),

          _buildCategoryHeader(context.tr('wizard.demoCatLegal')),
          _buildScreenButton(context, context.tr('wizard.screenCookiePolicy'), Routes.cookiePolicy),
          _buildScreenButton(context, context.tr('wizard.screenPrivacyPolicy'), Routes.privacyPolicy),
          _buildScreenButton(context, context.tr('wizard.screenTerms'), Routes.terms),

          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(Icons.check_circle, color: AppColors.primaryColor, size: 48),
                const SizedBox(height: 12),
                Text(
                  context.tr('wizard.demoScreensAvailable'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('wizard.demoTapButton'),
                  style: const TextStyle(
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
