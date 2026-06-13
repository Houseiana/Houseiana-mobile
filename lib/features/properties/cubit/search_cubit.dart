import 'package:flutter_bloc/flutter_bloc.dart';
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

  Future<void> search(PropertySearchParams params) async {
    emit(SearchLoading());
    try {
      final results = await _propertyService.searchProperties(
        params,
        userId: _userSession.userId,
      );
      final propertyMaps =
          results.map((property) => property.toJson()).toList();
      final hasMore = results.length >= params.limit;
      emit(SearchLoaded(
        properties: propertyMaps,
        hasMore: hasMore,
        params: params,
      ));
    } catch (e) {
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
      );

      final results = await _propertyService.searchProperties(
        newParams,
        userId: _userSession.userId,
      );
      final propertyMaps =
          results.map((property) => property.toJson()).toList();

      final hasMore = results.length >= newParams.limit;
      emit(SearchLoaded(
        properties: [...currentState.properties, ...propertyMaps],
        hasMore: hasMore,
        params: newParams,
      ));
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }

  Future<void> toggleFavorite(String propertyId) async {
    final currentState = state;
    if (currentState is! SearchLoaded) return;
    if (!_userSession.isLoggedIn) return;

    final isFav = currentState.properties.any((p) {
      final id = (p['id'] ?? p['_id'] ?? p['propertyId'] ?? '').toString();
      return id == propertyId &&
          (p['isGuestFavorite'] == true || p['guestFavorite'] == true);
    });

    final updated = currentState.properties.map((p) {
      final id = (p['id'] ?? p['_id'] ?? p['propertyId'] ?? '').toString();
      if (id == propertyId) {
        return {...p, 'guestFavorite': !isFav};
      }
      return p;
    }).toList();

    emit(SearchLoaded(
      properties: updated,
      hasMore: currentState.hasMore,
      params: currentState.params,
    ));

    await _userService.toggleFavorite(
      userId: _userSession.userId!,
      propertyId: propertyId,
    );
  }
}
