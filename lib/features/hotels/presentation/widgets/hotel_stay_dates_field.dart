import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:intl/intl.dart';

/// The check-in / check-out box for the hotel screens.
///
/// Deliberately a plain `showDatePicker` and not the property screen's inline
/// month calendar: hotels expose no nightly-prices and no booked-dates
/// endpoint, so there is nothing to price per day and no day that can honestly
/// be greyed out. Availability only becomes knowable once `/api/hotel-quote`
/// answers for a concrete range.
///
/// The widget is stateless — the dates live in `HotelDetailsCubit`, which also
/// owns the re-fetch they trigger.
class HotelStayDatesField extends StatelessWidget {
  final DateTime? checkIn;
  final DateTime? checkOut;

  /// Fires with the whole pair. Picking a check-in that is not before the
  /// current check-out clears the check-out, so the second argument can arrive
  /// null even after one had already been chosen.
  final void Function(DateTime? checkIn, DateTime? checkOut) onChanged;

  /// Off while a reload is in flight, so the guest can't queue two date changes
  /// against one request.
  final bool enabled;

  HotelStayDatesField({
    super.key,
    required this.checkIn,
    required this.checkOut,
    required this.onChanged,
    this.enabled = true,
  });

  int get _nights {
    final ci = checkIn;
    final co = checkOut;
    if (ci == null || co == null) return 0;
    // Date-only, or a stay picked across a DST shift comes back one night short.
    return DateUtils.dateOnly(co).difference(DateUtils.dateOnly(ci)).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat(
      'd MMM yyyy',
      Localizations.localeOf(context).languageCode,
    );
    final nights = _nights;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.neutral200),
            borderRadius: BorderRadius.circular(12),
          ),
          // IntrinsicHeight so the divider between the halves spans the taller
          // one; `stretch` on its own would ask for infinite height inside the
          // details screen's scroll view.
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _half(
                  context,
                  label: context.tr('booking.checkInDate'),
                  value: checkIn,
                  fmt: fmt,
                  onTap: () => _pickCheckIn(context),
                  showDivider: true,
                ),
                _half(
                  context,
                  label: context.tr('booking.checkOutDate'),
                  value: checkOut,
                  fmt: fmt,
                  onTap: () => _pickCheckOut(context),
                  showDivider: false,
                ),
              ],
            ),
          ),
        ),
        if (nights > 0) ...[
          const SizedBox(height: 8),
          Text(
            context.tr(
              nights == 1 ? 'booking.nightSingular' : 'booking.nightsCount',
              args: {'n': nights},
            ),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.neutral600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _half(
    BuildContext context, {
    required String label,
    required DateTime? value,
    required DateFormat fmt,
    required VoidCallback onTap,
    required bool showDivider,
  }) {
    return Expanded(
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: showDivider
              ? BoxDecoration(
                  // Directional so the separator stays between the halves in
                  // Arabic instead of jumping to the outer edge.
                  border: BorderDirectional(
                    end: BorderSide(color: AppColors.neutral200),
                  ),
                )
              : null,
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
                  fontWeight: value == null ? FontWeight.w400 : FontWeight.w600,
                  color:
                      value == null ? AppColors.neutral500 : AppColors.charcoal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickCheckIn(BuildContext context) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final last = today.add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: _clamp(checkIn, today, last),
      firstDate: today,
      lastDate: last,
    );
    if (picked == null) return;

    // A check-in on or after the current check-out would be a zero- or
    // negative-night stay, which the quote endpoint rejects. Drop the check-out
    // and let the guest pick it again against the new anchor.
    final co = checkOut;
    onChanged(picked, co != null && co.isAfter(picked) ? co : null);
  }

  Future<void> _pickCheckOut(BuildContext context) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final first =
        DateUtils.dateOnly(checkIn ?? today).add(const Duration(days: 1));
    // A check-in on the very last selectable day pushes `first` past the normal
    // one-year ceiling; showDatePicker asserts if lastDate precedes firstDate.
    final ceiling = today.add(const Duration(days: 365));
    final last = first.isAfter(ceiling) ? first : ceiling;

    final picked = await showDatePicker(
      context: context,
      initialDate: _clamp(checkOut, first, last),
      firstDate: first,
      lastDate: last,
    );
    if (picked == null) return;

    onChanged(checkIn, picked);
  }

  /// showDatePicker asserts that initialDate sits inside the range, and a date
  /// restored from route arguments can easily be in the past by now.
  static DateTime _clamp(DateTime? value, DateTime first, DateTime last) {
    if (value == null) return first;
    final v = DateUtils.dateOnly(value);
    if (v.isBefore(first)) return first;
    if (v.isAfter(last)) return last;
    return v;
  }
}
