import 'package:equatable/equatable.dart';

/// Full `GET /users/{id}` wrapper: `{ user, rating, userProfile, properties }`.
/// Mirrors the web `profile/[id]/page.tsx` `rawData` shape. Unlike the lean
/// [UserModel] returned by `UserService.getUser`, this preserves rating,
/// properties, bookings and hostRatings needed for the owner profile screen.
class PublicProfileModel extends Equatable {
  final PublicUserModel user;
  final PublicRating? rating;

  /// `userProfile` in the web response = a photo url override.
  final String? userProfilePhoto;

  /// Top-level `properties` (host listings). Web prefers this over user.properties.
  final List<PublicPropertyModel> properties;

  const PublicProfileModel({
    required this.user,
    this.rating,
    this.userProfilePhoto,
    this.properties = const [],
  });

  factory PublicProfileModel.fromJson(Map<String, dynamic> json) {
    // Handle a `{ data: {...} }` wrapper (mirrors UserService._item()).
    final root = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;

    // `user` may be nested or the root itself may BE the user.
    final userJson = (root['user'] is Map<String, dynamic>)
        ? root['user'] as Map<String, dynamic>
        : root;

    final ratingJson = root['rating'];
    final userProfile = root['userProfile'];

    return PublicProfileModel(
      user: PublicUserModel.fromJson(userJson),
      rating: ratingJson is Map<String, dynamic>
          ? PublicRating.fromJson(ratingJson)
          : null,
      userProfilePhoto: userProfile is String
          ? userProfile
          : (userProfile is Map
              ? (userProfile['photo'] ??
                      userProfile['url'] ??
                      userProfile['profilePhoto'])
                  ?.toString()
              : null),
      properties: _propList(root['properties']),
    );
  }

  /// Photo precedence mirrors web: `userProfile ?? user.profilePhoto`.
  String? get photoUrl =>
      (userProfilePhoto != null && userProfilePhoto!.isNotEmpty)
          ? userProfilePhoto
          : user.profilePhoto;

  /// Web prefers top-level `properties` then falls back to `user.properties`.
  List<PublicPropertyModel> get effectiveProperties =>
      properties.isNotEmpty ? properties : user.properties;

  static List<PublicPropertyModel> _propList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(PublicPropertyModel.fromJson)
        .toList();
  }

  @override
  List<Object?> get props => [user, rating, userProfilePhoto, properties];
}

class PublicRating extends Equatable {
  final double? averageRating;
  final int totalRatings;

  const PublicRating({this.averageRating, this.totalRatings = 0});

  factory PublicRating.fromJson(Map<String, dynamic> json) => PublicRating(
        averageRating: _toDouble(json['averageRating']),
        totalRatings: (json['totalRatings'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [averageRating, totalRatings];
}

class PublicUserModel extends Equatable {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? profilePhoto;
  final String? role; // GUEST_AND_HOST | GUEST | HOST | null
  final String? kycStatus; // VERIFIED | PENDING | REJECTED | null
  final bool? emailVerified;
  final bool? phoneVerified;
  final String? email;
  final String? phone;
  final String? countryCode;
  final String? preferredLanguage;
  final String? preferredCurrency;
  final String? nationality;
  final DateTime? createdAt;
  final PublicAddress? address;
  final String? nationalIdFrontPhoto;
  final List<PublicPropertyModel> properties;
  final List<PublicBooking> guestBookings;
  final List<PublicBooking> hostBookings;
  final List<PublicHostRating> hostRatings;

  const PublicUserModel({
    required this.id,
    this.firstName,
    this.lastName,
    this.profilePhoto,
    this.role,
    this.kycStatus,
    this.emailVerified,
    this.phoneVerified,
    this.email,
    this.phone,
    this.countryCode,
    this.preferredLanguage,
    this.preferredCurrency,
    this.nationality,
    this.createdAt,
    this.address,
    this.nationalIdFrontPhoto,
    this.properties = const [],
    this.guestBookings = const [],
    this.hostBookings = const [],
    this.hostRatings = const [],
  });

  factory PublicUserModel.fromJson(Map<String, dynamic> json) {
    final nationalId = json['nationalID'] ?? json['nationalId'];
    return PublicUserModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      profilePhoto: json['profilePhoto'] as String? ??
          json['avatarUrl'] as String? ??
          json['avatar'] as String?,
      role: json['role'] as String?,
      kycStatus: json['kycStatus'] as String?,
      emailVerified: json['emailVerified'] as bool?,
      phoneVerified: json['phoneVerified'] as bool?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      countryCode: json['countryCode'] as String?,
      preferredLanguage: json['preferredLanguage'] as String?,
      preferredCurrency: json['preferredCurrency'] as String?,
      nationality: json['nationality'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      address: json['address'] is Map<String, dynamic>
          ? PublicAddress.fromJson(json['address'] as Map<String, dynamic>)
          : null,
      nationalIdFrontPhoto:
          nationalId is Map ? nationalId['idFrontPhoto']?.toString() : null,
      properties: PublicProfileModel._propList(json['properties']),
      guestBookings: _bookingList(json['guestBookings']),
      hostBookings: _bookingList(json['hostBookings']),
      hostRatings: _ratingList(json['hostRatings']),
    );
  }

  String get fullName {
    final n = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    return n.isEmpty ? 'User' : n;
  }

  String get initials {
    final i = '${firstName?.isNotEmpty == true ? firstName![0] : ''}'
            '${lastName?.isNotEmpty == true ? lastName![0] : ''}'
        .toUpperCase();
    return i.isEmpty ? '?' : i;
  }

  static List<PublicBooking> _bookingList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(PublicBooking.fromJson)
        .toList();
  }

  static List<PublicHostRating> _ratingList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(PublicHostRating.fromJson)
        .toList();
  }

  @override
  List<Object?> get props => [id, firstName, lastName, role, kycStatus];
}

class PublicAddress extends Equatable {
  final String? cityName;
  final String? countryName;
  final String? streetAddress;

  const PublicAddress({this.cityName, this.countryName, this.streetAddress});

  factory PublicAddress.fromJson(Map<String, dynamic> json) {
    final city = json['city'];
    final cityName = city is Map ? city['name']?.toString() : city?.toString();
    final country = city is Map ? city['country'] : null;
    final countryName = country is Map ? country['name']?.toString() : null;
    return PublicAddress(
      cityName: cityName,
      countryName: countryName,
      streetAddress: json['streetAddress']?.toString(),
    );
  }

  /// `[city.name, country.name].filter(Boolean).join(', ')` (web parity).
  String get displayLocation => [cityName, countryName]
      .where((e) => e != null && e.isNotEmpty)
      .join(', ');

  @override
  List<Object?> get props => [cityName, countryName, streetAddress];
}

class PublicPropertyModel extends Equatable {
  final String? id;
  final String? title;
  final String? name;
  final String? description;
  final double? pricePerNight;

  const PublicPropertyModel({
    this.id,
    this.title,
    this.name,
    this.description,
    this.pricePerNight,
  });

  factory PublicPropertyModel.fromJson(Map<String, dynamic> json) =>
      PublicPropertyModel(
        // web: p.id ?? p.propertyCode
        id: (json['id'] ?? json['_id'] ?? json['propertyCode'])?.toString(),
        title: json['title'] as String?,
        name: json['name'] as String?,
        description: json['description'] as String?,
        pricePerNight: _toDouble(json['pricePerNight']),
      );

  String get displayTitle => title ?? name ?? 'Property';

  @override
  List<Object?> get props => [id, title, name, pricePerNight];
}

class PublicBooking extends Equatable {
  final String? id;
  final String? propertyName;
  final String? checkIn;
  final String? checkOut;
  final String? status;

  const PublicBooking({
    this.id,
    this.propertyName,
    this.checkIn,
    this.checkOut,
    this.status,
  });

  factory PublicBooking.fromJson(Map<String, dynamic> json) {
    final property = json['property'];
    return PublicBooking(
      id: (json['id'] ?? json['_id'])?.toString(),
      propertyName: property is Map ? property['name']?.toString() : null,
      checkIn: json['checkIn']?.toString(),
      checkOut: json['checkOut']?.toString(),
      status: json['status']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, propertyName, checkIn, checkOut, status];
}

class PublicHostRating extends Equatable {
  final String id;
  final String? guestId;
  final String? comment;
  final double ratingValue;
  final DateTime? createdAt;
  final String reviewerName;
  final String? reviewerPhoto;

  const PublicHostRating({
    required this.id,
    this.guestId,
    this.comment,
    this.ratingValue = 0,
    this.createdAt,
    this.reviewerName = 'Anonymous',
    this.reviewerPhoto,
  });

  factory PublicHostRating.fromJson(Map<String, dynamic> json) {
    final guest = json['guest'];
    final fn = guest is Map ? (guest['firstName'] ?? '') : '';
    final ln = guest is Map ? (guest['lastName'] ?? '') : '';
    final name = '$fn $ln'.trim();
    return PublicHostRating(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      guestId: json['guestId']?.toString(),
      comment: json['comment']?.toString(),
      ratingValue: _toDouble(json['ratingValue']) ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      reviewerName: name.isEmpty ? 'Anonymous' : name,
      reviewerPhoto: guest is Map ? guest['profilePhoto']?.toString() : null,
    );
  }

  @override
  List<Object?> get props => [id, guestId, ratingValue, createdAt];
}

/// Review summary derived from hostRatings (mirrors web `use-profile.ts`).
class ReviewSummary {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> breakdown; // {5:..,4:..,3:..,2:..,1:..}

  const ReviewSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.breakdown,
  });

  factory ReviewSummary.fromRatings(List<PublicHostRating> ratings) {
    final total = ratings.length;
    final avg = total == 0
        ? 0.0
        : ratings.fold<double>(0, (a, r) => a + r.ratingValue) / total;
    int bucket(int star) =>
        ratings.where((r) => r.ratingValue.round() == star).length;
    return ReviewSummary(
      averageRating: avg,
      totalReviews: total,
      breakdown: {
        5: bucket(5),
        4: bucket(4),
        3: bucket(3),
        2: bucket(2),
        1: bucket(1),
      },
    );
  }
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v);
  if (v is num) return v.toDouble();
  return null;
}
