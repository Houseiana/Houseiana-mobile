import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/features/host/cubit/listing_wizard_cubit.dart'
    hide sl;
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/network/api/end_points.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class Step01PropertyTypeScreen extends StatefulWidget {
  Step01PropertyTypeScreen({super.key});

  @override
  State<Step01PropertyTypeScreen> createState() =>
      _Step01PropertyTypeScreenState();
}

class _Step01PropertyTypeScreenState extends State<Step01PropertyTypeScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _propertyTypes = [];

  // Dummy types for Skeletonizer (placeholder name overridden at render time)
  static const _mockTypes = [
    {'id': 'mock1', 'name': '__loading__'},
    {'id': 'mock2', 'name': '__loading__'},
    {'id': 'mock3', 'name': '__loading__'},
    {'id': 'mock4', 'name': '__loading__'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPropertyTypes();
  }

  Future<void> _loadPropertyTypes() async {
    try {
      final api = sl<ApiConsumer>();
      final response = await api.get(EndPoints.propertyTypesLookup);

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

      if (raw is List) {
        final List<Map<String, dynamic>> loadedTypes = raw.map((item) {
          return {
            'id': item['id']?.toString() ?? '',
            'name': item['name']?.toString() ?? 'Unknown',
          };
        }).toList();

        if (mounted) {
          setState(() {
            _propertyTypes = loadedTypes;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Invalid data format');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Icon for a property type, keyed off the stable lookup `id` (1–13). The
  // backend localizes the `name` field (Arabic returns منزل / فيلا / …), so the
  // old name-substring matching found no English keyword in Arabic and returned
  // Icons.category for every card. Ids are language-independent, so the icon is
  // now correct in every locale — same pattern as the other lookup-id contracts
  // (payment method, host sort, amenities). Falls back to English-name matching
  // for any id the backend adds later.
  IconData _iconForType(Map<String, dynamic> type) {
    switch (type['id']?.toString()) {
      case '1':
        return Icons.apartment; // Apartment / Condo
      case '2':
        return Icons.house; // House
      case '3':
        return Icons.villa; // Villa
      case '4':
        return Icons.meeting_room; // Studio / Loft
      case '5':
        return Icons.home_work; // Townhouse
      case '6':
        return Icons.house_siding; // Guesthouse / Annex
      case '7':
        return Icons.apartment; // Serviced Apartment
      case '8':
        return Icons.hotel; // Aparthotel
      case '9':
        return Icons.cabin; // Cabin / Chalet
      case '10':
        return Icons.agriculture; // Farm Stay
      case '11':
        return Icons.sailing; // Houseboat
      case '12':
        return Icons.holiday_village; // Casa
      case '13':
        return Icons.category; // Other
    }
    return _iconForName(type['name']?.toString() ?? '');
  }

  IconData _iconForName(String typeName) {
    final lowerName = typeName.toLowerCase();
    if (lowerName.contains('apartment') || lowerName.contains('condo')) {
      return Icons.apartment;
    }
    if (lowerName.contains('houseboat')) return Icons.sailing;
    if (lowerName.contains('townhouse')) return Icons.home_work;
    // Check guesthouse/annex before the generic `house` match — otherwise
    // "Guesthouse" contains "house" and grabs the plain house icon.
    if (lowerName.contains('guesthouse') || lowerName.contains('annex')) {
      return Icons.house_siding;
    }
    if (lowerName.contains('house')) return Icons.house;
    if (lowerName.contains('villa')) return Icons.villa;
    if (lowerName.contains('studio') || lowerName.contains('loft')) {
      return Icons.meeting_room;
    }
    if (lowerName.contains('aparthotel')) return Icons.hotel;
    if (lowerName.contains('cabin') || lowerName.contains('chalet')) {
      return Icons.cabin;
    }
    if (lowerName.contains('farm')) return Icons.agriculture;
    if (lowerName.contains('casa')) return Icons.holiday_village;
    return Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ListingWizardCubit>();
    final currentType = cubit.state.data.propertyType;

    final displayTypes = _isLoading ? _mockTypes : _propertyTypes;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('wizard.whichBestDescribes'),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 32),
          Skeletonizer(
            enabled: _isLoading,
            containersColor: AppColors.skeletonBaseColor,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: displayTypes.length,
              itemBuilder: (context, index) {
                final type = displayTypes[index];
                final isSelected = !_isLoading && currentType == type['id'];
                final icon = _iconForType(type);

                return GestureDetector(
                  onTap: _isLoading
                      ? null
                      : () {
                          cubit.updateStepData({'propertyType': type['id']});
                        },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryColor
                            : AppColors.neutral200,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected
                          ? AppColors.primaryColor.withValues(alpha: 0.1)
                          : AppColors.cardBackground,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 40,
                          color: isSelected
                              ? AppColors.charcoal
                              : AppColors.neutral600,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          type['name'] == '__loading__'
                              ? context.tr('wizard.loading')
                              : type['name']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: AppColors.charcoal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
