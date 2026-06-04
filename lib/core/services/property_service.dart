import 'package:houseiana_mobile_app/core/constants/errors/exceptions.dart';
import 'package:houseiana_mobile_app/core/models/nightly_price_model.dart';
import 'package:houseiana_mobile_app/core/models/property_model.dart';
import 'package:houseiana_mobile_app/core/models/review_model.dart';
import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/network/api/end_points.dart';

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
  final dynamic regionId;

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
    this.regionId,
  });

  Map<String, dynamic> toQueryParams() => {
        if (location != null && location!.isNotEmpty) 'location': location,
        if (checkIn != null && checkIn!.isNotEmpty) 'checkin': checkIn,
        if (checkOut != null && checkOut!.isNotEmpty) 'checkout': checkOut,
        if (guests != null) 'guests': guests,
        if (minPrice != null) 'minPrice': minPrice,
        if (maxPrice != null) 'maxPrice': maxPrice,
        if (amenities?.isNotEmpty == true) 'amenities': amenities!.join(','),
        if (propertyType != null) 'type': propertyType,
        if (minBedrooms != null) 'minBedrooms': minBedrooms,
        if (beds != null) 'beds': beds,
        if (minBathrooms != null) 'minBathrooms': minBathrooms,
        if (minRating != null) 'minRating': minRating,
        if (isSorted == true) 'isSorted': 'true',
        if (regionId != null) 'regionId': regionId,
        'page': page,
        'limit': limit,
      };
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

  PropertyService(this._api);

  Future<List<PropertyModel>> searchProperties(
    PropertySearchParams params, {
    String? userId,
  }) async {
    final query = params.toQueryParams();
    if (userId != null) {
      query['userId'] = userId;
    }

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

  /// Calls property-search with `isSorted=true` and returns a paginated set
  /// of city groups (each carrying its own `regionId` so callers can pass it
  /// back on follow-up requests). The backend returns:
  /// `{ propertiesByCountry: [{ regionId, name, nameAr, totalCount,
  ///    properties: [...] }], pagination: { hasMore, total, ... } }`.
  Future<GroupedPropertiesPage> searchPropertiesGrouped(
    PropertySearchParams params, {
    String? userId,
  }) async {
    final query = params.toQueryParams();
    query['isSorted'] = 'true';
    if (userId != null) {
      query['userId'] = userId;
    }

    try {
      final response = await _api.get(
        EndPoints.propertySearch,
        queryParameters: query,
      );
      return _parseGroupedPage(response);
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

  Future<PropertyModel?> getPropertyById(
    String id, {
    String? userId,
    String? checkIn,
    String? checkOut,
  }) async {
    try {
      final response = await _api.get(
        EndPoints.propertyDetails(id),
        queryParameters: {
          if (userId != null) 'userId': userId,
          'checkin': checkIn ?? DateTime.now().toIso8601String(),
          'checkout': checkOut ?? DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        },
      );
      final item = _parseItem(response);
      return item != null ? PropertyModel.fromJson(item) : null;
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
      raw = raw['items'] ??
          raw['data'] ??
          raw.values.firstWhere(
            (v) => v is List,
            orElse: () => [],
          );
    }
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  Map<String, dynamic>? _parseItem(dynamic response) {
    if (response == null) return null;
    if (response is Map<String, dynamic>) {
      return (response['data'] as Map<String, dynamic>?) ?? response;
    }
    return null;
  }
}
