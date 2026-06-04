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

  // Maps known status names (any locale) to a canonical English key, mirroring
  // the web project. Used to resolve a selected status to its lookup id.
  static const Map<String, String> _canonicalStatusKey = {
    'active': 'active',
    'pending': 'pending',
    'draft': 'draft',
    'inactive': 'inactive',
    'paused': 'paused',
    'actionrequired': 'actionrequired',
    'rejected': 'rejected',
    'suspended': 'suspended',
    // Arabic
    'نشط': 'active',
    'معلق': 'pending',
    'مسودة': 'draft',
    'غيرنشط': 'inactive',
    'متوقف': 'paused',
    'إجراءمطلوب': 'actionrequired',
    'مرفوض': 'rejected',
  };

  String _canonical(String raw) {
    final norm = raw.toLowerCase().replaceAll(RegExp(r'\s'), '');
    return _canonicalStatusKey[norm] ?? norm;
  }

  /// Resolves a selected status (display name) to its lookup status id, matching
  /// the web behaviour which filters by numeric id rather than by name.
  /// Returns null for "all"/empty/unresolved so the backend returns everything.
  String? _statusIdFor(
    List<Map<String, dynamic>> statusOptions,
    String? status,
  ) {
    if (status == null || status.isEmpty || status.toLowerCase() == 'all') {
      return null;
    }
    final target = _canonical(status);
    for (final opt in statusOptions) {
      final name = (opt['name'] ?? opt['label'] ?? '').toString();
      if (_canonical(name) == target) {
        return opt['id']?.toString();
      }
    }
    return null;
  }

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
        status: _statusIdFor(currentState.statusOptions, newStatus),
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
        status: _statusIdFor(currentState.statusOptions, currentState.selectedStatus),
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
