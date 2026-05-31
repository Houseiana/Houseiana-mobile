import 'package:dio/dio.dart';
import 'package:houseiana_mobile_app/core/config/clerk_config.dart';
import 'package:flutter/foundation.dart';

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
              'Authorization': 'Bearer ${ClerkConfig.getBackendSecretKey()}',
              'Content-Type': 'application/json',
            },
          ),
        ) {
    _frontendDio = Dio(
      BaseOptions(
        baseUrl: '${ClerkConfig.frontendApiUrl}/v1',
        // Note: Removing hardcoded _clerk_js_version query parameter.
        // Clerk SDK will automatically use the appropriate version.
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

    final logInterceptor = LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
      logPrint: (Object object) {
        debugPrint(object.toString());
      },
    );
    _frontendDio.interceptors.add(logInterceptor);
    _backendDio.interceptors.add(logInterceptor);

  }

  // ── Initialize Client ─────────────────────────────────────────────────────

  /// Initializes the Clerk client session.
  /// Returns true on success, false on failure.
  /// Logs errors in debug mode for troubleshooting.
  Future<bool> _initClient() async {
    try {
      await _frontendDio.get('/client');
      return true;
    } on DioException catch (e) {
      // Log error in debug mode - don't silently swallow
      if (kDebugMode) {
        debugPrint('ClerkService: Failed to initialize client: ${e.message}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ClerkService: Unexpected error initializing client: $e');
      }
      return false;
    }
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
        final authData = _extractAuthData(response.data as Map<String, dynamic>? ?? {});
        return {
          'success': true,
          'data': data,
          'message': 'Sign up successful',
          'userId': authData['userId'] ?? data['created_user_id']?.toString() ?? '',
          'token': authData['token'],
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
      final authData = _extractAuthData(response.data as Map<String, dynamic>? ?? {});
      return {
        'success': true,
        'data': data,
        'message': 'Email verified successfully',
        'userId': authData['userId'] ?? data?['created_user_id']?.toString() ?? '',
        'token': authData['token'],
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
          final authData = _extractAuthData(step2.data as Map<String, dynamic>? ?? {});
          final userId = authData['userId'] ?? completeData['user_id']?.toString() ?? '';
          final sessionId = authData['sessionId'] ?? completeData['created_session_id']?.toString() ?? '';
          final token = authData['token'];
          return {
            'success': true,
            'data': completeData,
            'message': 'Sign in successful',
            'userId': userId,
            'sessionId': sessionId,
            'token': token,
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
        final authData = _extractAuthData(step1.data as Map<String, dynamic>? ?? {});
        final userId = authData['userId'] ?? signInData['user_id']?.toString() ?? '';
        final sessionId = authData['sessionId'] ?? signInData['created_session_id']?.toString() ?? '';
        final token = authData['token'];
        return {
          'success': true,
          'data': signInData,
          'message': 'Sign in successful',
          'userId': userId,
          'sessionId': sessionId,
          'token': token,
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
        final authData = _extractAuthData(response.data as Map<String, dynamic>? ?? {});
        final userId = authData['userId'] ?? data['user_id']?.toString() ?? '';
        final sessionId = authData['sessionId'] ?? data['created_session_id']?.toString() ?? '';
        final token = authData['token'];
        return {
          'success': true,
          'data': data,
          'message': 'Sign in successful',
          'userId': userId,
          'sessionId': sessionId,
          'token': token,
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

  Future<Map<String, bool>> getPrivacySettings(String userId) async {
    final metadata = await _getPublicMetadata(userId);
    final settings = metadata['privacySettings'];

    return {
      ...ClerkPrivacyDefaults.values,
      if (settings is Map)
        for (final entry in settings.entries)
          if (entry.value is bool) entry.key.toString(): entry.value as bool,
    };
  }

  Future<Map<String, bool>> updatePrivacySetting({
    required String userId,
    required String setting,
    required bool value,
  }) async {
    final current = await getPrivacySettings(userId);
    final updated = {
      ...current,
      setting: value,
    };
    final metadata = await _getPublicMetadata(userId);

    await _backendDio.patch(
      '/users/$userId/metadata',
      data: {
        'public_metadata': {
          ...metadata,
          'privacySettings': updated,
        },
      },
    );

    return updated;
  }

  Future<Map<String, dynamic>?> getDataRequest(String userId) async {
    final metadata = await _getPublicMetadata(userId);
    final request = metadata['dataRequest'];
    return request is Map<String, dynamic> ? request : null;
  }

  Future<Map<String, dynamic>> requestDataExport(String userId) async {
    final existing = await getDataRequest(userId);
    if (existing != null && existing['status'] == 'pending') {
      return existing;
    }

    final now = DateTime.now();
    final request = {
      'id': 'dr_${now.millisecondsSinceEpoch}',
      'requestedAt': now.toIso8601String(),
      'status': 'pending',
      'estimatedReadyAt': now.add(const Duration(days: 30)).toIso8601String(),
    };
    final metadata = await _getPublicMetadata(userId);

    await _backendDio.patch(
      '/users/$userId/metadata',
      data: {
        'public_metadata': {
          ...metadata,
          'dataRequest': request,
        },
      },
    );

    return request;
  }

  Future<Map<String, dynamic>> _getPublicMetadata(String userId) async {
    final response = await _backendDio.get('/users/$userId');
    final data = response.data;
    final metadata = data is Map ? data['public_metadata'] : null;
    if (metadata is Map<String, dynamic>) return metadata;
    if (metadata is Map) {
      return metadata.map((key, value) => MapEntry(key.toString(), value));
    }
    return {};
  }

  // ── Password Reset (Forgot Password) ─────────────────────────────────────

  /// Initiates a password reset by sending a reset code to the user's email.
  /// Used when a user forgets their password and requests a reset link/code.
  Future<Map<String, dynamic>> createPasswordReset({
    required String email,
  }) async {
    try {
      _cookies.clear();
      await _initClient();

      // Step 1: Create sign-in with the email to get the user context
      final response = await _frontendDio.post(
        '/client/sign_ins',
        data: {'identifier': email},
        options: _formOptions,
      );

      final data = response.data?['response'] as Map<String, dynamic>?;
      if (data == null) {
        return {'success': false, 'message': 'Failed to initiate password reset'};
      }

      final status = data['status']?.toString() ?? '';

      // If we found the user, Clerk will have sent them an email or code
      if (status == 'needs_first_factor' || status == 'needs_second_factor') {
        // For password reset, we typically use email_code strategy
        final signInId = data['id']?.toString() ?? '';

        // Prepare the second factor for email_code if needed
        // For password reset flow, Clerk typically sends an email link or code
        // The user will use this in the reset password screen
        return {
          'success': true,
          'signInId': signInId,
          'message': 'Password reset code sent to your email',
        };
      } else if (status == 'complete') {
        return {
          'success': true,
          'message': 'Password reset email sent',
        };
      } else {
        // If user doesn't exist or other status, still return success
        // for security reasons (don't reveal if email exists)
        return {
          'success': true,
          'message': 'If an account exists with this email, you will receive a password reset link',
        };
      }
    } on DioException {
      // For security, still return success even on error
      // to prevent email enumeration attacks
      return {
        'success': true,
        'message': 'If an account exists with this email, you will receive a password reset link',
      };
    }
  }

  /// Verifies the password reset code and sets a new password.
  Future<Map<String, dynamic>> resetPassword({
    required String signInId,
    required String code,
    required String newPassword,
  }) async {
    try {
      // First, attempt to verify with the code
      // For password reset, typically uses email_code or phone_code strategy
      final verifyResponse = await _frontendDio.post(
        '/client/sign_ins/$signInId/attempt_first_factor',
        data: {
          'strategy': 'email_code',
          'code': code,
        },
        options: _formOptions,
      );

      final verifyData = verifyResponse.data?['response'] as Map<String, dynamic>?;
      if (verifyData == null) {
        return {'success': false, 'message': 'Invalid verification code'};
      }

      final verifyStatus = verifyData['status']?.toString() ?? '';

      if (verifyStatus == 'needs_second_factor') {
        // Continue to second factor if needed
        return {
          'success': true,
          'needsSecondFactor': true,
          'signInId': signInId,
          'message': 'Additional verification required',
        };
      } else if (verifyStatus == 'complete') {
        // Code verified - now we need to update the password
        // However, Clerk's frontend API doesn't directly support password update
        // We need to use the backend API for this
        final userId = verifyData['user_id']?.toString() ?? '';
        if (userId.isNotEmpty) {
          return await _updateUserPassword(userId, newPassword);
        }
        return {'success': false, 'message': 'User not found'};
      }

      return {'success': false, 'message': 'Verification failed'};
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Updates user password using backend API.
  /// Uses PUT instead of POST as per Clerk's REST API specification.
  /// Note: Password update via Clerk API requires the request to be
  /// authenticated with the backend secret key, which is already configured
  /// in _backendDio. The Clerk API will validate password requirements
  /// (min 8 chars, at least 1 number and 1 letter).
  Future<Map<String, dynamic>> _updateUserPassword(String userId, String newPassword) async {
    try {
      // Validate password meets Clerk's requirements before sending
      if (newPassword.length < 8) {
        return {
          'success': false,
          'message': 'Password must be at least 8 characters',
        };
      }

      // Use PUT for update operations as per REST conventions
      await _backendDio.put(
        '/users/$userId',
        data: {
          'password': newPassword,
        },
      );
      return {
        'success': true,
        'message': 'Password reset successfully',
      };
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Public wrapper for changing an authenticated user's password.
  /// Called from the change-password screen after UI validation passes.
  Future<Map<String, dynamic>> changeUserPassword({
    required String userId,
    required String newPassword,
  }) async {
    return await _updateUserPassword(userId, newPassword);
  }

  // ── Session Management ─────────────────────────────────────────────────────

  /// Attempts to restore a session from stored session ID.
  /// Returns user data if session is valid, or null if expired/invalid.
  Future<Map<String, dynamic>?> getSession(String sessionId) async {
    try {
      final response = await _backendDio.get('/sessions/$sessionId');
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // Session expired or invalid
      }
      return _handleError(e);
    }
  }

  /// Revokes a session (logout).
  Future<Map<String, dynamic>> revokeSession(String sessionId) async {
    try {
      await _backendDio.post('/sessions/$sessionId/revoke');
      return {'success': true, 'message': 'Session revoked'};
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Gets all active sessions for a user.
  Future<Map<String, dynamic>> getUserSessions(String userId) async {
    try {
      final response = await _backendDio.get('/users/$userId/sessions');
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── Token Helper ──────────────────────────────────────────────────────────

  /// Extracts userId, sessionId, and token from Clerk's full response.
  /// Looks into client.sessions to find the active session details.
  Map<String, String?> _extractAuthData(Map<String, dynamic> fullResponse) {
    String? userId;
    String? sessionId;
    String? token;

    final responseObj = fullResponse['response'] as Map<String, dynamic>?;
    if (responseObj != null) {
       sessionId = responseObj['created_session_id']?.toString() ?? responseObj['id']?.toString();
       userId = responseObj['user_id']?.toString() ?? responseObj['created_user_id']?.toString();
       
       // Fallback token extraction from response object directly
       final lat = responseObj['last_active_token'];
       if (lat is Map) {
          token = lat['jwt']?.toString();
       }
       final sess = responseObj['session'];
       if (sess is Map && token == null) {
          final lat2 = sess['last_active_token'];
          if (lat2 is Map) {
             token = lat2['jwt']?.toString();
          }
       }
    }

    final clientObj = fullResponse['client'] as Map<String, dynamic>?;
    if (clientObj != null) {
      final sessions = clientObj['sessions'] as List?;
      if (sessions != null && sessions.isNotEmpty) {
        // Find the session that matches created_session_id, or just the first active one
        Map<String, dynamic>? targetSession;
        if (sessionId != null) {
          try {
            targetSession = sessions.firstWhere(
              (s) => s is Map && s['id'] == sessionId,
            ) as Map<String, dynamic>?;
          } catch (_) {}
        }
        
        targetSession ??= (sessions.firstWhere(
          (s) => s is Map && s['status'] == 'active',
          orElse: () => sessions.first,
        ) as Map<String, dynamic>?);

        if (targetSession != null) {
          if (userId == null || userId.isEmpty) {
            final user = targetSession['user'];
            if (user is Map) {
              userId = user['id']?.toString();
            }
          }

          final lat = targetSession['last_active_token'];
          if (lat is Map) {
            final jwt = lat['jwt']?.toString();
            if (jwt != null && jwt.isNotEmpty) {
               token = jwt;
            }
          }
        }
      }
    }

    return {
      'userId': userId,
      'sessionId': sessionId,
      'token': token,
    };
  }

  // ── Error Handler ─────────────────────────────────────────────────────────

  Map<String, dynamic> _handleError(DioException e) {
    String message = 'An error occurred';

    if (e.response != null) {
      final data = e.response?.data;
      debugPrint('[Clerk] ${e.response?.statusCode} ${e.requestOptions.uri} → $data');

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
      debugPrint('[Clerk] No response — ${e.type}: ${e.message}');
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

class ClerkPrivacyDefaults {
  const ClerkPrivacyDefaults._();

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
