import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_booking.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_details.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_quote.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_summary.dart';
import 'package:houseiana_mobile_app/core/services/hotel_service.dart';
import 'package:houseiana_mobile_app/core/utils/money.dart';
import 'package:houseiana_mobile_app/core/utils/number_input.dart';
import 'package:houseiana_mobile_app/features/hotels/presentation/cubit/hotel_booking_cubit.dart';
import 'package:houseiana_mobile_app/features/hotels/presentation/cubit/hotel_booking_state.dart';
import 'package:houseiana_mobile_app/features/hotels/presentation/widgets/hotel_quote_rows.dart';
import 'package:houseiana_mobile_app/features/hotels/presentation/widgets/hotel_unavailable_view.dart';
import 'package:houseiana_mobile_app/features/hotels/presentation/widgets/room_type_card.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:houseiana_mobile_app/shared/widgets/empty_state/empty_state_widget.dart';
import 'package:intl/intl.dart';

/// Hotel bookings are settled through the SAME payment flow as property
/// bookings: the hotels endpoints only create the booking, and everything
/// afterwards is addressed by `bookingId` through booking-manager, which does
/// not care which kind of stay it is. (Same reason `/booking-manager/{id}/cancel`
/// cancels a hotel stay — see the Trips screen.)
///
/// Kept as a flag rather than inlined so the flow can be turned off from one
/// place if the hotel side of it ever diverges.
const bool kHotelPaymentEnabled = true;

/// "Review your booking" — the last screen before
/// `POST /api/hotel-bookings/create`.
///
/// It never re-prices anything: the quote, the dates and the chosen rate plans
/// all arrive as route arguments from the details screen and are read-only
/// here. Changing the room count would invalidate the quote this screen was
/// handed, so the only way to change the selection is to go back.
///
/// Route arguments (`settings.arguments` as a Map):
///
/// | key | type | required |
/// |---|---|---|
/// | `hotelName`, `hotelCoverPhoto`, `hotelLocation` | String | no |
/// | `checkIn`, `checkOut` | `yyyy-MM-dd` / ISO String / DateTime | **yes** |
/// | `selections` | List of `{ratePlanId, rooms, roomTypeName, boardBasis}` | **yes** |
/// | `quote` | [HotelQuote] or its JSON map | no (breakdown hidden without it) |
/// | `adults` | int or String | no |
/// | `childrenAges` | List of int — one age per child, as PRICED | no |
///
/// A selection map may additionally carry `freeCancellationDays`,
/// `freeCancellationHours` and `cancellationPolicyType`; the cancellation
/// section renders only for the plans that do. Falling back to a default would
/// print "non-refundable" for every booking whose arguments simply omitted the
/// fields — a promise this screen is in no position to make.
class HotelBookingScreen extends StatefulWidget {
  HotelBookingScreen({super.key});

  @override
  State<HotelBookingScreen> createState() => _HotelBookingScreenState();
}

class _HotelBookingScreenState extends State<HotelBookingScreen> {
  bool _didInit = false;
  bool _loadingDialogOpen = false;

  String _hotelName = '';
  String _hotelCoverPhoto = '';
  String _hotelLocation = '';

  /// Already `yyyy-MM-dd` — the only date format the hotel endpoints take.
  String _checkIn = '';
  String _checkOut = '';

  HotelQuote? _quote;
  List<_BookedRooms> _booked = const <_BookedRooms>[];
  int _adults = 0;

  /// One age per child, exactly the list the quote on this screen was priced
  /// with. The create endpoint takes `childrenAges` too and re-prices from it,
  /// so the count is DERIVED from the ages rather than carried beside them —
  /// a count without matching ages is refused outright.
  List<int> _childrenAges = const <int>[];

  int get _children => _childrenAges.length;

  /// Text controllers keyed by field, created on demand and seeded once from
  /// the cubit's form. The cubit stays the source of truth for validity; these
  /// only hold the text, so nothing writes back into them mid-edit and the
  /// cursor never jumps.
  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};

  /// Fields the guest has typed in at least once. An empty field is only
  /// *wrong* once it has been filled and cleared — flagging a form the guest
  /// has not reached yet is noise.
  final Set<String> _touched = <String>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    _readArguments();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _readArguments() {
    final raw = ModalRoute.of(context)?.settings.arguments;
    if (raw is! Map) return;
    final args = Map<String, dynamic>.from(raw);

    _hotelName = asHotelString(args['hotelName']);
    _hotelCoverPhoto = asHotelString(args['hotelCoverPhoto']);
    _hotelLocation = asHotelString(args['hotelLocation']);
    _checkIn = _apiDay(args['checkIn']);
    _checkOut = _apiDay(args['checkOut']);
    _adults = asHotelInt(args['adults']);
    // `children` also arrives, but only as the count these ages already carry.
    _childrenAges = _readChildAges(args['childrenAges']);

    final quote = args['quote'];
    if (quote is HotelQuote) {
      _quote = quote;
    } else if (quote is Map) {
      _quote = HotelQuote.fromJson(Map<String, dynamic>.from(quote));
    }

    final rawSelections = args['selections'];
    _booked = [
      for (final entry in (rawSelections is List
          ? rawSelections.whereType<Map>()
          : const <Map>[]))
        _BookedRooms.fromArguments(Map<String, dynamic>.from(entry)),
    ].where((b) => b.ratePlanId.isNotEmpty && b.rooms > 0).toList();

    if (!_hasBooking) return;
    context.read<HotelBookingCubit>().start(
      checkIn: _checkIn,
      checkOut: _checkOut,
      selections: [
        for (final booked in _booked)
          HotelBookingSelection(
            ratePlanId: booked.ratePlanId,
            rooms: booked.rooms,
            // Occupancy is per selection in the request, but the details
            // screen only knows the party as a whole, so it goes out
            // unchanged on every line.
            adults: _adults > 0 ? _adults : 1,
            childrenAges: _childrenAges,
          ),
      ],
    );
  }

  /// Child ages as the details screen priced them.
  ///
  /// Tolerant of a list that has been through JSON (ages as strings), and
  /// drops anything negative — the backend answers those with "Child ages
  /// cannot be negative." and rejects the whole booking.
  List<int> _readChildAges(dynamic raw) {
    if (raw is! List) return const <int>[];
    final ages = <int>[];
    for (final entry in raw) {
      final age = asHotelIntOrNull(entry);
      if (age != null && age >= 0) ages.add(age);
    }
    return ages;
  }

  /// Accepts whatever the details screen hands over: a `DateTime`, an ISO
  /// timestamp or an already-formatted day. Anything with a `T` is truncated —
  /// an ISO timestamp on a hotel endpoint is the same class of bug the host
  /// calendar hit with `dd-MM-yyyy`.
  String _apiDay(dynamic value) {
    if (value is DateTime) return HotelService.apiDate(value);
    return HotelSearchParams.dateOnly(asHotelString(value)) ?? '';
  }

  bool get _hasBooking =>
      _checkIn.isNotEmpty && _checkOut.isNotEmpty && _booked.isNotEmpty;

  /// The quote's own night count wins: it is what the total on this screen was
  /// priced for. The dates only fill in for a booking that arrived without a
  /// quote.
  int get _nights {
    final quoted = _quote?.nights ?? 0;
    if (quoted > 0) return quoted;
    final start = DateTime.tryParse(_checkIn);
    final end = DateTime.tryParse(_checkOut);
    if (start == null || end == null) return 0;
    final nights = end.difference(start).inDays;
    return nights > 0 ? nights : 0;
  }

  int get _totalRooms => _booked.fold(0, (sum, b) => sum + b.rooms);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HotelBookingCubit, HotelBookingState>(
      listener: _onStateChanged,
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.cardBackground,
          appBar: AppBar(
            backgroundColor: AppColors.cardBackground,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: AppColors.charcoal),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              context.tr('hotels.reviewBooking'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: AppColors.neutral200),
            ),
          ),
          body: _body(state),
        );
      },
    );
  }

  Widget _body(HotelBookingState state) {
    if (state is HotelBookingUnavailable) return HotelUnavailableView();
    if (!_hasBooking) {
      // A deep link or a restored route that lost its arguments: there is
      // nothing to book here and nothing a retry could fix.
      return EmptyStateWidget(
        icon: Icons.hotel_outlined,
        title: context.tr('hotels.missingBookingDetails'),
        subtitle: context.tr('hotels.missingBookingDetailsDescription'),
        buttonText: context.tr('common.back'),
        onButtonPressed: () => Navigator.maybePop(context),
      );
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _hotelCard(),
                const SizedBox(height: 28),
                _sectionTitle(context.tr('hotels.yourStay')),
                const SizedBox(height: 16),
                _stayCard(),
                if (_quote != null) ...[
                  const SizedBox(height: 28),
                  _sectionTitle(context.tr('booking.priceDetails')),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.neutral200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: HotelQuoteRows(quote: _quote),
                  ),
                ],
                const SizedBox(height: 28),
                _sectionTitle(context.tr('hotels.guestDetails')),
                const SizedBox(height: 6),
                Text(
                  context.tr('hotels.guestDetailsSubtitle'),
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.neutral500,
                  ),
                ),
                const SizedBox(height: 16),
                ..._guestSections(state),
                const SizedBox(height: 28),
                _sectionTitle(context.tr('hotels.extras')),
                const SizedBox(height: 16),
                _extras(state),
                ..._cancellationSection(),
                const SizedBox(height: 20),
                _legalNotice(),
              ],
            ),
          ),
        ),
        _bottomBar(state),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Stay summary
  // ---------------------------------------------------------------------------

  Widget _hotelCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.neutral200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _hotelCoverPhoto.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: _hotelCoverPhoto,
                    width: 80,
                    height: 72,
                    fit: BoxFit.cover,
                    memCacheWidth: 240,
                    placeholder: (context, url) => Container(
                      width: 80,
                      height: 72,
                      color: AppColors.neutral100,
                    ),
                    errorWidget: (context, url, error) => _coverPlaceholder(),
                  )
                : _coverPlaceholder(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _hotelName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_hotelLocation.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _hotelLocation,
                    style: TextStyle(fontSize: 12, color: AppColors.neutral500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      width: 80,
      height: 72,
      color: AppColors.neutral100,
      child: Icon(Icons.hotel_outlined, size: 28, color: AppColors.neutral300),
    );
  }

  Widget _stayCard() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.neutral200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _stayColumn(
                    context.tr('booking.checkInLabel'),
                    _formatDay(_checkIn),
                  ),
                ),
                Container(width: 1, height: 36, color: AppColors.neutral200),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 16),
                    child: _stayColumn(
                      context.tr('booking.checkOutLabel'),
                      _formatDay(_checkOut),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.neutral200),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_nights > 0)
                  _chip(
                    Icons.nightlight_outlined,
                    context.tr(
                      _nights == 1
                          ? 'booking.nightSingular'
                          : 'booking.nightsCount',
                      args: {'n': _nights},
                    ),
                  ),
                _chip(
                  Icons.meeting_room_outlined,
                  context.tr(
                    _totalRooms == 1
                        ? 'hotels.roomSingular'
                        : 'hotels.roomsCount',
                    args: {'n': _totalRooms},
                  ),
                ),
                if (_adults > 0)
                  _chip(
                    Icons.person_outline,
                    context.tr(
                      _adults == 1
                          ? 'hotels.adultSingular'
                          : 'hotels.adultsCount',
                      args: {'n': _adults},
                    ),
                  ),
                if (_children > 0)
                  _chip(
                    Icons.child_care_outlined,
                    context.tr(
                      _children == 1
                          ? 'hotels.childSingular'
                          : 'hotels.childrenCount',
                      args: {'n': _children},
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stayColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: AppColors.neutral500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
      ],
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.neutral500),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppColors.neutral700),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Lead guests — one form per booked room
  // ---------------------------------------------------------------------------

  /// The backend rejects the whole request unless `leadGuests.length == rooms`
  /// for EVERY selection, so the forms are generated from the room counts
  /// rather than from a single "main guest" block: two rooms always means two
  /// cards, grouped under the room type they belong to.
  List<Widget> _guestSections(HotelBookingState state) {
    final sections = <Widget>[];
    for (var s = 0; s < _booked.length && s < state.selections.length; s++) {
      if (sections.isNotEmpty) sections.add(const SizedBox(height: 20));
      sections.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            _booked[s].label(context),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
        ),
      );
      for (var r = 0; r < state.selections[s].rooms; r++) {
        if (r > 0) sections.add(const SizedBox(height: 12));
        sections.add(_guestCard(state, s, r));
      }
    }
    return sections;
  }

  Widget _guestCard(
    HotelBookingState state,
    int selectionIndex,
    int roomIndex,
  ) {
    final guest = state.form.leadGuestAt(selectionIndex, roomIndex) ??
        const HotelLeadGuest();
    // Numbered across the whole booking: "Room 3" has to mean the same card to
    // the guest and to the request, even when it comes from a second rate plan.
    final roomNumber =
        state.form.globalRoomIndex(selectionIndex, roomIndex) + 1;
    final cubit = context.read<HotelBookingCubit>();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.neutral200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('hotels.leadGuestForRoom', args: {'n': roomNumber}),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.neutral700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _field(
                  fieldKey: 'g:$selectionIndex:$roomIndex:first',
                  label: context.tr('booking.guestInfoFirstNameLabel'),
                  hint: context.tr('booking.guestInfoFirstNamePlaceholder'),
                  initialValue: guest.firstName,
                  icon: Icons.person_outline,
                  requiredMessageKey: 'booking.guestInfoFirstNameRequired',
                  textInputAction: TextInputAction.next,
                  onChanged: (value) => cubit.updateLeadGuest(
                    selectionIndex: selectionIndex,
                    roomIndex: roomIndex,
                    firstName: value,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  fieldKey: 'g:$selectionIndex:$roomIndex:last',
                  label: context.tr('booking.guestInfoLastNameLabel'),
                  hint: context.tr('booking.guestInfoLastNamePlaceholder'),
                  initialValue: guest.lastName,
                  icon: Icons.person_outline,
                  requiredMessageKey: 'booking.guestInfoLastNameRequired',
                  textInputAction: TextInputAction.next,
                  onChanged: (value) => cubit.updateLeadGuest(
                    selectionIndex: selectionIndex,
                    roomIndex: roomIndex,
                    lastName: value,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _field(
            fieldKey: 'g:$selectionIndex:$roomIndex:phone',
            label: context.tr('booking.guestInfoPhoneLabel'),
            hint: context.tr('booking.guestInfoPhonePlaceholder'),
            initialValue: guest.phone,
            icon: Icons.phone_outlined,
            requiredMessageKey: 'booking.guestInfoPhoneRequired',
            keyboardType: TextInputType.phone,
            // An Arabic keyboard types ٠١٢ into this field and the hotel
            // receives digits it cannot dial.
            inputFormatters: const [WesternDigitsInputFormatter()],
            onChanged: (value) => cubit.updateLeadGuest(
              selectionIndex: selectionIndex,
              roomIndex: roomIndex,
              phone: value,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Optional extras
  // ---------------------------------------------------------------------------

  Widget _extras(HotelBookingState state) {
    final cubit = context.read<HotelBookingCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(
          fieldKey: 'specialRequests',
          label: context.tr('hotels.specialRequests'),
          hint: context.tr('hotels.specialRequestsHint'),
          initialValue: state.specialRequests,
          icon: Icons.notes_outlined,
          maxLines: 3,
          maxLength: 500,
          onChanged: cubit.setSpecialRequests,
        ),
        const SizedBox(height: 12),
        _arrivalTimeField(state),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Cancellation policy
  // ---------------------------------------------------------------------------

  List<Widget> _cancellationSection() {
    final withPolicy = _booked.where((b) => b.plan != null).toList();
    if (withPolicy.isEmpty) return const <Widget>[];

    return [
      const SizedBox(height: 28),
      _sectionTitle(context.tr('booking.cancellationPolicyTitle')),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.ghostWhite,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < withPolicy.length; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              // Naming the plan only matters when there is more than one; a
              // single-plan booking reads better as a plain policy statement.
              if (withPolicy.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    withPolicy[i].label(context),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
                    ),
                  ),
                ),
              ..._policyLines(withPolicy[i].plan!),
            ],
          ],
        ),
      ),
    ];
  }

  /// The same copy the room cards showed, so the policy a guest picked one
  /// screen back reads identically here. The free-cancellation window counts
  /// BACK from check-in — never forward from today — and with the dates already
  /// fixed the concrete deadline can be spelled out.
  List<Widget> _policyLines(HotelRatePlan plan) {
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
      color = AppColors.neutral600;
    } else {
      label = context.tr('hotels.nonRefundable');
      color = AppColors.neutral600;
    }

    final deadline = plan.freeCancellationDeadline(DateTime.tryParse(_checkIn));
    // A window that has already closed is not a promise worth printing.
    final showDeadline = deadline != null && deadline.isAfter(DateTime.now());

    return [
      Text(label, style: TextStyle(fontSize: 14, height: 1.5, color: color)),
      if (showDeadline)
        Padding(
          padding: const EdgeInsets.only(top: 4),
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
            style: TextStyle(fontSize: 13, color: AppColors.neutral500),
          ),
        ),
    ];
  }

  Widget _legalNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.neutral200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 13,
            color: AppColors.neutral500,
            height: 1.5,
          ),
          children: [
            TextSpan(text: context.tr('booking.byAgreeingPrefix')),
            TextSpan(
              text: context.tr('booking.houseRulesCancellation'),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
            TextSpan(text: context.tr('booking.andSeparator')),
            TextSpan(
              text: context.tr('booking.guestRefundPolicy'),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Submit bar
  // ---------------------------------------------------------------------------

  Widget _bottomBar(HotelBookingState state) {
    final submitting = state is HotelBookingSubmitting;
    final needsSignIn = state.form.needsSignIn;
    final quote = _quote;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (quote != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('booking.totalUsd'),
                    style: TextStyle(fontSize: 13, color: AppColors.neutral500),
                  ),
                  Text(
                    Money.format(quote.total, quote.currencyCode),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
                    ),
                  ),
                ],
              ),
            ),
          // Says why the button is dead; without it an incomplete guest form
          // just reads as a broken button.
          if (!needsSignIn && !state.canSubmit && !submitting)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                context.tr('hotels.leadGuestRequired'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.neutral500),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submitAction(state),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.brandCharcoal,
                disabledBackgroundColor: AppColors.neutral200,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.brandCharcoal,
                      ),
                    )
                  : Text(
                      context.tr(
                        needsSignIn ? 'hotels.signInToBook' : 'hotels.bookNow',
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// A signed-out guest gets a way forward instead of a dead button — the form
  /// is complete, the session is what is missing.
  VoidCallback? _submitAction(HotelBookingState state) {
    if (state is HotelBookingSubmitting) return null;
    if (state.form.needsSignIn) {
      return () => Navigator.pushNamed(context, Routes.login);
    }
    if (!state.canSubmit) return null;
    return context.read<HotelBookingCubit>().submit;
  }

  // ---------------------------------------------------------------------------
  // Outcome
  // ---------------------------------------------------------------------------

  void _onStateChanged(BuildContext context, HotelBookingState state) {
    if (state is HotelBookingSubmitting) {
      _showLoadingDialog();
      return;
    }

    _dismissLoadingDialog();

    if (state is HotelBookingCreated) {
      _onBookingCreated(state.result);
    } else if (state is HotelBookingFailure) {
      _showFailure(state.message);
    }
  }

  void _onBookingCreated(HotelBookingResult result) {
    // The booking exists either way at this point. Payment needs an id to
    // address it by, so a response that carries none falls back to the
    // confirmation dialog rather than opening a payment screen that could not
    // identify what it is charging for.
    if (kHotelPaymentEnabled && result.hasBookingId) {
      Navigator.pushNamed(
        context,
        Routes.paymentMethod,
        // Same argument shape the property flow pushes
        // (booking_request_screen.dart). `property` is deliberately absent: the
        // payment screen only reads it to look up a host WhatsApp number, and a
        // hotel has no host — it falls back to the default contact.
        arguments: {
          'bookingId': result.bookingId,
          'totalPrice': _quote?.total ?? result.total,
          'checkIn': _checkIn,
          'checkOut': _checkOut,
          'nights': _nights,
          'guests': _adults + _children,
        },
      );
      return;
    }
    _showBookingConfirmedDialog(result);
  }

  /// Fallback for a create response that carried no booking id: the stay is
  /// booked and Trips is its record, there is simply nothing to address a
  /// payment to. Also the whole flow when [kHotelPaymentEnabled] is off.
  void _showBookingConfirmedDialog(HotelBookingResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: AppColors.success,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('hotels.bookingConfirmedTitle'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.tr('hotels.bookingConfirmedMessage'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.neutral500,
              ),
            ),
            if (result.hasBookingId) ...[
              const SizedBox(height: 10),
              Text(
                context.tr(
                  'hotels.bookingReference',
                  args: {'code': result.bookingId},
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal,
                ),
              ),
            ],
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _resetToShell();
                // BottomNavCubit is created inside the shell, so the Trips tab
                // cannot be selected from out here; Routes.trips is the same
                // screen with an automatic back button to the shell.
                Navigator.of(context).pushNamed(Routes.trips);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.brandCharcoal,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                context.tr('booking.viewMyTrips'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _resetToShell();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.charcoal,
                side: BorderSide(color: AppColors.neutral200),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                context.tr('common.ok'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetToShell() {
    Navigator.of(context)
        .pushNamedAndRemoveUntil(Routes.bottomNav, (route) => false);
  }

  /// [message] is a translation key or the backend's own reason — `context.tr`
  /// renders both, since an unknown key passes straight through.
  void _showFailure(String message) {
    final timedOut = _isTimeoutMessage(message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr(timedOut ? 'hotels.bookingTimeout' : message)),
        backgroundColor: AppColors.error,
        duration: Duration(seconds: timedOut ? 8 : 4),
        // A create that timed out may well have been accepted server-side, so
        // the guest is sent to Trips to check rather than nudged into a retry
        // that could book the rooms twice.
        action: timedOut
            ? SnackBarAction(
                label: context.tr('booking.viewMyTrips'),
                textColor: AppColors.textLight,
                onPressed: () => Navigator.pushNamed(context, Routes.trips),
              )
            : null,
      ),
    );
  }

  /// The network layer collapses connect/send/receive timeouts into this one
  /// literal (`DioConsumer._handleDioException`) and the cubit forwards the
  /// message verbatim, so matching the string is the only signal available.
  bool _isTimeoutMessage(String message) =>
      message.trim().toLowerCase() == 'connection timeout';

  void _showLoadingDialog() {
    if (_loadingDialogOpen) return;
    _loadingDialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      ),
    ).whenComplete(() => _loadingDialogOpen = false);
  }

  /// Only pops when a dialog is actually open and there is something to pop: a
  /// 401 forced logout can replace the whole stack underneath us, and a blind
  /// pop then crashes on `_history.isNotEmpty`.
  void _dismissLoadingDialog() {
    if (!_loadingDialogOpen || !mounted) return;
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();
    _loadingDialogOpen = false;
  }

  // ---------------------------------------------------------------------------
  // Shared bits
  // ---------------------------------------------------------------------------

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.charcoal,
      ),
    );
  }

  Widget _field({
    required String fieldKey,
    required String label,
    required String hint,
    required String initialValue,
    required IconData icon,
    required ValueChanged<String> onChanged,
    String? requiredMessageKey,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    int? maxLength,
  }) {
    final controller = _controllers.putIfAbsent(
      fieldKey,
      () => TextEditingController(text: initialValue),
    );
    final missing = requiredMessageKey != null &&
        _touched.contains(fieldKey) &&
        controller.text.trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.neutral700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          maxLength: maxLength,
          onChanged: (value) {
            _touched.add(fieldKey);
            onChanged(value);
          },
          style: TextStyle(fontSize: 15, color: AppColors.charcoal),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 14, color: AppColors.neutral400),
            prefixIcon: Icon(icon, size: 20, color: AppColors.neutral400),
            errorText: missing ? context.tr(requiredMessageKey) : null,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.neutral200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.neutral200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.primaryColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  /// Hourly arrival slots, `HH:mm` — the exact shape the endpoint has always
  /// taken, so picking instead of typing changes nothing about the payload.
  static final List<String> _arrivalSlots = List.generate(
    24,
    (hour) => '${hour.toString().padLeft(2, '0')}:00',
  );

  /// The hour the sheet opens on when nothing is picked yet: check-in windows
  /// start early afternoon, and a list parked at 00:00 reads as "there are no
  /// afternoon options" until you scroll.
  static const int _defaultArrivalSlotIndex = 14;

  /// Arrival time is picked, never typed. As a free-text box it collected
  /// "2 pm", "الظهر" and Arabic-Indic digits — none of which the hotel's front
  /// desk can act on — and the guest had to guess the format from a hint.
  Widget _arrivalTimeField(HotelBookingState state) {
    final value = state.arrivalTime.trim();
    final hasValue = value.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('hotels.arrivalTime'),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.neutral700,
          ),
        ),
        const SizedBox(height: 6),
        // Its own Material, or the tap ripple paints underneath the field.
        Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _openArrivalTimeSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.neutral200),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule_outlined,
                      size: 20, color: AppColors.neutral400),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hasValue ? value : context.tr('hotels.arrivalTimeHint'),
                      style: TextStyle(
                        fontSize: hasValue ? 15 : 14,
                        color: hasValue
                            ? AppColors.charcoal
                            : AppColors.neutral400,
                      ),
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down,
                      size: 20, color: AppColors.neutral500),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Sheet of arrival slots. Returns the picked `HH:mm`, an empty string for
  /// "not sure" (the field is optional, so clearing it has to stay one tap
  /// away), or null when dismissed — which must leave the value untouched.
  Future<void> _openArrivalTimeSheet() async {
    final cubit = context.read<HotelBookingCubit>();
    final current = cubit.state.arrivalTime.trim();

    const tileExtent = 52.0;
    final selectedIndex = _arrivalSlots.indexOf(current);
    final focusIndex =
        selectedIndex >= 0 ? selectedIndex : _defaultArrivalSlotIndex;
    // One slot of headroom above the focused hour, so it does not sit flush
    // against the divider and look like the top of the list.
    final controller = ScrollController(
      initialScrollOffset: ((focusIndex - 1) * tileExtent).clamp(
        0.0,
        (_arrivalSlots.length - 1) * tileExtent,
      ),
    );

    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.tr('hotels.arrivalTimeSheetTitle'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.charcoal,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: Icon(Icons.close,
                            size: 20, color: AppColors.neutral500),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: AppColors.neutral200),
                // Pinned above the scroller: undoing a pick should never mean
                // scrolling back to the top of twenty-four hours.
                _arrivalTile(
                  sheetContext,
                  value: '',
                  label: context.tr('hotels.arrivalTimeNotSure'),
                  selected: current.isEmpty,
                ),
                Divider(height: 1, color: AppColors.neutral200),
                Flexible(
                  child: ListView.builder(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemExtent: tileExtent,
                    itemCount: _arrivalSlots.length,
                    itemBuilder: (_, index) => _arrivalTile(
                      sheetContext,
                      value: _arrivalSlots[index],
                      label: _arrivalSlots[index],
                      selected: _arrivalSlots[index] == current,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    controller.dispose();
    if (picked == null || !mounted) return;
    cubit.setArrivalTime(picked);
  }

  Widget _arrivalTile(
    BuildContext sheetContext, {
    required String value,
    required String label,
    required bool selected,
  }) {
    return ListTile(
      dense: true,
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          color: AppColors.charcoal,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check, size: 20, color: AppColors.primaryColor)
          : null,
      onTap: () => Navigator.pop(sheetContext, value),
    );
  }

  String _formatDay(String apiDay) {
    final day = DateTime.tryParse(apiDay);
    if (day == null) return apiDay;
    return DateFormat(
      'd MMM yyyy',
      Localizations.localeOf(context).languageCode,
    ).format(day);
  }
}

/// The display half of one selection: what the guest picked, as the details
/// screen described it. The bookable half — rooms, occupancy, lead guests —
/// lives in the cubit's form; this only names the rooms those forms belong to.
class _BookedRooms {
  final String ratePlanId;
  final int rooms;
  final String roomTypeName;
  final String boardBasis;

  /// Filled only when the arguments carried cancellation fields, and parsed
  /// through [HotelRatePlan] so the deadline maths stays the model's rather
  /// than a second copy of it.
  final HotelRatePlan? plan;

  const _BookedRooms({
    required this.ratePlanId,
    required this.rooms,
    this.roomTypeName = '',
    this.boardBasis = '',
    this.plan,
  });

  factory _BookedRooms.fromArguments(Map<String, dynamic> json) {
    final ratePlanId = asHotelString(json['ratePlanId']);
    final hasPolicy = json['freeCancellationDays'] != null ||
        json['freeCancellationHours'] != null ||
        asHotelString(json['cancellationPolicyType']).isNotEmpty;
    return _BookedRooms(
      ratePlanId: ratePlanId,
      rooms: asHotelInt(json['rooms'], 1),
      roomTypeName: asHotelString(json['roomTypeName']),
      boardBasis: asHotelString(json['boardBasis']),
      // The selection map keys the plan as `ratePlanId`; the model reads `id`.
      plan: hasPolicy
          ? HotelRatePlan.fromJson({...json, 'id': ratePlanId})
          : null,
    );
  }

  /// "Deluxe Room · Bed & Breakfast × 2" — the same phrasing the price
  /// breakdown uses for the same line.
  String label(BuildContext context) {
    final board = hotelBoardBasisLabel(context, boardBasis);
    return board.isEmpty
        ? context.tr(
            'hotels.quoteLineNoBoard',
            args: {'roomType': roomTypeName, 'rooms': rooms},
          )
        : context.tr(
            'hotels.quoteLine',
            args: {
              'roomType': roomTypeName,
              'board': board,
              'rooms': rooms,
            },
          );
  }
}
