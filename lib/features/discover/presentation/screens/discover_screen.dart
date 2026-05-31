import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/models/property_model.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:houseiana_mobile_app/shared/widgets/cards/property_card_v2.dart';
import 'package:houseiana_mobile_app/shared/widgets/skeletons/list_skeleton.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _propertyService = sl<PropertyService>();
  final _session = sl<UserSession>();

  bool _isLoading = true;
  String? _error;
  List<PropertyModel> _properties = [];

  @override
  void initState() {
    super.initState();
    _loadDiscoverData();
  }

  Future<void> _loadDiscoverData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final properties = await _propertyService.getProperties(
        userId: _session.userId,
        page: 1,
        limit: 40,
      );

      if (!mounted) return;
      setState(() {
        _properties = properties;
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

  @override
  Widget build(BuildContext context) {
    final cityGroups = _buildCityGroups(_properties);
    final typeGroups = _buildTypeGroups(_properties);
    final topRated = [..._properties]
      ..sort((a, b) => _ratingOf(b).compareTo(_ratingOf(a)));
    final guestFavorites =
        _properties.where((property) => property.isGuestFavorite == true).toList();

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
          context.tr('discover.title'),
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
              ? _ErrorState(
                  message: _error!,
                  onRetry: _loadDiscoverData,
                )
              : RefreshIndicator(
                  onRefresh: _loadDiscoverData,
                  color: AppColors.primaryColor,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    children: [
                      _SearchHeader(
                        onTapSearch: () {
                          Navigator.pushNamed(context, Routes.searchModal)
                              .then((_) => _loadDiscoverData());
                        },
                      ),
                      const SizedBox(height: 24),
                      if (cityGroups.isNotEmpty) ...[
                        _SectionHeader(
                          title: context.tr('discover.browseLive'),
                          subtitle: context.tr('discover.browseLiveDescription'),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 180,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: cityGroups.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final group = cityGroups[index];
                              return _DestinationCard(
                                group: group,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  Routes.searchProperties,
                                  arguments: {'location': group.name},
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                      if (topRated.isNotEmpty) ...[
                        _SectionHeader(
                          title: context.tr('discover.topRated'),
                          subtitle: context.tr('discover.topRatedDescription'),
                        ),
                        const SizedBox(height: 12),
                        ...topRated.take(4).map(_buildPropertyCard),
                        const SizedBox(height: 20),
                      ],
                      if (guestFavorites.isNotEmpty) ...[
                        _SectionHeader(
                          title: context.tr('discover.guestFavorites'),
                          subtitle: context.tr('discover.guestFavoritesDescription'),
                        ),
                        const SizedBox(height: 12),
                        ...guestFavorites.take(3).map(_buildPropertyCard),
                        const SizedBox(height: 20),
                      ],
                      if (typeGroups.isNotEmpty) ...[
                        _SectionHeader(
                          title: context.tr('discover.browseByType'),
                          subtitle: context.tr('discover.browseByTypeDescription'),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: typeGroups
                              .map(
                                (group) => _TypeChip(
                                  label: '${group.name} (${group.count})',
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    Routes.searchProperties,
                                    arguments: {'propertyType': group.name},
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      if (_properties.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: _EmptyState(
                            title: context.tr('discover.noLiveListings'),
                            message: context.tr('discover.noLiveListingsDescription'),
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
      isFavorite: property.isFavourited ?? false,
      isSuperhost: property.isGuestFavorite ?? false,
      ribbonText: property.isGuestFavorite == true ? context.tr('home.guestFavorite') : null,
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

  double _ratingOf(PropertyModel property) {
    return property.averageRating ?? property.rating ?? 0;
  }

  List<_NamedCountGroup> _buildTypeGroups(List<PropertyModel> properties) {
    final counts = <String, int>{};
    for (final property in properties) {
      final type = (property.propertyType ?? '').trim();
      if (type.isEmpty) continue;
      counts[type] = (counts[type] ?? 0) + 1;
    }

    final groups = counts.entries
        .map((entry) => _NamedCountGroup(name: entry.key, count: entry.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return groups.take(8).toList();
  }

  List<_CityDiscoverGroup> _buildCityGroups(List<PropertyModel> properties) {
    final grouped = <String, List<PropertyModel>>{};
    for (final property in properties) {
      final city = (property.city ?? _extractCityFromLocation(property)).trim();
      if (city.isEmpty) continue;
      grouped.putIfAbsent(city, () => []).add(property);
    }

    final groups = grouped.entries
        .map(
          (entry) => _CityDiscoverGroup(
            name: entry.key,
            properties: entry.value,
          ),
        )
        .toList()
      ..sort((a, b) => b.properties.length.compareTo(a.properties.length));
    return groups.take(8).toList();
  }

  String _extractCityFromLocation(PropertyModel property) {
    final location = property.displayLocation.trim();
    if (location.isEmpty) return '';
    return location.split(',').first.trim();
  }
}

class _SearchHeader extends StatelessWidget {
  final VoidCallback onTapSearch;

  const _SearchHeader({required this.onTapSearch});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapSearch,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.ghostWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.neutral600),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('discover.searchLiveListings'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('discover.exploreCurrentStays'),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.neutral600),
          ],
        ),
      ),
    );
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

class _DestinationCard extends StatelessWidget {
  final _CityDiscoverGroup group;
  final VoidCallback onTap;

  const _DestinationCard({
    required this.group,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cover = group.properties.first.firstImageUrl;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 160,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              cover.isNotEmpty
                  ? Image.network(
                      cover,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallback(),
                    )
                  : _fallback(),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('discover.liveStays', args: {'count': group.properties.length}),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: AppColors.neutral200,
      child: const Icon(
        Icons.location_city,
        color: AppColors.neutral500,
        size: 36,
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ghostWhite,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.neutral600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.charcoal,
              ),
              child: Text(context.tr('common.retry')),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyState({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.travel_explore_outlined,
          size: 52,
          color: AppColors.neutral500,
        ),
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
      ],
    );
  }
}

class _NamedCountGroup {
  final String name;
  final int count;

  const _NamedCountGroup({
    required this.name,
    required this.count,
  });
}

class _CityDiscoverGroup {
  final String name;
  final List<PropertyModel> properties;

  const _CityDiscoverGroup({
    required this.name,
    required this.properties,
  });
}
