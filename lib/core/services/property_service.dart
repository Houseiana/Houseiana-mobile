import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:houseiana_mobile_app/core/constants/errors/exceptions.dart';
import 'package:houseiana_mobile_app/core/models/country_option.dart';
import 'package:houseiana_mobile_app/core/models/nightly_price_model.dart';
import 'package:houseiana_mobile_app/core/models/property_model.dart';
import 'package:houseiana_mobile_app/core/models/region_category_model.dart';
import 'package:houseiana_mobile_app/core/models/region_village_model.dart';
import 'package:houseiana_mobile_app/core/models/review_model.dart';
import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/network/api/end_points.dart';
import 'package:houseiana_mobile_app/core/services/lookups_cache.dart';

class PropertySearchParams {
  final String? location;
  final String? checkIn;
  final String? checkOut;
  final int? guests;
  final double? minPrice;
  final double? maxPrice;
  final List<String>? amenities;
  final String? propertyType;
  final int? minBedrooms;
  final int? beds;
  final int? minBathrooms;
  final double? minRating;
  final int page;
  final int limit;
  final bool? isSorted;

  /// Sort option id (as a string) from `/api/Lookups/PropertySorting`, e.g.
  /// '3' = Price High→Low. Sent to the backend as the `sortBy` query param,
  /// matching the web contract. Null/empty means no explicit sort.
  final String? sortBy;
  final dynamic regionId;

  /// Village id from `/api/Lookups/region-villages`, sent to the search
  /// endpoint as the `villageId` query param (Country tab drill-down:
  /// country → region → village → stays). Village ids live in a DIFFERENT id
  /// space than the RegionCategory region ids — never send a region id here.
  /// Null means no village filter.
  final int? villageId;

  /// Region category id from `/api/Lookups/RegionCategory`, sent to the search
  /// endpoint as the `featuredRegionId` query param. Used to scope the HOME
  /// featured listings to a destination via the in-place chip filter. Distinct
  /// from [villageId], which is the deep-listing equivalent. Null means All.
  final int? featuredRegionId;

  /// Geo-radius filter sent to `/api/property-search` as `lat`, `lng` and
  /// `radiusKm`. Populated from the search map's visible region (center +
  /// half-diagonal distance in km) so panning/zooming the map re-queries that
  /// area. Mirrors the web "discover" map contract (use-discover →
  /// publicSearchFilter). All three are set together; null means no geo filter.
  final double? lat;
  final double? lng;
  final double? radiusKm;

  PropertySearchParams({
    this.location,
    this.checkIn,
    this.checkOut,
    this.guests,
    this.minPrice,
    this.maxPrice,
    this.amenities,
    this.propertyType,
    this.minBedrooms,
    this.beds,
    this.minBathrooms,
    this.minRating,
    this.page = 1,
    this.limit = 20,
    this.isSorted,
    this.sortBy,
    this.regionId,
    this.villageId,
    this.featuredRegionId,
    this.lat,
    this.lng,
    this.radiusKm,
  });

  /// Calendar day (`yyyy-MM-dd`) for a date the caller may hand over as a full
  /// ISO timestamp — the search modal passes `DateTime.toIso8601String()`
  /// (`2026-08-05T00:00:00.000`), while every other date this app sends the
  /// backend is a plain day. Trimmed here, the single place the query is built,
  /// so the first page and every `loadMore` agree.
  static String? _dateOnly(String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final t = trimmed.indexOf('T');
    return t > 0 ? trimmed.substring(0, t) : trimmed;
  }

  Map<String, dynamic> toQueryParams() => {
        if (location != null && location!.isNotEmpty) 'location': location,
        if (_dateOnly(checkIn) != null) 'checkin': _dateOnly(checkIn),
        if (_dateOnly(checkOut) != null) 'checkout': _dateOnly(checkOut),
        if (guests != null) 'guests': guests,
        if (minPrice != null) 'minPrice': minPrice,
        if (maxPrice != null) 'maxPrice': maxPrice,
        // Sent as repeated keys (amenities=1&amenities=2) via Dio's ListFormat.multi,
        // matching the web contract. Values are amenity IDs from /api/lookups/Amenities.
        if (amenities?.isNotEmpty == true) 'amenities': amenities,
        if (propertyType != null) 'type': propertyType,
        // Backend/web contract uses `bedrooms`/`bathrooms` (treated as a minimum),
        // NOT `minBedrooms`/`minBathrooms` — the latter are silently ignored, which
        // made these two filters do nothing. Field names stay min* internally.
        if (minBedrooms != null) 'bedrooms': minBedrooms,
        if (beds != null) 'beds': beds,
        if (minBathrooms != null) 'bathrooms': minBathrooms,
        if (minRating != null) 'minRating': minRating,
        if (isSorted == true) 'isSorted': 'true',
        if (sortBy != null && sortBy!.isNotEmpty) 'sortBy': sortBy,
        if (regionId != null) 'regionId': regionId,
        if (villageId != null) 'villageId': villageId,
        if (featuredRegionId != null) 'featuredRegionId': featuredRegionId,
        // Map viewport → center + radius geo filter. radiusKm is rounded up to a
        // whole km to mirror the web's `Math.ceil` (which sends an integer).
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (radiusKm != null) 'radiusKm': radiusKm!.ceil(),
        'page': page,
        'limit': limit,
      };
}

/// A sort choice from `/api/Lookups/PropertySorting`. [id] is sent to the
/// search API as the `sortBy` query param; [name] is the backend-provided
/// label (the UI may localize known ids and fall back to this name).
class SortOption {
  final String id;
  final String name;

  const SortOption({required this.id, required this.name});
}

class CityPropertyGroup {
  final int? regionId;
  final String name;
  final String? nameAr;
  final int? totalCount;
  final List<Map<String, dynamic>> properties;

  const CityPropertyGroup({
    this.regionId,
    required this.name,
    this.nameAr,
    this.totalCount,
    required this.properties,
  });

  /// Returns the localized city/region label — `nameAr` when in Arabic and
  /// available, otherwise `name`.
  String localizedName({required bool isArabic}) {
    if (isArabic && nameAr != null && nameAr!.trim().isNotEmpty) {
      return nameAr!;
    }
    return name;
  }

  /// Serialises the group (including its raw property maps) so a home page can
  /// be persisted to the cache and restored via [CityPropertyGroup.fromCacheJson].
  Map<String, dynamic> toCacheJson() => {
        'regionId': regionId,
        'name': name,
        'nameAr': nameAr,
        'totalCount': totalCount,
        'properties': properties,
      };

  /// Rebuilds a group from its cached JSON (see [toCacheJson]).
  factory CityPropertyGroup.fromCacheJson(Map<String, dynamic> json) {
    final rawProps = json['properties'];
    return CityPropertyGroup(
      regionId: (json['regionId'] as num?)?.toInt(),
      name: (json['name'] ?? '').toString(),
      nameAr: json['nameAr']?.toString(),
      totalCount: (json['totalCount'] as num?)?.toInt(),
      properties: rawProps is List
          ? rawProps
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : const [],
    );
  }
}

/// Normalizes raw property-search JSON through the [PropertyModel] layer
/// (`fromJson(...).toJson()`), which is what the card widgets' map keys rely
/// on. Top-level so [compute] can run it off the UI isolate for big pages —
/// the map CONTENTS are byte-identical to the old on-main-thread path.
List<Map<String, dynamic>> _normalizePropertyMaps(
    List<Map<String, dynamic>> raw) {
  return raw.map((m) => PropertyModel.fromJson(m).toJson()).toList();
}

/// Below this count the isolate spawn + payload copy costs more than the
/// normalization itself, so small pages stay synchronous.
const int _normalizeComputeThreshold = 30;

class PropertySearchPage {
  /// Normalized property maps (see [_normalizePropertyMaps]) — the exact
  /// shape the guest list cards consume. Callers no longer re-serialize
  /// models themselves.
  final List<Map<String, dynamic>> properties;

  /// Backend-reported total number of matches across ALL pages (the
  /// `totalCount` at the top of the property-search response). Null when the
  /// response carries no total — callers fall back to the loaded count.
  final int? total;

  const PropertySearchPage({required this.properties, this.total});
}

class GroupedPropertiesPage {
  final List<CityPropertyGroup> groups;
  final bool hasMore;
  final int total;
  final int totalGroups;

  const GroupedPropertiesPage({
    required this.groups,
    required this.hasMore,
    required this.total,
    required this.totalGroups,
  });
}

class PropertyService {
  final ApiConsumer _api;
  final LookupsCache _lookups;

  PropertyService(this._api, this._lookups);

  /// Searches listings and returns one flat page of normalized property maps.
  ///
  /// Deliberately **never** sends `userId`: `/api/property-search` switches to
  /// personalized pricing the moment a user id is present — it stacks the
  /// platform's "New Listing Discount" on top of the host's calendar discount
  /// (2000 → 1400 → 1120) and reports the combined `discountPercent`. The
  /// guest calendar (`/nightly-prices`) and the booking quote (`/availability`)
  /// are queried without a user id, so a personalized row made the same unit
  /// read one price on the card and another everywhere else. Every guest-facing
  /// price surface therefore stays on the public pricing.
  Future<PropertySearchPage> searchProperties(
    PropertySearchParams params, {
    CancelToken? cancelToken,
  }) async {
    final query = params.toQueryParams();

    try {
      final response = await _api.get(
        EndPoints.propertySearch,
        queryParameters: query,
        cancelToken: cancelToken,
      );
      final rawList = _extractList(response);
      final normalized = rawList.length >= _normalizeComputeThreshold
          ? await compute(_normalizePropertyMaps, rawList)
          : _normalizePropertyMaps(rawList);
      final total = _extractTotal(response);
      if (kDebugMode) {
        // An empty page is ambiguous from the outside (no matches vs. a shape
        // we failed to read) — print what was asked and what came back.
        debugPrint('[PropertySearch] $query → rows=${normalized.length} '
            'total=$total');
      }
      return PropertySearchPage(
        properties: normalized,
        total: total,
      );
    } on RequestCancelledException {
      rethrow; // keep the type — callers swallow cancellations silently
    } catch (e) {
      throw ServerException.msg(e.toString());
    }
  }

  /// Reads the all-pages match total from a property-search response wrapper,
  /// checking `totalCount`/`total` at the root, inside `pagination`, and under
  /// a `data` envelope. Returns null when no total is present.
  int? _extractTotal(dynamic response) {
    dynamic totalIn(Map root) {
      final direct = root['totalCount'] ?? root['total'];
      if (direct != null) return direct;
      final pagination = root['pagination'];
      if (pagination is Map) {
        return pagination['total'] ?? pagination['totalCount'];
      }
      return null;
    }

    if (response is! Map) return null;
    var candidate = totalIn(response);
    if (candidate == null && response['data'] is Map) {
      candidate = totalIn(response['data'] as Map);
    }
    if (candidate is int) return candidate;
    return int.tryParse(candidate?.toString() ?? '');
  }

  /// Calls property-search with `isSorted=true` and returns a paginated set
  /// of city groups (each carrying its own `regionId` so callers can pass it
  /// back on follow-up requests). The backend returns:
  /// `{ propertiesByCountry: [{ regionId, name, nameAr, totalCount,
  ///    properties: [...] }], pagination: { hasMore, total, ... } }`.
  ///
  /// Like [searchProperties], no `userId` is sent — see that method for why the
  /// home rails must stay on public pricing.
  Future<GroupedPropertiesPage> searchPropertiesGrouped(
    PropertySearchParams params, {
    CancelToken? cancelToken,
  }) async {
    final query = params.toQueryParams();
    query['isSorted'] = 'true';

    try {
      final response = await _api.get(
        EndPoints.propertySearch,
        queryParameters: query,
        cancelToken: cancelToken,
      );
      return _parseGroupedPage(response);
    } on RequestCancelledException {
      rethrow;
    } catch (e) {
      throw ServerException.msg(e.toString());
    }
  }

  GroupedPropertiesPage _parseGroupedPage(dynamic response) {
    Map<String, dynamic>? root;
    if (response is Map<String, dynamic>) {
      root = response;
      if (root['data'] is Map<String, dynamic> &&
          (root['propertiesByCountry'] == null)) {
        root = root['data'] as Map<String, dynamic>;
      }
    }

    final listRaw = root?['propertiesByCountry'];
    final groups = <CityPropertyGroup>[];
    if (listRaw is List) {
      for (final entry in listRaw) {
        if (entry is! Map) continue;
        final props = entry['properties'];
        if (props is! List) continue;
        final regionIdRaw = entry['regionId'] ?? entry['cityId'];
        final regionId = regionIdRaw is int
            ? regionIdRaw
            : (regionIdRaw is String ? int.tryParse(regionIdRaw) : null);
        final name = (entry['name'] ?? entry['city'] ?? entry['state'] ?? '')
            .toString()
            .trim();
        if (name.isEmpty) continue;
        groups.add(
          CityPropertyGroup(
            regionId: regionId,
            name: name,
            nameAr: entry['nameAr']?.toString(),
            totalCount: entry['totalCount'] is int
                ? entry['totalCount'] as int
                : int.tryParse(entry['totalCount']?.toString() ?? ''),
            properties: props.whereType<Map<String, dynamic>>().toList(),
          ),
        );
      }
    }

    final pagination = root?['pagination'];
    bool hasMore = false;
    int total = 0;
    int totalGroups = groups.length;
    if (pagination is Map) {
      hasMore = pagination['hasMore'] == true;
      total = pagination['total'] is int
          ? pagination['total'] as int
          : int.tryParse(pagination['total']?.toString() ?? '') ?? 0;
      totalGroups = pagination['totalGroups'] is int
          ? pagination['totalGroups'] as int
          : groups.length;
    }
    if (total == 0 && root?['totalCount'] is int) {
      total = root!['totalCount'] as int;
    }

    return GroupedPropertiesPage(
      groups: groups,
      hasMore: hasMore,
      total: total,
      totalGroups: totalGroups,
    );
  }

  /// Flat listing fetch used only by the Discover screen, which reads the
  /// per-row `isFavourited` flag that `userId` unlocks. Passing a user id also
  /// switches the endpoint to personalized pricing (see [searchProperties]) —
  /// don't reuse this for any guest-facing price surface.
  Future<List<PropertyModel>> getProperties({
    String? location,
    String? checkIn,
    String? checkOut,
    int? guests,
    int page = 1,
    int limit = 20,
    String? userId,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (location != null && location.isNotEmpty) 'location': location,
      if (checkIn != null && checkIn.isNotEmpty) 'checkin': checkIn,
      if (checkOut != null && checkOut.isNotEmpty) 'checkout': checkOut,
      if (guests != null) 'guests': guests,
      if (userId != null) 'userId': userId,
    };

    try {
      final response = await _api.get(
        EndPoints.propertySearch,
        queryParameters: query,
      );
      return _parsePropertyList(response);
    } catch (e) {
      throw ServerException.msg(e.toString());
    }
  }

  /// Loads one listing for the details screen.
  ///
  /// No `userId` here either (see [searchProperties]): with one the endpoint
  /// answers with the personalized price — 3000 becomes 2400 for a signed-in
  /// guest — so the details page would price the same unit differently
  /// depending on whether anyone is signed in. The favourite state that used to
  /// ride along on this call (`isFavourited`) now comes from
  /// `FavoritesNotifier`, seeded from `/users/favorites`.
  Future<PropertyModel?> getPropertyById(
    String id, {
    String? checkIn,
    String? checkOut,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _api.get(
        EndPoints.propertyDetails(id),
        queryParameters: {
          'checkin': checkIn ?? DateTime.now().toIso8601String(),
          'checkout': checkOut ?? DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        },
        cancelToken: cancelToken,
      );
      final item = _parseItem(response);
      return item != null ? PropertyModel.fromJson(item) : null;
    } on RequestCancelledException {
      rethrow;
    } catch (e) {
      throw ServerException.msg(e.toString());
    }
  }

  /// Loads the available sort options from `/api/Lookups/PropertySorting`.
  /// The backend returns `[{ id, name }, ...]`; each id is what the search
  /// endpoint expects as the `sortBy` filter.
  Future<List<SortOption>> getSortingOptions() async {
    try {
      final response = await _lookups.getOrFetch(
        EndPoints.propertySortingLookup,
        () => _api.get(EndPoints.propertySortingLookup),
      );
      return _extractList(response)
          .map((m) {
            final id = (m['id'] ?? m['value'] ?? '').toString().trim();
            final name =
                (m['name'] ?? m['title'] ?? m['label'] ?? '').toString().trim();
            return SortOption(id: id, name: name);
          })
          .where((o) => o.id.isNotEmpty && o.name.isNotEmpty)
          .toList();
    } catch (e) {
      throw ServerException.msg(e.toString());
    }
  }

  /// Loads the destination regions from `/api/Lookups/RegionCategory`.
  /// The backend returns `{ success, data: [{ id, name, propertyCount, photo }] }`.
  /// Names localize via the `lang` QUERY param only — the `lang` header is
  /// ignored by this controller (verified against prod), so it is passed
  /// explicitly here. On the home the chosen id is sent to the search endpoint
  /// as `featuredRegionId` (in-place filter); on the Country tab it is sent to
  /// `region-villages` as `regionId` to list the region's villages.
  Future<List<RegionCategory>> getRegionCategories({bool force = false}) async {
    final lang = _lookups.activeLang;
    try {
      final response = await _lookups.getOrFetch(
        // lang is embedded in the cache key (on top of the cache's own locale
        // suffix) to bust older entries cached before the ?lang= fix, which
        // hold English names under the Arabic key.
        '${EndPoints.regionCategoryLookup}?lang=$lang',
        () => _api.get(
          EndPoints.regionCategoryLookup,
          queryParameters: {'lang': lang},
        ),
        force: force,
      );
      return _extractList(response)
          .map(RegionCategory.fromJson)
          .where((c) => c.id > 0 && c.name.isNotEmpty)
          .toList();
    } catch (e) {
      throw ServerException.msg(e.toString());
    }
  }

  /// Loads the countries from `/api/lookups/country` →
  /// `{ success, data: [{ id, name }] }`, localized via the `lang` query
  /// param. Sorted by id so the order is stable across locales (the backend
  /// orders alphabetically per language). Drives the Country tab's first level.
  Future<List<CountryOption>> getCountries({bool force = false}) async {
    final lang = _lookups.activeLang;
    try {
      final response = await _lookups.getOrFetch(
        '${EndPoints.countriesLookup}?lang=$lang',
        () => _api.get(
          EndPoints.countriesLookup,
          queryParameters: {'lang': lang},
        ),
        force: force,
      );
      return _extractList(response)
          .map(CountryOption.fromJson)
          .where((c) => c.id > 0 && c.name.isNotEmpty)
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));
    } catch (e) {
      throw ServerException.msg(e.toString());
    }
  }

  /// Loads the villages of a destination region from
  /// `GET /api/Lookups/region-villages?regionId={regionId}` →
  /// `{ success, data: [{ id, name, propertyCount }] }` (already ordered by
  /// property count desc). [regionId] is a RegionCategory id; each returned
  /// village id is what `/api/property-search` expects as `villageId`.
  Future<List<RegionVillage>> getRegionVillages(
    int regionId, {
    bool force = false,
  }) async {
    final lang = _lookups.activeLang;
    try {
      final response = await _lookups.getOrFetch(
        '${EndPoints.regionVillagesLookup}?regionId=$regionId&lang=$lang',
        () => _api.get(
          EndPoints.regionVillagesLookup,
          queryParameters: {'regionId': regionId, 'lang': lang},
        ),
        force: force,
      );
      return _extractList(response)
          .map(RegionVillage.fromJson)
          .where((v) => v.id > 0 && v.name.isNotEmpty)
          .toList();
    } catch (e) {
      throw ServerException.msg(e.toString());
    }
  }

  Future<List<ReviewModel>> getRatings(String propertyId) async {
    try {
      final response = await _api.get(EndPoints.propertyRatings(propertyId));
      return _parseReviewList(response);
    } catch (e) {
      throw ServerException.msg(e.toString());
    }
  }

  Future<List<ReviewModel>> getRatingsPaginated(
    String propertyId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _api.get(
        EndPoints.propertyRatings(propertyId),
        queryParameters: {'page': page, 'limit': limit},
      );
      return _parseReviewList(response);
    } catch (e) {
      throw ServerException.msg(e.toString());
    }
  }

  Future<Map<String, dynamic>?> getAvailability(
    String propertyId, {
    String? checkIn,
    String? checkOut,
  }) async {
    try {
      final response = await _api.get(
        EndPoints.propertyAvailability(propertyId),
        queryParameters: {
          'checkin': checkIn ?? DateTime.now().toIso8601String(),
          'checkout': checkOut ?? DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        },
      );
      return _parseItem(response);
    } catch (e) {
      throw ServerException.msg(e.toString());
    }
  }

  Future<NightlyPricesPage> getNightlyPrices(
    String propertyId, {
    int page = 1,
  }) async {
    try {
      final response = await _api.get(
        EndPoints.propertyNightlyPrices(propertyId),
        queryParameters: {'page': page},
      );
      return NightlyPricesPage.fromJson(response);
    } catch (e) {
      throw ServerException.msg(e.toString());
    }
  }

  Future<Set<DateTime>> getBookedDates(String propertyId) async {
    try {
      final response =
          await _api.get(EndPoints.propertyBookedDates(propertyId));
      final map = response is Map<String, dynamic>
          ? response
          : <String, dynamic>{};
      final ranges = map['booked_Ranges'] ?? map['bookedRanges'] ?? map['data'];
      final result = <DateTime>{};
      if (ranges is List) {
        for (final entry in ranges) {
          if (entry is! Map) continue;
          final fromRaw = entry['from'] ?? entry['start'];
          final toRaw = entry['to'] ?? entry['end'] ?? fromRaw;
          if (fromRaw == null || toRaw == null) continue;
          final from = DateTime.tryParse(fromRaw.toString());
          final to = DateTime.tryParse(toRaw.toString());
          if (from == null || to == null) continue;
          final start = DateTime(from.year, from.month, from.day);
          final end = DateTime(to.year, to.month, to.day);
          var d = start;
          while (!d.isAfter(end)) {
            result.add(d);
            d = d.add(const Duration(days: 1));
          }
        }
      }
      return result;
    } catch (e) {
      throw ServerException.msg(e.toString());
    }
  }

  List<PropertyModel> _parsePropertyList(dynamic response) {
    final maps = _extractList(response);
    return maps.map(PropertyModel.fromJson).toList();
  }

  List<ReviewModel> _parseReviewList(dynamic response) {
    final maps = _extractList(response);
    return maps.map(ReviewModel.fromJson).toList();
  }

  List<Map<String, dynamic>> _extractList(dynamic response) {
    if (response == null) return [];
    dynamic raw = response;
    if (raw is Map) {
      raw = raw['data'] ?? raw['items'] ?? raw;
    }
    if (raw is Map) {
      final map = raw;
      // Property-search answers with a named `properties` array plus a parallel
      // `propertiesByCountry` grouping of the same rows. Read those names
      // explicitly: the "first list in the map" fallback below picks whichever
      // array the backend happens to serialise first, so any other array in the
      // payload turns a good page into a silent "No properties found".
      final named = map['items'] ?? map['data'] ?? map['properties'];
      final grouped = _flattenGroupedProperties(map['propertiesByCountry']);
      if (named is List && named.isNotEmpty) {
        raw = named;
      } else if (grouped.isNotEmpty) {
        raw = grouped;
      } else if (named is List) {
        raw = named; // genuinely empty result set
      } else {
        raw = map.values.firstWhere((v) => v is List, orElse: () => []);
      }
    }
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  /// Flattens `propertiesByCountry: [{ ..., properties: [...] }]` into one flat
  /// row list, so a grouped answer to a flat query still renders.
  List<Map<String, dynamic>> _flattenGroupedProperties(dynamic raw) {
    if (raw is! List) return const [];
    final rows = <Map<String, dynamic>>[];
    for (final group in raw) {
      if (group is! Map) continue;
      final props = group['properties'];
      if (props is List) rows.addAll(props.whereType<Map<String, dynamic>>());
    }
    return rows;
  }

  Map<String, dynamic>? _parseItem(dynamic response) {
    if (response == null) return null;
    if (response is Map<String, dynamic>) {
      return (response['data'] as Map<String, dynamic>?) ?? response;
    }
    return null;
  }
}
