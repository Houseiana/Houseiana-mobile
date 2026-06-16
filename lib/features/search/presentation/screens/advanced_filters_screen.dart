import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// Editable price boxes (min/max). Kept in sync with [_priceRange] in both
  /// directions so the user can either drag the slider or type an exact value,
  /// matching the web project's price filter.
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  /// Selected amenity IDs (as strings) — these are what the backend
  /// `amenities` filter expects, matching the web project's contract.
  final Set<String> _selectedAmenityIds = <String>{};
  bool _lookupsLoading = true;
  bool _lookupsFailed = false;

  String _formatPrice(double value) =>
      'EGP ${_priceFormatter.format(value.toInt())}';

  /// Amenities loaded from `/api/lookups/Amenities`. Each carries the `id`
  /// sent to the search API and the `name` shown to the user.
  List<_AmenityOption> _amenities = const [];

  @override
  void initState() {
    super.initState();
    _syncPriceFields();
    _loadLookups();
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  /// Pushes [_priceRange] into the two text fields. Min shows blank at the
  /// floor (0 = "any minimum"); max shows blank at the ceiling (= "any
  /// maximum"), mirroring the web inputs.
  void _syncPriceFields() {
    _minPriceController.text =
        _priceRange.start > 0 ? _priceRange.start.toInt().toString() : '';
    _maxPriceController.text = _priceRange.end < _maxPriceLimit
        ? _priceRange.end.toInt().toString()
        : '';
  }

  double _parsePrice(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    final parsed = double.tryParse(digits) ?? 0;
    return parsed.clamp(0, _maxPriceLimit).toDouble();
  }

  /// Live update while typing in the MIN box. Keeps the slider valid
  /// (start <= end) without rewriting the field being edited.
  void _onMinPriceChanged(String value) {
    final parsed = _parsePrice(value);
    setState(() {
      final start = parsed > _priceRange.end ? _priceRange.end : parsed;
      _priceRange = RangeValues(start, _priceRange.end);
    });
  }

  /// Live update while typing in the MAX box. An empty box means "no maximum"
  /// (the ceiling). Keeps end >= start so the slider stays valid.
  void _onMaxPriceChanged(String value) {
    final parsed =
        value.trim().isEmpty ? _maxPriceLimit : _parsePrice(value);
    setState(() {
      final end = parsed < _priceRange.start ? _priceRange.start : parsed;
      _priceRange = RangeValues(_priceRange.start, end);
    });
  }

  /// Normalizes the boxes once editing ends (keyboard "done" / focus loss),
  /// reflecting the clamped values back into both fields.
  void _commitPriceFields() => setState(_syncPriceFields);

  Future<void> _loadLookups() async {
    try {
      final api = sl<ApiConsumer>();
      final response = await api.get(EndPoints.amenitiesLookup);
      final amenities = _extractAmenities(response);
      if (!mounted) return;
      setState(() {
        _amenities = amenities;
        _lookupsLoading = false;
        _lookupsFailed = amenities.isEmpty;
        // Drop any selection that is no longer offered by the lookup.
        _selectedAmenityIds
            .removeWhere((id) => !amenities.any((a) => a.id == id));
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _lookupsLoading = false;
        _lookupsFailed = true;
      });
    }
  }

  /// Parses the amenities lookup into `{id, name}` options. The backend
  /// returns `[{ "id": 1, "name": "WiFi" }, ...]`; we keep the `id` because
  /// the search API filters by amenity ID, not by name.
  List<_AmenityOption> _extractAmenities(dynamic response) {
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
    if (raw is! List) return const [];

    final options = <_AmenityOption>[];
    final seenIds = <String>{};
    for (final item in raw) {
      if (item is! Map) continue;
      final id = (item['id'] ??
              item['amenityId'] ??
              item['value'] ??
              item['key'] ??
              '')
          .toString()
          .trim();
      final name = (item['name'] ??
              item['title'] ??
              item['label'] ??
              item['amenityName'] ??
              item['type'] ??
              '')
          .toString()
          .trim();
      if (id.isEmpty || name.isEmpty) continue;
      if (!seenIds.add(id)) continue;
      options.add(_AmenityOption(id: id, name: name));
    }
    return options;
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
                _selectedAmenityIds.clear();
                _syncPriceFields();
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
                RangeSlider(
                  values: _priceRange,
                  min: 0,
                  max: _maxPriceLimit,
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
                      _syncPriceFields();
                    });
                  },
                ),
                const SizedBox(height: 8),
                // Editable min/max boxes so the user can type an exact price
                // (e.g. 3000) instead of being limited to slider steps — the
                // same UX as the web filter.
                Row(
                  children: [
                    Expanded(
                      child: _buildPriceField(
                        label: context.tr('filters.minimum'),
                        controller: _minPriceController,
                        active: _priceRange.start > 0,
                        hint: '0',
                        onChanged: _onMinPriceChanged,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPriceField(
                        label: context.tr('filters.maximum'),
                        controller: _maxPriceController,
                        active: _priceRange.end < _maxPriceLimit,
                        hint: _priceFormatter.format(_maxPriceLimit.toInt()),
                        onChanged: _onMaxPriceChanged,
                      ),
                    ),
                  ],
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
                    final isSelected =
                        _selectedAmenityIds.contains(amenity.id);
                    return FilterChip(
                      label: Text(amenity.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedAmenityIds.add(amenity.id);
                          } else {
                            _selectedAmenityIds.remove(amenity.id);
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
                  _commitPriceFields();
                  Navigator.pop(context, {
                    // Null at the floor/ceiling means "no price filter", matching
                    // the web contract (minPrice only when > 0, maxPrice only when
                    // below the ceiling). `priceRange` is kept for completeness.
                    'minPrice':
                        _priceRange.start > 0 ? _priceRange.start : null,
                    'maxPrice': _priceRange.end < _maxPriceLimit
                        ? _priceRange.end
                        : null,
                    'priceRange': _priceRange,
                    'bedrooms': _bedrooms,
                    'beds': _beds,
                    'bathrooms': _bathrooms,
                    // Amenity IDs — consumed as the search API `amenities` filter.
                    'amenities': _selectedAmenityIds.toList(),
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

  Widget _buildPriceField({
    required String label,
    required TextEditingController controller,
    required bool active,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? AppColors.primaryColor.withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? AppColors.primaryColor : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.neutral600),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.done,
                  onChanged: onChanged,
                  onEditingComplete: _commitPriceFields,
                  onTapOutside: (_) {
                    FocusScope.of(context).unfocus();
                    _commitPriceFields();
                  },
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutral400,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'EGP',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal,
                ),
              ),
            ],
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

/// A selectable amenity from `/api/lookups/Amenities`: [id] is sent to the
/// search API, [name] is shown to the user.
class _AmenityOption {
  final String id;
  final String name;

  const _AmenityOption({required this.id, required this.name});
}
