import 'package:equatable/equatable.dart';

class ReviewModel extends Equatable {
  final String id;
  final String propertyId;
  final String? bookingId;
  final String? userId;
  final String? userName;
  final String? userAvatar;
  final double rating;
  final String? comment;
  final DateTime? createdAt;
  final List<String>? photos;
  final bool? isHostReview;

  const ReviewModel({
    required this.id,
    required this.propertyId,
    this.bookingId,
    this.userId,
    this.userName,
    this.userAvatar,
    required this.rating,
    this.comment,
    this.createdAt,
    this.photos,
    this.isHostReview,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['_id'] ?? json['id'] ?? '',
      propertyId: json['property'] is Map
          ? (json['property']['_id'] ?? json['property']['id'] ?? '').toString()
          : (json['property'] ?? json['propertyId'] ?? '').toString(),
      bookingId: json['bookingId'] as String?,
      userId: json['user']?.toString() ?? json['userId']?.toString(),
      userName: json['userName'] as String? ??
          json['reviewerName'] as String? ??
          json['guestName'] as String?,
      userAvatar: json['userAvatar'] as String? ??
          json['avatar'] as String? ??
          json['reviewerAvatar'] as String?,
      rating: _toDouble(json['rating'] ?? json['overall'] ?? 0),
      comment: json['comment'] as String? ??
          json['text'] as String? ??
          json['review'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      photos: (json['photos'] as List<dynamic>?)?.cast<String>(),
      isHostReview:
          json['isHostReview'] as bool? ?? json['hostReview'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'property': propertyId,
        'bookingId': bookingId,
        'user': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt?.toIso8601String(),
        'photos': photos,
        'isHostReview': isHostReview,
      };

  String get formattedDate {
    if (createdAt == null) return '';
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
    return '${months[createdAt!.month - 1]} ${createdAt!.day}, ${createdAt!.year}';
  }

  @override
  List<Object?> get props => [id, propertyId, rating];
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
