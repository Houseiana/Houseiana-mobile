import 'package:equatable/equatable.dart';
import 'package:houseiana_mobile_app/core/models/property_model.dart';
import 'package:houseiana_mobile_app/core/models/property_ratings.dart';

abstract class PropertyDetailsState extends Equatable {
  const PropertyDetailsState();

  @override
  List<Object?> get props => [];
}

class PropertyDetailsInitial extends PropertyDetailsState {}

class PropertyDetailsLoading extends PropertyDetailsState {}

class PropertyDetailsLoaded extends PropertyDetailsState {
  final PropertyModel property;

  /// Reviews and their aggregates — see [PropertyRatings].
  ///
  /// `null` means "not answered yet": the page renders as soon as the property
  /// lands and the ratings call finishes after it. `PropertyRatings.empty` is
  /// the different, settled answer "this property has no reviews", which is why
  /// the two are not collapsed into one empty value.
  final PropertyRatings? ratings;

  const PropertyDetailsLoaded({required this.property, this.ratings});

  @override
  List<Object?> get props => [property, ratings];

  PropertyDetailsLoaded copyWith({
    PropertyModel? property,
    PropertyRatings? ratings,
  }) {
    return PropertyDetailsLoaded(
      property: property ?? this.property,
      ratings: ratings ?? this.ratings,
    );
  }
}

class PropertyDetailsError extends PropertyDetailsState {
  final String message;

  const PropertyDetailsError({required this.message});

  @override
  List<Object?> get props => [message];
}
