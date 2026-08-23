import 'package:flutter/foundation.dart';

/// Favourite-HOTEL ids, exposed as a [ValueNotifier] so one card's heart can
/// rebuild alone instead of the whole list.
///
/// Deliberately separate from `FavoritesNotifier` rather than sharing it:
///
/// * that notifier is REPLACE-seeded (`seed`) on every home and favourites load
///   from `/users/{id}/favorites`, which only ever lists PROPERTIES — any hotel
///   id living in the same set would be wiped on the next property load;
/// * hotel ids are UUIDs from a different id space, and they toggle through a
///   different endpoint (`POST /api/hotels/{id}/favorite`).
///
/// There is no "list my favourite hotels" endpoint yet, so this is seeded with
/// [addAll] (a union) from the `isFavorite` flag on search and details rows —
/// NEVER from `isGuestFavorite`, which is the quality badge and would light up
/// hearts the user never set.
class HotelFavoritesNotifier extends ValueNotifier<Set<String>> {
  HotelFavoritesNotifier() : super(const <String>{});

  bool contains(String hotelId) => value.contains(hotelId);

  /// Replaces the whole set. Only for a surface that knows the user's COMPLETE
  /// hotel wishlist — no endpoint offers that today, so prefer [addAll].
  void seed(Set<String> ids) {
    value = Set.unmodifiable(ids);
  }

  /// Unions ids in — for paged surfaces that only see which of *their* rows are
  /// favourites.
  void addAll(Iterable<String> ids) {
    final next = Set<String>.from(value)..addAll(ids);
    if (next.length != value.length) value = Set.unmodifiable(next);
  }

  /// Removes ids that came back un-favourited, so a heart cleared on another
  /// device does not stay lit after a refresh.
  void applyStates(Map<String, bool> states) {
    final next = Set<String>.from(value);
    states.forEach((id, isFavorite) {
      if (isFavorite) {
        next.add(id);
      } else {
        next.remove(id);
      }
    });
    if (next.length != value.length || !next.containsAll(value)) {
      value = Set.unmodifiable(next);
    }
  }

  /// Flips a single id. Returns true when the hotel is a favourite AFTER the
  /// toggle — used for the optimistic update and its rollback (toggling twice
  /// restores the original state).
  bool toggle(String hotelId) {
    final next = Set<String>.from(value);
    final nowFavorite = !next.remove(hotelId);
    if (nowFavorite) next.add(hotelId);
    value = Set.unmodifiable(next);
    return nowFavorite;
  }

  /// Clears everything — e.g. on logout.
  void clear() {
    value = const <String>{};
  }
}
