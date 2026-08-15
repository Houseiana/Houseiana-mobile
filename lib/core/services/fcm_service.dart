import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/network/api/end_points.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles Firebase Cloud Messaging — token retrieval, permission request,
/// foreground/background message handling, and backend registration via
/// POST /api/auth/device-token.
class FCMService {
  static FCMService? _instance;
  static FCMService get instance => _instance ??= FCMService._();
  FCMService._();

  // Last token successfully registered with the backend, and for which user.
  // Lets us skip the upload when nothing changed (every app start would
  // otherwise re-post the same token).
  static const _keySyncedToken = 'fcm_synced_token';
  static const _keySyncedUserId = 'fcm_synced_user_id';
  // Set while a logout-time deleteToken is unconfirmed; retried on the next
  // launch so an offline logout still ends up invalidating the token.
  static const _keyPendingDelete = 'fcm_pending_delete';

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  bool _initialized = false;
  Future<void>? _inflightSync;
  bool _syncRequestedWhileInflight = false;

  /// Call once after Firebase.initializeApp().
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      // Listeners and the background handler go FIRST. These are broadcast
      // streams — an event fired while requestPermission's modal is open or
      // while the initial sync is on the wire would otherwise be dropped, and
      // a rotation lost here leaves pushes pointed at a dead token all session.
      FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);

      // Re-register on token rotation.
      _messaging.onTokenRefresh.listen((_) {
        debugPrint('[FCM] Token refreshed');
        syncDeviceToken();
      });

      // Foreground messages — show a snackbar/banner via app-level overlay (future work)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM] Foreground message: ${message.notification?.title}');
      });

      // Tap on notification (app in background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM] Notification tapped: ${message.data}');
        _handleNotificationTap(message.data);
      });

      // Request permission (iOS / macOS; on Android the manifest handles it)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

      // Tap on notification (app was terminated) — handled BEFORE the sync,
      // which can hold the line for tens of seconds on a cold-start backend.
      final initial = await _messaging.getInitialMessage();
      if (initial != null) {
        _handleNotificationTap(initial.data);
      }

      // Finish a token wipe a previous (possibly offline) logout started.
      // Runs even when signed out, unlike the sync below.
      await _retryPendingDelete();

      // Register the token for an already-signed-in session (cold start).
      await syncDeviceToken();
    } catch (e) {
      debugPrint('[FCM] Initialization error: $e');
    }
  }

  /// Registers the current FCM token with the backend for the signed-in user.
  ///
  /// Safe to call from anywhere, any number of times: no-ops when signed out
  /// or while the session has no auth token yet, skips the request when this
  /// user+token pair is already registered, and collapses concurrent calls —
  /// a call landing while a sync is on the wire queues exactly one re-run, so
  /// the final run always observes the latest user and token. The synced
  /// marker is only written after a successful upload, so a failed attempt is
  /// retried on the next trigger (login, app start, or token rotation).
  Future<void> syncDeviceToken() {
    final inflight = _inflightSync;
    if (inflight != null) {
      _syncRequestedWhileInflight = true;
      return inflight;
    }
    // The loop exit and the hand-off below sit in one synchronous block, so
    // there is no instant where a caller can see a live `_inflightSync` that
    // no longer has a loop to consume its request.
    final done = Completer<void>();
    _inflightSync = done.future;
    () async {
      try {
        do {
          _syncRequestedWhileInflight = false;
          await _syncDeviceToken();
        } while (_syncRequestedWhileInflight);
      } finally {
        _inflightSync = null;
        done.complete();
      }
    }();
    return done.future;
  }

  Future<void> _syncDeviceToken() async {
    try {
      final session = sl<UserSession>();
      if (!session.isLoggedIn) return;
      final userId = session.userId!;
      // The endpoint requires the Bearer JWT. Without one the POST would go
      // out unauthenticated, 401, and the interceptor would force-logout a
      // freshly created session (the email-verification signup path can save
      // a userId with no token — same guard as _syncBackendSession there).
      final authToken = session.authToken;
      if (authToken == null || authToken.isEmpty) return;

      // Finish any pending logout-time wipe first, so a fast re-login never
      // registers the old token the background deleteToken is about to kill.
      await _retryPendingDelete();

      final token = await _getToken();
      if (token == null || token.isEmpty) return;

      final prefs = sl<SharedPreferences>();
      if (prefs.getString(_keySyncedToken) == token &&
          prefs.getString(_keySyncedUserId) == userId) {
        return; // Already registered for this user.
      }

      await sl<ApiConsumer>().post(
        EndPoints.deviceToken,
        body: {'token': token},
      );

      // The POST can be slow (cold-start backend). If the user changed while
      // it was on the wire, don't stamp the stale pair — the queued re-run
      // registers the right one.
      if (sl<UserSession>().userId != userId) return;
      await prefs.setString(_keySyncedToken, token);
      await prefs.setString(_keySyncedUserId, userId);
      debugPrint('[FCM] Device token registered');
    } catch (e) {
      debugPrint('[FCM] Device token sync failed: $e');
    }
  }

  /// iOS can throw apns-token-not-set when asked too soon after startup —
  /// give APNs a moment and retry before giving up on this trigger.
  Future<String?> _getToken() async {
    for (var attempt = 0; ; attempt++) {
      try {
        return await _messaging.getToken();
      } catch (e) {
        if (attempt >= 2) {
          debugPrint('[FCM] getToken failed: $e');
          return null;
        }
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
  }

  /// Call on logout: forgets the synced marker so the next sign-in
  /// re-registers, and invalidates the token so this device stops receiving
  /// the previous user's pushes. A fresh token is minted on the next
  /// getToken().
  ///
  /// Fast and safe to await — only local prefs are awaited; the token
  /// invalidation runs in the background so logout never waits on the
  /// network. If it fails (offline logout), the pending-delete marker makes
  /// the next launch finish the wipe.
  Future<void> onLogout() async {
    try {
      final prefs = sl<SharedPreferences>();
      await prefs.remove(_keySyncedToken);
      await prefs.remove(_keySyncedUserId);
      await prefs.setBool(_keyPendingDelete, true);
      unawaited(() async {
        try {
          await _messaging.deleteToken();
          await prefs.remove(_keyPendingDelete);
        } catch (e) {
          debugPrint('[FCM] deleteToken failed (will retry next launch): $e');
        }
      }());
    } catch (e) {
      debugPrint('[FCM] Logout cleanup failed: $e');
    }
  }

  Future<void> _retryPendingDelete() async {
    final prefs = sl<SharedPreferences>();
    if (prefs.getBool(_keyPendingDelete) != true) return;
    try {
      await _messaging.deleteToken();
      await prefs.remove(_keyPendingDelete);
      debugPrint('[FCM] Completed the pending token wipe from a previous logout');
    } catch (e) {
      debugPrint('[FCM] Pending token wipe still failing: $e');
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    // Navigate based on notification type
    final type = data['type']?.toString();
    debugPrint('[FCM] Handling tap — type: $type, data: $data');
    // Navigation is handled at the app level via a global navigator key
  }

  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (_) {
      return null;
    }
  }
}

/// Top-level function required by Firebase for background messages.
@pragma('vm:entry-point')
Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.notification?.title}');
}
