import 'package:equatable/equatable.dart';
import 'package:houseiana_mobile_app/core/models/booking_model.dart';

enum TripStatus {
  upcoming('UPCOMING'),
  past('PAST'),
  cancelled('CANCELLED'),
  needToPay('NEEDTOPAY');

  final String value;
  const TripStatus(this.value);

  static TripStatus fromString(String? status) {
    if (status == null) return TripStatus.upcoming;
    final upper = status.toUpperCase().replaceAll(' ', '').replaceAll('_', '');
    if (upper == 'PAST' || upper == 'COMPLETED') return TripStatus.past;
    if (upper == 'CANCELLED') return TripStatus.cancelled;
    if (upper == 'NEEDTOPAY') return TripStatus.needToPay;
    return TripStatus.upcoming;
  }
}

/// A single tab in the guest Trips screen, sourced from the
/// `GET /api/Lookups/BookingStatus` lookup ( `[{ id, name }]` ).
///
/// [filter] is what gets passed as the `status` query param to the
/// user-trips endpoint — the lookup `id` (int) for live data, or a legacy
/// status string for the offline [fallback].
class TripFilterTab extends Equatable {
  final Object filter;
  final String label;

  const TripFilterTab({required this.filter, required this.label});

  factory TripFilterTab.fromJson(Map<String, dynamic> json) => TripFilterTab(
        filter: (json['id'] as num?)?.toInt() ?? json['id'] ?? '',
        label: (json['name'] ?? '').toString(),
      );

  /// Used when the lookup call fails so the screen stays functional.
  static const List<TripFilterTab> fallback = [
    TripFilterTab(filter: 'UPCOMING', label: 'Upcoming'),
    TripFilterTab(filter: 'PAST', label: 'Past'),
    TripFilterTab(filter: 'CANCELLED', label: 'Cancelled'),
  ];

  /// Stable key for caching results per tab.
  String get key => filter.toString();

  @override
  List<Object?> get props => [filter, label];
}

class TripModel extends Equatable {
  final String id;
  final String propertyId;
  final String? userId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final double totalPrice;
  final TripStatus status;
  final PropertySummary? property;
  final String? message;
  final DateTime? createdAt;

  // Flat fields returned by `GET /users/{userId}/user-trips` (web parity).
  // The endpoint does NOT nest a `property` object — it returns these directly.
  final String? propertyTitleFlat;
  final String? propertyCoverPhoto;
  final String? currency;
  final String? confirmationCode;
  final String? paymentStatus;
  final double? amountPaid;
  final String? hostName;
  final String? hostId;
  final double? averageRating;
  final DateTime? cancelledAt;
  final DateTime? paymentDueDate;

  const TripModel({
    required this.id,
    required this.propertyId,
    this.userId,
    required this.checkIn,
    required this.checkOut,
    this.guests = 1,
    required this.totalPrice,
    this.status = TripStatus.upcoming,
    this.property,
    this.message,
    this.createdAt,
    this.propertyTitleFlat,
    this.propertyCoverPhoto,
    this.currency,
    this.confirmationCode,
    this.paymentStatus,
    this.amountPaid,
    this.hostName,
    this.hostId,
    this.averageRating,
    this.cancelledAt,
    this.paymentDueDate,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    PropertySummary? propertySummary;
    if (json['property'] is Map) {
      propertySummary =
          PropertySummary.fromJson(json['property'] as Map<String, dynamic>);
    }

    DateTime? parseDate(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());

    return TripModel(
      id: json['_id'] ?? json['id'] ?? json['bookingId'] ?? '',
      propertyId: json['property'] is Map
          ? (json['property']['_id'] ?? json['property']['id'] ?? '').toString()
          : (json['property'] ?? json['propertyId'] ?? '').toString(),
      userId: json['user']?.toString(),
      checkIn: DateTime.parse(json['checkInDate'] ??
          json['checkIn'] ??
          DateTime.now().toIso8601String()),
      checkOut: DateTime.parse(json['checkOutDate'] ??
          json['checkOut'] ??
          DateTime.now().toIso8601String()),
      guests: json['guests'] as int? ?? json['numberOfGuests'] as int? ?? 1,
      totalPrice: _toDouble(json['totalPrice'] ?? json['total'] ?? 0),
      status: TripStatus.fromString(json['status'] as String?),
      property: propertySummary,
      message: json['message'] as String?,
      createdAt: parseDate(json['createdAt']),
      propertyTitleFlat: json['propertyTitle'] as String?,
      propertyCoverPhoto: json['propertyCoverPhoto'] as String?,
      currency: json['currency'] as String?,
      confirmationCode: json['confirmationCode'] as String?,
      paymentStatus: json['paymentStatus'] as String?,
      amountPaid: json['amountPaid'] != null ? _toDouble(json['amountPaid']) : null,
      hostName: json['hostName'] as String?,
      hostId: json['hostId'] as String?,
      averageRating:
          json['averageRating'] != null ? _toDouble(json['averageRating']) : null,
      cancelledAt: parseDate(json['cancelledAt']),
      paymentDueDate: parseDate(json['paymentDueDate']),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'property': propertyId,
        'propertyId': propertyId,
        'user': userId,
        'checkInDate': checkIn.toIso8601String(),
        'checkOutDate': checkOut.toIso8601String(),
        'guests': guests,
        'totalPrice': totalPrice,
        'status': status.value,
        'propertyTitle': displayTitle,
        'propertyCoverPhoto': imageUrl,
        'currency': currency,
        'confirmationCode': confirmationCode,
        'paymentStatus': paymentStatus,
        'amountPaid': amountPaid,
        'hostName': hostName,
        'hostId': hostId,
      };

  int get nights => checkOut.difference(checkIn).inDays;
  bool get isUpcoming => status == TripStatus.upcoming;
  bool get isPast => status == TripStatus.past;
  bool get isCancelled => status == TripStatus.cancelled;
  bool get isNeedToPay => status == TripStatus.needToPay;

  /// Title preferring the flat web field, then a nested property, then fallback.
  String get displayTitle {
    if (propertyTitleFlat != null && propertyTitleFlat!.isNotEmpty) {
      return propertyTitleFlat!;
    }
    return property?.displayTitle ?? 'Property';
  }

  /// Cover image preferring the flat web field, then nested property photos.
  String get imageUrl {
    if (propertyCoverPhoto != null && propertyCoverPhoto!.isNotEmpty) {
      return propertyCoverPhoto!;
    }
    return property?.firstImageUrl ?? '';
  }

  /// Currency code shown next to the total (web defaults to EGP).
  String get currencyLabel =>
      (currency != null && currency!.isNotEmpty) ? currency! : 'EGP';

  String get formattedCheckIn => _formatDate(checkIn);
  String get formattedCheckOut => _formatDate(checkOut);

  String get bookingIdFormatted {
    final code =
        (confirmationCode != null && confirmationCode!.isNotEmpty)
            ? confirmationCode!
            : id;
    if (code.isEmpty) return '';
    return '#HOU-${code.substring(0, code.length.clamp(0, 6))}';
  }

  @override
  List<Object?> get props => [id, propertyId, checkIn, checkOut, status];
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

String _formatDate(DateTime dt) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}
