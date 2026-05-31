import 'package:equatable/equatable.dart';
import 'package:houseiana_mobile_app/core/models/property_model.dart';
import 'package:houseiana_mobile_app/core/models/review_model.dart';

abstract class PropertyDetailsState extends Equatable {
  const PropertyDetailsState();

  @override
  List<Object?> get props => [];
}

class PropertyDetailsInitial extends PropertyDetailsState {}

class PropertyDetailsLoading extends PropertyDetailsState {}

class PropertyDetailsLoaded extends PropertyDetailsState {
  final PropertyModel property;
  final List<ReviewModel> ratings;
  final Map<String, dynamic>? availability;
  final int ratingsPage;
  final bool hasMoreRatings;

  const PropertyDetailsLoaded({
    required this.property,
    this.ratings = const [],
    this.availability,
    this.ratingsPage = 1,
    this.hasMoreRatings = false,
  });

  @override
  List<Object?> get props =>
      [property, ratings, availability, ratingsPage, hasMoreRatings];

  PropertyDetailsLoaded copyWith({
    PropertyModel? property,
    List<ReviewModel>? ratings,
    Map<String, dynamic>? availability,
    int? ratingsPage,
    bool? hasMoreRatings,
  }) {
    return PropertyDetailsLoaded(
      property: property ?? this.property,
      ratings: ratings ?? this.ratings,
      availability: availability ?? this.availability,
      ratingsPage: ratingsPage ?? this.ratingsPage,
      hasMoreRatings: hasMoreRatings ?? this.hasMoreRatings,
    );
  }
}

class PropertyDetailsError extends PropertyDetailsState {
  final String message;

  const PropertyDetailsError({required this.message});

  @override
  List<Object?> get props => [message];
}
