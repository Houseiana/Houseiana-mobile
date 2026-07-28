import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/errors/exceptions.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/favorites_notifier.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/core/utils/discount_utils.dart';
import 'package:houseiana_mobile_app/features/properties/presentation/widgets/property_map_view.dart';
import 'package:houseiana_mobile_app/features/properties/presentation/widgets/property_sort_control.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:houseiana_mobile_app/shared/widgets/cards/property_list_card.dart';
import 'package:houseiana_mobile_app/shared/widgets/common/sign_in_prompt_sheet.dart';
import 'package:houseiana_mobile_app/shared/widgets/empty_state/empty_state_widget.dart';
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
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _pageLimit = 20;

  /// Backend-reported total across all pages (`totalCount` in the search
  /// response). Null when the response carries no total — the count label
  /// then falls back to the loaded length (+ "+" while more pages exist).
  int? _totalCount;

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

  /// Monotonic stamp of the CURRENT query (text/filters/sort/geo scope).
  /// [_loadData] and [_searchThisArea] bump it when they start a new query and
  /// drop their own response if a newer one started meanwhile; [_loadMore]
  /// captures it and drops its page if the query it belongs to was replaced
  /// while the request was in flight (last-requested query wins).
  int _querySeq = 0;

  /// Aborts the in-flight query when a newer one starts or the screen is
  /// disposed. [_querySeq] still guards ORDERING of responses; the token just
  /// stops wasted bandwidth/parsing on results that would be dropped anyway.
  CancelToken? _queryToken;

  CancelToken _nextQueryToken() {
    _queryToken?.cancel();
    return _queryToken = CancelToken();
  }

  /// True while a marker's preview card is shown on the map. Used to lift the
  /// bottom "List" toggle so it doesn't collide with the (taller) preview card.
  bool _hasMapSelection = false;

  /// Translation key describing why the last full load failed, or null when it
  /// succeeded. Without this a failed request (the backend cold start blows the
  /// receive timeout on the first call of a session) left the screen on its
  /// skeleton forever with no way back — now it shows a retry state.
  String? _loadErrorKey;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadData();
  }

  @override
  void dispose() {
    _queryToken?.cancel();
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
    final seq = ++_querySeq;
    setState(() {
      _isLoading = true;
      _loadErrorKey = null;
      _currentPage = 1;
      _hasMore = true;
      _filterLocation = location;
    });

    final PropertySearchPage searchPage;
    try {
      searchPage = await _propertyService.searchProperties(
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
        cancelToken: _nextQueryToken(),
      );
    } on RequestCancelledException {
      // Superseded by a newer query or the screen was disposed.
      return;
    } catch (e) {
      // Timeout / server error — surface a retry instead of an endless
      // skeleton (and never let the exception escape into the zone).
      if (!mounted || seq != _querySeq) return;
      setState(() {
        _isLoading = false;
        _loadErrorKey = loadErrorKeyFor(e);
      });
      // Previous results are still on screen (a failed refresh), and the error
      // state would hide them — report the failure in a snack bar instead.
      if (_properties.isNotEmpty) {
        _showErrorSnack(_loadErrorKey!,
            onRetry: () => _loadData(location: _filterLocation));
      }
      return;
    }
    // Already normalized maps (PropertyService runs the model round-trip,
    // off the UI isolate for big pages).
    final propertyMaps = searchPage.properties;

    final favIds = await _loadFavoriteIds();

    // A newer query started while this was in flight — drop this result.
    if (!mounted || seq != _querySeq) return;
    // Hearts read the app-wide notifier; this list is the user's FULL
    // favourites, so replace-seed it (null = the call failed, keep what we had).
    if (favIds != null) sl<FavoritesNotifier>().seed(favIds);
    setState(() {
      _properties = propertyMaps;
      _isLoading = false;
      _hasMore = propertyMaps.length >= _pageLimit;
      _totalCount = searchPage.total;
    });
  }

  /// The signed-in user's favourite ids, or null when they can't be fetched —
  /// a favourites hiccup must not take the listings down with it, and an empty
  /// set would wrongly clear every heart.
  Future<Set<String>?> _loadFavoriteIds() async {
    if (!_session.isLoggedIn) return null;
    try {
      final favs = await _userService.getFavorites(_session.userId!);
      return favs
          .map((f) => (f['propertyId'] ?? f['id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (_) {
      return null;
    }
  }

  void _showErrorSnack(String messageKey, {required VoidCallback onRetry}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.tr(messageKey)),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: context.tr('common.retry'),
            onPressed: onRetry,
          ),
        ),
      );
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    final seq = _querySeq;
    setState(() => _isLoadingMore = true);

    final nextPage = _currentPage + 1;
    final PropertySearchPage morePage;
    try {
      morePage = await _propertyService.searchProperties(
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
        // The CURRENT query's token: a new query cancels this stale page.
        cancelToken: _queryToken,
      );
    } on RequestCancelledException {
      if (mounted) setState(() => _isLoadingMore = false);
      return;
    } catch (e) {
      if (!mounted) return;
      // Keep `_hasMore` so scrolling again (or the snack bar's retry) picks the
      // same page up — only the loading flag is released.
      setState(() => _isLoadingMore = false);
      if (seq == _querySeq) {
        _showErrorSnack(loadErrorKeyFor(e), onRetry: _loadMore);
      }
      return;
    }
    if (!mounted) return;
    // The query this page belongs to was replaced while the request was in
    // flight — drop the page, but release the flag so the new list can paginate.
    if (seq != _querySeq) {
      setState(() => _isLoadingMore = false);
      return;
    }
    final moreMaps = morePage.properties;

    setState(() {
      if (moreMaps.isEmpty) {
        _hasMore = false;
      } else {
        _properties.addAll(moreMaps);
        _currentPage = nextPage;
        _hasMore = moreMaps.length >= _pageLimit;
      }
      if (morePage.total != null) {
        _totalCount = morePage.total;
      }
      _isLoadingMore = false;
    });
  }

  Future<void> _toggleFavorite(String propertyId) async {
    if (!_session.isLoggedIn) {
      showSignInToSaveFavoritesSheet(context);
      return;
    }
    // No setState: UserService flips the FavoritesNotifier optimistically
    // (and rolls back on failure), so only the tapped heart repaints.
    try {
      await _userService.toggleFavorite(
        userId: _session.userId!,
        propertyId: propertyId,
      );
    } catch (_) {
      // Rollback already handled by the notifier; nothing to show here.
    }
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
                  // A failed load with nothing to fall back on: offer a retry.
                  // (With results still on screen the failure went to a snack
                  // bar instead — see [_loadData].)
                  : _loadErrorKey != null && _properties.isEmpty
                      ? _buildErrorState()
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
    final seq = ++_querySeq;
    setState(() {
      _isAreaSearching = true;
      _currentPage = 1;
      _hasMore = true;
    });
    try {
      final searchPage = await _propertyService.searchProperties(
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
        cancelToken: _nextQueryToken(),
      );
      // A newer query started while this was in flight — drop this result.
      if (!mounted || seq != _querySeq) return;
      final maps = searchPage.properties;
      setState(() {
        _properties = maps;
        _isAreaSearching = false;
        _hasMore = maps.length >= _pageLimit;
        _totalCount = searchPage.total;
      });
    } catch (e) {
      // A newer pan already superseded this one (cancellations land here too):
      // stay quiet. Otherwise tell the user the area search failed instead of
      // silently dropping the spinner and leaving the old pins in place.
      if (!mounted || seq != _querySeq) return;
      setState(() => _isAreaSearching = false);
      _showErrorSnack(loadErrorKeyFor(e), onRetry: _searchThisArea);
    }
  }

  /// Count shown in the list header and map pill: the backend total when
  /// known, otherwise the loaded length with a "+" while more pages exist.
  String get _countLabel =>
      _totalCount?.toString() ?? '${_properties.length}${_hasMore ? '+' : ''}';

  /// Translation key matching [_countLabel]: singular only when the count is
  /// exactly 1 (known total of 1, or a single fully-loaded result).
  String get _countLabelKey {
    final isOne = _totalCount == 1 ||
        (_totalCount == null && _properties.length == 1 && !_hasMore);
    return isOne ? 'property.propertyFound' : 'property.propertiesFound';
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
              context.tr(_countLabelKey, args: {'count': _countLabel}),
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
                  context.tr(_countLabelKey, args: {'count': _countLabel}),
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
    final price = _extractPrice(p);
    final discountPct = effectiveDiscountPercent(p);
    final original = originalNightlyPrice(p);
    final showOriginal =
        discountPct > 0 && original != null && original > price;
    return PropertyListCard(
      imageUrl: _extractImage(p),
      title: _extractTitle(p),
      location: _extractLocation(p),
      priceText: price.toStringAsFixed(0),
      originalPriceText: showOriginal ? original.toStringAsFixed(0) : null,
      discountPercent: discountPct,
      currency: _extractCurrency(p),
      rating: _extractRating(p),
      reviewCount: _extractCount(p, const ['reviewsCount', 'reviewCount']),
      bedrooms:
          _extractCount(p, const ['bedrooms', 'bedroomsCount', 'bedroomCount']),
      beds: _extractCount(p, const ['beds', 'bedsCount', 'bedCount']),
      bathrooms: _extractCount(p, const ['bathrooms', 'bathroomCount']),
      isGuestFavorite:
          (p['isGuestFavorite'] ?? p['guestFavorite'] ?? false) == true,
      propertyId: id,
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

  /// Shown when a load failed and there is nothing to display. Pull-to-refresh
  /// works here too, so the user isn't forced onto the button.
  Widget _buildErrorState() {
    return RefreshIndicator(
      onRefresh: () => _loadData(location: _filterLocation),
      color: AppColors.primaryColor,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
          ErrorStateWidget(
            message: context.tr(_loadErrorKey!),
            onRetry: () => _loadData(location: _filterLocation),
          ),
        ],
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

