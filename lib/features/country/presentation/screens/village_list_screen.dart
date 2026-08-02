import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/errors/exceptions.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/models/region_village_model.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/features/country/presentation/widgets/destination_message_state.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:houseiana_mobile_app/i18n/locale_aware_state.dart';
import 'package:houseiana_mobile_app/shared/widgets/skeletons/page_skeletons.dart';

/// Third level of the Country tab: the villages of a destination region, from
/// `GET /api/Lookups/region-villages?regionId={regionId}`. Tapping a village
/// opens the stays list ([Routes.searchProperties]) filtered by `villageId`.
class VillageListScreen extends StatefulWidget {
  final int regionId;
  final String regionName;

  const VillageListScreen({
    super.key,
    required this.regionId,
    required this.regionName,
  });

  @override
  State<VillageListScreen> createState() => _VillageListScreenState();
}

class _VillageListScreenState extends State<VillageListScreen>
    with LocaleAwareState<VillageListScreen> {
  final _propertyService = sl<PropertyService>();

  bool _isLoading = true;
  String? _error;
  List<RegionVillage> _villages = [];

  /// Header title — seeded from the route argument (frozen in the language it
  /// was tapped in) and re-resolved after a language switch.
  late String _regionName = widget.regionName;

  @override
  void initState() {
    super.initState();
    _loadVillages();
  }

  /// Village names are localized by the backend, so a language switch has to
  /// re-fetch the list (and re-resolve the region title above it).
  @override
  void onLocaleChanged() {
    _loadVillages(force: true);
    _refreshRegionName();
  }

  Future<void> _refreshRegionName() async {
    try {
      final regions = await _propertyService.getRegionCategories();
      if (!mounted) return;
      for (final region in regions) {
        if (region.id == widget.regionId) {
          setState(() => _regionName = region.name);
          return;
        }
      }
    } catch (_) {
      // Title-only refresh — keep the previous label on failure.
    }
  }

  /// [force] (pull-to-refresh) bypasses the 24h lookups cache and keeps the
  /// current list on screen instead of flashing the skeleton.
  Future<void> _loadVillages({bool force = false}) async {
    setState(() {
      if (!force) _isLoading = true;
      _error = null;
    });

    try {
      final villages = await _propertyService.getRegionVillages(
        widget.regionId,
        force: force,
      );
      if (!mounted) return;
      setState(() {
        _villages = villages;
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
                  ? const TileListSkeleton(
                      itemCount: 8,
                      leadingCircle: true,
                      leadingSize: 44,
                    )
                  : _error != null
                      ? DestinationMessageState(
                          icon: Icons.error_outline,
                          title: context.tr('country.unableToLoadVillages'),
                          message: _error!,
                          actionLabel: context.tr('common.retry'),
                          onAction: _loadVillages,
                        )
                      : _villages.isEmpty
                          ? DestinationMessageState(
                              icon: Icons.holiday_village_outlined,
                              title: context.tr('country.noVillages'),
                              message:
                                  context.tr('country.noVillagesDescription'),
                            )
                          : RefreshIndicator(
                              color: AppColors.primaryColor,
                              onRefresh: () => _loadVillages(force: true),
                              child: ListView.separated(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(16),
                                itemCount: _villages.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (_, i) => _VillageTile(
                                  village: _villages[i],
                                  regionId: widget.regionId,
                                  regionName: _regionName,
                                ),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _regionName,
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
                    _villages.length == 1
                        ? context.tr('country.villageSingular',
                            args: {'count': _villages.length})
                        : context.tr('country.villagesCount',
                            args: {'count': _villages.length}),
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

class _VillageTile extends StatelessWidget {
  final RegionVillage village;

  /// The region this village belongs to — handed to the results screen only so
  /// an empty village can offer "search the whole region" instead of a dead end.
  final int regionId;
  final String regionName;

  const _VillageTile({
    required this.village,
    required this.regionId,
    required this.regionName,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          Routes.searchProperties,
          arguments: {
            // `location` is display-only on the results screen (it is NOT sent
            // to the API when villageId is present) — the strict filter is the
            // villageId below.
            'location': village.name,
            'villageId': village.id,
            'parentRegionId': regionId,
            'parentRegionName': regionName,
            'totalGuests': 0,
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.neutral100,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.holiday_village_outlined,
                size: 22,
                color: AppColors.neutral600,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    village.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    context.tr('country.propertyCountValue',
                        args: {'count': village.propertyCount}),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.neutral400,
            ),
          ],
        ),
      ),
    );
  }
}
