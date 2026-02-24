import 'package:equatable/equatable.dart';

abstract class PropertiesState extends Equatable {
  const PropertiesState();

  @override
  List<Object?> get props => [];
}

class PropertiesInitial extends PropertiesState {}

class PropertiesLoading extends PropertiesState {}

class PropertiesLoaded extends PropertiesState {
  final List<dynamic> properties;

  const PropertiesLoaded({required this.properties});

  @override
  List<Object?> get props => [properties];
}

class PropertiesError extends PropertiesState {
  final String message;

  const PropertiesError({required this.message});

  @override
  List<Object?> get props => [message];
}
