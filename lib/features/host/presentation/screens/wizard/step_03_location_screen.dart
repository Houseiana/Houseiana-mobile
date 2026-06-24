import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/features/host/cubit/listing_wizard_cubit.dart' hide sl;
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/network/api/end_points.dart';
import 'package:houseiana_mobile_app/core/services/places_service.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class Step03LocationScreen extends StatefulWidget {
  const Step03LocationScreen({super.key});

  @override
  State<Step03LocationScreen> createState() => _Step03LocationScreenState();
}

class _Step03LocationScreenState extends State<Step03LocationScreen> {
  bool _showForm = false;
  bool _isSearching = false;

  final _searchController = TextEditingController();
  final _addressController = TextEditingController();
  final _buildingController = TextEditingController();
  final _floorController = TextEditingController();
  final _unitController = TextEditingController();
  final _areaController = TextEditingController();
  final _postalController = TextEditingController();

  List<Map<String, dynamic>> _countries = [];
  List<Map<String, dynamic>> _states = [];
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _villages = [];

  String? _selectedCountryId;
  String? _selectedStateId;
  String? _selectedCityId;
  String? _selectedVillageId;

  GoogleMapController? _mapController;
  LatLng _currentLocation = const LatLng(30.0444, 31.2357); // Cairo default

  Timer? _debounce;

  // ── Address autocomplete (Google Places) ──────────────────────────────────
  final PlacesService _placesService = PlacesService();
  List<PlacePrediction> _predictions = [];
  String? _placesSessionToken;
  bool _isResolving = false;
  // Monotonic id so a slow/superseded autocomplete response can't overwrite
  // newer suggestions or reappear after a place was already selected.
  int _searchSeq = 0;

  @override
  void initState() {
    super.initState();
    // Seed text fields from existing wizard data so values persist across
    // back/forward navigation and are shown when editing an existing listing.
    final data = context.read<ListingWizardCubit>().state.data;
    _addressController.text = data.address ?? '';
    _areaController.text = data.district ?? '';
    _buildingController.text = data.buildingNumber ?? '';
    _floorController.text = data.floorNumber ?? '';
    _unitController.text = data.unitNumber ?? '';
    _postalController.text = data.postalCode ?? '';
    _selectedCountryId = data.country;
    _selectedStateId = data.stateProvince;
    _selectedCityId = data.city;
    _selectedVillageId = data.village;
    _preloadLocation();
  }

  /// Loads the country list and, when editing an existing listing, cascades
  /// through the saved state/city/village so their dropdowns appear
  /// pre-selected. In create mode (no saved ids) this just loads countries.
  Future<void> _preloadLocation() async {
    await _loadCountries();
    final country = _selectedCountryId;
    if (country == null || country.isEmpty) return;
    await _loadStates(country);
    final state = _selectedStateId;
    if (state == null || state.isEmpty) return;
    await _loadCities(state);
    final city = _selectedCityId;
    if (city == null || city.isEmpty) return;
    await _loadVillages(city);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _addressController.dispose();
    _buildingController.dispose();
    _floorController.dispose();
    _unitController.dispose();
    _areaController.dispose();
    _postalController.dispose();
    _debounce?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    try {
      final api = sl<ApiConsumer>();
      final response = await api.get(EndPoints.countriesLookup);
      final List<Map<String, dynamic>> data = _extractList(response);
      if (mounted) {
        setState(() {
          _countries = data;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadStates(String countryId) async {
    try {
      final api = sl<ApiConsumer>();
      final response = await api.get(EndPoints.statesLookup(int.parse(countryId)));
      dynamic raw = response;
      if (raw is Map && raw['states'] != null) {
        raw = raw['states'];
      }
      final List<Map<String, dynamic>> data = _extractList(raw);
      if (mounted) {
        setState(() {
          _states = data;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadCities(String stateId) async {
    try {
      final api = sl<ApiConsumer>();
      final response = await api.get(EndPoints.citiesLookup(int.parse(stateId)));
      dynamic raw = response;
      if (raw is Map && raw['cities'] != null) {
        raw = raw['cities'];
      }
      final List<Map<String, dynamic>> data = _extractList(raw);
      if (mounted) {
        setState(() {
          _cities = data;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadVillages(String cityId) async {
    try {
      final api = sl<ApiConsumer>();
      final response = await api.get(EndPoints.villagesLookup(int.parse(cityId)));
      dynamic raw = response;
      if (raw is Map && raw['villages'] != null) {
        raw = raw['villages'];
      }
      final List<Map<String, dynamic>> data = _extractList(raw);
      if (mounted) {
        setState(() {
          _villages = data;
        });
      }
    } catch (_) {}
  }

  List<Map<String, dynamic>> _extractList(dynamic response) {
    dynamic raw = response;
    if (raw is Map) raw = raw['data'] ?? raw['items'] ?? raw['result'] ?? raw;
    if (raw is Map) {
      raw = raw['items'] ?? raw['data'] ?? raw.values.firstWhere((v) => v is List, orElse: () => []);
    }
    if (raw is List) {
      final unknownLabel = mounted ? context.tr('wizard.wizardLocationUnknown') : 'Unknown';
      return raw.map((item) {
        return {
          'id': item['id']?.toString() ?? '',
          'name': item['name']?.toString() ?? unknownLabel,
        };
      }).toList();
    }
    return [];
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    final q = query.trim();
    if (q.isEmpty) {
      _searchSeq++; // invalidate any in-flight fetch
      setState(() => _predictions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _fetchPredictions(q);
    });
  }

  /// Queries Google Places Autocomplete and shows the suggestions the user can
  /// pick from (web parity). Replaces the old single-shot geocode that silently
  /// jumped to the first match — the cause of the "random place on the map" bug.
  Future<void> _fetchPredictions(String query) async {
    if (!mounted) return;
    final seq = ++_searchSeq;
    setState(() => _isSearching = true);
    _placesSessionToken ??= _placesService.newSessionToken();
    try {
      final lang = Localizations.localeOf(context).languageCode;
      final results = await _placesService.autocomplete(
        query,
        language: lang,
        sessionToken: _placesSessionToken,
      );
      if (!mounted) return;
      // Drop superseded responses (rapid typing) and any that land while a
      // selection is being resolved, so stale suggestions can't reappear.
      if (seq != _searchSeq || _isResolving) return;
      setState(() => _predictions = results);
    } catch (_) {
      if (mounted && seq == _searchSeq) setState(() => _predictions = []);
    } finally {
      if (mounted && seq == _searchSeq) setState(() => _isSearching = false);
    }
  }

  /// Fetches full details for the chosen suggestion, then fills the coordinates,
  /// street, postal code and cascades the country/state/district dropdowns to
  /// the matching lookup ids (mirrors the web LocationStep place_changed logic).
  Future<void> _onPredictionSelected(PlacePrediction prediction) async {
    _debounce?.cancel();
    _searchSeq++; // invalidate any in-flight autocomplete request
    FocusScope.of(context).unfocus();
    setState(() {
      _predictions = [];
      _isResolving = true;
      _searchController.text = prediction.mainText.isNotEmpty
          ? prediction.mainText
          : prediction.description;
    });
    try {
      final lang = Localizations.localeOf(context).languageCode;
      final details = await _placesService.details(
        prediction.placeId,
        language: lang,
        sessionToken: _placesSessionToken,
      );
      _placesSessionToken = null; // selecting a place ends the billing session
      if (!mounted) return;
      if (details == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('wizard.wizardLocationGeocodingError'))),
        );
        return;
      }
      await _applyPlaceDetails(details);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('wizard.wizardLocationGeocodingError'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isResolving = false);
    }
  }

  /// Applies a resolved [PlaceDetails] to the form: cascades country → state →
  /// district lookups (matching by localized name), fills the street / postal
  /// fields, sets the coordinates and recentres the confirmation map.
  Future<void> _applyPlaceDetails(PlaceDetails details) async {
    final cubit = context.read<ListingWizardCubit>();

    // Resolve the country → state → district lookup ids by name. Each level is
    // loaded before the next so the name match runs against the fresh options.
    final country = _findByName(_countries, details.countryName);
    if (country != null) {
      final countryId = country['id'] as String;
      _selectedCountryId = countryId;
      _selectedStateId = null;
      _selectedCityId = null;
      _selectedVillageId = null;
      _states = [];
      _cities = [];
      _villages = [];
      // Clear downstream ids in the cubit too. updateStepData merges with
      // `?? old`, so an empty string is the only way to clear them — otherwise a
      // stale district/village from a previous selection would leak into the
      // submitted payload when this level fails to re-resolve.
      cubit.updateStepData({
        'country': countryId,
        'stateProvince': '',
        'city': '',
        'village': '',
      });
      await _loadStates(countryId);

      final state = _findByName(_states, details.stateName, stateMode: true);
      if (state != null) {
        final stateId = state['id'] as String;
        _selectedStateId = stateId;
        cubit.updateStepData({'stateProvince': stateId});
        await _loadCities(stateId);

        final city = _findByName(_cities, details.cityName);
        if (city != null) {
          final cityId = city['id'] as String;
          _selectedCityId = cityId;
          cubit.updateStepData({'city': cityId});
          await _loadVillages(cityId);
        }
      }
    }

    if (!mounted) return;

    final street = details.street.isNotEmpty
        ? details.street
        : (details.formattedAddress.isNotEmpty
            ? details.formattedAddress
            : details.name);

    cubit.updateStepData({
      'latitude': details.latitude,
      'longitude': details.longitude,
      'address': street,
      if (details.postalCode.isNotEmpty) 'postalCode': details.postalCode,
    });

    setState(() {
      if (street.isNotEmpty) _addressController.text = street;
      if (details.postalCode.isNotEmpty) {
        _postalController.text = details.postalCode;
      }
      _currentLocation = LatLng(details.latitude, details.longitude);
      _showForm = true;
    });
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_currentLocation, 15),
    );
  }

  // Web parity: state names from Google ("Marsa Matrouh Governorate") rarely
  // equal the backend lookup ("Matrouh"), so strip common administrative
  // suffixes before comparing.
  static const List<String> _stateSuffixes = [
    'governorate',
    'municipality',
    'province',
    'district',
    'region',
    'state',
  ];

  String _normalizeStateName(String name) {
    var n = name.toLowerCase().trim();
    for (final suffix in _stateSuffixes) {
      if (n.endsWith(' $suffix')) {
        n = n.substring(0, n.length - suffix.length - 1).trim();
        break;
      }
    }
    return n;
  }

  /// Finds the lookup entry whose name matches [name] — exact first, then a
  /// two-way "contains" match. Mirrors the web findStateByName/findCityByName.
  Map<String, dynamic>? _findByName(
    List<Map<String, dynamic>> items,
    String name, {
    bool stateMode = false,
  }) {
    if (name.trim().isEmpty) return null;
    String norm(String s) =>
        stateMode ? _normalizeStateName(s) : s.toLowerCase().trim();
    final n = norm(name);
    if (n.isEmpty) return null;
    for (final item in items) {
      if (norm(item['name']?.toString() ?? '') == n) return item;
    }
    for (final item in items) {
      final iname = norm(item['name']?.toString() ?? '');
      if (iname.isNotEmpty && (iname.contains(n) || n.contains(iname))) {
        return item;
      }
    }
    return null;
  }

  void _useCurrentLocation() => _switchView(true);

  void _enterManually() => _switchView(true);

  /// Switches between the map and form views, clearing any dangling
  /// (unselected) suggestions and cancelling pending autocomplete work so a
  /// stale dropdown can't leak across the switch.
  void _switchView(bool showForm) {
    _debounce?.cancel();
    _searchSeq++;
    setState(() {
      _predictions = [];
      _showForm = showForm;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _showForm ? _buildFormView(context) : _buildMapView(context);
  }

  Widget _buildMapView(BuildContext context) {
    final cubit = context.read<ListingWizardCubit>();
    // A fixed-height map inside a scroll view (instead of Expanded) so the
    // open keyboard pushes content into the scroll area rather than collapsing
    // the map and clipping the suggestions overlay.
    final double mapHeight =
        (MediaQuery.of(context).size.height * 0.62).clamp(380.0, 560.0).toDouble();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Text(
              context.tr('wizard.wizardLocationStepTitle'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
          ),
          Container(
            height: mapHeight,
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.neutral200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          cubit.state.data.latitude ?? _currentLocation.latitude,
                          cubit.state.data.longitude ?? _currentLocation.longitude,
                        ),
                        zoom: 12,
                      ),
                      onMapCreated: (controller) => _mapController = controller,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                        Factory<OneSequenceGestureRecognizer>(
                          () => EagerGestureRecognizer(),
                        ),
                      },
                      onTap: (loc) {
                        cubit.updateStepData({
                          'latitude': loc.latitude,
                          'longitude': loc.longitude,
                        });
                        _currentLocation = loc;
                        _switchView(true);
                      },
                      markers: {
                        if (cubit.state.data.latitude != null)
                          Marker(
                            markerId: const MarkerId('selected'),
                            position: LatLng(
                              cubit.state.data.latitude!,
                              cubit.state.data.longitude!,
                            ),
                          ),
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 24,
                  left: 24,
                  right: 24,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: context.tr('wizard.wizardLocationSearchHint'),
                              border: InputBorder.none,
                              prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.neutral600),
                              suffixIcon: _isSearching
                                  ? const Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        _buildPredictionsList(),
                        _buildResolvingRow(),
                        // Hide the action shortcuts while suggestions are showing
                        // so the card stays compact and the list stays reachable.
                        if (_predictions.isEmpty) ...[
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.near_me_outlined, color: AppColors.charcoal),
                            title: Text(context.tr('wizard.wizardLocationUseCurrent'), style: const TextStyle(fontWeight: FontWeight.w500)),
                            onTap: _useCurrentLocation,
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.edit_outlined, color: AppColors.neutral600),
                            title: Text(context.tr('wizard.wizardLocationEnterManually')),
                            onTap: _enterManually,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormView(BuildContext context) {
    final cubit = context.watch<ListingWizardCubit>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => _switchView(false),
                icon: const Icon(Icons.arrow_back),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('wizard.wizardLocationStepTitle'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            context.tr('wizard.wizardLocationSearchDescription'),
            style: const TextStyle(fontSize: 14, color: AppColors.neutral600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: context.tr('wizard.wizardLocationSearchTypingHint'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.neutral300),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
          ),
          _buildPredictionsList(),
          _buildResolvingRow(),
          const SizedBox(height: 24),
          Text(
            context.tr('wizard.wizardLocationOrEnterManually'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.charcoal),
          ),
          const SizedBox(height: 16),

          _buildLabel(context.tr('wizard.wizardLocationCountryLabel')),
          _buildDropdown(_selectedCountryId, context.tr('wizard.wizardLocationSelectCountry'), _countries, (v) {
            setState(() {
              _selectedCountryId = v;
              _selectedStateId = null;
              _selectedCityId = null;
              _selectedVillageId = null;
              _states = [];
              _cities = [];
              _villages = [];
            });
            // Blank the downstream ids so the previous state/city/village can't
            // persist under the new country (web parity; empty string clears).
            cubit.updateStepData({
              'country': v,
              'stateProvince': '',
              'city': '',
              'village': '',
            });
            if (v != null) _loadStates(v);
          }),
          
          if (_states.isNotEmpty) ...[
            _buildLabel(context.tr('wizard.wizardLocationStateLabel')),
            _buildDropdown(_selectedStateId, context.tr('wizard.wizardLocationSelectState'), _states, (v) {
              setState(() {
                _selectedStateId = v;
                _selectedCityId = null;
                _selectedVillageId = null;
                _cities = [];
                _villages = [];
              });
              cubit.updateStepData({
                'stateProvince': v,
                'city': '',
                'village': '',
              });
              if (v != null) _loadCities(v);
            }),
          ],

          if (_cities.isNotEmpty) ...[
            _buildLabel(context.tr('wizard.wizardLocationDistrictLabel')),
            _buildDropdown(_selectedCityId, context.tr('wizard.wizardLocationSelectDistrict'), _cities, (v) {
              setState(() {
                _selectedCityId = v;
                _selectedVillageId = null;
                _villages = [];
              });
              cubit.updateStepData({'city': v, 'village': ''});
              if (v != null) _loadVillages(v);
            }),
          ],

          if (_villages.isNotEmpty) ...[
            _buildLabel(context.tr('wizard.wizardLocationNeighborhoodLabel')),
            _buildDropdown(_selectedVillageId, context.tr('wizard.wizardLocationSelectNeighborhood'), _villages, (v) {
              setState(() => _selectedVillageId = v);
              cubit.updateStepData({'village': v});
            }),
          ],

          _buildLabel(context.tr('wizard.wizardLocationAreaLabel')),
          TextField(
            controller: _areaController,
            decoration: _inputDecoration(context.tr('wizard.wizardLocationAreaHint')),
            onChanged: (v) => cubit.updateStepData({'district': v}),
          ),
          const SizedBox(height: 16),

          _buildLabel(context.tr('wizard.wizardLocationStreetLabel')),
          TextField(
            controller: _addressController,
            decoration: _inputDecoration(context.tr('wizard.wizardLocationStreetHint')),
            onChanged: (v) => cubit.updateStepData({'address': v}),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel(context.tr('wizard.wizardLocationBuildingLabel')),
                    TextField(
                      controller: _buildingController,
                      decoration: _inputDecoration(context.tr('wizard.wizardLocationBuildingHint')),
                      onChanged: (v) => cubit.updateStepData({'buildingNumber': v}),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel(context.tr('wizard.wizardLocationFloorLabel')),
                    TextField(
                      controller: _floorController,
                      decoration: _inputDecoration(context.tr('wizard.wizardLocationFloorHint')),
                      onChanged: (v) => cubit.updateStepData({'floorNumber': v}),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel(context.tr('wizard.wizardLocationUnitLabel')),
                    TextField(
                      controller: _unitController,
                      decoration: _inputDecoration(context.tr('wizard.wizardLocationUnitHint')),
                      onChanged: (v) => cubit.updateStepData({'unitNumber': v}),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildLabel(context.tr('wizard.wizardLocationPostalLabel')),
          TextField(
            controller: _postalController,
            decoration: _inputDecoration(context.tr('wizard.wizardLocationPostalHint')),
            onChanged: (v) => cubit.updateStepData({'postalCode': v}),
          ),
          const SizedBox(height: 24),
          
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 18, color: AppColors.neutral600),
              const SizedBox(width: 8),
              Text(
                context.tr('wizard.wizardLocationConfirmOnMap'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.charcoal),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('wizard.wizardLocationMapHelper'),
            style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.ghostWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.neutral300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    cubit.state.data.latitude ?? _currentLocation.latitude,
                    cubit.state.data.longitude ?? _currentLocation.longitude,
                  ),
                  zoom: 15,
                ),
                onMapCreated: (controller) => _mapController = controller,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
                onTap: (loc) {
                  setState(() => _currentLocation = loc);
                  cubit.updateStepData({
                    'latitude': loc.latitude,
                    'longitude': loc.longitude,
                  });
                },
                markers: {
                  Marker(
                    markerId: const MarkerId('selected_location'),
                    position: LatLng(
                      cubit.state.data.latitude ?? _currentLocation.latitude,
                      cubit.state.data.longitude ?? _currentLocation.longitude,
                    ),
                    draggable: true,
                    onDragEnd: (newPosition) {
                      setState(() => _currentLocation = newPosition);
                      cubit.updateStepData({
                        'latitude': newPosition.latitude,
                        'longitude': newPosition.longitude,
                      });
                    },
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  ),
                },
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// The dropdown of address suggestions shown under the search field. Renders
  /// nothing when there are no predictions.
  Widget _buildPredictionsList() {
    if (_predictions.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _predictions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final p = _predictions[index];
          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: const Icon(Icons.location_on_outlined,
                size: 20, color: AppColors.neutral600),
            title: Text(
              p.mainText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
            subtitle: p.secondaryText.isNotEmpty
                ? Text(
                    p.secondaryText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.neutral500),
                  )
                : null,
            onTap: () => _onPredictionSelected(p),
          );
        },
      ),
    );
  }

  /// A small inline "getting details…" indicator shown while the selected
  /// place's details are being fetched and the form is being filled.
  Widget _buildResolvingRow() {
    if (!_isResolving) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            context.tr('wizard.wizardLocationResolving'),
            style: const TextStyle(fontSize: 13, color: AppColors.neutral600),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.charcoal),
      ),
    );
  }

  Widget _buildDropdown(String? value, String hint, List<Map<String, dynamic>> items, ValueChanged<String?> onChanged) {
    // If the list changed and doesn't contain the previously selected value, it should be null.
    // The state resetting logic handles this mostly, but to be absolutely safe:
    final bool valueExists = value == null || items.any((item) => item['id'] == value);
    final safeValue = valueExists ? value : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        initialValue: safeValue,
        hint: Text(hint, style: const TextStyle(color: AppColors.neutral500)),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.neutral300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.neutral300),
          ),
        ),
        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.neutral600),
        items: items.map((e) => DropdownMenuItem<String>(value: e['id'] as String, child: Text(e['name'] as String))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.neutral400, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.neutral300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.neutral300),
      ),
    );
  }
}
