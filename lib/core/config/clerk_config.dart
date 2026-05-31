class ClerkConfig {
  ClerkConfig._();

  // ═══════════════════════════════════════════════════════════════════════════
  // SECURITY NOTES
  //
  // 1. Publishable key (pk_live_/pk_test_) is safe in client code. Override at
  //    build time with: flutter build --dart-define=CLERK_PUBLISHABLE_KEY=pk_xxx
  //
  // 2. Secret key (sk_live_/sk_test_) MUST NEVER be embedded in the mobile app.
  //    Anyone can extract it from the APK. All operations requiring sk_* must
  //    be proxied through the Houseiana .NET backend, which holds the secret
  //    server-side. clerk_service.dart still references getBackendSecretKey()
  //    in places — those Clerk Backend API calls should be migrated to the
  //    .NET backend. Until then, those calls will fail (which is the safe
  //    failure mode — they were already failing silently before this fix).
  // ═══════════════════════════════════════════════════════════════════════════

  /// Clerk Publishable Key (production by default).
  /// Override at build time:
  ///   flutter build --dart-define=CLERK_PUBLISHABLE_KEY=pk_test_xxx
  static const String publishableKey = String.fromEnvironment(
    'CLERK_PUBLISHABLE_KEY',
    defaultValue: 'pk_live_Y2xlcmsuaG91c2VpYW5hLmNvbSQ',
  );

  /// Clerk Secret Key. Empty by default — must come from a build flag if any
  /// legacy Clerk Backend API call needs it. Do NOT commit a real value here.
  static const String secretKey = String.fromEnvironment(
    'CLERK_SECRET_KEY',
    defaultValue: '',
  );

  static String getBackendSecretKey() => secretKey;
  static bool get hasBackendSecretKey => secretKey.isNotEmpty;

  /// Clerk Frontend API Base URL (production instance).
  static const String frontendApiUrl = 'https://clerk.houseiana.com';

  /// Clerk Backend API Base URL. Only used by legacy code paths that should
  /// be moved to the .NET backend.
  static const String backendApiUrl = 'https://api.clerk.com/v1';
}
