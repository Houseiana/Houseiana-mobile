import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/features/host/data/models/calendar_day_model.dart';

/// A single day cell in the host calendar grid. Renders the day number, the
/// nightly price, and a status-driven background (matches the web legend:
/// Confirmed / Pending / Blocked / Check-out).
class CalendarDayCell extends StatelessWidget {
  final DateTime day;
  final CalendarDay? info;
  final bool isSelected;
  final bool isPast;
  final bool isCheckout;
  final bool isToday;
  final String currency;
  final VoidCallback? onTap;

  const CalendarDayCell({
    super.key,
    required this.day,
    required this.info,
    required this.isSelected,
    required this.isPast,
    required this.isCheckout,
    required this.isToday,
    required this.currency,
    this.onTap,
  });

  // Web legend colors.
  static const Color _confirmedBg = Color(0xFF1D242B);
  static const Color _pendingBg = Color(0xFFFFFBEB);
  static const Color _pendingText = Color(0xFFB38600);
  static const Color _pendingBorder = Color(0x80FCC519);
  static const Color _blockedBg = Color(0xFFF5F6F8);
  static const Color _checkoutBg = Color(0xFFF0FDF4);
  static const Color _checkoutText = Color(0xFF009966);
  static const Color _checkoutBorder = Color(0xFF86EFAC);

  @override
  Widget build(BuildContext context) {
    final status = info?.status ?? CalendarStatus.available;

    Color bg = Colors.white;
    Color fg = AppColors.charcoal;
    Color priceColor = AppColors.neutral400;
    Border? border = Border.all(color: AppColors.neutral200);
    bool showBlockedIcon = false;

    if (isSelected) {
      bg = AppColors.charcoal;
      fg = Colors.white;
      priceColor = Colors.white70;
      border = null;
    } else {
      switch (status) {
        case CalendarStatus.booked:
        case CalendarStatus.reserved:
          bg = _confirmedBg;
          fg = Colors.white;
          priceColor = Colors.white70;
          border = null;
          break;
        case CalendarStatus.pending:
          bg = _pendingBg;
          fg = _pendingText;
          priceColor = _pendingText;
          border = Border.all(color: _pendingBorder);
          break;
        case CalendarStatus.blocked:
          bg = _blockedBg;
          fg = AppColors.neutral500;
          priceColor = AppColors.neutral400;
          showBlockedIcon = true;
          border = null;
          break;
        case CalendarStatus.available:
        case CalendarStatus.unknown:
          if (isCheckout) {
            bg = _checkoutBg;
            fg = _checkoutText;
            priceColor = _checkoutText;
            border = Border.all(color: _checkoutBorder);
          }
          break;
      }
    }

    if (isToday && !isSelected) {
      border = Border.all(color: AppColors.primaryColor, width: 1.5);
    }

    final price = info?.price;
    final priceLabel = price != null ? '$currency${_fmt(price)}' : null;

    return GestureDetector(
      onTap: isPast ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: isPast ? 0.4 : 1,
        child: Container(
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 3),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: border,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
              if (showBlockedIcon)
                const Icon(Icons.block, size: 12, color: AppColors.neutral400)
              else if (priceLabel != null)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    priceLabel,
                    style: TextStyle(fontSize: 9, color: priceColor),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(double price) => price == price.roundToDouble()
      ? price.toStringAsFixed(0)
      : price.toStringAsFixed(2);
}
