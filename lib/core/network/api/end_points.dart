import 'package:houseiana_mobile_app/core/config/app_config.dart';

class EndPoints {
  EndPoints._();

  // Base URL — pulled from AppConfig per environment.
  static String get baseUrl => AppConfig.backendApiUrl;

  // ── Auth ────────────────────────────────────────────────────────────────────
  // POST /api/auth/login                → backend session sync (Bearer token required)
  static const String authLogin = '/api/auth/login';
  // GET  /api/auth/version-check?version={v}&platform={IOS|ANDROID}
  // Force-update gate. Response: { success, data: { forceUpdate: bool, updateUrl: String } }
  static const String versionCheck = '/api/auth/version-check';

  // ── Properties ──────────────────────────────────────────────────────────────
  // GET  /api/property-search           → search / list properties
  // GET  /api/property-search/{id}      → single property details
  // GET  /api/property-search/{id}/availability
  // GET  /api/property-search/{id}/booked-dates
  static const String propertySearch = '/api/property-search';
  static String propertyDetails(String id) => '/api/property-search/$id';
  static String propertyAvailability(String id) =>
      '/api/property-search/$id/availability';
  static String propertyBookedDates(String id) =>
      '/api/property-search/$id/booked-dates';
  // GET /api/property-search/{id}/nightly-prices?page={n}  → ~1 month of prices per page
  static String propertyNightlyPrices(String id) =>
      '/api/property-search/$id/nightly-prices';

  // ── Users ───────────────────────────────────────────────────────────────────
  // GET  /users/{id}                    → get user profile
  // POST /users/{id}/profile            → update user profile (multipart)
  // POST /users/favorites               → add / remove favorite
  // GET  /users/{userId}/favorites      → list user favorites
  // GET  /users/{userId}/user-trips     → get trips (query: status)
  // POST /users/{userId}/passport       → add/update passport
  // GET  /users/{userId}/passport       → get passport
  // POST /users/{userId}/national-id    → add/update national id (multipart)
  // GET  /users/{userId}/national-id    → get national id
  // POST /users/address                 → add/update address
  // GET  /users/{userId}/address        → get address
  // POST /users/{userId}/emergency-contact
  // GET  /users/{userId}/emergency-contact
  static String userById(String id) => '/users/$id';
  static String updateUserProfile(String id) => '/users/$id/profile';
  // POST /users/update                 → generic profile update
  //   body: { userId, firstName, lastName, phone }
  static const String usersUpdate = '/users/update';
  // POST /users/delete-account         → permanently delete account (body: { userId })
  static const String deleteAccount = '/users/delete-account';
  static const String favorites = '/users/favorites';
  static String userFavorites(String userId) => '/users/$userId/favorites';
  static String userTrips(String userId) => '/users/$userId/user-trips';
  static String userPassport(String userId) => '/users/$userId/passport';
  static String nationalId(String userId) => '/users/$userId/national-id';
  static const String userAddress = '/users/address';
  static String getUserAddress(String userId) => '/users/$userId/address';
  static String emergencyContact(String userId) =>
      '/users/$userId/emergency-contact';

  // ── Properties (Host) ───────────────────────────────────────────────────────
  // POST /api/properties                → create listing
  // POST /api/properties/draft          → save draft (also UPDATES when propertyId is sent)
  // GET  /api/properties/by-host        → host listings
  // GET  /api/properties/{id}           → property (edit prefill — same shape the web edit screen loads)
  // PUT  /api/properties/{id}           → update listing
  // POST /api/properties/{id}/delete    → delete listing
  // POST /api/properties/deactivate     → deactivate listing (body: { propertyId, userId })
  // POST /api/properties/reactivate     → reactivate listing (body: { propertyId, hostId })
  static const String properties = '/api/properties';
  static const String propertiesDraft = '/api/properties/draft';
  static String propertyById(String id) => '/api/properties/$id';
  static const String propertiesDeactivate = '/api/properties/deactivate';
  static const String propertiesReactivate = '/api/properties/reactivate';

  // ── Host Dashboard ──────────────────────────────────────────────────────────
  static String hostDashboard(String userId) => '/users/$userId/host-dashboard';

  // ── Bookings ────────────────────────────────────────────────────────────────
  // POST /booking-manager               → create booking
  // GET  /booking-manager/{id}          → booking details
  // POST /booking-manager/{id}/cancel   → cancel booking
  // POST /booking-manager/{id}/approve  → approve booking (host)
  static const String createBooking = '/booking-manager';
  static String bookingById(String id) => '/booking-manager/$id';
  static const String listBookings = '/api/bookings/list';
  static const String bookingDisplayStatusLookup = '/api/Lookups/BookingDisplayStatus';
  // GET /api/Lookups/BookingStatus → [{ id, name }] — drives the guest Trips tabs.
  static const String bookingStatusLookup = '/api/Lookups/BookingStatus';
  static String cancelBooking(String id) => '/booking-manager/$id/cancel';
  static String approveBooking(String id) => '/booking-manager/$id/approve';

  // ── Chat ────────────────────────────────────────────────────────────────────
  // GET  /api/chat/conversations        → list conversations (query: userId)
  // POST /api/chat/conversations        → create conversation
  // GET  /api/chat/conversations/{id}   → conversation details
  // POST /api/chat/start-booking-chat   → start chat about a booking
  // GET  /api/chat/firebase-token       → firebase custom token
  static const String conversations = '/api/chat/conversations';
  static String conversationById(String id) => '/api/chat/conversations/$id';
  static const String startBookingChat = '/api/chat/start-booking-chat';
  static const String firebaseToken = '/api/chat/firebase-token';

  // ── Ratings ─────────────────────────────────────────────────────────────────
  // GET  /api/ratings/property/{propertyId}
  // POST /api/ratings/property-by-guest
  static String propertyRatings(String propertyId) =>
      '/api/ratings/property/$propertyId';
  static const String ratePropertyByGuest = '/api/ratings/property-by-guest';

  // ── Lookups ─────────────────────────────────────────────────────────────────
  static const String amenitiesLookup = '/api/lookups/Amenities';
  static const String propertyTypesLookup = '/api/lookups/PropertyType';
  static const String countriesLookup = '/api/lookups/country';
  static String statesLookup(int countryId) => '/api/lookups/states?countryId=$countryId';
  static String citiesLookup(int stateId) => '/api/lookups/cities?stateId=$stateId';
  static String villagesLookup(int cityId) => '/api/lookups/villages?cityId=$cityId';
  // GET /api/Lookups/Gender → [{ id, name }] — drives the personal-info gender dropdown
  // and supplies the genderId expected by POST /users/{id}/profile.
  static const String genderLookup = '/api/Lookups/Gender';
  // GET /api/Lookups/PayoutMethod → [{ id, name }] — drives the host payout
  // method picker; the chosen id is sent as `payoutMethodId`.
  static const String payoutMethodLookup = '/api/Lookups/PayoutMethod';
  // GET /api/Lookups/relationshipOfEmergencyContact → [{ id, name }] — drives the
  // emergency-contact relationship dropdown; the chosen id is sent as `relationship`.
  static const String relationshipLookup =
      '/api/Lookups/relationshipOfEmergencyContact';
  static const String propertyHighlightsLookup = '/api/Lookups/PropertyHighlight';
  static const String propertyAdminStatusLookup = '/api/Lookups/PropertyAdminStatus';
  static const String propertySortingLookup = '/api/Lookups/PropertySorting';
  // GET /api/Lookups/RegionCategory → [{ id, name, propertyCount, photo }]
  // Home destination categories. The chosen id is sent to /api/property-search
  // as `featuredRegionId` for the in-place home filter, or as `villageId` when
  // drilling into a region's full listing.
  static const String regionCategoryLookup = '/api/Lookups/RegionCategory';
  // GET /api/Lookups/ReasonBlockProperty → [{ id, name }] used for calendar blocking.
  static const String reasonBlockPropertyLookup =
      '/api/Lookups/ReasonBlockProperty';

  // ── Host Calendar (management) ───────────────────────────────────────────
  // GET  /api/properties/by-host?hostId=&limit=        → host listings (dropdown)
  // GET  /api/property-calendar?propertyId=&userId=&page=&date=  → month daily slots
  // POST /api/properties/special-price                          → set special price (host)
  // POST /api/properties/calendar/update-status                  → block / unblock
  // POST /booking-manager/minimum-days                           → set min nights (no /api)
  static const String propertiesByHost = '/api/properties/by-host';
  static const String propertyCalendar = '/api/property-calendar';
  static const String specialPrice = '/api/properties/special-price';
  static const String calendarUpdateStatus =
      '/api/properties/calendar/update-status';
  static const String minimumDays = '/booking-manager/minimum-days';
}
