/// Models for the "Your day here" block — the nearby places a stay is
/// surrounded by, and the categories they are filed under.
///
/// ONE model serves BOTH stay kinds, because the two backends disagree about
/// almost every field name and value format. See
/// `docs/nearby_places_contract.md` for the verified contract; the differences
/// that matter here are:
///
/// | | property | hotel |
/// |---|---|---|
/// | owner key | `propertyId` | `hotelId` |
/// | Arabic name | `nameAR` alongside `name` | no `nameAR` — `name` is already localized |
/// | `priceLevel` / `timeOfDay` | stable enums (`LATE_MORNING`) | **server-localized display text** (`Late Morning`, `قبل الظهر`) |
/// | `image` | present (always `""` so far) | absent |
///
/// The localization split is the trap. Property rows are never translated by
/// the backend — both `name` and `nameAR` always come back, so the client picks
/// by locale. Hotel rows ARE translated, enum-looking fields included, so
/// `timeOfDay` reads `"صباحاً"` in Arabic and cannot be switched on. Every
/// enum here therefore parses leniently and keeps the raw string as a fallback
/// label, and ordering falls back to `displayOrder` (a stable int on both).
library;

/// Part of the day a place belongs to, used to order the suggested day plan.
///
/// Declaration order IS the running order of the day — [NearbyPlace.compare]
/// sorts on `index`.
enum NearbyTimeOfDay {
  morning,
  lateMorning,
  afternoon,
  evening,
}

/// How expensive a place is, from `/api/Lookups/PriceLevel`.
enum NearbyPriceLevel {
  cheap,
  moderate,
  expensive,
}

/// Normalises a backend token so `LATE_MORNING`, `Late Morning` and
/// `late-morning` all collapse to the same key.
///
/// Arabic values (`"قبل الظهر"`) survive this untouched and simply match
/// nothing, which is the intended outcome: they are display text, not tokens.
String _token(Object? raw) => raw
    ?.toString()
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[\s\-]+'), '_') ??
    '';

NearbyTimeOfDay? _parseTimeOfDay(Object? raw) {
  switch (_token(raw)) {
    case 'morning':
      return NearbyTimeOfDay.morning;
    case 'late_morning':
      return NearbyTimeOfDay.lateMorning;
    case 'afternoon':
      return NearbyTimeOfDay.afternoon;
    case 'evening':
      return NearbyTimeOfDay.evening;
    default:
      return null;
  }
}

NearbyPriceLevel? _parsePriceLevel(Object? raw) {
  switch (_token(raw)) {
    case 'cheap':
      return NearbyPriceLevel.cheap;
    case 'moderately_priced':
    case 'moderate':
      return NearbyPriceLevel.moderate;
    case 'expensive':
      return NearbyPriceLevel.expensive;
    default:
      return null;
  }
}

int? _asIntOrNull(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _asDoubleOrNull(Object? value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

String _asString(Object? value) => value?.toString().trim() ?? '';

/// The raw form of an enum-ish field, kept only when it is worth showing.
///
/// `priceLevel` and `timeOfDay` come back as text the hotels backend has
/// already localized, which is why an unparseable value is printed verbatim
/// rather than dropped. But the admin DTOs express both as INTEGERS, so if a
/// read endpoint ever follows suit the same fallback would put a payments icon
/// next to a bare "2". A value that is just a number is an id, not a label.
String _displayLabel(String raw) =>
    raw.isEmpty || num.tryParse(raw) != null ? '' : raw;

/// A nearby category from `GET /api/Lookups/NearbyCategories`.
///
/// **Localizes through the `?lang=` QUERY param only** — the `lang` header is
/// ignored by this controller, exactly like `RegionCategory` and
/// `PropertyType`. The returned [name] is a bare slug (`coffee`, `breakfast`)
/// in English and a plain word in Arabic; neither is the marketing copy the
/// chips show. The UI keys its own copy off the stable [id] and only falls
/// back to [name] for an id it does not recognise, so a category added
/// backend-side still renders instead of vanishing.
class NearbyCategory {
  final int id;
  final String name;

  const NearbyCategory({required this.id, required this.name});

  factory NearbyCategory.fromJson(Map<String, dynamic> json) => NearbyCategory(
        id: _asIntOrNull(json['id']) ?? 0,
        name: _asString(json['name']),
      );

  static List<NearbyCategory> listFrom(Object? raw) => raw is List
      ? raw
          .whereType<Map>()
          .map((e) => NearbyCategory.fromJson(Map<String, dynamic>.from(e)))
          .where((c) => c.id > 0)
          .toList()
      : const <NearbyCategory>[];
}

/// One place near a stay.
///
/// Built from either `data.nearbyPlaces[]` on a details payload or the
/// per-category `…/nearby-places?categoryId=N` endpoint — the two return the
/// same row shape for a given stay kind.
class NearbyPlace {
  final String id;

  /// The property or hotel this place hangs off (`propertyId` / `hotelId`).
  final String stayId;

  final int categoryId;

  /// English name for a property; for a hotel this is whatever the backend
  /// localized it to. Read [localizedName] rather than this.
  final String name;

  /// Arabic name — properties only. Empty for hotels, which have no `nameAR`.
  final String nameAr;

  final String description;

  /// Arabic description — properties only. Empty for hotels.
  final String descriptionAr;

  /// Out of 5. Fractional in the wild (`4.5` in production), so never an int.
  final double? rating;

  /// Can be `0` (property, "no reviews yet") or `null` (hotel, "not tracked").
  /// Both mean "print no count", which is why the UI checks for a positive
  /// value rather than for null.
  final int? reviewCount;

  final int? distanceMeters;
  final int? walkMinutes;

  /// `0` in the wild for a place close enough that driving is meaningless.
  final int? driveMinutes;

  /// The raw `googleMapsUrl`. Untrusted — live rows carry values like `"test"`
  /// and `"testinnng"`. Use [mapsUri], which returns null for anything that is
  /// not an absolute http(s) URL.
  final String googleMapsUrl;

  /// Parsed price level, or null when the backend sent localized display text.
  final NearbyPriceLevel? priceLevel;

  /// The raw price-level string, kept so a hotel's already-localized
  /// `"متوسط السعر"` can still be shown when [priceLevel] could not parse.
  final String priceLevelLabel;

  /// Can be `0` (properties are 0-based in production) or `null` (hotels).
  final int? displayOrder;

  /// Parsed part of day, or null when the backend sent localized display text.
  final NearbyTimeOfDay? timeOfDay;

  /// The raw time-of-day string — the fallback label for [timeOfDay], same as
  /// [priceLevelLabel].
  final String timeOfDayLabel;

  /// Always `""` on every row observed so far, and absent entirely on hotels,
  /// but the backend DTO declares it nullable-string, so a URL may appear.
  final String imageUrl;

  const NearbyPlace({
    required this.id,
    required this.stayId,
    required this.categoryId,
    required this.name,
    this.nameAr = '',
    this.description = '',
    this.descriptionAr = '',
    this.rating,
    this.reviewCount,
    this.distanceMeters,
    this.walkMinutes,
    this.driveMinutes,
    this.googleMapsUrl = '',
    this.priceLevel,
    this.priceLevelLabel = '',
    this.displayOrder,
    this.timeOfDay,
    this.timeOfDayLabel = '',
    this.imageUrl = '',
  });

  factory NearbyPlace.fromJson(Map<String, dynamic> json) {
    final priceRaw = _asString(json['priceLevel']);
    final timeRaw = _asString(json['timeOfDay']);
    return NearbyPlace(
      id: _asString(json['id']),
      // Whichever key this backend uses — properties send `propertyId`,
      // hotels send `hotelId`.
      stayId: _asString(json['propertyId'] ?? json['hotelId']),
      categoryId: _asIntOrNull(json['categoryId']) ?? 0,
      name: _asString(json['name']),
      nameAr: _asString(json['nameAR'] ?? json['nameAr']),
      description: _asString(json['description']),
      descriptionAr: _asString(json['descriptionAR'] ?? json['descriptionAr']),
      rating: _asDoubleOrNull(json['rating']),
      reviewCount: _asIntOrNull(json['reviewCount']),
      distanceMeters: _asIntOrNull(json['distanceMeters']),
      walkMinutes: _asIntOrNull(json['walkMinutes']),
      driveMinutes: _asIntOrNull(json['driveMinutes']),
      googleMapsUrl: _asString(json['googleMapsUrl']),
      priceLevel: _parsePriceLevel(priceRaw),
      priceLevelLabel: _displayLabel(priceRaw),
      displayOrder: _asIntOrNull(json['displayOrder']),
      timeOfDay: _parseTimeOfDay(timeRaw),
      timeOfDayLabel: _displayLabel(timeRaw),
      imageUrl: _asString(json['image']),
    );
  }

  static List<NearbyPlace> listFrom(Object? raw) => raw is List
      ? raw
          .whereType<Map>()
          .map((e) => NearbyPlace.fromJson(Map<String, dynamic>.from(e)))
          .where((p) => p.name.isNotEmpty || p.nameAr.isNotEmpty)
          .toList()
      : const <NearbyPlace>[];

  /// The name to print. Arabic when we have one and the app is in Arabic;
  /// otherwise [name] — which for a hotel is already in the right language,
  /// because the hotels controller honours the `lang` header.
  String localizedName({required bool isArabic}) =>
      isArabic && nameAr.isNotEmpty ? nameAr : name;

  /// The description to print — same rule as [localizedName].
  String localizedDescription({required bool isArabic}) =>
      isArabic && descriptionAr.isNotEmpty ? descriptionAr : description;

  /// The maps link, or null when the stored value is not a usable web URL.
  ///
  /// Live data contains `"test"` and `"testinnng"`, which `Uri.parse` happily
  /// accepts as scheme-less relative references — hence the explicit scheme and
  /// host checks rather than a bare `tryParse` null test.
  Uri? get mapsUri {
    final uri = Uri.tryParse(googleMapsUrl.trim());
    if (uri == null) return null;
    if (uri.host.isEmpty) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return uri;
  }

  /// Whether a review count is worth printing — `0` and `null` both are not.
  bool get hasReviewCount => (reviewCount ?? 0) > 0;

  /// Whether the rating is worth printing.
  ///
  /// This payload spells "unset" as `0` in every numeric field it owns
  /// (`reviewCount`, `driveMinutes`, `displayOrder`) and as `""` in `image`, so
  /// a blank rating arrives as `0` too. Printing it would put a filled star and
  /// "0.0" next to the name, which reads as *rated zero* rather than *not
  /// rated yet*.
  bool get hasRating => (rating ?? 0) > 0;

  /// Whether the drive time is worth printing. `0` means "close enough that
  /// driving is not a thing", not "instant".
  bool get hasDriveMinutes => (driveMinutes ?? 0) > 0;

  bool get hasWalkMinutes => (walkMinutes ?? 0) > 0;

  /// Orders places for the suggested day plan: through the day first, then by
  /// the host's own [displayOrder].
  ///
  /// Rows whose [timeOfDay] did not parse (every hotel row in Arabic) sort
  /// after the ones that did rather than scattering through them.
  ///
  /// **This comparator deliberately stops there** — a place with neither key is
  /// left equal to its neighbours so [sorted] can fall back to the order the
  /// backend sent. Breaking the last tie on [name] used to look tidier and was
  /// wrong: an Arabic hotel has no parseable `timeOfDay` AND a null
  /// `displayOrder`, so every row tied and the chain came out alphabetical by
  /// Arabic name — the evening bar leading, arrows still asserting a sequence,
  /// and "start with coffee" printed on the last card. The same hotel in
  /// English ordered correctly, so the plan reversed itself on a language
  /// switch. Sort through [sorted], never with `List.sort`, which is unstable.
  static int compare(NearbyPlace a, NearbyPlace b) {
    final at = a.timeOfDay?.index ?? NearbyTimeOfDay.values.length;
    final bt = b.timeOfDay?.index ?? NearbyTimeOfDay.values.length;
    if (at != bt) return at.compareTo(bt);
    final ao = a.displayOrder ?? 1 << 30;
    final bo = b.displayOrder ?? 1 << 30;
    if (ao != bo) return ao.compareTo(bo);
    // Category id is the last key with any meaning: the lookup numbers them
    // coffee, breakfast, shopping, gifts, family, entertainment, essentials —
    // which is already roughly a day. It is also stable across languages,
    // unlike everything else left at this point.
    return a.categoryId.compareTo(b.categoryId);
  }

  /// [places] ordered by [compare], with ties resolved by the order they
  /// arrived in — a stable sort, which `List.sort` is not.
  ///
  /// The payload order is the last thing standing when a hotel gives us neither
  /// a parseable time of day nor a display order, and it is a real signal: the
  /// backend returns the rows in the order the hotel entered them.
  static List<NearbyPlace> sorted(List<NearbyPlace> places) {
    final indexed = [
      for (var i = 0; i < places.length; i++) (i, places[i]),
    ]..sort((a, b) {
        final byRule = compare(a.$2, b.$2);
        return byRule != 0 ? byRule : a.$1.compareTo(b.$1);
      });
    return [for (final entry in indexed) entry.$2];
  }

  /// The day plan: at most one place per category, earliest in the day first.
  ///
  /// One per category is what keeps the chain readable — the web shows coffee
  /// then breakfast then shopping, not three coffees. [limit] caps it so a
  /// well-stocked listing does not turn the row into an endless scroll.
  static List<NearbyPlace> dayPlan(List<NearbyPlace> places, {int limit = 4}) {
    final seen = <int>{};
    final plan = <NearbyPlace>[];
    for (final place in sorted(places)) {
      if (!seen.add(place.categoryId)) continue;
      plan.add(place);
      if (plan.length >= limit) break;
    }
    return plan;
  }
}
