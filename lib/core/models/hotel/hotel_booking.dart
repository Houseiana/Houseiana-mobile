import 'package:houseiana_mobile_app/core/models/hotel/hotel_summary.dart';

/// Models for `POST /api/hotel-bookings/create`.
///
/// Body: `{ guestId, checkIn, checkOut, selections: [...], specialRequests,
///          arrivalTime }`

/// One named occupant. The backend needs exactly one of these per booked room.
class HotelLeadGuest {
  final String firstName;
  final String lastName;
  final String phone;

  const HotelLeadGuest({
    this.firstName = '',
    this.lastName = '',
    this.phone = '',
  });

  bool get isComplete =>
      firstName.trim().isNotEmpty &&
      lastName.trim().isNotEmpty &&
      phone.trim().isNotEmpty;

  String get displayName => [firstName.trim(), lastName.trim()]
      .where((s) => s.isNotEmpty)
      .join(' ');

  HotelLeadGuest copyWith({
    String? firstName,
    String? lastName,
    String? phone,
  }) =>
      HotelLeadGuest(
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        phone: phone ?? this.phone,
      );

  Map<String, dynamic> toJson() => {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'phone': phone.trim(),
      };
}

class HotelBookingSelection {
  final String ratePlanId;
  final int rooms;
  final int adults;
  final int children;
  final List<HotelLeadGuest> leadGuests;

  const HotelBookingSelection({
    required this.ratePlanId,
    this.rooms = 1,
    this.adults = 1,
    this.children = 0,
    this.leadGuests = const <HotelLeadGuest>[],
  });

  /// HARD backend rule, enforced server-side with
  /// "Every selection must provide one lead guest per room
  /// (leadGuests count must equal rooms)." Checking it here keeps the whole
  /// request off the wire when the form is incomplete.
  bool get isValid =>
      ratePlanId.isNotEmpty &&
      rooms > 0 &&
      leadGuests.length == rooms &&
      leadGuests.every((g) => g.isComplete);

  HotelBookingSelection copyWith({
    int? rooms,
    int? adults,
    int? children,
    List<HotelLeadGuest>? leadGuests,
  }) =>
      HotelBookingSelection(
        ratePlanId: ratePlanId,
        rooms: rooms ?? this.rooms,
        adults: adults ?? this.adults,
        children: children ?? this.children,
        leadGuests: leadGuests ?? this.leadGuests,
      );

  Map<String, dynamic> toJson() => {
        'ratePlanId': ratePlanId,
        'rooms': rooms,
        'adults': adults,
        'children': children,
        'leadGuests': [for (final g in leadGuests) g.toJson()],
      };
}

class HotelBookingRequest {
  final String guestId;

  /// Already `yyyy-MM-dd` — never an ISO timestamp.
  final String checkIn;
  final String checkOut;

  final List<HotelBookingSelection> selections;
  final String specialRequests;
  final String arrivalTime;

  const HotelBookingRequest({
    required this.guestId,
    required this.checkIn,
    required this.checkOut,
    this.selections = const <HotelBookingSelection>[],
    this.specialRequests = '',
    this.arrivalTime = '',
  });

  bool get isValid =>
      guestId.isNotEmpty &&
      checkIn.isNotEmpty &&
      checkOut.isNotEmpty &&
      selections.isNotEmpty &&
      selections.every((s) => s.isValid);

  int get totalRooms => selections.fold(0, (sum, s) => sum + s.rooms);

  Map<String, dynamic> toJson() => {
        'guestId': guestId,
        'checkIn': checkIn,
        'checkOut': checkOut,
        'selections': [for (final s in selections) s.toJson()],
        'specialRequests': specialRequests.trim(),
        'arrivalTime': arrivalTime.trim(),
      };
}

/// The create-booking response shape is NOT verified against a successful call
/// (probing it would have written real data to the backend), so every field is
/// read through aliases, nothing throws on a missing key, and the untouched
/// payload is kept in [raw] for whatever the screen turns out to need.
class HotelBookingResult {
  final String bookingId;
  final String status;
  final double? total;
  final String? currencyCode;
  final Map<String, dynamic> raw;

  const HotelBookingResult({
    this.bookingId = '',
    this.status = '',
    this.total,
    this.currencyCode,
    this.raw = const <String, dynamic>{},
  });

  bool get hasBookingId => bookingId.isNotEmpty;

  factory HotelBookingResult.fromJson(Map<String, dynamic> json) =>
      HotelBookingResult(
        bookingId: asHotelString(
          json['bookingId'] ??
              json['id'] ??
              json['_id'] ??
              json['hotelBookingId'] ??
              json['bookingCode'],
        ),
        status: asHotelString(json['status'] ?? json['bookingStatus']),
        total: asHotelDouble(json['total'] ?? json['totalPrice']),
        currencyCode: () {
          final code = asHotelString(json['currencyCode'] ?? json['currency']);
          return code.isEmpty ? null : code;
        }(),
        raw: json,
      );
}
