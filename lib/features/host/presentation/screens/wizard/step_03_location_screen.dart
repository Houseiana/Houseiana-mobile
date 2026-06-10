import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/features/host/cubit/listing_wizard_cubit.dart' hide sl;
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/network/api/end_points.dart';
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
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      if (query.trim().isNotEmpty) {
        _performGeocodingSearch(query.trim());
      }
    });
  }

  Future<void> _performGeocodingSearch(String query) async {
    if (!mounted) return;
    setState(() {
      _isSearching = true;
    });
    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        String addressText = query;
        String postalCode = '';

        try {
          final placemarks = await placemarkFromCoordinates(loc.latitude, loc.longitude);
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            addressText = '${place.street ?? ''}, ${place.locality ?? ''}'.trim().replaceAll(RegExp(r'^,\s*'), '');
            if (addressText.isEmpty) {
              addressText = place.name ?? query;
            }
            postalCode = place.postalCode ?? '';
          }
        } catch (_) {
          // Fallback to query if reverse geocoding fails
        }

        if (mounted) {
          context.read<ListingWizardCubit>().updateStepData({
            'latitude': loc.latitude,
            'longitude': loc.longitude,
            'address': addressText,
          });
          
          setState(() {
            if (addressText.isNotEmpty) {
              _addressController.text = addressText;
            }
            _postalController.text = postalCode;
            _currentLocation = LatLng(loc.latitude, loc.longitude);
            _showForm = true;
          });
          _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation, 15));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('wizard.wizardLocationNoResults'))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('wizard.wizardLocationGeocodingError'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _useCurrentLocation() {
    setState(() {
      _showForm = true;
    });
  }

  void _enterManually() {
    setState(() {
      _showForm = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _showForm ? _buildFormView(context) : _buildMapView(context);
  }

  Widget _buildMapView(BuildContext context) {
    return Column(
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
        Expanded(
          child: Container(
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
                          context.read<ListingWizardCubit>().state.data.latitude ?? _currentLocation.latitude,
                          context.read<ListingWizardCubit>().state.data.longitude ?? _currentLocation.longitude,
                        ),
                        zoom: 12,
                      ),
                      onMapCreated: (controller) => _mapController = controller,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      onTap: (loc) {
                        setState(() {
                          _currentLocation = loc;
                          _showForm = true;
                        });
                        context.read<ListingWizardCubit>().updateStepData({
                          'latitude': loc.latitude,
                          'longitude': loc.longitude,
                        });
                      },
                      markers: {
                        if (context.read<ListingWizardCubit>().state.data.latitude != null)
                          Marker(
                            markerId: const MarkerId('selected'),
                            position: LatLng(
                              context.read<ListingWizardCubit>().state.data.latitude!,
                              context.read<ListingWizardCubit>().state.data.longitude!,
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
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
                onPressed: () {
                  setState(() => _showForm = false);
                },
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
            cubit.updateStepData({'country': v});
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
              cubit.updateStepData({'stateProvince': v});
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
              cubit.updateStepData({'city': v});
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
