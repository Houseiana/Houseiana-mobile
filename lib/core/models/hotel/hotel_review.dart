import 'package:houseiana_mobile_app/core/models/hotel/hotel_summary.dart';

/// Models for the hotel review endpoints.
///
/// `GET /api/hotels/{hotelId}/reviews` was only ever probed against an EMPTY
/// dataset, so the ROW SHAPE IS UNVERIFIED. Everything in [HotelReview] is
/// optional and read through key aliases; `HotelReview.fromJson({})` must not
/// throw. Once a real row is seen, tighten this — do not guess harder now.

class HotelReview {
  final String id;
  final String comment;
  final String guestName;
  final String guestAvatar;

  /// The overall score. The create endpoint takes `ratingValue` as an int, so
  /// rows are read from both `ratingValue` and the usual `rating` aliases.
  final double rating;

  final DateTime? createdAt;

  const HotelReview({
    this.id = '',
    this.comment = '',
    this.guestName = '',
    this.guestAvatar = '',
    this.rating = 0,
    this.createdAt,
  });

  bool get hasComment => comment.trim().isNotEmpty;

  factory HotelReview.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());

    final guest = json['guest'] is Map
        ? Map<String, dynamic>.from(json['guest'] as Map)
        : const <String, dynamic>{};

    final name = asHotelString(
      json['guestName'] ??
          json['userName'] ??
          json['reviewerName'] ??
          guest['name'] ??
          [guest['firstName'], guest['lastName']]
              .where((s) => s != null && s.toString().trim().isNotEmpty)
              .join(' '),
    );

    return HotelReview(
      id: asHotelString(json['id'] ?? json['_id'] ?? json['reviewId']),
      comment: asHotelString(json['comment'] ?? json['review'] ?? json['text']),
      guestName: name,
      guestAvatar: asHotelString(
        json['guestAvatar'] ?? json['avatar'] ?? guest['profileImage'],
      ),
      rating: asHotelDouble(
            json['ratingValue'] ?? json['rating'] ?? json['overallRating'],
          ) ??
          0,
      createdAt: parseDate(json['createdAt'] ?? json['date']),
    );
  }
}

/// Body for `POST /api/hotels/{hotelId}/reviews/create`.
///
/// Contract notes: the key is `guestId` (not `userId`, unlike the property
/// rating endpoint), `ratingValue` is an int, and there is NO bookingId — the
/// review attaches to the hotel, not to a specific stay.
class HotelReviewDraft {
  final int ratingValue;
  final String comment;
  final double cleanliness;
  final double accuracy;
  final double checkIn;
  final double communication;
  final double location;
  final double value;

  const HotelReviewDraft({
    this.ratingValue = 0,
    this.comment = '',
    this.cleanliness = 0,
    this.accuracy = 0,
    this.checkIn = 0,
    this.communication = 0,
    this.location = 0,
    this.value = 0,
  });

  List<double> get categoryScores =>
      [cleanliness, accuracy, checkIn, communication, location, value];

  bool get isComplete =>
      ratingValue > 0 &&
      comment.trim().isNotEmpty &&
      categoryScores.every((v) => v > 0);

  HotelReviewDraft copyWith({
    int? ratingValue,
    String? comment,
    double? cleanliness,
    double? accuracy,
    double? checkIn,
    double? communication,
    double? location,
    double? value,
  }) =>
      HotelReviewDraft(
        ratingValue: ratingValue ?? this.ratingValue,
        comment: comment ?? this.comment,
        cleanliness: cleanliness ?? this.cleanliness,
        accuracy: accuracy ?? this.accuracy,
        checkIn: checkIn ?? this.checkIn,
        communication: communication ?? this.communication,
        location: location ?? this.location,
        value: value ?? this.value,
      );

  /// Applies one score to every category at once — the "rate everything the
  /// same" shortcut on the review sheet.
  HotelReviewDraft withAllCategories(double score) => copyWith(
        cleanliness: score,
        accuracy: score,
        checkIn: score,
        communication: score,
        location: score,
        value: score,
      );

  Map<String, dynamic> toJson(String guestId) => {
        'guestId': guestId,
        'ratingValue': ratingValue,
        'comment': comment.trim(),
        'cleanliness': cleanliness,
        'accuracy': accuracy,
        'checkIn': checkIn,
        'communication': communication,
        'location': location,
        'value': value,
      };
}
