import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/features/host/cubit/listing_wizard_cubit.dart' hide sl;
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/network/api/end_points.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class Step05AmenitiesScreen extends StatefulWidget {
  const Step05AmenitiesScreen({super.key});

  @override
  State<Step05AmenitiesScreen> createState() => _Step05AmenitiesScreenState();
}

class _Step05AmenitiesScreenState extends State<Step05AmenitiesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _amenities = [];

  // Dummy amenities for Skeletonizer
  static const _mockAmenities = [
    {'id': 'mock1', 'name': 'Loading WiFi'},
    {'id': 'mock2', 'name': 'Loading Pool'},
    {'id': 'mock3', 'name': 'Loading Gym'},
    {'id': 'mock4', 'name': 'Loading Kitchen'},
    {'id': 'mock5', 'name': 'Loading TV'},
    {'id': 'mock6', 'name': 'Loading Parking'},
    {'id': 'mock7', 'name': 'Loading Dryer'},
  ];

  @override
  void initState() {
    super.initState();
    _loadAmenities();
  }

  Future<void> _loadAmenities() async {
    try {
      final api = sl<ApiConsumer>();
      final response = await api.get(EndPoints.amenitiesLookup);

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
        final List<Map<String, dynamic>> loadedAmenities = raw.map((item) {
          return {
            'id': item['id']?.toString() ?? '',
            'name': item['name']?.toString() ?? 'Unknown',
          };
        }).toList();

        if (mounted) {
          setState(() {
            _amenities = loadedAmenities;
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

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ListingWizardCubit>();
    final selected = cubit.state.data.amenities.toSet();

    final displayAmenities = _isLoading ? _mockAmenities : _amenities;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('wizard.whatAmenities'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('wizard.selectAllAmenities'),
            style: const TextStyle(fontSize: 15, color: AppColors.neutral600),
          ),
          const SizedBox(height: 32),
          Skeletonizer(
            enabled: _isLoading,
            containersColor: AppColors.skeletonBaseColor,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: displayAmenities.map((amenityMap) {
                final amenityId = amenityMap['id']!;
                final amenityName = amenityMap['name']!;
                final isSelected = !_isLoading && selected.contains(amenityId);

                return FilterChip(
                  label: Text(amenityName),
                  selected: isSelected,
                  onSelected: _isLoading
                      ? null
                      : (v) {
                          final updated = Set<String>.from(selected);
                          if (v) {
                            updated.add(amenityId);
                          } else {
                            updated.remove(amenityId);
                          }
                          cubit.updateStepData({'amenities': updated.toList()});
                        },
                  backgroundColor: Colors.white,
                  selectedColor: AppColors.primaryColor,
                  checkmarkColor: AppColors.charcoal,
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primaryColor
                        : const Color(0xFFE5E7EB),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
