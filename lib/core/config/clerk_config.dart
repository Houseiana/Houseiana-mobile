class ClerkConfig {
  ClerkConfig._();

  // ═══════════════════════════════════════════════════════════════════════════
  // ⚠️  SECURITY: API keys MUST be loaded from environment variables in production.
  //    Never commit real keys to source control.
  //    Build with: flutter build --dart-define=CLERK_PUBLISHABLE_KEY=pk_xxx
  // ═══════════════════════════════════════════════════════════════════════════

  /// Clerk Publishable Key (safe for client-side use).
  /// Format: pk_live_... or pk_test_...
  /// Set via: flutter build --dart-define=CLERK_PUBLISHABLE_KEY=pk_xxx
  static String get publishableKey {
    return const String.fromEnvironment(
      'pk_test_Y2xlcmsuaG91c2VpYW5hLm5ldCQ',
      defaultValue: '',
    );
  }

  /// Secret key for backend API calls (server-side only).
  /// Format: sk_live_... or sk_test_...
  /// Set via: flutter build --dart-define=CLERK_SECRET_KEY=sk_xxx
  static String get secretKey {
    return const String.fromEnvironment(
      'sk_test_1v2twd9j6yO93Ial7eUUs30rg9A3eMU3v4KCZIdHXn',
      defaultValue: '',
    );
  }

  /// Returns the secret key, or empty string if not configured.
  /// Check .isEmpty before using for backend operations.
  static String getBackendSecretKey() => secretKey;

  /// Returns true if secretKey is configured for backend operations.
  static bool get hasBackendSecretKey => secretKey.isNotEmpty;

  /// Clerk Frontend API Base URL.
  /// Extracted from the publishable key's domain (clerk.houseiana.com).
  // static const String frontendApiUrl = 'https://clerk.cafkejr.xyz';
 static const String frontendApiUrl = 'https://clerk.houseiana.com';
  /// Clerk Backend API Base URL (for server-side operations only).
  static const String backendApiUrl = 'https://api.clerk.com/v1';
}
