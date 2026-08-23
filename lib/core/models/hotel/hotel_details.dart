import 'package:houseiana_mobile_app/core/models/hotel/hotel_summary.dart';

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
      );
}

/// Rooms a guest may add before the backend has reported the real stock (i.e.
/// before dates are picked). Deliberately small: both the quote and the booking
/// are re-validated server-side, so this only has to be a reasonable UI cap.
const int _unknownStockRoomCap = 10;
