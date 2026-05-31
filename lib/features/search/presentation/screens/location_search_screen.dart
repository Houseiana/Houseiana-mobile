import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/models/property_model.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class LocationSearchScreen extends StatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final _searchController = TextEditingController();
  final _propertyService = sl<PropertyService>();
  final _session = sl<UserSession>();

  bool _isLoading = true;
  String? _error;
  List<_LocationSuggestion> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadLocations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final properties = await _propertyService.getProperties(
        userId: _session.userId,
        page: 1,
        limit: 60,
      );

      final suggestions = _buildSuggestions(properties);

      if (!mounted) return;
      setState(() {
        _suggestions = suggestions;
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

  List<_LocationSuggestion> _buildSuggestions(List<PropertyModel> properties) {
    final unique = <String, _LocationSuggestion>{};

    for (final property in properties) {
      final city = (property.city ?? '').trim();
      final displayLocation = property.displayLocation.trim();

      if (displayLocation.isNotEmpty) {
        unique.putIfAbsent(
          displayLocation.toLowerCase(),
          () => _LocationSuggestion(
            name: displayLocation,
            typeKey: city.isNotEmpty
                ? 'search.locationTypeDestination'
                : 'search.locationTypeListing',
          ),
        );
      }

      if (city.isNotEmpty) {
        unique.putIfAbsent(
          city.toLowerCase(),
          () => const _LocationSuggestion(
            name: '',
            typeKey: 'search.locationTypeCity',
          ).copyWith(name: city),
        );
      }
    }

    final items = unique.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _suggestions.where((item) {
      if (query.isEmpty) return true;
      return item.name.toLowerCase().contains(query) ||
          context.tr(item.typeKey).toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: context.tr('search.searchLocations'),
            border: InputBorder.none,
            hintStyle: const TextStyle(color: AppColors.neutral400),
          ),
          style: const TextStyle(fontSize: 16),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            )
          : _error != null
              ? _LocationMessageState(
                  icon: Icons.error_outline,
                  title: context.tr('search.unableToLoadLocations'),
                  message: _error!,
                  actionLabel: context.tr('common.retry'),
                  onAction: _loadLocations,
                )
              : filtered.isEmpty
                  ? _LocationMessageState(
                      icon: Icons.search_off_outlined,
                      title: query.isEmpty
                          ? context.tr('search.noLiveLocations')
                          : context.tr('search.noMatchingLocations'),
                      message: query.isEmpty
                          ? context.tr('search.noLiveLocationsDescription')
                          : context.tr('search.noMatchingLocationsDescription'),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      children: [
                        Text(
                          query.isEmpty
                              ? context.tr('search.liveDestinations')
                              : context.tr('search.matchingLocations'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          query.isEmpty
                              ? context.tr('search.suggestionsInfo')
                              : context.tr('search.matchesFound', args: {'count': filtered.length}),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.neutral600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...filtered.map(_buildLocationTile),
                      ],
                    ),
    );
  }

  Widget _buildLocationTile(_LocationSuggestion location) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.ghostWhite,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.location_on_outlined,
          color: AppColors.charcoal,
          size: 20,
        ),
      ),
      title: Text(
        location.name,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.charcoal,
        ),
      ),
      subtitle: Text(
        context.tr(location.typeKey),
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.neutral600,
        ),
      ),
      onTap: () => Navigator.pop(context, location.name),
    );
  }
}

class _LocationSuggestion {
  final String name;
  final String typeKey;

  const _LocationSuggestion({
    required this.name,
    required this.typeKey,
  });

  _LocationSuggestion copyWith({String? name, String? typeKey}) =>
      _LocationSuggestion(
        name: name ?? this.name,
        typeKey: typeKey ?? this.typeKey,
      );
}

class _LocationMessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _LocationMessageState({
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
            Icon(icon, size: 48, color: AppColors.neutral500),
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
