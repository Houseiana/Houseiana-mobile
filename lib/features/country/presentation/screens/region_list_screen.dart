import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/errors/exceptions.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/models/region_category_model.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/features/country/presentation/widgets/destination_message_state.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:houseiana_mobile_app/shared/widgets/skeletons/page_skeletons.dart';

/// Second level of the Country tab: the destination regions of a country,
/// from `GET /api/Lookups/RegionCategory` (photo + name + stays count).
/// Tapping a region opens its villages ([Routes.villageList]).
///
/// The backend does not scope RegionCategory by country (no such param
/// exists — probed countryId/country/countryCode against prod, all ignored),
/// and every region in the catalog today is Egyptian. So the regions are
/// shown only for Egypt ([_destinationsCountryId]); other countries get the
/// "no destinations yet" empty state instead of Egypt's data. When the
/// backend adds country scoping, drop the gate and pass the id instead.
class RegionListScreen extends StatefulWidget {
  final int countryId;
  final String countryName;
  final String countryFlag;

  const RegionListScreen({
    super.key,
    required this.countryId,
    required this.countryName,
    required this.countryFlag,
  });

  @override
  State<RegionListScreen> createState() => _RegionListScreenState();
}

class _RegionListScreenState extends State<RegionListScreen> {
  final _propertyService = sl<PropertyService>();

  /// Stable `/api/lookups/country` id of the only country the destination
  /// catalog covers today (2 = Egypt).
  static const int _destinationsCountryId = 2;

  bool _isLoading = true;
  String? _error;
  List<RegionCategory> _regions = [];

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  /// [force] (pull-to-refresh) bypasses the 24h lookups cache and keeps the
  /// current grid on screen instead of flashing the skeleton.
  Future<void> _loadRegions({bool force = false}) async {
    // The whole catalog is Egyptian — don't show it under other countries.
    if (widget.countryId != _destinationsCountryId) {
      setState(() {
        _regions = [];
        _isLoading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      if (!force) _isLoading = true;
      _error = null;
    });

    try {
      final regions = await _propertyService.getRegionCategories(force: force);
      if (!mounted) return;
      setState(() {
        _regions = regions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // Prefer the typed `.message` (ServerException.toString() also returns
        // it, but the explicit read doesn't depend on that).
        _error = e is ServerException && e.message.trim().isNotEmpty
            ? e.message
            : e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ghostWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const GridSkeleton(
                      itemCount: 6,
                      crossAxisCount: 2,
                      childAspectRatio: 0.82,
                    )
                  : _error != null
                      ? DestinationMessageState(
                          icon: Icons.error_outline,
                          title: context.tr('country.unableToLoadRegions'),
                          message: _error!,
                          actionLabel: context.tr('common.retry'),
                          onAction: _loadRegions,
                        )
                      : _regions.isEmpty
                          ? DestinationMessageState(
                              icon: Icons.landscape_outlined,
                              title: context.tr('country.noRegions'),
                              message:
                                  context.tr('country.noRegionsDescription'),
                            )
                          : RefreshIndicator(
                              color: AppColors.primaryColor,
                              onRefresh: () => _loadRegions(force: true),
                              child: GridView.builder(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(16),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 14,
                                  crossAxisSpacing: 14,
                                  childAspectRatio: 0.82,
                                ),
                                itemCount: _regions.length,
                                itemBuilder: (_, i) =>
                                    _RegionCard(region: _regions[i]),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back,
                color: AppColors.charcoal, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          if (widget.countryFlag.isNotEmpty) ...[
            Text(
              widget.countryFlag,
              style: const TextStyle(fontSize: 26),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.countryName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!_isLoading && _error == null)
                  Text(
                    _regions.length == 1
                        ? context.tr('country.regionSingular',
                            args: {'count': _regions.length})
                        : context.tr('country.regionsCount',
                            args: {'count': _regions.length}),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RegionCard extends StatelessWidget {
  final RegionCategory region;

  const _RegionCard({required this.region});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          Routes.villageList,
          arguments: {
            'regionId': region.id,
            'regionName': region.name,
          },
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: region.photo.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: region.photo,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: double.infinity,
                          color: const Color(0xFFF0F0F0),
                        ),
                        errorWidget: (context, url, error) =>
                            _imageFallback(),
                      )
                    : _imageFallback(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    region.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.home_outlined,
                        size: 12,
                        color: AppColors.neutral600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          context.tr('country.propertyCountValue',
                              args: {'count': region.propertyCount}),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.neutral600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 14,
                        color: AppColors.neutral400,
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
      width: double.infinity,
      color: AppColors.neutral200,
      child: const Icon(
        Icons.landscape_outlined,
        size: 40,
        color: AppColors.neutral400,
      ),
    );
  }
}
