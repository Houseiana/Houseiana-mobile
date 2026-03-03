import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';

class AmenitiesScreen extends StatelessWidget {
  final List<AmenityCategory> categories;

  const AmenitiesScreen({
    super.key,
    required this.categories,
  });

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
          'Amenities',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(height: 32),
        itemBuilder: (context, index) {
          return _buildCategory(categories[index]);
        },
      ),
    );
  }

  Widget _buildCategory(AmenityCategory category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Title
        Text(
          category.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 16),

        // Amenities List
        ...category.amenities.map((amenity) => _buildAmenityItem(amenity)),
      ],
    );
  }

  Widget _buildAmenityItem(Amenity amenity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.ghostWhite,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              amenity.icon,
              size: 20,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(width: 16),

          // Amenity Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  amenity.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.charcoal,
                  ),
                ),
                if (amenity.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    amenity.description!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Available/Unavailable Indicator
          if (!amenity.isAvailable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Not available',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AmenityCategory {
  final String title;
  final List<Amenity> amenities;

  AmenityCategory({
    required this.title,
    required this.amenities,
  });
}

class Amenity {
  final String name;
  final String? description;
  final IconData icon;
  final bool isAvailable;

  Amenity({
    required this.name,
    this.description,
    required this.icon,
    this.isAvailable = true,
  });
}
