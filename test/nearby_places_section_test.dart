import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/models/nearby_place.dart';
import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/services/cache_service.dart';
import 'package:houseiana_mobile_app/core/services/lookups_cache.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:houseiana_mobile_app/shared/widgets/nearby/nearby_places_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serves `/api/Lookups/NearbyCategories` the way production does: the seven
/// ids in id order, localized by the `lang` QUERY param and NOT by the header.
class _LookupApi implements ApiConsumer {
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
        {'id': 1, 'name': ar ? 'قهوة' : 'coffee'},
        {'id': 2, 'name': ar ? 'فطور' : 'breakfast'},
        {'id': 3, 'name': ar ? 'تسوق' : 'shopping'},
        {'id': 4, 'name': ar ? 'هدايا' : 'gifts'},
        {'id': 5, 'name': ar ? 'عائلة' : 'family'},
        {'id': 6, 'name': ar ? 'ترفيه' : 'entertainment'},
        {'id': 7, 'name': ar ? 'أساسيات' : 'essentials'},
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
          {Map<String, dynamic>? body,
          Map<String, dynamic>? queryParameters}) =>
      throw UnimplementedError();

  @override
  Future<dynamic> patch(String path,
          {Map<String, dynamic>? body,
          Map<String, dynamic>? queryParameters}) =>
      throw UnimplementedError();

  @override
  Future<dynamic> delete(String path,
          {Map<String, dynamic>? body,
          Map<String, dynamic>? queryParameters}) =>
      throw UnimplementedError();
}

/// Rebuilds a [MaterialApp] around [child] whenever [locale] changes, the way
/// `HouseianaApp` does on a `LocaleCubit` emission — so the section keeps its
/// State across the switch exactly like it does in the app.
class _LocaleHost extends StatelessWidget {
  const _LocaleHost({required this.locale, required this.builder});

  final ValueListenable<Locale> locale;
  final WidgetBuilder builder;

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
        home: Scaffold(
          body: SingleChildScrollView(child: Builder(builder: builder)),
        ),
      ),
    );
  }
}

// The three staging rows on property 55ea8a85… — the listing in the design.
List<NearbyPlace> _propertyPlaces() => NearbyPlace.listFrom([
      {
        'id': 'p1',
        'propertyId': 'stay-1',
        'categoryId': 1,
        'name': ' Starbucks',
        'nameAR': 'ستاربكس',
        'description': 'Starbucks coffee ',
        'descriptionAR': 'ستاربكس كافيه',
        'rating': 5,
        'reviewCount': 899,
        'distanceMeters': 1000,
        'walkMinutes': 15,
        'driveMinutes': 5,
        'googleMapsUrl': 'https://maps.app.goo.gl/ovtcLTx1K7qqQ9966',
        'priceLevel': 'EXPENSIVE',
        'displayOrder': 1,
        'timeOfDay': 'MORNING',
        'image': '',
      },
      {
        'id': 'p2',
        'propertyId': 'stay-1',
        'categoryId': 2,
        'name': 'gad',
        'nameAR': 'جاد',
        'description': 'gad restaurent',
        'descriptionAR': 'مطعم جاد',
        'rating': 4,
        'reviewCount': 300,
        'distanceMeters': 500,
        'walkMinutes': 10,
        'driveMinutes': 4,
        'googleMapsUrl': 'https://maps.app.goo.gl/ovtcLTx1K7qqQ9966',
        'priceLevel': 'CHEAP',
        'displayOrder': 2,
        'timeOfDay': 'LATE_MORNING',
        'image': '',
      },
      {
        'id': 'p3',
        'propertyId': 'stay-1',
        'categoryId': 3,
        'name': 'mall of egypt',
        'nameAR': 'مول مصر',
        'description': 'mall of egypttttt',
        'descriptionAR': 'مول مصر',
        'rating': 5,
        'reviewCount': 1000,
        'distanceMeters': 1500,
        'walkMinutes': 20,
        'driveMinutes': 8,
        'googleMapsUrl': 'https://maps.app.goo.gl/ovtcLTx1K7qqQ9966',
        'priceLevel': 'EXPENSIVE',
        'displayOrder': 3,
        'timeOfDay': 'AFTERNOON',
        'image': '',
      },
    ]);

/// One hotel row, in whichever language the backend would have localized it to.
List<NearbyPlace> _hotelPlaces({required bool arabic}) =>
    NearbyPlace.listFrom([
      {
        'id': 'h1',
        'hotelId': 'hotel-1',
        'categoryId': 1,
        'categoryName': arabic ? 'قهوة' : 'coffee',
        'name': arabic ? 'كوستا كافيه' : 'costa cafe',
        'description': arabic ? 'كوستا كافيه' : 'costa coffee',
        'rating': 4,
        'reviewCount': 150,
        'distanceMeters': 800,
        'walkMinutes': 10,
        'driveMinutes': 4,
        'googleMapsUrl': 'test',
        'priceLevel': arabic ? 'رخيص' : 'Cheap',
        'displayOrder': 1,
        'timeOfDay': arabic ? 'صباحاً' : 'Morning',
      },
    ]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _LookupApi api;

  Future<void> registerServices(String appLocale) async {
    SharedPreferences.setMockInitialValues({'app_locale': appLocale});
    final prefs = await SharedPreferences.getInstance();
    api = _LookupApi();
    await sl.reset();
    sl.registerSingleton<PropertyService>(
      PropertyService(api, LookupsCache(CacheService(prefs), prefs)),
    );
  }

  tearDown(() => sl.reset());

  testWidgets('renders nothing at all when the stay has no nearby places',
      (tester) async {
    await registerServices('en');
    await tester.runAsync(() => AppLocalizations.load(AppLocale.en));

    final locale = ValueNotifier<Locale>(const Locale('en'));
    addTearDown(locale.dispose);

    await tester.pumpWidget(_LocaleHost(
      locale: locale,
      builder: (_) => NearbyPlacesSection(
        places: const [],
        loadCategory: (_) async => const [],
      ),
    ));
    await tester.pumpAndSettle();

    // Not an empty state, not a heading — the block is simply absent, because
    // that is the case for the overwhelming majority of live stays.
    expect(find.text('Your day here'), findsNothing);
    // findsWidgets on SizedBox would pass even if the whole block rendered —
    // the chrome is full of them. Zero height is the actual claim.
    expect(tester.getSize(find.byType(NearbyPlacesSection)), Size.zero);
  });

  testWidgets('shows chips only for categories that actually have places',
      (tester) async {
    await registerServices('en');
    await tester.runAsync(() => AppLocalizations.load(AppLocale.en));

    final locale = ValueNotifier<Locale>(const Locale('en'));
    addTearDown(locale.dispose);

    await tester.pumpWidget(_LocaleHost(
      locale: locale,
      builder: (_) => NearbyPlacesSection(
        places: _propertyPlaces(),
        loadCategory: (id) async =>
            _propertyPlaces().where((p) => p.categoryId == id).toList(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Your day here'), findsOneWidget);
    // The three categories the payload has.
    expect(find.text('Start your day slow ☕'), findsOneWidget);
    expect(find.text('Breakfast nearby 🥐'), findsOneWidget);
    expect(find.text('Shop with ease 🛍️'), findsOneWidget);
    // The four it does not — a chip leading to "nothing here" is worse than
    // no chip.
    expect(find.text('Little treats and gifts 🎁'), findsNothing);
    expect(find.text('For kids and family 🧸'), findsNothing);
    expect(find.text('Moments and memories 🎮'), findsNothing);
    expect(find.text('Everyday essentials 🧴'), findsNothing);
  });

  testWidgets('labels chips from our copy, never the lookup name',
      (tester) async {
    await registerServices('ar');
    await tester.runAsync(() => AppLocalizations.load(AppLocale.ar));

    final locale = ValueNotifier<Locale>(const Locale('ar'));
    addTearDown(locale.dispose);

    await tester.pumpWidget(_LocaleHost(
      locale: locale,
      builder: (_) => NearbyPlacesSection(
        places: _propertyPlaces(),
        loadCategory: (id) async =>
            _propertyPlaces().where((p) => p.categoryId == id).toList(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('يومك هنا'), findsOneWidget);
    expect(find.text('ابدأ يومك بهدوء ☕'), findsOneWidget);
    // The lookup's own name for the same category is a bare word and must not
    // be what the chip says.
    expect(find.text('قهوة'), findsNothing);
    // And the lookup is asked in Arabic through the QUERY param, because this
    // controller ignores the lang header.
    expect(api.langs, ['ar']);
  });

  testWidgets('the day plan runs through the day and names each category',
      (tester) async {
    await registerServices('ar');
    await tester.runAsync(() => AppLocalizations.load(AppLocale.ar));

    final locale = ValueNotifier<Locale>(const Locale('ar'));
    addTearDown(locale.dispose);

    await tester.pumpWidget(_LocaleHost(
      locale: locale,
      builder: (_) => NearbyPlacesSection(
        places: _propertyPlaces(),
        loadCategory: (id) async =>
            _propertyPlaces().where((p) => p.categoryId == id).toList(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('اقتراح هاوسيانا ليومك'), findsOneWidget);
    expect(find.text('ابدأ بقهوة'), findsOneWidget);
    expect(find.text('إفطار خفيف'), findsOneWidget);
    expect(find.text('تسوّق'), findsOneWidget);

    // Morning first, afternoon last — the payload order is irrelevant.
    final captions = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .toList();
    expect(captions.indexOf('ابدأ بقهوة'), lessThan(captions.indexOf('تسوّق')));
  });

  testWidgets('Arabic minute counts agree with their noun', (tester) async {
    await registerServices('ar');
    await tester.runAsync(() => AppLocalizations.load(AppLocale.ar));

    final locale = ValueNotifier<Locale>(const Locale('ar'));
    addTearDown(locale.dispose);

    await tester.pumpWidget(_LocaleHost(
      locale: locale,
      builder: (_) => NearbyPlacesSection(
        places: _propertyPlaces(),
        loadCategory: (id) async =>
            _propertyPlaces().where((p) => p.categoryId == id).toList(),
      ),
    ));
    await tester.pumpAndSettle();

    // 15 takes the singular (11+ band), 5 takes the broken plural (3-10).
    expect(find.text('15 دقيقة مشي'), findsWidgets);
    expect(find.text('5 دقائق بالسيارة'), findsWidgets);
    // The one-size-fits-all string would have produced this instead.
    expect(find.text('15 دقائق مشي'), findsNothing);
  });

  testWidgets('a chip tap fetches that category and swaps the list',
      (tester) async {
    await registerServices('en');
    await tester.runAsync(() => AppLocalizations.load(AppLocale.en));

    final requested = <int>[];
    final locale = ValueNotifier<Locale>(const Locale('en'));
    addTearDown(locale.dispose);

    await tester.pumpWidget(_LocaleHost(
      locale: locale,
      builder: (_) => NearbyPlacesSection(
        places: _propertyPlaces(),
        loadCategory: (id) async {
          requested.add(id);
          return _propertyPlaces().where((p) => p.categoryId == id).toList();
        },
      ),
    ));
    await tester.pumpAndSettle();

    // The first category is fetched with the page, so the default list is live
    // rather than only seeded.
    expect(requested, [1]);
    // The descriptions only ever render on the place cards, so they say which
    // category the LIST is showing — the names also appear in the day plan.
    expect(find.text('Starbucks coffee'), findsOneWidget);
    expect(find.text('mall of egypttttt'), findsNothing);

    await tester.tap(find.text('Shop with ease 🛍️'));
    await tester.pumpAndSettle();

    expect(requested, [1, 3]);
    expect(find.text('mall of egypttttt'), findsOneWidget);
    expect(find.text('Starbucks coffee'), findsNothing);

    // Going back costs nothing — the answer is kept for the life of the screen.
    await tester.tap(find.text('Start your day slow ☕'));
    await tester.pumpAndSettle();
    expect(requested, [1, 3]);
  });

  testWidgets('a failed category fetch keeps the seeded rows on screen',
      (tester) async {
    await registerServices('en');
    await tester.runAsync(() => AppLocalizations.load(AppLocale.en));

    final locale = ValueNotifier<Locale>(const Locale('en'));
    addTearDown(locale.dispose);

    await tester.pumpWidget(_LocaleHost(
      locale: locale,
      builder: (_) => NearbyPlacesSection(
        places: _propertyPlaces(),
        loadCategory: (_) async => throw Exception('502'),
      ),
    ));
    await tester.pumpAndSettle();

    // The details payload already told us the truth; an error banner over good
    // data would help nobody.
    expect(find.text('Starbucks coffee'), findsOneWidget);
  });

  testWidgets('a hotel row prints the already-localized price level verbatim',
      (tester) async {
    await registerServices('ar');
    await tester.runAsync(() => AppLocalizations.load(AppLocale.ar));

    final locale = ValueNotifier<Locale>(const Locale('ar'));
    addTearDown(locale.dispose);

    await tester.pumpWidget(_LocaleHost(
      locale: locale,
      builder: (_) => NearbyPlacesSection(
        places: _hotelPlaces(arabic: true),
        loadCategory: (_) async => _hotelPlaces(arabic: true),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('كوستا كافيه'), findsWidgets);
    // "رخيص" cannot be parsed into NearbyPriceLevel.cheap, so it is shown as
    // it arrived rather than dropped.
    expect(find.text('رخيص'), findsOneWidget);
    // "test" is not a URL — no map affordance.
    expect(find.text('افتح على الخريطة'), findsNothing);
  });

  testWidgets('a real maps link gets an affordance', (tester) async {
    await registerServices('en');
    await tester.runAsync(() => AppLocalizations.load(AppLocale.en));

    final locale = ValueNotifier<Locale>(const Locale('en'));
    addTearDown(locale.dispose);

    await tester.pumpWidget(_LocaleHost(
      locale: locale,
      builder: (_) => NearbyPlacesSection(
        places: _propertyPlaces(),
        loadCategory: (id) async =>
            _propertyPlaces().where((p) => p.categoryId == id).toList(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Open in Maps'), findsOneWidget);
  });

  testWidgets('a hotel language switch re-seeds and re-asks the endpoint',
      (tester) async {
    await registerServices('en');
    await tester.runAsync(() => AppLocalizations.load(AppLocale.en));

    var arabic = false;
    var fetches = 0;
    final locale = ValueNotifier<Locale>(const Locale('en'));
    addTearDown(locale.dispose);

    await tester.pumpWidget(_LocaleHost(
      locale: locale,
      builder: (_) => NearbyPlacesSection(
        // The host screen re-fetches the hotel on a language switch, so the
        // section is handed a freshly localized list.
        places: _hotelPlaces(arabic: arabic),
        loadCategory: (_) async {
          fetches++;
          return _hotelPlaces(arabic: arabic);
        },
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('costa cafe'), findsWidgets);
    expect(fetches, 1);

    arabic = true;
    await tester.runAsync(() => AppLocalizations.load(AppLocale.ar));
    locale.value = const Locale('ar');
    await tester.pumpAndSettle();

    expect(find.text('كوستا كافيه'), findsWidgets);
    expect(find.text('costa cafe'), findsNothing);
    // The category cached in English is dropped, not reused.
    expect(fetches, 2);
  });

  testWidgets('a property language switch does NOT re-ask the endpoint',
      (tester) async {
    await registerServices('en');
    await tester.runAsync(() => AppLocalizations.load(AppLocale.en));

    var fetches = 0;
    final locale = ValueNotifier<Locale>(const Locale('en'));
    addTearDown(locale.dispose);

    await tester.pumpWidget(_LocaleHost(
      locale: locale,
      builder: (_) => NearbyPlacesSection(
        places: _propertyPlaces(),
        loadCategory: (id) async {
          fetches++;
          return _propertyPlaces().where((p) => p.categoryId == id).toList();
        },
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Starbucks coffee'), findsOneWidget);
    expect(fetches, 1);

    await tester.runAsync(() => AppLocalizations.load(AppLocale.ar));
    locale.value = const Locale('ar');
    await tester.pumpAndSettle();

    // Property rows carry both languages at once, so the switch is a pure
    // rebuild — re-fetching would burn a request per category for nothing.
    expect(find.text('ستاربكس كافيه'), findsOneWidget);
    expect(fetches, 1);
  });
testWidgets('survives a phone-sized viewport with worst-case content',
      (tester) async {
    await registerServices('ar');
    await tester.runAsync(() => AppLocalizations.load(AppLocale.ar));

    // A real handset, not the 800x600 test surface — the chip strip, the day
    // plan and the pill wrap all have to fit something this narrow.
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Worst case: every category filled, names and descriptions far longer
    // than anything the admin UI is likely to accept, and a place with nothing
    // but a name.
    final long = 'مركز تجاري ضخم جداً يضم عشرات المحلات والمطاعم والمقاهي '
        'ودور السينما ومناطق ألعاب للأطفال وكل ما تحتاجه العائلة';
    final places = NearbyPlace.listFrom([
      for (var id = 1; id <= 7; id++)
        {
          'id': 'x$id',
          'propertyId': 'stay-1',
          'categoryId': id,
          'name': long,
          'nameAR': long,
          'description': long * 3,
          'descriptionAR': long * 3,
          'rating': 4.5,
          'reviewCount': 12345,
          'distanceMeters': 12500,
          'walkMinutes': 120,
          'driveMinutes': 45,
          'googleMapsUrl': 'https://maps.app.goo.gl/x',
          'priceLevel': 'MODERATELY_PRICED',
          'displayOrder': id,
          'timeOfDay': const ['MORNING', 'LATE_MORNING', 'AFTERNOON', 'EVENING'][id % 4],
          'image': '',
        },
      {
        'id': 'bare',
        'propertyId': 'stay-1',
        'categoryId': 1,
        'name': 'X',
        'nameAR': 'س',
        'displayOrder': 99,
      },
    ]);

    final locale = ValueNotifier<Locale>(const Locale('ar'));
    addTearDown(locale.dispose);

    await tester.pumpWidget(_LocaleHost(
      locale: locale,
      builder: (_) => NearbyPlacesSection(
        places: places,
        loadCategory: (id) async =>
            places.where((p) => p.categoryId == id).toList(),
      ),
    ));
    await tester.pumpAndSettle();

    // No RenderFlex overflow, no unbounded-constraint assert — pumpAndSettle
    // would have surfaced either as a test failure.
    expect(tester.takeException(), isNull);
    expect(find.text('يومك هنا'), findsOneWidget);
    // The place with no description or travel times still renders.
    expect(find.text('س'), findsWidgets);
  });
  testWidgets('the fetched rows really replace the seeded ones',
      (tester) async {
    await registerServices('en');
    await tester.runAsync(() => AppLocalizations.load(AppLocale.en));

    final locale = ValueNotifier<Locale>(const Locale('en'));
    addTearDown(locale.dispose);

    await tester.pumpWidget(_LocaleHost(
      locale: locale,
      builder: (_) => NearbyPlacesSection(
        places: _propertyPlaces(),
        // The endpoint is the authority — it can return a corrected or longer
        // list than the details payload embedded. Every other test here hands
        // back rows identical to the seed, so none of them would notice if the
        // write at `_byCategory[categoryId] = places` were deleted.
        loadCategory: (id) async => NearbyPlace.listFrom([
          {
            'id': 'fresh-$id',
            'propertyId': 'stay-1',
            'categoryId': id,
            'name': 'Fresh from the endpoint',
            'description': 'Only the endpoint knows about this one',
            'walkMinutes': 3,
          },
        ]),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Fresh from the endpoint'), findsOneWidget);
    expect(find.text('Starbucks coffee'), findsNothing);
  });

  testWidgets('a category the lookup does not list still renders',
      (tester) async {
    await registerServices('en');
    await tester.runAsync(() => AppLocalizations.load(AppLocale.en));

    final locale = ValueNotifier<Locale>(const Locale('en'));
    addTearDown(locale.dispose);

    // Category 8 does not exist in the lookup today. The 24h lookup cache means
    // a guest can hold a stale copy for a day after the backend adds one, so
    // the lookup must ORDER the chips, never decide which exist — otherwise the
    // block would paint and then vanish, leaving its two dividers stacked.
    final places = NearbyPlace.listFrom([
      {
        'id': 'n1',
        'propertyId': 'stay-1',
        'categoryId': 8,
        'name': 'Something new',
        'description': 'A category the lookup has not caught up with',
        'walkMinutes': 5,
      },
    ]);

    await tester.pumpWidget(_LocaleHost(
      locale: locale,
      builder: (_) => NearbyPlacesSection(
        places: places,
        loadCategory: (_) async => places,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Your day here'), findsOneWidget);
    expect(find.text('Something new'), findsOneWidget);
    // No copy for id 8, and the lookup has no name for it either, so the chip
    // falls back to the generic label rather than showing a raw key.
    expect(find.text('Nearby'), findsOneWidget);
    expect(find.text('nearby.category.8'), findsNothing);
  });

  testWidgets('a single place shows no "suggestion for your day" chain',
      (tester) async {
    await registerServices('en');
    await tester.runAsync(() => AppLocalizations.load(AppLocale.en));

    final locale = ValueNotifier<Locale>(const Locale('en'));
    addTearDown(locale.dispose);

    await tester.pumpWidget(_LocaleHost(
      locale: locale,
      builder: (_) => NearbyPlacesSection(
        places: _hotelPlaces(arabic: false),
        loadCategory: (_) async => _hotelPlaces(arabic: false),
      ),
    ));
    await tester.pumpAndSettle();

    // A "day plan" of one card is not a plan. The place still shows below.
    expect(find.text("Houseiana's suggestion for your day"), findsNothing);
    expect(find.text('Your day here'), findsOneWidget);
    expect(find.text('costa coffee'), findsOneWidget);
  });

  testWidgets('distances read in metres under a km and kilometres above it',
      (tester) async {
    await registerServices('en');
    await tester.runAsync(() => AppLocalizations.load(AppLocale.en));

    final locale = ValueNotifier<Locale>(const Locale('en'));
    addTearDown(locale.dispose);

    final places = NearbyPlace.listFrom([
      for (final m in [350, 1000, 1500])
        {
          'id': 'd$m',
          'propertyId': 'stay-1',
          'categoryId': 1,
          'name': 'Place $m',
          'distanceMeters': m,
          'displayOrder': m,
        },
    ]);

    await tester.pumpWidget(_LocaleHost(
      locale: locale,
      builder: (_) => NearbyPlacesSection(
        places: places,
        loadCategory: (_) async => places,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('350 m away'), findsOneWidget);
    // Exactly 1000 crosses into kilometres, and a whole one drops the ".0".
    expect(find.text('1 km away'), findsOneWidget);
    expect(find.text('1.5 km away'), findsOneWidget);
  });

  testWidgets('a response from before a language switch is discarded',
      (tester) async {
    await registerServices('en');
    await tester.runAsync(() => AppLocalizations.load(AppLocale.en));

    var arabic = false;
    final gate = Completer<void>();
    final locale = ValueNotifier<Locale>(const Locale('en'));
    addTearDown(locale.dispose);

    await tester.pumpWidget(_LocaleHost(
      locale: locale,
      builder: (_) => NearbyPlacesSection(
        places: _hotelPlaces(arabic: arabic),
        loadCategory: (_) async {
          // The first request hangs until we release it — long enough for the
          // guest to switch language underneath it.
          if (!gate.isCompleted) {
            final wasArabic = arabic;
            await gate.future;
            return _hotelPlaces(arabic: wasArabic);
          }
          return _hotelPlaces(arabic: arabic);
        },
      ),
    ));
    await tester.pumpAndSettle();

    arabic = true;
    await tester.runAsync(() => AppLocalizations.load(AppLocale.ar));
    locale.value = const Locale('ar');
    await tester.pumpAndSettle();

    // The stale English response lands only now, after the re-seed.
    gate.complete();
    await tester.pumpAndSettle();

    // Without the generation guard this would write English rows into a
    // freshly Arabic list — one chip in English, the rest Arabic.
    expect(find.text('costa cafe'), findsNothing);
    expect(find.text('كوستا كافيه'), findsWidgets);
  });
}
