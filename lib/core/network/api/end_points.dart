class EndPoints {
  EndPoints._();

  // Base URL — production backend on Azure Container Apps
  static const String baseUrl =
      'https://houseiana-api-prod.jollyisland-881a1746.eastus.azurecontainerapps.io';

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

  // ── Users ───────────────────────────────────────────────────────────────────
  // GET  /users/{id}                    → get user profile
  // POST /users/{id}/profile            → update user profile (multipart)
  // POST /users/favorites               → add / remove favorite
  // GET  /users/{userId}/favorites      → list user favorites
  // GET  /users/{userId}/user-trips     → get trips (query: status)
  // POST /users/{userId}/passport       → add/update passport
  // GET  /users/{userId}/passport       → get passport
  // POST /users/address                 → add/update address
  // GET  /users/{userId}/address        → get address
  // POST /users/{userId}/emergency-contact
  // GET  /users/{userId}/emergency-contact
  static String userById(String id) => '/users/$id';
  static String updateUserProfile(String id) => '/users/$id/profile';
  static const String favorites = '/users/favorites';
  static String userFavorites(String userId) => '/users/$userId/favorites';
  static String userTrips(String userId) => '/users/$userId/user-trips';
  static String userPassport(String userId) => '/users/$userId/passport';
  static const String userAddress = '/users/address';
  static String getUserAddress(String userId) => '/users/$userId/address';
  static String emergencyContact(String userId) =>
      '/users/$userId/emergency-contact';

  // ── Bookings ────────────────────────────────────────────────────────────────
  // POST /booking-manager               → create booking
  // GET  /booking-manager/{id}          → booking details
  // POST /booking-manager/{id}/cancel   → cancel booking
  static const String createBooking = '/booking-manager';
  static String bookingById(String id) => '/booking-manager/$id';
  static String cancelBooking(String id) => '/booking-manager/$id/cancel';

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
  static String citiesLookup(int countryId) =>
      '/api/lookups/cities?countryId=$countryId';

  // ── Files ───────────────────────────────────────────────────────────────────
  static const String uploadFile = '/api/files/upload';
  static const String uploadMultipleFiles = '/api/files/upload-multiple';
}
