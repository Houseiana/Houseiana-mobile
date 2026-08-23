import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/errors/exceptions.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_summary.dart';
import 'package:houseiana_mobile_app/core/services/hotel_favorites_notifier.dart';
import 'package:houseiana_mobile_app/core/services/hotel_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/hotels/presentation/cubit/hotel_search_state.dart';

/// Drives the standalone hotel results screen: one grouped search, paging over
/// the groups, and drilling from a region into its cities.
class HotelSearchCubit extends Cubit<HotelSearchState> {
  final HotelService _service;
  final UserSession _session;

  HotelSearchCubit(this._service, this._session)
      : super(const HotelSearchInitial());

  static const int _pageSize = 20;

  /// Cancels the previous in-flight search/page when a new one starts (or the
  /// cubit closes), so a fast drill-down or a screen pop stops paying for
  /// results that will be thrown away.
  CancelToken? _requestToken;

  /// The query the visible results came from, kept outside the state so
  /// [refresh] and [drillDownToRegion] still work from an error state — where
  /// there is no [HotelSearchResults] around to read `params` off.
  HotelSearchParams? _lastParams;

  HotelSearchParams? get lastParams => _lastParams;

  CancelToken _nextToken() {
    _requestToken?.cancel();
    return _requestToken = CancelToken();
  }

  @override
  Future<void> close() {
    _requestToken?.cancel();
    return super.close();
  }

  /// Entry point for the results route: turns `ModalRoute.settings.arguments`
  /// into params and searches. Tolerant about types because the callers differ —
  /// the home hotels segment passes a region id it read off a search response,
  /// the search sheet passes DateTime objects.
  Future<void> searchFromArguments(Map<String, dynamic>? arguments) =>
      search(paramsFromArguments(arguments));

  Future<void> search(HotelSearchParams params) =>
      _load(params, showLoading: true);

  /// Region to cities. Sending `regionId` makes the backend group by CITY
  /// instead of by region, which is what the "Hotels in Hammam" header shows.
  ///
  /// One-way on purpose: [HotelSearchParams.copyWith] cannot null a `regionId`
  /// back out, and going up is a pop to the unscoped screen anyway.
  Future<void> drillDownToRegion(int regionId) {
    final base = _lastParams ?? paramsFromArguments(null);
    return search(base.copyWith(regionId: regionId, page: 1));
  }

  /// Pull-to-refresh. Keeps the current list on screen while it reloads —
  /// RefreshIndicator already draws a spinner, so emitting [HotelSearchLoading]
  /// here would swap the results for a skeleton for no reason. From an
  /// error/unavailable state there is nothing to keep, so the loading state is
  /// emitted as usual.
  Future<void> refresh() {
    final params = _lastParams;
    if (params == null) return Future<void>.value();
    return _load(
      params.copyWith(page: 1),
      showLoading: state is! HotelSearchResults,
    );
  }

  Future<void> loadMore() async {
    final current = state;
    // Not loaded yet, already appending, or on the last page — all no-ops.
    if (current is! HotelSearchLoaded || !current.hasMore) return;

    emit(HotelSearchLoadingMore(
      groups: current.groups,
      hasMore: current.hasMore,
      params: current.params,
      total: current.total,
      totalGroups: current.totalGroups,
    ));

    // copyWith, never a hand-rebuilt params object: rebuilding by hand is how
    // the property search kept silently dropping filters between pages.
    final nextParams = current.params.copyWith(page: current.params.page + 1);
    try {
      final page = await _service.searchHotels(
        nextParams,
        cancelToken: _nextToken(),
      );
      _seedFavoriteHearts(nextParams, page);
      if (isClosed) return;
      _lastParams = nextParams;
      emit(HotelSearchLoaded(
        groups: _mergeGroups(current.groups, page.groups),
        hasMore: page.hasMore,
        params: nextParams,
        total: page.total,
        totalGroups: page.totalGroups,
      ));
    } on RequestCancelledException {
      return;
    } on HotelsUnavailableException {
      if (isClosed) return;
      emit(const HotelSearchUnavailable());
    } catch (e) {
      if (isClosed) return;
      emit(HotelSearchError(loadErrorKeyFor(e)));
    }
  }

  Future<void> _load(
    HotelSearchParams params, {
    required bool showLoading,
  }) async {
    _lastParams = params;
    if (showLoading) emit(const HotelSearchLoading());
    try {
      final page = await _service.searchHotels(
        params,
        cancelToken: _nextToken(),
      );
      // Seed before emitting so no heart ever paints from a stale set.
      _seedFavoriteHearts(params, page);
      if (isClosed) return;
      emit(HotelSearchLoaded(
        groups: page.groups,
        hasMore: page.hasMore,
        params: params,
        total: page.total,
        totalGroups: page.totalGroups,
      ));
    } on RequestCancelledException {
      // Superseded by a newer query (or the screen closed) — never surface a
      // "Request cancelled" error state.
      return;
    } on HotelsUnavailableException {
      // 404 on /api/hotel-search: the feature is not deployed on this backend.
      // A retry can never fix that, hence its own state rather than an error.
      if (isClosed) return;
      emit(const HotelSearchUnavailable());
    } catch (e) {
      if (isClosed) return;
      // Always a translation key. The transport's own messages ("Unexpected
      // error occurred", "Server error occurred") are untranslated English, so
      // for a plain list load a localized "couldn't load, try again" beats
      // echoing them; the reason-carrying calls (quote, booking) are where a
      // backend message is worth surfacing verbatim.
      emit(HotelSearchError(loadErrorKeyFor(e)));
    }
  }

  /// Lights the hearts for rows the backend says this user saved.
  ///
  /// Union only ([HotelFavoritesNotifier.addAll]), and only from `isFavorite` —
  /// `isGuestFavorite` is the quality badge, and seeding from it resurrects
  /// hotels the user never saved. A search without a `userId` reports every row
  /// as `isFavorite:false`, which says nothing about the wishlist, so it is
  /// skipped entirely rather than read as "nothing is saved".
  void _seedFavoriteHearts(HotelSearchParams params, HotelSearchPage page) {
    final userId = params.userId;
    if (userId == null || userId.isEmpty) return;
    final ids = [
      for (final hotel in page.flatHotels)
        if (hotel.isFavorite) hotel.hotelId,
    ];
    if (ids.isEmpty) return;
    sl<HotelFavoritesNotifier>().addAll(ids);
  }

  /// Merges a freshly fetched page into the groups already on screen.
  ///
  /// Paging is over groups, so page 2 normally brings entirely new ones — but a
  /// group repeated across pages must extend the existing header instead of
  /// drawing a second one, and a hotel repeated inside it must not appear twice
  /// (the list keys off hotelId).
  static List<HotelGroup> _mergeGroups(
    List<HotelGroup> existing,
    List<HotelGroup> incoming,
  ) {
    final merged = <HotelGroup>[...existing];
    final indexByKey = <String, int>{
      for (var i = 0; i < merged.length; i++) _groupKey(merged[i]): i,
    };

    for (final group in incoming) {
      final key = _groupKey(group);
      final at = indexByKey[key];
      if (at == null) {
        indexByKey[key] = merged.length;
        merged.add(group);
        continue;
      }
      final current = merged[at];
      final seen = {for (final hotel in current.hotels) hotel.hotelId};
      final added = [
        for (final hotel in group.hotels)
          if (seen.add(hotel.hotelId)) hotel,
      ];
      if (added.isEmpty) continue;
      merged[at] = current.copyWith(hotels: [...current.hotels, ...added]);
    }
    return merged;
  }

  /// City groups carry no `regionId`, so they can only be identified by their
  /// (backend-localized) name — fine, because a language switch re-runs the
  /// whole search instead of merging pages across languages.
  static String _groupKey(HotelGroup group) =>
      group.regionId?.toString() ?? 'name:${group.name}';

  /// Route arguments to params. Keys match what the results route is pushed
  /// with: `regionId`, `checkIn`, `checkOut`, `adults`, `children`, `rooms`
  /// (`regionName` is the screen's header, not a query param).
  HotelSearchParams paramsFromArguments(Map<String, dynamic>? arguments) {
    final args = arguments ?? const <String, dynamic>{};
    return HotelSearchParams(
      // Sent so each row comes back with this viewer's own `isFavorite` state.
      userId: _session.isLoggedIn ? _session.userId : null,
      regionId: asHotelIntOrNull(args['regionId']),
      checkIn: _argDate(args['checkIn']),
      checkOut: _argDate(args['checkOut']),
      adults: asHotelIntOrNull(args['adults']),
      children: asHotelIntOrNull(args['children']),
      rooms: asHotelIntOrNull(args['rooms']),
      limit: asHotelInt(args['limit'], _pageSize),
    );
  }

  /// A date argument arrives either pre-formatted or as a [DateTime]. Both end
  /// up as a plain calendar day: an ISO timestamp is mis-handled here the same
  /// way it was on property search.
  static String? _argDate(dynamic raw) {
    if (raw is DateTime) return HotelService.apiDate(raw);
    return HotelSearchParams.dateOnly(raw?.toString());
  }
}
