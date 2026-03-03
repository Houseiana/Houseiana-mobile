import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({super.key});

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  bool _isMapView = true;
  final TextEditingController _searchController = TextEditingController(text: 'Doha, Qatar');

  final List<Map<String, dynamic>> _properties = [
    {
      'id': '1',
      'name': 'Luxury Villa West Bay',
      'rating': 4.92,
      'price': 250,
      'isFavorite': true,
      'image': 'https://images.unsplash.com/photo-1711110065918-388182f86e00?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxsdXh1cnklMjB2aWxsYSUyMGV4dGVyaW9yJTIwcG9vbHxlbnwxfHx8fDE3NzIzMjM1Mzd8MA&ixlib=rb-4.1.0&q=80&w=400',
      'mapTop': 80.0,
      'mapLeft': 160.0,
    },
    {
      'id': '2',
      'name': 'Modern Studio - The Pearl',
      'rating': 4.78,
      'price': 120,
      'isFavorite': false,
      'image': 'https://images.unsplash.com/photo-1594873604892-b599f847e859?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxtb2Rlcm4lMjBhcGFydG1lbnQlMjBpbnRlcmlvcnxlbnwxfHx8fDE3NzIyMzcwMTV8MA&ixlib=rb-4.1.0&q=80&w=400',
      'mapTop': 40.0,
      'mapLeft': 60.0,
    },
    {
      'id': '3',
      'name': 'Beachfront Apartment',
      'rating': 4.85,
      'price': 185,
      'isFavorite': false,
      'image': 'https://images.unsplash.com/photo-1627141234469-24711efb373c?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjb250ZW1wb3JhcnklMjBob3VzZSUyMGFyY2hpdGVjdHVyZXxlbnwxfHx8fDE3NzIzMjM1Mzd8MA&ixlib=rb-4.1.0&q=80&w=400',
      'mapTop': 120.0,
      'mapLeft': 248.69,
    },
    {
      'id': '4',
      'name': 'Downtown Penthouse',
      'rating': 4.65,
      'price': 95,
      'isFavorite': false,
      'image': 'https://images.unsplash.com/photo-1568115286680-d203e08a8be6?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxwZW50aG91c2UlMjBjaXR5JTIwdmlld3xlbnwxfHx8fDE3NzIyODU5MDh8MA&ixlib=rb-4.1.0&q=80&w=400',
      'mapTop': 160.0,
      'mapLeft': 100.0,
    },
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
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            _buildSearchBar(),

            // Map or List View
            Expanded(
              child: _isMapView ? _buildMapView() : _buildListOnlyView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // Search Input
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9FA),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 16, right: 8),
                    child: Icon(Icons.search, size: 16, color: Color(0xFF9CA3AF)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Search location...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Filter Button
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1D242B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.tune, size: 18, color: Colors.white),
              onPressed: () {
                // TODO: Show filter dialog
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Column(
      children: [
        // Map Container
        Container(
          height: 240,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE8F4F3), Color(0xFFD4EBE8)],
            ),
          ),
          child: Stack(
            children: [
              // Map Markers
              ..._properties.map((property) => _buildMapMarker(
                top: property['mapTop'] as double,
                left: property['mapLeft'] as double,
                price: property['price'] as int,
                isFeatured: property['isFavorite'] as bool,
              )),

              // List/Map Toggle Button
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: _buildToggleButton(),
                ),
              ),
            ],
          ),
        ),

        // Properties List
        Expanded(
          child: _buildPropertiesList(),
        ),
      ],
    );
  }

  Widget _buildListOnlyView() {
    return _buildPropertiesList();
  }

  Widget _buildMapMarker({
    required double top,
    required double left,
    required int price,
    bool isFeatured = false,
  }) {
    return Positioned(
      top: top,
      left: left,
      child: Column(
        children: [
          // Price Label
          Container(
            height: 22,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isFeatured ? const Color(0xFF1D242B) : AppColors.primaryColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '\$$price',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isFeatured ? Colors.white : const Color(0xFF1D242B),
              ),
            ),
          ),
          // Pointer Triangle
          CustomPaint(
            size: const Size(8, 8),
            painter: TrianglePainter(
              color: isFeatured ? const Color(0xFF1D242B) : AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isMapView = !_isMapView;
        });
      },
      child: Container(
        height: 27,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          _isMapView ? 'List' : 'Map',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF000000),
          ),
        ),
      ),
    );
  }

  Widget _buildPropertiesList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Section Title
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_properties.length} Properties Found',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF000000),
                  ),
                ),
              ],
            ),
          ),

          // Property Cards List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              itemCount: _properties.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final property = _properties[index];
                return _buildPropertyCard(
                  name: property['name'] as String,
                  rating: property['rating'] as double,
                  price: property['price'] as int,
                  isFavorite: property['isFavorite'] as bool,
                  imageUrl: property['image'] as String,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard({
    required String name,
    required double rating,
    required int price,
    required bool isFavorite,
    required String imageUrl,
  }) {
    return Container(
      height: 102,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Property Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              width: 90,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 90,
                  height: 80,
                  color: isFavorite ? const Color(0xFFE5E5E5) : const Color(0xFFE0E0E0),
                );
              },
            ),
          ),
          const SizedBox(width: 12),

          // Property Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Guest Favorite Badge
                if (isFavorite)
                  Container(
                    height: 14,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D242B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Guest Favorite',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),

                if (isFavorite) const SizedBox(height: 0),

                // Property Name
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF000000),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),

                // Rating
                Row(
                  children: [
                    const Icon(Icons.star, size: 10, color: Color(0xFFFCC519)),
                    const SizedBox(width: 4),
                    Text(
                      rating.toString(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF000000),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Price
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF000000),
                    ),
                    children: [
                      TextSpan(text: '\$$price '),
                      const TextSpan(
                        text: '/night',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Triangle Pointer
class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
