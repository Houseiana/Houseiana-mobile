import 'package:equatable/equatable.dart';

/// Status of a single day returned by `/api/property-calendar`.
enum CalendarStatus { available, booked, pending, reserved, blocked, unknown }

/// Parses the backend status string (e.g. `BOOKED`, `Blocked`) into a
/// [CalendarStatus]. Case-insensitive.
CalendarStatus parseCalendarStatus(dynamic raw) {
  switch ((raw ?? '').toString().toUpperCase()) {
    case 'AVAILABLE':
      return CalendarStatus.available;
    case 'BOOKED':
      return CalendarStatus.booked;
    case 'PENDING':
      return CalendarStatus.pending;
    case 'RESERVED':
      return CalendarStatus.reserved;
    case 'BLOCKED':
      return CalendarStatus.blocked;
    default:
      return CalendarStatus.unknown;
  }
}

/// One day slot of the host calendar.
class CalendarDay extends Equatable {
  /// Normalized to `DateTime(year, month, day)` (no time component).
  final DateTime date;
  final CalendarStatus status;
  final double? price;
  final String? bookedByName;
  final String? reason;
  final String? currency;

  const CalendarDay({
    required this.date,
    required this.status,
    this.price,
    this.bookedByName,
    this.reason,
    this.currency,
  });

  /// BOOKED / PENDING / RESERVED are all treated as occupied (matches web).
  bool get isBookedLike =>
      status == CalendarStatus.booked ||
      status == CalendarStatus.pending ||
      status == CalendarStatus.reserved;

  bool get isBlocked => status == CalendarStatus.blocked;

  /// `yyyy-MM-dd` key built from numeric parts (timezone-safe).
  String get key => dayKey(date);

  factory CalendarDay.fromJson(Map<String, dynamic> json) {
    final parsed = DateTime.tryParse((json['date'] ?? '').toString());
    final normalized = parsed != null
        ? DateTime(parsed.year, parsed.month, parsed.day)
        : DateTime(1970);
    var status = parseCalendarStatus(json['status'] ?? json['lockStatus']);
    // Some payloads only flag availability; treat an unavailable, non-booked
    // day as blocked.
    if ((status == CalendarStatus.available ||
            status == CalendarStatus.unknown) &&
        json['isAvailable'] == false) {
      status = CalendarStatus.blocked;
    }
    return CalendarDay(
      date: normalized,
      status: status,
      price: _toDouble(json['price']),
      bookedByName: (json['bookedByName'] ?? json['guestName'])?.toString(),
      reason: (json['reason'] ?? json['reasonBlockStatus'])?.toString(),
      currency: json['currency']?.toString(),
    );
  }

  @override
  List<Object?> get props =>
      [date, status, price, bookedByName, reason, currency];
}

/// A contiguous run of occupied days grouped into a single reservation.
class CalendarBooking extends Equatable {
  final DateTime start; // first night
  final DateTime end; // last night (inclusive)
  final CalendarStatus status;
  final String? guestName;

  const CalendarBooking({
    required this.start,
    required this.end,
    required this.status,
    this.guestName,
  });

  bool get isPending =>
      status == CalendarStatus.pending || status == CalendarStatus.reserved;

  /// The check-out day (day after the last night).
  DateTime get checkoutDay =>
      DateTime(end.year, end.month, end.day).add(const Duration(days: 1));

  @override
  List<Object?> get props => [start, end, status, guestName];
}

/// `yyyy-MM-dd` built from numeric components — never via `toIso8601String`
/// on a non-normalized value (avoids UTC day-shift).
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
