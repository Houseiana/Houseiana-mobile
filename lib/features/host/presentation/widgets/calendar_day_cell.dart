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
  static const Color _discountBadge = Color(0xFFF43F5E); // rose-500 (web parity)

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

    final d = info;
    final showDiscount = !showBlockedIcon &&
        d != null &&
        d.hasDiscount &&
        d.discountedPrice != null;
    final showBadge = showDiscount && d.discountPercent != null;

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
              // Day number, with the discount badge pinned to the top-right so
              // it reads at a glance without stealing vertical room from the
              // prices below.
              _dayRow(fg, showBadge),
              if (showBlockedIcon)
                const Icon(Icons.block, size: 12, color: AppColors.neutral400)
              else
                _priceContent(fg, priceColor, showDiscount),
            ],
          ),
        ),
      ),
    );
  }

  /// Top line of the cell: the day number, plus a `-X%` pill in the top-right
  /// corner on discounted days. The pill is wrapped in a `scaleDown` FittedBox
  /// so it never overflows a tight cell.
  Widget _dayRow(Color fg, bool showBadge) {
    final dayText = Text(
      '${day.day}',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: fg,
      ),
    );
    if (!showBadge) return dayText;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        dayText,
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: _discountBadgePill(info!.discountPercent!),
          ),
        ),
      ],
    );
  }

  Widget _discountBadgePill(int pct) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: _discountBadge,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '-$pct%',
        style: const TextStyle(
          fontSize: 9,
          height: 1.0,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  /// The bottom-left price content. On a discounted day it shows the struck-out
  /// original above a larger, rose-colored discounted amount; the `-X%` badge
  /// lives in [_dayRow] at the top-right. Sizes are generous and each line is
  /// wrapped in its own `scaleDown` FittedBox so nothing overflows a tight cell.
  Widget _priceContent(Color fg, Color priceColor, bool showDiscount) {
    final d = info;
    if (showDiscount) {
      final original = d!.price;
      final discounted = d.discountedPrice!;
      // Make the discounted amount pop in rose to match the badge, but fall
      // back to the foreground color on dark backgrounds (selected / booked).
      final discountColor = fg == Colors.white ? Colors.white : _discountBadge;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (original != null)
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '$currency${_fmt(original)}',
                style: TextStyle(
                  fontSize: 9,
                  height: 1.1,
                  color: priceColor,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '$currency${_fmt(discounted)}',
              style: TextStyle(
                fontSize: 12,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: discountColor,
              ),
            ),
          ),
        ],
      );
    }
    final price = d?.price;
    if (price == null) return const SizedBox.shrink();
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        '$currency${_fmt(price)}',
        style: TextStyle(fontSize: 9, color: priceColor),
      ),
    );
  }

  String _fmt(double price) => price == price.roundToDouble()
      ? price.toStringAsFixed(0)
      : price.toStringAsFixed(2);
}
