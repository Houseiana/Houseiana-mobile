import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';

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

  final List<String> _propertyTypes = [
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

  final List<String> _amenities = [
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
        title: const Text(
          'Filters',
          style: TextStyle(
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
              });
            },
            child: const Text(
              'Clear All',
              style: TextStyle(
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
                const Text(
                  'Price Range',
                  style: TextStyle(
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
                const Text(
                  'Bedrooms',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 16),
                _buildCounter('Bedrooms', _bedrooms, (val) {
                  setState(() => _bedrooms = val);
                }),

                const SizedBox(height: 24),

                // Bathrooms
                const Text(
                  'Bathrooms',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 16),
                _buildCounter('Bathrooms', _bathrooms, (val) {
                  setState(() => _bathrooms = val);
                }),

                const SizedBox(height: 32),

                // Property Type
                const Text(
                  'Property Type',
                  style: TextStyle(
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
                        color: isSelected ? AppColors.charcoal : AppColors.neutral600,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 32),

                // Amenities
                const Text(
                  'Amenities',
                  style: TextStyle(
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
                        color: isSelected ? AppColors.charcoal : AppColors.neutral600,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
                  color: Colors.black.withOpacity(0.08),
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
                child: const Text(
                  'Show Results',
                  style: TextStyle(
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

  Widget _buildCounter(String label, int value, Function(int) onChanged) {
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
            value == 0 ? 'Any' : value.toString(),
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
}
