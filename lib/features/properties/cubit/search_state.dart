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

  /// Backend-reported total across all pages (`totalCount` in the search
  /// response), or null when unknown — the UI then falls back to
  /// `properties.length`.
  final int? total;

  const SearchLoaded({
    required this.properties,
    required this.hasMore,
    required this.params,
    this.total,
  });

  @override
  List<Object?> get props => [properties, hasMore, params, total];
}

class SearchLoadingMore extends SearchState {
  final List<Map<String, dynamic>> existing;
  final bool hasMore;
  final PropertySearchParams params;

  /// See [SearchLoaded.total].
  final int? total;

  const SearchLoadingMore({
    required this.existing,
    required this.hasMore,
    required this.params,
    this.total,
  });

  @override
  List<Object?> get props => [existing, hasMore, params, total];
}

class SearchError extends SearchState {
  final String message;

  const SearchError(this.message);

  @override
  List<Object?> get props => [message];
}
