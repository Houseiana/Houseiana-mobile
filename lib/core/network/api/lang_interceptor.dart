import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Adds a `lang` header (`ar` or `en`) to every request so the backend can
/// return localized data. This mirrors the web client, which sets the `lang`
/// header on all requests (GET/POST/PUT/…) in its request interceptor — not
/// only reads. The active locale is read from SharedPreferences using the same
/// key written by [LocaleCubit].
class LangInterceptor extends Interceptor {
  static const String _localeKey = 'app_locale';
  static const String _defaultLang = 'en';

  final SharedPreferences _prefs;

  LangInterceptor(this._prefs);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final stored = _prefs.getString(_localeKey);
    final lang = (stored == 'ar') ? 'ar' : (stored == 'en' ? 'en' : _defaultLang);
    options.headers['lang'] = lang;
    handler.next(options);
  }
}
