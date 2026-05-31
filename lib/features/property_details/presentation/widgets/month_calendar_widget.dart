import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/models/nightly_price_model.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/widgets/nightly_price_cell.dart';
import 'package:intl/intl.dart';

class MonthCalendarWidget extends StatelessWidget {
  final DateTime month;
  final List<NightlyPrice>? prices;
  final bool isLoading;
  final String? error;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String currency;
  final int totalPages;
  final String? baseMonthKey;
  final Set<DateTime> bookedDates;
  final ValueChanged<DateTime> onDayTap;
  final VoidCallback onRetry;

  const MonthCalendarWidget({
    super.key,
    required this.month,
    required this.prices,
    required this.isLoading,
    required this.error,
    required this.checkIn,
    required this.checkOut,
    required this.currency,
    required this.totalPages,
    required this.baseMonthKey,
    required this.bookedDates,
    required this.onDayTap,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final monthTitle =
        DateFormat.yMMMM(locale).format(month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: Text(
              monthTitle,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
          ),
        ),
        if (error != null)
          _buildError(context)
        else
          _buildGrid(context),
      ],
    );
  }

  Widget _buildError(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      child: Column(
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.error, size: 32),
          const SizedBox(height: 8),
          const Text(
            "Couldn't load prices",
            style: TextStyle(
              fontSize: 13,
              color: AppColors.neutral600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Monday-first: leading blanks = (weekday - 1) mod 7
    final leading = (firstDay.weekday - DateTime.monday) % 7;
    final totalCells = ((leading + daysInMonth) / 7).ceil() * 7;

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    final priceMap = <int, NightlyPrice>{};
    if (prices != null) {
      for (final p in prices!) {
        if (p.date.year == month.year && p.date.month == month.month) {
          priceMap[p.date.day] = p;
        }
      }
    }

    return Stack(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 0.78,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            if (index < leading) return const SizedBox.shrink();
            final dayNum = index - leading + 1;
            if (dayNum > daysInMonth) return const SizedBox.shrink();
            final date = DateTime(month.year, month.month, dayNum);
            final priceEntry = priceMap[dayNum];

            final isPast = date.isBefore(todayOnly);
            final isToday = date.isAtSameMomentAs(todayOnly);
            final outsideWindow = _isOutsideWindow(date);
            final isBooked = bookedDates.contains(date);

            final rangeState = _rangeState(date);

            return NightlyPriceCell(
              date: date,
              price: priceEntry?.price,
              isSpecialPrice: priceEntry?.isSpecialPrice ?? false,
              rangeState: rangeState,
              isToday: isToday,
              isPast: isPast,
              isOutsideWindow: outsideWindow,
              isBooked: isBooked,
              currency: currency,
              onTap: () => onDayTap(date),
            );
          },
        ),
        if (isLoading && prices == null)
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.6),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  bool _isOutsideWindow(DateTime date) {
    if (baseMonthKey == null) return false;
    final parts = baseMonthKey!.split('-');
    final baseYear = int.parse(parts[0]);
    final baseMonth = int.parse(parts[1]);
    final diff =
        (date.year * 12 + date.month) - (baseYear * 12 + baseMonth);
    final page = diff + 1;
    return page < 1 || page > totalPages;
  }

  NightlyCellRangeState _rangeState(DateTime date) {
    final ci = checkIn;
    final co = checkOut;
    if (ci == null) return NightlyCellRangeState.none;
    final d = DateTime(date.year, date.month, date.day);
    final ciOnly = DateTime(ci.year, ci.month, ci.day);
    if (d.isAtSameMomentAs(ciOnly)) {
      return co == null
          ? NightlyCellRangeState.start
          : NightlyCellRangeState.start;
    }
    if (co != null) {
      final coOnly = DateTime(co.year, co.month, co.day);
      if (d.isAtSameMomentAs(coOnly)) return NightlyCellRangeState.end;
      if (d.isAfter(ciOnly) && d.isBefore(coOnly)) {
        return NightlyCellRangeState.inRange;
      }
    }
    return NightlyCellRangeState.none;
  }
}
