import 'package:flutter/widgets.dart';

/// Re-fetches **backend-localized** data when the app language changes.
///
/// Static copy goes through `context.tr(...)` and re-renders by itself on a
/// language switch. Data the *backend* localizes does not: lookup names
/// (countries, destinations, villages, booking statuses) and list payloads
/// returned under the `lang` header/query were fetched once in `initState` and
/// are still sitting in `State` in the previous language.
///
/// That is invisible on a route pushed fresh, but the bottom-nav tabs stay
/// mounted for the whole session (the shell's lazy `IndexedStack` keeps every
/// visited tab alive), so their `initState` runs exactly once. Switching the
/// language therefore left English chrome wrapped around Arabic data — e.g. the
/// Country tab reading "3 countries / Explore destinations" above قطر / مصر —
/// until the app was restarted.
///
/// `MaterialApp.locale` is driven by `LocaleCubit`, so a switch rebuilds the
/// `Localizations` scope and every mounted descendant — including the hidden
/// tabs — gets `didChangeDependencies`. That is the hook used here.
mixin LocaleAwareState<T extends StatefulWidget> on State<T> {
  String? _lastLanguageCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final code = Localizations.localeOf(context).languageCode;
    final previous = _lastLanguageCode;
    _lastLanguageCode = code;
    // The first resolution is the initial build, already covered by initState.
    if (previous != null && previous != code) onLocaleChanged();
  }

  /// Called after the app language changed (never on the initial build).
  /// Re-fetch anything the backend returns already localized.
  void onLocaleChanged();
}
