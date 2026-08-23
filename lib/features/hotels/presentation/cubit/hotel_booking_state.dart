import 'package:equatable/equatable.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_booking.dart';

/// The editable half of the hotel booking screen.
///
/// It lives outside the state subclasses so the guest's typing survives every
/// status change: submitting, failing and coming back to edit all carry the
/// same [HotelBookingForm] forward. The one invariant it exists to protect is
/// the backend's hard rule — one lead guest per booked room for EVERY
/// selection — which the cubit keeps true by re-fitting [HotelLeadGuest] lists
/// whenever the room count moves.
class HotelBookingForm extends Equatable {
  /// Clerk user id. Empty when signed out, which is also what makes
  /// [canSubmit] false — see [needsSignIn].
  final String guestId;

  /// Already `yyyy-MM-dd`, exactly as the hotel endpoints take it.
  final String checkIn;
  final String checkOut;

  final List<HotelBookingSelection> selections;
  final String specialRequests;
  final String arrivalTime;

  const HotelBookingForm({
    this.guestId = '',
    this.checkIn = '',
    this.checkOut = '',
    this.selections = const <HotelBookingSelection>[],
    this.specialRequests = '',
    this.arrivalTime = '',
  });

  int get totalRooms => selections.fold(0, (sum, s) => sum + s.rooms);

  /// Room number across the WHOLE booking, not within one selection: the form
  /// numbers rooms 1..n continuously even when they come from two different
  /// rate plans, so "Room 3" means the same card to the guest and to us.
  int globalRoomIndex(int selectionIndex, int roomIndex) {
    var offset = 0;
    for (var i = 0; i < selectionIndex && i < selections.length; i++) {
      offset += selections[i].rooms;
    }
    return offset + roomIndex;
  }

  /// Null instead of throwing — the screen rebuilds against a state that may
  /// already have shrunk the list under it.
  HotelLeadGuest? leadGuestAt(int selectionIndex, int roomIndex) {
    if (selectionIndex < 0 || selectionIndex >= selections.length) return null;
    final guests = selections[selectionIndex].leadGuests;
    if (roomIndex < 0 || roomIndex >= guests.length) return null;
    return guests[roomIndex];
  }

  HotelBookingRequest toRequest() => HotelBookingRequest(
        guestId: guestId,
        checkIn: checkIn,
        checkOut: checkOut,
        selections: selections,
        specialRequests: specialRequests,
        arrivalTime: arrivalTime,
      );

  /// Mirrors [HotelBookingRequest.isValid] by asking the request itself, so the
  /// enabled/disabled button and the network guard can never drift apart — an
  /// invalid request has no path to the wire.
  bool get canSubmit => toRequest().isValid;

  /// Distinguishes "not signed in" from "form incomplete"; both make
  /// [canSubmit] false but only one of them is fixable by typing.
  bool get needsSignIn => guestId.isEmpty;

  HotelBookingForm copyWith({
    String? guestId,
    String? checkIn,
    String? checkOut,
    List<HotelBookingSelection>? selections,
    String? specialRequests,
    String? arrivalTime,
  }) =>
      HotelBookingForm(
        guestId: guestId ?? this.guestId,
        checkIn: checkIn ?? this.checkIn,
        checkOut: checkOut ?? this.checkOut,
        selections: selections ?? this.selections,
        specialRequests: specialRequests ?? this.specialRequests,
        arrivalTime: arrivalTime ?? this.arrivalTime,
      );

  // `HotelBookingSelection`/`HotelLeadGuest` are plain models without value
  // equality, so two lists compare by element identity here. The cubit always
  // rebuilds the list it emits, which makes every real edit a new state; a
  // no-op edit re-emits the same instances and bloc drops it.
  @override
  List<Object?> get props => [
        guestId,
        checkIn,
        checkOut,
        selections,
        specialRequests,
        arrivalTime,
      ];
}

abstract class HotelBookingState extends Equatable {
  final HotelBookingForm form;

  const HotelBookingState(this.form);

  List<HotelBookingSelection> get selections => form.selections;
  String get specialRequests => form.specialRequests;
  String get arrivalTime => form.arrivalTime;
  int get totalRooms => form.totalRooms;
  bool get canSubmit => form.canSubmit;

  @override
  List<Object?> get props => [form];
}

/// Idle *and* editing: every keystroke lands back here, which also clears a
/// previous [HotelBookingFailure] so a stale error cannot outlive the fix.
class HotelBookingInitial extends HotelBookingState {
  const HotelBookingInitial([super.form = const HotelBookingForm()]);
}

class HotelBookingSubmitting extends HotelBookingState {
  const HotelBookingSubmitting([super.form = const HotelBookingForm()]);
}

class HotelBookingCreated extends HotelBookingState {
  final HotelBookingResult result;

  const HotelBookingCreated(
    this.result, [
    super.form = const HotelBookingForm(),
  ]);

  @override
  List<Object?> get props => [result, form];
}

/// [message] is either a translation key or the backend's own reason string;
/// `context.tr` passes an unknown key through unchanged, so the screen renders
/// both the same way.
class HotelBookingFailure extends HotelBookingState {
  final String message;

  /// Bumped by the cubit on every submit. Two identical local rejections in a
  /// row (tapping Book twice with the same incomplete form) would otherwise be
  /// value-equal, and bloc drops an equal state — the second tap would show no
  /// snackbar at all.
  final int attempt;

  const HotelBookingFailure(
    this.message, [
    super.form = const HotelBookingForm(),
    this.attempt = 0,
  ]);

  @override
  List<Object?> get props => [message, form, attempt];
}

/// Hotels are not deployed on this backend — the screen shows the "coming
/// soon" view, never a retry.
class HotelBookingUnavailable extends HotelBookingState {
  const HotelBookingUnavailable([super.form = const HotelBookingForm()]);
}
