import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';

class SearchPropertiesScreen extends StatefulWidget {
  const SearchPropertiesScreen({super.key});

  @override
  State<SearchPropertiesScreen> createState() => _SearchPropertiesScreenState();
}

class _SearchPropertiesScreenState extends State<SearchPropertiesScreen> {
  final _propertyService = sl<PropertyService>();
  final _userService = sl<UserService>();
  final _session = sl<UserSession>();

  List<Map<String, dynamic>> _results = [];
  bool _isLoading = true;
  bool _didInit = false;

  // Search params from route arguments
  String _location = '';
  String? _checkIn;
  String? _checkOut;
  int _totalGuests = 0;

  Set<String> _favorites = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _location = (args['location'] ?? '').toString();
      _checkIn = args['checkIn']?.toString();
      _checkOut = args['checkOut']?.toString();
      _totalGuests = (args['totalGuests'] ?? args['adults'] ?? 0) as int;
    }
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() => _isLoading = true);

    final props = await _propertyService.getProperties(
      location: _location.isNotEmpty ? _location : null,
      checkIn: _checkIn,
      checkOut: _checkOut,
      guests: _totalGuests > 0 ? _totalGuests : null,
      userId: _session.userId,
    );

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
        _results = props;
        _favorites = favIds;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite(String propertyId) async {
    setState(() {
      if (_favorites.contains(propertyId)) {
        _favorites.remove(propertyId);
      } else {
        _favorites.add(propertyId);
      }
    });
    if (_session.isLoggedIn) {
      await _userService.toggleFavorite(
        userId: _session.userId!,
        propertyId: propertyId,
      );
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _extractImage(Map<String, dynamic> p) {
    final photos = p['photos'] ?? p['images'] ?? p['coverPhoto'];
    if (photos is List && photos.isNotEmpty) {
      final first = photos.first;
      if (first is String) return first;
      if (first is Map) return (first['url'] ?? first['photoUrl'] ?? '').toString();
    }
    if (photos is String) return photos;
    return '';
  }

  String _extractLocation(Map<String, dynamic> p) {
    if (p['city'] is Map) {
      final city = p['city'] as Map;
      final country = (p['country'] as Map?)?['name'] ?? '';
      final cityName = city['name'] ?? city['cityName'] ?? '';
      return country.toString().isNotEmpty ? '$cityName, $country' : cityName.toString();
    }
    return (p['location'] ?? p['city'] ?? p['address'] ?? '').toString();
  }

  String _extractPrice(Map<String, dynamic> p) {
    final price = p['pricePerNight'] ?? p['price'] ?? p['basePrice'] ?? 0;
    return price.toString();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearchSummary(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFFFCC519)),
                    )
                  : _results.isEmpty
                      ? _buildEmptyState()
                      : _buildResultsList(),
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
              child: const Icon(Icons.arrow_back, size: 18, color: Color(0xFF1D242B)),
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
                    const Icon(Icons.search, size: 16, color: Color(0xFF6B7280)),
                    const SizedBox(width: 8),
                    Text(
                      _location.isNotEmpty ? _location : 'Anywhere',
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
            onTap: _loadResults,
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

  Widget _buildSearchSummary() {
    final parts = <String>[];
    if (_checkIn != null) {
      final dt = DateTime.tryParse(_checkIn!);
      if (dt != null) {
        const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        parts.add('${months[dt.month - 1]} ${dt.day}');
      }
    }
    if (_checkOut != null) {
      final dt = DateTime.tryParse(_checkOut!);
      if (dt != null) {
        const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        parts.add('${months[dt.month - 1]} ${dt.day}');
      }
    }
    if (_totalGuests > 0) parts.add('$_totalGuests guest${_totalGuests > 1 ? 's' : ''}');

    if (parts.isEmpty && _isLoading == false) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          if (!_isLoading)
            Text(
              '${_results.length} ${_results.length == 1 ? 'property' : 'properties'} found',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D242B),
              ),
            ),
          const Spacer(),
          if (parts.isNotEmpty)
            Text(
              parts.join(' · '),
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return RefreshIndicator(
      onRefresh: _loadResults,
      color: const Color(0xFFFCC519),
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _results.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) => _buildPropertyCard(_results[index]),
      ),
    );
  }

  Widget _buildPropertyCard(Map<String, dynamic> p) {
    final propertyId = (p['id'] ?? p['propertyId'] ?? '').toString();
    final title = (p['title'] ?? p['name'] ?? 'Property').toString();
    final location = _extractLocation(p);
    final price = _extractPrice(p);
    final rating = (p['rating'] ?? p['averageRating'] ?? 0.0);
    final reviewCount = (p['reviewsCount'] ?? p['reviewCount'] ?? 0);
    final imageUrl = _extractImage(p);
    final isGuestFavorite = (p['isGuestFavorite'] ?? p['guestFavorite'] ?? false) == true;
    final isFav = _favorites.contains(propertyId);

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
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D242B),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Guest Favorite',
                          style: TextStyle(
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
                      onTap: () => _toggleFavorite(propertyId),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: isFav ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, size: 13, color: Color(0xFFFCC519)),
                      const SizedBox(width: 3),
                      Text(
                        rating is num && rating > 0
                            ? (rating as num).toStringAsFixed(2)
                            : 'New',
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
                          style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
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
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1D242B)),
                      children: [
                        TextSpan(text: '\$$price '),
                        const TextSpan(
                          text: '/night',
                          style: TextStyle(
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

  Widget _imagePlaceholder() {
    return Container(
      height: 180,
      color: const Color(0xFFF3F4F6),
      child: const Center(
        child: Icon(Icons.home_work_outlined, size: 40, color: Color(0xFFD1D5DB)),
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
            const Icon(Icons.search_off_outlined, size: 64, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 16),
            const Text(
              'No properties found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D242B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your search or filters',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFCC519),
                foregroundColor: const Color(0xFF1D242B),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Modify Search', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
