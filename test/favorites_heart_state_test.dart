import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/services/cache_service.dart';
import 'package:houseiana_mobile_app/core/services/favorites_notifier.dart';
import 'package:houseiana_mobile_app/core/services/lookups_cache.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/properties/cubit/search_cubit.dart';
import 'package:houseiana_mobile_app/features/properties/cubit/search_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serves a search page whose first row carries the "Guest favourite" quality
/// badge (`guestFavorite`) while the user's wishlist holds a different unit.
class _FakeApi implements ApiConsumer {
  final List<String> paths = [];
  final List<Map<String, dynamic>> queries = [];

  /// Property ids the backend reports as saved by this user.
  List<String> savedIds;

  /// Makes the favourites call blow up (timeout, 500, cold start …).
  bool favoritesFail = false;

  _FakeApi({this.savedIds = const ['saved-1']});

  @override
  Future<dynamic> get(String path,
      {Map<String, dynamic>? queryParameters, CancelToken? cancelToken}) async {
    paths.add(path);
    queries.add(Map<String, dynamic>.from(queryParameters ?? const {}));

    if (path.contains('/favorites')) {
      if (favoritesFail) throw Exception('favorites unavailable');
      return {
        'data': [
          for (final id in savedIds)
            {
              'propertyId': id,
              'property': {'id': id, 'title': 'Saved $id'},
            }
        ],
      };
    }

    return {
      'success': true,
      'totalCount': 2,
      'properties': [
        {
          'id': 'badged-1',
          'title': 'Guest favourite chalet',
          'currency': 'EGP',
          'pricePerNight': 3990,
          // The listing quality badge — NOT the viewer's wishlist.
          'guestFavorite': true,
        },
        {
          'id': 'saved-1',
          'title': 'The one the user actually saved',
          'currency': 'EGP',
          'pricePerNight': 9765,
        },
      ],
      'pagination': {'hasMore': false, 'total': 2},
    };
  }

  @override
  Future<dynamic> post(String path,
          {Map<String, dynamic>? body,
          bool formDataIsEnabled = false,
          Map<String, dynamic>? queryParameters,
          CancelToken? cancelToken}) =>
      throw UnimplementedError();

  @override
  Future<dynamic> put(String path,
          {Map<String, dynamic>? body, Map<String, dynamic>? queryParameters}) =>
      throw UnimplementedError();

  @override
  Future<dynamic> patch(String path,
          {Map<String, dynamic>? body, Map<String, dynamic>? queryParameters}) =>
      throw UnimplementedError();

  @override
  Future<dynamic> delete(String path,
          {Map<String, dynamic>? body, Map<String, dynamic>? queryParameters}) =>
      throw UnimplementedError();
}

class _Harness {
  final _FakeApi api;
  final UserService userService;
  final SearchCubit cubit;
  final FavoritesNotifier favorites;

  _Harness(this.api, this.userService, this.cubit, this.favorites);
}

Future<_Harness> _harness({List<String> savedIds = const ['saved-1']}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final api = _FakeApi(savedIds: savedIds);
  final cache = CacheService(prefs);
  final lookups = LookupsCache(cache, prefs);
  final favorites = FavoritesNotifier();
  final session = UserSession(prefs);
  await session.saveUser(userId: 'user-1');

  final userService = UserService(api, cache, lookups, favorites);

  // SearchCubit reads the notifier through the service locator.
  await sl.reset();
  sl.registerSingleton<FavoritesNotifier>(favorites);

  final cubit = SearchCubit(
    PropertyService(api, lookups),
    userService,
    session,
  );
  return _Harness(api, userService, cubit, favorites);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async => sl.reset());

  // A unit un-saved from the wishlist came back with a filled heart on the
  // next search: the results screen filled every row flagged `guestFavorite`,
  // which is the "Guest favourite" quality badge, not the viewer's wishlist.
  group('hearts follow the wishlist, not the Guest-favourite badge', () {
    test('a badged listing nobody saved stays unfilled', () async {
      final h = await _harness();

      await h.cubit.search(PropertySearchParams(page: 1, limit: 20));

      expect(h.favorites.contains('badged-1'), isFalse);
      expect(h.cubit.state, isA<SearchLoaded>());
    });

    test('the saved listing is filled', () async {
      final h = await _harness();

      await h.cubit.search(PropertySearchParams(page: 1, limit: 20));

      expect(h.favorites.contains('saved-1'), isTrue);
    });

    test('un-saving is not undone by the next search', () async {
      final h = await _harness();
      await h.cubit.search(PropertySearchParams(page: 1, limit: 20));
      expect(h.favorites.contains('saved-1'), isTrue);

      // The user removes it — the backend list no longer carries it.
      h.api.savedIds = const [];
      h.favorites.toggle('saved-1');

      await h.cubit.search(PropertySearchParams(page: 1, limit: 20));

      expect(h.favorites.contains('saved-1'), isFalse);
    });

    test('a failed favourites call keeps the hearts it had (and the results)',
        () async {
      final h = await _harness();
      h.favorites.seed({'saved-1'});
      h.api.favoritesFail = true;

      await h.cubit.search(PropertySearchParams(page: 1, limit: 20));

      expect(h.favorites.contains('saved-1'), isTrue);
      expect(h.cubit.state, isA<SearchLoaded>());
    });
  });

  group('favourite ids cover the whole wishlist', () {
    test('asks for more than one screenful and reads both row shapes',
        () async {
      final h = await _harness(savedIds: const ['a', 'b']);

      final ids = await h.userService.getFavoriteIds('user-1');

      expect(ids, {'a', 'b'});
      final favoritesQuery = h.api.queries[h.api.paths
          .indexWhere((p) => p.contains('/favorites'))];
      expect(favoritesQuery['limit'], greaterThanOrEqualTo(80));
    });
  });
}
