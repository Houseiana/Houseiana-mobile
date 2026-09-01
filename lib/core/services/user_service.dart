import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:houseiana_mobile_app/core/models/booking_model.dart';
import 'package:houseiana_mobile_app/core/models/gender_option.dart';
import 'package:houseiana_mobile_app/core/models/public_profile_model.dart';
import 'package:houseiana_mobile_app/core/models/trip_model.dart';
import 'package:houseiana_mobile_app/core/models/user_model.dart';
import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/network/api/end_points.dart';
import 'package:houseiana_mobile_app/core/services/cache_service.dart';
import 'package:houseiana_mobile_app/core/services/favorites_notifier.dart';
import 'package:houseiana_mobile_app/core/services/lookups_cache.dart';

/// Handles all user-related API calls to the backend.
/// Routes: /users/*, /booking-manager/*, /api/chat/conversations
class UserService {
  final ApiConsumer _api;
  final CacheService _cache;
  final LookupsCache _lookups;
  final FavoritesNotifier _favorites;

  UserService(this._api, this._cache, this._lookups, this._favorites);

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

  /// The signed-in user's saved property ids — the ONLY source a heart may be
  /// filled from (see [FavoritesNotifier]).
  ///
  /// Fetched in one page big enough to hold a whole wishlist: the set
  /// replace-seeds the notifier, so a short page would silently empty the
  /// hearts of everyone past the default 20.
  Future<Set<String>> getFavoriteIds(String userId) async {
    final favorites = await getFavorites(userId, limit: _favoriteIdsPageSize);
    return favorites
        .map(_favoritePropertyId)
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  static const int _favoriteIdsPageSize = 100;

  /// A favourites row is either the property itself or a
  /// `{ propertyId, property: {...} }` wrapper.
  String _favoritePropertyId(Map<String, dynamic> row) {
    final property = row['property'];
    return (row['propertyId'] ??
            (property is Map ? (property['id'] ?? property['_id']) : null) ??
            row['id'] ??
            '')
        .toString();
  }

  /// POST /users/favorites
  /// Body: { "userId": "...", "propertyId": "..." }
  /// The backend toggles — if already favourite it removes it.
  ///
  /// A favourite changes what the home should show (which hearts are filled),
  /// and per product spec the home must NOT be served stale from cache after a
  /// favourite. So this invalidates the cached home list + favourite sets — the
  /// next home load then misses the cache, fetches fresh from the API and
  /// re-caches. This is the single choke point for every favourite toggle in
  /// the app (home, favorites, wishlists, recommendations, search, details).
  Future<bool> toggleFavorite({
    required String userId,
    required String propertyId,
  }) async {
    // Optimistic: flip the app-wide notifier first so every heart repaints
    // instantly, then revert if the POST fails.
    _favorites.toggle(propertyId);
    try {
      await _api.post(
        EndPoints.favorites,
        body: {'userId': userId, 'propertyId': propertyId},
      );
    } catch (_) {
      _favorites.toggle(propertyId);
      rethrow;
    }
    await _cache.removeByPrefix(HomeCache.listPrefix);
    await _cache.removeByPrefix(HomeCache.favPrefix);
    return true;
  }

  // ── Trips / Bookings ─────────────────────────────────────────────────────

  /// GET /api/Lookups/BookingStatus → `[{ id, name }]`
  /// Drives the guest Trips tabs (Upcoming / Past / Cancelled / Need To Pay /
  /// Awaiting Approval). Falls back to a static list if the lookup fails.
  Future<List<TripFilterTab>> getTripFilterTabs() async {
    try {
      final response = await _lookups.getOrFetch(
        EndPoints.bookingStatusLookup,
        () => _api.get(EndPoints.bookingStatusLookup),
      );
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

  /// The id a REVIEW addresses a stay by: the HOTEL id for a hotel stay, the
  /// PROPERTY id otherwise — `POST /api/hotels/{hotelId}/reviews/create` and
  /// `POST /api/ratings/property-by-guest` are keyed by the stay, never by the
  /// booking, so without it the review cannot be posted at all.
  ///
  /// `GET /users/{userId}/user-trips` does not always carry it: a real past
  /// hotel stay came back flagged HOTEL, with a title and a cover photo, and no
  /// hotel id anywhere in the row — which is what left the review button on
  /// "This hotel is no longer available". When the row comes up short,
  /// `GET /booking-manager/{bookingId}` is a different DTO over the same
  /// booking and is worth one attempt before giving up.
  ///
  /// Returns an empty string when neither source knows it, and never throws —
  /// the caller decides what to tell the guest.
  Future<String> resolveStayEntityId({
    required String bookingId,
    required bool isHotel,
    String localId = '',
  }) async {
    final local = localId.trim();
    // The reviews path declares its hotel id as a uuid
    // (`/api/hotels/{hotelId}/reviews/create`), so a hotel candidate that is
    // not uuid-shaped — a booking code like `HB-D66CA676`, a row index — is
    // worth checking against the booking DTO before it is used.
    final localIsTrustworthy =
        local.isNotEmpty && (!isHotel || _looksLikeUuid(local));
    if (localIsTrustworthy) return local;
    if (bookingId.isEmpty) return local;
    try {
      final booking = await getBookingDetails(bookingId);
      final resolved = booking == null
          ? ''
          : (isHotel ? booking.resolvedHotelId : booking.propertyId.trim());
      // Never come out of here worse off than we went in.
      return resolved.isNotEmpty ? resolved : local;
    } catch (_) {
      // Hotel bookings may not be served by /booking-manager at all. A failure
      // here is "no better answer", not an error worth surfacing.
      return local;
    }
  }

  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static bool _looksLikeUuid(String value) => _uuidPattern.hasMatch(value);

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
      final response = await _lookups.getOrFetch(
        EndPoints.genderLookup,
        () => _api.get(EndPoints.genderLookup),
      );
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

  // ── Identity Verification ──────────────────────────────────────────────────
  // Mirrors the web personal-info identity sections (AccountAPI in auth.service):
  //   passport          → POST /users/{id}/passport          (JSON)
  //   national id       → POST /users/{id}/national-id        (multipart + photos)
  //   emergency contact → POST /users/{id}/emergency-contact  (JSON)
  // The relationship dropdown is driven by the localized lookup, and the chosen
  // id (not the localized name) is sent back — see [[payment-method-lookup-id-contract]].

  /// GET /users/{userId}/passport
  Future<Map<String, dynamic>?> getPassport(String userId) async {
    final response = await _api.get(EndPoints.userPassport(userId));
    return _item(response);
  }

  /// POST /users/{userId}/passport — multipart, mirrors `AccountAPI.updatePassport`.
  /// Text keys: passportNumber, issuingCountry, issueDate (`yyyy-MM-dd`), expiryDate.
  /// File key: passportPhoto (optional).
  ///
  /// The backend binds these from `multipart/form-data` (`[FromForm]`), exactly
  /// like the profile-update and national-id endpoints — sending JSON makes every
  /// field bind as null and the request 400s with "One or more fields are
  /// invalid". So this MUST go out as form-data, and the photo as a
  /// [MultipartFile], not a path.
  Future<bool> updatePassport(
    String userId, {
    required Map<String, dynamic> fields,
    String? photoPath,
  }) async {
    final body = <String, dynamic>{...fields};
    if (photoPath != null && photoPath.isNotEmpty) {
      body['passportPhoto'] = await MultipartFile.fromFile(
        photoPath,
        filename: _fileName(photoPath),
      );
    }
    await _api.post(
      EndPoints.userPassport(userId),
      body: body,
      formDataIsEnabled: true,
    );
    return true;
  }

  /// GET /users/{userId}/national-id
  Future<Map<String, dynamic>?> getNationalId(String userId) async {
    final response = await _api.get(EndPoints.nationalId(userId));
    return _item(response);
  }

  /// POST /users/{userId}/national-id — multipart, mirrors `AccountAPI.addNationalId`.
  /// Text keys: idNumber, issuingCountry, issueDate (`yyyy-MM-dd`), expiryDate.
  /// File keys: idFrontPhoto, idBackPhoto (optional). The backend binds these
  /// from `multipart/form-data` (just like the profile-update endpoint), so the
  /// photos must go out as [MultipartFile], not paths.
  Future<bool> addNationalId(
    String userId, {
    required Map<String, dynamic> fields,
    String? frontPhotoPath,
    String? backPhotoPath,
  }) async {
    final body = <String, dynamic>{...fields};
    if (frontPhotoPath != null && frontPhotoPath.isNotEmpty) {
      body['idFrontPhoto'] = await MultipartFile.fromFile(
        frontPhotoPath,
        filename: _fileName(frontPhotoPath),
      );
    }
    if (backPhotoPath != null && backPhotoPath.isNotEmpty) {
      body['idBackPhoto'] = await MultipartFile.fromFile(
        backPhotoPath,
        filename: _fileName(backPhotoPath),
      );
    }
    await _api.post(
      EndPoints.nationalId(userId),
      body: body,
      formDataIsEnabled: true,
    );
    return true;
  }

  /// GET /users/{userId}/emergency-contact
  Future<Map<String, dynamic>?> getEmergencyContact(String userId) async {
    final response = await _api.get(EndPoints.emergencyContact(userId));
    return _item(response);
  }

  /// POST /users/{userId}/emergency-contact — JSON, mirrors
  /// `AccountAPI.addEmergencyContact`.
  /// Keys: fullName, relationship (lookup id as a *string* — the DTO types it
  /// as a string, so a raw int 400s), phoneNumber, whatsappNumber, emailAddress.
  Future<bool> addEmergencyContact(
      String userId, Map<String, dynamic> body) async {
    await _api.post(EndPoints.emergencyContact(userId), body: body);
    return true;
  }

  /// GET /api/Lookups/relationshipOfEmergencyContact → `[{ id, name }]`.
  /// Drives the emergency-contact relationship dropdown. Falls back to an empty
  /// list on failure.
  Future<List<Map<String, dynamic>>> getRelationshipOptions() async {
    try {
      final response = await _lookups.getOrFetch(
        EndPoints.relationshipLookup,
        () => _api.get(EndPoints.relationshipLookup),
      );
      return _list(response)
          .map((e) => {
                'id': e['id'],
                'name': e['name']?.toString() ?? '',
              })
          .where((m) => m['id'] != null && (m['name'] as String).isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  String _fileName(String path) => path.split(RegExp(r'[\\/]')).last;

  // ── Cancel Booking ────────────────────────────────────────────────────────

  /// POST /booking-manager/{id}/cancel
  /// Body matches the web (`BookingService.cancel`): `{ userId, reason? }`.
  /// The backend authorizes the guest cancel by `userId`, so it must be sent —
  /// an empty body fails with "failed to cancel".
  Future<bool> cancelBooking(
    String bookingId, {
    required String userId,
    String? reason,
  }) async {
    await _api.post(EndPoints.cancelBooking(bookingId), body: {
      'userId': userId,
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    });
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
  // Contract mirrors the web `AccountService` (auth.service.ts):
  //   list   → GET  /users/{userId}/payout-methods        ({ data: { data: [...] } })
  //   add    → POST /users/{userId}/payout-method          { payoutMethodId, accountId, accountName }
  //   delete → POST /users/delete-payout-method/{id}
  // The picker options come from GET /api/Lookups/PayoutMethod.

  /// GET /api/Lookups/PayoutMethod → `[{ id, name }]`.
  /// Drives the "Add payout method" picker. Falls back to an empty list.
  Future<List<Map<String, dynamic>>> getPayoutMethodOptions() async {
    try {
      final response = await _lookups.getOrFetch(
        EndPoints.payoutMethodLookup,
        () => _api.get(EndPoints.payoutMethodLookup),
      );
      return _list(response)
          .map((e) => {
                'id': e['id'],
                'name': e['name']?.toString() ?? '',
              })
          .where((m) => m['id'] != null && (m['name'] as String).isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// GET /users/{userId}/payout-methods
  Future<List<Map<String, dynamic>>> getPayoutMethods(String userId) async {
    final response = await _api.get('/users/$userId/payout-methods');
    return _list(response);
  }

  /// POST /users/{userId}/payout-method (singular).
  /// Body: { payoutMethodId, accountId, accountName } — matches the web.
  Future<Map<String, dynamic>?> addPayoutMethod(
    String userId,
    Map<String, dynamic> body,
  ) async {
    final response =
        await _api.post('/users/$userId/payout-method', body: body);
    return _item(response);
  }

  /// POST /users/delete-payout-method/{id}
  Future<bool> deletePayoutMethod(String payoutId) async {
    await _api.post('/users/delete-payout-method/$payoutId');
    return true;
  }

  /// GET /users/{userId}/payouts — payout transaction history.
  /// Mirrors the web `AccountAPI.getPayouts`: rows live under `payouts`
  /// (or `data`), with a sibling `totalMoney` + `currency` pair that feeds
  /// the "Your credit balance" box.
  Future<PayoutHistory> getPayouts(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.get(
      '/users/$userId/payouts',
      queryParameters: {'page': page, 'limit': limit},
    );

    dynamic payload = response;
    if (payload is Map && payload['data'] is Map) {
      payload = payload['data'];
    }

    final rows = <Map<String, dynamic>>[];
    num totalMoney = 0;
    String currency = '';
    if (payload is Map) {
      final raw = payload['payouts'] ?? payload['data'] ?? payload['items'];
      if (raw is List) rows.addAll(raw.whereType<Map<String, dynamic>>());
      // Backend decimals sometimes arrive as strings — never hard-cast money.
      final rawTotal = payload['totalMoney'];
      totalMoney =
          rawTotal is num ? rawTotal : num.tryParse('$rawTotal') ?? 0;
      currency = payload['currency']?.toString() ?? '';
    } else if (payload is List) {
      rows.addAll(payload.whereType<Map<String, dynamic>>());
    }

    return PayoutHistory(
      payouts: rows,
      totalMoney: totalMoney,
      currency: currency,
    );
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
      // Explicit key paths only. The old fallback picked "the first List found
      // anywhere in the map", which silently returns just ONE of two arrays the
      // day the backend starts splitting property and hotel stays — the exact
      // class of bug already documented for property search. Hotel bookings
      // land in this same list today (`{ success, data: [...] }`), but the
      // split shape is cheap to survive, so handle it rather than guess.
      final properties = raw['properties'];
      final hotels = raw['hotels'];
      raw = raw['trips'] ??
          raw['bookings'] ??
          raw['items'] ??
          raw['data'] ??
          [
            ...(properties is List ? properties : const []),
            ...(hotels is List ? hotels : const []),
          ];
    }
    if (raw is List) {
      final rows = raw.whereType<Map<String, dynamic>>().toList();
      final trips = rows.map(TripModel.fromJson).toList();
      if (kDebugMode) {
        debugPrint('[Trips] keys='
            '${response is Map ? response.keys.toList() : response.runtimeType}'
            ' rows=${trips.length} hotels=${trips.where((t) => t.isHotel).length}');
        // A row with no stay id can be neither reviewed nor re-booked, and the
        // key it hides behind is the one part of this contract no probe has
        // pinned down. Print the whole row so the next run names it.
        for (var i = 0; i < trips.length; i++) {
          final trip = trips[i];
          final stayId =
              trip.isHotel ? trip.resolvedHotelId : trip.propertyId.trim();
          if (stayId.isEmpty) {
            debugPrint('[Trips] ${trip.isHotel ? 'hotel' : 'property'} row '
                '${trip.id} carries no stay id — row=${rows[i]}');
          }
        }
      }
      return trips;
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

/// Result of [UserService.getPayouts]: the transaction rows plus the
/// credit-balance pair the backend returns alongside them.
class PayoutHistory {
  final List<Map<String, dynamic>> payouts;
  final num totalMoney;
  final String currency;

  const PayoutHistory({
    required this.payouts,
    required this.totalMoney,
    required this.currency,
  });
}
