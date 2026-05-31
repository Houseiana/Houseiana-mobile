import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
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
  int? _minBathrooms;
  String? _propertyType;
  List<String>? _amenities;
  double? _minRating;

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
        minBathrooms: _minBathrooms,
        propertyType: _propertyType,
        amenities: _amenities,
        minRating: _minRating,
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
        minBathrooms: _minBathrooms,
        propertyType: _propertyType,
        amenities: _amenities,
        minRating: _minRating,
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
                  : _properties.isEmpty
                      ? _buildEmptyState()
                      : _isMapView
                          ? _buildMapView()
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

    final range = result['priceRange'];
    setState(() {
      if (range is RangeValues) {
        _minPrice = range.start;
        _maxPrice = range.end;
      }
      final bedrooms = result['bedrooms'];
      _minBedrooms = bedrooms is int && bedrooms > 0 ? bedrooms : null;
      final bathrooms = result['bathrooms'];
      _minBathrooms = bathrooms is int && bathrooms > 0 ? bathrooms : null;
      _propertyType = result['propertyType']?.toString();
      final amenities = result['amenities'];
      _amenities = amenities is List
          ? amenities.map((item) => item.toString()).toList()
          : null;
      final rating = result['minRating'];
      _minRating = rating is num && rating > 0 ? rating.toDouble() : null;
    });
    await _loadData(location: _filterLocation);
  }

  Future<void> _clearFilters() async {
    setState(() {
      _filterLocation = null;
      _minPrice = null;
      _maxPrice = null;
      _minBedrooms = null;
      _minBathrooms = null;
      _propertyType = null;
      _amenities = null;
      _minRating = null;
    });
    await _loadData(location: null);
  }

  Widget _buildMapView() {
    return Column(
      children: [
        Container(
          height: 240,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE8F4F3), Color(0xFFD4EBE8)],
            ),
          ),
          child: Stack(
            children: [
              ..._properties.take(5).toList().asMap().entries.map((entry) {
                final idx = entry.key;
                final p = entry.value;
                final positions = [
                  const Offset(80, 60),
                  const Offset(160, 40),
                  const Offset(200, 120),
                  const Offset(60, 150),
                  const Offset(240, 80),
                ];
                final pos = positions[idx % positions.length];
                return _buildMapMarker(
                  top: pos.dy,
                  left: pos.dx,
                  price: _extractPrice(p).toInt(),
                  isFeatured: _favoriteIds.contains(_extractId(p)),
                );
              }),
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(child: _buildToggleButton()),
              ),
            ],
          ),
        ),
        Expanded(child: _buildPropertiesList()),
      ],
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
              Text(
                context.tr('property.propertiesFound', args: {'count': '${_properties.length}${_hasMore ? '+' : ''}'}),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D242B),
                ),
              ),
              if (!_isMapView)
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
        ),
        Expanded(
          child: ListView.separated(
            controller: _isMapView ? null : _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: _properties.length + (_isLoadingMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
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
    final isFav = _favoriteIds.contains(id);
    final imageUrl = _extractImage(p);
    final title = _extractTitle(p);
    final location = _extractLocation(p);
    final price = _extractPrice(p);
    final currency = _extractCurrency(p);
    final rating = _extractRating(p);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        Routes.propertyDetails,
        arguments: {'propertyId': id, 'property': p},
      ),
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 86,
                      height: 86,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isFav)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D242B),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        context.tr('home.guestFavorite'),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D242B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (location.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        location,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.neutral600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFCC519)),
                      const SizedBox(width: 3),
                      Text(
                        rating > 0 ? rating.toStringAsFixed(2) : context.tr('property.newRating'),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF1D242B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1D242B)),
                      children: [
                        TextSpan(
                          text: currency.isNotEmpty
                              ? '${price.toStringAsFixed(0)} $currency '
                              : '${price.toStringAsFixed(0)} ',
                        ),
                        TextSpan(
                          text: context.tr('home.perNight'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.neutral600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _toggleFavorite(id),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFav ? Colors.red : AppColors.neutral400,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        color: AppColors.ghostWhite,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.home_work_outlined, color: AppColors.neutral400, size: 30),
    );
  }

  Widget _buildMapMarker({
    required double top,
    required double left,
    required int price,
    bool isFeatured = false,
  }) {
    return Positioned(
      top: top,
      left: left,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isFeatured ? const Color(0xFF1D242B) : AppColors.primaryColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '\$$price',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isFeatured ? Colors.white : const Color(0xFF1D242B),
              ),
            ),
          ),
          CustomPaint(
            size: const Size(8, 8),
            painter: _TrianglePainter(
              color: isFeatured ? const Color(0xFF1D242B) : AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton() {
    return GestureDetector(
      onTap: () => setState(() => _isMapView = !_isMapView),
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

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
