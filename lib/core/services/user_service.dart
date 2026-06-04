import 'package:houseiana_mobile_app/core/models/booking_model.dart';
import 'package:houseiana_mobile_app/core/models/gender_option.dart';
import 'package:houseiana_mobile_app/core/models/public_profile_model.dart';
import 'package:houseiana_mobile_app/core/models/trip_model.dart';
import 'package:houseiana_mobile_app/core/models/user_model.dart';
import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/network/api/end_points.dart';

/// Handles all user-related API calls to the backend.
/// Routes: /users/*, /booking-manager/*, /api/chat/conversations
class UserService {
  final ApiConsumer _api;

  UserService(this._api);

  // ── Profile ──────────────────────────────────────────────────────────────

  /// GET /users/{id}
  /// Backend returns `{ user, rating, userProfile, properties, bookings, ... }`.
  /// We unwrap the nested `user` object before parsing.
  Future<UserModel?> getUser(String userId) async {
    final response = await _api.get(EndPoints.userById(userId));
    final item = _item(response);
    if (item == null) return null;

    final userJson = (item['user'] is Map<String, dynamic>)
        ? item['user'] as Map<String, dynamic>
        : item;
    return UserModel.fromJson(userJson);
  }

  /// GET /users/{id} — FULL wrapper for the public/owner profile screen.
  /// Unlike [getUser], this preserves rating / properties / bookings /
  /// hostRatings. The whole response is passed to the model (which unwraps
  /// `data` and `user` itself) so sibling keys like `rating` survive.
  Future<PublicProfileModel?> getPublicProfile(String userId) async {
    final response = await _api.get(EndPoints.userById(userId));
    if (response is Map<String, dynamic>) {
      return PublicProfileModel.fromJson(response);
    }
    return null;
  }

  // ── Favorites ────────────────────────────────────────────────────────────

  /// GET /users/{userId}/favorites
  Future<List<Map<String, dynamic>>> getFavorites(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.get(
      EndPoints.userFavorites(userId),
      queryParameters: {'page': page, 'limit': limit},
    );
    return _list(response);
  }

  /// POST /users/favorites
  /// Body: { "userId": "...", "propertyId": "..." }
  /// The backend toggles — if already favourite it removes it.
  Future<bool> toggleFavorite({
    required String userId,
    required String propertyId,
  }) async {
    await _api.post(
      EndPoints.favorites,
      body: {'userId': userId, 'propertyId': propertyId},
    );
    return true;
  }

  // ── Trips / Bookings ─────────────────────────────────────────────────────

  /// GET /api/Lookups/BookingStatus → `[{ id, name }]`
  /// Drives the guest Trips tabs (Upcoming / Past / Cancelled / Need To Pay /
  /// Awaiting Approval). Falls back to a static list if the lookup fails.
  Future<List<TripFilterTab>> getTripFilterTabs() async {
    try {
      final response = await _api.get(EndPoints.bookingStatusLookup);
      final tabs = _list(response)
          .map(TripFilterTab.fromJson)
          .where((t) => t.label.isNotEmpty)
          .toList();
      return tabs.isEmpty ? TripFilterTab.fallback : tabs;
    } catch (_) {
      return TripFilterTab.fallback;
    }
  }

  /// GET /users/{userId}/user-trips?status={status}
  /// [status] is the `BookingStatus` lookup id (int) — matching the web — or a
  /// legacy status string (UPCOMING / PAST / CANCELLED). Omitted when null.
  Future<List<TripModel>> getTrips(
    String userId, {
    Object? status,
  }) async {
    final response = await _api.get(
      EndPoints.userTrips(userId),
      queryParameters: {
        if (status != null) 'status': status,
      },
    );
    return _tripList(response);
  }

  /// GET /booking-manager/{id}
  Future<BookingModel?> getBookingDetails(String bookingId) async {
    final response = await _api.get(EndPoints.bookingById(bookingId));
    final item = _item(response);
    return item != null ? BookingModel.fromJson(item) : null;
  }

  /// POST /booking-manager
  Future<BookingModel?> createBooking(Map<String, dynamic> body) async {
    final response = await _api.post(EndPoints.createBooking, body: body);
    final item = _item(response);
    return item != null ? BookingModel.fromJson(item) : null;
  }

  // ── Profile Update ────────────────────────────────────────────────────────

  /// POST /users/{id}/profile
  ///
  /// The backend binds these fields from `multipart/form-data` (`[FromForm]`),
  /// exactly like the web's `FormData` upload — sending JSON is silently
  /// ignored and nothing persists. So this MUST go out as form-data.
  /// [body] keys mirror the web payload: firstName, lastName, email, phone,
  /// genderId, dateOfBirth (`yyyy-MM-dd`), address, nationality, ...
  Future<bool> updateProfile(String userId, Map<String, dynamic> body) async {
    await _api.post(
      EndPoints.updateUserProfile(userId),
      body: body,
      formDataIsEnabled: true,
    );
    return true;
  }

  /// GET /api/Lookups/Gender → `[{ id, name }]`
  /// Drives the personal-info gender dropdown and provides the `genderId` the
  /// profile-update endpoint expects. Falls back to a static list on failure.
  Future<List<GenderOption>> getGenders() async {
    try {
      final response = await _api.get(EndPoints.genderLookup);
      final options = _list(response)
          .map(GenderOption.fromJson)
          .where((g) => g.name.isNotEmpty)
          .toList();
      return options.isEmpty ? GenderOption.fallback : options;
    } catch (_) {
      return GenderOption.fallback;
    }
  }

  /// POST /users/update — generic profile update.
  /// Mirrors the web `BackendAPI.User.update`. Used by the request-to-book
  /// "Confirm your details" flow to persist the guest's name + phone before a
  /// PENDING booking is created.
  /// Body: { userId, firstName, lastName, phone }
  Future<bool> updateUser({
    required String userId,
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    await _api.post(EndPoints.usersUpdate, body: {
      'userId': userId,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (phone != null) 'phone': phone,
    });
    return true;
  }

  // ── Delete Account ────────────────────────────────────────────────────────

  /// POST /users/delete-account
  /// Body: { "userId": "..." }
  Future<bool> deleteAccount(String userId) async {
    await _api.post(EndPoints.deleteAccount, body: {'userId': userId});
    return true;
  }

  // ── KYC / Passport ────────────────────────────────────────────────────────

  /// POST /users/{userId}/passport
  Future<bool> updatePassport(String userId, Map<String, dynamic> body) async {
    await _api.post(EndPoints.userPassport(userId), body: body);
    return true;
  }

  /// GET /users/{userId}/passport
  Future<Map<String, dynamic>?> getPassport(String userId) async {
    final response = await _api.get(EndPoints.userPassport(userId));
    return _item(response);
  }

  // ── Cancel Booking ────────────────────────────────────────────────────────

  /// POST /booking-manager/{id}/cancel
  Future<bool> cancelBooking(String bookingId) async {
    await _api.post(EndPoints.cancelBooking(bookingId), body: {});
    return true;
  }

  // ── Create Property ───────────────────────────────────────────────────────

  /// POST /api/properties
  Future<Map<String, dynamic>?> createProperty(
      Map<String, dynamic> body) async {
    final response = await _api.post('/api/properties', body: body);
    return _item(response);
  }

  // ── Addresses ─────────────────────────────────────────────────────────────

  /// GET /users/{userId}/address
  Future<List<AddressModel>> getAddresses(String userId) async {
    final response = await _api.get(EndPoints.getUserAddress(userId));
    return _addressList(response);
  }

  /// POST /users/{userId}/address
  Future<AddressModel?> addAddress(
      String userId, Map<String, dynamic> body) async {
    final response =
        await _api.post(EndPoints.getUserAddress(userId), body: body);
    final item = _item(response);
    return item != null ? AddressModel.fromJson(item) : null;
  }

  /// PATCH /users/{userId}/address/{addressId}
  Future<AddressModel?> updateAddress(
    String userId,
    String addressId,
    Map<String, dynamic> body,
  ) async {
    final response = await _api.patch(
      '/users/$userId/address/$addressId',
      body: body,
    );
    final item = _item(response);
    return item != null ? AddressModel.fromJson(item) : null;
  }

  /// DELETE /users/{userId}/address/{addressId}
  Future<bool> deleteAddress(String userId, String addressId) async {
    await _api.delete(
      '/users/$userId/address/$addressId',
    );
    return true;
  }

  // ── Payment Methods ──────────────────────────────────────────────────────

  /// GET /api/payment-methods
  Future<List<PaymentMethodModel>> getPaymentMethods(String userId) async {
    final response = await _api.get(
      '/api/payment-methods',
      queryParameters: {'userId': userId},
    );
    return _paymentMethodList(response);
  }

  /// POST /api/payment-methods
  Future<PaymentMethodModel?> addPaymentMethod(
      String userId, Map<String, dynamic> body) async {
    final response = await _api.post(
      '/api/payment-methods',
      body: {
        ...body,
        'userId': userId,
      },
    );
    final item = _item(response);
    return item != null ? PaymentMethodModel.fromJson(item) : null;
  }

  /// DELETE /api/payment-methods/{methodId}
  Future<bool> deletePaymentMethod(String userId, String methodId) async {
    await _api.delete('/api/payment-methods/$methodId');
    return true;
  }

  /// PATCH /api/payment-methods/{methodId}/set-default
  Future<bool> setDefaultPaymentMethod(String userId, String methodId) async {
    await _api.patch('/api/payment-methods/$methodId/set-default');
    return true;
  }

  /// GET /api/payments?userId={userId}
  Future<List<Map<String, dynamic>>> getPaymentHistory(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.get(
      '/api/payments',
      queryParameters: {
        'userId': userId,
        'page': page,
        'limit': limit,
      },
    );
    return _list(response);
  }

  // ── Payout Methods ───────────────────────────────────────────────────────

  /// GET /users/{userId}/payout-methods
  Future<List<Map<String, dynamic>>> getPayoutMethods(String userId) async {
    final response = await _api.get('/users/$userId/payout-methods');
    return _list(response);
  }

  /// POST /users/{userId}/payout-methods
  Future<Map<String, dynamic>?> addPayoutMethod(
    String userId,
    Map<String, dynamic> body,
  ) async {
    final response =
        await _api.post('/users/$userId/payout-methods', body: body);
    return _item(response);
  }

  /// DELETE /users/{userId}/payout-methods/{id}
  Future<bool> deletePayoutMethod(String userId, String payoutId) async {
    await _api.delete('/users/$userId/payout-methods/$payoutId');
    return true;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Map<String, dynamic>? _item(dynamic response) {
    if (response == null) return null;
    if (response is Map<String, dynamic>) {
      return (response['data'] as Map<String, dynamic>?) ?? response;
    }
    return null;
  }

  List<TripModel> _tripList(dynamic response) {
    if (response == null) return [];
    dynamic raw = response;
    if (raw is Map) raw = raw['data'] ?? raw['items'] ?? raw;
    if (raw is Map) {
      raw = raw['items'] ??
          raw['data'] ??
          raw.values.firstWhere(
            (v) => v is List,
            orElse: () => [],
          );
    }
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map((e) => TripModel.fromJson(e))
          .toList();
    }
    return [];
  }

  List<Map<String, dynamic>> _list(dynamic response) {
    if (response == null) return [];
    dynamic raw = response;
    if (raw is Map) raw = raw['data'] ?? raw['items'] ?? raw;
    if (raw is Map) {
      raw = raw['items'] ??
          raw['data'] ??
          raw.values.firstWhere(
            (v) => v is List,
            orElse: () => [],
          );
    }
    if (raw is List) return raw.whereType<Map<String, dynamic>>().toList();
    return [];
  }

  List<AddressModel> _addressList(dynamic response) {
    if (response == null) return [];
    dynamic raw = response;
    if (raw is Map) raw = raw['data'] ?? raw['items'] ?? raw;
    if (raw is Map) {
      raw = raw['items'] ??
          raw['data'] ??
          raw.values.firstWhere(
            (v) => v is List,
            orElse: () => [],
          );
    }
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map((e) => AddressModel.fromJson(e))
          .toList();
    }
    return [];
  }

  List<PaymentMethodModel> _paymentMethodList(dynamic response) {
    if (response == null) return [];
    dynamic raw = response;
    if (raw is Map) raw = raw['data'] ?? raw['items'] ?? raw;
    if (raw is Map) {
      raw = raw['items'] ??
          raw['data'] ??
          raw.values.firstWhere(
            (v) => v is List,
            orElse: () => [],
          );
    }
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map((e) => PaymentMethodModel.fromJson(e))
          .toList();
    }
    return [];
  }
}
