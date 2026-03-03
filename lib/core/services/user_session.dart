import 'package:shared_preferences/shared_preferences.dart';

/// Stores and retrieves the currently signed-in Clerk user ID.
/// The user ID is used as a path/query parameter in backend API calls
/// because the backend identifies users by their Clerk ID.
class UserSession {
  static const _keyUserId    = 'clerk_user_id';
  static const _keyEmail     = 'user_email';
  static const _keyFirstName = 'user_first_name';
  static const _keyLastName  = 'user_last_name';

  final SharedPreferences _prefs;

  UserSession(this._prefs);

  // ── Write ──────────────────────────────────────────────────────────────────

  Future<void> saveUser({
    required String userId,
    String? email,
    String? firstName,
    String? lastName,
  }) async {
    await _prefs.setString(_keyUserId, userId);
    if (email != null)     await _prefs.setString(_keyEmail, email);
    if (firstName != null) await _prefs.setString(_keyFirstName, firstName);
    if (lastName != null)  await _prefs.setString(_keyLastName, lastName);
  }

  Future<void> clear() async {
    await _prefs.remove(_keyUserId);
    await _prefs.remove(_keyEmail);
    await _prefs.remove(_keyFirstName);
    await _prefs.remove(_keyLastName);
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  String? get userId    => _prefs.getString(_keyUserId);
  String? get email     => _prefs.getString(_keyEmail);
  String? get firstName => _prefs.getString(_keyFirstName);
  String? get lastName  => _prefs.getString(_keyLastName);

  String get fullName {
    final f = firstName ?? '';
    final l = lastName ?? '';
    final full = '$f $l'.trim();
    return full.isEmpty ? 'User' : full;
  }

  bool get isLoggedIn => userId != null && userId!.isNotEmpty;
}
