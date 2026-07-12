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
  /// Property/unit name as returned flat by `/api/bookings/list` (`unitName`).
  final String? unitName;
  final String? propertyCoverPhoto;
  final String? currency;
  final String? confirmationCode;
  /// Real reservation reference from the backend (`bookingCode`), preferred
  /// over the id-derived `R-XXXX` fallback.
  final String? bookingCode;
  final DateTime? createdAt;
  /// Guest display name as returned flat by `/api/bookings/list` (`title`).
  /// The backend falls back to `Booking #XXXX` when the guest has no name.
  final String? guestName;
  /// Free-text note left on the booking (`notes`).
  final String? notes;
  /// Nights count as returned by `/api/bookings/list` (`nights`); when absent
  /// the count is derived from [checkIn]/[checkOut].
  final int? apiNights;
  /// Payment state from the backend (`paymentStatus`): `PAID`, `PENDING`,
  /// `FAILED`, `REFUNDED`, `PARTIALLY_REFUNDED` (mirrors the web
  /// `PaymentStatus` enum). Null when the endpoint sends no payment info.
  final String? paymentStatus;

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
    this.unitName,
    this.propertyCoverPhoto,
    this.currency,
    this.confirmationCode,
    this.bookingCode,
    this.createdAt,
    this.guestName,
    this.notes,
    this.apiNights,
    this.paymentStatus,
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
      unitName: json['unitName'] as String?,
      propertyCoverPhoto: json['propertyCoverPhoto'] as String?,
      currency: json['currency'] as String?,
      confirmationCode: json['confirmationCode'] as String?,
      bookingCode: json['bookingCode'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      guestName: json['title'] as String? ?? json['guestName'] as String?,
      notes: json['notes'] as String?,
      apiNights: json['nights'] is int
          ? json['nights'] as int
          : int.tryParse('${json['nights'] ?? ''}'),
      paymentStatus: _parsePaymentStatus(json),
    );
  }

  /// Normalizes the backend payment info: prefers the `paymentStatus` string,
  /// falling back to boolean `isPaid`/`paid` flags. Returns null when the
  /// response carries no payment information at all (the UI then hides the
  /// payment indicator instead of showing a hardcoded "Paid").
  static String? _parsePaymentStatus(Map<String, dynamic> json) {
    final raw = json['paymentStatus'] ?? json['payment_status'];
    if (raw is String && raw.trim().isNotEmpty) {
      return raw.trim().toUpperCase().replaceAll(' ', '_');
    }
    final paid = json['isPaid'] ?? json['paid'];
    if (paid == true) return 'PAID';
    return null;
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
        'unitName': unitName,
        'bookingCode': bookingCode,
        'paymentStatus': paymentStatus,
      };

  int get nights => checkOut.difference(checkIn).inDays;

  /// Nights count preferring the backend-provided `nights`, falling back to the
  /// date-derived count (mirrors the web reservation card).
  int get nightsCount =>
      (apiNights != null && apiNights! > 0) ? apiNights! : nights;

  BookingStatus get bookingStatus => BookingStatus.fromString(status);

  /// Short id-derived reference shown on the host reservation card, matching the
  /// web's `R-${id.slice(0,4).toUpperCase()}` (independent of [bookingCode]).
  String get bookingRefShort {
    if (id.isEmpty) return '';
    return 'R-${id.substring(0, id.length.clamp(0, 4)).toUpperCase()}';
  }

  /// Title-cased status for the coloured badge (backend sends display strings
  /// like `Requested`, `Currently Hosting`; [status] itself is upper-cased).
  String get statusLabel {
    if (status.isEmpty) return status;
    return status
        .split(' ')
        .map((w) => w.isEmpty
            ? w
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  /// Guest name for the reservation card. The backend substitutes an
  /// id-derived `Booking #XXXX` when the guest has no name — that (or an
  /// absent name) is replaced with the real [bookingCodeFormatted] reference.
  String get guestDisplayName {
    final name = guestName?.trim() ?? '';
    final isBackendFallback =
        name.isEmpty || name.toLowerCase().startsWith('booking #');
    if (!isBackendFallback) return name;
    final code = bookingCodeFormatted;
    return code.isEmpty ? '' : 'Booking $code';
  }

  /// Currency code shown next to the total (web defaults to EGP).
  String get currencyLabel =>
      (currency != null && currency!.isNotEmpty) ? currency! : 'EGP';

  /// Short, human-friendly booking reference shown instead of the raw id.
  /// Prefers the real backend `bookingCode`, then `confirmationCode`, and only
  /// falls back to the id-derived `R-XXXX` when neither is provided.
  String get bookingCodeFormatted {
    if (bookingCode != null && bookingCode!.isNotEmpty) {
      return bookingCode!;
    }
    if (confirmationCode != null && confirmationCode!.isNotEmpty) {
      return confirmationCode!;
    }
    if (id.isEmpty) return '';
    return 'R-${id.substring(0, id.length.clamp(0, 4)).toUpperCase()}';
  }

  /// Property/unit name for host booking cards. Prefers the flat `unitName`
  /// field from `/api/bookings/list`, then any nested property title.
  String? get displayUnitName {
    if (unitName != null && unitName!.isNotEmpty) return unitName;
    if (propertyTitle != null && propertyTitle!.isNotEmpty) return propertyTitle;
    return null;
  }

  @override
  List<Object?> get props =>
      [id, propertyId, checkIn, checkOut, status, paymentStatus, bookingCode];
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

/// Aggregate booking counters returned alongside `/api/bookings/list` under
/// the top-level `bookingStats` key. Powers the host Reservations stat cards.
class BookingStats extends Equatable {
  final int totalReservations;
  final int totalUpcoming;
  final int totalRequested;
  final double revenueSecured;

  /// Currency code for [revenueSecured] (backend may omit it; the web hard-codes
  /// EGP). Defaults to EGP at the render layer when null.
  final String? currency;

  const BookingStats({
    this.totalReservations = 0,
    this.totalUpcoming = 0,
    this.totalRequested = 0,
    this.revenueSecured = 0,
    this.currency,
  });

  static const BookingStats empty = BookingStats();

  factory BookingStats.fromJson(Map<String, dynamic> json) => BookingStats(
        totalReservations: _toInt(json['totalReservations']),
        totalUpcoming: _toInt(json['totalUpcoming']),
        totalRequested: _toInt(json['totalRequested']),
        revenueSecured: _toDouble(json['revenueSecured']),
        currency: json['currency'] as String?,
      );

  @override
  List<Object?> get props =>
      [totalReservations, totalUpcoming, totalRequested, revenueSecured, currency];
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return int.tryParse(value) ?? double.tryParse(value)?.round() ?? 0;
  return 0;
}
