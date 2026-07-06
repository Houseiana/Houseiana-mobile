import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:intl/intl.dart';

enum NightlyCellRangeState { none, start, end, inRange }

class NightlyPriceCell extends StatelessWidget {
  final DateTime? date;

  /// Amount displayed as the main price for this night — the discounted price
  /// when a discount applies, otherwise the regular price.
  final double? price;
  final bool isSpecialPrice;

  /// Pre-discount price, rendered struck-through above [price]. Non-null only
  /// when a discount applies.
  final double? originalPrice;

  /// Discount percentage badge for this night. Non-null only when discounted.
  final int? discountPercent;
  final NightlyCellRangeState rangeState;
  final bool isToday;
  final bool isPast;
  final bool isOutsideWindow;
  final bool isBooked;
  final String currency;
  final VoidCallback? onTap;

  const NightlyPriceCell({
    super.key,
    required this.date,
    required this.price,
    required this.isSpecialPrice,
    this.originalPrice,
    this.discountPercent,
    required this.rangeState,
    required this.isToday,
    required this.isPast,
    required this.isOutsideWindow,
    required this.isBooked,
    required this.currency,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (date == null) {
      return const SizedBox.shrink();
    }

    final selected = rangeState == NightlyCellRangeState.start ||
        rangeState == NightlyCellRangeState.end;
    final inRange = rangeState == NightlyCellRangeState.inRange;

    Color bg = Colors.transparent;
    Color dayColor = AppColors.charcoal;
    Color priceColor = AppColors.neutral500;
    BoxBorder? border;

    if (selected) {
      bg = AppColors.primaryColor;
      dayColor = AppColors.charcoal;
      priceColor = AppColors.charcoal;
    } else if (inRange) {
      bg = const Color(0xFFFFF6D6);
      dayColor = AppColors.charcoal;
      priceColor = AppColors.charcoal;
    } else if (isBooked) {
      dayColor = AppColors.neutral400;
      priceColor = AppColors.neutral400;
    } else if (isPast || isOutsideWindow) {
      dayColor = AppColors.neutral400;
      priceColor = AppColors.neutral400;
    } else if (isSpecialPrice) {
      priceColor = AppColors.primaryDark;
    }

    if (isToday && !selected && !inRange && !isBooked) {
      border = Border.all(color: AppColors.primaryColor, width: 1);
    }

    final canTap = !isPast && !isOutsideWindow && !isBooked && onTap != null;

    final hasDiscount = originalPrice != null &&
        price != null &&
        originalPrice! > price! &&
        !isPast &&
        !isOutsideWindow &&
        !isBooked;

    final priceText = (price != null && !isPast && !isOutsideWindow)
        ? _formatPrice(price!)
        : null;
    final strike = isBooked
        ? TextDecoration.lineThrough
        : TextDecoration.none;

    // Rose used for the discounted amount + badge (matches the web calendar).
    const discountColor = Color(0xFFE11D48);

    return InkWell(
      onTap: canTap ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: border,
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${date!.day}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w600,
                      color: dayColor,
                      decoration: strike,
                      decorationColor: AppColors.neutral400,
                      decorationThickness: 2,
                    ),
                  ),
                  if (hasDiscount) ...[
                    const SizedBox(height: 1),
                    // Original price, struck through, above the discounted one.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _formatPrice(originalPrice!),
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 9,
                            height: 1.05,
                            color: selected
                                ? AppColors.charcoal.withValues(alpha: 0.6)
                                : AppColors.neutral400,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: AppColors.neutral400,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _formatPrice(price!),
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.05,
                            fontWeight: FontWeight.w700,
                            color:
                                selected ? AppColors.charcoal : discountColor,
                          ),
                        ),
                      ),
                    ),
                  ] else if (priceText != null) ...[
                    const SizedBox(height: 2),
                    // The currency is shown once in the footer ("Approximate
                    // prices in <currency>…"), so each cell shows just the
                    // amount and scales it down to fit the narrow cell instead
                    // of truncating it with an ellipsis (the "EGP 1,…" bug).
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          priceText,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 10.5,
                            height: 1.1,
                            fontWeight: isSpecialPrice
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: priceColor,
                            decoration: strike,
                            decorationColor: AppColors.neutral400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Discount badge takes precedence over the special-price dot.
            if (hasDiscount && discountPercent != null)
              Positioned(
                top: 3,
                right: 3,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : discountColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '-$discountPercent%',
                    style: TextStyle(
                      fontSize: 7.5,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: selected ? discountColor : Colors.white,
                    ),
                  ),
                ),
              )
            else if (isSpecialPrice && !isPast && !isOutsideWindow)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryDark,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatPrice(double value) {
    final formatter = NumberFormat.decimalPattern();
    return formatter.format(value.round());
  }
}
