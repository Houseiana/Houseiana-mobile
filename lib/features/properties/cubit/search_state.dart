import 'package:equatable/equatable.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  final List<Map<String, dynamic>> properties;
  final bool hasMore;
  final PropertySearchParams params;

  const SearchLoaded({
    required this.properties,
    required this.hasMore,
    required this.params,
  });

  @override
  List<Object?> get props => [properties, hasMore, params];
}

class SearchLoadingMore extends SearchState {
  final List<Map<String, dynamic>> existing;
  final bool hasMore;
  final PropertySearchParams params;

  const SearchLoadingMore({
    required this.existing,
    required this.hasMore,
    required this.params,
  });

  @override
  List<Object?> get props => [existing, hasMore, params];
}

class SearchError extends SearchState {
  final String message;

  const SearchError(this.message);

  @override
  List<Object?> get props => [message];
}
