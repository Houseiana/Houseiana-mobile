import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static const _keyUserId = 'clerk_user_id';
  static const _keyEmail = 'user_email';
  static const _keyFirstName = 'user_first_name';
  static const _keyLastName = 'user_last_name';
  static const _keySessionId = 'clerk_session_id';
  static const _keyAuthToken = 'auth_token';
  static const _keyIsHost = 'user_is_host';

  final SharedPreferences _prefs;

  UserSession(this._prefs);

  Future<void> saveUser({
    required String userId,
    String? email,
    String? firstName,
    String? lastName,
    String? sessionId,
    bool? isHost,
  }) async {
    await _prefs.setString(_keyUserId, userId);
    if (email != null) await _prefs.setString(_keyEmail, email);
    if (firstName != null) await _prefs.setString(_keyFirstName, firstName);
    if (lastName != null) await _prefs.setString(_keyLastName, lastName);
    if (sessionId != null) await _prefs.setString(_keySessionId, sessionId);
    if (isHost != null) await _prefs.setBool(_keyIsHost, isHost);
  }

  Future<void> saveAuthToken(String token) async {
    await _prefs.setString(_keyAuthToken, token);
  }

  Future<void> clear() async {
    await _prefs.remove(_keyUserId);
    await _prefs.remove(_keyEmail);
    await _prefs.remove(_keyFirstName);
    await _prefs.remove(_keyLastName);
    await _prefs.remove(_keySessionId);
    await _prefs.remove(_keyAuthToken);
    await _prefs.remove(_keyIsHost);
  }

  String? get userId => _prefs.getString(_keyUserId);
  String? get email => _prefs.getString(_keyEmail);
  String? get firstName => _prefs.getString(_keyFirstName);
  String? get lastName => _prefs.getString(_keyLastName);
  String? get sessionId => _prefs.getString(_keySessionId);
  String? get authToken => _prefs.getString(_keyAuthToken);

  bool get isHost => _prefs.getBool(_keyIsHost) ?? false;

  String get fullName {
    final f = firstName ?? '';
    final l = lastName ?? '';
    final full = '$f $l'.trim();
    return full.isEmpty ? 'User' : full;
  }

  bool get isLoggedIn => userId != null && userId!.isNotEmpty;
}
