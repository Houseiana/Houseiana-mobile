import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:houseiana_mobile_app/shared/widgets/skeletons/property_skeleton.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _userService = sl<UserService>();
  final _session = sl<UserSession>();

  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (!_session.isLoggedIn) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    final favs = await _userService.getFavorites(_session.userId!, limit: 50);
    if (mounted) {
      setState(() {
        _favorites = favs;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFavorite(String propertyId) async {
    setState(() {
      _favorites.removeWhere(
        (f) => (f['propertyId'] ?? f['id'] ?? '').toString() == propertyId,
      );
    });
    await _userService.toggleFavorite(
      userId: _session.userId!,
      propertyId: propertyId,
    );
  }

  String _extractImage(Map<String, dynamic> p) {
    final prop = p['property'] as Map<String, dynamic>? ?? p;
    final photos = prop['images'] ?? prop['photos'] ?? prop['coverPhoto'];
    if (photos is List && photos.isNotEmpty) {
      final first = photos.first;
      if (first is String) return first;
      if (first is Map) return (first['url'] ?? '').toString();
    }
    if (photos is String && photos.isNotEmpty) return photos;
    return '';
  }

  String _extractTitle(Map<String, dynamic> p) {
    final prop = p['property'] as Map<String, dynamic>? ?? p;
    return (prop['title'] ?? prop['name'] ?? context.tr('favorites.propertyFallback')).toString();
  }

  String _extractLocation(Map<String, dynamic> p) {
    final prop = p['property'] as Map<String, dynamic>? ?? p;
    final addr = prop['address'];
    if (addr is Map) {
      final city = addr['city'] ?? '';
      final country = addr['country'] ?? '';
      if (city.isNotEmpty && country.isNotEmpty) return '$city, $country';
      if (city.isNotEmpty) return city;
    }
    return (prop['location'] ?? '').toString();
  }

  double _extractPrice(Map<String, dynamic> p) {
    final prop = p['property'] as Map<String, dynamic>? ?? p;
    final price = prop['pricePerNight'] ?? prop['price'] ?? 0;
    if (price is num) return price.toDouble();
    return double.tryParse(price.toString()) ?? 0;
  }

  double _extractRating(Map<String, dynamic> p) {
    final prop = p['property'] as Map<String, dynamic>? ?? p;
    final r = prop['rating'] ?? prop['averageRating'] ?? 0;
    if (r is num) return r.toDouble();
    return double.tryParse(r.toString()) ?? 0;
  }

  String _extractPropertyId(Map<String, dynamic> f) =>
      (f['propertyId'] ?? f['id'] ?? '').toString();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          context.tr('favorites.title'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_session.isLoggedIn) {
      return _buildSignInPrompt();
    }
    if (_isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => const PropertySkeletonCard(),
      );
    }
    if (_favorites.isEmpty) {
      return _buildEmptyState();
    }
    return RefreshIndicator(
      onRefresh: _loadFavorites,
      color: AppColors.primaryColor,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _favorites.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _buildFavoriteCard(_favorites[index]);
        },
      ),
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> f) {
    final propertyId = _extractPropertyId(f);
    final imageUrl = _extractImage(f);
    final title = _extractTitle(f);
    final location = _extractLocation(f);
    final price = _extractPrice(f);
    final rating = _extractRating(f);
    final property = f['property'] as Map<String, dynamic>? ?? f;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        Routes.propertyDetails,
        arguments: {
          'propertyId':
              (property['id'] ?? property['_id'] ?? property['propertyId'] ?? '')
                  .toString(),
          'property': property,
        },
      ).then((_) => _loadFavorites()),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => _removeFavorite(propertyId),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (location.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        location,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.neutral600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 14, color: AppColors.primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            rating > 0
                                ? rating.toStringAsFixed(2)
                                : context.tr('favorites.newRating'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.charcoal,
                            ),
                          ),
                        ],
                      ),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.charcoal,
                          ),
                          children: [
                            TextSpan(text: '\$${price.toStringAsFixed(0)} '),
                            TextSpan(
                              text: context.tr('favorites.perNight'),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: AppColors.neutral600,
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
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 180,
      color: AppColors.ghostWhite,
      child: const Center(
        child: Icon(Icons.home_work_outlined,
            size: 50, color: AppColors.neutral400),
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 40,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('favorites.noFavorites'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('favorites.noFavoritesDescription'),
              style: const TextStyle(fontSize: 14, color: AppColors.neutral600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context, Routes.bottomNav, (r) => false),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.charcoal,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(context.tr('favorites.explorePropertiesAction'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline,
                  size: 40, color: AppColors.primaryColor),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('favorites.signInToView'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('favorites.signInToViewDescription'),
              style: const TextStyle(fontSize: 14, color: AppColors.neutral600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, Routes.login)
                    .then((_) => _loadFavorites()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.charcoal,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  context.tr('favorites.signIn'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
