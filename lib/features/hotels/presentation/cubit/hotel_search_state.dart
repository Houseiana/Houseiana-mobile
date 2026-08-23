import 'package:equatable/equatable.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_summary.dart';

abstract class HotelSearchState extends Equatable {
  const HotelSearchState();

  @override
  List<Object?> get props => const [];
}

class HotelSearchInitial extends HotelSearchState {
  const HotelSearchInitial();
}

class HotelSearchLoading extends HotelSearchState {
  const HotelSearchLoading();
}

/// Everything the results list needs, shared by the settled state and the
/// "appending a page" state so the screen renders both from one code path.
///
/// [HotelSearchLoaded] and [HotelSearchLoadingMore] are SIBLINGS, not parent and
/// child: a screen that tests `state is HotelSearchLoaded` first would otherwise
/// swallow the appending state and never draw its footer spinner.
abstract class HotelSearchResults extends HotelSearchState {
  /// Region groups on an unscoped search, CITY groups once [params] carries a
  /// `regionId` — that one param flips the backend's grouping level, and city
  /// groups come back without an id of their own (so they cannot be drilled
  /// into further).
  final List<HotelGroup> groups;

  /// Derived from `page < totalPages`: the hotel response carries no `hasMore`
  /// flag, unlike property search.
  final bool hasMore;

  /// The exact params these results came from. `loadMore` copies them instead of
  /// rebuilding, so dates/guests/regionId can never drift between pages.
  final HotelSearchParams params;

  /// Backend counters. Pagination here is over GROUPS, not hotels, so [total] is
  /// a group count — never label it "N hotels".
  final int total;
  final int totalGroups;

  const HotelSearchResults({
    required this.groups,
    required this.hasMore,
    required this.params,
    this.total = 0,
    this.totalGroups = 0,
  });

  List<HotelSummary> get hotels => [for (final g in groups) ...g.hotels];

  /// Groups with headers but no rows still read as "nothing found" to a user, so
  /// emptiness is decided on the hotels, not on [groups].
  bool get isEmpty => hotels.isEmpty;

  @override
  List<Object?> get props => [groups, hasMore, params, total, totalGroups];
}

class HotelSearchLoaded extends HotelSearchResults {
  const HotelSearchLoaded({
    required super.groups,
    required super.hasMore,
    required super.params,
    super.total,
    super.totalGroups,
  });
}

class HotelSearchLoadingMore extends HotelSearchResults {
  const HotelSearchLoadingMore({
    required super.groups,
    required super.hasMore,
    required super.params,
    super.total,
    super.totalGroups,
  });
}

class HotelSearchError extends HotelSearchState {
  /// A translation key (`common.loadFailed` / `common.slowServer`). The screen
  /// renders it through `context.tr`, which passes an unknown key straight
  /// through — so a backend reason stored here would render fine too.
  final String messageKey;

  const HotelSearchError(this.messageKey);

  @override
  List<Object?> get props => [messageKey];
}

/// The hotels endpoints are not deployed on the backend this build talks to.
///
/// Deliberately not a [HotelSearchError]: retrying can never help, so the screen
/// must show a "coming soon" empty state instead of a retry button.
class HotelSearchUnavailable extends HotelSearchState {
  const HotelSearchUnavailable();
}
