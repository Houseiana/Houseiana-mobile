import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:url_launcher/url_launcher.dart';

import 'amenities_screen.dart';
import 'location_map_screen.dart';
import 'reviews_screen.dart';

class PropertyDetailsScreen extends StatefulWidget {
  const PropertyDetailsScreen({super.key});

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  int _currentPage = 0;
  bool _isFavorite = false;
  bool _descriptionExpanded = false;
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
      await _resolveCoordinates();
    }
  }

  Future<void> _resolveCoordinates() async {
    double? lat = (_property['latitude'] as num?)?.toDouble() ??
        (_property['lat'] as num?)?.toDouble();
    double? lng = (_property['longitude'] as num?)?.toDouble() ??
        (_property['lng'] as num?)?.toDouble();

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
      ((_property['pricePerNight'] ??
                  _property['price'] ??
                  _property['basePrice'] ??
                  0) as num)
          .toDouble();

  double get _rating =>
      ((_property['rating'] ?? _property['averageRating'] ?? 0) as num)
          .toDouble();

  int get _reviewCount =>
      ((_property['reviewsCount'] ??
                  _property['reviewCount'] ??
                  _property['totalReviews'] ??
                  0) as num)
          .toInt();

  String get _location {
    if (_property['city'] is Map) {
      final city = _property['city'] as Map;
      final country = (_property['country'] as Map?)?['name'] ?? '';
      final cityName = city['name'] ?? city['cityName'] ?? '';
      return country.toString().isNotEmpty
          ? '$cityName, $country'
          : cityName.toString();
    }
    return (_property['location'] ??
            _property['city'] ??
            _property['address'] ??
            '')
        .toString();
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
      ((_property['bedrooms'] ?? _property['bedroomCount'] ?? 0) as num)
          .toInt();

  int get _bathrooms =>
      ((_property['bathrooms'] ?? _property['bathroomCount'] ?? 0) as num)
          .toInt();

  int get _maxGuests =>
      ((_property['maxGuests'] ??
                  _property['guestCapacity'] ??
                  _property['capacity'] ??
                  0) as num)
          .toInt();

  String get _hostName {
    final host = _property['host'];
    if (host is Map) {
      return (host['name'] ?? host['firstName'] ?? '').toString();
    }
    return (_property['hostName'] ?? _property['ownerName'] ?? '').toString();
  }

  String get _hostAvatar {
    final host = _property['host'];
    if (host is Map) {
      return (host['avatar'] ??
              host['photo'] ??
              host['profilePicture'] ??
              '')
          .toString();
    }
    return '';
  }

  String get _propertyType =>
      (_property['propertyType'] ??
              _property['type'] ??
              _property['category'] ??
              '')
          .toString();

  String get _area {
    final area =
        _property['area'] ?? _property['size'] ?? _property['squareMeters'];
    if (area != null &&
        area.toString().isNotEmpty &&
        area.toString() != '0' &&
        area.toString() != '0.0') {
      return '${area}m\u00B2';
    }
    return '';
  }

  String get _checkInTime =>
      (_property['checkInTime'] ?? _property['checkIn'] ?? '').toString();

  String get _checkOutTime =>
      (_property['checkOutTime'] ?? _property['checkOut'] ?? '').toString();

  List<String> get _rules {
    final rules = _property['rules'] ?? _property['houseRules'];
    if (rules is List) {
      return rules
          .map((r) => r.toString())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (rules is String && rules.isNotEmpty) return [rules];
    return [];
  }

  String get _cancellationPolicy =>
      (_property['cancellationPolicy'] ??
              _property['cancelPolicy'] ??
              '')
          .toString();

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.bioYellow),
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPhotoHeader(context),
                          if (_photos.isNotEmpty) _buildThumbnailStrip(),
                          _buildPropertyInfo(),
                          const _SectionDivider(),
                          if (_hostName.isNotEmpty) ...[
                            _buildHostSection(),
                            const _SectionDivider(),
                          ],
                          if (_description.isNotEmpty) ...[
                            _buildAboutSection(),
                            const _SectionDivider(),
                          ],
                          if (_bedrooms > 0 ||
                              _bathrooms > 0 ||
                              _maxGuests > 0 ||
                              _area.isNotEmpty) ...[
                            _buildPropertyDetailsSection(),
                            const _SectionDivider(),
                          ],
                          if (_checkInTime.isNotEmpty ||
                              _checkOutTime.isNotEmpty) ...[
                            _buildCheckInSection(),
                            const _SectionDivider(),
                          ],
                          if (_amenities.isNotEmpty) ...[
                            _buildAmenitiesSection(),
                            const _SectionDivider(),
                          ],
                          if (_rules.isNotEmpty) ...[
                            _buildRulesSection(),
                            const _SectionDivider(),
                          ],
                          if (_cancellationPolicy.isNotEmpty) ...[
                            _buildCancellationSection(),
                            const _SectionDivider(),
                          ],
                          _buildLocationSection(),
                          if (_ratings.isNotEmpty || _reviewCount > 0) ...[
                            const _SectionDivider(),
                            _buildReviewsSection(),
                          ],
                          const SizedBox(height: 100),
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

  // ── Photo Carousel ────────────────────────────────────────────────────────

  Widget _buildPhotoHeader(BuildContext context) {
    final photos = _photos;

    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          // Swipeable carousel
          photos.isNotEmpty
              ? PageView.builder(
                  controller: _pageController,
                  physics: const ClampingScrollPhysics(),
                  itemCount: photos.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (_, i) => CachedNetworkImage(
                    imageUrl: photos[i],
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: AppColors.neutral100,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.bioYellow,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => _photoPlaceholder(),
                  ),
                )
              : _photoPlaceholder(),

          // Top gradient for status bar readability
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 100,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Left arrow
          if (photos.length > 1 && _currentPage > 0)
            Positioned(
              left: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: _CircleButton(
                  icon: Icons.chevron_left,
                  onTap: () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  backgroundColor: Colors.black.withOpacity(0.45),
                  iconColor: Colors.white,
                ),
              ),
            ),

          // Right arrow
          if (photos.length > 1 && _currentPage < photos.length - 1)
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: _CircleButton(
                  icon: Icons.chevron_right,
                  onTap: () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  backgroundColor: Colors.black.withOpacity(0.45),
                  iconColor: Colors.white,
                ),
              ),
            ),

          // Back button
          Positioned(
            left: 16,
            top: 12 + MediaQuery.of(context).padding.top,
            child: _CircleButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),
          ),

          // Share & Favorite
          Positioned(
            right: 16,
            top: 12 + MediaQuery.of(context).padding.top,
            child: Row(
              children: [
                _CircleButton(
                  icon: Icons.share_outlined,
                  onTap: () {},
                ),
                const SizedBox(width: 8),
                _CircleButton(
                  icon:
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                  iconColor:
                      _isFavorite ? Colors.red : AppColors.charcoal,
                  onTap: () =>
                      setState(() => _isFavorite = !_isFavorite),
                ),
              ],
            ),
          ),

          // Dot indicators
          if (photos.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  photos.length > 10 ? 10 : photos.length,
                  (i) {
                    final active = i == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 20 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Photo counter badge
          if (photos.isNotEmpty)
            Positioned(
              right: 16,
              bottom: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
      height: 300,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE5E5E5), Color(0xFFD0D0D0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child:
            Icon(Icons.home_work_outlined, size: 64, color: Color(0xFFB0B0B0)),
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
                  color: isSelected
                      ? AppColors.bioYellow
                      : AppColors.neutral200,
                  width: isSelected ? 2.5 : 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: photos[index],
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      Container(color: const Color(0xFFD0D0D0)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Property Info ─────────────────────────────────────────────────────────

  Widget _buildPropertyInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property type badge
          if (_propertyType.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9E6),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Text(
                  _propertyType,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
            ),

          // Title
          Text(
            _title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),

          // Rating + Reviews + Location row
          Row(
            children: [
              if (_rating > 0) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.bioYellow,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.white),
                      const SizedBox(width: 3),
                      Text(
                        _rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (_reviewCount > 0) ...[
                Text(
                  '$_reviewCount review${_reviewCount != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (_location.isNotEmpty) ...[
                const Text(
                  '\u00B7',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.location_on_outlined,
                    size: 15, color: Color(0xFF6B7280)),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    _location,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),

          // Quick stats
          if (_bedrooms > 0 || _bathrooms > 0 || _maxGuests > 0)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_bedrooms > 0) ...[
                      _QuickStat(
                        icon: Icons.bed_outlined,
                        label: '$_bedrooms Bed${_bedrooms > 1 ? 's' : ''}',
                      ),
                      const _StatDot(),
                    ],
                    if (_bathrooms > 0) ...[
                      _QuickStat(
                        icon: Icons.bathtub_outlined,
                        label:
                            '$_bathrooms Bath${_bathrooms > 1 ? 's' : ''}',
                      ),
                      const _StatDot(),
                    ],
                    if (_maxGuests > 0) ...[
                      _QuickStat(
                        icon: Icons.people_outline,
                        label:
                            '$_maxGuests Guest${_maxGuests > 1 ? 's' : ''}',
                      ),
                      if (_area.isNotEmpty) const _StatDot(),
                    ],
                    if (_area.isNotEmpty)
                      _QuickStat(
                        icon: Icons.square_foot,
                        label: _area,
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Host Section ──────────────────────────────────────────────────────────

  Widget _buildHostSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          final host = _property['host'];
          if (host is Map) {
            Navigator.pushNamed(context, Routes.hostProfile,
                arguments: {'host': host});
          }
        },
        child: Row(
          children: [
            // Host avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.ghostWhite,
                border: Border.all(color: AppColors.neutral200),
              ),
              child: _hostAvatar.isNotEmpty
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: _hostAvatar,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.person,
                          size: 26,
                          color: AppColors.charcoal,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      size: 26,
                      color: AppColors.charcoal,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hosted by $_hostName',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'View profile',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.neutral400),
          ],
        ),
      ),
    );
  }

  // ── About Section ─────────────────────────────────────────────────────────

  Widget _buildAboutSection() {
    const maxLines = 4;
    final showToggle = _description.length > 200;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About this place',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 10),
          AnimatedCrossFade(
            firstChild: Text(
              _description,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.6,
              ),
            ),
            secondChild: Text(
              _description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.6,
              ),
            ),
            crossFadeState: _descriptionExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
          if (showToggle)
            GestureDetector(
              onTap: () => setState(
                  () => _descriptionExpanded = !_descriptionExpanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _descriptionExpanded ? 'Show less' : 'Read more',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Property Details Section ──────────────────────────────────────────────

  Widget _buildPropertyDetailsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Property Details',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 14),
          _buildDetailRow(Icons.bed_outlined,
              '$_bedrooms Bedroom${_bedrooms > 1 ? 's' : ''}'),
          if (_bathrooms > 0)
            _buildDetailRow(Icons.bathtub_outlined,
                '$_bathrooms Bathroom${_bathrooms > 1 ? 's' : ''}'),
          if (_maxGuests > 0)
            _buildDetailRow(Icons.people_outline,
                'Up to $_maxGuests guest${_maxGuests > 1 ? 's' : ''}'),
          if (_area.isNotEmpty)
            _buildDetailRow(Icons.square_foot, 'Area: $_area'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.ghostWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Icon(icon, size: 20, color: AppColors.charcoal),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Check-in / Check-out Section ──────────────────────────────────────────

  Widget _buildCheckInSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Check-in Details',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (_checkInTime.isNotEmpty)
                Expanded(
                  child: _CheckInCard(
                    icon: Icons.login,
                    title: 'Check-in',
                    time: _checkInTime,
                  ),
                ),
              if (_checkInTime.isNotEmpty && _checkOutTime.isNotEmpty)
                const SizedBox(width: 12),
              if (_checkOutTime.isNotEmpty)
                Expanded(
                  child: _CheckInCard(
                    icon: Icons.logout,
                    title: 'Check-out',
                    time: _checkOutTime,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Amenities Section ─────────────────────────────────────────────────────

  Widget _buildAmenitiesSection() {
    final amenities = _amenities;
    final showAll = amenities.length <= 6;
    final displayed = showAll ? amenities : amenities.sublist(0, 6);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What this place offers',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 14),
          ...displayed.map(
            (name) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.ghostWhite,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _amenityIcon(name),
                      size: 20,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!showAll)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AmenitiesScreen(
                          categories: [
                            AmenityCategory(
                              title: 'All Amenities',
                              amenities: amenities
                                  .map((name) => Amenity(
                                        name: name,
                                        icon: _amenityIcon(name),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.charcoal,
                    side: const BorderSide(color: AppColors.charcoal),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Show all ${amenities.length} amenities',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── House Rules Section ───────────────────────────────────────────────────

  Widget _buildRulesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'House Rules',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 14),
          ..._rules.map(
            (rule) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      rule,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF374151),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Cancellation Policy Section ───────────────────────────────────────────

  Widget _buildCancellationSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cancellation Policy',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.policy_outlined,
                  size: 20,
                  color: Color(0xFFB45309),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _cancellationPolicy,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF92400E),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Location Section ──────────────────────────────────────────────────────

  Widget _buildLocationSection() {
    final hasCoords = _lat != null && _lng != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Location',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          if (_location.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on,
                    size: 16, color: AppColors.bioYellow),
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
          ],
          const SizedBox(height: 14),

          // Map
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
                                size: 40, color: AppColors.neutral400),
                            const SizedBox(height: 8),
                            Text(
                              _location.isNotEmpty
                                  ? 'Loading map...'
                                  : 'Location not available',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.neutral400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),

          // Directions button
          if (hasCoords)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openDirections,
                icon: const Icon(Icons.directions, size: 18),
                label: const Text('Get Directions'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.charcoal,
                  side: const BorderSide(color: AppColors.charcoal),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Reviews Section ───────────────────────────────────────────────────────

  Widget _buildReviewsSection() {
    final displayedReviews =
        _ratings.length > 3 ? _ratings.sublist(0, 3) : _ratings;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Reviews',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
              if (_ratings.length > 3)
                GestureDetector(
                  onTap: () => _openAllReviews(),
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Rating summary card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                // Big rating number
                Column(
                  children: [
                    Text(
                      _rating > 0 ? _rating.toStringAsFixed(1) : '--',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: AppColors.charcoal,
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          Icons.star,
                          size: 16,
                          color: i < _rating.round()
                              ? AppColors.bioYellow
                              : AppColors.neutral200,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_reviewCount review${_reviewCount != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Rating label
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.bioYellow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _ratingLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Review cards
          ...displayedReviews.map((r) {
            final guestName =
                (r['guestName'] ?? r['userName'] ?? r['name'] ?? 'Guest')
                    .toString();
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

          // Show all button
          if (_ratings.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _openAllReviews(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.charcoal,
                    side: const BorderSide(color: AppColors.charcoal),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Show all $_reviewCount reviews',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String get _ratingLabel {
    if (_rating >= 4.5) return 'Excellent';
    if (_rating >= 4.0) return 'Very Good';
    if (_rating >= 3.5) return 'Good';
    if (_rating >= 3.0) return 'Average';
    return 'Fair';
  }

  Widget _buildReviewCard({
    required String name,
    required String date,
    required int rating,
    required String comment,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.ghostWhite,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'G',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
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
                        color: AppColors.charcoal,
                      ),
                    ),
                    if (date.isNotEmpty)
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.neutral400,
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  rating.clamp(0, 5),
                  (_) => const Icon(Icons.star,
                      size: 12, color: AppColors.bioYellow),
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

  // ── Bottom Bar ────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.neutral200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _price > 0 ? '\$${_price.toStringAsFixed(0)}' : '--',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
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
            width: 140,
            height: 50,
            child: ElevatedButton(
              onPressed: _onReserve,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bioYellow,
                foregroundColor: AppColors.charcoal,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Reserve',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Navigation Helpers ────────────────────────────────────────────────────

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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
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
                color: AppColors.bioYellow,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sign in to reserve',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
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
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
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
                  backgroundColor: AppColors.bioYellow,
                  foregroundColor: AppColors.charcoal,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Sign In',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, Routes.signUp);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.charcoal,
                  side: const BorderSide(
                      color: AppColors.neutral200, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Create an Account',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAllReviews() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewsScreen(
          averageRating: _rating,
          totalReviews: _reviewCount,
          reviews: _ratings.map((r) {
            final guestName =
                (r['guestName'] ?? r['userName'] ?? r['name'] ?? 'Guest')
                    .toString();
            final comment =
                (r['comment'] ?? r['review'] ?? r['text'] ?? '').toString();
            final ratingVal =
                ((r['rating'] ?? r['overallRating'] ?? 5) as num).toDouble();
            final date = _formatDate(r['createdAt'] ?? r['date'] ?? '');
            return Review(
              reviewerName: guestName,
              rating: ratingVal,
              date: date,
              comment: comment,
            );
          }).toList(),
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
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw.toString();
    }
  }

  IconData _amenityIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('wifi') || lower.contains('internet')) {
      return Icons.wifi;
    }
    if (lower.contains('pool') || lower.contains('swimming')) {
      return Icons.pool;
    }
    if (lower.contains('parking')) return Icons.local_parking;
    if (lower.contains('kitchen')) return Icons.kitchen;
    if (lower.contains('tv') || lower.contains('television')) return Icons.tv;
    if (lower.contains('air') ||
        lower.contains('ac') ||
        lower.contains('conditioning')) {
      return Icons.ac_unit;
    }
    if (lower.contains('washer') ||
        lower.contains('laundry') ||
        lower.contains('washing')) {
      return Icons.local_laundry_service;
    }
    if (lower.contains('gym') || lower.contains('fitness')) {
      return Icons.fitness_center;
    }
    if (lower.contains('elevator') || lower.contains('lift')) {
      return Icons.elevator;
    }
    if (lower.contains('garden') || lower.contains('yard')) return Icons.yard;
    if (lower.contains('bbq') ||
        lower.contains('grill') ||
        lower.contains('barbecue')) {
      return Icons.outdoor_grill;
    }
    if (lower.contains('balcony') || lower.contains('terrace')) {
      return Icons.balcony;
    }
    if (lower.contains('heat') || lower.contains('heating')) {
      return Icons.whatshot;
    }
    if (lower.contains('security') || lower.contains('safe')) {
      return Icons.security;
    }
    if (lower.contains('iron')) return Icons.iron;
    if (lower.contains('coffee') || lower.contains('nespresso')) {
      return Icons.coffee;
    }
    if (lower.contains('jacuzzi') ||
        lower.contains('hot tub') ||
        lower.contains('sauna')) {
      return Icons.hot_tub;
    }
    if (lower.contains('smoke') || lower.contains('no smoking')) {
      return Icons.smoke_free;
    }
    if (lower.contains('pet')) return Icons.pets;
    if (lower.contains('breakfast') || lower.contains('food')) {
      return Icons.restaurant;
    }
    if (lower.contains('towel') ||
        lower.contains('linen') ||
        lower.contains('bedding')) {
      return Icons.dry_cleaning;
    }
    return Icons.check_circle_outline;
  }
}

// ── Reusable Widgets ──────────────────────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Divider(height: 1, color: AppColors.neutral200),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color iconColor;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.backgroundColor = Colors.white,
    this.iconColor = AppColors.charcoal,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuickStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StatDot extends StatelessWidget {
  const _StatDot();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '\u00B7',
        style: TextStyle(
          fontSize: 16,
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _CheckInCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;

  const _CheckInCard({
    required this.icon,
    required this.title,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.ghostWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: AppColors.charcoal),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
        ],
      ),
    );
  }
}
