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

  // ⚠️ TEMPORARY: defaults below point to the TEST Clerk instance
  // (clerk.cafkejr.xyz) so a plain "Run" uses test. Before any production
  // build, revert these defaults to the prod values shown in comments, or
  // pass the prod values via --dart-define.
  //   PROD publishableKey:  pk_live_Y2xlcmsuaG91c2VpYW5hLmNvbSQ
  //   PROD frontendApiUrl:  https://clerk.houseiana.com

  /// Clerk Publishable Key (TEST instance by default — see warning above).
  /// Override at build time:
  ///   flutter build --dart-define=CLERK_PUBLISHABLE_KEY=pk_live_xxx
  static const String publishableKey = String.fromEnvironment(
    'CLERK_PUBLISHABLE_KEY',
    defaultValue: 'pk_live_Y2xlcmsuY2Fma2Vqci54eXok',
  );

  /// Clerk Secret Key. Empty by default — must come from a build flag if any
  /// legacy Clerk Backend API call needs it. Do NOT commit a real value here.
  static const String secretKey = String.fromEnvironment(
    'sk_live_1v2twd9j6yO93Ial7eUUs30rg9A3eMU3v4KCZIdHXn',
    // 'sk_live_gia87Rsr3iMVlMAmVlbHVIW79TTQzrEbjULFRfHQsJ',
    defaultValue: '',
  );

  static String getBackendSecretKey() => secretKey;
  static bool get hasBackendSecretKey => secretKey.isNotEmpty;

  /// Clerk Frontend API Base URL (TEST instance by default — see warning above).
  /// Must match the instance of [publishableKey]. Override at build time:
  ///   flutter run --dart-define=CLERK_FRONTEND_API_URL=https://clerk.houseiana.com
  static const String frontendApiUrl = String.fromEnvironment(
    'CLERK_FRONTEND_API_URL',
    defaultValue: 'https://clerk.cafkejr.xyz',
  );

  /// Clerk Backend API Base URL. Only used by legacy code paths that should
  /// be moved to the .NET backend.
  static const String backendApiUrl = 'https://api.clerk.com/v1';
}


//class ClerkConfig {
//   ClerkConfig._();
//
//   // ═══════════════════════════════════════════════════════════════════════════
//   // SECURITY NOTES
//   //
//   // 1. Publishable key (pk_live_/pk_test_) is safe in client code. Override at
//   //    build time with: flutter build --dart-define=CLERK_PUBLISHABLE_KEY=pk_xxx
//   //
//   // 2. Secret key (sk_live_/sk_test_) MUST NEVER be embedded in the mobile app.
//   //    Anyone can extract it from the APK. All operations requiring sk_* must
//   //    be proxied through the Houseiana .NET backend, which holds the secret
//   //    server-side. clerk_service.dart still references getBackendSecretKey()
//   //    in places — those Clerk Backend API calls should be migrated to the
//   //    .NET backend. Until then, those calls will fail (which is the safe
//   //    failure mode — they were already failing silently before this fix).
//   // ═══════════════════════════════════════════════════════════════════════════
//
//   /// Clerk Publishable Key (production by default).
//   /// Override at build time:
//   ///   flutter build --dart-define=CLERK_PUBLISHABLE_KEY=pk_test_xxx
//   static const String publishableKey = String.fromEnvironment(
//     'CLERK_PUBLISHABLE_KEY',
//     defaultValue: 'pk_live_Y2xlcmsuaG91c2VpYW5hLmNvbSQ',
//   );
//
//   /// Clerk Secret Key. Empty by default — must come from a build flag if any
//   /// legacy Clerk Backend API call needs it. Do NOT commit a real value here.
//   static const String secretKey = String.fromEnvironment(
//     'CLERK_SECRET_KEY',
//     defaultValue: '',
//   );
//   static String getBackendSecretKey() => secretKey;
//   static bool get hasBackendSecretKey => secretKey.isNotEmpty;
//
//   /// Clerk Frontend API Base URL (production instance).
//   static const String frontendApiUrl = 'https://clerk.houseiana.com';
//
//   /// Clerk Backend API Base URL. Only used by legacy code paths that should
//   /// be moved to the .NET backend.
//   static const String backendApiUrl = 'https://api.clerk.com/v1';
// }