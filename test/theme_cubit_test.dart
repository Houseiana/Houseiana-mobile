import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:houseiana_mobile_app/core/theme/theme_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  group('ThemeCubit', () {
    test('defaults to light on a fresh install', () async {
      final cubit = ThemeCubit(await prefsWith({}));
      expect(cubit.state, ThemeMode.light);
    });

    test('restores the stored mode', () async {
      expect(
        ThemeCubit(await prefsWith({'app_theme_mode': 'dark'})).state,
        ThemeMode.dark,
      );
      expect(
        ThemeCubit(await prefsWith({'app_theme_mode': 'system'})).state,
        ThemeMode.system,
      );
      expect(
        ThemeCubit(await prefsWith({'app_theme_mode': 'light'})).state,
        ThemeMode.light,
      );
    });

    test('falls back to light on an unrecognised stored value', () async {
      final cubit = ThemeCubit(await prefsWith({'app_theme_mode': 'sepia'}));
      expect(cubit.state, ThemeMode.light);
    });

    test('switchMode persists and emits', () async {
      final prefs = await prefsWith({});
      final cubit = ThemeCubit(prefs);

      final emissions = expectLater(
        cubit.stream,
        emitsInOrder([ThemeMode.dark, ThemeMode.system]),
      );

      await cubit.switchMode(ThemeMode.dark);
      await cubit.switchMode(ThemeMode.system);
      await emissions;

      expect(prefs.getString('app_theme_mode'), 'system');
      // A cubit built from the same prefs comes back on the stored mode.
      expect(ThemeCubit(prefs).state, ThemeMode.system);

      await cubit.close();
    });

    test('switching to the current mode neither writes nor emits', () async {
      final prefs = await prefsWith({});
      final cubit = ThemeCubit(prefs);

      final emitted = <ThemeMode>[];
      final sub = cubit.stream.listen(emitted.add);

      await cubit.switchMode(ThemeMode.light); // already light

      expect(emitted, isEmpty);
      expect(prefs.getString('app_theme_mode'), isNull);

      await sub.cancel();
      await cubit.close();
    });
  });
}
