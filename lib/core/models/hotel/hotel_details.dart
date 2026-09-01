import 'package:houseiana_mobile_app/core/models/hotel/hotel_summary.dart';
import 'package:houseiana_mobile_app/core/models/nearby_place.dart';

/// Models for `GET /api/hotels/{id}/details?checkIn=&checkOut=`.
///
/// The response nests hotel → roomTypes → ratePlans. Passing dates makes the
/// backend fill `nights`, `stayPrice` and `serviceFee`; without them `nights`
/// is 0 and only `basePrice` is meaningful.

class HotelPhoto {
  final String id;
  final String url;

  const HotelPhoto({required this.id, required this.url});

  factory HotelPhoto.fromJson(Map<String, dynamic> json) => HotelPhoto(
        id: asHotelString(json['id']),
        url: asHotelString(json['url']),
      );

  static List<HotelPhoto> listFrom(dynamic raw) => raw is List
      ? raw
          .whereType<Map>()
          .map((e) => HotelPhoto.fromJson(Map<String, dynamic>.from(e)))
          .where((p) => p.url.isNotEmpty)
          .toList()
      : const <HotelPhoto>[];
}

class HotelBedConfig {
  final String bedType;
  final int count;

  const HotelBedConfig({required this.bedType, this.count = 1});

  factory HotelBedConfig.fromJson(Map<String, dynamic> json) => HotelBedConfig(
        bedType: asHotelString(json['bedType']),
        count: asHotelInt(json['count'], 1),
      );

  static List<HotelBedConfig> listFrom(dynamic raw) => raw is List
      ? raw
          .whereType<Map>()
          .map((e) => HotelBedConfig.fromJson(Map<String, dynamic>.from(e)))
          .where((b) => b.bedType.isNotEmpty)
          .toList()
      : const <HotelBedConfig>[];
}

/// An add-on the guest can pay extra for: `{ id, name, price }`.
///
/// `GET /api/hotels/{id}/details` sends these twice — once at the hotel level
/// (`services`, e.g. "Airport Transfer") and once per room type
/// (`roomTypes[].services`, e.g. "Extra Bed").
///
/// **A service carries no currency of its own.** Currency in this API belongs
/// to the RATE PLAN, so the amount is only safe to label with the code the
/// surrounding plans agree on — [HotelRoomType.singleCurrencyCode] and
/// [HotelDetails.singleCurrencyCode] answer null when they do not, and the UI
/// then prints the bare number rather than guessing.
///
/// None of these are priced by `POST /api/hotel-quote`: its request carries a
/// rate plan, a room count and that room's occupancy, and has NO field for a
/// service id at all. They are therefore not part of any total the app shows,
/// and every surface that lists them has to say so.
class HotelExtraService {
  final int id;
  final String name;
  final double price;

  const HotelExtraService({
    required this.id,
    required this.name,
    this.price = 0,
  });

  /// A zero (or absent) price is an add-on at no charge, not a missing value.
  bool get isFree => price <= 0;

  factory HotelExtraService.fromJson(Map<String, dynamic> json) =>
      HotelExtraService(
        id: asHotelInt(json['id']),
        name: asHotelString(json['name']),
        price: asHotelDouble(json['price']) ?? 0,
      );

  static List<HotelExtraService> listFrom(dynamic raw) => raw is List
      ? raw
          .whereType<Map>()
          .map((e) => HotelExtraService.fromJson(Map<String, dynamic>.from(e)))
          .where((s) => s.name.isNotEmpty)
          .toList()
      : const <HotelExtraService>[];
}

/// One house rule: `{ name, allowed }` — `{"Pets Allowed", false}`.
///
/// The name is the hotel's own statement ("Pets Allowed", "ID Required at
/// Check-in", "Married Couples Only") and arrives already localized, so it is
/// shown as it came and never keyed off. [allowed] says whether that statement
/// is TRUE for this hotel — it is not a permission on the name, which is why
/// the UI renders a yes/no next to the sentence instead of the word "allowed"
/// ("ID Required at Check-in — Not allowed" would invert the meaning).
///
/// A missing flag reads as false: a hotel that never said "pets are fine" must
/// not be quoted as having said it.
class HotelPolicy {
  final String name;
  final bool allowed;

  const HotelPolicy({required this.name, this.allowed = false});

  factory HotelPolicy.fromJson(Map<String, dynamic> json) => HotelPolicy(
        name: asHotelString(json['name']),
        allowed: json['allowed'] == true,
      );

  static List<HotelPolicy> listFrom(dynamic raw) => raw is List
      ? raw
          .whereType<Map>()
          .map((e) => HotelPolicy.fromJson(Map<String, dynamic>.from(e)))
          .where((p) => p.name.isNotEmpty)
          .toList()
      : const <HotelPolicy>[];
}

/// What one age band of children costs:
/// `{ minAge, maxAge, ordinal, pricingMode, value }`.
///
/// `pricingMode` has only ever been observed as `FixedAmount`. [isPercentage]
/// is a tolerant reader for the percentage variant rather than a verified
/// value, and anything unrecognized falls back to a plain amount.
///
/// `ordinal` orders the bands. It is NOT confirmed to mean "the Nth child", so
/// the UI leads with the age range and prints the ordinal only to tell two
/// bands apart when a hotel sends more than one.
///
/// Whether the amount is per night or per stay is not in the contract, so no
/// screen may claim either — "per child" is as far as the payload goes.
class HotelChildRule {
  final int minAge;
  final int maxAge;
  final int ordinal;
  final String pricingMode;
  final double value;

  const HotelChildRule({
    this.minAge = 0,
    this.maxAge = 0,
    this.ordinal = 0,
    this.pricingMode = '',
    this.value = 0,
  });

  bool get isFree => value <= 0;

  bool get isPercentage => pricingMode.toLowerCase().contains('percent');

  factory HotelChildRule.fromJson(Map<String, dynamic> json) => HotelChildRule(
        minAge: asHotelInt(json['minAge']),
        maxAge: asHotelInt(json['maxAge']),
        ordinal: asHotelInt(json['ordinal']),
        pricingMode: asHotelString(json['pricingMode']),
        value: asHotelDouble(json['value']) ?? 0,
      );

  /// Sorted by `ordinal` so the bands print in the order the hotel entered
  /// them, not in whatever order the array happened to arrive in.
  static List<HotelChildRule> listFrom(dynamic raw) => raw is List
      ? (raw
          .whereType<Map>()
          .map((e) => HotelChildRule.fromJson(Map<String, dynamic>.from(e)))
          .toList()
        ..sort((a, b) => a.ordinal.compareTo(b.ordinal)))
      : const <HotelChildRule>[];
}

/// `childrenPolicy` — the hotel's stance on children plus its per-age-band
/// charges.
///
/// **Null on hotels that never filled it in**, which means UNKNOWN and not
/// "children are banned". The section simply does not render, the same way a
/// null `availableUnits` means unknown stock rather than sold out.
class HotelChildrenPolicy {
  final bool childrenAllowed;
  final int? minChildAge;
  final int? maxChildAge;
  final List<HotelChildRule> rules;

  const HotelChildrenPolicy({
    this.childrenAllowed = false,
    this.minChildAge,
    this.maxChildAge,
    this.rules = const <HotelChildRule>[],
  });

  /// A band worth printing needs an upper bound — `maxChildAge` alone is enough
  /// ("up to 12"), but a lone `minChildAge` of 0 says nothing.
  bool get hasAgeRange => maxChildAge != null && maxChildAge! > 0;

  factory HotelChildrenPolicy.fromJson(Map<String, dynamic> json) =>
      HotelChildrenPolicy(
        childrenAllowed: json['childrenAllowed'] == true,
        minChildAge: asHotelIntOrNull(json['minChildAge']),
        maxChildAge: asHotelIntOrNull(json['maxChildAge']),
        rules: HotelChildRule.listFrom(json['rules']),
      );

  /// Null-safe entry point — the key is absent or null on most hotels.
  static HotelChildrenPolicy? from(dynamic raw) => raw is Map
      ? HotelChildrenPolicy.fromJson(Map<String, dynamic>.from(raw))
      : null;
}

/// A bookable rate on a room type. This is the unit the quote and the booking
/// both address — `ratePlanId`, never the room-type id.
class HotelRatePlan {
  final String id;
  final String boardBasis;
  final String cancellationPolicyType;

  /// Per rate plan, NOT per hotel: one hotel was observed quoting EGP on one
  /// room type and QAR on another. Never lift this to the hotel level.
  final String currencyCode;

  final double basePrice;

  /// `basePrice * nights` for the dates in the request — 0 when no dates were
  /// sent, in which case only [basePrice] should be shown.
  final double stayPrice;
  final double serviceFee;

  final int freeCancellationHours;
  final int freeCancellationDays;

  const HotelRatePlan({
    required this.id,
    this.boardBasis = '',
    this.cancellationPolicyType = '',
    this.currencyCode = 'EGP',
    this.basePrice = 0,
    this.stayPrice = 0,
    this.serviceFee = 0,
    this.freeCancellationHours = 0,
    this.freeCancellationDays = 0,
  });

  bool get hasFreeCancellation =>
      freeCancellationDays > 0 || freeCancellationHours > 0;

  /// The free-cancellation window counts BACK from CHECK-IN, never forward from
  /// the booking date — the same anchor the property cancellation copy uses.
  /// Returns null until the guest has actually picked a check-in date.
  DateTime? freeCancellationDeadline(DateTime? checkIn) {
    if (checkIn == null || !hasFreeCancellation) return null;
    return checkIn.subtract(
      Duration(days: freeCancellationDays, hours: freeCancellationHours),
    );
  }

  /// Price for one room for the whole stay. Falls back to the nightly base when
  /// the details call carried no dates.
  double get effectiveStayPrice => stayPrice > 0 ? stayPrice : basePrice;

  factory HotelRatePlan.fromJson(Map<String, dynamic> json) {
    final code = asHotelString(json['currencyCode']);
    return HotelRatePlan(
      id: asHotelString(json['id']),
      boardBasis: asHotelString(json['boardBasis']),
      cancellationPolicyType: asHotelString(json['cancellationPolicyType']),
      currencyCode: code.isEmpty ? 'EGP' : code,
      basePrice: asHotelDouble(json['basePrice']) ?? 0,
      stayPrice: asHotelDouble(json['stayPrice']) ?? 0,
      serviceFee: asHotelDouble(json['serviceFee']) ?? 0,
      freeCancellationHours: asHotelInt(json['freeCancellationHours']),
      freeCancellationDays: asHotelInt(json['freeCancellationDays']),
    );
  }

  static List<HotelRatePlan> listFrom(dynamic raw) => raw is List
      ? raw
          .whereType<Map>()
          .map((e) => HotelRatePlan.fromJson(Map<String, dynamic>.from(e)))
          .where((p) => p.id.isNotEmpty)
          .toList()
      : const <HotelRatePlan>[];
}

class HotelRoomType {
  final String id;
  final String name;
  final String description;
  final String roomCategory;
  final String viewType;
  final String coverPhoto;
  final int sizeSqm;
  final int baseOccupancy;

  /// Rooms left for the requested dates, or **null when the details call
  /// carried no dates** — the backend cannot know the stock without a range,
  /// and it answers null (verified live), not 0.
  ///
  /// Null therefore means UNKNOWN, never "sold out". Collapsing the two is how
  /// a dateless visit ends up branding a fully available hotel as fully booked.
  final int? availableUnits;
  final List<HotelPhoto> photos;
  final List<HotelBedConfig> beds;
  final List<HotelAmenity> amenities;
  final List<HotelRatePlan> ratePlans;

  /// Paid add-ons offered on THIS room type ("Extra Bed"). Never priced by
  /// the quote — see [HotelExtraService].
  final List<HotelExtraService> services;

  const HotelRoomType({
    required this.id,
    required this.name,
    this.description = '',
    this.roomCategory = '',
    this.viewType = '',
    this.coverPhoto = '',
    this.sizeSqm = 0,
    this.baseOccupancy = 0,
    this.availableUnits,
    this.photos = const <HotelPhoto>[],
    this.beds = const <HotelBedConfig>[],
    this.amenities = const <HotelAmenity>[],
    this.ratePlans = const <HotelRatePlan>[],
    this.services = const <HotelExtraService>[],
  });

  /// Only a stock the backend actually reported as zero is sold out. An unknown
  /// stock (no dates in the query) is bookable — the guest picks dates and the
  /// real number arrives with them.
  bool get isSoldOut => ratePlans.isEmpty || availableUnits == 0;

  /// True once the backend has priced a real date range, so the UI may show
  /// stock-based copy ("only 2 rooms left") and cap the rooms stepper.
  bool get hasKnownAvailability => availableUnits != null;

  /// Upper bound for the rooms stepper. With an unknown stock, fall back to a
  /// sane cap instead of locking the control at zero.
  int get maxSelectableRooms => availableUnits ?? _unknownStockRoomCap;

  /// Cover first, then the gallery, de-duplicated and blank-free.
  List<String> get galleryUrls {
    final urls = <String>[];
    if (coverPhoto.isNotEmpty) urls.add(coverPhoto);
    for (final p in photos) {
      if (p.url.isNotEmpty && !urls.contains(p.url)) urls.add(p.url);
    }
    return urls;
  }

  /// The one currency every rate plan on this room quotes, or null when they
  /// disagree. A service fee arrives without a currency of its own, so this is
  /// the only code that can honestly be printed next to one.
  String? get singleCurrencyCode {
    final codes = <String>{for (final plan in ratePlans) plan.currencyCode};
    return codes.length == 1 ? codes.first : null;
  }

  HotelRatePlan? get cheapestRatePlan {
    if (ratePlans.isEmpty) return null;
    final sorted = [...ratePlans]..sort((a, b) {
        final byStay = a.effectiveStayPrice.compareTo(b.effectiveStayPrice);
        return byStay != 0 ? byStay : a.basePrice.compareTo(b.basePrice);
      });
    return sorted.first;
  }

  factory HotelRoomType.fromJson(Map<String, dynamic> json) => HotelRoomType(
        id: asHotelString(json['id']),
        name: asHotelString(json['name']),
        description: asHotelString(json['description']),
        roomCategory: asHotelString(json['roomCategory']),
        viewType: asHotelString(json['viewType']),
        coverPhoto: asHotelString(json['coverPhoto']),
        sizeSqm: asHotelInt(json['sizeSqm']),
        baseOccupancy: asHotelInt(json['baseOccupancy']),
        availableUnits: asHotelIntOrNull(json['availableUnits']),
        photos: HotelPhoto.listFrom(json['photos']),
        beds: HotelBedConfig.listFrom(json['beds']),
        amenities: HotelAmenity.listFrom(json['amenities']),
        ratePlans: HotelRatePlan.listFrom(json['ratePlans']),
        services: HotelExtraService.listFrom(json['services']),
      );
}

class HotelDetails {
  final String hotelId;
  final String name;
  final String description;
  final String coverPhoto;
  final String cityName;
  final String countryName;
  final String streetAddress;
  final String checkInTime;
  final String checkOutTime;
  final int starRating;
  final int reviewCount;

  /// Nights the backend priced for — 0 when the details call carried no dates.
  final int nights;

  final double? reviewScore;
  final double? latitude;
  final double? longitude;
  final List<HotelPhoto> photos;
  final List<HotelAmenity> amenities;
  final List<HotelRoomType> roomTypes;

  /// The hotel's own house rules (`policies`) — yes/no statements, localized.
  final List<HotelPolicy> policies;

  /// Paid add-ons offered by the hotel itself ("Airport Transfer").
  final List<HotelExtraService> services;

  /// Null when the hotel never filled it in — UNKNOWN, not "no children".
  final HotelChildrenPolicy? childrenPolicy;

  /// The "Your day here" places. Same section as the property screen's, but
  /// the rows arrive in the hotel dialect — see [NearbyPlace]. Usually empty.
  final List<NearbyPlace> nearbyPlaces;

  const HotelDetails({
    required this.hotelId,
    required this.name,
    this.description = '',
    this.coverPhoto = '',
    this.cityName = '',
    this.countryName = '',
    this.streetAddress = '',
    this.checkInTime = '',
    this.checkOutTime = '',
    this.starRating = 0,
    this.reviewCount = 0,
    this.nights = 0,
    this.reviewScore,
    this.latitude,
    this.longitude,
    this.photos = const <HotelPhoto>[],
    this.amenities = const <HotelAmenity>[],
    this.roomTypes = const <HotelRoomType>[],
    this.policies = const <HotelPolicy>[],
    this.services = const <HotelExtraService>[],
    this.childrenPolicy,
    this.nearbyPlaces = const <NearbyPlace>[],
  });

  /// Every gallery image, cover first, de-duplicated.
  List<String> get galleryUrls {
    final urls = <String>[];
    if (coverPhoto.isNotEmpty) urls.add(coverPhoto);
    for (final p in photos) {
      if (p.url.isNotEmpty && !urls.contains(p.url)) urls.add(p.url);
    }
    return urls;
  }

  String get location =>
      [cityName, countryName].where((s) => s.trim().isNotEmpty).join(', ');

  /// Hotels send real coordinates, so an absent pair means "no map" — never a
  /// reason to geocode the address like the property screen does.
  bool get hasCoordinates => latitude != null && longitude != null;

  bool get hasRating => reviewScore != null && reviewCount > 0;

  List<HotelRatePlan> get allRatePlans =>
      [for (final r in roomTypes) ...r.ratePlans];

  /// True when two rate plans quote different currencies. The UI then refuses to
  /// print a single hotel-level "from" price, because adding EGP to QAR is wrong.
  bool get hasMixedCurrencies =>
      allRatePlans.map((p) => p.currencyCode).toSet().length > 1;

  /// The one currency every rate plan in this hotel quotes, or null when they
  /// disagree — the inverse of [hasMixedCurrencies], and the only code that may
  /// be printed next to a currency-less amount such as a service fee or a
  /// children's charge.
  String? get singleCurrencyCode {
    final codes = <String>{for (final plan in allRatePlans) plan.currencyCode};
    return codes.length == 1 ? codes.first : null;
  }

  HotelRatePlan? get cheapestRatePlan {
    final plans = allRatePlans;
    if (plans.isEmpty) return null;
    final sorted = [...plans]..sort((a, b) => a.basePrice.compareTo(b.basePrice));
    return sorted.first;
  }

  bool get hasBookableRooms => roomTypes.any((r) => !r.isSoldOut);

  factory HotelDetails.fromJson(Map<String, dynamic> json) => HotelDetails(
        hotelId: asHotelString(json['hotelId'] ?? json['id']),
        name: asHotelString(json['name']),
        description: asHotelString(json['description']),
        coverPhoto: asHotelString(json['coverPhoto']),
        cityName: asHotelString(json['cityName']),
        countryName: asHotelString(json['countryName']),
        streetAddress: asHotelString(json['streetAddress']),
        checkInTime: asHotelString(json['checkInTime']),
        checkOutTime: asHotelString(json['checkOutTime']),
        starRating: asHotelInt(json['starRating']),
        reviewCount: asHotelInt(json['reviewCount']),
        nights: asHotelInt(json['nights']),
        reviewScore: asHotelDouble(json['reviewScore']),
        latitude: asHotelDouble(json['latitude']),
        longitude: asHotelDouble(json['longitude']),
        photos: HotelPhoto.listFrom(json['photos']),
        amenities: HotelAmenity.listFrom(json['amenities']),
        roomTypes: json['roomTypes'] is List
            ? (json['roomTypes'] as List)
                .whereType<Map>()
                .map((e) => HotelRoomType.fromJson(Map<String, dynamic>.from(e)))
                .where((r) => r.id.isNotEmpty)
                .toList()
            : const <HotelRoomType>[],
        policies: HotelPolicy.listFrom(json['policies']),
        services: HotelExtraService.listFrom(json['services']),
        childrenPolicy: HotelChildrenPolicy.from(json['childrenPolicy']),
        nearbyPlaces: NearbyPlace.listFrom(json['nearbyPlaces']),
      );
}

/// Rooms a guest may add before the backend has reported the real stock (i.e.
/// before dates are picked). Deliberately small: both the quote and the booking
/// are re-validated server-side, so this only has to be a reasonable UI cap.
const int _unknownStockRoomCap = 10;
