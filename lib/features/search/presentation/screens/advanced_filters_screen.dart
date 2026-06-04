import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  /// Price filter operates in EGP and opens up to this nightly ceiling.
  static const double _maxPriceLimit = 200000;
  static const RangeValues _defaultPriceRange =
      RangeValues(0, _maxPriceLimit);

  final NumberFormat _priceFormatter = NumberFormat('#,##0');

  RangeValues _priceRange = _defaultPriceRange;
  int _bedrooms = 0;
  int _beds = 0;
  int _bathrooms = 0;
  final List<String> _selectedAmenities = [];
  bool _lookupsLoading = true;
  bool _lookupsFailed = false;

  String _formatPrice(double value) =>
      'EGP ${_priceFormatter.format(value.toInt())}';

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
      final response = await api.get(EndPoints.amenitiesLookup);
      final amenities = _extractLookupNames(response);
      if (!mounted) return;
      setState(() {
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
                _priceRange = _defaultPriceRange;
                _bedrooms = 0;
                _beds = 0;
                _bathrooms = 0;
                _selectedAmenities.clear();
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
                      _formatPrice(_priceRange.start),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.neutral600,
                      ),
                    ),
                    Text(
                      _priceRange.end >= _maxPriceLimit
                          ? '${_formatPrice(_priceRange.end)}+'
                          : _formatPrice(_priceRange.end),
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
                  max: _maxPriceLimit,
                  divisions: 40,
                  activeColor: AppColors.primaryColor,
                  labels: RangeLabels(
                    _formatPrice(_priceRange.start),
                    _priceRange.end >= _maxPriceLimit
                        ? '${_formatPrice(_priceRange.end)}+'
                        : _formatPrice(_priceRange.end),
                  ),
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

                // Beds
                Text(
                  context.tr('filters.beds'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 16),
                _buildCounter(_beds, (val) {
                  setState(() => _beds = val);
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
                if (_lookupsLoading || _lookupsFailed) ...[
                  _buildLookupStatus(),
                  const SizedBox(height: 24),
                ],

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
                    'beds': _beds,
                    'bathrooms': _bathrooms,
                    'amenities': _selectedAmenities,
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
