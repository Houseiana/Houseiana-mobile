part of 'routes.dart';

class AppRoutes {
  AppRoutes._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // ==================== Authentication ====================
      case Routes.splash:
        return _buildRoute(const SplashScreen(), settings);
      case Routes.onboarding:
        return _buildRoute(const OnboardingScreen(), settings);
      case Routes.login:
        return _buildRoute(const LoginScreen(), settings);
      case Routes.signUp:
        return _buildRoute(const SignUpScreen(), settings);
      case Routes.otpVerification:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          OtpVerificationScreen(
            phoneNumber: args?['phoneNumber']?.toString(),
            signUpId:    args?['signUpId']?.toString(),
            signInId:    args?['signInId']?.toString(),
            email:       args?['email']?.toString(),
            name:        args?['name']?.toString(),
            strategy:    args?['strategy']?.toString(),
            verifyType:  args?['verifyType']?.toString() ?? 'phone',
          ),
          settings,
        );
      case Routes.forgotPassword:
        return _buildRoute(const ForgotPasswordScreen(), settings);
      case Routes.resetPassword:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          ResetPasswordScreen(email: args?['email']),
          settings,
        );

      // ==================== Main Navigation ====================
      case Routes.bottomNav:
        return _buildRoute(const BottomNavScreen(), settings);
      case Routes.dashboard:
        return _buildRoute(const ClientDashboardScreen(), settings);

      // ==================== Property Discovery ====================
      case Routes.searchModal:
        return _buildRoute(const SearchModalScreen(), settings);
      case Routes.searchProperties:
        return _buildRoute(const SearchPropertiesScreen(), settings);
      case Routes.propertyDetails:
        return _buildRoute(const PropertyDetailsScreen(), settings);
      case Routes.discover:
        return _buildRoute(const DiscoverScreen(), settings);
      case Routes.recommendations:
        return _buildRoute(const RecommendationsScreen(), settings);
      case Routes.wishlists:
        return _buildRoute(const WishlistsScreen(), settings);

      // ==================== Messages ====================
      case Routes.conversations:
      case Routes.messages:
        return _buildRoute(const ConversationsScreen(), settings);
      case Routes.chatConversation:
        return _buildRoute(const ChatConversationScreen(), settings);
      case Routes.contactHost:
        return _buildRoute(const ContactHostScreen(), settings);

      // ==================== Profile & Settings ====================
      case Routes.accountSettings:
        return _buildRoute(const AccountSettingsScreen(), settings);
      case Routes.notificationSettings:
        return _buildRoute(const NotificationSettingsScreen(), settings);
      case Routes.privacySettings:
        return _buildRoute(const PrivacySettingsScreen(), settings);
      case Routes.languageSettings:
        return _buildRoute(const LanguageSettingsScreen(), settings);
      case Routes.currencySettings:
        return _buildRoute(const CurrencySettingsScreen(), settings);
      case Routes.paymentMethods:
        return _buildRoute(const PaymentMethodsScreen(), settings);
      case Routes.savedAddresses:
        return _buildRoute(const SavedAddressesScreen(), settings);
      case Routes.changePassword:
        return _buildRoute(const ChangePasswordScreen(), settings);
      case Routes.personalInformation:
        return _buildRoute(const PersonalInformationScreen(), settings);
      case Routes.kycVerification:
        return _buildRoute(const KycVerificationScreen(), settings);

      // ==================== Host ====================
      case Routes.becomeHost:
        return _buildRoute(const BecomeHostScreen(), settings);
      case Routes.listProperty:
        return _buildRoute(const ListPropertyScreen(), settings);
      case Routes.propertySetup:
        return _buildRoute(const PropertySetupScreen(), settings);
      case Routes.pricingSetup:
        return _buildRoute(const PricingSetupScreen(), settings);
      case Routes.availabilityCalendar:
        return _buildRoute(const AvailabilityCalendarScreen(), settings);
      case Routes.hostDashboard:
        return _buildRoute(const HostDashboardScreen(), settings);

      // ==================== Support ====================
      case Routes.helpCenter:
        return _buildRoute(const HelpCenterScreen(), settings);
      case Routes.contactSupport:
        return _buildRoute(const ContactSupportScreen(), settings);

      // ==================== Legal ====================
      case Routes.cookiePolicy:
        return _buildRoute(const CookiePolicyScreen(), settings);
      case Routes.privacyPolicy:
        return _buildRoute(const PrivacyPolicyScreen(), settings);
      case Routes.terms:
        return _buildRoute(const TermsScreen(), settings);

      // ==================== Booking ====================
      case Routes.bookingRequest:
        return _buildRoute(const BookingRequestScreen(), settings);
      case Routes.paymentMethod:
        return _buildRoute(const PaymentMethodScreen(), settings);
      case Routes.bookingConfirmation:
        return _buildRoute(const BookingConfirmationScreen(), settings);

      // ==================== Payment Status ====================
      case Routes.paymentPending:
        return _buildRoute(const PaymentPendingScreen(), settings);
      case Routes.paymentFailed:
        return _buildRoute(const PaymentFailedScreen(), settings);
      case Routes.paymentCancel:
        return _buildRoute(const PaymentCancelScreen(), settings);

      // ==================== Trips ====================
      case Routes.trips:
        return _buildRoute(const TripsScreen(), settings);
      case Routes.tripDetails:
        return _buildRoute(const TripDetailsScreen(), settings);

      // ==================== Notifications ====================
      case Routes.notifications:
        return _buildRoute(const NotificationsScreen(), settings);

      // ==================== Country Cities ====================
      case Routes.cityList:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          CityListScreen(
            countryName: args?['countryName']?.toString() ?? '',
            countryFlag: args?['countryFlag']?.toString() ?? '',
            cities: (args?['cities'] as List<dynamic>? ?? [])
                .map((e) => Map<String, String>.from(e as Map))
                .toList(),
          ),
          settings,
        );

      // ==================== Demo ====================
      case Routes.allScreensDemo:
        return _buildRoute(const AllScreensDemo(), settings);

      // ==================== Fallback ====================
      default:
        return _buildRoute(
          Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Route not found: ${settings.name}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to home
                    },
                    child: const Text('Go to Home'),
                  ),
                ],
              ),
            ),
          ),
          settings,
        );
    }
  }

  static MaterialPageRoute<dynamic> _buildRoute(
    Widget page,
    RouteSettings settings,
  ) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }
}
