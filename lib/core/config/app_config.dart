// Environment configuration for the app.
// Use different environments for dev/staging/prod builds.

enum AppEnvironment {
  development,
  staging,
  production,
}

class AppConfig {
  AppConfig._();

  static AppEnvironment environment = AppEnvironment.staging;

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
}
