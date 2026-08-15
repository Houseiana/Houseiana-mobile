import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the user's appearance choice and persists it.
///
/// Mirrors [LocaleCubit]: the stored value is read synchronously in the
/// constructor initializer, so the very first frame already paints in the right
/// theme — there is no async load and no flash of the wrong appearance.
///
/// [ThemeMode.system] needs no extra work: `MaterialApp` resolves it from the
/// platform brightness and rebuilds when the OS setting changes.
class ThemeCubit extends Cubit<ThemeMode> {
  static const String _themeKey = 'app_theme_mode';

  final SharedPreferences _prefs;

  ThemeCubit(this._prefs) : super(_loadStoredMode(_prefs));

  static ThemeMode _loadStoredMode(SharedPreferences prefs) {
    switch (prefs.getString(_themeKey)) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'light':
      default:
        // Light is the default for a fresh install: existing users keep the
        // appearance they already know until they opt into something else.
        return ThemeMode.light;
    }
  }

  Future<void> switchMode(ThemeMode mode) async {
    if (state == mode) return;

    await _prefs.setString(_themeKey, mode.name);
    emit(mode);
  }
}
