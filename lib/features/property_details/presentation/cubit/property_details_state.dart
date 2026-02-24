import 'package:equatable/equatable.dart';

abstract class PropertyDetailsState extends Equatable {
  const PropertyDetailsState();

  @override
  List<Object?> get props => [];
}

class PropertyDetailsInitial extends PropertyDetailsState {}

class PropertyDetailsLoading extends PropertyDetailsState {}

class PropertyDetailsLoaded extends PropertyDetailsState {
  final dynamic property;

  const PropertyDetailsLoaded({required this.property});

  @override
  List<Object?> get props => [property];
}

class PropertyDetailsError extends PropertyDetailsState {
  final String message;

  const PropertyDetailsError({required this.message});

  @override
  List<Object?> get props => [message];
}
