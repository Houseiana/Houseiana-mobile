import 'package:equatable/equatable.dart';
import 'package:houseiana_mobile_app/core/models/review_model.dart';

/// Everything `GET /api/ratings/property/{propertyId}` answers with.
///
/// The endpoint returns the reviews **and** the aggregates in one envelope:
///
/// ```json
/// { "success": true, "data": [ … ], "averageRating": 4, "totalRatings": 1,
///   "averageCleanliness": 0, "averageAccuracy": 0, … }
/// ```
///
/// Reading only `data` (what the old `getRatingsPaginated` did) threw the six
/// category averages away, which are exactly what the web reviews block draws
/// its bars from — hence this model instead of a bare `List<ReviewModel>`.
///
/// There is **no pagination**: the swagger route takes `propertyId` and nothing
/// else, so `page`/`limit` were being ignored and "has more" was inferred from
/// a page size the server never honoured. One call returns every review.
class PropertyRatings extends Equatable {
  final List<ReviewModel> reviews;
  final double averageRating;
  final int totalRatings;

  /// The six per-category averages. `0` means "never scored" — the property
  /// rating DTO lets a guest submit an overall star with every category left
  /// null, and that is what today's reviews look like.
  final double cleanliness;
  final double accuracy;
  final double checkIn;
  final double communication;
  final double location;
  final double value;

  const PropertyRatings({
    this.reviews = const [],
    this.averageRating = 0,
    this.totalRatings = 0,
    this.cleanliness = 0,
    this.accuracy = 0,
    this.checkIn = 0,
    this.communication = 0,
    this.location = 0,
    this.value = 0,
  });

  static const PropertyRatings empty = PropertyRatings();

  bool get isEmpty => reviews.isEmpty && totalRatings == 0;

  bool get hasReviews => reviews.isNotEmpty;

  /// Whether the category bars are worth drawing. All-zero is the common case
  /// (see [cleanliness]); six empty bars would be noise, not information.
  bool get hasCategoryScores =>
      cleanliness > 0 ||
      accuracy > 0 ||
      checkIn > 0 ||
      communication > 0 ||
      location > 0 ||
      value > 0;

  factory PropertyRatings.fromJson(dynamic response) {
    if (response == null) return empty;

    // A bare array is tolerated: the aggregates are then derived from the rows
    // so the header still shows a real score instead of `--`.
    if (response is List) {
      final reviews = _reviews(response);
      return PropertyRatings(
        reviews: reviews,
        averageRating: _average(reviews),
        totalRatings: reviews.length,
      );
    }

    if (response is! Map) return empty;
    final map = Map<String, dynamic>.from(response);
    final reviews = _reviews(map['data'] ?? map['items'] ?? map['ratings']);

    final total = _toInt(map['totalRatings'] ?? map['total'] ?? map['count']);
    final average = _toDouble(map['averageRating'] ?? map['average']);

    return PropertyRatings(
      reviews: reviews,
      // The aggregates win when the payload carries them; the rows are the
      // fallback so a summary-less response is not read as "no rating".
      averageRating: average > 0 ? average : _average(reviews),
      totalRatings: total > 0 ? total : reviews.length,
      cleanliness: _toDouble(map['averageCleanliness']),
      accuracy: _toDouble(map['averageAccuracy']),
      checkIn: _toDouble(map['averageCheckIn']),
      communication: _toDouble(map['averageCommunication']),
      location: _toDouble(map['averageLocation']),
      value: _toDouble(map['averageValue']),
    );
  }

  @override
  List<Object?> get props => [
        reviews,
        averageRating,
        totalRatings,
        cleanliness,
        accuracy,
        checkIn,
        communication,
        location,
        value,
      ];

  static List<ReviewModel> _reviews(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => ReviewModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static double _average(List<ReviewModel> reviews) {
    final scored = reviews.where((r) => r.rating > 0).toList();
    if (scored.isEmpty) return 0;
    final sum = scored.fold<double>(0, (acc, r) => acc + r.rating);
    return sum / scored.length;
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
