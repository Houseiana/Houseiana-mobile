import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/errors/exceptions.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_booking.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_quote.dart';
import 'package:houseiana_mobile_app/core/services/hotel_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/hotels/presentation/cubit/hotel_booking_state.dart';

/// Owns the hotel booking form and the single `POST /api/hotel-bookings/create`
/// call behind it.
///
/// The reason it holds form state at all is the backend's hard rule: *every*
/// selection must carry exactly one lead guest per booked room, or the request
/// comes back `success:false` with "Every selection must provide one lead guest
/// per room". Keeping the guest lists here — resized together with the room
/// count instead of assembled at submit time — makes an out-of-sync request
/// unrepresentable.
class HotelBookingCubit extends Cubit<HotelBookingState> {
  final HotelService _service;
  final UserSession _session;

  /// Fingerprint of the selection [start] was last called with. The screen
  /// reads its route arguments in `didChangeDependencies`, which can fire more
  /// than once; re-seeding there would wipe whatever the guest already typed.
  String? _signature;

  /// Submit counter, carried into [HotelBookingFailure] so a repeated identical
  /// rejection is still a new state and still reaches the screen.
  int _attempt = 0;

  HotelBookingCubit(this._service, this._session)
      : super(const HotelBookingInitial());

  /// Seeds the form from what the details screen booked: the dates it quoted
  /// and one selection per chosen rate plan. A no-op for an unchanged
  /// selection.
  void start({
    required String checkIn,
    required String checkOut,
    required List<HotelBookingSelection> selections,
  }) {
    final signature = HotelQuote.signatureOf(
      checkIn,
      checkOut,
      [
        for (final s in selections)
          HotelSelection(ratePlanId: s.ratePlanId, rooms: s.rooms),
      ],
    );
    if (signature == _signature) return;
    _signature = signature;

    _emitForm(
      state.form.copyWith(
        // Read live rather than at construction time: the guest may have signed
        // in between app launch and reaching this screen.
        guestId: _session.userId ?? '',
        checkIn: checkIn,
        checkOut: checkOut,
        selections: _withLeadGuests(selections),
      ),
    );
  }

  /// Room-count change. Guests already typed for the surviving rooms stay in
  /// place; only the tail is added or dropped.
  void setRooms(int selectionIndex, int rooms) {
    if (selectionIndex < 0 || selectionIndex >= state.selections.length) return;
    if (rooms < 1) return;
    final current = state.selections[selectionIndex];
    if (current.rooms == rooms) return;

    final updated = [...state.selections];
    updated[selectionIndex] = current.copyWith(
      rooms: rooms,
      leadGuests: _fit(current.leadGuests, rooms),
    );
    // The seeded selection no longer describes the form, so a later start()
    // with the original arguments must be allowed to run again.
    _signature = null;
    _emitForm(state.form.copyWith(selections: _withPrefill(updated)));
  }

  /// Per-field so the screen can push one `onChanged` at a time without
  /// rebuilding a whole guest at the call site.
  void updateLeadGuest({
    required int selectionIndex,
    required int roomIndex,
    String? firstName,
    String? lastName,
    String? phone,
  }) {
    final guest = state.form.leadGuestAt(selectionIndex, roomIndex);
    if (guest == null) return;

    final selection = state.selections[selectionIndex];
    final guests = [...selection.leadGuests];
    guests[roomIndex] = guest.copyWith(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
    );

    final updated = [...state.selections];
    updated[selectionIndex] = selection.copyWith(leadGuests: guests);
    _emitForm(state.form.copyWith(selections: updated));
  }

  void setSpecialRequests(String value) =>
      _emitForm(state.form.copyWith(specialRequests: value));

  void setArrivalTime(String value) =>
      _emitForm(state.form.copyWith(arrivalTime: value));

  /// Submits the form this cubit holds. The screen's button binds to
  /// `state.canSubmit`, which is the same predicate [createBooking] re-checks
  /// before touching the network.
  Future<void> submit() {
    final form = state.form.copyWith(guestId: _session.userId ?? '');
    return createBooking(form.toRequest());
  }

  Future<void> createBooking(HotelBookingRequest request) async {
    final form = state.form;
    final attempt = ++_attempt;
    if (!_session.isLoggedIn) {
      emit(HotelBookingFailure('hotels.signInToBook', form, attempt));
      return;
    }
    if (!request.isValid) {
      // The lead-guest rule is the only way a request built by this screen can
      // be invalid, so it gets the specific message.
      emit(HotelBookingFailure('hotels.leadGuestRequired', form, attempt));
      return;
    }

    emit(HotelBookingSubmitting(form));
    try {
      final result = await _service.createBooking(request);
      if (isClosed) return;
      emit(HotelBookingCreated(result, form));
    } on HotelsUnavailableException {
      // Must precede the ServerException clause — it is a subclass of it.
      if (!isClosed) emit(HotelBookingUnavailable(form));
    } on ServerException catch (e) {
      // Already a human backend reason, or a translation key; either renders
      // through `context.tr`.
      if (!isClosed) emit(HotelBookingFailure(e.message, form, attempt));
    } catch (_) {
      if (isClosed) return;
      emit(HotelBookingFailure('hotels.bookingFailed', form, attempt));
    }
  }

  /// Editing always lands back on [HotelBookingInitial] so a failure message
  /// from a previous attempt does not survive the correction that fixes it.
  void _emitForm(HotelBookingForm form) {
    if (isClosed) return;
    emit(HotelBookingInitial(form));
  }

  /// Gives every selection exactly `rooms` lead guests, carrying over anything
  /// already typed for the same rate plan.
  List<HotelBookingSelection> _withLeadGuests(
    List<HotelBookingSelection> selections,
  ) {
    final typed = <String, List<HotelLeadGuest>>{
      for (final s in state.selections) s.ratePlanId: s.leadGuests,
    };
    return _withPrefill([
      for (final s in selections)
        s.copyWith(
          leadGuests: _fit(
            s.leadGuests.isNotEmpty
                ? s.leadGuests
                : (typed[s.ratePlanId] ?? const <HotelLeadGuest>[]),
            s.rooms,
          ),
        ),
    ]);
  }

  List<HotelLeadGuest> _fit(List<HotelLeadGuest> guests, int rooms) => [
        for (var i = 0; i < rooms; i++)
          i < guests.length ? guests[i] : const HotelLeadGuest(),
      ];

  /// Convenience only: room 1's lead guest is nearly always the person booking,
  /// so it starts filled from the session. Never overwrites typed input, and is
  /// a no-op for a session with no name or phone on file.
  List<HotelBookingSelection> _withPrefill(
    List<HotelBookingSelection> selections,
  ) {
    if (selections.isEmpty) return selections;
    final first = selections.first;
    if (first.leadGuests.isEmpty) return selections;

    final existing = first.leadGuests.first;
    if (existing.firstName.isNotEmpty ||
        existing.lastName.isNotEmpty ||
        existing.phone.isNotEmpty) {
      return selections;
    }

    final me = HotelLeadGuest(
      firstName: _session.firstName ?? '',
      lastName: _session.lastName ?? '',
      phone: _session.phone ?? '',
    );
    if (me.firstName.isEmpty && me.lastName.isEmpty && me.phone.isEmpty) {
      return selections;
    }

    return [
      first.copyWith(leadGuests: [me, ...first.leadGuests.skip(1)]),
      ...selections.skip(1),
    ];
  }
}
