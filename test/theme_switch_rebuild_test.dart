import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/theme/dark_theme.dart';
import 'package:houseiana_mobile_app/core/theme/light_theme.dart';
import 'package:houseiana_mobile_app/core/theme/theme_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guards the one real risk of the mutable-palette design: a widget that is not
/// rebuilt on a theme switch keeps serving the previous theme's colors.
///
/// If someone reintroduces `const` on an app widget (or caches widget instances
/// across builds), the pop-back assertion below fails.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => AppColors.setDark(false));
  tearDown(() => AppColors.setDark(false));

  /// A screen that reads the palette in `build` — exactly what the real
  /// screens do.
  Widget probe(String label) => _Probe(label: label);

  Future<ThemeCubit> pumpApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final cubit = ThemeCubit(await SharedPreferences.getInstance());

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, mode) => MaterialApp(
            theme: lightTheme(),
            darkTheme: darkTheme(),
            themeMode: mode,
            themeAnimationDuration: Duration.zero,
            builder: (context, child) {
              AppColors.setDark(
                Theme.of(context).brightness == Brightness.dark,
              );
              return child ?? const SizedBox.shrink();
            },
            // Mirrors AppRoutes.onGenerateRoute: the page is produced by a
            // builder that runs on every rebuild. Returning one captured
            // instance instead is what made screens keep the old theme's
            // colors until something forced them to rebuild.
            onGenerateRoute: (settings) => MaterialPageRoute<void>(
              builder: (_) => probe(settings.name == '/b' ? 'b' : 'a'),
              settings: settings,
            ),
          ),
        ),
      ),
    );
    return cubit;
  }

  Color backgroundOf(WidgetTester tester, String label) {
    final box = tester.widget<ColoredBox>(
      find.byKey(ValueKey('probe-bg-$label')),
    );
    return box.color;
  }

  Color textColorOf(WidgetTester tester, String label) {
    return tester
        .widget<Text>(find.byKey(ValueKey('probe-text-$label')))
        .style!
        .color!;
  }

  testWidgets('switching to dark repaints the visible route', (tester) async {
    final cubit = await pumpApp(tester);

    expect(backgroundOf(tester, 'a'), AppColorsLight.cardBackground);
    expect(textColorOf(tester, 'a'), AppColorsLight.charcoal);

    await cubit.switchMode(ThemeMode.dark);
    await tester.pumpAndSettle();

    expect(backgroundOf(tester, 'a'), AppColorsDark.cardBackground);
    expect(textColorOf(tester, 'a'), AppColorsDark.charcoal);
  });

  testWidgets('a route covered during the switch is repainted too',
      (tester) async {
    final cubit = await pumpApp(tester);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));

    navigator.pushNamed('/b');
    await tester.pumpAndSettle();
    expect(backgroundOf(tester, 'b'), AppColorsLight.cardBackground);

    // Route 'a' is in the stack but not visible while we switch.
    await cubit.switchMode(ThemeMode.dark);
    await tester.pumpAndSettle();

    navigator.pop();
    await tester.pumpAndSettle();

    expect(backgroundOf(tester, 'a'), AppColorsDark.cardBackground);
    expect(textColorOf(tester, 'a'), AppColorsDark.charcoal);
  });

  testWidgets('AppRoutes builds a fresh page on every rebuild', (tester) async {
    // A route that hands back one captured widget is identity-stable, and
    // `Element.updateChild` skips an identical child — the screen would keep
    // the previous theme's colors. Guard the real route table, not a stand-in.
    await tester.pumpWidget(MaterialApp(home: const SizedBox.shrink()));
    final context = tester.element(find.byType(SizedBox));

    for (final name in [Routes.login, Routes.bottomNav, Routes.searchModal]) {
      final route = AppRoutes.onGenerateRoute(RouteSettings(name: name))
          as MaterialPageRoute;
      expect(
        identical(route.builder(context), route.builder(context)),
        isFalse,
        reason: '$name returns a captured instance; wrap it in `() =>`',
      );
    }
  });

  testWidgets('switching back to light restores the light palette',
      (tester) async {
    final cubit = await pumpApp(tester);

    await cubit.switchMode(ThemeMode.dark);
    await tester.pumpAndSettle();
    await cubit.switchMode(ThemeMode.light);
    await tester.pumpAndSettle();

    expect(backgroundOf(tester, 'a'), AppColorsLight.cardBackground);
    expect(textColorOf(tester, 'a'), AppColorsLight.charcoal);
  });
}

class _Probe extends StatelessWidget {
  final String label;

  _Probe({required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ColoredBox(
        key: ValueKey('probe-bg-$label'),
        color: AppColors.cardBackground,
        child: Text(
          label,
          key: ValueKey('probe-text-$label'),
          style: TextStyle(color: AppColors.charcoal),
        ),
      ),
    );
  }
}
