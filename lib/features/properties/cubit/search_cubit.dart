import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/errors/exceptions.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/favorites_notifier.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/features/properties/cubit/search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final PropertyService _propertyService;
  final UserService _userService;
  final UserSession _userSession;

  SearchCubit(this._propertyService, this._userService, this._userSession)
      : super(SearchInitial());

  /// Cancels the previous in-flight search/page when a new one starts (or
  /// the cubit closes) — rapid filter/sort changes stop wasting bandwidth
  /// and parse work on results that will be discarded anyway.
  CancelToken? _requestToken;

  CancelToken _nextToken() {
    _requestToken?.cancel();
    return _requestToken = CancelToken();
  }

  @override
  Future<void> close() {
    _requestToken?.cancel();
    return super.close();
  }

  /// Union-adds this page's favourite ids into the app-wide notifier (a
  /// search page only knows its own slice — never remove). Hearts render from
  /// the notifier, so favourite state stays out of the emitted list.
  void _seedFavorites(List<Map<String, dynamic>> maps) {
    if (!_userSession.isLoggedIn) return;
    sl<FavoritesNotifier>().addAll(maps
        .where((p) =>
            p['guestFavorite'] == true || p['isGuestFavorite'] == true)
        .map((p) => (p['id'] ?? p['_id'] ?? p['propertyId'] ?? '').toString())
        .where((id) => id.isNotEmpty));
  }

  Future<void> search(PropertySearchParams params) async {
    emit(SearchLoading());
    try {
      final page = await _propertyService.searchProperties(
        params,
        userId: _userSession.userId,
        cancelToken: _nextToken(),
      );
      // Already normalized maps (PropertyService runs the model round-trip,
      // off the UI isolate for big pages).
      final propertyMaps = page.properties;
      _seedFavorites(propertyMaps);
      final hasMore = propertyMaps.length >= params.limit;
      emit(SearchLoaded(
        properties: propertyMaps,
        hasMore: hasMore,
        params: params,
        total: page.total,
      ));
    } on RequestCancelledException {
      // Superseded by a newer search (or the screen closed) — never surface
      // a "Request cancelled" error state.
      return;
    } catch (e) {
      if (isClosed) return;
      emit(SearchError(e.toString()));
    }
  }

  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! SearchLoaded) return;
    if (!currentState.hasMore) return;

    emit(SearchLoadingMore(
      existing: currentState.properties,
      hasMore: true,
      params: currentState.params,
      total: currentState.total,
    ));

    try {
      final nextPage = currentState.params.page + 1;
      final newParams = PropertySearchParams(
        location: currentState.params.location,
        checkIn: currentState.params.checkIn,
        checkOut: currentState.params.checkOut,
        guests: currentState.params.guests,
        minPrice: currentState.params.minPrice,
        maxPrice: currentState.params.maxPrice,
        amenities: currentState.params.amenities,
        propertyType: currentState.params.propertyType,
        minBedrooms: currentState.params.minBedrooms,
        beds: currentState.params.beds,
        minBathrooms: currentState.params.minBathrooms,
        minRating: currentState.params.minRating,
        page: nextPage,
        limit: currentState.params.limit,
        isSorted: currentState.params.isSorted,
        sortBy: currentState.params.sortBy,
        regionId: currentState.params.regionId,
        villageId: currentState.params.villageId,
        featuredRegionId: currentState.params.featuredRegionId,
        lat: currentState.params.lat,
        lng: currentState.params.lng,
        radiusKm: currentState.params.radiusKm,
      );

      final page = await _propertyService.searchProperties(
        newParams,
        userId: _userSession.userId,
        cancelToken: _nextToken(),
      );
      final propertyMaps = page.properties;
      _seedFavorites(propertyMaps);

      final hasMore = propertyMaps.length >= newParams.limit;
      emit(SearchLoaded(
        properties: [...currentState.properties, ...propertyMaps],
        hasMore: hasMore,
        params: newParams,
        total: page.total ?? currentState.total,
      ));
    } on RequestCancelledException {
      return;
    } catch (e) {
      if (isClosed) return;
      emit(SearchError(e.toString()));
    }
  }

  Future<void> toggleFavorite(String propertyId) async {
    if (!_userSession.isLoggedIn) return;
    // No emit: UserService flips the app-wide FavoritesNotifier
    // optimistically (rolling back on failure), so only the tapped heart
    // repaints — the results list is never re-emitted for a heart tap.
    try {
      await _userService.toggleFavorite(
        userId: _userSession.userId!,
        propertyId: propertyId,
      );
    } catch (_) {
      // Rollback already handled by the notifier.
    }
  }
}
