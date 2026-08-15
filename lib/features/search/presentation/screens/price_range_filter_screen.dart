import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class PriceRangeFilterScreen extends StatefulWidget {
  PriceRangeFilterScreen({super.key});

  @override
  State<PriceRangeFilterScreen> createState() => _PriceRangeFilterScreenState();
}

class _PriceRangeFilterScreenState extends State<PriceRangeFilterScreen> {
  static const double _defaultMinPrice = 0;
  static const double _defaultMaxPrice = 1000;

  RangeValues _priceRange =
      const RangeValues(_defaultMinPrice, _defaultMaxPrice);
  int? _resultCount;
  double? _averageNightlyPrice;
  bool _didReadArguments = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadArguments) return;
    _didReadArguments = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! Map) return;

    final initialMin = _readDouble(args['minPrice']) ?? _defaultMinPrice;
    final initialMax = _readDouble(args['maxPrice']) ?? _defaultMaxPrice;
    _resultCount = _readInt(args['resultCount'] ?? args['totalResults']);
    _averageNightlyPrice = _readDouble(args['averageNightlyPrice']);

    _priceRange = RangeValues(
      initialMin.clamp(_defaultMinPrice, _defaultMaxPrice),
      initialMax.clamp(_defaultMinPrice, _defaultMaxPrice),
    );
  }

  double? _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final averagePrice = _averageNightlyPrice;

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('filters.priceRange'),
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
                _priceRange =
                    const RangeValues(_defaultMinPrice, _defaultMaxPrice);
              });
            },
            child: Text(context.tr('filters.reset')),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.ghostWhite,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _PriceValueColumn(
                          label: context.tr('filters.minimum'),
                          value: '\$${_priceRange.start.round()}',
                          crossAxisAlignment: CrossAxisAlignment.start,
                        ),
                        Container(
                          width: 40,
                          height: 2,
                          color: AppColors.neutral400,
                        ),
                        _PriceValueColumn(
                          label: context.tr('filters.maximum'),
                          value: '\$${_priceRange.end.round()}',
                          crossAxisAlignment: CrossAxisAlignment.end,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  RangeSlider(
                    values: _priceRange,
                    min: _defaultMinPrice,
                    max: _defaultMaxPrice,
                    divisions: 100,
                    activeColor: AppColors.primaryColor,
                    inactiveColor: AppColors.neutral400.withValues(alpha: 0.3),
                    labels: RangeLabels(
                      '\$${_priceRange.start.round()}',
                      '\$${_priceRange.end.round()}',
                    ),
                    onChanged: (values) {
                      setState(() => _priceRange = values);
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$0',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.neutral600,
                        ),
                      ),
                      Text(
                        '\$1000+',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.neutral600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    context.tr('filters.quickSelection'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildQuickOption('\$0 - \$100', 0, 100),
                      _buildQuickOption('\$100 - \$250', 100, 250),
                      _buildQuickOption('\$250 - \$500', 250, 500),
                      _buildQuickOption('\$500 - \$750', 500, 750),
                      _buildQuickOption('\$750+', 750, 1000),
                    ],
                  ),
                  if (averagePrice != null) ...[
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.charcoal,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              context.tr('filters.averageNightlyInfo',
                                  args: {'price': '\$${averagePrice.round()}'}),
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.charcoal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
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
                onPressed: () => Navigator.pop(context, _priceRange),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.brandCharcoal,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _resultCount != null
                      ? context.tr('filters.showResultsCount',
                          args: {'count': _resultCount})
                      : context.tr('filters.applyPriceRange'),
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

  Widget _buildQuickOption(String label, double min, double max) {
    final isSelected = _priceRange.start == min && _priceRange.end == max;

    return GestureDetector(
      onTap: () => setState(() => _priceRange = RangeValues(min, max)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.neutral200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            // The selected chip is the brand yellow in both themes, so its
            // label has to stay dark.
            color: isSelected ? AppColors.brandCharcoal : AppColors.charcoal,
          ),
        ),
      ),
    );
  }
}

class _PriceValueColumn extends StatelessWidget {
  final String label;
  final String value;
  final CrossAxisAlignment crossAxisAlignment;

  _PriceValueColumn({
    required this.label,
    required this.value,
    required this.crossAxisAlignment,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.neutral600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
      ],
    );
  }
}
