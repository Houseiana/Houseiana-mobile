import 'package:equatable/equatable.dart';

enum BookingStatus {
  pending('PENDING'),
  confirmed('CONFIRMED'),
  upcoming('UPCOMING'),
  completed('COMPLETED'),
  cancelled('CANCELLED'),
  past('PAST');

  final String value;
  const BookingStatus(this.value);

  static BookingStatus fromString(String? status) {
    if (status == null) return BookingStatus.pending;
    final upper = status.toUpperCase();
    return BookingStatus.values.firstWhere(
      (s) => s.value == upper,
      orElse: () => BookingStatus.pending,
    );
  }
}

class BookingModel extends Equatable {
  final String id;
  final String propertyId;
  final String? userId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final int? numberOfGuests;
  final double totalPrice;
  final String status;
  final String? message;
  final PropertySummary? property;
  final String? propertyTitle;
  final String? propertyCoverPhoto;
  final String? currency;
  final String? confirmationCode;
  final DateTime? createdAt;

  const BookingModel({
    required this.id,
    required this.propertyId,
    this.userId,
    required this.checkIn,
    required this.checkOut,
    this.guests = 1,
    this.numberOfGuests,
    required this.totalPrice,
    this.status = 'PENDING',
    this.message,
    this.property,
    this.propertyTitle,
    this.propertyCoverPhoto,
    this.currency,
    this.confirmationCode,
    this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    PropertySummary? propertySummary;
    if (json['property'] is Map) {
      propertySummary =
          PropertySummary.fromJson(json['property'] as Map<String, dynamic>);
    }

    return BookingModel(
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
      numberOfGuests: json['numberOfGuests'] as int?,
      totalPrice:
          _toDouble(json['totalPrice'] ?? json['total'] ?? json['price'] ?? 0),
      status: json['status']?.toString().toUpperCase() ?? 'PENDING',
      message: json['message'] as String?,
      property: propertySummary,
      propertyTitle:
          propertySummary?.displayTitle ?? json['propertyTitle'] as String?,
      propertyCoverPhoto: json['propertyCoverPhoto'] as String?,
      currency: json['currency'] as String?,
      confirmationCode: json['confirmationCode'] as String?,
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
        'numberOfGuests': numberOfGuests,
        'totalPrice': totalPrice,
        'status': status,
        'message': message,
        'propertyTitle': propertyTitle,
      };

  int get nights => checkOut.difference(checkIn).inDays;
  BookingStatus get bookingStatus => BookingStatus.fromString(status);

  /// Currency code shown next to the total (web defaults to EGP).
  String get currencyLabel =>
      (currency != null && currency!.isNotEmpty) ? currency! : 'EGP';

  /// Short, human-friendly booking reference shown instead of the raw id.
  /// Mirrors the web host reservations card (`R-XXXX`) while preferring the
  /// real confirmation code when the backend provides one.
  String get bookingCodeFormatted {
    if (confirmationCode != null && confirmationCode!.isNotEmpty) {
      return confirmationCode!;
    }
    if (id.isEmpty) return '';
    return 'R-${id.substring(0, id.length.clamp(0, 4)).toUpperCase()}';
  }

  @override
  List<Object?> get props => [id, propertyId, checkIn, checkOut, status];
}

class PropertySummary extends Equatable {
  final String id;
  final String? title;
  final String? name;
  final String? city;
  final Map<String, dynamic>? country;
  final String? hostId;
  final List<dynamic> photos;
  final List<dynamic>? images;
  final dynamic coverPhoto;

  const PropertySummary({
    required this.id,
    this.title,
    this.name,
    this.city,
    this.country,
    this.hostId,
    this.photos = const [],
    this.images,
    this.coverPhoto,
  });

  factory PropertySummary.fromJson(Map<String, dynamic> json) {
    final photosRaw = json['photos'] ?? json['images'] ?? json['coverPhoto'];
    List<dynamic> photosList = [];
    if (photosRaw is List) {
      photosList = photosRaw;
    } else if (photosRaw is String) {
      photosList = [photosRaw];
    }

    return PropertySummary(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] as String?,
      name: json['name'] as String?,
      city: json['city'] is Map
          ? (json['city']['name'] ?? json['city']['cityName'])?.toString()
          : json['city'] as String?,
      country: json['country'] as Map<String, dynamic>?,
      hostId: json['hostId'] as String? ?? json['owner'] as String?,
      photos: photosList,
      images: json['images'] as List<dynamic>?,
      coverPhoto: json['coverPhoto'],
    );
  }

  String get displayTitle => title ?? name ?? 'Property';
  String get displayLocation {
    if (city != null && city!.isNotEmpty) {
      final countryName = country?['name']?.toString() ?? '';
      return countryName.isNotEmpty ? '$city, $countryName' : city!;
    }
    return '';
  }

  String get firstImageUrl {
    if (photos.isNotEmpty) {
      final first = photos.first;
      if (first is String) return first;
      if (first is Map) {
        return (first['url'] ?? first['photoUrl'] ?? '').toString();
      }
    }
    if (coverPhoto is String) return coverPhoto as String;
    if (coverPhoto is Map) {
      return (coverPhoto['url'] ?? coverPhoto['photoUrl'] ?? '').toString();
    }
    return '';
  }

  @override
  List<Object?> get props => [id, title, name, city, hostId];
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
