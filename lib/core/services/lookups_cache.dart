import 'package:shared_preferences/shared_preferences.dart';

import 'cache_service.dart';

/// Read-through cache for the near-static `/api/Lookups/*` endpoints
/// (Gender, PayoutMethod, PropertySorting, Amenities, ...). These lists are
/// re-fetched on every screen open today; their values change rarely, so a
/// long TTL is safe.
///
/// The backend localizes lookup `name`s via the `lang` request header
/// (see `LangInterceptor`), so the cache key embeds the active locale read
/// from the same SharedPreferences key the interceptor uses — key and header
/// always agree, and a language switch simply resolves to a different entry
/// (no invalidation needed).
///
/// The **raw JSON response** is cached (not parsed models) so every existing
/// caller-side parser keeps working unchanged.
class LookupsCache {
  final CacheService _cache;
  final SharedPreferences _prefs;

  LookupsCache(this._cache, this._prefs);

  /// Same key `LocaleCubit`/`LangInterceptor` use.
  static const String _localeKey = 'app_locale';

  static const Duration defaultTtl = Duration(hours: 24);

  String _key(String endpoint) =>
      'lookup_${endpoint}_${_prefs.getString(_localeKey) ?? 'en'}';

  /// Returns the cached JSON for [endpoint], or invokes [fetch], caches the
  /// non-null result, and returns it. Errors from [fetch] propagate so callers
  /// keep their existing fallbacks.
  Future<dynamic> getOrFetch(
    String endpoint,
    Future<dynamic> Function() fetch, {
    Duration ttl = defaultTtl,
  }) async {
    final cached = _cache.getJson<Object>(_key(endpoint));
    if (cached != null) return cached;

    final response = await fetch();
    if (response != null) {
      await _cache.setJson(_key(endpoint), response, ttl: ttl);
    }
    return response;
  }
}
