part of 'routes.dart';

class AppRoutes {
  AppRoutes._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // ==================== Authentication ====================
      case Routes.splash:
        return _buildRoute(() => SplashScreen(), settings);
      case Routes.forceUpdate:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          () => ForceUpdateScreen(
            updateUrl: args?['updateUrl']?.toString() ?? '',
          ),
          settings,
        );
      case Routes.onboarding:
        return _buildRoute(() => OnboardingScreen(), settings);
      case Routes.login:
        return _buildRoute(() => LoginScreen(), settings);
      case Routes.signUp:
        return _buildRoute(() => SignUpScreen(), settings);
      case Routes.otpVerification:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          () => OtpVerificationScreen(
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
        return _buildRoute(() => ForgotPasswordScreen(), settings);
      case Routes.resetPassword:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          () => ResetPasswordScreen(email: args?['email']),
          settings,
        );

      // ==================== Main Navigation ====================
      case Routes.bottomNav:
        return _buildRoute(() => BottomNavScreen(), settings);
      case Routes.home:
        return _buildRoute(() => BottomNavScreen(), settings);
      case Routes.dashboard:
        return _buildRoute(() => ClientDashboardScreen(), settings);
      case Routes.properties:
        return _buildRoute(() => PropertiesScreen(), settings);

      // ==================== Property Discovery ====================
      case Routes.searchModal:
        return _buildRoute(() => SearchModalScreen(), settings);
      case Routes.advancedFilters:
        return _buildRoute(() => AdvancedFiltersScreen(), settings);
      case Routes.locationSearch:
        return _buildRoute(() => LocationSearchScreen(), settings);
      case Routes.mapFullScreen:
        return _buildRoute(() => MapFullScreen(), settings);
      case Routes.priceRangeFilter:
        return _buildRoute(() => PriceRangeFilterScreen(), settings);
      case Routes.searchProperties:
        return _buildRoute(
          () => BlocProvider(
            create: (_) => sl<SearchCubit>(),
            child: SearchPropertiesScreen(),
          ),
          settings,
        );
      case Routes.propertyDetails:
        final propertyId = _extractPropertyId(settings.arguments);
        return _buildRoute(
          () => BlocProvider(
            create: (_) => sl<PropertyDetailsCubit>(),
            child: PropertyDetailsScreen(propertyIdToLoad: propertyId),
          ),
          settings,
        );
      case Routes.amenities:
        final args = settings.arguments as Map<String, dynamic>?;
        final categories = args?['categories'];
        return _buildRoute(
          () => AmenitiesScreen(
            categories:
                categories is List<AmenityCategory> ? categories : const [],
          ),
          settings,
        );
      case Routes.reviews:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          () => BlocProvider(
            create: (_) => sl<PropertyDetailsCubit>(),
            child: ReviewsScreen(
              propertyId: args?['propertyId']?.toString(),
              averageRating: (args?['averageRating'] as num?)?.toDouble() ?? 0,
              totalReviews: (args?['totalReviews'] as num?)?.toInt() ?? 0,
            ),
          ),
          settings,
        );
      case Routes.locationMap:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          () => LocationMapScreen(
            propertyName: args?['propertyName']?.toString(),
            title: args?['title']?.toString(),
            address: args?['address']?.toString() ?? '',
            lat: (args?['lat'] as num?)?.toDouble() ?? 0,
            lng: (args?['lng'] as num?)?.toDouble() ?? 0,
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
          () => HostProfileScreen(
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
      case Routes.ownerProfile:
        final args = settings.arguments as Map<String, dynamic>?;
        final userId = (args?['userId'] ?? args?['id'] ?? '').toString();
        return _buildRoute(
          () => BlocProvider(
            create: (_) => sl<OwnerProfileCubit>()..load(userId),
            child: OwnerProfileScreen(userId: userId),
          ),
          settings,
        );
      case Routes.discover:
        return _buildRoute(() => DiscoverScreen(), settings);
      case Routes.recommendations:
        return _buildRoute(() => RecommendationsScreen(), settings);
      case Routes.wishlists:
        return _buildRoute(() => WishlistsScreen(), settings);
      case Routes.favorites:
        return _buildRoute(() => FavoritesScreen(), settings);

      // ==================== Messages ====================
      case Routes.conversations:
      case Routes.messages:
        return _buildRoute(() => ConversationsScreen(), settings);
      case Routes.chatConversation:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          () => BlocProvider(
            create: (_) => sl<ChatCubit>(),
            child: ChatConversationScreen(conversation: args),
          ),
          settings,
        );
      case Routes.contactHost:
        return _buildRoute(() => ContactHostScreen(), settings);

      // ==================== Profile & Settings ====================
      case Routes.profile:
        return _buildRoute(() => ProfileScreen(), settings);
      case Routes.accountSettings:
        return _buildRoute(() => AccountSettingsScreen(), settings);
      case Routes.notificationSettings:
        return _buildRoute(() => NotificationSettingsScreen(), settings);
      case Routes.privacySettings:
        return _buildRoute(() => PrivacySettingsScreen(), settings);
      case Routes.languageSettings:
        return _buildRoute(() => LanguageSettingsScreen(), settings);
      case Routes.appearanceSettings:
        return _buildRoute(() => AppearanceSettingsScreen(), settings);
      case Routes.paymentMethods:
        return _buildRoute(
          () => BlocProvider(
            create: (_) => sl<PaymentMethodsCubit>()..loadPaymentMethods(),
            child: PaymentMethodsScreen(),
          ),
          settings,
        );
      case Routes.paymentHistory:
        return _buildRoute(() => PaymentHistoryScreen(), settings);
      case Routes.savedAddresses:
        return _buildRoute(
          () => BlocProvider(
            create: (_) => sl<SavedAddressesCubit>()..loadAddresses(),
            child: SavedAddressesScreen(),
          ),
          settings,
        );
      case Routes.changePassword:
        return _buildRoute(() => ChangePasswordScreen(), settings);
      case Routes.personalInformation:
        return _buildRoute(() => PersonalInformationScreen(), settings);
      case Routes.kycVerification:
        return _buildRoute(() => IdentityVerificationScreen(), settings);

      // ==================== Host ====================
      case Routes.becomeHost:
        return _buildRoute(() => BecomeHostScreen(), settings);
      case Routes.listProperty:
        {
          final args = settings.arguments as Map<String, dynamic>?;
          final editId = args?['propertyId']?.toString();
          return _buildRoute(
            () => PropertyWizardScreen(editPropertyId: editId),
            settings,
          );
        }
      case Routes.propertySetup:
        return _buildRoute(() => PropertySetupScreen(), settings);
      case Routes.pricingSetup:
        return _buildRoute(() => PricingSetupScreen(), settings);
      case Routes.availabilityCalendar:
        return _buildRoute(() => AvailabilityCalendarScreen(), settings);
      case Routes.hostCalendar:
        final args = settings.arguments as Map<String, dynamic>?;
        final propertyId = args?['propertyId']?.toString();
        return _buildRoute(
          () => BlocProvider(
            create: (_) => sl<HostCalendarManagementCubit>()
              ..init(initialPropertyId: propertyId),
            child: HostCalendarScreen(),
          ),
          settings,
        );
      case Routes.hostDashboard:
        return _buildRoute(() => HostDashboardScreen(), settings);
      case Routes.hostListings:
        return _buildRoute(() => HostListingsScreen(), settings);
      case Routes.hostBookings:
        return _buildRoute(
          () => BlocProvider(
            create: (_) => sl<HostBookingsCubit>()..loadBookings(),
            child: HostBookingsScreen(),
          ),
          settings,
        );
      case Routes.hostPayout:
        return _buildRoute(() => HostPayoutScreen(), settings);
      case Routes.hostReviews:
        return _buildRoute(() => HostReviewsScreen(), settings);
      case Routes.propertyWizard:
        {
          final args = settings.arguments as Map<String, dynamic>?;
          final editId = args?['propertyId']?.toString();
          return _buildRoute(
            () => PropertyWizardScreen(editPropertyId: editId),
            settings,
          );
        }

      // ==================== Support ====================
      case Routes.helpCenter:
        return _buildRoute(() => HelpCenterScreen(), settings);
      case Routes.contactSupport:
        return _buildRoute(() => ContactSupportScreen(), settings);

      // ==================== Legal ====================
      case Routes.cookiePolicy:
        return _buildRoute(() => CookiePolicyScreen(), settings);
      case Routes.privacyPolicy:
        return _buildRoute(() => PrivacyPolicyScreen(), settings);
      case Routes.terms:
        return _buildRoute(() => TermsScreen(), settings);

      // ==================== Booking ====================
      case Routes.dateSelection:
        return _buildRoute(() => DateSelectionScreen(), settings);
      case Routes.guestSelection:
        return _buildRoute(() => GuestSelectionScreen(), settings);
      case Routes.bookingRequest:
        return _buildRoute(
          () => BlocProvider(
            create: (_) => sl<BookingCubit>(),
            child: BookingRequestScreen(),
          ),
          settings,
        );
      case Routes.payment:
        return _buildRoute(() => PaymentMethodScreen(), settings);
      case Routes.paymentMethod:
        return _buildRoute(() => PaymentMethodScreen(), settings);
      case Routes.bookingConfirmation:
        return _buildRoute(() => BookingConfirmationScreen(), settings);
      case Routes.sadadWebView:
        final sadadArgs = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          () => SadadWebViewScreen(
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
          () => PaypalWebViewScreen(
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
          () => ExternalPaymentWebViewScreen(
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
          () => ReviewPropertyScreen(
            bookingId: reviewArgs?['bookingId']?.toString(),
            propertyId: reviewArgs?['propertyId']?.toString(),
          ),
          settings,
        );

      // ==================== Payment Status ====================
      case Routes.paymentPending:
        return _buildRoute(() => PaymentPendingScreen(), settings);
      case Routes.paymentFailed:
        return _buildRoute(() => PaymentFailedScreen(), settings);
      case Routes.paymentCancel:
        return _buildRoute(() => PaymentCancelScreen(), settings);

      // ==================== Trips ====================
      case Routes.trips:
        return _buildRoute(() => TripsScreen(), settings);
      case Routes.tripDetails:
        return _buildRoute(() => TripDetailsScreen(), settings);

      // ==================== Notifications ====================
      case Routes.notifications:
        return _buildRoute(
          () => BlocProvider(
            create: (_) => sl<NotificationsCubit>()..loadNotifications(),
            child: NotificationsScreen(),
          ),
          settings,
        );

      // ==================== Country tab drill-down ====================
      case Routes.regionList:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          () => RegionListScreen(
            countryId: args?['countryId'] is int
                ? args!['countryId'] as int
                : int.tryParse(args?['countryId']?.toString() ?? '') ?? 0,
            countryName: args?['countryName']?.toString() ?? '',
            countryFlag: args?['countryFlag']?.toString() ?? '',
          ),
          settings,
        );
      case Routes.villageList:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          () => VillageListScreen(
            regionId: args?['regionId'] is int
                ? args!['regionId'] as int
                : int.tryParse(args?['regionId']?.toString() ?? '') ?? 0,
            regionName: args?['regionName']?.toString() ?? '',
          ),
          settings,
        );

      // ==================== Demo ====================
      case Routes.allScreensDemo:
        return _buildRoute(() => AllScreensDemo(), settings);

      // ==================== Fallback ====================
      default:
        return _buildRoute(
          () => Scaffold(
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

  /// Takes a *builder*, not a ready-made widget.
  ///
  /// Holding one instance and returning it from `builder` would make the page
  /// identity-stable across rebuilds, and `Element.updateChild` skips a child
  /// whose widget is identical — so the screen would never repaint after a
  /// light/dark switch (it only appeared to work on the tab shell, which
  /// rebuilds internally when the tab index changes).
  static MaterialPageRoute<T> _buildRoute<T>(
    Widget Function() page,
    RouteSettings settings,
  ) {
    return MaterialPageRoute<T>(
      builder: (_) => page(),
      settings: settings,
    );
  }

  static String _extractPropertyId(Object? arguments) {
    if (arguments is String) return arguments;
    if (arguments is Map) {
      final direct =
          arguments['propertyId'] ?? arguments['id'] ?? arguments['_id'];
      if (direct != null && direct.toString().isNotEmpty) {
        return direct.toString();
      }
      final property = arguments['property'];
      if (property is Map) {
        final nested =
            property['propertyId'] ?? property['id'] ?? property['_id'];
        if (nested != null) return nested.toString();
      }
    }
    return '';
  }
}
