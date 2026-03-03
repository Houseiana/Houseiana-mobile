import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:url_launcher/url_launcher.dart';
import 'location_map_screen.dart';

class PropertyDetailsScreen extends StatefulWidget {
  const PropertyDetailsScreen({super.key});

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  int _selectedTab = 0;
  int _currentPage = 0;
  bool _isFavorite = false;
  late final PageController _pageController = PageController();
  bool _isLoading = true;
  bool _didInit = false;

  String? _propertyId;
  Map<String, dynamic> _property = {};
  List<Map<String, dynamic>> _ratings = [];
  double? _lat;
  double? _lng;

  final _propertyService = sl<PropertyService>();
  final _session = sl<UserSession>();

  final List<String> _tabs = ['Overview', 'Amenities', 'Reviews', 'Location'];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final passed = args['property'];
      if (passed is Map<String, dynamic>) _property = passed;
      final propertyId = args['propertyId']?.toString() ?? '';
      _propertyId = propertyId;
      if (propertyId.isNotEmpty) {
        _loadDetails(propertyId);
        return;
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadDetails(String propertyId) async {
    final detail = await _propertyService.getPropertyById(
      propertyId,
      userId: _session.userId,
    );
    final ratings = await _propertyService.getRatings(propertyId);
    if (mounted) {
      setState(() {
        if (detail != null) _property = detail;
        _ratings = ratings;
        _isLoading = false;
      });
      // Resolve coordinates after property data is set
      await _resolveCoordinates();
    }
  }

  Future<void> _resolveCoordinates() async {
    // 1. Try direct lat/lng from API response
    double? lat = (_property['latitude'] as num?)?.toDouble()
        ?? (_property['lat'] as num?)?.toDouble();
    double? lng = (_property['longitude'] as num?)?.toDouble()
        ?? (_property['lng'] as num?)?.toDouble();

    // 2. Fall back to geocoding the address string
    if ((lat == null || lng == null) && _location.isNotEmpty) {
      try {
        final locations = await locationFromAddress(_location);
        if (locations.isNotEmpty) {
          lat = locations.first.latitude;
          lng = locations.first.longitude;
        }
      } catch (_) {}
    }

    if (mounted && lat != null && lng != null) {
      setState(() {
        _lat = lat;
        _lng = lng;
      });
    }
  }

  // ── Data helpers ──────────────────────────────────────────────────────────

  String get _title =>
      (_property['title'] ?? _property['name'] ?? 'Property').toString();

  String get _description =>
      (_property['description'] ?? _property['about'] ?? '').toString();

  double get _price =>
      ((_property['pricePerNight'] ?? _property['price'] ?? _property['basePrice'] ?? 0) as num)
          .toDouble();

  double get _rating =>
      ((_property['rating'] ?? _property['averageRating'] ?? 0) as num).toDouble();

  int get _reviewCount =>
      ((_property['reviewsCount'] ?? _property['reviewCount'] ?? _property['totalReviews'] ?? 0) as num)
          .toInt();

  String get _location {
    if (_property['city'] is Map) {
      final city = _property['city'] as Map;
      final country = (_property['country'] as Map?)?['name'] ?? '';
      final cityName = city['name'] ?? city['cityName'] ?? '';
      return country.toString().isNotEmpty ? '$cityName, $country' : cityName.toString();
    }
    return (_property['location'] ?? _property['city'] ?? _property['address'] ?? '').toString();
  }

  List<String> get _photos {
    final photos = _property['photos'] ?? _property['images'];
    if (photos is List) {
      return photos.map<String>((p) {
        if (p is String) return p;
        if (p is Map) return (p['url'] ?? p['photoUrl'] ?? '').toString();
        return '';
      }).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }

  List<String> get _amenities {
    final ams = _property['amenities'];
    if (ams is List) {
      return ams.map<String>((a) {
        if (a is String) return a;
        if (a is Map) return (a['name'] ?? a['amenityName'] ?? '').toString();
        return '';
      }).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }

  int get _bedrooms =>
      ((_property['bedrooms'] ?? _property['bedroomCount'] ?? 0) as num).toInt();

  int get _bathrooms =>
      ((_property['bathrooms'] ?? _property['bathroomCount'] ?? 0) as num).toInt();

  int get _maxGuests =>
      ((_property['maxGuests'] ?? _property['guestCapacity'] ?? _property['capacity'] ?? 0) as num)
          .toInt();

  String get _hostName {
    final host = _property['host'];
    if (host is Map) return (host['name'] ?? host['firstName'] ?? '').toString();
    return (_property['hostName'] ?? _property['ownerName'] ?? '').toString();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPhotoHeader(context),
                    if (_photos.isNotEmpty) _buildThumbnailStrip(),
                    _buildTabBar(),
                    _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(
                              child: CircularProgressIndicator(color: Color(0xFFFCC519)),
                            ),
                          )
                        : _buildContent(),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoHeader(BuildContext context) {
    final photos = _photos;

    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          // ── Swipeable carousel ──────────────────────────────────────
          photos.isNotEmpty
              ? PageView.builder(
                  controller: _pageController,
                  physics: const ClampingScrollPhysics(),
                  itemCount: photos.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (_, i) => Image.network(
                    photos[i],
                    width: double.infinity,
                    height: 280,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _photoPlaceholder(),
                  ),
                )
              : _photoPlaceholder(),

          // Gradient overlay
          Container(
            height: 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.35), Colors.transparent],
              ),
            ),
          ),

          // ── Left arrow ─────────────────────────────────────────────
          if (photos.length > 1 && _currentPage > 0)
            Positioned(
              left: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_left,
                        color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),

          // ── Right arrow ────────────────────────────────────────────
          if (photos.length > 1 && _currentPage < photos.length - 1)
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_right,
                        color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),

          // Back button
          Positioned(
            left: 16,
            top: 16 + MediaQuery.of(context).padding.top,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back, size: 20, color: Color(0xFF1D242B)),
              ),
            ),
          ),

          // Share & Favorite
          Positioned(
            right: 16,
            top: 16 + MediaQuery.of(context).padding.top,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.share_outlined, size: 20, color: Color(0xFF1D242B)),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _isFavorite = !_isFavorite),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: _isFavorite ? Colors.red : const Color(0xFF1D242B),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Dot indicators (centered, bottom) ──────────────────────
          if (photos.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(photos.length, (i) {
                  final active = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: active ? Colors.white : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

          // Photo counter badge (top-right of bottom area)
          if (photos.isNotEmpty)
            Positioned(
              right: 16,
              bottom: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentPage + 1} / ${photos.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE5E5E5), Color(0xFFD0D0D0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.home_work_outlined, size: 64, color: Color(0xFFB0B0B0)),
      ),
    );
  }

  Widget _buildThumbnailStrip() {
    final photos = _photos;
    return Container(
      height: 68,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == _currentPage;
          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? const Color(0xFFFCC519) : const Color(0xFFE5E7EB),
                  width: isSelected ? 2.5 : 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  photos[index],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: const Color(0xFFD0D0D0)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isActive = index == _selectedTab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? const Color(0xFF1D242B) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  _tabs[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? const Color(0xFF1D242B) : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D242B),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.star, size: 14, color: Color(0xFFFCC519)),
              const SizedBox(width: 2),
              Text(
                _rating > 0 ? _rating.toStringAsFixed(2) : 'New',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D242B),
                ),
              ),
              if (_reviewCount > 0)
                Text(
                  ' · ($_reviewCount reviews) · ',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                )
              else
                const Text(' · ', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              const Icon(Icons.location_on, size: 13, color: Color(0xFF6B7280)),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  _location,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_selectedTab == 0) _buildOverviewTab(),
          if (_selectedTab == 1) _buildAmenitiesTab(),
          if (_selectedTab == 2) _buildReviewsTab(),
          if (_selectedTab == 3) _buildLocationTab(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── OVERVIEW ─────────────────────────────────────────────────────────────

  Widget _buildOverviewTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hostName.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9FA),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(Icons.person, size: 24, color: Color(0xFF1D242B)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Hosted by $_hostName',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D242B),
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (_description.isNotEmpty) ...[
          const Text(
            'About this place',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1D242B)),
          ),
          const SizedBox(height: 10),
          Text(
            _description,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.6),
          ),
          const SizedBox(height: 20),
        ],
        const Text(
          'Property Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1D242B)),
        ),
        const SizedBox(height: 12),
        if (_bedrooms == 0 && _bathrooms == 0 && _maxGuests == 0)
          const Text(
            'Details not available.',
            style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (_bedrooms > 0)
                _DetailChip(
                  icon: Icons.bed,
                  label: '$_bedrooms Bedroom${_bedrooms > 1 ? 's' : ''}',
                ),
              if (_bathrooms > 0)
                _DetailChip(
                  icon: Icons.bathtub_outlined,
                  label: '$_bathrooms Bathroom${_bathrooms > 1 ? 's' : ''}',
                ),
              if (_maxGuests > 0)
                _DetailChip(
                  icon: Icons.people_outline,
                  label: '$_maxGuests Guest${_maxGuests > 1 ? 's' : ''}',
                ),
            ],
          ),
      ],
    );
  }

  // ── AMENITIES ─────────────────────────────────────────────────────────────

  Widget _buildAmenitiesTab() {
    final amenities = _amenities;
    if (amenities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'No amenities listed.',
            style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: amenities
          .map(
            (name) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9FA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      size: 20,
                      color: Color(0xFF1D242B),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // ── REVIEWS ───────────────────────────────────────────────────────────────

  Widget _buildReviewsTab() {
    if (_ratings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'No reviews yet.',
            style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Text(
                    _rating > 0 ? _rating.toStringAsFixed(2) : '—',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1D242B),
                    ),
                  ),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        Icons.star,
                        size: 14,
                        color: i < _rating.round()
                            ? const Color(0xFFFCC519)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_reviewCount review${_reviewCount != 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ..._ratings.map((r) {
          final guestName =
              (r['guestName'] ?? r['userName'] ?? r['name'] ?? 'Guest').toString();
          final comment =
              (r['comment'] ?? r['review'] ?? r['text'] ?? '').toString();
          final ratingVal =
              ((r['rating'] ?? r['overallRating'] ?? 5) as num).toInt();
          final date = _formatDate(r['createdAt'] ?? r['date'] ?? '');
          return _buildReviewCard(
            name: guestName,
            date: date,
            rating: ratingVal,
            comment: comment,
          );
        }),
      ],
    );
  }

  Widget _buildReviewCard({
    required String name,
    required String date,
    required int rating,
    required String comment,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFF9F9FA),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'G',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D242B),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D242B),
                      ),
                    ),
                    if (date.isNotEmpty)
                      Text(
                        date,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                      ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  rating.clamp(0, 5),
                  (_) => const Icon(Icons.star, size: 12, color: Color(0xFFFCC519)),
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              comment,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── LOCATION ──────────────────────────────────────────────────────────────

  Widget _buildLocationTab() {
    final hasCoords = _lat != null && _lng != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Map thumbnail
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 200,
            child: hasCoords
                ? GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(_lat!, _lng!),
                      zoom: 14,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('property'),
                        position: LatLng(_lat!, _lng!),
                        infoWindow: InfoWindow(title: _title),
                      ),
                    },
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    scrollGesturesEnabled: false,
                    rotateGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                    onTap: (_) => _openFullMap(),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FE),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_searching,
                              size: 40, color: Color(0xFF9CA3AF)),
                          const SizedBox(height: 8),
                          Text(
                            _location.isNotEmpty
                                ? 'Loading map...'
                                : 'Location not available',
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF9CA3AF)),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 20),

        // Location text
        if (_location.isNotEmpty) ...[
          const Text(
            'Location',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D242B),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Color(0xFFFCC519)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _location,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Directions button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: hasCoords ? _openDirections : null,
              icon: const Icon(Icons.directions, size: 18),
              label: const Text('Get Directions'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1D242B),
                side: const BorderSide(color: Color(0xFF1D242B)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ] else
          const Text(
            'Location not available.',
            style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          ),
      ],
    );
  }

  void _onReserve() {
    if (!_session.isLoggedIn) {
      _showSignInPrompt();
      return;
    }
    Navigator.pushNamed(
      context,
      Routes.bookingRequest,
      arguments: {
        'propertyId': _propertyId,
        'property': _property,
        'price': _price,
        'title': _title,
      },
    );
  }

  void _showSignInPrompt() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF9E6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 32,
                color: Color(0xFFFCC519),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'Sign in to reserve',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D242B),
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            const Text(
              'You need to be signed in to make a reservation. Log in or create an account to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            // Sign in button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // close sheet
                  Navigator.pushNamed(
                    context,
                    Routes.login,
                    arguments: {
                      'redirectRoute': Routes.bookingRequest,
                      'redirectArguments': {
                        'propertyId': _propertyId,
                        'property': _property,
                        'price': _price,
                        'title': _title,
                      },
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFCC519),
                  foregroundColor: const Color(0xFF1D242B),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Create account button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context); // close sheet
                  Navigator.pushNamed(context, Routes.signUp);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1D242B),
                  side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Create an Account',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullMap() {
    if (_lat == null || _lng == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationMapScreen(
          propertyName: _title,
          address: _location,
          lat: _lat!,
          lng: _lng!,
        ),
      ),
    );
  }

  Future<void> _openDirections() async {
    if (_lat == null || _lng == null) return;
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$_lat,$_lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatDate(dynamic raw) {
    if (raw == null || raw.toString().isEmpty) return '';
    try {
      final dt = DateTime.parse(raw.toString());
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw.toString();
    }
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _price > 0 ? '\$${_price.toStringAsFixed(0)}' : '—',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D242B),
                ),
              ),
              const Text(
                '/night',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 128,
            height: 48,
            child: ElevatedButton(
              onPressed: _onReserve,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFCC519),
                foregroundColor: const Color(0xFF1D242B),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Reserve',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D242B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1D242B)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

