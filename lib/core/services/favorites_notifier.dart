import 'package:flutter/foundation.dart';

/// App-wide favourite-property ids, exposed as a [ValueNotifier] so a card's
/// heart can rebuild alone (via [ValueListenableBuilder]) instead of the
/// whole screen/list re-rendering on every toggle.
///
/// `UserService.toggleFavorite` is the single write path: it flips the id
/// here optimistically before the POST and reverts on failure. Screens SEED
/// ids when they load their data ([seed] replaces, [addAll] unions — search
/// pages only know their own slice, so they union).
class FavoritesNotifier extends ValueNotifier<Set<String>> {
  FavoritesNotifier() : super(const <String>{});

  bool contains(String propertyId) => value.contains(propertyId);

  /// Replaces the whole set — for screens that load the user's complete
  /// favourites list (home, favorites screen).
  void seed(Set<String> ids) {
    value = Set.unmodifiable(ids);
  }

  /// Unions ids in — for paged surfaces (search results) that only see
  /// which of *their* items are favourites.
  void addAll(Iterable<String> ids) {
    final next = Set<String>.from(value)..addAll(ids);
    if (next.length != value.length) value = Set.unmodifiable(next);
  }

  /// Flips a single id. Returns true when the id is a favourite AFTER the
  /// toggle. Used for the optimistic update and its rollback (toggling twice
  /// restores the original state).
  bool toggle(String propertyId) {
    final next = Set<String>.from(value);
    final nowFavorite = !next.remove(propertyId);
    if (nowFavorite) next.add(propertyId);
    value = Set.unmodifiable(next);
    return nowFavorite;
  }

  /// Clears everything — e.g. on logout.
  void clear() {
    value = const <String>{};
  }
}
