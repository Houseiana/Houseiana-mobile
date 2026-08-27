import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/errors/exceptions.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_details.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_quote.dart';
import 'package:houseiana_mobile_app/core/services/hotel_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/hotels/presentation/cubit/hotel_details_state.dart';

/// Drives the hotel details page: the hotel itself, the stay dates, the
/// multi-room selection and the live quote that prices it.
///
/// The three move together. Dates are a server-side input — `/details` computes
/// `nights`, `stayPrice` and `serviceFee` from the query dates — so changing
/// them re-fetches the hotel before anything can be re-priced, and a rate plan
/// that disappeared in the meantime must leave the selection with it or the
/// next quote comes back "Rate plan not found.".
class HotelDetailsCubit extends Cubit<HotelDetailsState> {
  final HotelService _service;
  final UserSession _session;
  final String hotelId;

  /// How many reviews the preview section under the details shows. The full
  /// list lives on its own screen.
  static const int reviewsPreviewLimit = 5;

  /// Occupancy caps. Both describe ONE room, which is how the quote and the
  /// booking read them — 20 adults or 10 children in a single room is already
  /// far past anything a hotel would honour, and the backend re-validates.
  static const int maxAdultsPerRoom = 20;
  static const int maxChildrenPerRoom = 10;

  HotelDetailsCubit(this._service, this._session, this.hotelId)
      : super(const HotelDetailsState(loading: true));

  /// Aborts the details/reviews request when the screen is popped mid-load.
  final CancelToken _cancelToken = CancelToken();

  /// Quotes get their own token so a superseded one can be dropped without
  /// killing the details request that shares the screen.
  CancelToken? _quoteToken;

  /// Reviews are fetched once per screen, not on every dated re-fetch.
  bool _reviewsRequested = false;

  @override
  Future<void> close() {
    _cancelToken.cancel();
    _quoteToken?.cancel();
    return super.close();
  }

  /// The signed-in guest, for the sign-in gate on Reserve and as the `guestId`
  /// the booking step needs. Null while signed out — browsing and quoting both
  /// work anonymously.
  String? get guestId => _session.userId;

  bool get isLoggedIn => _session.isLoggedIn;

  /// Opens the page, optionally with the dates the guest already searched with.
  ///
  /// Seeding them here rather than through [setDates] keeps the first paint to a
  /// single request — [setDates] deliberately re-fetches, which would be a
  /// wasted round trip before anything has loaded.
  Future<void> start({DateTime? checkIn, DateTime? checkOut}) {
    final ci = _dayOnly(checkIn);
    final co = _dayOnly(checkOut);
    emit(state.copyWith(
      checkIn: ci,
      checkOut: co,
      clearCheckIn: ci == null,
      clearCheckOut: co == null,
    ));
    return load();
  }

  /// Fetches the hotel for the current dates.
  ///
  /// Dates only go on the wire as a complete range: a half-picked one makes the
  /// backend price nothing, and sending it would zero out `stayPrice` for no
  /// reason.
  Future<void> load() async {
    final hasContent = state.hotel != null;
    emit(state.copyWith(
      loading: !hasContent,
      reloading: hasContent,
      unavailable: false,
      clearError: true,
    ));

    try {
      final hotel = await _service.getHotelDetails(
        hotelId,
        checkIn: state.hasDates ? HotelService.apiDate(state.checkIn!) : null,
        checkOut: state.hasDates ? HotelService.apiDate(state.checkOut!) : null,
        cancelToken: _cancelToken,
      );
      if (isClosed) return;

      // A rate plan the guest had selected can be gone from the new response
      // (different dates, sold out since). Keeping it would make the very next
      // quote fail with "Rate plan not found.", so the selection is pruned to
      // what the fresh payload actually offers.
      final selections = _prunedSelections(hotel, state.selections);
      final pruned = !mapEquals(selections, state.selections);
      if (pruned && kDebugMode) {
        debugPrint('[HotelDetails] dropped stale selections: '
            '${state.selections} → $selections');
      }

      emit(state.copyWith(
        hotel: hotel,
        selections: selections,
        loading: false,
        reloading: false,
        clearError: true,
        // A quote priced against a selection that no longer exists is a lie.
        clearQuote: pruned,
      ));
      unawaited(loadReviews());
    } on RequestCancelledException {
      return; // screen popped mid-load — nothing to show
    } on HotelsUnavailableException {
      if (isClosed) return;
      // Not an error state: retrying can never help on a backend without
      // hotels, so the page shows the "coming soon" view instead.
      emit(state.copyWith(loading: false, reloading: false, unavailable: true));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        loading: false,
        reloading: false,
        errorKey: _errorKeyFor(e),
      ));
    }
  }

  /// Applies a stay range, re-fetches the hotel for it, then re-prices.
  ///
  /// The re-fetch is not optional: every `stayPrice`, `serviceFee` and `nights`
  /// on screen was computed by the backend from the previous dates.
  Future<void> setDates(DateTime? checkIn, DateTime? checkOut) async {
    final ci = _dayOnly(checkIn);
    var co = _dayOnly(checkOut);
    // The picker already refuses an inverted range; this is the backstop, since
    // a 0-night range would otherwise be sent to be priced.
    if (ci != null && co != null && !co.isAfter(ci)) co = null;
    if (ci == state.checkIn && co == state.checkOut) return;

    emit(state.copyWith(
      checkIn: ci,
      checkOut: co,
      clearCheckIn: ci == null,
      clearCheckOut: co == null,
      clearQuote: true,
      quoteLoading: false,
      clearQuoteError: true,
    ));

    await load();
    if (isClosed || state.hotel == null) return;
    await refreshQuote();
  }

  /// Sets how many rooms of one rate plan the guest wants (0 deselects it).
  ///
  /// Selections on OTHER room types are untouched by design — the booking
  /// endpoint takes several selections in one request, and the web lets a guest
  /// book a double and a suite together.
  void setRooms(String ratePlanId, int rooms) {
    final next = Map<String, int>.from(state.selections);
    if (rooms <= 0) {
      next.remove(ratePlanId);
    } else {
      next[ratePlanId] = rooms;
    }
    if (mapEquals(next, state.selections)) return;

    emit(state.copyWith(
      selections: next,
      clearQuote: true,
      quoteLoading: false,
      clearQuoteError: true,
    ));
    refreshQuote();
  }

  void clearSelection() {
    if (state.selections.isEmpty) return;
    emit(state.copyWith(
      selections: const <String, int>{},
      clearQuote: true,
      quoteLoading: false,
      clearQuoteError: true,
    ));
  }

  /// Adults sharing ONE room.
  ///
  /// Occupancy stopped being display-only the day the quote started pricing
  /// it, so every change re-prices the stay rather than waiting for the
  /// booking screen to reveal a different total.
  void setAdults(int adults) {
    final next = adults.clamp(1, maxAdultsPerRoom);
    if (next == state.adults) return;
    _emitOccupancy(adults: next);
  }

  /// Children sharing ONE room.
  ///
  /// Ages already picked survive a change to the count; a child added at the
  /// end starts with NO age, and that null is what holds the quote back until
  /// the guest supplies one.
  void setChildren(int children) {
    final next = children.clamp(0, maxChildrenPerRoom);
    if (next == state.childAges.length) return;
    _emitOccupancy(childAges: [
      for (var i = 0; i < next; i++)
        i < state.childAges.length ? state.childAges[i] : null,
    ]);
  }

  /// One child's age. Null puts that child back to "age not given", which is
  /// the state a fresh child starts in.
  void setChildAge(int index, int? age) {
    if (index < 0 || index >= state.childAges.length) return;
    final next = age == null ? null : (age < 0 ? 0 : age);
    if (next == state.childAges[index]) return;
    final ages = [...state.childAges];
    ages[index] = next;
    _emitOccupancy(childAges: ages);
  }

  /// Drops the priced total the moment the party changes, then re-prices.
  /// Keeping the old quote on screen for even one frame would show a total
  /// that belongs to a different party.
  void _emitOccupancy({int? adults, List<int?>? childAges}) {
    emit(state.copyWith(
      adults: adults,
      childAges: childAges,
      clearQuote: true,
      quoteLoading: false,
      clearQuoteError: true,
    ));
    refreshQuote();
  }

  /// Prices the current selection through `POST /api/hotel-quote`.
  ///
  /// The quote is the only thing that may state a total: rate-plan prices are
  /// per room and carry no service fee. A response that arrives after the guest
  /// has changed the dates or the room count is dropped — its total belongs to a
  /// selection that is no longer on screen.
  Future<void> refreshQuote() async {
    if (!state.hasDates || !state.hasSelection) {
      emit(state.copyWith(clearQuote: true, quoteLoading: false));
      return;
    }
    // A child with no age yet is not a party the backend can price. Sending
    // the selection anyway is refused outright ("childrenAges must contain
    // exactly one age per child in every selection."), and quietly dropping
    // the child would quote a stay the guest is not taking. Not an error
    // state: the stay section asks for the age, this only keeps a total that
    // no longer describes the party off the screen.
    if (!state.occupancyIsPriceable) {
      emit(state.copyWith(
        clearQuote: true,
        quoteLoading: false,
        clearQuoteError: true,
      ));
      return;
    }

    final ci = HotelService.apiDate(state.checkIn!);
    final co = HotelService.apiDate(state.checkOut!);
    final sels = state.selectionList;
    final signature = HotelQuote.signatureOf(ci, co, sels);

    _quoteToken?.cancel();
    final token = _quoteToken = CancelToken();

    emit(state.copyWith(quoteLoading: true, clearQuoteError: true));
    try {
      final quote = await _service.getQuote(
        checkIn: ci,
        checkOut: co,
        selections: sels,
        cancelToken: token,
      );
      if (isClosed || _quoteIsStale(signature)) return;
      emit(state.copyWith(quote: quote, quoteLoading: false));
    } on RequestCancelledException {
      return; // a newer quote took over — it owns `quoteLoading` now
    } catch (e) {
      if (isClosed || _quoteIsStale(signature)) return;
      emit(state.copyWith(
        quoteLoading: false,
        // Backend reasons here are already human ("Rate plan not found."), and
        // `context.tr` passes them through untouched.
        quoteErrorKey: e is ServerException ? e.message : 'hotels.quoteFailed',
        clearQuote: true,
      ));
    }
  }

  /// First page of reviews for the preview section.
  ///
  /// Deliberately silent on failure: reviews are secondary content and the row
  /// shape is unverified, so a bad payload must not replace a working page with
  /// an error.
  Future<void> loadReviews({bool force = false}) async {
    if (_reviewsRequested && !force) return;
    _reviewsRequested = true;
    emit(state.copyWith(reviewsLoading: true));
    try {
      final reviews = await _service.getReviews(
        hotelId,
        limit: reviewsPreviewLimit,
        cancelToken: _cancelToken,
      );
      if (isClosed) return;
      emit(state.copyWith(reviews: reviews, reviewsLoading: false));
    } on RequestCancelledException {
      return;
    } catch (e) {
      if (kDebugMode) debugPrint('[HotelDetails] reviews failed: $e');
      _reviewsRequested = false; // a pull-to-refresh may retry
      if (isClosed) return;
      emit(state.copyWith(reviewsLoading: false));
    }
  }

  /// Backend reason when there is one, translation key otherwise.
  ///
  /// The timeout key wins over the reason: this backend scales to zero, so the
  /// first call of a session can time out while being perfectly healthy, and
  /// "the server is being slow" is both truer and more actionable than whatever
  /// Dio put in the message.
  String _errorKeyFor(Object error) {
    final fallback = loadErrorKeyFor(error);
    if (fallback == 'common.slowServer') return fallback;
    return error is ServerException && error.message.trim().isNotEmpty
        ? error.message
        : fallback;
  }

  /// Keeps only the selected rate plans the fresh payload still offers, capped
  /// at the units it says are left.
  Map<String, int> _prunedSelections(
    HotelDetails hotel,
    Map<String, int> current,
  ) {
    if (current.isEmpty) return const <String, int>{};
    final next = <String, int>{};
    for (final room in hotel.roomTypes) {
      for (final plan in room.ratePlans) {
        final rooms = current[plan.id] ?? 0;
        if (rooms <= 0) continue;
        // A room type that actually sold out for the new dates loses its
        // selection outright — keeping it would make every later quote fail
        // with "Rate plan not found." / no availability, with no way for the
        // guest to clear it.
        if (room.isSoldOut) continue;
        // Stock can also shrink between two loads. Cap only against a stock the
        // backend really reported: null means "no dates were sent", not zero.
        final stock = room.availableUnits;
        next[plan.id] = stock != null ? min(rooms, stock) : rooms;
      }
    }
    return next;
  }

  /// True when the quote that just came back no longer describes what is on
  /// screen.
  ///
  /// Recomputed from LIVE state, dates included. Comparing against the dates
  /// captured before the await only ever catches a room-count change — a guest
  /// who switched dates mid-request would have the old range's total painted
  /// over the new one.
  bool _quoteIsStale(String signature) {
    if (!state.hasDates) return true;
    final live = HotelQuote.signatureOf(
      HotelService.apiDate(state.checkIn!),
      HotelService.apiDate(state.checkOut!),
      state.selectionList,
    );
    return live != signature;
  }

  /// Calendar day, no time — the hotels API takes plain `yyyy-MM-dd`, and a
  /// stray time component would make [HotelDetailsState.nights] off by one.
  DateTime? _dayOnly(DateTime? value) =>
      value == null ? null : DateTime(value.year, value.month, value.day);
}
