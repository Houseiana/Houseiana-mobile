import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/utils/money.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

/// The stay's price breakdown, rendered straight from a
/// `/property-search/{id}/availability` response — `pricePerNight`, `subtotal`,
/// `cleaningFee`, `serviceFee`, optional `platformCommission` / `discount`, and
/// `totalPrice`. Mirrors the web booking card (`booking-card.tsx`).
///
/// Nothing is computed here: the fees only exist in that quote (the property
/// payload reports `serviceFee: 0` even where the quote charges 2100), so this
/// widget is the single renderer for both the details screen's price section
/// and the date-picker calendar footer.
class AvailabilityQuoteRows extends StatelessWidget {
  /// Raw `/availability` response, or null when it failed to load.
  final Map<String, dynamic>? availability;
  final String currency;

  /// Nights to label the first row with when the response omits `nights`.
  final int? nightsFallback;

  /// Tighter type/spacing for the calendar footer, where vertical room is scarce.
  final bool compact;

  const AvailabilityQuoteRows({
    super.key,
    required this.availability,
    required this.currency,
    this.nightsFallback,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: _rows(context),
    );
  }

  List<Widget> _rows(BuildContext context) {
    final avail = availability;
    if (avail == null) {
      return [
        Text(
          context.tr('propertyDetails.priceDetailsUnavailable'),
          style: const TextStyle(fontSize: 13, color: AppColors.neutral500),
        ),
      ];
    }
    if (avail['isAvailable'] == false) {
      return [
        Text(
          context.tr('propertyDetails.datesNotAvailable'),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFFD00416),
          ),
        ),
      ];
    }

    double? amount(String key) {
      final v = avail[key];
      return v is num ? v.toDouble() : null;
    }

    String money(double? value) => Money.format(value, currency);

    final nights = (avail['nights'] as num?)?.toInt() ?? nightsFallback ?? 0;
    final nightlyLabel = nights == 1
        ? context.tr('booking.priceByNightTemplate',
            args: {'price': money(amount('pricePerNight')), 'nights': nights})
        : context.tr('booking.priceByNightsTemplate',
            args: {'price': money(amount('pricePerNight')), 'nights': nights});

    final platformCommission = amount('platformCommission') ?? 0;
    final discount = amount('discount') ?? 0;
    final gap = SizedBox(height: compact ? 8 : 12);

    return [
      _row(nightlyLabel, money(amount('subtotal'))),
      gap,
      _row(context.tr('booking.cleaningFee'), money(amount('cleaningFee'))),
      gap,
      _row(context.tr('booking.serviceFee'), money(amount('serviceFee'))),
      if (platformCommission > 0) ...[
        gap,
        _row(context.tr('booking.platformFee'), money(platformCommission)),
      ],
      if (discount > 0) ...[
        gap,
        _row(context.tr('booking.discount'), '- ${money(discount)}',
            isDiscount: true),
      ],
      Divider(height: compact ? 18 : 24, color: AppColors.neutral200),
      _row(context.tr('booking.totalUsd'), money(amount('totalPrice')),
          isTotal: true),
    ];
  }

  Widget _row(String label, String value,
      {bool isTotal = false, bool isDiscount = false}) {
    const discountGreen = Color(0xFF059669);
    final labelSize = compact ? (isTotal ? 14.0 : 13.0) : (isTotal ? 16.0 : 14.0);
    final valueSize = compact ? (isTotal ? 15.0 : 13.0) : (isTotal ? 17.0 : 14.0);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: labelSize,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
              color: isDiscount
                  ? discountGreen
                  : isTotal
                      ? AppColors.charcoal
                      : const Color(0xFF6B7280),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: valueSize,
            fontWeight: FontWeight.w700,
            color: isDiscount ? discountGreen : AppColors.charcoal,
          ),
        ),
      ],
    );
  }
}
