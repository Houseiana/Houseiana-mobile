import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/properties/presentation/widgets/property_map_view.dart';
import 'package:houseiana_mobile_app/features/properties/presentation/widgets/property_sort_control.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:houseiana_mobile_app/shared/widgets/cards/property_list_card.dart';
import 'package:houseiana_mobile_app/shared/widgets/skeletons/list_skeleton.dart' show ListSkeletonLoader;

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({super.key});

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  bool _isMapView = false;
  final TextEditingController _searchController = TextEditingController();

  final _propertyService = sl<PropertyService>();
  final _userService = sl<UserService>();
  final _session = sl<UserSession>();
  final _scrollController = ScrollController();

  List<Map<String, dynamic>> _properties = [];
  Set<String> _favoriteIds = {};
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _pageLimit = 20;

  String? _filterLocation;
  double? _minPrice;
  double? _maxPrice;
  int? _minBedrooms;
  int? _beds;
  int? _minBathrooms;
  List<String>? _amenities;

  /// Selected sort option id (the `sortBy` value sent to the search API), or
  /// null for the default ordering. The pill + sheet live in
  /// [PropertySortControl]; this screen owns the value and re-queries.
  String? _sortBy;

  // Map viewport geo-filter (center + radius). Set when the user pans/zooms the
  // map; sent to the search API as `lat`/`lng`/`radiusKm`. Null = no geo scope.
  double? _lat;
  double? _lng;
  double? _radiusKm;

  /// True while a pan/zoom-triggered "search this area" request is in flight.
  /// Drives a lightweight pill on the map instead of the full-screen skeleton,
  /// so the map (and the user's camera position) is never torn down mid-search.
  bool _isAreaSearching = false;

  /// Monotonic stamp so a slow area search can't overwrite a newer one
  /// (rapid panning fires several; last-requested wins).
  int _areaSearchSeq = 0;

  /// True while a marker's preview card is shown on the map. Used to lift the
  /// bottom "List" toggle so it doesn't collide with the (taller) preview card.
  bool _hasMapSelection = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadData({String? location}) async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _hasMore = true;
      _filterLocation = location;
    });

    final props = await _propertyService.searchProperties(
      PropertySearchParams(
        location: location ?? _filterLocation,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minBedrooms: _minBedrooms,
        beds: _beds,
        minBathrooms: _minBathrooms,
        amenities: _amenities,
        sortBy: _sortBy,
        lat: _lat,
        lng: _lng,
        radiusKm: _radiusKm,
        page: 1,
        limit: _pageLimit,
      ),
      userId: _session.userId,
    );
    final propertyMaps = props.map((property) => property.toJson()).toList();

    Set<String> favIds = {};
    if (_session.isLoggedIn) {
      final favs = await _userService.getFavorites(_session.userId!);
      favIds = favs
          .map((f) => (f['propertyId'] ?? f['id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();
    }

    if (mounted) {
      setState(() {
        _properties = propertyMaps;
        _favoriteIds = favIds;
        _isLoading = false;
        _hasMore = props.length >= _pageLimit;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    final nextPage = _currentPage + 1;
    final more = await _propertyService.searchProperties(
      PropertySearchParams(
        location: _filterLocation,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minBedrooms: _minBedrooms,
        beds: _beds,
        minBathrooms: _minBathrooms,
        amenities: _amenities,
        sortBy: _sortBy,
        lat: _lat,
        lng: _lng,
        radiusKm: _radiusKm,
        page: nextPage,
        limit: _pageLimit,
      ),
      userId: _session.userId,
    );
    final moreMaps = more.map((property) => property.toJson()).toList();

    if (mounted) {
      setState(() {
        if (more.isEmpty) {
          _hasMore = false;
        } else {
          _properties.addAll(moreMaps);
          _currentPage = nextPage;
          _hasMore = more.length >= _pageLimit;
        }
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _toggleFavorite(String propertyId) async {
    if (!_session.isLoggedIn) {
      Navigator.pushNamed(context, Routes.login);
      return;
    }
    final isFav = _favoriteIds.contains(propertyId);
    setState(() {
      if (isFav) {
        _favoriteIds.remove(propertyId);
      } else {
        _favoriteIds.add(propertyId);
      }
    });
    await _userService.toggleFavorite(
      userId: _session.userId!,
      propertyId: propertyId,
    );
  }

  String _extractImage(Map<String, dynamic> p) {
    final photos = p['images'] ?? p['photos'] ?? p['coverPhoto'];
    if (photos is List && photos.isNotEmpty) {
      final first = photos.first;
      if (first is String) return first;
      if (first is Map) return (first['url'] ?? first['photoUrl'] ?? '').toString();
    }
    if (photos is String && photos.isNotEmpty) return photos;
    return '';
  }

  String _extractTitle(Map<String, dynamic> p) =>
      (p['title'] ?? p['name'] ?? context.tr('property.untitled')).toString();

  String _extractLocation(Map<String, dynamic> p) {
    final addr = p['address'];
    if (addr is Map) {
      final city = addr['city'] ?? '';
      final country = addr['country'] ?? '';
      if (city.isNotEmpty && country.isNotEmpty) return '$city, $country';
      if (city.isNotEmpty) return city;
      if (country.isNotEmpty) return country;
    }
    return (p['location'] ?? '').toString();
  }

  double _extractPrice(Map<String, dynamic> p) {
    final price = p['pricePerNight'] ?? p['price'] ?? p['basePrice'] ?? 0;
    if (price is num) return price.toDouble();
    return double.tryParse(price.toString()) ?? 0;
  }

  String _extractCurrency(Map<String, dynamic> p) {
    final currency = p['currency'];
    if (currency is String && currency.isNotEmpty) return currency;
    return '';
  }

  double _extractRating(Map<String, dynamic> p) {
    final r = p['rating'] ?? p['averageRating'] ?? 0;
    if (r is num) return r.toDouble();
    return double.tryParse(r.toString()) ?? 0;
  }

  String _extractId(Map<String, dynamic> p) =>
      (p['id'] ?? p['_id'] ?? p['propertyId'] ?? '').toString();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: _isLoading
                  ? const ListSkeletonLoader(showSearchBar: false, showCategories: false)
                  // Map view wins over the empty state: panning to a region with
                  // no listings must keep the map on-screen so the user can pan
                  // back out (the map shows its own "no properties here" hint).
                  : _isMapView
                      ? _buildMapView()
                      : _properties.isEmpty
                          ? _buildEmptyState()
                          : _buildListView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, Routes.searchModal)
                  .then((_) => _loadData()),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9FA),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 16, right: 8),
                      child: Icon(Icons.search, size: 18, color: Color(0xFF9CA3AF)),
                    ),
                    Expanded(
                      child: Text(
                        _filterLocation ?? context.tr('home.searchAnywhere'),
                        style: TextStyle(
                          fontSize: 14,
                          color: _filterLocation != null
                              ? const Color(0xFF1D242B)
                              : const Color(0xFF9CA3AF),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1D242B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.tune, size: 18, color: Colors.white),
              onPressed: _openAdvancedFilters,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAdvancedFilters() async {
    final result = await Navigator.pushNamed(context, Routes.advancedFilters);
    if (!mounted || result is! Map) return;

    setState(() {
      // Null = "no price filter" (slider at floor/ceiling), per the web
      // contract — the filters screen already applies that rule.
      final minPrice = result['minPrice'];
      _minPrice = minPrice is num ? minPrice.toDouble() : null;
      final maxPrice = result['maxPrice'];
      _maxPrice = maxPrice is num ? maxPrice.toDouble() : null;
      final bedrooms = result['bedrooms'];
      _minBedrooms = bedrooms is int && bedrooms > 0 ? bedrooms : null;
      final beds = result['beds'];
      _beds = beds is int && beds > 0 ? beds : null;
      final bathrooms = result['bathrooms'];
      _minBathrooms = bathrooms is int && bathrooms > 0 ? bathrooms : null;
      final amenities = result['amenities'];
      _amenities = amenities is List
          ? amenities.map((item) => item.toString()).toList()
          : null;
    });
    await _loadData(location: _filterLocation);
  }

  Future<void> _clearFilters() async {
    setState(() {
      _filterLocation = null;
      _minPrice = null;
      _maxPrice = null;
      _minBedrooms = null;
      _beds = null;
      _minBathrooms = null;
      _amenities = null;
      _lat = null;
      _lng = null;
      _radiusKm = null;
    });
    await _loadData(location: null);
  }

  /// Called (debounced by [PropertyMapView]) when the user pans/zooms the map.
  /// Stores the new viewport as a geo-filter and re-queries that area.
  void _onMapAreaChanged(double lat, double lng, double radiusKm) {
    _lat = lat;
    _lng = lng;
    _radiusKm = radiusKm;
    _searchThisArea();
  }

  /// Re-runs the search scoped to the current map viewport. Unlike [_loadData]
  /// it keeps the map mounted (no full-screen skeleton) and preserves the
  /// active text/filter selection, so panning only narrows results by area.
  Future<void> _searchThisArea() async {
    final seq = ++_areaSearchSeq;
    setState(() {
      _isAreaSearching = true;
      _currentPage = 1;
      _hasMore = true;
    });
    try {
      final props = await _propertyService.searchProperties(
        PropertySearchParams(
          location: _filterLocation,
          minPrice: _minPrice,
          maxPrice: _maxPrice,
          minBedrooms: _minBedrooms,
          beds: _beds,
          minBathrooms: _minBathrooms,
          amenities: _amenities,
          sortBy: _sortBy,
          lat: _lat,
          lng: _lng,
          radiusKm: _radiusKm,
          page: 1,
          limit: _pageLimit,
        ),
        userId: _session.userId,
      );
      // A newer area search started while this was in flight — drop this result.
      if (!mounted || seq != _areaSearchSeq) return;
      final maps = props.map((property) => property.toJson()).toList();
      setState(() {
        _properties = maps;
        _isAreaSearching = false;
        _hasMore = props.length >= _pageLimit;
      });
    } catch (_) {
      if (!mounted || seq != _areaSearchSeq) return;
      setState(() => _isAreaSearching = false);
    }
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        // Real, interactive map. Panning/zooming reports the viewport via
        // `onAreaChanged`, which re-queries the search API by `lat`/`lng`/
        // `radiusKm` — the same contract the web discover map uses.
        Positioned.fill(
          child: PropertyMapView(
            properties: _properties,
            onAreaChanged: _onMapAreaChanged,
            onSelectionChanged: (selected) =>
                setState(() => _hasMapSelection = selected),
          ),
        ),
        // Results-count / "searching this area" pill, floating at the top.
        Positioned(
          top: 12,
          left: 0,
          right: 0,
          child: Center(child: _buildMapStatusPill()),
        ),
        // Back-to-list toggle, floating at the bottom. Lifted above the marker
        // preview card while one is shown so the two don't overlap.
        Positioned(
          bottom: _hasMapSelection ? 150 : 16,
          left: 0,
          right: 0,
          child: Center(child: _buildToggleButton()),
        ),
      ],
    );
  }

  /// Floating pill over the map: shows the live result count, or a spinner
  /// while a pan/zoom-triggered area search is running.
  Widget _buildMapStatusPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isAreaSearching) ...[
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              context.tr('property.searchingArea'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D242B),
              ),
            ),
          ] else
            Text(
              context.tr('property.propertiesFound', args: {
                'count': '${_properties.length}${_hasMore ? '+' : ''}'
              }),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D242B),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primaryColor,
      child: _buildPropertiesList(),
    );
  }

  Widget _buildPropertiesList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  context.tr('property.propertiesFound', args: {'count': '${_properties.length}${_hasMore ? '+' : ''}'}),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D242B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PropertySortControl(
                    selectedId: _sortBy,
                    onChanged: (id) {
                      setState(() => _sortBy = id);
                      _loadData(location: _filterLocation);
                    },
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _isMapView = true),
                    child: Row(
                      children: [
                        const Icon(Icons.map_outlined, size: 14, color: AppColors.neutral600),
                        const SizedBox(width: 4),
                        Text(
                          context.tr('property.map'),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.neutral600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            controller: _isMapView ? null : _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: _properties.length + (_isLoadingMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              if (index == _properties.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primaryColor),
                  ),
                );
              }
              final p = _properties[index];
              final id = _extractId(p);
              return _buildPropertyCard(p, id);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyCard(Map<String, dynamic> p, String id) {
    return PropertyListCard(
      imageUrl: _extractImage(p),
      title: _extractTitle(p),
      location: _extractLocation(p),
      priceText: _extractPrice(p).toStringAsFixed(0),
      currency: _extractCurrency(p),
      rating: _extractRating(p),
      reviewCount: _extractCount(p, const ['reviewsCount', 'reviewCount']),
      bedrooms:
          _extractCount(p, const ['bedrooms', 'bedroomsCount', 'bedroomCount']),
      beds: _extractCount(p, const ['beds', 'bedsCount', 'bedCount']),
      bathrooms: _extractCount(p, const ['bathrooms', 'bathroomCount']),
      isGuestFavorite:
          (p['isGuestFavorite'] ?? p['guestFavorite'] ?? false) == true,
      isFavorite: _favoriteIds.contains(id),
      onTap: () => Navigator.pushNamed(
        context,
        Routes.propertyDetails,
        arguments: {'propertyId': id, 'property': p},
      ),
      onFavoriteToggle: () => _toggleFavorite(id),
    );
  }

  /// Reads the first non-empty count among [keys] (handles num and numeric
  /// strings), returning 0 when none are present.
  int _extractCount(Map<String, dynamic> p, List<String> keys) {
    for (final key in keys) {
      final value = p[key];
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return 0;
  }

  Widget _buildToggleButton() {
    return GestureDetector(
      onTap: () => setState(() {
        _isMapView = !_isMapView;
        // Leaving the map clears any pending preview-card selection state.
        _hasMapSelection = false;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          _isMapView ? context.tr('property.listView') : context.tr('property.map'),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D242B),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 80, color: AppColors.neutral400),
            const SizedBox(height: 24),
            Text(
              context.tr('property.noPropertiesFound'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('property.noPropertiesFoundDescription'),
              style: const TextStyle(fontSize: 14, color: AppColors.neutral600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _clearFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.charcoal,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(context.tr('property.clearFilters'), style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

