import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Supported locales
enum AppLocale {
  en('en', 'English', ''),
  ar('ar', 'العربية', '');

  final String code;
  final String name;
  final String flag;

  const AppLocale(this.code, this.name, this.flag);

  static AppLocale fromCode(String code) {
    return AppLocale.values.firstWhere(
      (locale) => locale.code == code,
      orElse: () => AppLocale.en,
    );
  }
}

/// Localizations delegate for Houseiana app.
class AppLocalizations {
  final AppLocale locale;
  final Map<String, dynamic> _strings;

  AppLocalizations._({
    required this.locale,
    required Map<String, dynamic> strings,
  }) : _strings = strings;

  static AppLocalizations? _cached;
  static AppLocale _currentLocale = AppLocale.en;

  /// Retrieves the [AppLocalizations] for the given [context].
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations._(locale: AppLocale.en, strings: const {});
  }

  static Future<AppLocalizations> load(AppLocale locale) async {
    if (_cached != null && _currentLocale == locale) {
      return _cached!;
    }

    try {
      final jsonString = await rootBundle.loadString(
        'lib/i18n/translations/${locale.code}.json',
      );
      final strings = json.decode(jsonString) as Map<String, dynamic>;
      _cached = AppLocalizations._(locale: locale, strings: strings);
      _currentLocale = locale;
      return _cached!;
    } catch (_) {
      if (locale != AppLocale.en) {
        return load(AppLocale.en);
      }
      return AppLocalizations._(locale: locale, strings: {});
    }
  }

  static AppLocale get currentLocale => _currentLocale;

  /// Resolves a dot-separated translation key (e.g. `auth.signIn`).
  /// Falls back to the key itself if not found.
  /// Supports {placeholder} substitution via [args].
  String tr(String key, {Map<String, Object?>? args}) {
    final keys = key.split('.');
    dynamic value = _strings;

    for (final segment in keys) {
      if (value is Map<String, dynamic>) {
        value = value[segment];
      } else {
        value = null;
        break;
      }
    }

    var result = value?.toString() ?? key;
    if (args != null) {
      args.forEach((k, v) {
        result = result.replaceAll('{$k}', v?.toString() ?? '');
      });
    }
    return result;
  }

  /// Legacy alias for [tr].
  String get(String key) => tr(key);

  // Convenience getters (kept for backwards compatibility)
  String get appName => tr('app.name');
  String get welcomeBack => tr('auth.welcomeBack');
  String get signIn => tr('auth.signIn');
  String get signUp => tr('auth.signUp');
  String get email => tr('auth.email');
  String get password => tr('auth.password');
  String get homeTitle => tr('home.title');
  String get search => tr('home.search');
  String get booking => tr('booking.title');
  String get trips => tr('trips.title');
  String get profile => tr('profile.title');
  String get messages => tr('messages.title');
  String get settings => tr('profile.accountSettings');
  String get logout => tr('profile.logout');
  String get loading => tr('common.loading');
  String get error => tr('common.error');
  String get retry => tr('common.retry');
  String get cancel => tr('common.cancel');
  String get save => tr('common.save');
  String get done => tr('common.done');
  String get confirm => tr('common.confirm');
  String get next => tr('common.next');
  String get previous => tr('common.previous');

  bool get isRtl => locale == AppLocale.ar;
  TextDirection get textDirection =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations.load(AppLocale.fromCode(locale.languageCode));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => true;
}

/// Convenience extension: `context.tr('auth.signIn')`.
extension AppLocalizationsContext on BuildContext {
  String tr(String key, {Map<String, Object?>? args}) =>
      AppLocalizations.of(this).tr(key, args: args);

  AppLocalizations get l10n => AppLocalizations.of(this);

  bool get isRtl => AppLocalizations.of(this).isRtl;
}
