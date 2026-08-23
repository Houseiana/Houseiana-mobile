import 'package:houseiana_mobile_app/core/models/hotel/hotel_summary.dart';

/// Models for `POST /api/hotel-quote`.
///
/// Request: `{ checkIn, checkOut, selections: [{ ratePlanId, rooms }] }`
/// Response: `{ hotelId, checkIn, checkOut, nights, lines: [...],
///              roomsSubtotal, serviceFee, total, currencyCode }`
///
/// Unlike the property `/availability` endpoint, the hotel quote's
/// `roomsSubtotal` is NOT already discounted — `total` is a plain
/// `roomsSubtotal + serviceFee`.

/// One line of what the guest wants to book, as the quote endpoint takes it.
class HotelSelection {
  final String ratePlanId;
  final int rooms;

  const HotelSelection({required this.ratePlanId, required this.rooms});

  Map<String, dynamic> toJson() => {'ratePlanId': ratePlanId, 'rooms': rooms};

  HotelSelection copyWith({int? rooms}) =>
      HotelSelection(ratePlanId: ratePlanId, rooms: rooms ?? this.rooms);
}

class HotelQuoteLine {
  final String ratePlanId;
  final String roomTypeId;
  final String roomTypeName;
  final String boardBasis;
  final int rooms;
  final double stayPricePerRoom;
  final double subtotal;

  const HotelQuoteLine({
    required this.ratePlanId,
    this.roomTypeId = '',
    this.roomTypeName = '',
    this.boardBasis = '',
    this.rooms = 1,
    this.stayPricePerRoom = 0,
    this.subtotal = 0,
  });

  factory HotelQuoteLine.fromJson(Map<String, dynamic> json) => HotelQuoteLine(
        ratePlanId: asHotelString(json['ratePlanId']),
        roomTypeId: asHotelString(json['roomTypeId']),
        roomTypeName: asHotelString(json['roomTypeName']),
        boardBasis: asHotelString(json['boardBasis']),
        rooms: asHotelInt(json['rooms'], 1),
        stayPricePerRoom: asHotelDouble(json['stayPricePerRoom']) ?? 0,
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

  /// Fingerprint of the selection this quote priced. The cubit discards a
  /// response whose signature no longer matches the live selection, so a slow
  /// quote can never overwrite the price of a newer one.
  static String signatureOf(
    String checkIn,
    String checkOut,
    List<HotelSelection> selections,
  ) {
    final parts = [
      for (final s in selections) '${s.ratePlanId}:${s.rooms}',
    ]..sort();
    return '$checkIn|$checkOut|${parts.join(",")}';
  }

  String get signature => signatureOf(
        checkIn,
        checkOut,
        [
          for (final l in lines)
            HotelSelection(ratePlanId: l.ratePlanId, rooms: l.rooms),
        ],
      );

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
