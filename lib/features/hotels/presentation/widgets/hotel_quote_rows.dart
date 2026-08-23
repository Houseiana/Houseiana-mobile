import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_quote.dart';
import 'package:houseiana_mobile_app/core/utils/money.dart';
import 'package:houseiana_mobile_app/features/hotels/presentation/widgets/room_type_card.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// The stay's price breakdown, rendered straight from a `POST /api/hotel-quote`
/// response: one row per selected rate plan, the rooms subtotal, the service fee
/// and the total.
///
/// Nothing is computed here. Unlike the property `/availability` quote, hotel
/// `roomsSubtotal` is NOT pre-discounted and there is no discount or cleaning
/// fee to reconcile — `total` is a plain `roomsSubtotal + serviceFee`, so the
/// column adds up on screen exactly as the server sent it. Deliberately does
/// not carry over the property screen's `grossSubtotal = subtotal + discount`
/// correction, which would invent a discount hotels never quote.
///
/// Every amount uses the quote's own `currencyCode`: the backend refuses a
/// selection that mixes currencies, so one quote is always single-currency.
class HotelQuoteRows extends StatelessWidget {
  final HotelQuote? quote;

  /// A quote request is in flight — shows placeholder rows instead of the last
  /// quote's numbers, which belong to a selection the guest has already changed.
  final bool loading;

  /// Either a translation key (`hotels.quoteFailed`) or a raw backend reason
  /// ("Rate plan not found."). `context.tr` passes an unknown key through
  /// unchanged, so both render correctly without the caller having to know
  /// which one it holds.
  final String? errorMessage;

  HotelQuoteRows({
    super.key,
    required this.quote,
    this.loading = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final message = errorMessage;
    if (message != null) {
      return Text(
        context.tr(message),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.error,
        ),
      );
    }

    if (loading) return _loading();

    final q = quote;
    if (q == null || q.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: _rows(context, q),
    );
  }

  List<Widget> _rows(BuildContext context, HotelQuote q) {
    String money(double value) => Money.format(value, q.currencyCode);

    return [
      for (final line in q.lines) ...[
        _row(_lineLabel(context, line), money(line.subtotal)),
        const SizedBox(height: 12),
      ],
      _row(context.tr('hotels.roomsSubtotal'), money(q.roomsSubtotal)),
      const SizedBox(height: 12),
      _row(context.tr('booking.serviceFee'), money(q.serviceFee)),
      Divider(height: 24, color: AppColors.neutral200),
      _row(context.tr('booking.totalUsd'), money(q.total), isTotal: true),
    ];
  }

  String _lineLabel(BuildContext context, HotelQuoteLine line) {
    final board = hotelBoardBasisLabel(context, line.boardBasis);
    // A rate plan can arrive without a board basis; naming an empty one reads
    // as "Deluxe Room ·  × 2".
    return board.isEmpty
        ? context.tr('hotels.quoteLineNoBoard',
            args: {'roomType': line.roomTypeName, 'rooms': line.rooms})
        : context.tr('hotels.quoteLine', args: {
            'roomType': line.roomTypeName,
            'board': board,
            'rooms': line.rooms,
          });
  }

  /// Placeholder rows sized like a two-line quote, so the section keeps its
  /// height while a new selection is being priced instead of collapsing and
  /// bouncing the scroll position.
  Widget _loading() {
    return Skeletonizer(
      containersColor: AppColors.skeletonBaseColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++) ...[
            _skeletonRow(i.isEven ? 180 : 140),
            const SizedBox(height: 12),
          ],
          Divider(height: 24, color: AppColors.neutral200),
          _skeletonRow(90),
        ],
      ),
    );
  }

  Widget _skeletonRow(double labelWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          height: 14,
          width: labelWidth,
          decoration: BoxDecoration(
            color: AppColors.neutral200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Container(
          height: 14,
          width: 70,
          decoration: BoxDecoration(
            color: AppColors.neutral200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
              color: isTotal ? AppColors.charcoal : AppColors.neutral500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 17 : 14,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
      ],
    );
  }
}
