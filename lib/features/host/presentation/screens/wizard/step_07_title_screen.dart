import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/features/host/cubit/listing_wizard_cubit.dart' hide sl;
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/network/api/end_points.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class Step07TitleScreen extends StatefulWidget {
  const Step07TitleScreen({super.key});

  @override
  State<Step07TitleScreen> createState() => _Step07TitleScreenState();
}

class _Step07TitleScreenState extends State<Step07TitleScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  bool _isLoadingHighlights = true;
  List<Map<String, dynamic>> _highlightsLookup = [];

  // Mock highlights for Skeletonizer
  static const _mockHighlights = [
    {'id': 1, 'name': 'Beachfront'},
    {'id': 2, 'name': 'Modern'},
    {'id': 3, 'name': 'Spacious'},
    {'id': 4, 'name': 'Quiet'},
  ];

  @override
  void initState() {
    super.initState();
    final data = context.read<ListingWizardCubit>().state.data;
    _titleController = TextEditingController(text: data.title ?? '');
    _descriptionController = TextEditingController(text: data.description ?? '');
    _loadHighlights();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadHighlights() async {
    try {
      final api = sl<ApiConsumer>();
      final response = await api.get(EndPoints.propertyHighlightsLookup);

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
        final List<Map<String, dynamic>> loadedHighlights = raw.map((item) {
          return {
            'id': item['id'] as int? ?? 0,
            'name': item['name']?.toString() ?? 'Unknown',
          };
        }).toList();

        if (mounted) {
          setState(() {
            _highlightsLookup = loadedHighlights;
            _isLoadingHighlights = false;
          });
        }
      } else {
        throw Exception('Invalid data format');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingHighlights = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ListingWizardCubit>();
    final selectedHighlights = cubit.state.data.highlights.toSet();
    final displayHighlights = _isLoadingHighlights ? _mockHighlights : _highlightsLookup;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Section
          _buildSectionHeader(context.tr('wizard.givePropertyTitle')),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _titleController,
            hint: context.tr('wizard.titleHint'),
            maxLength: 32,
            maxLines: 2,
            onChanged: (v) => cubit.updateStepData({'title': v}),
          ),
          const SizedBox(height: 32),

          // Description Section
          _buildSectionHeader(context.tr('wizard.describeProperty')),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _descriptionController,
            hint: context.tr('wizard.descHint'),
            maxLength: 500,
            maxLines: 5,
            onChanged: (v) => cubit.updateStepData({'description': v}),
          ),
          const SizedBox(height: 32),

          // Highlights Section
          _buildSectionHeader(context.tr('wizard.chooseHighlights')),
          const SizedBox(height: 8),
          Text(
            context.tr('wizard.selectHighlightsDesc'),
            style: const TextStyle(fontSize: 14, color: AppColors.neutral600),
          ),
          const SizedBox(height: 16),
          Skeletonizer(
            enabled: _isLoadingHighlights,
            containersColor: AppColors.skeletonBaseColor,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: displayHighlights.map((h) {
                final id = h['id'] as int;
                final name = h['name'] as String;
                final isSelected = !_isLoadingHighlights && selectedHighlights.contains(id);

                return ChoiceChip(
                  label: Text(
                    name,
                    style: TextStyle(
                      color: isSelected ? AppColors.charcoal : AppColors.charcoal,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: _isLoadingHighlights
                      ? null
                      : (v) {
                          final updated = Set<int>.from(selectedHighlights);
                          if (v) {
                            updated.add(id);
                          } else {
                            updated.remove(id);
                          }
                          cubit.updateStepData({'highlights': updated.toList()});
                        },
                  backgroundColor: Colors.white,
                  selectedColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? AppColors.primaryColor : const Color(0xFFE5E9EE),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  showCheckmark: false,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF2F3A45),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required int maxLength,
    required int maxLines,
    required Function(String) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLength: maxLength,
        maxLines: maxLines,
        onChanged: (v) {
          // Replace multiple spaces with a single space as in web
          final cleaned = v.replaceAll(RegExp(r'\s{2,}'), ' ');
          if (cleaned != v) {
            controller.value = controller.value.copyWith(
              text: cleaned,
              selection: TextSelection.collapsed(offset: cleaned.length),
            );
            onChanged(cleaned);
          } else {
            onChanged(v);
          }
        },
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF1D242B),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFD2D2D2)),
          contentPadding: const EdgeInsets.all(20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
          ),
          counterStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2F3A45),
          ),
        ),
      ),
    );
  }
}
