import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

/// Cubit for managing app locale/language
class LocaleCubit extends Cubit<AppLocale> {
  static const String _localeKey = 'app_locale';
  final SharedPreferences _prefs;

  LocaleCubit(this._prefs) : super(_loadStoredLocale(_prefs));

  static AppLocale _loadStoredLocale(SharedPreferences prefs) {
    final storedCode = prefs.getString(_localeKey);
    if (storedCode != null) {
      return AppLocale.fromCode(storedCode);
    }
    return AppLocale.en;
  }

  /// Switch to a new locale
  Future<void> switchLocale(AppLocale locale) async {
    if (state == locale) return;

    await _prefs.setString(_localeKey, locale.code);
    emit(locale);
  }

  /// Toggle between English and Arabic
  Future<void> toggleLocale() async {
    final newLocale = state == AppLocale.en ? AppLocale.ar : AppLocale.en;
    await switchLocale(newLocale);
  }
}
