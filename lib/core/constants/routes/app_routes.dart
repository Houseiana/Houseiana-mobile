part of 'routes.dart';

class AppRoutes {
  AppRoutes._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // ==================== Authentication ====================
      case Routes.splash:
        return _buildRoute(const SplashScreen(), settings);
      case Routes.forceUpdate:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          ForceUpdateScreen(
            updateUrl: args?['updateUrl']?.toString() ?? '',
          ),
          settings,
        );
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
            signUpId: args?['signUpId']?.toString(),
            signInId: args?['signInId']?.toString(),
            email: args?['email']?.toString(),
            name: args?['name']?.toString(),
            strategy: args?['strategy']?.toString(),
            verifyType: args?['verifyType']?.toString() ?? 'phone',
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
      case Routes.home:
        return _buildRoute(const BottomNavScreen(), settings);
      case Routes.dashboard:
        return _buildRoute(const ClientDashboardScreen(), settings);
      case Routes.properties:
        return _buildRoute(const PropertiesScreen(), settings);

      // ==================== Property Discovery ====================
      case Routes.searchModal:
        return _buildRoute(const SearchModalScreen(), settings);
      case Routes.advancedFilters:
        return _buildRoute(const AdvancedFiltersScreen(), settings);
      case Routes.locationSearch:
        return _buildRoute(const LocationSearchScreen(), settings);
      case Routes.mapFullScreen:
        return _buildRoute(const MapFullScreen(), settings);
      case Routes.priceRangeFilter:
        return _buildRoute(const PriceRangeFilterScreen(), settings);
      case Routes.searchProperties:
        return _buildRoute(
          BlocProvider(
            create: (_) => sl<SearchCubit>(),
            child: const SearchPropertiesScreen(),
          ),
          settings,
        );
      case Routes.propertyDetails:
        final propertyId = _extractPropertyId(settings.arguments);
        return _buildRoute(
          BlocProvider(
            create: (_) => sl<PropertyDetailsCubit>(),
            child: PropertyDetailsScreen(propertyIdToLoad: propertyId),
          ),
          settings,
        );
      case Routes.amenities:
        final args = settings.arguments as Map<String, dynamic>?;
        final categories = args?['categories'];
        return _buildRoute(
          AmenitiesScreen(
            categories: categories is List<AmenityCategory> ? categories : const [],
          ),
          settings,
        );
      case Routes.reviews:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          BlocProvider(
            create: (_) => sl<PropertyDetailsCubit>(),
            child: ReviewsScreen(
              propertyId: args?['propertyId']?.toString(),
              averageRating:
                  (args?['averageRating'] as num?)?.toDouble() ?? 0,
              totalReviews: (args?['totalReviews'] as num?)?.toInt() ?? 0,
            ),
          ),
          settings,
        );
      case Routes.locationMap:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          LocationMapScreen(
            propertyName: args?['propertyName']?.toString(),
            title: args?['title']?.toString(),
            address: args?['address']?.toString() ?? '',
            lat: (args?['lat'] as num?)?.toDouble() ?? 0,
            lng: (args?['lng'] as num?)?.toDouble() ?? 0,
          ),
          settings,
        );
      case Routes.nightlyPricesCalendar:
        final args = settings.arguments as Map<String, dynamic>?;
        final propertyId = args?['propertyId']?.toString() ?? '';
        final currency = args?['currency']?.toString() ?? 'EGP';
        return _buildRoute<Map<String, DateTime>>(
          BlocProvider(
            create: (_) => sl<NightlyPricesCubit>(param1: propertyId),
            child: NightlyPricesCalendarScreen(currency: currency),
          ),
          settings,
        );
      case Routes.hostProfile:
        final args = settings.arguments as Map?;
        final host = args?['host'] as Map? ?? {};
        final firstName = (host['firstName'] ?? '').toString();
        final lastName = (host['lastName'] ?? '').toString();
        final name = '$firstName $lastName'.trim().isEmpty
            ? 'Host'
            : '$firstName $lastName'.trim();
        final photoUrl =
            (host['profilePicture'] ?? host['avatar'] ?? host['photo'] ?? '')
                .toString();
        final hostId = (host['_id'] ?? host['id'] ?? '').toString();
        final joinedRaw = host['createdAt']?.toString() ?? '';
        String joined = '2024';
        if (joinedRaw.length >= 4) joined = joinedRaw.substring(0, 4);
        final rating = double.tryParse(host['rating']?.toString() ?? '') ?? 0.0;
        final reviews = int.tryParse(host['reviewsCount']?.toString() ??
                host['totalReviews']?.toString() ??
                '') ??
            0;
        return _buildRoute(
          HostProfileScreen(
            hostName: name,
            hostPhotoUrl: photoUrl.isEmpty ? null : photoUrl,
            joinedDate: joined,
            rating: rating,
            reviewsCount: reviews,
            bio: host['bio']?.toString(),
            isSuperhost: host['isSuperhost'] == true,
            hostId: hostId.isEmpty ? null : hostId,
          ),
          settings,
        );
      case Routes.discover:
        return _buildRoute(const DiscoverScreen(), settings);
      case Routes.recommendations:
        return _buildRoute(const RecommendationsScreen(), settings);
      case Routes.wishlists:
        return _buildRoute(const WishlistsScreen(), settings);
      case Routes.favorites:
        return _buildRoute(const FavoritesScreen(), settings);

      // ==================== Messages ====================
      case Routes.conversations:
      case Routes.messages:
        return _buildRoute(const ConversationsScreen(), settings);
      case Routes.chatConversation:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          BlocProvider(
            create: (_) => sl<ChatCubit>(),
            child: ChatConversationScreen(conversation: args),
          ),
          settings,
        );
      case Routes.contactHost:
        return _buildRoute(const ContactHostScreen(), settings);

      // ==================== Profile & Settings ====================
      case Routes.profile:
        return _buildRoute(const ProfileScreen(), settings);
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
        return _buildRoute(
          BlocProvider(
            create: (_) => sl<PaymentMethodsCubit>()..loadPaymentMethods(),
            child: const PaymentMethodsScreen(),
          ),
          settings,
        );
      case Routes.paymentHistory:
        return _buildRoute(const PaymentHistoryScreen(), settings);
      case Routes.savedAddresses:
        return _buildRoute(
          BlocProvider(
            create: (_) => sl<SavedAddressesCubit>()..loadAddresses(),
            child: const SavedAddressesScreen(),
          ),
          settings,
        );
      case Routes.changePassword:
        return _buildRoute(const ChangePasswordScreen(), settings);
      case Routes.personalInformation:
        return _buildRoute(const PersonalInformationScreen(), settings);
      case Routes.kycVerification:
        return _buildRoute(
          BlocProvider(
            create: (_) => sl<KycCubit>(),
            child: const KycVerificationScreen(),
          ),
          settings,
        );

      // ==================== Host ====================
      case Routes.becomeHost:
        return _buildRoute(const BecomeHostScreen(), settings);
      case Routes.listProperty:
        return _buildRoute(const PropertyWizardScreen(), settings);
      case Routes.propertySetup:
        return _buildRoute(const PropertySetupScreen(), settings);
      case Routes.pricingSetup:
        return _buildRoute(const PricingSetupScreen(), settings);
      case Routes.availabilityCalendar:
        return _buildRoute(const AvailabilityCalendarScreen(), settings);
      case Routes.hostDashboard:
        return _buildRoute(const HostDashboardScreen(), settings);
      case Routes.hostListings:
        return _buildRoute(const HostListingsScreen(), settings);
      case Routes.hostBookings:
        return _buildRoute(
          BlocProvider(
            create: (_) => sl<HostBookingsCubit>()..loadBookings(),
            child: const HostBookingsScreen(),
          ),
          settings,
        );
      case Routes.hostEarnings:
        return _buildRoute(const HostEarningsScreen(), settings);
      case Routes.hostPayout:
        return _buildRoute(const HostPayoutScreen(), settings);
      case Routes.hostReviews:
        return _buildRoute(const HostReviewsScreen(), settings);
      case Routes.propertyWizard:
        return _buildRoute(const PropertyWizardScreen(), settings);

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
      case Routes.dateSelection:
        return _buildRoute(const DateSelectionScreen(), settings);
      case Routes.guestSelection:
        return _buildRoute(const GuestSelectionScreen(), settings);
      case Routes.bookingRequest:
        return _buildRoute(
          BlocProvider(
            create: (_) => sl<BookingCubit>(),
            child: const BookingRequestScreen(),
          ),
          settings,
        );
      case Routes.payment:
        return _buildRoute(const PaymentMethodScreen(), settings);
      case Routes.paymentMethod:
        return _buildRoute(const PaymentMethodScreen(), settings);
      case Routes.bookingConfirmation:
        return _buildRoute(const BookingConfirmationScreen(), settings);
      case Routes.sadadWebView:
        final sadadArgs = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          SadadWebViewScreen(
            paymentUrl: sadadArgs?['paymentUrl'] ?? '',
            bookingId: sadadArgs?['bookingId'] ?? '',
            orderId: sadadArgs?['orderId'] ?? '',
            formAction: sadadArgs?['formAction']?.toString(),
            formData: sadadArgs?['formData'] is Map
                ? Map<String, dynamic>.from(sadadArgs?['formData'] as Map)
                : null,
          ),
          settings,
        );
      case Routes.paypalWebView:
        final paypalArgs = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          PaypalWebViewScreen(
            approvalUrl: paypalArgs?['approvalUrl'] ?? '',
            bookingId: paypalArgs?['bookingId'] ?? '',
            orderId: paypalArgs?['orderId'] ?? '',
            userId: paypalArgs?['userId'] ?? '',
          ),
          settings,
        );
      case Routes.externalPaymentWebView:
        final paymentArgs = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          ExternalPaymentWebViewScreen(
            title: paymentArgs?['title']?.toString() ?? 'Payment',
            paymentUrl: paymentArgs?['paymentUrl']?.toString() ?? '',
            bookingId: paymentArgs?['bookingId']?.toString() ?? '',
            provider: paymentArgs?['provider']?.toString() ?? '',
            intentionId: paymentArgs?['intentionId']?.toString(),
          ),
          settings,
        );
      case Routes.reviewProperty:
        final reviewArgs = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          ReviewPropertyScreen(
            bookingId: reviewArgs?['bookingId']?.toString(),
            propertyId: reviewArgs?['propertyId']?.toString(),
          ),
          settings,
        );

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
        return _buildRoute(
          BlocProvider(
            create: (_) => sl<NotificationsCubit>()..loadNotifications(),
            child: const NotificationsScreen(),
          ),
          settings,
        );

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

  static MaterialPageRoute<T> _buildRoute<T>(
    Widget page,
    RouteSettings settings,
  ) {
    return MaterialPageRoute<T>(
      builder: (_) => page,
      settings: settings,
    );
  }

  static String _extractPropertyId(Object? arguments) {
    if (arguments is String) return arguments;
    if (arguments is Map) {
      final direct = arguments['propertyId'] ??
          arguments['id'] ??
          arguments['_id'];
      if (direct != null && direct.toString().isNotEmpty) {
        return direct.toString();
      }
      final property = arguments['property'];
      if (property is Map) {
        final nested = property['propertyId'] ??
            property['id'] ??
            property['_id'];
        if (nested != null) return nested.toString();
      }
    }
    return '';
  }
}
