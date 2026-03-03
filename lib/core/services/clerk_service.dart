import 'package:dio/dio.dart';
import 'package:houseiana_mobile_app/core/config/clerk_config.dart';

class ClerkService {
  late final Dio _frontendDio;
  final Dio _backendDio;

  // In-memory cookie store to maintain session state across multi-step calls
  final _cookies = <String, String>{};

  // Clerk Frontend API requires form-urlencoded, not JSON
  static final _formOptions = Options(
    contentType: 'application/x-www-form-urlencoded',
  );

  ClerkService()
      : _backendDio = Dio(
          BaseOptions(
            baseUrl: ClerkConfig.backendApiUrl,
            headers: {
              'Authorization': 'Bearer ${ClerkConfig.secretKey}',
              'Content-Type': 'application/json',
            },
          ),
        ) {
    _frontendDio = Dio(
      BaseOptions(
        baseUrl: '${ClerkConfig.frontendApiUrl}/v1',
        queryParameters: {'_clerk_js_version': '5.35.0'},
      ),
    );

    // Persist cookies between multi-step auth calls
    _frontendDio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_cookies.isNotEmpty) {
            options.headers['Cookie'] =
                _cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          final setCookies = response.headers['set-cookie'] ?? [];
          for (final raw in setCookies) {
            final nameValue = raw.split(';').first.trim();
            final eqIdx = nameValue.indexOf('=');
            if (eqIdx > 0) {
              _cookies[nameValue.substring(0, eqIdx).trim()] =
                  nameValue.substring(eqIdx + 1).trim();
            }
          }
          handler.next(response);
        },
      ),
    );
  }

  // ── Initialize Client ─────────────────────────────────────────────────────

  Future<void> _initClient() async {
    try {
      await _frontendDio.get('/client');
    } catch (_) {}
  }

  // ── Sign Up ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    try {
      _cookies.clear();
      await _initClient();

      final body = <String, String>{
        'email_address': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
      };
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        body['phone_number'] = phoneNumber;
      }

      final response = await _frontendDio.post(
        '/client/sign_ups',
        data: body,
        options: _formOptions,
      );
      final data = response.data?['response'] as Map<String, dynamic>?;

      if (data == null) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      final status = data['status']?.toString() ?? '';

      if (status == 'complete') {
        return {
          'success': true,
          'data': data,
          'message': 'Sign up successful',
          'userId': data['created_user_id']?.toString() ?? '',
        };
      } else if (status == 'missing_requirements') {
        final signUpId = data['id']?.toString() ?? '';
        await prepareEmailVerification(signUpId: signUpId);
        return {
          'success': true,
          'data': data,
          'requiresVerification': true,
          'signUpId': signUpId,
          'message': 'Please verify your email',
        };
      } else {
        return {
          'success': false,
          'message': 'Sign up failed: $status',
        };
      }
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── Email Verification ────────────────────────────────────────────────────

  Future<Map<String, dynamic>> prepareEmailVerification({
    required String signUpId,
  }) async {
    try {
      final response = await _frontendDio.post(
        '/client/sign_ups/$signUpId/prepare_verification',
        data: {'strategy': 'email_code'},
        options: _formOptions,
      );
      return {
        'success': true,
        'data': response.data,
        'message': 'Verification email sent',
      };
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> verifyEmailCode({
    required String signUpId,
    required String code,
  }) async {
    try {
      final response = await _frontendDio.post(
        '/client/sign_ups/$signUpId/attempt_verification',
        data: {'strategy': 'email_code', 'code': code},
        options: _formOptions,
      );
      final data = response.data?['response'] as Map<String, dynamic>?;
      return {
        'success': true,
        'data': data,
        'message': 'Email verified successfully',
        'userId': data?['created_user_id']?.toString() ?? '',
      };
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── Sign In ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> signIn({
    required String identifier,
    required String password,
  }) async {
    try {
      _cookies.clear();
      await _initClient();

      // Step 1: Create sign-in with identifier (form-urlencoded)
      final step1 = await _frontendDio.post(
        '/client/sign_ins',
        data: {'identifier': identifier},
        options: _formOptions,
      );
      final signInData = step1.data?['response'] as Map<String, dynamic>?;
      if (signInData == null) {
        return {'success': false, 'message': 'Failed to start sign in'};
      }

      final signInId = signInData['id']?.toString() ?? '';
      final status = signInData['status']?.toString() ?? '';

      if (status == 'needs_first_factor') {
        // Step 2: Submit password
        final step2 = await _frontendDio.post(
          '/client/sign_ins/$signInId/attempt_first_factor',
          data: {'strategy': 'password', 'password': password},
          options: _formOptions,
        );
        final completeData = step2.data?['response'] as Map<String, dynamic>?;
        if (completeData == null) {
          return {'success': false, 'message': 'Authentication failed'};
        }

        final finalStatus = completeData['status']?.toString() ?? '';
        if (finalStatus == 'complete') {
          final userId = completeData['created_session_id']?.toString()
              ?? completeData['user_id']?.toString()
              ?? '';
          return {
            'success': true,
            'data': completeData,
            'message': 'Sign in successful',
            'userId': userId,
          };
        } else if (finalStatus == 'needs_second_factor') {
          // Determine which 2FA strategy to use
          final factors = completeData['supported_second_factors'] as List? ?? [];
          final firstFactor = factors.isNotEmpty ? factors[0] as Map? : null;
          final strategy = firstFactor?['strategy']?.toString() ?? 'totp';
          // For phone/email OTP, send the code first
          if (strategy == 'phone_code' || strategy == 'email_code') {
            await _frontendDio.post(
              '/client/sign_ins/${completeData['id']}/prepare_second_factor',
              data: {'strategy': strategy},
              options: _formOptions,
            );
          }
          return {
            'success': false,
            'requiresSecondFactor': true,
            'signInId': completeData['id']?.toString() ?? '',
            'strategy': strategy,
            'message': 'Please enter your 2FA code',
          };
        } else {
          return {
            'success': false,
            'message': 'Sign in incomplete: $finalStatus',
          };
        }
      } else if (status == 'complete') {
        final userId = signInData['created_session_id']?.toString()
            ?? signInData['user_id']?.toString()
            ?? '';
        return {
          'success': true,
          'data': signInData,
          'message': 'Sign in successful',
          'userId': userId,
        };
      } else {
        return {
          'success': false,
          'message': 'Unexpected sign-in status: $status',
        };
      }
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── Phone Verification ────────────────────────────────────────────────────

  Future<Map<String, dynamic>> verifyOTP({
    required String signUpId,
    required String code,
  }) async {
    try {
      final response = await _frontendDio.post(
        '/client/sign_ups/$signUpId/attempt_verification',
        data: {'strategy': 'phone_code', 'code': code},
        options: _formOptions,
      );
      return {
        'success': true,
        'data': response.data,
        'message': 'Phone verified successfully',
      };
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> preparePhoneVerification({
    required String signUpId,
  }) async {
    try {
      final response = await _frontendDio.post(
        '/client/sign_ups/$signUpId/prepare_verification',
        data: {'strategy': 'phone_code'},
        options: _formOptions,
      );
      return {
        'success': true,
        'data': response.data,
        'message': 'Verification code sent',
      };
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── Second Factor (2FA) ───────────────────────────────────────────────────

  /// Sends the OTP for phone_code / email_code second factor.
  /// Not needed for TOTP — user reads code from authenticator app.
  Future<Map<String, dynamic>> prepareSecondFactor({
    required String signInId,
    required String strategy, // 'phone_code' | 'email_code'
  }) async {
    try {
      final response = await _frontendDio.post(
        '/client/sign_ins/$signInId/prepare_second_factor',
        data: {'strategy': strategy},
        options: _formOptions,
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Submits the 2FA code regardless of strategy (totp / phone_code / email_code).
  Future<Map<String, dynamic>> verifySecondFactor({
    required String signInId,
    required String strategy,
    required String code,
  }) async {
    try {
      final response = await _frontendDio.post(
        '/client/sign_ins/$signInId/attempt_second_factor',
        data: {'strategy': strategy, 'code': code},
        options: _formOptions,
      );
      final data = response.data?['response'] as Map<String, dynamic>?;
      if (data == null) return {'success': false, 'message': 'Invalid response'};

      final status = data['status']?.toString() ?? '';
      if (status == 'complete') {
        final userId = data['created_session_id']?.toString()
            ?? data['user_id']?.toString()
            ?? '';
        return {
          'success': true,
          'data': data,
          'message': 'Sign in successful',
          'userId': userId,
        };
      } else {
        return {'success': false, 'message': '2FA verification failed: $status'};
      }
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── Get User ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getUser(String userId) async {
    try {
      final response = await _backendDio.get('/users/$userId');
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── Error Handler ─────────────────────────────────────────────────────────

  Map<String, dynamic> _handleError(DioException e) {
    String message = 'An error occurred';

    if (e.response != null) {
      final data = e.response?.data;
      print('[Clerk] ${e.response?.statusCode} ${e.requestOptions.uri} → $data');

      if (data is Map<String, dynamic>) {
        if (data['errors'] is List) {
          final errors = data['errors'] as List;
          if (errors.isNotEmpty && errors[0] is Map) {
            message = errors[0]['long_message']?.toString()
                ?? errors[0]['message']?.toString()
                ?? 'Error ${e.response?.statusCode}';
          }
        } else if (data['error'] != null) {
          message = data['error'].toString();
        } else if (data['message'] != null) {
          message = data['message'].toString();
        } else {
          message = 'Error ${e.response?.statusCode}';
        }
      } else if (data is String && data.isNotEmpty) {
        message = data;
      } else {
        message = 'Error ${e.response?.statusCode}';
      }
    } else {
      print('[Clerk] No response — ${e.type}: ${e.message}');
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
          message = 'Connection timed out. Please try again.';
          break;
        case DioExceptionType.connectionError:
          message = 'No internet connection. Check your network.';
          break;
        case DioExceptionType.badCertificate:
          message = 'SSL certificate error.';
          break;
        default:
          message = e.message ?? 'Unknown error';
      }
    }

    return {'success': false, 'message': message};
  }
}
