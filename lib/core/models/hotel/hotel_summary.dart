/// Models for `GET /api/hotel-search` — the grouped hotel search results.
///
/// Verified response shape:
/// `{ success, data: { hotels: [ { regionId?, name, totalCount, hotels: [...] } ],
///    totalGroups }, pagination: { page, limit, total, totalPages } }`
library;

/// Tolerant readers. Money has been seen arriving as a String elsewhere in this
/// API (the payout contract), so nothing here ever hard-casts.
int asHotelInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

int? asHotelIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? asHotelDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

String asHotelString(dynamic value) => value?.toString().trim() ?? '';

/// A hotel or room-type amenity (`{ id, name }`). Names arrive already
/// localized — the `lang` header works on the hotels endpoints.
class HotelAmenity {
  final int id;
  final String name;

  const HotelAmenity({required this.id, required this.name});

  factory HotelAmenity.fromJson(Map<String, dynamic> json) => HotelAmenity(
        id: asHotelInt(json['id']),
        name: asHotelString(json['name']),
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  static List<HotelAmenity> listFrom(dynamic raw) => raw is List
      ? raw
          .whereType<Map>()
          .map((e) => HotelAmenity.fromJson(Map<String, dynamic>.from(e)))
          .where((a) => a.name.isNotEmpty)
          .toList()
      : const <HotelAmenity>[];
}

/// One hotel row inside a search group.
class HotelSummary {
  final String hotelId;
  final String name;
  final String coverPhoto;
  final String cityName;
  final String countryName;
  final String currencyCode;
  final int starRating;
  final int reviewCount;
  final int nights;
  final int availableRoomTypes;
  final double? reviewScore;
  final double price;

  /// The signed-in user's wishlist state. NOT the same thing as
  /// [isGuestFavorite] — seeding a heart from that one resurrects hotels the
  /// user never saved (the property side already learned this the hard way).
  final bool isFavorite;

  /// Quality BADGE ("Guest favourite"), awarded by the backend. Display only.
  final bool isGuestFavorite;

  final List<HotelAmenity> amenities;

  const HotelSummary({
    required this.hotelId,
    required this.name,
    this.coverPhoto = '',
    this.cityName = '',
    this.countryName = '',
    this.currencyCode = 'EGP',
    this.starRating = 0,
    this.reviewCount = 0,
    this.nights = 0,
    this.availableRoomTypes = 0,
    this.reviewScore,
    this.price = 0,
    this.isFavorite = false,
    this.isGuestFavorite = false,
    this.amenities = const <HotelAmenity>[],
  });

  /// `nights == 0` (the search carried no dates) → [price] is a per-night rate.
  /// `nights > 0` → [price] is the STAY TOTAL for the searched dates and rooms
  /// (`basePrice * nights * rooms`). The card must label it accordingly.
  bool get isStayTotal => nights > 0;

  bool get hasRating => reviewScore != null && reviewCount > 0;

  String get location =>
      [cityName, countryName].where((s) => s.trim().isNotEmpty).join(', ');

  factory HotelSummary.fromJson(Map<String, dynamic> json) {
    final code = asHotelString(json['currencyCode']);
    return HotelSummary(
      hotelId: asHotelString(json['hotelId'] ?? json['id']),
      name: asHotelString(json['name']),
      coverPhoto: asHotelString(json['coverPhoto']),
      cityName: asHotelString(json['cityName']),
      countryName: asHotelString(json['countryName']),
      currencyCode: code.isEmpty ? 'EGP' : code,
      starRating: asHotelInt(json['starRating']),
      reviewCount: asHotelInt(json['reviewCount']),
      nights: asHotelInt(json['nights']),
      availableRoomTypes: asHotelInt(json['availableRoomTypes']),
      reviewScore: asHotelDouble(json['reviewScore']),
      price: asHotelDouble(json['price']) ?? 0,
      isFavorite: json['isFavorite'] == true,
      isGuestFavorite: json['isGuestFavorite'] == true,
      amenities: HotelAmenity.listFrom(json['amenities']),
    );
  }

  /// Round-trips through [HotelSummary.fromJson] so a page can be cached.
  Map<String, dynamic> toJson() => {
        'hotelId': hotelId,
        'name': name,
        'coverPhoto': coverPhoto,
        'cityName': cityName,
        'countryName': countryName,
        'currencyCode': currencyCode,
        'starRating': starRating,
        'reviewCount': reviewCount,
        'nights': nights,
        'availableRoomTypes': availableRoomTypes,
        'reviewScore': reviewScore,
        'price': price,
        'isFavorite': isFavorite,
        'isGuestFavorite': isGuestFavorite,
        'amenities': [for (final a in amenities) a.toJson()],
      };

  HotelSummary copyWith({bool? isFavorite}) => HotelSummary(
        hotelId: hotelId,
        name: name,
        coverPhoto: coverPhoto,
        cityName: cityName,
        countryName: countryName,
        currencyCode: currencyCode,
        starRating: starRating,
        reviewCount: reviewCount,
        nights: nights,
        availableRoomTypes: availableRoomTypes,
        reviewScore: reviewScore,
        price: price,
        isFavorite: isFavorite ?? this.isFavorite,
        isGuestFavorite: isGuestFavorite,
        amenities: amenities,
      );
}

/// One group of hotels in the search response.
class HotelGroup {
  /// Null when the search was ALREADY scoped by `regionId`: the backend then
  /// groups by CITY and omits the key entirely. Present (and drillable) only on
  /// an unscoped search, where the groups are regions.
  final int? regionId;
  final String name;
  final int totalCount;
  final List<HotelSummary> hotels;

  const HotelGroup({
    this.regionId,
    required this.name,
    this.totalCount = 0,
    this.hotels = const <HotelSummary>[],
  });

  /// Only a region-level group can be drilled into — a city group carries no id
  /// to send back as `regionId`.
  bool get canDrillDown => regionId != null;

  factory HotelGroup.fromJson(Map<String, dynamic> json) => HotelGroup(
        regionId: asHotelIntOrNull(json['regionId']),
        name: asHotelString(json['name']),
        totalCount: asHotelInt(json['totalCount']),
        hotels: json['hotels'] is List
            ? (json['hotels'] as List)
                .whereType<Map>()
                .map((e) => HotelSummary.fromJson(Map<String, dynamic>.from(e)))
                .where((h) => h.hotelId.isNotEmpty)
                .toList()
            : const <HotelSummary>[],
      );

  Map<String, dynamic> toJson() => {
        'regionId': regionId,
        'name': name,
        'totalCount': totalCount,
        'hotels': [for (final h in hotels) h.toJson()],
      };

  HotelGroup copyWith({List<HotelSummary>? hotels}) => HotelGroup(
        regionId: regionId,
        name: name,
        totalCount: totalCount,
        hotels: hotels ?? this.hotels,
      );
}

/// One page of grouped hotel results.
class HotelSearchPage {
  final List<HotelGroup> groups;
  final int totalGroups;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const HotelSearchPage({
    this.groups = const <HotelGroup>[],
    this.totalGroups = 0,
    this.page = 1,
    this.limit = 20,
    this.total = 0,
    this.totalPages = 0,
  });

  /// The hotel response carries NO `hasMore` flag (unlike property search) —
  /// derive it from the page counters instead of inventing one.
  bool get hasMore => page < totalPages;

  List<HotelSummary> get flatHotels => [for (final g in groups) ...g.hotels];

  bool get isEmpty => flatHotels.isEmpty;

  Map<String, dynamic> toCacheJson() => {
        'groups': [for (final g in groups) g.toJson()],
        'totalGroups': totalGroups,
        'page': page,
        'limit': limit,
        'total': total,
        'totalPages': totalPages,
      };

  factory HotelSearchPage.fromCacheJson(Map<String, dynamic> json) =>
      HotelSearchPage(
        groups: json['groups'] is List
            ? (json['groups'] as List)
                .whereType<Map>()
                .map((e) => HotelGroup.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : const <HotelGroup>[],
        totalGroups: asHotelInt(json['totalGroups']),
        page: asHotelInt(json['page'], 1),
        limit: asHotelInt(json['limit'], 20),
        total: asHotelInt(json['total']),
        totalPages: asHotelInt(json['totalPages']),
      );
}

/// Query params for `GET /api/hotel-search`.
///
/// NOTE the camelCase keys: hotels take `checkIn`/`checkOut`, while the property
/// search endpoint takes lowercase `checkin`/`checkout`. Not interchangeable.
class HotelSearchParams {
  final String? userId;
  final String? checkIn;
  final String? checkOut;
  final int? adults;
  final int? children;
  final int? rooms;

  /// Hotel-search region id — a THIRD id space, unrelated to `featuredRegionId`
  /// (RegionCategory 18–27) and to `villageId`. Its only source is the
  /// `regionId` on an unscoped search response's groups.
  final int? regionId;

  final int page;
  final int limit;

  const HotelSearchParams({
    this.userId,
    this.checkIn,
    this.checkOut,
    this.adults,
    this.children,
    this.rooms,
    this.regionId,
    this.page = 1,
    this.limit = 20,
  });

  /// `loadMore` must go through here rather than rebuilding the object by hand —
  /// a hand-rebuilt copy is how the property search kept dropping filters.
  HotelSearchParams copyWith({int? page, int? limit, int? regionId}) =>
      HotelSearchParams(
        userId: userId,
        checkIn: checkIn,
        checkOut: checkOut,
        adults: adults,
        children: children,
        rooms: rooms,
        regionId: regionId ?? this.regionId,
        page: page ?? this.page,
        limit: limit ?? this.limit,
      );

  /// The API wants a plain calendar day. An ISO timestamp is silently
  /// mis-handled here the same way it was on property search, so anything with
  /// a `T` is truncated at it.
  static String? dateOnly(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final tIndex = trimmed.indexOf('T');
    return tIndex > 0 ? trimmed.substring(0, tIndex) : trimmed;
  }

  Map<String, dynamic> toQueryParams() {
    final inDate = dateOnly(checkIn);
    final outDate = dateOnly(checkOut);
    return {
      if (userId != null && userId!.isNotEmpty) 'userId': userId,
      if (inDate != null) 'checkIn': inDate,
      if (outDate != null) 'checkOut': outDate,
      if (adults != null && adults! > 0) 'adults': adults,
      if (children != null && children! > 0) 'children': children,
      if (rooms != null && rooms! > 0) 'rooms': rooms,
      if (regionId != null) 'regionId': regionId,
      'page': page,
      'limit': limit,
    };
  }
}
