import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/network/api/end_points.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';

/// Handles Firebase Cloud Messaging — token retrieval, permission request,
/// and foreground/background message handling.
class FCMService {
  static FCMService? _instance;
  static FCMService get instance => _instance ??= FCMService._();
  FCMService._();

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  /// Call once after Firebase.initializeApp().
  Future<void> initialize() async {
    try {
      // Request permission (iOS / macOS; on Android the manifest handles it)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

      // Get token and upload to backend
      final token = await _messaging.getToken();
      debugPrint('[FCM] Token: $token');
      if (token != null) await _uploadToken(token);

      // Re-upload on token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('[FCM] Token refreshed: $newToken');
        _uploadToken(newToken);
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

      // Tap on notification (app was terminated)
      final initial = await _messaging.getInitialMessage();
      if (initial != null) {
        _handleNotificationTap(initial.data);
      }

      // Background handler (must be a top-level function)
      FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);
    } catch (e) {
      debugPrint('[FCM] Initialization error: $e');
    }
  }

  Future<void> _uploadToken(String token) async {
    try {
      final session = sl<UserSession>();
      if (!session.isLoggedIn || session.userId == null) return;
      final api = sl<ApiConsumer>();
      await api.post(
        EndPoints.firebaseToken,
        body: {'userId': session.userId, 'token': token},
      );
    } catch (e) {
      debugPrint('[FCM] Token upload failed: $e');
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
