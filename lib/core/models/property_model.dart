import 'package:equatable/equatable.dart';

class PropertyModel extends Equatable {
  final String id;
  final String? title;
  final String? name;
  final String? description;
  final double? pricePerNight;
  final double? price;
  final double? basePrice;
  final String? location;
  final String? city;
  final String? address;
  final Map<String, dynamic>? cityData;
  final Map<String, dynamic>? countryData;
  final List<dynamic> photos;
  final List<dynamic>? images;
  final dynamic coverPhoto;
  final double? rating;
  final int? reviewCount;
  final int? bedrooms;
  final int? bathrooms;
  final int? maxGuests;
  final List<String>? amenities;
  final String? propertyType;
  final String? hostId;
  final Map<String, dynamic>? fees;
  final bool? isFavourited;
  final bool? isGuestFavorite;
  final double? averageRating;
  final int? reviewsCount;
  final int? beds;
  final String? currency;
  final double? priceWithoutDiscount;
  final double? weeklyDiscount;
  final double? smallBookingDiscount;
  final String? availabilityType;
  final bool? instantBook;
  final String? status;
  final int? viewCount;
  final double? occupancyRate;
  final double? revenueThisMonth;
  final double? latitude;
  final double? longitude;

  const PropertyModel({
    required this.id,
    this.title,
    this.name,
    this.description,
    this.pricePerNight,
    this.price,
    this.basePrice,
    this.location,
    this.city,
    this.address,
    this.cityData,
    this.countryData,
    this.photos = const [],
    this.images,
    this.coverPhoto,
    this.rating,
    this.reviewCount,
    this.bedrooms,
    this.bathrooms,
    this.maxGuests,
    this.amenities,
    this.propertyType,
    this.hostId,
    this.fees,
    this.isFavourited,
    this.isGuestFavorite,
    this.averageRating,
    this.reviewsCount,
    this.beds,
    this.currency,
    this.priceWithoutDiscount,
    this.weeklyDiscount,
    this.smallBookingDiscount,
    this.availabilityType,
    this.instantBook,
    this.status,
    this.viewCount,
    this.occupancyRate,
    this.revenueThisMonth,
    this.latitude,
    this.longitude,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    final photosRaw = json['photos'] ?? json['images'] ?? json['coverPhoto'];
    List<dynamic> photosList = [];
    if (photosRaw is List) {
      photosList = photosRaw;
    } else if (photosRaw is String) {
      photosList = [photosRaw];
    }

    return PropertyModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      pricePerNight: _toDouble(
          json['pricePerNight'] ?? json['price'] ?? json['basePrice']),
      price: _toDouble(json['price']),
      basePrice: _toDouble(json['basePrice']),
      location: json['location'] as String?,
      city: json['city'] is Map
          ? (json['city']['name'] ?? json['city']['cityName'])?.toString()
          : json['city'] as String?,
      address: json['address'] as String?,
      cityData:
          json['city'] is Map ? json['city'] as Map<String, dynamic> : null,
      countryData: json['country'] is Map
          ? json['country'] as Map<String, dynamic>
          : (json['country'] is String ? {'name': json['country']} : null),
      photos: photosList,
      images: json['images'] as List<dynamic>?,
      coverPhoto: json['coverPhoto'],
      rating: _toDouble(json['rating'] ?? json['avgRating']),
      reviewCount: json['reviewCount'] as int? ?? json['numReviews'] as int?,
      bedrooms: json['bedrooms'] as int? ?? json['bedroomsCount'] as int?,
      bathrooms: json['bathrooms'] as int?,
      maxGuests: json['maxGuests'] as int? ?? json['guests'] as int?,
      amenities: (json['amenities'] as List<dynamic>?)?.cast<String>(),
      propertyType: json['propertyType'] as String? ?? json['type'] as String?,
      hostId: json['hostId'] as String? ?? json['owner'] as String?,
      fees: json['fees'] as Map<String, dynamic>?,
      isFavourited:
          json['isFavourited'] as bool? ?? json['isFavorite'] as bool?,
      isGuestFavorite: json['isGuestFavorite'] as bool? ?? json['guestFavorite'] as bool?,
      averageRating: _toDouble(json['averageRating'] ?? json['avgRating'] ?? json['rating']),
      reviewsCount: json['reviewsCount'] as int? ?? json['reviewCount'] as int? ?? json['numReviews'] as int?,
      beds: json['beds'] as int?,
      currency: json['currency'] as String?,
      priceWithoutDiscount: _toDouble(json['priceWithoutDiscount'] ?? json['originalPrice']),
      weeklyDiscount: _toDouble(json['weeklyDiscount']),
      smallBookingDiscount: _toDouble(json['smallBookingDiscount']),
      availabilityType: json['availabilityType'] as String?,
      instantBook: json['instantBook'] as bool?,
      status: json['status'] as String?,
      viewCount: json['viewCount'] as int? ?? 0,
      occupancyRate: _toDouble(json['occupancyRate']) ?? 0.0,
      revenueThisMonth: _toDouble(json['revenueThisMonth']) ?? 0.0,
      latitude: _toDouble(json['latitude'] ?? json['lat']),
      longitude: _toDouble(json['longitude'] ?? json['lng'] ?? json['lon']),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'title': title,
        'name': name,
        'description': description,
        'pricePerNight': pricePerNight,
        'price': price,
        'basePrice': basePrice,
        'location': location,
        'city': city,
        'address': address,
        'photos': photos,
        'images': images,
        'coverPhoto': coverPhoto,
        'rating': rating,
        'reviewCount': reviewCount,
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'beds': beds,
        'maxGuests': maxGuests,
        'amenities': amenities,
        'propertyType': propertyType,
        'hostId': hostId,
        'fees': fees,
        'isFavourited': isFavourited,
        'isGuestFavorite': isGuestFavorite,
        'averageRating': averageRating,
        'reviewsCount': reviewsCount,
        'currency': currency,
        'priceWithoutDiscount': priceWithoutDiscount,
        'weeklyDiscount': weeklyDiscount,
        'smallBookingDiscount': smallBookingDiscount,
        'availabilityType': availabilityType,
        'instantBook': instantBook,
        'status': status,
        'viewCount': viewCount,
        'occupancyRate': occupancyRate,
        'revenueThisMonth': revenueThisMonth,
        'latitude': latitude,
        'longitude': longitude,
      };

  String get displayTitle => title ?? name ?? 'Property';
  double get displayPrice => pricePerNight ?? price ?? basePrice ?? 0;
  String get displayLocation {
    if (city != null && city!.isNotEmpty) {
      final countryName = countryData?['name']?.toString() ?? '';
      return countryName.isNotEmpty ? '$city, $countryName' : city!;
    }
    return location ?? address ?? '';
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
  List<Object?> get props => [id, title, name, pricePerNight, location];
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
