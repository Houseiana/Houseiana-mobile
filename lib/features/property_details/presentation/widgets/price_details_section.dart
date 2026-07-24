import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/widgets/availability_quote_rows.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:intl/intl.dart';

/// Web-parity price breakdown for the property details screen
/// (`booking-card.tsx`).
///
/// Every amount is read straight off the `/property-search/{id}/availability`
/// quote for the selected dates — `pricePerNight`, `subtotal`, `cleaningFee`,
/// `serviceFee`, optional `platformCommission` / `discount`, and `totalPrice`.
/// Nothing is computed locally, and nothing is shown before the guest picks
/// dates: the service fee is a share of the stay, so it has no meaning without
/// them. That is also why the property payload can't feed this section — the
/// details endpoint reports `serviceFee: 0` even where the quote charges 2100.
class PriceDetailsSection extends StatelessWidget {
  final String currency;
  final DateTime? checkIn;
  final DateTime? checkOut;

  /// Raw `/availability` response for [checkIn]–[checkOut], or null when it
  /// hasn't loaded / failed.
  final Map<String, dynamic>? availability;
  final bool isLoading;
  final VoidCallback onPickDates;

  const PriceDetailsSection({
    super.key,
    required this.currency,
    required this.checkIn,
    required this.checkOut,
    required this.availability,
    required this.isLoading,
    required this.onPickDates,
  });

  bool get _hasDates => checkIn != null && checkOut != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('booking.priceDetails'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 14),
          _datesPicker(context),
          const SizedBox(height: 16),
          if (!_hasDates)
            Text(
              context.tr('propertyDetails.priceDetailsHint'),
              style: const TextStyle(fontSize: 13, color: AppColors.neutral500),
            )
          else if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            AvailabilityQuoteRows(
              availability: availability,
              currency: currency,
              nightsFallback: checkOut!.difference(checkIn!).inDays,
            ),
        ],
      ),
    );
  }

  /// Check-in / checkout box mirroring the web card; both halves open the same
  /// nightly-prices calendar the Reserve button uses.
  Widget _datesPicker(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final fmt = DateFormat('d MMM yyyy', locale);

    Widget half(String label, DateTime? value) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value == null
                      ? context.tr('booking.addDate')
                      : fmt.format(value),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
        );

    return InkWell(
      onTap: onPickDates,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.neutral200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            half(context.tr('booking.checkInDate'), checkIn),
            Container(width: 1, height: 56, color: AppColors.neutral200),
            half(context.tr('booking.checkOutDate'), checkOut),
          ],
        ),
      ),
    );
  }

}
