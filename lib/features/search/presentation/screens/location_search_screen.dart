import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';

class LocationSearchScreen extends StatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final _searchController = TextEditingController();
  final List<Map<String, String>> _recentSearches = [
    {'name': 'Doha, Qatar', 'type': 'City'},
    {'name': 'West Bay, Doha', 'type': 'District'},
    {'name': 'The Pearl Qatar', 'type': 'Area'},
  ];

  final List<Map<String, String>> _popularDestinations = [
    {'name': 'Doha, Qatar', 'type': 'City'},
    {'name': 'West Bay', 'type': 'District'},
    {'name': 'The Pearl Qatar', 'type': 'Area'},
    {'name': 'Lusail City', 'type': 'City'},
    {'name': 'Al Wakrah', 'type': 'City'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          decoration: const InputDecoration(
            hintText: 'Search locations...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: AppColors.neutral400),
          ),
          style: const TextStyle(fontSize: 16),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Searches',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _recentSearches.clear());
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._recentSearches.map((location) => _buildLocationTile(location, isRecent: true)),
            const SizedBox(height: 32),
          ],
          const Text(
            'Popular Destinations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 16),
          ..._popularDestinations.map((location) => _buildLocationTile(location)),
        ],
      ),
    );
  }

  Widget _buildLocationTile(Map<String, String> location, {bool isRecent = false}) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.ghostWhite,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isRecent ? Icons.history : Icons.location_on_outlined,
          color: AppColors.charcoal,
          size: 20,
        ),
      ),
      title: Text(
        location['name']!,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.charcoal,
        ),
      ),
      subtitle: Text(
        location['type']!,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.neutral600,
        ),
      ),
      onTap: () {
        Navigator.pop(context, location['name']);
      },
    );
  }
}
