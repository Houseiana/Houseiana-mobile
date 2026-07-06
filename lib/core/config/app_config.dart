// Environment configuration for the app.
// Use different environments for dev/staging/prod builds.

enum AppEnvironment {
  development,
  staging,
  production,
}

class AppConfig {
  AppConfig._();

  static AppEnvironment environment = AppEnvironment.production;

  // ── Backend API ──────────────────────────────────────────────────────────────

  /// Backend API base URL — changes per environment.
  /// For production, this should be your own backend proxy that forwards
  /// authenticated requests to Clerk's backend API.
  static String get backendApiUrl {
    switch (environment) {
      case AppEnvironment.development:
        return 'http://10.0.2.2:3000/api'; // Android emulator localhost
      case AppEnvironment.staging:
        return 'https://houseiana-api.jollyisland-881a1746.eastus.azurecontainerapps.io';
      case AppEnvironment.production:
        return 'https://houseiana-api-prod.jollyisland-881a1746.eastus.azurecontainerapps.io';
        // return 'https://houseiana-user-backend-production.up.railway.app';
    }
  }

  // ── Web app (Next.js) ──────────────────────────────────────────────────────

  /// Deployed Houseiana web app. Account privacy settings and GDPR data
  /// requests are served by the web app's Next.js API routes, which hold the
  /// Clerk secret key server-side and store the data in the Clerk user's
  /// publicMetadata. The mobile app calls them with the same Clerk session
  /// JWT it already uses for the .NET backend.
  /// Note: `houseiana.com` (no www) 307-redirects — use the www host directly.
  static const String webAppUrl = 'https://www.houseiana.com';

  // ── Clerk Frontend API ─────────────────────────────────────────────────────

  /// Clerk Frontend API — used only for unauthenticated sign-in/sign-up flows.
  /// This is safe to embed in the app because it only handles public operations.
  static const String clerkFrontendApiUrl = 'https://clerk.houseiana.com';

  /// Hardcoded Clerk Frontend API version — pins the JS version for stability.
  static const String clerkJsVersion = '5.35.0';

  // ── Clerk Backend API (via proxy) ──────────────────────────────────────────

  /// If you must call Clerk Backend API directly from the mobile app (not recommended),
  /// all requests MUST be proxied through your own backend to protect the secret key.
  /// Set to empty string to enforce proxy usage.
  static const String clerkBackendProxyUrl = '';

  // ── Feature Flags ───────────────────────────────────────────────────────────

  /// Enable detailed debug logging. Set to false in production.
  static bool get enableDebugLogging {
    return environment == AppEnvironment.development;
  }

  // ── Google OAuth ────────────────────────────────────────────────────────────

  /// Google OAuth Client ID (from Google Cloud Console).
  /// Set via --dart-define=GOOGLE_CLIENT_ID=your_client_id at build time.
  static String get googleClientId {
    const defaultClientId = String.fromEnvironment(
      'GOOGLE_CLIENT_ID',
      defaultValue: '',
    );
    return defaultClientId;
  }

  /// Google OAuth Server Client ID (for token exchange on backend).
  /// Set via --dart-define=GOOGLE_SERVER_CLIENT_ID=your_server_client_id.
  static String get googleServerClientId {
    const defaultServerId = String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
      defaultValue: '',
    );
    return defaultServerId;
  }

  /// Whether Google Sign-In is configured (both IDs must be set).
  static bool get isGoogleSignInConfigured {
    return googleClientId.isNotEmpty && googleServerClientId.isNotEmpty;
  }

  // ── Google Maps / Places ─────────────────────────────────────────────────────

  /// Google Maps API key used by the Places Autocomplete/Details REST APIs that
  /// power the address search in the listing-location step. Defaults to the same
  /// key embedded in the native Android manifest / iOS AppDelegate (Maps SDK),
  /// which is also enabled for the Places web service. Override at build time
  /// with --dart-define=GOOGLE_MAPS_API_KEY=your_key.
  static String get googleMapsApiKey {
    const fromEnv = String.fromEnvironment(
      'GOOGLE_MAPS_API_KEY',
      defaultValue: '',
    );
    return fromEnv.isNotEmpty
        ? fromEnv
        : 'AIzaSyB-j9eljyNW0HUccE15yxhgt70aiHNuC-k';
  }

  // ── PayPal ─────────────────────────────────────────────────────────────────

  /// PayPal Client ID (for PayPal checkout).
  /// Set via --dart-define=PAYPAL_CLIENT_ID=your_client_id at build time.
  static String get paypalClientId {
    const defaultClientId = String.fromEnvironment(
      'PAYPAL_CLIENT_ID',
      defaultValue: '',
    );
    return defaultClientId;
  }

  /// Whether PayPal is configured.
  static bool get isPayPalConfigured {
    return paypalClientId.isNotEmpty;
  }

  // ── App Store / Google Play (force-update) ───────────────────────────────────

  /// Apple App Store numeric ID for the Houseiana iOS app
  /// (bundle `com.houseianaapp.users`). Verified via Apple's iTunes lookup API.
  static const String iosAppStoreId = '6770710644';

  /// Android application id for the Houseiana app on Google Play.
  static const String androidPackageId = 'com.houseiana.app';

  /// App Store listing (universal link) — opens the App Store app on-device
  /// and falls back to Safari elsewhere.
  static String get appStoreUrl =>
      'https://apps.apple.com/app/id$iosAppStoreId';

  /// App Store deep link — opens the native App Store app directly.
  /// Requires `itms-apps` in the iOS `LSApplicationQueriesSchemes`.
  static String get appStoreDeepLink =>
      'itms-apps://apps.apple.com/app/id$iosAppStoreId';

  /// Google Play listing — opens the Play Store app on-device or a browser.
  static String get playStoreUrl =>
      'https://play.google.com/store/apps/details?id=$androidPackageId';

  /// Google Play deep link — opens the native Play Store app directly.
  /// Requires the `market` scheme in the Android manifest `<queries>`.
  static String get playStoreDeepLink =>
      'market://details?id=$androidPackageId';
}
