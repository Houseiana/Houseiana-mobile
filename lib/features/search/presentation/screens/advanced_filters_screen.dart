import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/network/api/end_points.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class AdvancedFiltersScreen extends StatefulWidget {
  const AdvancedFiltersScreen({super.key});

  @override
  State<AdvancedFiltersScreen> createState() => _AdvancedFiltersScreenState();
}

class _AdvancedFiltersScreenState extends State<AdvancedFiltersScreen> {
  RangeValues _priceRange = const RangeValues(50, 500);
  int _bedrooms = 0;
  int _bathrooms = 0;
  String? _propertyType;
  final List<String> _selectedAmenities = [];
  double _minRating = 0;
  bool _lookupsLoading = true;
  bool _lookupsFailed = false;

  List<String> _propertyTypes = [
    'Apartment / Condo',
    'House',
    'Villa',
    'Studio / Loft',
    'Townhouse',
    'Guesthouse / Annex',
    'Serviced Apartment',
    'Aparthotel',
    'Cabin / Chalet',
    'Farm Stay',
    'Houseboat',
    'Casa',
    'Other',
  ];

  List<String> _amenities = [
    'WiFi',
    'Kitchen',
    'Washer',
    'Dryer',
    'Air Conditioning',
    'Heating',
    'Workspace',
    'TV',
    'Free Parking',
    'Pool',
    'Gym',
    'Hot Tub',
    'Security',
    'BBQ Grill',
    'Jacuzzi',
    'Private Garden',
    'RoofTop',
    'Swing',
    'Iron',
    'Hair Dryer',
    'Coffee Maker',
    'Microwave',
    'Dishwasher',
    'Elevator',
    'Balcony',
    'Fireplace',
    'Security System',
  ];

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    try {
      final api = sl<ApiConsumer>();
      final results = await Future.wait([
        api.get(EndPoints.propertyTypesLookup),
        api.get(EndPoints.amenitiesLookup),
      ]);
      final propertyTypes = _extractLookupNames(results[0]);
      final amenities = _extractLookupNames(results[1]);
      if (!mounted) return;
      setState(() {
        if (propertyTypes.isNotEmpty) _propertyTypes = propertyTypes;
        if (amenities.isNotEmpty) _amenities = amenities;
        _lookupsLoading = false;
        _lookupsFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _lookupsLoading = false;
        _lookupsFailed = true;
      });
    }
  }

  List<String> _extractLookupNames(dynamic response) {
    dynamic raw = response;
    if (raw is Map) raw = raw['data'] ?? raw['items'] ?? raw['result'] ?? raw;
    if (raw is Map) {
      raw = raw['items'] ??
          raw['data'] ??
          raw.values.firstWhere(
            (value) => value is List,
            orElse: () => [],
          );
    }
    if (raw is! List) return [];
    return raw
        .map((item) {
          if (item is String) return item;
          if (item is Map) {
            return (item['name'] ??
                    item['title'] ??
                    item['label'] ??
                    item['value'] ??
                    item['amenityName'] ??
                    item['type'] ??
                    '')
                .toString();
          }
          return '';
        })
        .where((name) => name.trim().isNotEmpty)
        .map((name) => name.trim())
        .toSet()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('filters.title'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _priceRange = const RangeValues(50, 500);
                _bedrooms = 0;
                _bathrooms = 0;
                _propertyType = null;
                _selectedAmenities.clear();
                _minRating = 0;
              });
            },
            child: Text(
              context.tr('common.clearAll'),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.charcoal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Price Range
                Text(
                  context.tr('filters.priceRange'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${_priceRange.start.toInt()}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.neutral600,
                      ),
                    ),
                    Text(
                      '\$${_priceRange.end.toInt()}+',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
                RangeSlider(
                  values: _priceRange,
                  min: 0,
                  max: 1000,
                  divisions: 20,
                  activeColor: AppColors.primaryColor,
                  onChanged: (values) {
                    setState(() {
                      _priceRange = values;
                    });
                  },
                ),

                const SizedBox(height: 32),

                // Bedrooms
                Text(
                  context.tr('filters.bedrooms'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 16),
                _buildCounter(_bedrooms, (val) {
                  setState(() => _bedrooms = val);
                }),

                const SizedBox(height: 24),

                // Bathrooms
                Text(
                  context.tr('filters.bathrooms'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 16),
                _buildCounter(_bathrooms, (val) {
                  setState(() => _bathrooms = val);
                }),

                const SizedBox(height: 32),

                // Minimum Rating
                Text(
                  context.tr('filters.minRating'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.star,
                          size: 18, color: AppColors.charcoal),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _minRating == 0
                                ? context.tr('filters.anyRating')
                                : '${_minRating.toStringAsFixed(1)}+',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.charcoal,
                            ),
                          ),
                          Slider(
                            value: _minRating,
                            min: 0,
                            max: 5,
                            divisions: 10,
                            activeColor: AppColors.primaryColor,
                            inactiveColor: AppColors.neutral200,
                            onChanged: (val) {
                              setState(() => _minRating = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                if (_lookupsLoading || _lookupsFailed) ...[
                  _buildLookupStatus(),
                  const SizedBox(height: 24),
                ],

                // Property Type
                Text(
                  context.tr('filters.propertyType'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _propertyTypes.map((type) {
                    final isSelected = _propertyType == type;
                    return FilterChip(
                      label: Text(type),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _propertyType = selected ? type : null;
                        });
                      },
                      selectedColor: AppColors.primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.charcoal
                            : AppColors.neutral600,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 32),

                // Amenities
                Text(
                  context.tr('filters.amenities'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _amenities.map((amenity) {
                    final isSelected = _selectedAmenities.contains(amenity);
                    return FilterChip(
                      label: Text(amenity),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedAmenities.add(amenity);
                          } else {
                            _selectedAmenities.remove(amenity);
                          }
                        });
                      },
                      selectedColor: AppColors.primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.charcoal
                            : AppColors.neutral600,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Apply Button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'priceRange': _priceRange,
                    'bedrooms': _bedrooms,
                    'bathrooms': _bathrooms,
                    'propertyType': _propertyType,
                    'amenities': _selectedAmenities,
                    'minRating': _minRating,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.charcoal,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  context.tr('filters.showResults'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounter(int value, Function(int) onChanged) {
    return Row(
      children: [
        IconButton(
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
          color: value > 0 ? AppColors.charcoal : AppColors.neutral400,
        ),
        Container(
          width: 60,
          alignment: Alignment.center,
          child: Text(
            value == 0 ? context.tr('filters.any') : value.toString(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
          ),
        ),
        IconButton(
          onPressed: () => onChanged(value + 1),
          icon: const Icon(Icons.add_circle_outline),
          color: AppColors.primaryColor,
        ),
      ],
    );
  }

  Widget _buildLookupStatus() {
    final icon = _lookupsLoading ? Icons.sync : Icons.info_outline;
    final text = _lookupsLoading
        ? context.tr('filters.loadingLookups')
        : context.tr('filters.lookupsFailed');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.neutral600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.neutral600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
