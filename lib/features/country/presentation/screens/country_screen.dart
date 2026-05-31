import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/models/property_model.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class CountryScreen extends StatefulWidget {
  const CountryScreen({super.key});

  @override
  State<CountryScreen> createState() => _CountryScreenState();
}

class _CountryScreenState extends State<CountryScreen> {
  final _searchController = TextEditingController();
  final _propertyService = sl<PropertyService>();
  final _session = sl<UserSession>();

  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;
  List<_CountryGroup> _countries = [];

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

  Future<void> _loadCountries() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final properties = await _propertyService.getProperties(
        userId: _session.userId,
        page: 1,
        limit: 120,
      );

      if (!mounted) return;
      setState(() {
        _countries = _buildCountryGroups(properties);
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

  List<_CountryGroup> _buildCountryGroups(List<PropertyModel> properties) {
    final countries = <String, _CountryGroup>{};

    for (final property in properties) {
      final countryName = _extractCountryName(property);
      if (countryName.isEmpty) continue;

      final cityName = (property.city ?? '').trim().isNotEmpty
          ? property.city!.trim()
          : _extractCityFromLocation(property.displayLocation);
      if (cityName.isEmpty) continue;

      final countryKey = countryName.toLowerCase();
      final existingCountry = countries[countryKey] ??
          _CountryGroup(
            name: countryName,
            imageUrl: property.firstImageUrl,
            propertyCount: 0,
            cities: const [],
          );

      final cityMap = {
        for (final city in existingCountry.cities) city.name.toLowerCase(): city
      };
      final cityKey = cityName.toLowerCase();
      final existingCity = cityMap[cityKey];
      cityMap[cityKey] = existingCity == null
          ? _CityGroup(
              name: cityName,
              imageUrl: property.firstImageUrl,
              propertyCount: 1,
            )
          : existingCity.copyWith(
              propertyCount: existingCity.propertyCount + 1,
              imageUrl: existingCity.imageUrl.isNotEmpty
                  ? existingCity.imageUrl
                  : property.firstImageUrl,
            );

      countries[countryKey] = existingCountry.copyWith(
        propertyCount: existingCountry.propertyCount + 1,
        imageUrl: existingCountry.imageUrl.isNotEmpty
            ? existingCountry.imageUrl
            : property.firstImageUrl,
        cities: cityMap.values.toList()
          ..sort((a, b) {
            final byCount = b.propertyCount.compareTo(a.propertyCount);
            return byCount != 0 ? byCount : a.name.compareTo(b.name);
          }),
      );
    }

    final list = countries.values.toList()
      ..sort((a, b) {
        final byCount = b.propertyCount.compareTo(a.propertyCount);
        return byCount != 0 ? byCount : a.name.compareTo(b.name);
      });
    return list;
  }

  String _extractCountryName(PropertyModel property) {
    final fromCountryData = (property.countryData?['name'] ??
            property.countryData?['countryName'] ??
            property.countryData?['title'])
        ?.toString()
        .trim();
    if (fromCountryData != null && fromCountryData.isNotEmpty) {
      return fromCountryData;
    }

    final location = property.displayLocation;
    final parts = location.split(',').map((part) => part.trim()).toList();
    if (parts.length > 1 && parts.last.isNotEmpty) return parts.last;
    return '';
  }

  String _extractCityFromLocation(String location) {
    final parts = location.split(',').map((part) => part.trim()).toList();
    if (parts.isEmpty) return '';
    return parts.first;
  }

  List<_CountryGroup> get _filtered {
    if (_searchQuery.isEmpty) return _countries;
    final query = _searchQuery.toLowerCase();
    return _countries.where((country) {
      return country.name.toLowerCase().contains(query) ||
          country.cities.any((city) => city.name.toLowerCase().contains(query));
    }).toList();
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
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    )
                  : _error != null
                      ? _MessageState(
                          icon: Icons.error_outline,
                          title: context.tr('country.unableToLoadDestinations'),
                          message: _error!,
                          actionLabel: context.tr('common.retry'),
                          onAction: _loadCountries,
                        )
                      : filtered.isEmpty
                          ? _MessageState(
                              icon: Icons.search_off_outlined,
                              title: context.tr('country.noDestinationsFound'),
                              message: _searchQuery.isEmpty
                                  ? context.tr('country.noDestinationsEmptyDescription')
                                  : context.tr('country.noDestinationsSearchDescription'),
                            )
                          : RefreshIndicator(
                              color: AppColors.primaryColor,
                              onRefresh: _loadCountries,
                              child: GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 14,
                                  crossAxisSpacing: 14,
                                  childAspectRatio: 0.82,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (_, i) => _CountryCard(
                                  country: filtered[i],
                                ),
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
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('country.title'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            visibleCount == 1
                ? context.tr('country.destinationSingular', args: {'count': visibleCount})
                : context.tr('country.destinations', args: {'count': visibleCount}),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.neutral600,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value.trim()),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: context.tr('country.searchCountryCity'),
              hintStyle: const TextStyle(
                fontSize: 14,
                color: AppColors.neutral400,
              ),
              prefixIcon: const Icon(
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
                      child: const Icon(
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
  final _CountryGroup country;

  const _CountryCard({required this.country});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          Routes.cityList,
          arguments: {
            'countryName': country.name,
            'countryFlag': '',
            'cities': country.cities
                .map(
                  (city) => {
                    'name': city.name,
                    'properties': city.propertyCount.toString(),
                    'image': city.imageUrl,
                  },
                )
                .toList(),
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
                child: country.imageUrl.isNotEmpty
                    ? Image.network(
                        country.imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imageFallback(),
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
                    country.name,
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
                          context.tr('country.propertyCountValue', args: {'count': country.propertyCount}),
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
        Icons.public,
        size: 40,
        color: AppColors.neutral400,
      ),
    );
  }
}

class _CountryGroup {
  final String name;
  final String imageUrl;
  final int propertyCount;
  final List<_CityGroup> cities;

  const _CountryGroup({
    required this.name,
    required this.imageUrl,
    required this.propertyCount,
    required this.cities,
  });

  _CountryGroup copyWith({
    String? imageUrl,
    int? propertyCount,
    List<_CityGroup>? cities,
  }) {
    return _CountryGroup(
      name: name,
      imageUrl: imageUrl ?? this.imageUrl,
      propertyCount: propertyCount ?? this.propertyCount,
      cities: cities ?? this.cities,
    );
  }
}

class _CityGroup {
  final String name;
  final String imageUrl;
  final int propertyCount;

  const _CityGroup({
    required this.name,
    required this.imageUrl,
    required this.propertyCount,
  });

  _CityGroup copyWith({
    String? imageUrl,
    int? propertyCount,
  }) {
    return _CityGroup(
      name: name,
      imageUrl: imageUrl ?? this.imageUrl,
      propertyCount: propertyCount ?? this.propertyCount,
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.neutral500),
            const SizedBox(height: 14),
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
                height: 1.5,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
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
