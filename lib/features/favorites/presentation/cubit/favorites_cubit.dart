import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/favorites/presentation/cubit/favorites_state.dart';

class FavoritesCubit extends Cubit<FavoritesState> {
  final UserService _userService;
  final UserSession _session;

  FavoritesCubit(this._userService, this._session) : super(FavoritesInitial());

  Future<void> getFavorites() async {
    if (!_session.isLoggedIn) {
      emit(const FavoritesLoaded(favorites: []));
      return;
    }

    emit(FavoritesLoading());
    try {
      final favorites = await _userService.getFavorites(
        _session.userId!,
        page: 1,
        limit: 50,
      );
      emit(FavoritesLoaded(favorites: favorites));
    } catch (e) {
      emit(FavoritesError(message: e.toString()));
    }
  }

  Future<void> toggleFavorite(String propertyId) async {
    if (!_session.isLoggedIn) return;

    final current = state;
    if (current is FavoritesLoaded) {
      final existingIds = current.favorites
          .map((f) => (f['propertyId'] ?? f['id'] ?? '').toString())
          .toSet();

      final isFav = existingIds.contains(propertyId);
      List<Map<String, dynamic>> updated;

      if (isFav) {
        updated = current.favorites
            .where((f) =>
                (f['propertyId'] ?? f['id'] ?? '').toString() != propertyId)
            .cast<Map<String, dynamic>>()
            .toList();
      } else {
        updated = [...current.favorites, {'propertyId': propertyId}];
      }

      emit(FavoritesLoaded(favorites: updated));
    }

    await _userService.toggleFavorite(
      userId: _session.userId!,
      propertyId: propertyId,
    );
  }

  bool isFavorite(String propertyId) {
    final current = state;
    if (current is FavoritesLoaded) {
      return current.favorites.any(
        (f) => (f['propertyId'] ?? f['id'] ?? '').toString() == propertyId,
      );
    }
    return false;
  }
}