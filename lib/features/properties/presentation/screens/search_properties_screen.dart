import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/features/properties/cubit/search_cubit.dart';
import 'package:houseiana_mobile_app/features/properties/cubit/search_state.dart';
import 'package:houseiana_mobile_app/features/properties/presentation/widgets/property_map_view.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class SearchPropertiesScreen extends StatefulWidget {
  const SearchPropertiesScreen({super.key});

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
  bool _mapView = false;

  /// Selected sort option id (the `sortBy` value sent to the search API), or
  /// null for the default ordering.
  String? _sortBy;

  /// Sort options shown in the sheet. Seeded with the known backend values so
  /// the control works immediately, then refreshed from
  /// `/api/Lookups/PropertySorting` (web parity).
  List<SortOption> _sortOptions = _fallbackSortOptions;

  /// Known PropertySorting lookup values — used as an offline/error fallback
  /// and to seed the control before the live lookup resolves.
  static const List<SortOption> _fallbackSortOptions = [
    SortOption(id: '1', name: 'Newest First'),
    SortOption(id: '2', name: 'Oldest First'),
    SortOption(id: '3', name: 'Price: High to Low'),
    SortOption(id: '4', name: 'Price: Low to High'),
    SortOption(id: '5', name: 'Highest Rated'),
    SortOption(id: '6', name: 'Most Booked'),
  ];

  /// Maps stable PropertySorting ids to localized labels; unknown ids fall
  /// back to the backend-provided name (see [_sortDisplayName]).
  static const Map<String, String> _sortLabelKeys = {
    '1': 'filters.sortNewest',
    '2': 'filters.sortOldest',
    '3': 'filters.sortPriceHighLow',
    '4': 'filters.sortPriceLowHigh',
    '5': 'filters.sortHighestRated',
    '6': 'filters.sortMostBooked',
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadSortOptions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readArgumentsAndSearch();
    });
  }

  Future<void> _loadSortOptions() async {
    try {
      final options = await sl<PropertyService>().getSortingOptions();
      if (!mounted || options.isEmpty) return;
      setState(() => _sortOptions = options);
    } catch (_) {
      // Keep the fallback options on failure.
    }
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
    }
    _doSearch();
  }

  void _doSearch() {
    // When opened from "See All" we already have a regionId — don't also send
    // `location` so the backend filters strictly by region.
    final locationParam = _regionId != null ? null : _location;
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
      backgroundColor: Colors.white,
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
                    return const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFFFCC519)),
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
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9FA),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Icon(Icons.arrow_back,
                  size: 18, color: Color(0xFF1D242B)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9FA),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.search,
                        size: 16, color: Color(0xFF6B7280)),
                    const SizedBox(width: 8),
                    Text(
                      _location.isNotEmpty ? _location : context.tr('home.anywhere'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1D242B),
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
                color: _mapView
                    ? const Color(0xFFFCC519)
                    : const Color(0xFFF9F9FA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Icon(
                _mapView ? Icons.list_alt : Icons.map_outlined,
                size: 18,
                color: const Color(0xFF1D242B),
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
                final priceRange = result['priceRange'] as RangeValues?;
                _minPrice = priceRange?.start;
                _maxPrice = priceRange?.end;
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
                color: const Color(0xFF1D242B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.tune, size: 18, color: Colors.white),
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

    final foundText = results.length == 1
        ? context.tr('property.propertyFoundShort', args: {'count': results.length})
        : context.tr('property.propertiesFoundShort', args: {'count': results.length});

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
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D242B),
                  ),
                ),
                if (parts.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    parts.join(' · '),
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildSortButton(),
        ],
      ),
    );
  }

  /// Localized label for a sort option: a translated label for known backend
  /// ids, falling back to the backend-provided name otherwise.
  String _sortDisplayName(SortOption option) {
    final key = _sortLabelKeys[option.id];
    return key != null ? context.tr(key) : option.name;
  }

  /// The compact "Sort by" pill shown in the results header (web parity).
  /// Highlights when a sort is active and shows the selected option's label.
  Widget _buildSortButton() {
    SortOption? selected;
    for (final option in _sortOptions) {
      if (option.id == _sortBy) {
        selected = option;
        break;
      }
    }
    final isActive = _sortBy != null;
    final label = selected != null
        ? _sortDisplayName(selected)
        : context.tr('filters.sortBy');

    return GestureDetector(
      onTap: _openSortSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFCC519) : const Color(0xFFF9F9FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_vert, size: 16, color: Color(0xFF1D242B)),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D242B),
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down,
                size: 16, color: Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }

  /// Bottom sheet listing the sort options plus a "default" entry that clears
  /// any active sort. Selecting an option re-runs the search with `sortBy`.
  void _openSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                child: Row(
                  children: [
                    Text(
                      context.tr('filters.sortBy'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D242B),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close,
                          size: 20, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              _buildSortTile(
                sheetContext,
                id: null,
                label: context.tr('filters.sortDefault'),
              ),
              ..._sortOptions.map(
                (option) => _buildSortTile(
                  sheetContext,
                  id: option.id,
                  label: _sortDisplayName(option),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortTile(
    BuildContext sheetContext, {
    required String? id,
    required String label,
  }) {
    final selected = _sortBy == id;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: const Color(0xFF1D242B),
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check, size: 20, color: Color(0xFFFCC519))
          : null,
      onTap: () {
        Navigator.pop(sheetContext);
        if (_sortBy != id) {
          setState(() => _sortBy = id);
          _doSearch();
        }
      },
    );
  }

  Widget _buildResultsList(
      SearchState state, List<Map<String, dynamic>> results) {
    final isLoadingMore = state is SearchLoadingMore;
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200) {
          context.read<SearchCubit>().loadMore();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () async {
          _doSearch();
        },
        color: const Color(0xFFFCC519),
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
                  child: CircularProgressIndicator(color: Color(0xFFFCC519)),
                ),
              );
            }
            return _buildPropertyCard(results[index]);
          },
        ),
      ),
    );
  }

  Widget _buildPropertyCard(Map<String, dynamic> p) {
    final propertyId = (p['id'] ?? p['_id'] ?? p['propertyId'] ?? '').toString();
    final title = (p['title'] ?? p['name'] ?? context.tr('property.untitled')).toString();
    final location = _extractLocation(p);
    final price = _extractPrice(p);
    final currency = _extractCurrency(p);
    final rating = (p['rating'] ?? p['averageRating'] ?? 0.0);
    final reviewCount = (p['reviewsCount'] ?? p['reviewCount'] ?? 0);
    final imageUrl = _extractImage(p);
    final bedrooms =
        _extractCount(p, const ['bedrooms', 'bedroomsCount', 'bedroomCount']);
    final beds = _extractCount(p, const ['beds', 'bedsCount', 'bedCount']);
    final bathrooms = _extractCount(p, const ['bathrooms', 'bathroomCount']);
    final isGuestFavorite =
        (p['isGuestFavorite'] ?? p['guestFavorite'] ?? false) == true;
    final isFav = (p['guestFavorite'] ?? p['isGuestFavorite'] ?? false) == true;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        Routes.propertyDetails,
        arguments: {'propertyId': propertyId, 'property': p},
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                  if (isGuestFavorite)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D242B),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          context.tr('home.guestFavorite'),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => context
                          .read<SearchCubit>()
                          .toggleFavorite(propertyId),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: isFav
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star,
                          size: 13, color: Color(0xFFFCC519)),
                      const SizedBox(width: 3),
                      Text(
                        rating is num && rating > 0
                            ? rating.toStringAsFixed(2)
                            : context.tr('property.newRating'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D242B),
                        ),
                      ),
                      if (reviewCount is num && reviewCount > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '($reviewCount)',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D242B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      location,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Unit specs (bedrooms · beds · bathrooms), mirroring the web
                  // listing card: icon + count only, each hidden when 0.
                  if (bedrooms > 0 || bathrooms > 0) ...[
                    const SizedBox(height: 6),
                    _buildUnitSpecs(bedrooms, beds, bathrooms),
                  ],
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D242B)),
                      children: [
                        TextSpan(
                          text: currency.isNotEmpty
                              ? '$price $currency '
                              : '$price ',
                        ),
                        TextSpan(
                          text: context.tr('home.perNight'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

  /// Compact bedrooms · beds · bathrooms row used on the search result card,
  /// matching the web listing card (icon + count, no labels).
  Widget _buildUnitSpecs(int bedrooms, int beds, int bathrooms) {
    return Row(
      children: [
        if (bedrooms > 0) _specItem(Icons.meeting_room_outlined, bedrooms),
        if (beds > 0) _specItem(Icons.bed_outlined, beds),
        if (bathrooms > 0) _specItem(Icons.bathtub_outlined, bathrooms),
      ],
    );
  }

  Widget _specItem(IconData icon, int value) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF1D242B)),
          const SizedBox(width: 3),
          Text(
            '$value',
            style: const TextStyle(fontSize: 12, color: Color(0xFF1D242B)),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 180,
      color: const Color(0xFFF3F4F6),
      child: const Center(
        child:
            Icon(Icons.home_work_outlined, size: 40, color: Color(0xFFD1D5DB)),
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
            const Icon(Icons.search_off_outlined,
                size: 64, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 16),
            Text(
              context.tr('property.noPropertiesFound'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D242B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('property.noPropertiesFoundDescription'),
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFCC519),
                foregroundColor: const Color(0xFF1D242B),
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
            const Icon(Icons.error_outline_outlined,
                size: 64, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 16),
            Text(
              context.tr('common.errorOccurred'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D242B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _doSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFCC519),
                foregroundColor: const Color(0xFF1D242B),
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
