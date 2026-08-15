import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/services/cache_service.dart';
import 'package:houseiana_mobile_app/core/services/lookups_cache.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/features/country/presentation/screens/country_screen.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:houseiana_mobile_app/i18n/locale_aware_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serves `/api/lookups/country` in whatever language the `lang` QUERY param
/// asks for — the way production behaves (the `lang` header is ignored by this
/// controller).
class _CountryApi implements ApiConsumer {
  /// Every `lang` the screen has asked for, in order.
  final List<String> langs = [];

  @override
  Future<dynamic> get(String path,
      {Map<String, dynamic>? queryParameters, CancelToken? cancelToken}) async {
    final lang = (queryParameters?['lang'] ?? 'en').toString();
    langs.add(lang);
    final ar = lang == 'ar';
    return {
      'success': true,
      'data': [
        {'id': 1, 'name': ar ? 'قطر' : 'Qatar'},
        {'id': 2, 'name': ar ? 'مصر' : 'Egypt'},
        {'id': 3, 'name': ar ? 'البحرين' : 'Bahrain'},
      ],
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

/// Rebuilds a [MaterialApp] around [child] whenever [locale] changes — the same
/// thing `HouseianaApp` does when `LocaleCubit` emits, so the screen under test
/// keeps its State across the switch exactly like it does in the app.
class _LocaleHost extends StatelessWidget {
  const _LocaleHost({required this.locale, required this.child});

  final ValueListenable<Locale> locale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: locale,
      builder: (_, value, __) => MaterialApp(
        locale: value,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: child,
      ),
    );
  }
}

/// Minimal `LocaleAwareState` user, for asserting *when* the hook fires.
class _Probe extends StatefulWidget {
  const _Probe(this.onChanged);
  final VoidCallback onChanged;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> with LocaleAwareState<_Probe> {
  @override
  void onLocaleChanged() => widget.onChanged();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => sl.reset());

  testWidgets(
      'country list follows a language switch instead of staying Arabic',
      (tester) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'ar'});
    final prefs = await SharedPreferences.getInstance();
    final api = _CountryApi();
    await sl.reset();
    sl.registerSingleton<PropertyService>(
      PropertyService(api, LookupsCache(CacheService(prefs), prefs)),
    );

    // The delegate decodes the translations on a background isolate, which
    // pumpAndSettle can't drive — warm the language about to be rendered so the
    // delegate resolves from its (single-entry) static cache instead.
    await tester.runAsync(() => AppLocalizations.load(AppLocale.ar));

    final locale = ValueNotifier<Locale>(const Locale('ar'));
    addTearDown(locale.dispose);

    await tester.pumpWidget(
      _LocaleHost(locale: locale, child: CountryScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('مصر'), findsOneWidget);
    expect(api.langs, ['ar']);

    await tester.runAsync(() => AppLocalizations.load(AppLocale.en));

    // Switch to English the way the language screen does: persist first (the
    // lookup services read the pref), then emit the new locale.
    await prefs.setString('app_locale', 'en');
    locale.value = const Locale('en');
    await tester.pumpAndSettle();

    expect(api.langs, ['ar', 'en'], reason: 'the tab must re-query in English');
    expect(find.text('Egypt'), findsOneWidget);
    expect(find.text('مصر'), findsNothing);
  });

  testWidgets('the hook fires on a language change only', (tester) async {
    var calls = 0;
    final locale = ValueNotifier<Locale>(const Locale('en'));
    addTearDown(locale.dispose);

    await tester.runAsync(() => AppLocalizations.load(AppLocale.en));

    await tester.pumpWidget(
      _LocaleHost(locale: locale, child: _Probe(() => calls++)),
    );
    await tester.pumpAndSettle();
    expect(calls, 0, reason: 'the first build is initState territory');

    // An unrelated inherited-widget change must not trigger a re-fetch.
    await tester.binding.setSurfaceSize(const Size(500, 900));
    await tester.pumpAndSettle();
    addTearDown(() => tester.binding.setSurfaceSize(null));
    expect(calls, 0);

    await tester.runAsync(() => AppLocalizations.load(AppLocale.ar));
    locale.value = const Locale('ar');
    await tester.pumpAndSettle();
    expect(calls, 1);

    // Rebuilding with the same locale is not a change.
    locale.value = const Locale('ar');
    await tester.pumpAndSettle();
    expect(calls, 1);
  });

  test('the home list cache is bucketed per language', () {
    expect(
      HomeCache.listKey(null, 'en'),
      isNot(HomeCache.listKey(null, 'ar')),
    );
    // Prefix-wide invalidation (favourite toggle) must still clear both.
    expect(HomeCache.listKey(null, 'ar').startsWith(HomeCache.listPrefix), isTrue);
    expect(HomeCache.listKey(7, 'en').startsWith(HomeCache.listPrefix), isTrue);
  });
}
