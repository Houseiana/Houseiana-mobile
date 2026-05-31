import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/host_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/host/cubit/host_listings_state.dart';

class HostListingsCubit extends Cubit<HostListingsState> {
  final _hostService = sl<HostService>();
  final _session = sl<UserSession>();
  
  int _currentPage = 1;
  static const int _limit = 20;

  HostListingsCubit() : super(HostListingsInitial());

  Future<void> loadInitialData() async {
    if (!_session.isLoggedIn) {
      emit(const HostListingsError('Not logged in'));
      return;
    }

    emit(HostListingsLoading());
    _currentPage = 1;

    try {
      final statusesFuture = _hostService.getPropertyAdminStatuses();
      final sortsFuture = _hostService.getPropertySortingOptions();
      final statsFuture = _hostService.getHostStats(_session.userId!);
      
      final statuses = await statusesFuture;
      final sorts = await sortsFuture;
      final stats = await statsFuture;

      final response = await _hostService.getHostListingsPaginated(
        _session.userId!,
        page: _currentPage,
        limit: _limit,
      );

      emit(HostListingsLoaded(
        properties: response.properties,
        statusCounts: response.statusCounts,
        statusOptions: statuses,
        sortOptions: sorts,
        stats: stats,
        hasMore: response.pagination.page < response.pagination.totalPages,
      ));
    } catch (e) {
      emit(HostListingsError(e.toString()));
    }
  }

  Future<void> applyFilters({
    String? status,
    String? sort,
    String? searchQuery,
  }) async {
    final currentState = state;
    if (currentState is! HostListingsLoaded) return;

    // Use current state values if new ones are not provided
    final newStatus = status ?? currentState.selectedStatus;
    final newSort = sort ?? currentState.selectedSort;
    final newQuery = searchQuery ?? currentState.searchQuery;

    emit(currentState.copyWith(isReloadingList: true));
    _currentPage = 1;

    try {
      final response = await _hostService.getHostListingsPaginated(
        _session.userId!,
        page: _currentPage,
        limit: _limit,
        status: newStatus == 'All' ? null : newStatus,
        sortBy: newSort,
        searchQuery: newQuery.isEmpty ? null : newQuery,
      );

      emit(currentState.copyWith(
        properties: response.properties,
        statusCounts: response.statusCounts,
        selectedStatus: newStatus == 'All' ? '' : newStatus, // Use empty string to reset to null in copyWith
        selectedSort: newSort,
        searchQuery: newQuery,
        hasMore: response.pagination.page < response.pagination.totalPages,
        isLoadingMore: false,
        isReloadingList: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(isReloadingList: false));
      // Optionally handle error (e.g. show toast) without losing current state
    }
  }

  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! HostListingsLoaded || !currentState.hasMore || currentState.isLoadingMore) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));
    _currentPage++;

    try {
      final response = await _hostService.getHostListingsPaginated(
        _session.userId!,
        page: _currentPage,
        limit: _limit,
        status: currentState.selectedStatus,
        sortBy: currentState.selectedSort,
        searchQuery: currentState.searchQuery.isEmpty ? null : currentState.searchQuery,
      );

      emit(currentState.copyWith(
        properties: [...currentState.properties, ...response.properties],
        statusCounts: response.statusCounts,
        hasMore: response.pagination.page < response.pagination.totalPages,
        isLoadingMore: false,
      ));
    } catch (e) {
      // Revert loading more state on error
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }
}
