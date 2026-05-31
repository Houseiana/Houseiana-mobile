import 'package:equatable/equatable.dart';
import 'package:houseiana_mobile_app/core/models/host_listings_response_model.dart';
import 'package:houseiana_mobile_app/core/models/property_model.dart';

abstract class HostListingsState extends Equatable {
  const HostListingsState();

  @override
  List<Object?> get props => [];
}

class HostListingsInitial extends HostListingsState {}

class HostListingsLoading extends HostListingsState {}

class HostListingsLoaded extends HostListingsState {
  final List<PropertyModel> properties;
  final StatusCounts statusCounts;
  final List<Map<String, dynamic>> statusOptions;
  final List<Map<String, dynamic>> sortOptions;
  final String? selectedStatus;
  final String? selectedSort;
  final String searchQuery;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isReloadingList;
  final Map<String, dynamic> stats;

  const HostListingsLoaded({
    required this.properties,
    required this.statusCounts,
    required this.statusOptions,
    required this.sortOptions,
    this.selectedStatus,
    this.selectedSort,
    this.searchQuery = '',
    this.hasMore = false,
    this.isLoadingMore = false,
    this.isReloadingList = false,
    this.stats = const {},
  });

  HostListingsLoaded copyWith({
    List<PropertyModel>? properties,
    StatusCounts? statusCounts,
    List<Map<String, dynamic>>? statusOptions,
    List<Map<String, dynamic>>? sortOptions,
    String? selectedStatus,
    String? selectedSort,
    String? searchQuery,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isReloadingList,
    Map<String, dynamic>? stats,
  }) {
    return HostListingsLoaded(
      properties: properties ?? this.properties,
      statusCounts: statusCounts ?? this.statusCounts,
      statusOptions: statusOptions ?? this.statusOptions,
      sortOptions: sortOptions ?? this.sortOptions,
      selectedStatus: selectedStatus == '' ? null : (selectedStatus ?? this.selectedStatus),
      selectedSort: selectedSort == '' ? null : (selectedSort ?? this.selectedSort),
      searchQuery: searchQuery ?? this.searchQuery,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isReloadingList: isReloadingList ?? this.isReloadingList,
      stats: stats ?? this.stats,
    );
  }

  @override
  List<Object?> get props => [
        properties,
        statusCounts,
        statusOptions,
        sortOptions,
        selectedStatus,
        selectedSort,
        searchQuery,
        hasMore,
        isLoadingMore,
        isReloadingList,
        stats,
      ];
}

class HostListingsError extends HostListingsState {
  final String message;

  const HostListingsError(this.message);

  @override
  List<Object?> get props => [message];
}
