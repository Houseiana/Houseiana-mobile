import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_details.dart';
import 'package:houseiana_mobile_app/core/utils/money.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/screens/photo_gallery_screen.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:intl/intl.dart';

/// Board-basis values that have a translated label. The hotels endpoints
/// already localize `boardBasis` through the `lang` header, so an unmapped
/// value is rendered as it arrived rather than replaced by a raw key.
const _boardKeys = <String, String>{
  'Room Only': 'hotels.boardRoomOnly',
  'Bed & Breakfast': 'hotels.boardBedAndBreakfast',
  'Half Board': 'hotels.boardHalfBoard',
  'Full Board': 'hotels.boardFullBoard',
  'All Inclusive': 'hotels.boardAllInclusive',
};

/// Board-basis label for a rate plan or a quote line. Shared with
/// `HotelQuoteRows` so the price breakdown names a plan exactly the way the
/// room card did — a guest who picked "Bed & Breakfast" must not read
/// "Room Only" two sections further down.
String hotelBoardBasisLabel(BuildContext context, String boardBasis) {
  final raw = boardBasis.trim();
  if (raw.isEmpty) return '';
  final key = _boardKeys[raw];
  return key == null ? raw : context.tr(key);
}

/// One room type on the hotel details screen: its photos, the specs that decide
/// whether it fits the party, and a selectable row per rate plan.
///
/// The rate plan — not the room type — is what the quote and the booking
/// address, so every price, currency and rooms counter here belongs to a
/// specific [HotelRatePlan]. Currency is per rate plan (one hotel was observed
/// quoting EGP on one room type and QAR on another), which is why nothing on
/// this card ever adds two plans together.
class RoomTypeCard extends StatelessWidget {
  final HotelRoomType roomType;

  /// Nights the details call priced. 0 means no dates were sent, and the rate
  /// plans then only carry a nightly `basePrice`.
  final int nights;

  /// Anchor for the free-cancellation deadline — the window counts BACK from
  /// check-in, so without it only the relative window can be shown.
  final DateTime? checkIn;

  /// Rooms currently selected, keyed by `ratePlanId`.
  final Map<String, int> selections;

  /// Currency the current selection is locked to, or null when nothing is
  /// selected yet.
  ///
  /// One hotel really can quote two currencies (an EGP room beside a QAR one),
  /// and `POST /api/hotel-quote` refuses the mix outright: "Selections must
  /// share the same currency." Knowing the locked currency lets the card refuse
  /// the second currency up front rather than letting the guest build a
  /// selection that can never be priced.
  final String? lockedCurrencyCode;

  final void Function(String ratePlanId, int rooms) onRoomsChanged;

  /// Opens the photo viewer at the tapped index. Left null, the card pushes
  /// [PhotoGalleryScreen] itself so it also works standalone.
  final void Function(List<String> photos, int initialIndex)? onPhotoTap;

  RoomTypeCard({
    super.key,
    required this.roomType,
    required this.selections,
    required this.onRoomsChanged,
    this.lockedCurrencyCode,
    this.nights = 0,
    this.checkIn,
    this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    final soldOut = roomType.isSoldOut;
    final badge = _availabilityBadge(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _photos(context, roomType.galleryUrls),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        roomType.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ),
                    if (badge != null) badge,
                  ],
                ),
                const SizedBox(height: 10),
                _specChips(context),
                ..._bedRows(context),
                ..._amenities(context),
                ..._services(context),
                const SizedBox(height: 12),
                // Sold-out rows stay on screen: a guest who scrolled this far
                // should see what the room offers and that it is gone, not an
                // empty card that looks like a loading bug.
                Opacity(
                  opacity: soldOut ? 0.5 : 1,
                  child: Column(children: _ratePlanRows(context, soldOut)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Photos
  // ---------------------------------------------------------------------------

  Widget _photos(BuildContext context, List<String> photos) {
    if (photos.isEmpty) return _photoPlaceholder(double.infinity);

    void open(int index) {
      final handler = onPhotoTap;
      if (handler != null) {
        handler(photos, index);
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) =>
              PhotoGalleryScreen(photos: photos, initialIndex: index),
        ),
      );
    }

    if (photos.length == 1) {
      return GestureDetector(
        onTap: () => open(0),
        child: _photo(photos.first, width: double.infinity, memCacheWidth: 800),
      );
    }

    // A horizontal strip rather than a PageView: these are a glance at the room
    // next to its price, not the hero gallery the hotel header already owns.
    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        itemCount: photos.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) => GestureDetector(
          onTap: () => open(index),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            // Half-width tiles render at ~220dp, so 450 is already generous.
            child: _photo(photos[index], width: 220, memCacheWidth: 450),
          ),
        ),
      ),
    );
  }

  Widget _photo(
    String url, {
    required double width,
    required int memCacheWidth,
  }) {
    return CachedNetworkImage(
      imageUrl: url,
      height: 150,
      width: width,
      fit: BoxFit.cover,
      memCacheWidth: memCacheWidth,
      // A static block, never a per-image spinner — a strip of them flickers.
      placeholder: (context, url) => Container(
        height: 150,
        width: width,
        color: AppColors.neutral100,
      ),
      errorWidget: (context, url, error) => _photoPlaceholder(width),
    );
  }

  Widget _photoPlaceholder(double width) {
    return Container(
      height: 150,
      width: width,
      color: AppColors.neutral100,
      child: Icon(Icons.bed_outlined, size: 32, color: AppColors.neutral300),
    );
  }

  // ---------------------------------------------------------------------------
  // Specs
  // ---------------------------------------------------------------------------

  Widget _specChips(BuildContext context) {
    final chips = <String>[
      if (roomType.sizeSqm > 0)
        context.tr('hotels.roomSize', args: {'size': roomType.sizeSqm}),
      if (roomType.viewType.isNotEmpty)
        context.tr('hotels.roomView', args: {'view': roomType.viewType}),
      // Backend-localized already — never key off this string, only show it.
      if (roomType.roomCategory.isNotEmpty) roomType.roomCategory,
      if (roomType.baseOccupancy > 0)
        context.tr('hotels.sleeps', args: {'count': roomType.baseOccupancy}),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [for (final label in chips) _chip(label)],
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: AppColors.neutral700),
      ),
    );
  }

  List<Widget> _bedRows(BuildContext context) {
    if (roomType.beds.isEmpty) return const <Widget>[];
    return [
      const SizedBox(height: 10),
      for (final bed in roomType.beds)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(
                Icons.king_bed_outlined,
                size: 16,
                color: AppColors.neutral500,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  context.tr(
                    'hotels.bedsSummary',
                    args: {'count': bed.count, 'bedType': bed.bedType},
                  ),
                  style: TextStyle(fontSize: 13, color: AppColors.neutral600),
                ),
              ),
            ],
          ),
        ),
    ];
  }

  List<Widget> _amenities(BuildContext context) {
    final amenities = roomType.amenities;
    if (amenities.isEmpty) return const <Widget>[];

    final shown = amenities.take(4).toList();
    final extra = amenities.length - shown.length;

    return [
      const SizedBox(height: 10),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final amenity in shown) _chip(amenity.name),
          if (extra > 0)
            _chip(context.tr('hotels.amenitiesMore', args: {'n': extra})),
        ],
      ),
    ];
  }

  /// Paid add-ons offered on this room type ("Extra Bed").
  ///
  /// They are NOT in any total the app prints — the `POST /api/hotel-quote`
  /// request has no field for a service id — so the caption says so outright
  /// rather than letting a guest read them as included and be surprised at the
  /// desk.
  ///
  /// A service carries no currency of its own, so the amount is labelled with
  /// the code this room's rate plans agree on, and printed bare when they
  /// disagree (an EGP plan beside a QAR one really does happen here).
  List<Widget> _services(BuildContext context) {
    final services = roomType.services;
    if (services.isEmpty) return const <Widget>[];

    final currency = roomType.singleCurrencyCode ?? '';

    return [
      const SizedBox(height: 12),
      Text(
        context.tr('hotels.roomExtras'),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.charcoal,
        ),
      ),
      const SizedBox(height: 6),
      for (final service in services)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 16,
                color: AppColors.neutral500,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  // Backend-localized already — shown, never keyed off.
                  service.name,
                  style: TextStyle(fontSize: 13, color: AppColors.neutral600),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                service.isFree
                    ? context.tr('hotels.serviceFree')
                    : Money.format(service.price, currency),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal,
                ),
              ),
            ],
          ),
        ),
      Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          context.tr('hotels.extrasNotIncluded'),
          style: TextStyle(fontSize: 11, color: AppColors.neutral500),
        ),
      ),
    ];
  }

  Widget? _availabilityBadge(BuildContext context) {
    if (roomType.isSoldOut) {
      return _badge(context.tr('hotels.soldOut'), AppColors.error);
    }
    // Scarcity is only worth saying when it is actually scarce — and only once
    // the backend has reported a real stock. Before dates are picked it sends
    // null, and "only 0 rooms left" would be a lie.
    final units = roomType.availableUnits;
    if (units != null && units <= 3) {
      return _badge(
        context.tr(
          units == 1 ? 'hotels.unitLeftSingular' : 'hotels.unitsLeft',
          args: {'n': units},
        ),
        AppColors.warning,
      );
    }
    return null;
  }

  Widget _badge(String label, Color color) {
    return Container(
      margin: const EdgeInsetsDirectional.only(start: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Rate plans
  // ---------------------------------------------------------------------------

  List<Widget> _ratePlanRows(BuildContext context, bool soldOut) {
    // A room type with no rate plans is nothing the guest can buy, and
    // `isSoldOut` already counts it as sold out.
    if (roomType.ratePlans.isEmpty) {
      return [
        Text(
          context.tr('hotels.soldOut'),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.error,
          ),
        ),
      ];
    }

    final rows = <Widget>[];
    for (final plan in roomType.ratePlans) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 10));
      rows.add(_ratePlanRow(context, plan, enabled: !soldOut));
    }
    return rows;
  }

  Widget _ratePlanRow(
    BuildContext context,
    HotelRatePlan plan, {
    required bool enabled,
  }) {
    final rooms = selections[plan.id] ?? 0;
    final selected = rooms > 0;
    final board = hotelBoardBasisLabel(context, plan.boardBasis);

    // The quote endpoint refuses a selection that mixes currencies, so a plan in
    // a second currency is shown but not addable while another is selected.
    final blockedByCurrency = !selected &&
        lockedCurrencyCode != null &&
        lockedCurrencyCode != plan.currencyCode;

    // One room, in THIS plan's own currency. `stayPrice` is only filled when the
    // details call carried dates; the server's number is shown as it came, since
    // the quote — not this card — is the price of record.
    final priceText = nights > 0
        ? Money.format(plan.stayPrice, plan.currencyCode)
        : Money.format(plan.basePrice, plan.currencyCode);
    // `hotels.perNightFrom` interpolates a {price}; the amount is already
    // printed on its own line right above, so the caption uses the plain key.
    final priceCaption = nights > 0
        ? context.tr('hotels.perRoom')
        : blockedByCurrency
            ? context.tr('hotels.otherCurrency',
                args: {'currency': lockedCurrencyCode ?? ''})
            : context.tr('hotels.perNight');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primaryColor.withValues(alpha: 0.10)
            : AppColors.neutral50,
        border: Border.all(
          color: selected ? AppColors.primaryColor : AppColors.neutral200,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (board.isNotEmpty) ...[
                      Text(
                        board,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    ..._cancellationLines(context, plan),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    priceText,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
                    ),
                  ),
                  Text(
                    priceCaption,
                    style: TextStyle(fontSize: 11, color: AppColors.neutral500),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('hotels.roomsLabel'),
                  style: TextStyle(fontSize: 13, color: AppColors.neutral600),
                ),
              ),
              _counterBtn(
                Icons.remove,
                enabled && rooms > 0
                    ? () => onRoomsChanged(plan.id, rooms - 1)
                    : null,
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '$rooms',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
              _counterBtn(
                Icons.add,
                // Clamped to stock when the backend has reported one; before
                // dates are picked it has not, and the cap falls back to a sane
                // maximum rather than freezing the control at zero. Also blocked
                // when this plan would mix currencies into the selection.
                enabled && !blockedByCurrency && rooms < roomType.maxSelectableRooms
                    ? () => onRoomsChanged(plan.id, rooms + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// The policy line, plus the concrete deadline once a check-in exists. The
  /// free-cancellation window counts BACK from check-in, never forward from the
  /// booking date, so the copy names that anchor and the date it lands on.
  List<Widget> _cancellationLines(BuildContext context, HotelRatePlan plan) {
    final String label;
    final Color color;
    if (plan.freeCancellationDays > 0) {
      label = context.tr(
        'hotels.freeCancellationDays',
        args: {'days': plan.freeCancellationDays},
      );
      color = AppColors.success;
    } else if (plan.freeCancellationHours > 0) {
      label = context.tr(
        'hotels.freeCancellationHours',
        args: {'hours': plan.freeCancellationHours},
      );
      color = AppColors.success;
    } else if (plan.cancellationPolicyType.isNotEmpty) {
      label = context.tr(
        'hotels.cancellationPolicyType',
        args: {'type': plan.cancellationPolicyType},
      );
      color = AppColors.neutral500;
    } else {
      label = context.tr('hotels.nonRefundable');
      color = AppColors.neutral500;
    }

    final deadline = plan.freeCancellationDeadline(checkIn);
    // A deadline already in the past is not a promise worth printing.
    final showDeadline = deadline != null && deadline.isAfter(DateTime.now());

    return [
      Text(label, style: TextStyle(fontSize: 12, color: color)),
      if (showDeadline)
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            context.tr(
              'hotels.freeCancellationUntilDate',
              args: {
                'date': DateFormat(
                  'd MMM yyyy, HH:mm',
                  Localizations.localeOf(context).languageCode,
                ).format(deadline),
              },
            ),
            style: TextStyle(fontSize: 11, color: AppColors.neutral500),
          ),
        ),
    ];
  }

  Widget _counterBtn(IconData icon, VoidCallback? onTap) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? AppColors.neutral600 : AppColors.neutral200,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? AppColors.charcoal : AppColors.neutral400,
        ),
      ),
    );
  }
}
