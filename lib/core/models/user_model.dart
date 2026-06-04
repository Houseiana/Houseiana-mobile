import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String? bio;
  final DateTime? createdAt;
  final bool? isVerified;
  final String? verificationStatus;
  final Map<String, dynamic>? passport;
  final List<AddressModel>? addresses;
  final String? dateOfBirth;
  final String? gender;
  final int? genderId;
  final String? nationality;

  const UserModel({
    required this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.avatarUrl,
    this.bio,
    this.createdAt,
    this.isVerified,
    this.verificationStatus,
    this.passport,
    this.addresses,
    this.dateOfBirth,
    this.gender,
    this.genderId,
    this.nationality,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      firstName: json['firstName'] as String? ?? json['first_name'] as String?,
      lastName: json['lastName'] as String? ?? json['last_name'] as String?,
      email: json['email'] as String? ?? json['paypalEmail'] as String?,
      phone: json['phone'] as String? ?? json['phoneNumber'] as String?,
      avatarUrl: json['avatarUrl'] as String? ??
          json['avatar'] as String? ??
          json['profilePhoto'] as String? ??
          json['profilePicture'] as String?,
      bio: json['bio'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      isVerified: json['isVerified'] as bool? ?? json['verified'] as bool?,
      verificationStatus:
          json['verificationStatus'] as String? ?? json['kycStatus'] as String?,
      passport: json['passport'] as Map<String, dynamic>?,
      addresses: (json['addresses'] as List<dynamic>?)
          ?.map((a) => AddressModel.fromJson(a as Map<String, dynamic>))
          .toList(),
      dateOfBirth: json['dateOfBirth']?.toString(),
      gender: _parseGenderName(json['gender']),
      genderId: _parseGenderId(json),
      nationality: json['nationality'] as String?,
    );
  }

  /// The backend may return `gender` as a plain string or as an object
  /// `{ id, name }` (the web treats it as `{ id, name }`). Handle both safely
  /// so loading the profile never throws a type error.
  static String? _parseGenderName(dynamic value) {
    if (value is String) return value;
    if (value is Map) return value['name']?.toString();
    return null;
  }

  /// Resolves the integer gender id from either a top-level `genderId` field or
  /// a nested `gender.id`. Returns null when unset.
  static int? _parseGenderId(Map<String, dynamic> json) {
    final direct = json['genderId'];
    if (direct is int) return direct;
    if (direct is num) return direct.toInt();
    final parsedDirect = int.tryParse(direct?.toString() ?? '');
    if (parsedDirect != null) return parsedDirect;

    final gender = json['gender'];
    if (gender is Map) {
      final id = gender['id'];
      if (id is int) return id;
      if (id is num) return id.toInt();
      return int.tryParse(id?.toString() ?? '');
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'avatarUrl': avatarUrl,
        'bio': bio,
        'createdAt': createdAt?.toIso8601String(),
        'isVerified': isVerified,
        'verificationStatus': verificationStatus,
        'passport': passport,
        'addresses': addresses?.map((a) => a.toJson()).toList(),
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'genderId': genderId,
        'nationality': nationality,
      };

  String get fullName {
    final full = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    return full.isEmpty ? 'User' : full;
  }

  @override
  List<Object?> get props => [id, email, firstName, lastName];
}

class AddressModel extends Equatable {
  final String id;
  final String? label;
  final String? street;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;
  final bool? isDefault;

  const AddressModel({
    required this.id,
    this.label,
    this.street,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    this.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['_id'] ?? json['id'] ?? '',
      label: json['label'] as String?,
      street: json['street'] as String? ?? json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zipCode: json['zipCode'] as String? ?? json['zip'] as String?,
      country: json['country'] as String?,
      isDefault: json['isDefault'] as bool? ?? json['default'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'label': label,
        'street': street,
        'city': city,
        'state': state,
        'zipCode': zipCode,
        'country': country,
        'isDefault': isDefault,
      };

  @override
  List<Object?> get props => [id, label, street, city];
}

class PaymentMethodModel extends Equatable {
  final String id;
  final String type;
  final String? last4;
  final String? brand;
  final String? expiryMonth;
  final String? expiryYear;
  final String? email;
  final bool isDefault;

  const PaymentMethodModel({
    required this.id,
    required this.type,
    this.last4,
    this.brand,
    this.expiryMonth,
    this.expiryYear,
    this.email,
    this.isDefault = false,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type'] as String? ?? 'card',
      last4: json['last4'] as String?,
      brand: json['brand'] as String?,
      expiryMonth:
          json['expiryMonth'] as String? ?? json['exp_month'] as String?,
      expiryYear: json['expiryYear'] as String? ?? json['exp_year'] as String?,
      email: json['email'] as String?,
      isDefault:
          json['isDefault'] as bool? ?? json['default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'type': type,
        'last4': last4,
        'brand': brand,
        'expiryMonth': expiryMonth,
        'expiryYear': expiryYear,
        'email': email,
        'isDefault': isDefault,
      };

  String get displayName {
    if (type == 'paypal' || type == 'paypal_account') {
      return email ?? 'PayPal';
    }
    if (brand != null && last4 != null) {
      return '$brand ending in $last4';
    }
    if (last4 != null) {
      return 'Card ending in $last4';
    }
    return type;
  }

  String get displayDetails {
    if (type == 'paypal' || type == 'paypal_account') {
      return email ?? '';
    }
    if (expiryMonth != null && expiryYear != null) {
      return 'Expires $expiryMonth/$expiryYear';
    }
    return '';
  }

  @override
  List<Object?> get props => [id, type, last4, brand, email];
}
