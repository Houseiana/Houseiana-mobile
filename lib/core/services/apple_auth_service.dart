import 'package:flutter/foundation.dart';

/// Service for handling Apple Sign-In authentication.
/// After successful Apple auth, exchanges the token with the backend
/// to create a Clerk session.
///
/// NOTE: Full implementation requires:
/// 1. Apple Developer account with Sign in with Apple configured
/// 2. Backend endpoint at /account/apple/callback
/// 3. Running `flutter pub run sign_in_with_apple:configure` to generate credentials
class AppleAuthService {
  AppleAuthService();

  /// Initiates Apple Sign-In flow and exchanges token with backend.
  /// Returns a map with success status and user data or error message.
  ///
  /// Apple Sign-In is intentionally disabled until native Apple credentials and
  /// the backend callback are configured.
  ///
  /// Full Apple Sign-In requires:
  /// - The sign_in_with_apple package to be configured
  /// - Apple Developer Portal setup
  /// - Backend endpoint implementation
  Future<Map<String, dynamic>> signInWithApple() async {
    debugPrint('[AppleAuth] Apple Sign-In not yet implemented');
    return {
      'success': false,
      'message': 'Apple sign-in is being configured. Please use email/password for now.',
    };
  }

  /// Signs out from Apple (if applicable).
  Future<void> signOut() async {
    // Apple Sign-In doesn't have a sign-out method on the client side
    // Session management is handled by the backend
    debugPrint('[AppleAuth] Sign-out called (no-op for Apple)');
  }
}
