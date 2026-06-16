import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

/// Compact "Sort by" pill + bottom sheet shared by the property search results
/// screen and the Search-tab listing, so both sort the same way from one place.
///
/// Loads its options from `/api/Lookups/PropertySorting` (web parity), localizes
/// the known ids, and reports the chosen id (or null for the default ordering)
/// via [onChanged]. The caller owns the selected value ([selectedId]) and
/// re-runs its own search when it changes.
class PropertySortControl extends StatefulWidget {
  /// Currently selected PropertySorting id, or null for the default ordering.
  final String? selectedId;

  /// Called with the newly selected id (null = default) when the user picks a
  /// different option from the sheet.
  final ValueChanged<String?> onChanged;

  const PropertySortControl({
    super.key,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  State<PropertySortControl> createState() => _PropertySortControlState();
}

class _PropertySortControlState extends State<PropertySortControl> {
  /// Sort options shown in the sheet. Seeded with the known backend values so
  /// the control works immediately, then refreshed from
  /// `/api/Lookups/PropertySorting` (web parity).
  List<SortOption> _sortOptions = _fallbackSortOptions;

  /// Known PropertySorting lookup values — used as an offline/error fallback
  /// and to seed the control before the live lookup resolves.
  static const List<SortOption> _fallbackSortOptions = [
    SortOption(id: '1', name: 'Newest First'),
    SortOption(id: '2', name: 'Oldest First'),
    SortOption(id: '3', name: 'Price: High to Low'),
    SortOption(id: '4', name: 'Price: Low to High'),
    SortOption(id: '5', name: 'Highest Rated'),
    SortOption(id: '6', name: 'Most Booked'),
  ];

  /// Maps stable PropertySorting ids to localized labels; unknown ids fall
  /// back to the backend-provided name (see [_sortDisplayName]).
  static const Map<String, String> _sortLabelKeys = {
    '1': 'filters.sortNewest',
    '2': 'filters.sortOldest',
    '3': 'filters.sortPriceHighLow',
    '4': 'filters.sortPriceLowHigh',
    '5': 'filters.sortHighestRated',
    '6': 'filters.sortMostBooked',
  };

  @override
  void initState() {
    super.initState();
    _loadSortOptions();
  }

  Future<void> _loadSortOptions() async {
    try {
      final options = await sl<PropertyService>().getSortingOptions();
      if (!mounted || options.isEmpty) return;
      setState(() => _sortOptions = options);
    } catch (_) {
      // Keep the fallback options on failure.
    }
  }

  /// Localized label for a sort option: a translated label for known backend
  /// ids, falling back to the backend-provided name otherwise.
  String _sortDisplayName(SortOption option) {
    final key = _sortLabelKeys[option.id];
    return key != null ? context.tr(key) : option.name;
  }

  @override
  Widget build(BuildContext context) {
    SortOption? selected;
    for (final option in _sortOptions) {
      if (option.id == widget.selectedId) {
        selected = option;
        break;
      }
    }
    final isActive = widget.selectedId != null;
    final label = selected != null
        ? _sortDisplayName(selected)
        : context.tr('filters.sortBy');

    return GestureDetector(
      onTap: _openSortSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFCC519) : const Color(0xFFF9F9FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_vert, size: 16, color: Color(0xFF1D242B)),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D242B),
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down,
                size: 16, color: Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }

  /// Bottom sheet listing the sort options plus a "default" entry that clears
  /// any active sort. Selecting a different option reports it via [onChanged].
  void _openSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                child: Row(
                  children: [
                    Text(
                      context.tr('filters.sortBy'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D242B),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close,
                          size: 20, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              _buildSortTile(
                sheetContext,
                id: null,
                label: context.tr('filters.sortDefault'),
              ),
              ..._sortOptions.map(
                (option) => _buildSortTile(
                  sheetContext,
                  id: option.id,
                  label: _sortDisplayName(option),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortTile(
    BuildContext sheetContext, {
    required String? id,
    required String label,
  }) {
    final selected = widget.selectedId == id;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: const Color(0xFF1D242B),
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check, size: 20, color: Color(0xFFFCC519))
          : null,
      onTap: () {
        Navigator.pop(sheetContext);
        if (widget.selectedId != id) {
          widget.onChanged(id);
        }
      },
    );
  }
}
