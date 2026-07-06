import 'package:dio/dio.dart';
import 'package:houseiana_mobile_app/core/config/app_config.dart';
import 'package:houseiana_mobile_app/core/network/api/auth_interceptor.dart';
import 'package:houseiana_mobile_app/core/services/clerk_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';

/// Privacy settings + GDPR data requests, backed by the web app's Next.js
/// API routes (`/api/account/privacy-settings`, `/api/account/data-request`).
///
/// The data lives in the Clerk user's publicMetadata, which only the web
/// server (holder of the Clerk secret key) can write — so the mobile app has
/// to go through these routes instead of the Clerk Backend API. Auth is the
/// same Clerk session JWT used for the .NET backend; [AuthInterceptor]
/// attaches it and transparently refreshes on 401.
class AccountPrivacyService {
  final Dio _dio;

  AccountPrivacyService(ClerkService clerkService, UserSession userSession)
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.webAppUrl,
            headers: {'Content-Type': 'application/json'},
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 20),
          ),
        ) {
    _dio.interceptors.add(AuthInterceptor(clerkService, userSession));
  }

  Future<Map<String, bool>> getPrivacySettings() async {
    final response = await _dio.get('/api/account/privacy-settings');
    return _parseSettings(response.data);
  }

  Future<Map<String, bool>> updatePrivacySetting({
    required String setting,
    required bool value,
  }) async {
    final response = await _dio.patch(
      '/api/account/privacy-settings',
      data: {'setting': setting, 'value': value},
    );
    return _parseSettings(response.data);
  }

  Future<Map<String, dynamic>?> getDataRequest() async {
    final response = await _dio.get('/api/account/data-request');
    return _asStringKeyedMap(
      response.data is Map ? response.data['data'] : null,
    );
  }

  Future<Map<String, dynamic>> requestDataExport() async {
    try {
      final response = await _dio.post('/api/account/data-request', data: {});
      final request = _asStringKeyedMap(
        response.data is Map ? response.data['data'] : null,
      );
      if (request != null) return request;
      throw Exception('common.errorOccurred');
    } on DioException catch (e) {
      // The web route responds 400 with the existing request when one is
      // already pending — surface it instead of failing.
      final existing = _asStringKeyedMap(
        e.response?.data is Map ? e.response!.data['data'] : null,
      );
      if (e.response?.statusCode == 400 && existing != null) {
        return existing;
      }
      rethrow;
    }
  }

  Map<String, bool> _parseSettings(dynamic data) {
    final settings = data is Map ? data['data'] : null;
    return {
      ...PrivacyDefaults.values,
      if (settings is Map)
        for (final entry in settings.entries)
          if (entry.value is bool) entry.key.toString(): entry.value as bool,
    };
  }

  Map<String, dynamic>? _asStringKeyedMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, v) => MapEntry(key.toString(), v));
    }
    return null;
  }
}

/// Mirrors DEFAULT_PRIVACY_SETTINGS in the web app's
/// `/api/account/privacy-settings` route.
class PrivacyDefaults {
  const PrivacyDefaults._();

  static const values = <String, bool>{
    'shareActivityWithPartners': false,
    'includeInSearchEngines': true,
    'showProfileToHosts': true,
    'shareLocationWithHosts': true,
    'personalizedRecommendations': true,
    'personalizedAds': false,
    'usageAnalytics': true,
    'shareWithThirdParties': false,
  };
}
