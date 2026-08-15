import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/models/nightly_price_model.dart';
import 'package:houseiana_mobile_app/core/utils/money.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/cubit/nightly_prices_cubit.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/cubit/nightly_prices_state.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/widgets/availability_quote_rows.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/widgets/month_calendar_widget.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
// intl also exports a `TextDirection`; hiding it keeps `TextDirection.rtl`
// resolving to the Flutter one used by `Directionality`.
import 'package:intl/intl.dart' hide TextDirection;
import 'package:skeletonizer/skeletonizer.dart';

/// Web-parity booking card for the property details screen
/// (`booking-card.tsx`): the check-in / checkout box, the calendar that opens
/// **inside** the page right under it, and the price breakdown for the picked
/// range — all in one section, never a separate screen.
///
/// Every amount is read straight off the `/property-search/{id}/availability`
/// quote the [NightlyPricesCubit] fetches for the selected dates —
/// `pricePerNight`, `subtotal`, `cleaningFee`, `serviceFee`, optional
/// `platformCommission` / `discount`, and `totalPrice`. Nothing is computed
/// locally, and nothing is shown before the guest picks dates: the service fee
/// is a share of the stay, so it has no meaning without them. That is also why
/// the property payload can't feed this section — the details endpoint reports
/// `serviceFee: 0` even where the quote charges 2100.
class PriceDetailsSection extends StatelessWidget {
  final String currency;

  /// Shortest stay the host accepts. Shown up front and enforced before the
  /// guest reaches the reserve step, where the backend would reject them.
  final int? minNights;

  /// Stand-in amounts that only ever render as skeleton bones — they give the
  /// loading state the exact row count and shape of a real quote.
  static const _placeholderQuote = <String, dynamic>{
    'isAvailable': true,
    'pricePerNight': 1000,
    'subtotal': 2000,
    'cleaningFee': 100,
    'serviceFee': 200,
    'totalPrice': 2300,
  };

  PriceDetailsSection({
    super.key,
    required this.currency,
    this.minNights,
  });

  /// Whether [nights] falls short of the host's minimum.
  static bool isBelowMinimum(int nights, int? minNights) =>
      minNights != null && minNights > 1 && nights > 0 && nights < minNights;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NightlyPricesCubit, NightlyPricesState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('booking.priceDetails'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 14),
              _datesPicker(context, state),
              // The calendar grows and shrinks in place instead of pushing the
              // guest to another screen.
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: state.isCalendarOpen
                    ? _calendarPanel(context, state)
                    : const SizedBox(width: double.infinity),
              ),
              if (minNights != null && minNights! > 1) ...[
                const SizedBox(height: 12),
                _minimumStayNotice(context),
              ],
              if (state.hasCompleteRange &&
                  isBelowMinimum(
                      state.checkOut!.difference(state.checkIn!).inDays,
                      minNights)) ...[
                const SizedBox(height: 10),
                _belowMinimumWarning(
                    context, state.checkOut!.difference(state.checkIn!).inDays),
              ],
              const SizedBox(height: 16),
              _breakdown(context, state),
              const SizedBox(height: 12),
              // Same reassurance the web card puts under its Reserve button;
              // mobile's button lives in the sticky bar, so it goes here.
              Center(
                child: Text(
                  context.tr('propertyDetails.notChargedYet'),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Amber notice mirroring the web card's minimum-stay banner.
  Widget _minimumStayNotice(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        // dark-ok: amber minimum-stay notice — the tinted panel and its
        // amber-on-amber content stay a self-contained light island in
        // both themes.
        color: const Color(0xFFFFF8E1), // dark-ok
        border:
            Border.all(color: AppColors.primaryColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // dark-ok: on the amber notice panel
          const Icon(Icons.event_available_outlined,
              size: 16, color: Color(0xFFD4A017)), // dark-ok
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.tr('propertyDetails.minimumStay', args: {'n': minNights}),
              // dark-ok: on the amber notice panel
              style: const TextStyle(fontSize: 13, color: Color(0xFF7A6C3A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _belowMinimumWarning(BuildContext context, int nights) {
    return Text(
      context.tr('propertyDetails.belowMinimumStay',
          args: {'nights': nights, 'min': minNights}),
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.discountRed,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dates box
  // ---------------------------------------------------------------------------

  /// Check-in / checkout box mirroring the web card. Tapping a half focuses it
  /// (and opens the calendar); tapping the focused half again closes it.
  Widget _datesPicker(BuildContext context, NightlyPricesState state) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final fmt = DateFormat('d MMM yyyy', locale);
    final cubit = context.read<NightlyPricesCubit>();

    void tapField(NightlyStayField field) {
      if (state.focusedField == field) {
        cubit.focusField(null);
      } else {
        cubit.focusField(field, currency: currency);
      }
    }

    Widget half(String label, DateTime? value, NightlyStayField field) {
      final focused = state.focusedField == field;
      return Expanded(
        child: InkWell(
          key: ValueKey('stayField.${field.name}'),
          onTap: () => tapField(field),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: focused
                  ? AppColors.primaryColor.withValues(alpha: 0.1)
                  : Colors.transparent,
              border: focused
                  ? Border.all(color: AppColors.charcoal, width: 1.5)
                  : null,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        value == null ? FontWeight.w400 : FontWeight.w600,
                    color: value == null
                        ? AppColors.neutral500
                        : AppColors.charcoal,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.neutral200),
        borderRadius: BorderRadius.circular(12),
      ),
      // IntrinsicHeight so both halves — and the divider between them — match
      // the taller one; without it `stretch` would ask for infinite height
      // inside the page's scroll view.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            half(context.tr('booking.checkInDate'), state.checkIn,
                NightlyStayField.checkIn),
            Container(width: 1, color: AppColors.neutral200),
            half(context.tr('booking.checkOutDate'), state.checkOut,
                NightlyStayField.checkOut),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Inline calendar
  // ---------------------------------------------------------------------------

  Widget _calendarPanel(BuildContext context, NightlyPricesState state) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border.all(color: AppColors.neutral200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!state.initialized && state.fatalError != null)
            _calendarError(context)
          else if (!state.initialized)
            _InlineCalendarSkeleton()
          else ...[
            _monthNav(context, state),
            _weekHeader(context),
            MonthCalendarWidget(
              month: state.leftMonth,
              prices: state.pricesByMonth[
                  NightlyPricesPage.monthKeyFromDate(state.leftMonth)],
              isLoading: state.loadingMonths.contains(
                  NightlyPricesPage.monthKeyFromDate(state.leftMonth)),
              error: state.errorsByMonth[
                  NightlyPricesPage.monthKeyFromDate(state.leftMonth)],
              checkIn: state.checkIn,
              checkOut: state.checkOut,
              currency: state.currency,
              totalPages: state.totalPages ?? 12,
              baseMonthKey: state.baseMonthKey,
              bookedDates: state.bookedDates,
              onDayTap: context.read<NightlyPricesCubit>().tapDay,
              onRetry: () => context
                  .read<NightlyPricesCubit>()
                  .retryMonth(state.leftMonth),
              showTitle: false,
            ),
            const SizedBox(height: 8),
            _calendarFooter(context, state),
          ],
        ],
      ),
    );
  }

  Widget _monthNav(BuildContext context, NightlyPricesState state) {
    final cubit = context.read<NightlyPricesCubit>();
    final locale = Localizations.localeOf(context).toLanguageTag();
    final canPrev = cubit.canGoPrev();
    final canNext = cubit.canGoNext();

    return Row(
      children: [
        IconButton(
          onPressed: canPrev ? cubit.goPrev : null,
          // The Row is direction-aware, so "previous" already lands at the
          // right-hand edge in Arabic, and `chevron_left` carries
          // `matchTextDirection` so Flutter mirrors the glyph to match.
          // Swapping the icon by hand here would flip it a second time.
          icon: const Icon(Icons.chevron_left),
          color: AppColors.charcoal,
          disabledColor: AppColors.neutral300,
          visualDensity: VisualDensity.compact,
        ),
        Expanded(
          child: Center(
            child: Text(
              DateFormat.yMMMM(locale).format(state.leftMonth),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: canNext ? cubit.goNext : null,
          icon: const Icon(Icons.chevron_right),
          color: AppColors.charcoal,
          disabledColor: AppColors.neutral300,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _weekHeader(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final mondayStart = DateTime(2024, 1, 1); // a Monday
    final labels = List<String>.generate(7, (i) {
      final d = mondayStart.add(Duration(days: i));
      return DateFormat.E(locale).format(d).substring(0, 2);
    });

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: labels
            .map(
              (l) => Expanded(
                child: Center(
                  child: Text(
                    l,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _calendarError(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 32),
          const SizedBox(height: 8),
          Text(
            context.tr('propertyDetails.calendarLoadError'),
            style: TextStyle(
              fontSize: 13,
              color: AppColors.neutral600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () =>
                context.read<NightlyPricesCubit>().open(currency: currency),
            child: Text(
              context.tr('common.retry'),
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Selection summary + the "approximate prices" note, then Clear.
  Widget _calendarFooter(BuildContext context, NightlyPricesState state) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFmt = DateFormat('EEE, MMM d', locale);
    final cubit = context.read<NightlyPricesCubit>();

    String summary;
    if (state.checkIn == null) {
      summary = context.tr('propertyDetails.calendarSelectCheckIn');
    } else if (state.checkOut == null) {
      summary =
          '${dateFmt.format(state.checkIn!)} – ${context.tr('propertyDetails.calendarSelectCheckOut')}';
    } else {
      final nights = state.checkOut!.difference(state.checkIn!).inDays;
      final nightStay =
          context.tr('propertyDetails.calendarNightStay', args: {'n': nights});
      summary =
          '${dateFmt.format(state.checkIn!)} – ${dateFmt.format(state.checkOut!)} ($nightStay)';
    }

    return Column(
      children: [
        Text(
          context.tr('propertyDetails.calendarApproxPrices',
              args: {'currency': state.currency}),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.neutral500),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                summary,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal,
                ),
              ),
            ),
            if (state.checkIn != null || state.checkOut != null)
              TextButton(
                onPressed: cubit.clearSelection,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  context.tr('common.clear'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Price breakdown
  // ---------------------------------------------------------------------------

  Widget _breakdown(BuildContext context, NightlyPricesState state) {
    if (!state.hasCompleteRange) {
      return Text(
        context.tr('propertyDetails.priceDetailsHint'),
        style: TextStyle(fontSize: 13, color: AppColors.neutral500),
      );
    }
    if (state.quoteLoading) {
      // Skeleton of the real rows rather than a spinner, so the section keeps
      // its shape while the quote lands.
      return Skeletonizer(
        containersColor: AppColors.skeletonBaseColor,
        child: AvailabilityQuoteRows(
          availability: _placeholderQuote,
          currency: currency,
          nightsFallback: state.checkOut!.difference(state.checkIn!).inDays,
        ),
      );
    }
    // The quote is the only source of the fees; when it fails, the nights-only
    // total summed from the loaded grid is still better than nothing.
    if (state.quote == null) {
      final fallback = _stayTotalFallback(context, state);
      if (fallback != null) return fallback;
    }
    return AvailabilityQuoteRows(
      availability: state.quote,
      currency: currency,
      nightsFallback: state.checkOut!.difference(state.checkIn!).inDays,
    );
  }

  /// Nights-only total summed from the loaded nightly prices. When any night is
  /// discounted the pre-discount total renders struck through next to the
  /// charged total (same treatment as the day cells). Null when a night in the
  /// range has no loaded price.
  Widget? _stayTotalFallback(BuildContext context, NightlyPricesState state) {
    final totals = state.selectedRangeTotals;
    if (totals == null) return null;
    final hasDiscount = totals.effective < totals.original;
    // The app's discount red, matching NightlyPriceCell.
    const discountColor = AppColors.discountRed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('propertyDetails.priceDetailsUnavailable'),
          style: TextStyle(fontSize: 13, color: AppColors.neutral500),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr('propertyDetails.calendarStayTotal'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
            ),
            if (hasDiscount) ...[
              Text(
                Money.format(totals.original, state.currency),
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.neutral400,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: AppColors.neutral400,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              Money.format(totals.effective, state.currency),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: hasDiscount ? discountColor : AppColors.charcoal,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Placeholder grid shown while the first nightly-prices page loads, sized like
/// the real calendar so the section doesn't jump when the data lands.
class _InlineCalendarSkeleton extends StatelessWidget {
  _InlineCalendarSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      containersColor: AppColors.skeletonBaseColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Container(
              height: 18,
              width: 120,
              decoration: BoxDecoration(
                color: AppColors.neutral200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.78,
              ),
              itemCount: 35,
              itemBuilder: (context, index) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 18,
                    height: 13,
                    decoration: BoxDecoration(
                      color: AppColors.neutral200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 30,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.neutral200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
