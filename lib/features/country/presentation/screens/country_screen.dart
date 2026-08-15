import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/errors/exceptions.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/models/country_option.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/features/country/presentation/widgets/destination_message_state.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:houseiana_mobile_app/i18n/locale_aware_state.dart';
import 'package:houseiana_mobile_app/shared/widgets/skeletons/page_skeletons.dart';

/// First level of the Country tab: countries from `GET /api/lookups/country`.
/// Tapping a country opens its destination regions (RegionCategory), which in
/// turn drill into villages (region-villages) and finally the stays list
/// filtered by `villageId`.
class CountryScreen extends StatefulWidget {
  CountryScreen({super.key});

  @override
  State<CountryScreen> createState() => _CountryScreenState();
}

class _CountryScreenState extends State<CountryScreen>
    with LocaleAwareState<CountryScreen> {
  final _searchController = TextEditingController();
  final _propertyService = sl<PropertyService>();

  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;
  List<CountryOption> _countries = [];

  /// Flag emoji per stable country lookup id (1 = Qatar, 2 = Egypt,
  /// 3 = Bahrain). Names are localized by the backend, so the emoji must key
  /// off the id — same stable-id contract as the other lookups.
  static const Map<int, String> _flagsById = {
    1: '🇶🇦',
    2: '🇪🇬',
    3: '🇧🇭',
  };

  static String flagFor(int countryId) => _flagsById[countryId] ?? '🌍';

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// The country names are localized by the backend (`?lang=`), and this tab
  /// stays mounted for the whole session — so a language switch has to re-fetch
  /// them or the list keeps showing the previous language. `force: true` skips
  /// the 24h lookups cache and keeps the current list on screen (no skeleton
  /// flash) while the new-language one loads.
  @override
  void onLocaleChanged() => _loadCountries(force: true);

  /// [force] (pull-to-refresh) bypasses the 24h lookups cache and keeps the
  /// current list on screen instead of flashing the skeleton.
  Future<void> _loadCountries({bool force = false}) async {
    setState(() {
      if (!force) _isLoading = true;
      _error = null;
    });

    try {
      final countries = await _propertyService.getCountries(force: force);
      if (!mounted) return;
      setState(() {
        _countries = countries;
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

  List<CountryOption> get _filtered {
    if (_searchQuery.isEmpty) return _countries;
    final query = _searchQuery.toLowerCase();
    return _countries
        .where((c) => c.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppColors.ghostWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(filtered.length),
            Expanded(
              child: _isLoading
                  ? TileListSkeleton(
                      itemCount: 4,
                      leadingCircle: true,
                      leadingSize: 52,
                      tileHeight: 84,
                    )
                  : _error != null
                      ? DestinationMessageState(
                          icon: Icons.error_outline,
                          title: context.tr('country.unableToLoadDestinations'),
                          message: _error!,
                          actionLabel: context.tr('common.retry'),
                          onAction: _loadCountries,
                        )
                      : filtered.isEmpty
                          ? DestinationMessageState(
                              icon: Icons.search_off_outlined,
                              title: context.tr('country.noDestinationsFound'),
                              message: _searchQuery.isEmpty
                                  ? context.tr('country.noCountriesDescription')
                                  : context.tr(
                                      'country.noCountriesSearchDescription'),
                            )
                          : RefreshIndicator(
                              color: AppColors.primaryColor,
                              onRefresh: () => _loadCountries(force: true),
                              child: ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(16),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (_, i) =>
                                    _CountryCard(country: filtered[i]),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int visibleCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      color: AppColors.cardBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('country.title'),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          // Guarded so the subtitle never reads "0 countries" while the
          // skeleton is loading (or after a failed load).
          if (!_isLoading && _error == null) ...[
            const SizedBox(height: 4),
            Text(
              visibleCount == 1
                  ? context.tr('country.countrySingular',
                      args: {'count': visibleCount})
                  : context.tr('country.countriesCount',
                      args: {'count': visibleCount}),
              style: TextStyle(
                fontSize: 13,
                color: AppColors.neutral600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value.trim()),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: context.tr('country.searchCountry'),
              hintStyle: TextStyle(
                fontSize: 14,
                color: AppColors.neutral400,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: AppColors.neutral400,
                size: 20,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: Icon(
                        Icons.close,
                        color: AppColors.neutral400,
                        size: 18,
                      ),
                    )
                  : null,
              filled: true,
              fillColor: AppColors.neutral100,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primaryColor,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryCard extends StatelessWidget {
  final CountryOption country;

  _CountryCard({required this.country});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          Routes.regionList,
          arguments: {
            'countryId': country.id,
            'countryName': country.name,
            'countryFlag': _CountryScreenState.flagFor(country.id),
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
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
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _CountryScreenState.flagFor(country.id),
                style: const TextStyle(fontSize: 26),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    country.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    context.tr('country.exploreDestinations'),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
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
