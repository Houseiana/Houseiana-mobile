import 'package:equatable/equatable.dart';
import 'package:houseiana_mobile_app/core/models/booking_model.dart';

enum TripStatus {
  upcoming('UPCOMING'),
  past('PAST'),
  cancelled('CANCELLED');

  final String value;
  const TripStatus(this.value);

  static TripStatus fromString(String? status) {
    if (status == null) return TripStatus.upcoming;
    final upper = status.toUpperCase();
    if (upper == 'PAST' || upper == 'COMPLETED') return TripStatus.past;
    if (upper == 'CANCELLED') return TripStatus.cancelled;
    return TripStatus.upcoming;
  }
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
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    PropertySummary? propertySummary;
    if (json['property'] is Map) {
      propertySummary =
          PropertySummary.fromJson(json['property'] as Map<String, dynamic>);
    }

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
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'property': propertyId,
        'user': userId,
        'checkInDate': checkIn.toIso8601String(),
        'checkOutDate': checkOut.toIso8601String(),
        'guests': guests,
        'totalPrice': totalPrice,
        'status': status.value,
        'propertyTitle': property?.displayTitle,
      };

  int get nights => checkOut.difference(checkIn).inDays;
  bool get isUpcoming => status == TripStatus.upcoming;
  bool get isPast => status == TripStatus.past;
  bool get isCancelled => status == TripStatus.cancelled;

  String get formattedCheckIn => _formatDate(checkIn);
  String get formattedCheckOut => _formatDate(checkOut);

  String get bookingIdFormatted {
    return '#HOU-${id.padLeft(6, '0').substring(0, id.length.clamp(0, 6))}';
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
