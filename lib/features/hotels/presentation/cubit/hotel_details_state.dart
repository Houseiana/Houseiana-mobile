import 'package:equatable/equatable.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_details.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_quote.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_review.dart';

/// One rich state instead of a state family.
///
/// The dates, the room selection and the priced quote all move independently and
/// several of them are in flight at once (picking dates re-fetches the hotel AND
/// re-quotes). A `loading / loaded / error` family would force the screen to
/// rebuild the whole page from an old snapshot on every one of those steps.
class HotelDetailsState extends Equatable {
  /// First load only — the page has nothing to show yet.
  final bool loading;

  /// A re-fetch on top of content that is already on screen (the guest changed
  /// the dates). Kept apart from [loading] so the page never blanks back to a
  /// skeleton under the date picker the guest just used.
  final bool reloading;

  /// Hotels are not deployed on this backend — a "coming soon" state, never a
  /// retryable error.
  final bool unavailable;

  /// Translation key OR a raw backend reason; `context.tr` renders either.
  final String? errorKey;

  final HotelDetails? hotel;
  final DateTime? checkIn;
  final DateTime? checkOut;

  /// `ratePlanId` → rooms. Only positive entries are kept; deselecting removes
  /// the key entirely. Rate plans from different room types coexist here — the
  /// booking endpoint takes several selections at once.
  final Map<String, int> selections;

  /// Adults **in one room**. Never 0 — `/api/hotel-quote` refuses a selection
  /// without an adult ("Every selection needs at least one adult and no
  /// negative children.").
  final int adults;

  /// One entry per child sharing a room, `null` until the guest picks that
  /// child's age.
  ///
  /// The age is a PRICING input — the hotel charges per age band — so a quote
  /// may not go out while any entry is still unknown. Nulls are what makes
  /// "the guest added a child but has not said how old" a state of its own
  /// rather than a silent 0-year-old.
  final List<int?> childAges;

  final HotelQuote? quote;
  final bool quoteLoading;
  final String? quoteErrorKey;

  /// First page of reviews, shown as a preview section under the details. A
  /// failure here leaves the list empty and is never surfaced — reviews must not
  /// take the page down with them.
  final List<HotelReview> reviews;
  final bool reviewsLoading;

  const HotelDetailsState({
    this.loading = false,
    this.reloading = false,
    this.unavailable = false,
    this.errorKey,
    this.hotel,
    this.checkIn,
    this.checkOut,
    this.selections = const <String, int>{},
    this.adults = 2,
    this.childAges = const <int?>[],
    this.quote,
    this.quoteLoading = false,
    this.quoteErrorKey,
    this.reviews = const <HotelReview>[],
    this.reviewsLoading = false,
  });

  int get nights => (checkIn != null && checkOut != null)
      ? checkOut!.difference(checkIn!).inDays
      : 0;

  /// A usable stay range — a half-picked or inverted range is not one, and no
  /// dated call may go out until this is true.
  bool get hasDates => checkIn != null && checkOut != null && nights > 0;

  bool get hasSelection => selections.values.any((rooms) => rooms > 0);

  int get totalRooms =>
      selections.values.fold(0, (sum, rooms) => sum + (rooms > 0 ? rooms : 0));

  int get children => childAges.length;

  /// Every child has an age, so the party is fully described and can be priced.
  bool get childAgesComplete => childAges.every((age) => age != null);

  /// The ages as the endpoints take them. Only meaningful once
  /// [childAgesComplete] — a partial list would quote fewer children than the
  /// guest asked for.
  List<int> get resolvedChildAges =>
      [for (final age in childAges) if (age != null) age];

  /// Occupancy is complete enough to price: at least one adult and an age for
  /// every child.
  bool get occupancyIsPriceable => adults > 0 && childAgesComplete;

  /// The selection in the shape `/api/hotel-quote` and the booking endpoint
  /// take. Occupancy rides on EVERY line because both endpoints read it per
  /// selection, and the stay section only knows the party as a whole.
  List<HotelSelection> get selectionList => [
        for (final entry in selections.entries)
          if (entry.value > 0)
            HotelSelection(
              ratePlanId: entry.key,
              rooms: entry.value,
              adults: adults,
              childrenAges: resolvedChildAges,
            ),
      ];

  int roomsFor(String ratePlanId) => selections[ratePlanId] ?? 0;

  HotelRatePlan? ratePlanById(String ratePlanId) {
    for (final room in hotel?.roomTypes ?? const <HotelRoomType>[]) {
      for (final plan in room.ratePlans) {
        if (plan.id == ratePlanId) return plan;
      }
    }
    return null;
  }

  /// The selected rate plans with the room type they belong to — what the
  /// booking screen lists and what tells the UI how many lead guests to collect.
  List<({HotelRoomType room, HotelRatePlan plan, int rooms})>
      get selectedPlans => [
            for (final room in hotel?.roomTypes ?? const <HotelRoomType>[])
              for (final plan in room.ratePlans)
                if (roomsFor(plan.id) > 0)
                  (room: room, plan: plan, rooms: roomsFor(plan.id)),
          ];

  /// Currency for the totals. The quote is authoritative; before one exists the
  /// cheapest plan's currency is the best guess. Never sum across currencies —
  /// [HotelDetails.hasMixedCurrencies] says when a hotel-level total is a lie.
  String get currency =>
      quote?.currencyCode ?? hotel?.cheapestRatePlan?.currencyCode ?? 'EGP';

  /// Reserve is only ever enabled against a priced quote: the guest must see the
  /// exact total the booking will charge before committing to it.
  bool get canReserve =>
      hasDates && hasSelection && quote != null && !quoteLoading && !reloading;

  HotelDetailsState copyWith({
    bool? loading,
    bool? reloading,
    bool? unavailable,
    String? errorKey,
    HotelDetails? hotel,
    DateTime? checkIn,
    DateTime? checkOut,
    Map<String, int>? selections,
    int? adults,
    List<int?>? childAges,
    HotelQuote? quote,
    bool? quoteLoading,
    String? quoteErrorKey,
    List<HotelReview>? reviews,
    bool? reviewsLoading,
    bool clearError = false,
    bool clearQuote = false,
    bool clearQuoteError = false,
    bool clearCheckIn = false,
    bool clearCheckOut = false,
  }) {
    return HotelDetailsState(
      loading: loading ?? this.loading,
      reloading: reloading ?? this.reloading,
      unavailable: unavailable ?? this.unavailable,
      errorKey: clearError ? null : (errorKey ?? this.errorKey),
      hotel: hotel ?? this.hotel,
      checkIn: clearCheckIn ? null : (checkIn ?? this.checkIn),
      checkOut: clearCheckOut ? null : (checkOut ?? this.checkOut),
      selections: selections ?? this.selections,
      adults: adults ?? this.adults,
      childAges: childAges ?? this.childAges,
      quote: clearQuote ? null : (quote ?? this.quote),
      quoteLoading: quoteLoading ?? this.quoteLoading,
      quoteErrorKey:
          clearQuoteError ? null : (quoteErrorKey ?? this.quoteErrorKey),
      reviews: reviews ?? this.reviews,
      reviewsLoading: reviewsLoading ?? this.reviewsLoading,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        reloading,
        unavailable,
        errorKey,
        hotel,
        checkIn,
        checkOut,
        selections,
        adults,
        childAges,
        quote,
        quoteLoading,
        quoteErrorKey,
        reviews,
        reviewsLoading,
      ];
}
