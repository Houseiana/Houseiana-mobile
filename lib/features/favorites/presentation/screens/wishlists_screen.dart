import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:houseiana_mobile_app/shared/widgets/skeletons/property_skeleton.dart';

class WishlistsScreen extends StatefulWidget {
  const WishlistsScreen({super.key});

  @override
  State<WishlistsScreen> createState() => _WishlistsScreenState();
}

class _WishlistsScreenState extends State<WishlistsScreen> {
  final _userService = sl<UserService>();
  final _session = sl<UserSession>();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadSavedHomes();
  }

  Future<void> _loadSavedHomes() async {
    if (!_session.isLoggedIn) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final favorites = await _userService.getFavorites(
        _session.userId!,
        limit: 80,
      );
      if (!mounted) return;
      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFavorite(String propertyId) async {
    if (!_session.isLoggedIn || propertyId.isEmpty) return;

    final previous = List<Map<String, dynamic>>.from(_favorites);
    setState(() {
      _favorites.removeWhere((favorite) {
        return _extractPropertyId(favorite) == propertyId;
      });
    });

    try {
      await _userService.toggleFavorite(
        userId: _session.userId!,
        propertyId: propertyId,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _favorites = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Map<String, dynamic> _propertyOf(Map<String, dynamic> item) {
    return item['property'] is Map<String, dynamic>
        ? item['property'] as Map<String, dynamic>
        : item;
  }

  String _extractPropertyId(Map<String, dynamic> item) {
    final property = _propertyOf(item);
    return (item['propertyId'] ??
            property['_id'] ??
            property['id'] ??
            property['propertyId'] ??
            '')
        .toString();
  }

  String _extractImage(Map<String, dynamic> item) {
    final property = _propertyOf(item);
    final photos = property['images'] ?? property['photos'] ?? property['coverPhoto'];
    if (photos is List && photos.isNotEmpty) {
      final first = photos.first;
      if (first is String) return first;
      if (first is Map) return (first['url'] ?? first['photoUrl'] ?? '').toString();
    }
    if (photos is String) return photos;
    return '';
  }

  String _extractTitle(Map<String, dynamic> item) {
    final property = _propertyOf(item);
    return (property['title'] ??
            property['name'] ??
            context.tr('favorites.propertyFallback'))
        .toString();
  }

  String _extractLocation(Map<String, dynamic> item) {
    final property = _propertyOf(item);
    if (property['city'] is Map) {
      final city = (property['city']['name'] ?? property['city']['cityName'] ?? '')
          .toString();
      final country = property['country'] is Map
          ? (property['country']['name'] ?? '').toString()
          : '';
      if (city.isNotEmpty && country.isNotEmpty) return '$city, $country';
      if (city.isNotEmpty) return city;
    }
    final city = (property['city'] ?? '').toString();
    final location = (property['location'] ?? property['address'] ?? '').toString();
    return city.isNotEmpty ? city : location;
  }

  double _extractPrice(Map<String, dynamic> item) {
    final property = _propertyOf(item);
    final raw = property['pricePerNight'] ?? property['price'] ?? property['basePrice'];
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? 0;
  }

  double _extractRating(Map<String, dynamic> item) {
    final property = _propertyOf(item);
    final raw = property['averageRating'] ?? property['rating'] ?? property['avgRating'];
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('favorites.wishlists'),
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
      return _MessageState(
        icon: Icons.person_outline,
        title: context.tr('favorites.signInToViewWishlists'),
        message: context.tr('favorites.signInToViewWishlistsDescription'),
        actionLabel: context.tr('favorites.signIn'),
        onAction: () => Navigator.pushNamed(
          context,
          Routes.login,
          arguments: {'redirectRoute': Routes.wishlists},
        ).then((_) => _loadSavedHomes()),
      );
    }

    if (_isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.all(20),
        itemBuilder: (_, __) => const PropertySkeletonCard(),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: 4,
      );
    }

    if (_error != null) {
      return _MessageState(
        icon: Icons.error_outline,
        title: context.tr('favorites.unableToLoad'),
        message: _error!,
        actionLabel: context.tr('favorites.retry'),
        onAction: _loadSavedHomes,
      );
    }

    if (_favorites.isEmpty) {
      return _MessageState(
        icon: Icons.favorite_border,
        title: context.tr('favorites.noSavedHomes'),
        message: context.tr('favorites.noSavedHomesDescription'),
        actionLabel: context.tr('favorites.explorePropertiesAction'),
        onAction: () => Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.bottomNav,
          (_) => false,
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryColor,
      onRefresh: _loadSavedHomes,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _favorites.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _SavedHomeCard(
          favorite: _favorites[index],
          propertyId: _extractPropertyId(_favorites[index]),
          title: _extractTitle(_favorites[index]),
          location: _extractLocation(_favorites[index]),
          imageUrl: _extractImage(_favorites[index]),
          price: _extractPrice(_favorites[index]),
          rating: _extractRating(_favorites[index]),
          onRemove: _removeFavorite,
        ),
      ),
    );
  }
}

class _SavedHomeCard extends StatelessWidget {
  final Map<String, dynamic> favorite;
  final String propertyId;
  final String title;
  final String location;
  final String imageUrl;
  final double price;
  final double rating;
  final ValueChanged<String> onRemove;

  const _SavedHomeCard({
    required this.favorite,
    required this.propertyId,
    required this.title,
    required this.location,
    required this.imageUrl,
    required this.price,
    required this.rating,
    required this.onRemove,
  });

  Map<String, dynamic> get _property {
    return favorite['property'] is Map<String, dynamic>
        ? favorite['property'] as Map<String, dynamic>
        : favorite;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        Routes.propertyDetails,
        arguments: {
          'propertyId': propertyId,
          'property': _property,
        },
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.neutral200),
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
                          height: 190,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imageFallback(),
                        )
                      : _imageFallback(),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => onRemove(propertyId),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.red,
                        size: 21,
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
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      location,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.neutral600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 15,
                            color: AppColors.primaryColor,
                          ),
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
                      Text(
                        price > 0
                            ? '\$${price.toStringAsFixed(0)} ${context.tr('favorites.perNight')}'
                            : context.tr('favorites.viewDetailsShort'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.charcoal,
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

  Widget _imageFallback() {
    return Container(
      height: 190,
      width: double.infinity,
      color: AppColors.ghostWhite,
      child: const Icon(
        Icons.home_work_outlined,
        size: 46,
        color: AppColors.neutral400,
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.neutral400),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.neutral600,
                height: 1.45,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.charcoal,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
