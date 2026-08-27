import 'package:houseiana_mobile_app/core/models/hotel/hotel_summary.dart';

/// Models for `POST /api/hotel-quote`.
///
/// Request: `{ checkIn, checkOut, selections: [{ ratePlanId, rooms, adults,
///             children, childrenAges }] }`
/// Response: `{ hotelId, checkIn, checkOut, nights, lines: [...],
///              roomsSubtotal, serviceFee, total, currencyCode }`
///
/// Occupancy is a PRICING INPUT, not a filter. `adults`, `children` and
/// `childrenAges` describe ONE room; the backend charges the hotel's children
/// policy per room and multiplies by `rooms`, so a line always satisfies
/// `subtotal == (stayPricePerRoom + childrenTotalPerRoom) * rooms` (verified
/// live). `adults` does not move the price today, but the endpoint rejects a
/// selection without one.
///
/// Unlike the property `/availability` endpoint, the hotel quote's
/// `roomsSubtotal` is NOT already discounted — `total` is a plain
/// `roomsSubtotal + serviceFee`.
///
/// Server-side rules, all answered as **HTTP 200 + `success:false`**:
///  * "Every selection needs at least one adult and no negative children."
///  * "childrenAges must contain exactly one age per child in every selection."
///  * "Child ages cannot be negative."

/// One line of what the guest wants to book, as the quote endpoint takes it.
class HotelSelection {
  final String ratePlanId;
  final int rooms;

  /// Adults **in one room**, not across the whole selection. Never 0 — the
  /// endpoint refuses a selection without an adult.
  final int adults;

  /// One age per child sharing **one room**, e.g. `[5, 9]` for two children.
  ///
  /// The backend refuses any selection whose `childrenAges` length differs from
  /// its `children` count, so [children] is DERIVED from this list rather than
  /// stored beside it — the mismatch it rejects is unrepresentable here. Order
  /// does not affect the price (`[9, 5]` quotes the same as `[5, 9]`).
  final List<int> childrenAges;

  const HotelSelection({
    required this.ratePlanId,
    required this.rooms,
    this.adults = 1,
    this.childrenAges = const <int>[],
  });

  int get children => childrenAges.length;

  Map<String, dynamic> toJson() => {
        'ratePlanId': ratePlanId,
        'rooms': rooms,
        // Sent even at the defaults: omitting them is legal but leaves the
        // guest's real party out of a total they are about to pay.
        'adults': adults < 1 ? 1 : adults,
        'children': children,
        'childrenAges': childrenAges,
      };

  HotelSelection copyWith({
    int? rooms,
    int? adults,
    List<int>? childrenAges,
  }) =>
      HotelSelection(
        ratePlanId: ratePlanId,
        rooms: rooms ?? this.rooms,
        adults: adults ?? this.adults,
        childrenAges: childrenAges ?? this.childrenAges,
      );
}

class HotelQuoteLine {
  final String ratePlanId;
  final String roomTypeId;
  final String roomTypeName;
  final String boardBasis;
  final int rooms;
  final double stayPricePerRoom;

  /// What the hotel's children policy adds to ONE room for the whole stay — 0
  /// on a hotel with no policy, and 0 for a child older than its `maxChildAge`.
  ///
  /// Already included in [subtotal]; it is the *reason* the subtotal is higher
  /// than `stayPricePerRoom * rooms`, never a second amount to add on.
  final double childrenTotalPerRoom;

  final double subtotal;

  const HotelQuoteLine({
    required this.ratePlanId,
    this.roomTypeId = '',
    this.roomTypeName = '',
    this.boardBasis = '',
    this.rooms = 1,
    this.stayPricePerRoom = 0,
    this.childrenTotalPerRoom = 0,
    this.subtotal = 0,
  });

  bool get hasChildrenCharge => childrenTotalPerRoom > 0;

  factory HotelQuoteLine.fromJson(Map<String, dynamic> json) => HotelQuoteLine(
        ratePlanId: asHotelString(json['ratePlanId']),
        roomTypeId: asHotelString(json['roomTypeId']),
        roomTypeName: asHotelString(json['roomTypeName']),
        boardBasis: asHotelString(json['boardBasis']),
        rooms: asHotelInt(json['rooms'], 1),
        stayPricePerRoom: asHotelDouble(json['stayPricePerRoom']) ?? 0,
        childrenTotalPerRoom: asHotelDouble(json['childrenTotalPerRoom']) ?? 0,
        subtotal: asHotelDouble(json['subtotal']) ?? 0,
      );
}

class HotelQuote {
  final String hotelId;
  final String checkIn;
  final String checkOut;
  final String currencyCode;
  final int nights;
  final List<HotelQuoteLine> lines;
  final double roomsSubtotal;
  final double serviceFee;
  final double total;

  const HotelQuote({
    this.hotelId = '',
    this.checkIn = '',
    this.checkOut = '',
    this.currencyCode = 'EGP',
    this.nights = 0,
    this.lines = const <HotelQuoteLine>[],
    this.roomsSubtotal = 0,
    this.serviceFee = 0,
    this.total = 0,
  });

  int get totalRooms => lines.fold(0, (sum, l) => sum + l.rooms);

  bool get isEmpty => lines.isEmpty;

  /// True when the hotel's children policy charged anything at all — what tells
  /// the breakdown whether a children line is worth printing.
  bool get hasChildrenCharge => lines.any((l) => l.hasChildrenCharge);

  /// Fingerprint of the selection this quote priced. The cubit discards a
  /// response whose signature no longer matches the live selection, so a slow
  /// quote can never overwrite the price of a newer one.
  ///
  /// Occupancy is part of it: children move the total, so a quote that came
  /// back for "2 adults" must not be painted over a selection that now says
  /// "2 adults + a 5-year-old". Ages are sorted because the backend prices
  /// `[9, 5]` and `[5, 9]` identically.
  ///
  /// There is deliberately no way to rebuild this from a RESPONSE: the quote
  /// echoes `rooms` but never the occupancy it priced, so a signature derived
  /// from `lines` would compare unequal to every live one.
  static String signatureOf(
    String checkIn,
    String checkOut,
    List<HotelSelection> selections,
  ) {
    final parts = [
      for (final s in selections)
        '${s.ratePlanId}:${s.rooms}:${s.adults}:'
            '${([...s.childrenAges]..sort()).join("-")}',
    ]..sort();
    return '$checkIn|$checkOut|${parts.join(",")}';
  }

  factory HotelQuote.fromJson(Map<String, dynamic> json) {
    final code = asHotelString(json['currencyCode']);
    return HotelQuote(
      hotelId: asHotelString(json['hotelId']),
      checkIn: HotelSearchParams.dateOnly(asHotelString(json['checkIn'])) ?? '',
      checkOut:
          HotelSearchParams.dateOnly(asHotelString(json['checkOut'])) ?? '',
      currencyCode: code.isEmpty ? 'EGP' : code,
      nights: asHotelInt(json['nights']),
      lines: json['lines'] is List
          ? (json['lines'] as List)
              .whereType<Map>()
              .map((e) => HotelQuoteLine.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const <HotelQuoteLine>[],
      roomsSubtotal: asHotelDouble(json['roomsSubtotal']) ?? 0,
      serviceFee: asHotelDouble(json['serviceFee']) ?? 0,
      total: asHotelDouble(json['total']) ?? 0,
    );
  }
}
