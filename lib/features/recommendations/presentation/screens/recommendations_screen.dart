import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/models/property_model.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:houseiana_mobile_app/shared/widgets/cards/property_card_v2.dart';
import 'package:houseiana_mobile_app/shared/widgets/skeletons/list_skeleton.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final _propertyService = sl<PropertyService>();
  final _userService = sl<UserService>();
  final _session = sl<UserSession>();

  bool _isLoading = true;
  String? _error;
  List<PropertyModel> _allProperties = [];
  Set<String> _favoriteIds = {};
  List<Map<String, dynamic>> _favoriteRecords = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final propertiesFuture = _propertyService.getProperties(
        userId: _session.userId,
        page: 1,
        limit: 40,
      );
      final favoritesFuture = _session.isLoggedIn
          ? _userService.getFavorites(_session.userId!, limit: 50)
          : Future.value(<Map<String, dynamic>>[]);

      final results = await Future.wait([
        propertiesFuture,
        favoritesFuture,
      ]);

      final properties = results[0] as List<PropertyModel>;
      final favoriteRecords = results[1] as List<Map<String, dynamic>>;
      final favoriteIds = favoriteRecords
          .map((item) => (item['propertyId'] ?? item['id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();

      if (!mounted) return;
      setState(() {
        _allProperties = properties;
        _favoriteRecords = favoriteRecords;
        _favoriteIds = favoriteIds;
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

  Future<void> _toggleFavorite(PropertyModel property) async {
    if (!_session.isLoggedIn) {
      Navigator.pushNamed(
        context,
        Routes.login,
        arguments: {'redirectRoute': Routes.recommendations},
      );
      return;
    }

    final wasFavorite = _favoriteIds.contains(property.id);
    setState(() {
      if (wasFavorite) {
        _favoriteIds.remove(property.id);
      } else {
        _favoriteIds.add(property.id);
      }
    });

    try {
      await _userService.toggleFavorite(
        userId: _session.userId!,
        propertyId: property.id,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (wasFavorite) {
          _favoriteIds.add(property.id);
        } else {
          _favoriteIds.remove(property.id);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoriteProperties = _favoriteRecords
        .map((item) => item['property'] as Map<String, dynamic>? ?? item)
        .map(PropertyModel.fromJson)
        .where((property) => property.id.isNotEmpty)
        .toList();

    final favoriteTypes = favoriteProperties
        .map((property) => property.propertyType?.trim() ?? '')
        .where((type) => type.isNotEmpty)
        .toSet();

    final favoriteCities = favoriteProperties
        .map((property) => property.city?.trim() ?? '')
        .where((city) => city.isNotEmpty)
        .toSet();

    final similarToSaved = _allProperties.where((property) {
      if (_favoriteIds.contains(property.id)) return false;
      final type = property.propertyType?.trim() ?? '';
      final city = property.city?.trim() ?? '';
      return favoriteTypes.contains(type) || favoriteCities.contains(city);
    }).toList()
      ..sort((a, b) => _scoreOf(b).compareTo(_scoreOf(a)));

    final topRated = [..._allProperties]
      ..sort((a, b) => _scoreOf(b).compareTo(_scoreOf(a)));

    final guestFavorites =
        _allProperties.where((property) => property.isGuestFavorite == true).toList();

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
          context.tr('recommendations.title'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const ListSkeletonLoader(
              showSearchBar: false,
              showCategories: false,
            )
          : _error != null
              ? _RecommendationsMessage(
                  icon: Icons.error_outline,
                  title: context.tr('recommendations.unableToLoad'),
                  message: _error!,
                  actionLabel: context.tr('recommendations.retry'),
                  onAction: _loadData,
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppColors.primaryColor,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.ghostWhite,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _session.isLoggedIn
                              ? context.tr('recommendations.infoLoggedIn')
                              : context.tr('recommendations.infoLoggedOut'),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.neutral600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (favoriteProperties.isNotEmpty) ...[
                        _SectionHeader(
                          title:
                              context.tr('recommendations.savedHomesTitle'),
                          subtitle: context
                              .tr('recommendations.savedHomesSubtitle'),
                        ),
                        const SizedBox(height: 12),
                        ...favoriteProperties.take(3).map(_buildPropertyCard),
                        const SizedBox(height: 24),
                      ],
                      if (similarToSaved.isNotEmpty) ...[
                        _SectionHeader(
                          title: context.tr('recommendations.similarTitle'),
                          subtitle:
                              context.tr('recommendations.similarSubtitle'),
                        ),
                        const SizedBox(height: 12),
                        ...similarToSaved.take(4).map(_buildPropertyCard),
                        const SizedBox(height: 24),
                      ],
                      if (guestFavorites.isNotEmpty) ...[
                        _SectionHeader(
                          title: context
                              .tr('recommendations.guestFavoritesTitle'),
                          subtitle: context
                              .tr('recommendations.guestFavoritesSubtitle'),
                        ),
                        const SizedBox(height: 12),
                        ...guestFavorites.take(3).map(_buildPropertyCard),
                        const SizedBox(height: 24),
                      ],
                      if (topRated.isNotEmpty) ...[
                        _SectionHeader(
                          title: context.tr('recommendations.topRatedTitle'),
                          subtitle:
                              context.tr('recommendations.topRatedSubtitle'),
                        ),
                        const SizedBox(height: 12),
                        ...topRated.take(5).map(_buildPropertyCard),
                      ],
                      if (_allProperties.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: _RecommendationsMessage(
                            icon: Icons.travel_explore_outlined,
                            title: context.tr('recommendations.noDataTitle'),
                            message:
                                context.tr('recommendations.noDataMessage'),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPropertyCard(PropertyModel property) {
    return PropertyCardV2(
      id: property.id,
      imageUrl: property.firstImageUrl,
      title: property.displayTitle,
      location: property.displayLocation,
      price: property.displayPrice,
      originalPrice: property.priceWithoutDiscount,
      rating: _ratingOf(property),
      reviewCount: property.reviewsCount ?? property.reviewCount ?? 0,
      isFavorite: _favoriteIds.contains(property.id),
      isSuperhost: property.isGuestFavorite ?? false,
      ribbonText: property.isGuestFavorite == true
          ? context.tr('recommendations.guestFavoriteRibbon')
          : null,
      onFavoriteToggle: () => _toggleFavorite(property),
      onTap: () => Navigator.pushNamed(
        context,
        Routes.propertyDetails,
        arguments: {
          'propertyId': property.id,
          'property': property.toJson(),
        },
      ),
    );
  }

  double _scoreOf(PropertyModel property) {
    final rating = _ratingOf(property);
    final reviews = (property.reviewsCount ?? property.reviewCount ?? 0).toDouble();
    return rating * 1000 + reviews;
  }

  double _ratingOf(PropertyModel property) {
    return property.averageRating ?? property.rating ?? 0;
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.neutral600,
          ),
        ),
      ],
    );
  }
}

class _RecommendationsMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _RecommendationsMessage({
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.neutral500),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.neutral600,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.charcoal,
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
