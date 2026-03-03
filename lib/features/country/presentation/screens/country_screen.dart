import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';

class CountryScreen extends StatefulWidget {
  const CountryScreen({super.key});

  @override
  State<CountryScreen> createState() => _CountryScreenState();
}

class _CountryScreenState extends State<CountryScreen> {
  String _selectedRegion = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static const _regions = [
    'All',
    'Middle East',
    'Africa',
    'Europe',
    'Americas',
    'Asia',
  ];

  static const _countries = [
    // ── Middle East ─────────────────────────────────────────────────────────
    {
      'name': 'UAE', 'region': 'Middle East', 'properties': 312,
      // Burj Khalifa dominates the Dubai skyline
      'image': 'https://images.unsplash.com/photo-9n7rZJLWY7o?w=400&q=80', 'flag': '🇦🇪',
      'cities': [
        // Dubai – Burj Khalifa at night
        {'name': 'Dubai',     'properties': '210', 'image': 'https://images.unsplash.com/photo-9n7rZJLWY7o?w=400&q=80'},
        // Abu Dhabi – Sheikh Zayed Grand Mosque
        {'name': 'Abu Dhabi', 'properties': '102', 'image': 'https://images.unsplash.com/photo-YtVsAUt5ubs?w=400&q=80'},
      ],
    },
    {
      'name': 'Qatar', 'region': 'Middle East', 'properties': 124,
      // Doha Corniche skyline across the water
      'image': 'https://images.unsplash.com/photo-KUpxfPfQ_-E?w=400&q=80', 'flag': '🇶🇦',
      'cities': [
        {'name': 'Doha',      'properties': '105', 'image': 'https://images.unsplash.com/photo-KUpxfPfQ_-E?w=400&q=80'},
        {'name': 'Al Wakrah', 'properties': '19',  'image': 'https://images.unsplash.com/photo-ywwvpkaGO1M?w=400&q=80'},
      ],
    },
    {
      'name': 'KSA', 'region': 'Middle East', 'properties': 98,
      // Kingdom Tower (Al Mamlaka) – Riyadh landmark
      'image': 'https://images.unsplash.com/photo-Pb7pUEEHqAk?w=400&q=80', 'flag': '🇸🇦',
      'cities': [
        {'name': 'Riyadh', 'properties': '54', 'image': 'https://images.unsplash.com/photo-Pb7pUEEHqAk?w=400&q=80'},
        // Jeddah – Al Faisaliah / corniche
        {'name': 'Jeddah', 'properties': '31', 'image': 'https://images.unsplash.com/photo-HKWbVK1AQys?w=400&q=80'},
        // Mecca – Masjid Al-Haram / Kaaba
        {'name': 'Mecca',  'properties': '13', 'image': 'https://images.unsplash.com/photo-aB-X4OukMo8?w=400&q=80'},
      ],
    },
    {
      'name': 'Bahrain', 'region': 'Middle East', 'properties': 41,
      // Bahrain World Trade Center / Manama skyline
      'image': 'https://images.unsplash.com/photo-1578895101408-1a36b834405b?w=400&q=80', 'flag': '🇧🇭',
      'cities': [
        {'name': 'Manama', 'properties': '28', 'image': 'https://images.unsplash.com/photo-1578895101408-1a36b834405b?w=400&q=80'},
        {'name': 'Riffa',  'properties': '13', 'image': 'https://images.unsplash.com/photo-R_sXKrvL9bM?w=400&q=80'},
      ],
    },
    {
      'name': 'Turkey', 'region': 'Middle East', 'properties': 210,
      // Hagia Sophia & Sultan Ahmed Mosque (Blue Mosque) – Istanbul
      'image': 'https://images.unsplash.com/photo-_63Z9xUczLU?w=400&q=80', 'flag': '🇹🇷',
      'cities': [
        {'name': 'Istanbul', 'properties': '120', 'image': 'https://images.unsplash.com/photo-_63Z9xUczLU?w=400&q=80'},
        // Antalya – coastal cliffs & old harbour
        {'name': 'Antalya',  'properties': '57',  'image': 'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?w=400&q=80'},
        // Ankara – Ataturk Mausoleum (Anitkabir)
        {'name': 'Ankara',   'properties': '33',  'image': 'https://images.unsplash.com/photo-BJPAlIHRYyQ?w=400&q=80'},
      ],
    },

    // ── Africa ─────────────────────────────────────────────────────────────
    {
      'name': 'Egypt', 'region': 'Africa', 'properties': 143,
      // Aerial view of the Great Pyramids of Giza
      'image': 'https://images.unsplash.com/photo-rxv2qwYPe6s?w=400&q=80', 'flag': '🇪🇬',
      'cities': [
        // Cairo – Pyramids of Giza
        {'name': 'Cairo',          'properties': '72', 'image': 'https://images.unsplash.com/photo-rxv2qwYPe6s?w=400&q=80'},
        // Alexandria – Mediterranean waterfront
        {'name': 'Alexandria',     'properties': '31', 'image': 'https://images.unsplash.com/photo-1k7JC31SRyI?w=400&q=80'},
        // Hurghada – Red Sea coast
        {'name': 'Hurghada',       'properties': '25', 'image': 'https://images.unsplash.com/photo-PIXKiwf7iQA?w=400&q=80'},
        // Sharm El-Sheikh – Red Sea resort
        {'name': 'Sharm El-Sheikh','properties': '15', 'image': 'https://images.unsplash.com/photo-t3Xgc1q7N9g?w=400&q=80'},
      ],
    },

    // ── Europe ──────────────────────────────────────────────────────────────
    {
      'name': 'UK', 'region': 'Europe', 'properties': 386,
      // Big Ben, London
      'image': 'https://images.unsplash.com/photo-MdJq0zFUwrw?w=400&q=80', 'flag': '🇬🇧',
      'cities': [
        {'name': 'London',     'properties': '220', 'image': 'https://images.unsplash.com/photo-MdJq0zFUwrw?w=400&q=80'},
        // Manchester – city centre
        {'name': 'Manchester', 'properties': '94',  'image': 'https://images.unsplash.com/photo-1520986606214-8b456906c813?w=400&q=80'},
        // Edinburgh – castle skyline
        {'name': 'Edinburgh',  'properties': '72',  'image': 'https://images.unsplash.com/photo-1575919220112-29c81b1cee61?w=400&q=80'},
      ],
    },

    // ── Americas ────────────────────────────────────────────────────────────
    {
      'name': 'Canada', 'region': 'Americas', 'properties': 231,
      // CN Tower, Toronto
      'image': 'https://images.unsplash.com/photo-lw4Zhg5KGsI?w=400&q=80', 'flag': '🇨🇦',
      'cities': [
        {'name': 'Toronto',   'properties': '98',  'image': 'https://images.unsplash.com/photo-lw4Zhg5KGsI?w=400&q=80'},
        // Vancouver – mountains & harbour
        {'name': 'Vancouver', 'properties': '87',  'image': 'https://images.unsplash.com/photo-1560814304-4f05b62af116?w=400&q=80'},
        // Montreal – Old Port / Notre-Dame Basilica
        {'name': 'Montreal',  'properties': '46',  'image': 'https://images.unsplash.com/photo-1519098901909-b1553a1190af?w=400&q=80'},
      ],
    },

    // ── Asia ────────────────────────────────────────────────────────────────
    {
      'name': 'India', 'region': 'Asia', 'properties': 241,
      // Taj Mahal, Agra
      'image': 'https://images.unsplash.com/photo-e22GaIs1VuU?w=400&q=80', 'flag': '🇮🇳',
      'cities': [
        // Mumbai – Marine Drive / skyline
        {'name': 'Mumbai',    'properties': '94',  'image': 'https://images.unsplash.com/photo-1570168007204-dfb528c6958f?w=400&q=80'},
        // New Delhi – India Gate
        {'name': 'New Delhi', 'properties': '82',  'image': 'https://images.unsplash.com/photo-1524492412937-b28074a5d7da?w=400&q=80'},
        // Bangalore – Lalbagh / tech hub
        {'name': 'Bangalore', 'properties': '65',  'image': 'https://images.unsplash.com/photo-1596178065887-1198b6148b2b?w=400&q=80'},
      ],
    },
    {
      'name': 'Pakistan', 'region': 'Asia', 'properties': 87,
      // Faisal Mosque, Islamabad
      'image': 'https://images.unsplash.com/photo-P6ehGEKSOgo?w=400&q=80', 'flag': '🇵🇰',
      'cities': [
        // Karachi – sea view / skyline
        {'name': 'Karachi',   'properties': '38',  'image': 'https://images.unsplash.com/photo-1558618047-3b38c4e2c5d9?w=400&q=80'},
        // Lahore – Badshahi Mosque
        {'name': 'Lahore',    'properties': '31',  'image': 'https://images.unsplash.com/photo-1617897903246-719242758050?w=400&q=80'},
        // Islamabad – Faisal Mosque
        {'name': 'Islamabad', 'properties': '18',  'image': 'https://images.unsplash.com/photo-P6ehGEKSOgo?w=400&q=80'},
      ],
    },
    {
      'name': 'Thailand', 'region': 'Asia', 'properties': 231,
      // Wat Arun temple on the Chao Phraya, Bangkok
      'image': 'https://images.unsplash.com/photo-wd3tQvk0WXA?w=400&q=80', 'flag': '🇹🇭',
      'cities': [
        {'name': 'Bangkok',    'properties': '102', 'image': 'https://images.unsplash.com/photo-wd3tQvk0WXA?w=400&q=80'},
        // Phuket – Patong Beach / Phi Phi Islands
        {'name': 'Phuket',     'properties': '89',  'image': 'https://images.unsplash.com/photo-1537956965359-7573183d1f57?w=400&q=80'},
        // Chiang Mai – temples & mountains
        {'name': 'Chiang Mai', 'properties': '40',  'image': 'https://images.unsplash.com/photo-1512100356356-de1b84283e18?w=400&q=80'},
      ],
    },
    {
      'name': 'Indonesia', 'region': 'Asia', 'properties': 187,
      // Tegalalang rice terraces, Bali
      'image': 'https://images.unsplash.com/photo--2WlTWZLnRc?w=400&q=80', 'flag': '🇮🇩',
      'cities': [
        {'name': 'Bali',    'properties': '134', 'image': 'https://images.unsplash.com/photo--2WlTWZLnRc?w=400&q=80'},
        // Jakarta – Monas monument / skyline
        {'name': 'Jakarta', 'properties': '53',  'image': 'https://images.unsplash.com/photo-1555899434-94d1368aa7af?w=400&q=80'},
      ],
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    var list = List<Map<String, dynamic>>.from(_countries);
    if (_selectedRegion != 'All') {
      list = list.where((c) => c['region'] == _selectedRegion).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((c) => (c['name'] as String)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Country',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D242B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${filtered.length} destination${filtered.length == 1 ? '' : 's'} found',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Search bar
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search country...',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9CA3AF),
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF9CA3AF),
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: const Icon(
                                Icons.close,
                                color: Color(0xFF9CA3AF),
                                size: 18,
                              ),
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primaryColor, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Region filter chips
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _regions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final region = _regions[i];
                        final selected = _selectedRegion == region;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedRegion = region),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 7),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF1D242B)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFF1D242B)
                                    : const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Text(
                              region,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Country grid  / empty state
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off,
                              size: 56, color: Color(0xFFD1D5DB)),
                          const SizedBox(height: 16),
                          Text(
                            'No country found for\n"$_searchQuery"',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) =>
                          _CountryCard(country: filtered[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountryCard extends StatelessWidget {
  final Map<String, dynamic> country;
  const _CountryCard({required this.country});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          Routes.cityList,
          arguments: {
            'countryName': country['name'],
            'countryFlag': country['flag'],
            'cities': country['cities'],
          },
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      country['image'] as String,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.neutral200,
                        child: const Icon(Icons.public,
                            size: 40, color: AppColors.neutral400),
                      ),
                    ),
                    // Flag badge
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          country['flag'] as String,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Info
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    country['name'] as String,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D242B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.home_outlined,
                          size: 12, color: Color(0xFF6B7280)),
                      const SizedBox(width: 4),
                      Text(
                        '${country['properties']} properties',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right,
                          size: 14, color: Color(0xFF9CA3AF)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
