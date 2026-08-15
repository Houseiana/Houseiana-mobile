import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/utils/money.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/core/utils/discount_utils.dart';
import 'package:houseiana_mobile_app/features/properties/cubit/search_cubit.dart';
import 'package:houseiana_mobile_app/features/properties/cubit/search_state.dart';
import 'package:houseiana_mobile_app/features/properties/presentation/widgets/property_map_view.dart';
import 'package:houseiana_mobile_app/features/properties/presentation/widgets/property_sort_control.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:houseiana_mobile_app/shared/widgets/cards/property_list_card.dart';
import 'package:houseiana_mobile_app/shared/widgets/common/sign_in_prompt_sheet.dart';
import 'package:houseiana_mobile_app/shared/widgets/skeletons/list_skeleton.dart';

class SearchPropertiesScreen extends StatefulWidget {
  SearchPropertiesScreen({super.key});

  @override
  State<SearchPropertiesScreen> createState() => _SearchPropertiesScreenState();
}

class _SearchPropertiesScreenState extends State<SearchPropertiesScreen> {
  final _scrollController = ScrollController();
  String _location = '';
  String? _checkIn;
  String? _checkOut;
  int _totalGuests = 0;
  double? _minPrice;
  double? _maxPrice;
  int? _minBedrooms;
  int? _beds;
  int? _minBathrooms;
  String? _propertyType;
  List<String>? _amenities;
  double? _minRating;
  dynamic _regionId;

  /// Village id from `/api/Lookups/region-villages`, sent to the search API
  /// as `villageId` (Country tab: village tap). Distinct id space from the
  /// RegionCategory region ids — the home "See All" passes `regionId` instead.
  dynamic _villageId;

  /// The region a [_villageId] belongs to (Country tab drill-down). Never sent
  /// with the village filter — it only backs the "search the whole region"
  /// escape hatch offered when the village itself has no stays.
  dynamic _parentRegionId;
  String _parentRegionName = '';

  bool _mapView = false;

  /// Selected sort option id (the `sortBy` value sent to the search API), or
  /// null for the default ordering. The pill + sheet live in
  /// [PropertySortControl]; this screen only owns the value and re-searches.
  String? _sortBy;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readArgumentsAndSearch();
    });
  }

  void _readArgumentsAndSearch() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _location = (args['location'] ?? '').toString();
      _checkIn = args['checkIn']?.toString();
      _checkOut = args['checkOut']?.toString();
      _totalGuests = (args['totalGuests'] ?? args['adults'] ?? 0) as int;
      if (args['minPrice'] != null) {
        _minPrice = (args['minPrice'] as num).toDouble();
      }
      if (args['maxPrice'] != null) {
        _maxPrice = (args['maxPrice'] as num).toDouble();
      }
      _minBedrooms = args['minBedrooms'] as int?;
      _minBathrooms = args['minBathrooms'] as int?;
      _propertyType = args['propertyType'] as String?;
      _amenities = (args['amenities'] as List?)?.cast<String>();
      if (args['minRating'] != null) {
        _minRating = (args['minRating'] as num).toDouble();
      }
      _regionId = args['regionId'];
      _villageId = args['villageId'];
      _parentRegionId = args['parentRegionId'];
      _parentRegionName = (args['parentRegionName'] ?? '').toString();
    }
    // The header sits outside the result BlocBuilders, so it renders once with
    // the initial (empty) values: without this rebuild the search bar read
    // "Anywhere" even when the results were scoped to one village — and an
    // empty page gave no clue what had actually been searched.
    if (mounted) setState(() {});
    _doSearch();
  }

  void _doSearch() {
    // When opened from "See All" we already have a region scope (regionId or
    // villageId) — don't also send `location` so the backend filters strictly
    // by region.
    final hasRegionScope = _regionId != null || _villageId != null;
    final locationParam = hasRegionScope ? null : _location;
    context.read<SearchCubit>().search(PropertySearchParams(
          location: locationParam,
          checkIn: _checkIn,
          checkOut: _checkOut,
          guests: _totalGuests > 0 ? _totalGuests : null,
          minPrice: _minPrice,
          maxPrice: _maxPrice,
          minBedrooms: _minBedrooms,
          beds: _beds,
          minBathrooms: _minBathrooms,
          propertyType: _propertyType,
          amenities: _amenities,
          minRating: _minRating,
          isSorted: false,
          sortBy: _sortBy,
          regionId: _regionId,
          villageId: _villageId is int
              ? _villageId as int
              : int.tryParse(_villageId?.toString() ?? ''),
        ));
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SearchCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _extractImage(Map<String, dynamic> p) {
    final photos = p['photos'] ?? p['images'] ?? p['coverPhoto'];
    if (photos is List && photos.isNotEmpty) {
      final first = photos.first;
      if (first is String) return first;
      if (first is Map) {
        return (first['url'] ?? first['photoUrl'] ?? '').toString();
      }
    }
    if (photos is String) return photos;
    return '';
  }

  String _extractLocation(Map<String, dynamic> p) {
    if (p['city'] is Map) {
      final city = p['city'] as Map;
      final country = (p['country'] as Map?)?['name'] ?? '';
      final cityName = city['name'] ?? city['cityName'] ?? '';
      return country.toString().isNotEmpty
          ? '$cityName, $country'
          : cityName.toString();
    }
    return (p['location'] ?? p['city'] ?? p['address'] ?? '').toString();
  }

  String _extractPrice(Map<String, dynamic> p) {
    final price = p['pricePerNight'] ?? p['price'] ?? p['basePrice'] ?? 0;
    return price.toString();
  }

  String _extractCurrency(Map<String, dynamic> p) {
    final currency = p['currency'];
    if (currency is String && currency.isNotEmpty) return currency;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            BlocBuilder<SearchCubit, SearchState>(
              builder: (context, state) {
                if (state is SearchLoaded || state is SearchLoadingMore) {
                  return _buildSearchSummary(state);
                }
                return const SizedBox.shrink();
              },
            ),
            Expanded(
              child: BlocBuilder<SearchCubit, SearchState>(
                builder: (context, state) {
                  if (state is SearchLoading) {
                    return ListSkeletonLoader(
                      showSearchBar: false,
                      showCategories: false,
                    );
                  }
                  if (state is SearchError) {
                    return _buildErrorState(state.message);
                  }
                  if (state is SearchLoaded || state is SearchLoadingMore) {
                    final results = state is SearchLoaded
                        ? state.properties
                        : (state as SearchLoadingMore).existing;
                    if (results.isEmpty) {
                      return _buildEmptyState();
                    }
                    if (_mapView) {
                      return PropertyMapView(properties: results);
                    }
                    return _buildResultsList(state, results);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.neutral200)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.ghostWhite,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.neutral200),
              ),
              child:
                  Icon(Icons.arrow_back, size: 18, color: AppColors.charcoal),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.ghostWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.neutral200),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(Icons.search, size: 16, color: AppColors.neutral500),
                    const SizedBox(width: 8),
                    Text(
                      _location.isNotEmpty
                          ? _location
                          : context.tr('home.anywhere'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.charcoal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => setState(() => _mapView = !_mapView),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _mapView ? AppColors.primaryColor : AppColors.ghostWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.neutral200),
              ),
              child: Icon(
                _mapView ? Icons.list_alt : Icons.map_outlined,
                size: 18,
                // Active state is the brand yellow in both themes.
                color: _mapView ? AppColors.brandCharcoal : AppColors.charcoal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              final result = await Navigator.pushNamed(
                context,
                Routes.advancedFilters,
              );
              if (result is Map) {
                // Null = "no price filter" (slider at floor/ceiling), per the
                // web contract — the filters screen already applies that rule.
                final minPrice = result['minPrice'];
                _minPrice = minPrice is num ? minPrice.toDouble() : null;
                final maxPrice = result['maxPrice'];
                _maxPrice = maxPrice is num ? maxPrice.toDouble() : null;
                final bedrooms = result['bedrooms'];
                _minBedrooms =
                    bedrooms is int && bedrooms > 0 ? bedrooms : null;
                final beds = result['beds'];
                _beds = beds is int && beds > 0 ? beds : null;
                final bathrooms = result['bathrooms'];
                _minBathrooms =
                    bathrooms is int && bathrooms > 0 ? bathrooms : null;
                _amenities = (result['amenities'] as List?)?.cast<String>();
                _doSearch();
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(Icons.tune, size: 18, color: AppColors.cardBackground),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSummary(SearchState state) {
    final results = state is SearchLoaded
        ? state.properties
        : (state as SearchLoadingMore).existing;
    // Backend-reported total across all pages; without it the count would be
    // just the loaded page size (e.g. "20 found" for a 133-match region).
    final total = state is SearchLoaded
        ? state.total
        : (state as SearchLoadingMore).total;
    final count = total ?? results.length;
    final parts = <String>[];
    final months = context.tr('common.monthsShort').split(',');
    if (_checkIn != null) {
      final dt = DateTime.tryParse(_checkIn!);
      if (dt != null) {
        parts.add('${months[dt.month - 1]} ${dt.day}');
      }
    }
    if (_checkOut != null) {
      final dt = DateTime.tryParse(_checkOut!);
      if (dt != null) {
        parts.add('${months[dt.month - 1]} ${dt.day}');
      }
    }
    if (_totalGuests > 0) {
      parts.add(_totalGuests == 1
          ? '$_totalGuests ${context.tr('booking.guest')}'
          : '$_totalGuests ${context.tr('booking.guests')}');
    }

    final foundText = count == 1
        ? context.tr('property.propertyFoundShort', args: {'count': count})
        : context.tr('property.propertiesFoundShort', args: {'count': count});

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  foundText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
                if (parts.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    parts.join(' · '),
                    style: TextStyle(fontSize: 12, color: AppColors.neutral500),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          PropertySortControl(
            selectedId: _sortBy,
            onChanged: (id) {
              setState(() => _sortBy = id);
              _doSearch();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(
      SearchState state, List<Map<String, dynamic>> results) {
    final isLoadingMore = state is SearchLoadingMore;
    // Pagination is driven by _onScroll (the controller listener) alone — a
    // NotificationListener here used to double-fire loadMore per scroll-end
    // and could be triggered by nested horizontal scrollables.
    return RefreshIndicator(
      onRefresh: () async {
        _doSearch();
      },
      color: AppColors.primaryColor,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        itemCount: results.length + (isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          if (index >= results.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.primaryColor),
              ),
            );
          }
          return _buildPropertyCard(results[index]);
        },
      ),
    );
  }

  Widget _buildPropertyCard(Map<String, dynamic> p) {
    final propertyId =
        (p['id'] ?? p['_id'] ?? p['propertyId'] ?? '').toString();
    final rating = (p['rating'] ?? p['averageRating'] ?? 0.0);
    final reviewCount = (p['reviewsCount'] ?? p['reviewCount'] ?? 0);
    final isGuestFavorite =
        (p['isGuestFavorite'] ?? p['guestFavorite'] ?? false) == true;
    final price = double.tryParse(_extractPrice(p)) ?? 0;
    final discountPct = effectiveDiscountPercent(p);
    final original = originalNightlyPrice(p);
    final showOriginal =
        discountPct > 0 && original != null && original > price;

    return PropertyListCard(
      imageUrl: _extractImage(p),
      title: (p['title'] ?? p['name'] ?? context.tr('property.untitled'))
          .toString(),
      location: _extractLocation(p),
      priceText: Money.amountOnly(price),
      originalPriceText: showOriginal ? Money.amountOnly(original) : null,
      discountPercent: discountPct,
      currency: _extractCurrency(p),
      rating: rating is num ? rating.toDouble() : 0,
      reviewCount: reviewCount is num ? reviewCount.toInt() : 0,
      bedrooms:
          _extractCount(p, const ['bedrooms', 'bedroomsCount', 'bedroomCount']),
      beds: _extractCount(p, const ['beds', 'bedsCount', 'bedCount']),
      bathrooms: _extractCount(p, const ['bathrooms', 'bathroomCount']),
      isGuestFavorite: isGuestFavorite,
      propertyId: propertyId,
      onTap: () => Navigator.pushNamed(
        context,
        Routes.propertyDetails,
        arguments: {'propertyId': propertyId, 'property': p},
      ),
      onFavoriteToggle: () {
        if (!sl<UserSession>().isLoggedIn) {
          showSignInToSaveFavoritesSheet(context);
          return;
        }
        context.read<SearchCubit>().toggleFavorite(propertyId);
      },
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

  Widget _buildEmptyState() {
    // Name what came back empty — a bare "No properties found" over a header
    // that says "Anywhere" reads like a failure rather than a result.
    final searched = _location.trim();
    final canWidenToRegion = _villageId != null &&
        _parentRegionId != null &&
        _parentRegionName.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_outlined,
                size: 64, color: AppColors.neutral300),
            const SizedBox(height: 16),
            Text(
              context.tr('property.noPropertiesFound'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              searched.isEmpty
                  ? context.tr('property.noPropertiesFoundDescription')
                  : context.tr('property.noPropertiesInPlace',
                      args: {'place': searched}),
              style: TextStyle(fontSize: 14, color: AppColors.neutral500),
              textAlign: TextAlign.center,
            ),
            if (canWidenToRegion) ...[
              const SizedBox(height: 4),
              TextButton(
                onPressed: () {
                  setState(() {
                    _villageId = null;
                    _regionId = _parentRegionId;
                    _location = _parentRegionName;
                  });
                  _doSearch();
                },
                child: Text(
                  context.tr('property.searchWholeRegion',
                      args: {'place': _parentRegionName}),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.brandCharcoal,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(context.tr('property.modifySearch'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_outlined,
                size: 64, color: AppColors.neutral300),
            const SizedBox(height: 16),
            Text(
              context.tr('common.errorOccurred'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: AppColors.neutral500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _doSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.brandCharcoal,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(context.tr('common.tryAgain'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
