import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A lightweight persistent key/value cache backed by [SharedPreferences] with
/// an in-memory fast path.
///
/// Values are stored as JSON envelopes carrying a timestamp so an optional TTL
/// can expire stale entries. The home screen uses this for a **cache-first**
/// (read-through) strategy: read from cache, and only hit the network on a
/// miss — then write the response back. Favouriting a unit invalidates the
/// home cache (see `UserService.toggleFavorite`) so the next load fetches
/// fresh data and re-caches it.
class CacheService {
  final SharedPreferences _prefs;

  /// Decoded in-memory copies so repeated reads within a session skip both the
  /// JSON decoding and the SharedPreferences channel.
  final Map<String, _CacheEntry> _memory = {};

  /// Namespacing prefix so cache keys never collide with other prefs
  /// (UserSession, locale, cookies, ...).
  static const String _storePrefix = 'app_cache__';

  CacheService(this._prefs);

  String _storeKey(String key) => '$_storePrefix$key';

  /// Stores [value] (any JSON-encodable object) under [key]. When [ttl] is
  /// provided the entry is treated as expired once that much time has elapsed.
  Future<void> setJson(String key, Object? value, {Duration? ttl}) async {
    final entry = _CacheEntry(
      data: value,
      storedAtMs: DateTime.now().millisecondsSinceEpoch,
      ttlMs: ttl?.inMilliseconds,
    );
    _memory[key] = entry;
    try {
      await _prefs.setString(_storeKey(key), jsonEncode(entry.toJson()));
    } catch (_) {
      // Non-encodable payload — keep the in-memory copy and skip persistence.
    }
  }

  /// Returns the cached value for [key], or null when it is missing, expired,
  /// corrupt, or not of type [T]. Reads the in-memory copy first, then falls
  /// back to SharedPreferences (populating memory). Expired entries are evicted.
  T? getJson<T>(String key) {
    final entry = _memory[key] ?? _readFromPrefs(key);
    if (entry == null) return null;
    if (entry.isExpired) {
      remove(key); // fire-and-forget eviction
      return null;
    }
    final data = entry.data;
    return data is T ? data : null;
  }

  /// Whether a non-expired entry exists for [key].
  bool has(String key) => getJson<Object>(key) != null;

  _CacheEntry? _readFromPrefs(String key) {
    final raw = _prefs.getString(_storeKey(key));
    if (raw == null) return null;
    try {
      final entry =
          _CacheEntry.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      _memory[key] = entry;
      return entry;
    } catch (_) {
      return null;
    }
  }

  /// Removes a single cache entry.
  Future<void> remove(String key) async {
    _memory.remove(key);
    await _prefs.remove(_storeKey(key));
  }

  /// Removes every cache entry whose key starts with [keyPrefix]. Used to
  /// invalidate a whole family of entries at once (e.g. all home list caches
  /// across the different featured-region filters).
  Future<void> removeByPrefix(String keyPrefix) async {
    _memory.removeWhere((k, _) => k.startsWith(keyPrefix));
    final fullPrefix = _storeKey(keyPrefix);
    final keys =
        _prefs.getKeys().where((k) => k.startsWith(fullPrefix)).toList();
    for (final k in keys) {
      await _prefs.remove(k);
    }
  }

  /// Clears the entire cache namespace (leaves other prefs untouched).
  Future<void> clear() async {
    _memory.clear();
    final keys =
        _prefs.getKeys().where((k) => k.startsWith(_storePrefix)).toList();
    for (final k in keys) {
      await _prefs.remove(k);
    }
  }
}

class _CacheEntry {
  final Object? data;
  final int storedAtMs;
  final int? ttlMs;

  const _CacheEntry({
    required this.data,
    required this.storedAtMs,
    this.ttlMs,
  });

  bool get isExpired {
    final ttl = ttlMs;
    if (ttl == null) return false;
    final age = DateTime.now().millisecondsSinceEpoch - storedAtMs;
    return age > ttl;
  }

  Map<String, dynamic> toJson() => {
        'data': data,
        'ts': storedAtMs,
        if (ttlMs != null) 'ttl': ttlMs,
      };

  factory _CacheEntry.fromJson(Map<String, dynamic> json) => _CacheEntry(
        data: json['data'],
        storedAtMs: (json['ts'] as num?)?.toInt() ?? 0,
        ttlMs: (json['ttl'] as num?)?.toInt(),
      );
}

/// Cache-key helpers for the home screen data. Centralised here so the writer
/// ([HomeScreen]) and the invalidator (`UserService.toggleFavorite`) always
/// agree on the exact keys/prefixes.
class HomeCache {
  HomeCache._();

  /// Prefix covering every cached home list (one entry per featured-region
  /// filter). Removing this prefix invalidates all of them at once.
  static const String listPrefix = 'home_list_';

  /// Prefix covering the cached favourite-id sets (one entry per user).
  static const String favPrefix = 'home_fav_';

  /// Cache key for the region-category chips (independent of user/filter).
  /// Keyed per app language: the backend localizes names via `?lang=`, so
  /// each locale caches its own copy — otherwise a language switch would show
  /// the old language's names for up to [categoriesTtl].
  static String categoriesKey(String lang) => 'home_categories_$lang';

  /// Cache key for the home list under a given featured-region filter.
  /// `null` (the "All" chip) maps to a stable literal key.
  ///
  /// The `v2` segment retires entries written while the home rails were
  /// fetched with a `userId` (personalized pricing): those rows carry a
  /// signed-in guest's discounted price, and one bucket is shared by every
  /// session, so a stale entry would keep serving them for up to [listTtl].
  /// The prefix is unchanged, so prefix-wide invalidation still clears both.
  ///
  /// [lang] buckets the entry per app language, exactly like [categoriesKey]:
  /// the rows carry backend-localized text (titles, city names), so a single
  /// shared bucket kept serving the previous language's rails for up to
  /// [listTtl] after a switch — even across an app restart.
  static String listKey(int? featuredRegionId, String lang) =>
      '${listPrefix}v2_${lang}_${featuredRegionId ?? 'all'}';

  /// Cache key for a user's favourite-id set. Guests share a single bucket.
  static String favKey(String? userId) => '$favPrefix${userId ?? 'guest'}';

  // TTLs are generous safety nets against indefinitely stale data — the
  // primary invalidation is a favourite toggle + pull-to-refresh, not expiry.
  static const Duration listTtl = Duration(hours: 2);
  static const Duration favTtl = Duration(hours: 2);
  static const Duration categoriesTtl = Duration(hours: 24);
}

/// Cache keys for the home screen's Hotels segment.
///
/// A separate prefix from [HomeCache] on purpose: `UserService.toggleFavorite`
/// invalidates `HomeCache.listPrefix` on every property favourite, and a hotel
/// rail has no business being dropped by that (nor the reverse).
class HotelCache {
  HotelCache._();

  /// Prefix covering every cached hotel list (one entry per region filter).
  static const String listPrefix = 'hotel_list_';

  /// Cache key for the hotel rails under a given region filter. `null` (the
  /// unscoped search) maps to a stable literal key.
  ///
  /// [lang] buckets the entry per app language for the same reason as
  /// [HomeCache.listKey]: hotel, city, region and amenity names all come back
  /// backend-localized on the `lang` header, so one shared bucket would keep
  /// serving the previous language for up to [listTtl] — even across a restart.
  static String listKey(String lang, [int? regionId]) =>
      '${listPrefix}v1_${lang}_${regionId ?? 'all'}';

  static const Duration listTtl = Duration(hours: 2);
}
