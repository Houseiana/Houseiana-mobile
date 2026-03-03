import 'package:flutter/material.dart';

// Authentication Screens
import 'package:houseiana_mobile_app/features/splash/presentation/screens/splash_screen.dart';
import 'package:houseiana_mobile_app/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:houseiana_mobile_app/features/auth/presentation/screens/login_screen.dart';
import 'package:houseiana_mobile_app/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:houseiana_mobile_app/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:houseiana_mobile_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:houseiana_mobile_app/features/auth/presentation/screens/reset_password_screen.dart';

// Country & Cities
import 'package:houseiana_mobile_app/features/country/presentation/screens/city_list_screen.dart';

// Main Navigation
import 'package:houseiana_mobile_app/features/bottom_nav/presentation/screen/bottom_nav.dart';

// Property Screens
import 'package:houseiana_mobile_app/features/property_details/presentation/screens/property_details_screen.dart';
import 'package:houseiana_mobile_app/features/properties/presentation/screens/search_properties_screen.dart';
import 'package:houseiana_mobile_app/features/search/presentation/screens/search_modal_screen.dart';

// Dashboard & Discovery
import 'package:houseiana_mobile_app/features/dashboard/presentation/screens/client_dashboard_screen.dart';
import 'package:houseiana_mobile_app/features/discover/presentation/screens/discover_screen.dart';
import 'package:houseiana_mobile_app/features/recommendations/presentation/screens/recommendations_screen.dart';
import 'package:houseiana_mobile_app/features/favorites/presentation/screens/wishlists_screen.dart';

// Notifications
import 'package:houseiana_mobile_app/features/notifications/presentation/screens/notifications_screen.dart';

// Demo
import 'package:houseiana_mobile_app/features/demo/presentation/screens/all_screens_demo.dart';

// Messages
import 'package:houseiana_mobile_app/features/messages/presentation/screens/conversations_screen.dart';
import 'package:houseiana_mobile_app/features/messages/presentation/screens/chat_conversation_screen.dart';
import 'package:houseiana_mobile_app/features/messages/presentation/screens/contact_host_screen.dart';

// Profile & Settings
import 'package:houseiana_mobile_app/features/profile/presentation/screens/account_settings_screen.dart';
import 'package:houseiana_mobile_app/features/profile/presentation/screens/notification_settings_screen.dart';
import 'package:houseiana_mobile_app/features/profile/presentation/screens/privacy_settings_screen.dart';
import 'package:houseiana_mobile_app/features/profile/presentation/screens/language_settings_screen.dart';
import 'package:houseiana_mobile_app/features/profile/presentation/screens/currency_settings_screen.dart';
import 'package:houseiana_mobile_app/features/profile/presentation/screens/payment_methods_screen.dart';
import 'package:houseiana_mobile_app/features/profile/presentation/screens/saved_addresses_screen.dart';
import 'package:houseiana_mobile_app/features/profile/presentation/screens/change_password_screen.dart';
import 'package:houseiana_mobile_app/features/profile/presentation/screens/personal_information_screen.dart';
import 'package:houseiana_mobile_app/features/profile/presentation/screens/kyc_verification_screen.dart';

// Host Screens
import 'package:houseiana_mobile_app/features/host/presentation/screens/become_host_screen.dart';
import 'package:houseiana_mobile_app/features/host/presentation/screens/list_property_screen.dart';
import 'package:houseiana_mobile_app/features/host/presentation/screens/property_setup_screen.dart';
import 'package:houseiana_mobile_app/features/host/presentation/screens/pricing_setup_screen.dart';
import 'package:houseiana_mobile_app/features/host/presentation/screens/availability_calendar_screen.dart';
import 'package:houseiana_mobile_app/features/host/presentation/screens/host_dashboard_screen.dart';

// Support
import 'package:houseiana_mobile_app/features/support/presentation/screens/help_center_screen.dart';
import 'package:houseiana_mobile_app/features/support/presentation/screens/contact_support_screen.dart';

// Legal
import 'package:houseiana_mobile_app/features/legal/presentation/screens/cookie_policy_screen.dart';
import 'package:houseiana_mobile_app/features/legal/presentation/screens/privacy_policy_screen.dart';
import 'package:houseiana_mobile_app/features/legal/presentation/screens/terms_screen.dart';

// Booking
import 'package:houseiana_mobile_app/features/booking/presentation/screens/booking_request_screen.dart';
import 'package:houseiana_mobile_app/features/booking/presentation/screens/payment_method_screen.dart';
import 'package:houseiana_mobile_app/features/booking/presentation/screens/booking_confirmation_screen.dart';

// Payment Status
import 'package:houseiana_mobile_app/features/booking/presentation/screens/payment_pending_screen.dart';
import 'package:houseiana_mobile_app/features/booking/presentation/screens/payment_failed_screen.dart';
import 'package:houseiana_mobile_app/features/booking/presentation/screens/payment_cancel_screen.dart';

// Trips
import 'package:houseiana_mobile_app/features/trips/presentation/screens/trips_screen.dart';
import 'package:houseiana_mobile_app/features/trips/presentation/screens/trip_details_screen.dart';

part 'app_routes.dart';

class Routes {
  Routes._();

  // Authentication
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signUp = '/sign-up';
  static const String otpVerification = '/otp-verification';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // Main Navigation
  static const String bottomNav = '/bottom-nav';
  static const String home = '/home';
  static const String dashboard = '/dashboard';

  // Property Discovery
  static const String properties = '/properties';
  static const String searchProperties = '/search-properties';
  static const String propertyDetails = '/property-details';
  static const String discover = '/discover';
  static const String recommendations = '/recommendations';
  static const String wishlists = '/wishlists';

  // Property Details Sub-screens
  static const String photoGallery = '/photo-gallery';
  static const String amenities = '/amenities';
  static const String reviews = '/reviews';
  static const String hostProfile = '/host-profile';
  static const String locationMap = '/location-map';

  // Booking
  static const String dateSelection = '/date-selection';
  static const String guestSelection = '/guest-selection';
  static const String bookingRequest = '/booking-request';
  static const String paymentMethod = '/payment-method';
  static const String payment = '/payment';
  static const String bookingConfirmation = '/booking-confirmation';

  // Payment Status
  static const String paymentPending = '/payment-pending';
  static const String paymentFailed = '/payment-failed';
  static const String paymentCancel = '/payment-cancel';

  // Search Modal
  static const String searchModal = '/search-modal';

  // Filters & Search
  static const String advancedFilters = '/advanced-filters';
  static const String locationSearch = '/location-search';
  static const String mapFullScreen = '/map-full-screen';
  static const String priceRangeFilter = '/price-range-filter';

  // Trips
  static const String trips = '/trips';
  static const String upcomingTrips = '/upcoming-trips';
  static const String pastTrips = '/past-trips';
  static const String tripDetails = '/trip-details';

  // Messages
  static const String conversations = '/conversations';
  static const String messages = '/messages';
  static const String chatConversation = '/chat-conversation';
  static const String contactHost = '/contact-host';

  // Profile & Settings
  static const String profile = '/profile';
  static const String accountSettings = '/account-settings';
  static const String notificationSettings = '/notification-settings';
  static const String privacySettings = '/privacy-settings';
  static const String languageSettings = '/language-settings';
  static const String currencySettings = '/currency-settings';
  static const String paymentMethods = '/payment-methods';
  static const String savedAddresses = '/saved-addresses';
  static const String changePassword = '/change-password';
  static const String personalInformation = '/personal-information';
  static const String kycVerification = '/kyc-verification';

  // Host
  static const String becomeHost = '/become-host';
  static const String listProperty = '/list-property';
  static const String propertySetup = '/property-setup';
  static const String pricingSetup = '/pricing-setup';
  static const String availabilityCalendar = '/availability-calendar';
  static const String hostDashboard = '/host-dashboard';

  // Support
  static const String helpCenter = '/help-center';
  static const String contactSupport = '/contact-support';

  // Legal
  static const String cookiePolicy = '/cookie-policy';
  static const String privacyPolicy = '/privacy-policy';
  static const String terms = '/terms';

  // Country Cities
  static const String cityList = '/city-list';

  // Other
  static const String favorites = '/favorites';
  static const String chat = '/chat';
  static const String notifications = '/notifications';

  // Demo
  static const String allScreensDemo = '/all-screens-demo';
}
