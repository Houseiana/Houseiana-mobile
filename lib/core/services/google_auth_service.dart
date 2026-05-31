import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:houseiana_mobile_app/core/config/app_config.dart';
import 'package:dio/dio.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn;
  final Dio _dio;

  GoogleAuthService({GoogleSignIn? googleSignIn, Dio? dio})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: <String>['email', 'profile'],
            ),
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.backendApiUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
            ));

  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return {'success': false, 'message': 'Google sign-in was cancelled'};
      }

      final googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null) {
        return {
          'success': false,
          'message': 'Failed to get Google access token'
        };
      }

      final backendResponse = await _exchangeGoogleToken(googleAuth.idToken!);

      return backendResponse;
    } catch (e) {
      debugPrint('[GoogleAuth] Sign-in error: $e');
      return {'success': false, 'message': 'Google sign-in failed'};
    }
  }

  Future<Map<String, dynamic>> _exchangeGoogleToken(String idToken) async {
    try {
      final response = await _dio.post(
        '/account/google/callback',
        data: {'token': idToken},
      );

      final data = response.data;

      if (data['success'] == true || data['token'] != null) {
        return {
          'success': true,
          'message': 'Google sign-in successful',
          'userId':
              data['userId']?.toString() ?? data['user']?['id']?.toString(),
          'sessionId':
              data['sessionId']?.toString() ?? data['session_id']?.toString(),
          'token': data['token']?.toString() ?? data['authToken']?.toString(),
        };
      } else {
        return {
          'success': false,
          'message': data['message']?.toString() ?? 'Authentication failed',
        };
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return {'success': false, 'message': 'Invalid Google token'};
      }
      if (e.response?.statusCode == 409) {
        return {
          'success': false,
          'message': 'Email already registered with another account'
        };
      }
      return {'success': false, 'message': 'Failed to connect to server'};
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('[GoogleAuth] Sign-out error: $e');
    }
  }

  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      debugPrint('[GoogleAuth] Disconnect error: $e');
    }
  }
}
