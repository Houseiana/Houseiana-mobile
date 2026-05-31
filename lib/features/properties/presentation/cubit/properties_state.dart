import 'package:equatable/equatable.dart';
import 'package:houseiana_mobile_app/core/models/property_model.dart';

abstract class PropertiesState extends Equatable {
  const PropertiesState();

  @override
  List<Object?> get props => [];
}

class PropertiesInitial extends PropertiesState {}

class PropertiesLoading extends PropertiesState {}

class PropertiesLoaded extends PropertiesState {
  final List<PropertyModel> properties;
  final bool hasMore;
  final int currentPage;
  final bool isLoadingMore;

  const PropertiesLoaded({
    required this.properties,
    this.hasMore = true,
    this.currentPage = 1,
    this.isLoadingMore = false,
  });

  PropertiesLoaded copyWith({
    List<PropertyModel>? properties,
    bool? hasMore,
    int? currentPage,
    bool? isLoadingMore,
  }) {
    return PropertiesLoaded(
      properties: properties ?? this.properties,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [properties, hasMore, currentPage, isLoadingMore];
}

class PropertiesError extends PropertiesState {
  final String message;

  const PropertiesError({required this.message});

  @override
  List<Object?> get props => [message];
}
