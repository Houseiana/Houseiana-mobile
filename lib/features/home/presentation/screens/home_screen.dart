import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/app_strings.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/bottom_nav/presentation/cubit/cubit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';
  Set<String> _favoriteProperties = {};

  List<Map<String, dynamic>> _properties = [];
  bool _isLoading = true;

  final _propertyService = sl<PropertyService>();
  final _userService = sl<UserService>();
  final _session = sl<UserSession>();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Load properties from backend
    final props = await _propertyService.getProperties(
      userId: _session.userId,
    );

    // If user is logged in, also load their favourites
    Set<String> favIds = {};
    if (_session.isLoggedIn) {
      final favs = await _userService.getFavorites(_session.userId!);
      favIds = favs
          .map((f) =>
              (f['propertyId'] ?? f['id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();
    }

    if (mounted) {
      setState(() {
        _properties = props;
        _favoriteProperties = favIds;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite(String propertyId) async {
    // Optimistic UI update
    setState(() {
      if (_favoriteProperties.contains(propertyId)) {
        _favoriteProperties.remove(propertyId);
      } else {
        _favoriteProperties.add(propertyId);
      }
    });

    // Sync with backend if logged in
    if (_session.isLoggedIn) {
      await _userService.toggleFavorite(
        userId: _session.userId!,
        propertyId: propertyId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildSearchBar(),
                const SizedBox(height: 20),
                _buildCategoryFilters(),
                const SizedBox(height: 20),
                _buildSectionHeader('', AppStrings.viewAll),
                const SizedBox(height: 12),
                _buildPropertyList(),
                const SizedBox(height: 32),
                _buildTrustBadges(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Logo and app name
        Row(
          children: [
            Image.asset(
              'assets/images/logo_icon.png',
              width: 28,
              height: 38,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Text(
              AppStrings.appName,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                height: 1.25,
                color: Color(0xFF1D242B),
              ),
            ),
          ],
        ),
        // Action buttons
        Row(
          children: [
            // List Your Home button
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, Routes.listProperty);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.bioYellow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'List Your Home',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: Color(0xFF1D242B),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildIconButton(Icons.notifications_none_outlined, () {
              Navigator.pushNamed(context, Routes.notifications);
            }),
            const SizedBox(width: 8),
            _buildIconButton(Icons.person_outline, () {
              if (_session.isLoggedIn) {
                context.read<BottomNavCubit>().changeIndex(4);
              } else {
                _showSignInPrompt();
              }
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9FA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          size: 18,
          color: const Color(0xFF6B7280),
        ),
      ),
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
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF9E6), shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline_rounded,
                  size: 38, color: Color(0xFFFCC519)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sign in to view your profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                  color: Color(0xFF1D242B)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Access your bookings, saved properties,\nand account settings by signing in.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, Routes.login);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFCC519),
                  foregroundColor: const Color(0xFF1D242B),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Sign In',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity, height: 50,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, Routes.signUp);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1D242B),
                  side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Create an Account',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSearch() {
    Navigator.pushNamed(context, Routes.searchModal);
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: _openSearch,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Where field
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(left: 16),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.where,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.25,
                        color: Color(0xFF000000),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Check-in field
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.checkIn,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 11,
                        height: 1.25,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Check-out field
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.checkOut,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 11,
                        height: 1.25,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Who field + search button
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(left: 10, right: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.who,
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 11,
                            height: 1.25,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.search,
                        size: 16,
                        color: Color(0xFF1D242B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final categories = [
      AppStrings.all,
      AppStrings.apartment,
      AppStrings.house,
      AppStrings.villa,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFEF9E7) : Colors.white,
                  border: Border.all(
                    color: isSelected ? AppColors.primaryColor : const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                    height: 1.23,
                    color: isSelected ? const Color(0xFF000000) : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String actionText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            height: 1.25,
            color: Color(0xFF1D242B),
          ),
        ),
        GestureDetector(
          onTap: () {
            context.read<BottomNavCubit>().changeIndex(1);
          },
          child: Text(
            actionText,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              height: 1.23,
              color: AppColors.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        ),
      );
    }

    if (_properties.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'No properties found.',
            style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < _properties.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          _buildPropertyCardFromData(_properties[i]),
        ],
      ],
    );
  }

  Widget _buildPropertyCardFromData(Map<String, dynamic> p) {
    // Map backend field names → display values
    final propertyId = (p['id'] ?? p['propertyId'] ?? '').toString();
    final title = (p['title'] ?? p['name'] ?? 'Property').toString();
    final location = _extractLocation(p);
    final price = _extractPrice(p);
    final rating = (p['rating'] ?? p['averageRating'] ?? p['ratingAverage'] ?? 0.0);
    final reviewCount = (p['reviewsCount'] ?? p['reviewCount'] ?? p['totalReviews'] ?? 0);
    final imageUrl = _extractImage(p);
    final isGuestFavorite = (p['isGuestFavorite'] ?? p['guestFavorite'] ?? false) == true;
    final discount = p['discountPercentage'] ?? p['discount'];

    return _buildPropertyCard(
      propertyId: propertyId.isEmpty ? title : propertyId,
      propertyData: p,
      imageUrl: imageUrl,
      badge: isGuestFavorite ? 'Guest Favorite' : null,
      rating: rating is num ? rating.toStringAsFixed(2) : rating.toString(),
      reviewCount: reviewCount.toString(),
      title: title,
      location: location,
      originalPrice: null,
      price: '\$$price',
      discount: discount != null && discount != 0 ? '-$discount%' : null,
    );
  }

  String _extractLocation(Map<String, dynamic> p) {
    if (p['city'] is Map) {
      final city = p['city'] as Map;
      final cityName = city['name'] ?? city['cityName'] ?? '';
      final country = p['country']?['name'] ?? '';
      return country.isNotEmpty ? '$cityName, $country' : cityName.toString();
    }
    return (p['location'] ?? p['city'] ?? p['address'] ?? 'Qatar').toString();
  }

  String _extractPrice(Map<String, dynamic> p) {
    final price = p['pricePerNight'] ?? p['price'] ?? p['basePrice'] ?? p['nightlyPrice'] ?? 0;
    return price.toString();
  }

  String _extractImage(Map<String, dynamic> p) {
    // Try common image field names
    final photos = p['photos'] ?? p['images'] ?? p['coverPhoto'];
    if (photos is List && photos.isNotEmpty) {
      final first = photos.first;
      if (first is String) return first;
      if (first is Map) return (first['url'] ?? first['photoUrl'] ?? '').toString();
    }
    if (photos is String) return photos;
    return '';
  }

  Widget _buildPropertyCard({
    required String propertyId,
    required Map<String, dynamic> propertyData,
    required String imageUrl,
    String? badge,
    required String rating,
    String? reviewCount,
    required String title,
    required String location,
    String? originalPrice,
    required String price,
    String? discount,
  }) {
    final isFavorite = _favoriteProperties.contains(propertyId);
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          Routes.propertyDetails,
          arguments: {'propertyId': propertyId, 'property': propertyData},
        );
      },
      child: Container(
        height: 309,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.00001),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Image
            Container(
              height: 200,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 200,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFE8E8E8), Color(0xFFD4D4D4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (badge != null)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D242B),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                            height: 1.2,
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
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: isFavorite ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ),
                  if (discount != null)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          discount,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                            height: 1.2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Property Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Color(0xFFFCC519)),
                      const SizedBox(width: 4),
                      Text(
                        rating,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          height: 1.25,
                          color: Color(0xFF000000),
                        ),
                      ),
                      if (reviewCount != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '($reviewCount reviews)',
                          style: const TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            height: 1.25,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      height: 1.27,
                      color: Color(0xFF1D242B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location,
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 11,
                      height: 1.27,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (originalPrice != null) ...[
                        Text(
                          originalPrice,
                          style: const TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                            height: 1.23,
                            color: Color(0xFF9CA3AF),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        price,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          height: 1.25,
                          color: Color(0xFF000000),
                        ),
                      ),
                      const Text(
                        '/night',
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                          height: 1.23,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustBadges() {
    final badges = [
      {'icon': Icons.credit_card, 'label': 'VISA'},
      {'icon': Icons.verified_outlined, 'label': 'Verified Host'},
      {'icon': Icons.lock_outline, 'label': '256-Bit Encryption'},
      {'icon': Icons.security_outlined, 'label': 'Secure SSL Payment'},
      {'icon': Icons.support_agent_outlined, 'label': '24/7 Support'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Safe & Secure',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF1D242B),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: badges.map((badge) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    badge['icon'] as IconData,
                    size: 22,
                    color: AppColors.charcoal,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    badge['label'] as String,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Text(
            '© 2026 Houseiana. All Rights Reserved.',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF9CA3AF),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
