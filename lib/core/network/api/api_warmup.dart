import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:houseiana_mobile_app/core/config/app_config.dart';
import 'package:houseiana_mobile_app/core/network/api/end_points.dart';

/// Wakes the backend container at app start.
///
/// The API scales to zero, so the first request of a session pays a ~31s cold
/// start (see `backend_dio.dart`). Home is cache-first and often makes no call
/// at all, which means the container stays asleep until the user opens Search
/// — and *they* pay for the boot. Firing one throwaway request as the app
/// launches moves that wait behind the splash screen instead.
///
/// Deliberately fire-and-forget: nothing awaits it, failures are swallowed, and
/// it runs on a bare client (no auth needed — property-search is public) so it
/// can never interfere with a real request or trigger a token refresh.
class ApiWarmup {
  ApiWarmup._();

  static bool _fired = false;

  /// Sends the wake-up request once per process. Returns immediately.
  static void ping() {
    if (_fired) return;
    _fired = true;
    _ping();
  }

  static Future<void> _ping() async {
    // No retry and a generous receive window: nothing is waiting on this, and
    // the only job is to keep the connection open until the container boots.
    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.backendApiUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 90),
    ));
    try {
      await dio.get(
        EndPoints.propertySearch,
        queryParameters: {'page': 1, 'limit': 1},
      );
      if (kDebugMode) debugPrint('[ApiWarmup] backend is warm');
    } catch (e) {
      // Offline, or the container took longer than the window — the real
      // request will retry on its own.
      if (kDebugMode) debugPrint('[ApiWarmup] skipped: $e');
    } finally {
      dio.close(force: true);
    }
  }
}
