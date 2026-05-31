import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/network/api/end_points.dart';
import 'package:houseiana_mobile_app/core/services/clerk_service.dart';
import 'package:houseiana_mobile_app/core/services/google_auth_service.dart';
import 'package:houseiana_mobile_app/core/services/apple_auth_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/features/auth/presentation/cubit/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final ClerkService _clerkService;
  final GoogleAuthService _googleAuthService;
  final AppleAuthService _appleAuthService;

  AuthCubit({
    ClerkService? clerkService,
    GoogleAuthService? googleAuthService,
    AppleAuthService? appleAuthService,
  })  : _clerkService = clerkService ?? ClerkService(),
        _googleAuthService = googleAuthService ?? GoogleAuthService(),
        _appleAuthService = appleAuthService ?? AppleAuthService(),
        super(AuthInitial());

  // ── Backend Session Sync ──────────────────────────────────────────────────

  /// Pings the backend `/api/auth/login` endpoint with the stored Bearer token
  /// after signup. The response is intentionally ignored; failures must not
  /// break the auth flow.
  Future<void> _syncBackendSession() async {
    final token = sl<UserSession>().authToken;
    if (token == null || token.isEmpty) return;
    try {
      await sl<ApiConsumer>().post(EndPoints.authLogin);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthCubit] /api/auth/login sync failed (ignored): $e');
      }
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      final result = await _clerkService.signIn(
        identifier: email,
        password: password,
      );

      if (result['success'] == true) {
        final data = result['data'] as Map?;
        final userId = result['userId']?.toString() ??
            data?['created_user_id']?.toString() ??
            '';
        final sessionId = result['sessionId']?.toString() ??
            data?['created_session_id']?.toString() ??
            '';

        final userData = data?['user_data'] as Map?;
        final firstName = userData?['first_name']?.toString() ??
            data?['first_name']?.toString();
        final lastName = userData?['last_name']?.toString() ??
            data?['last_name']?.toString();

        if (userId.isNotEmpty) {
          await sl<UserSession>().saveUser(
            userId: userId,
            email: email,
            firstName: firstName,
            lastName: lastName,
            sessionId: sessionId.isNotEmpty ? sessionId : null,
          );
          final jwt = result['token']?.toString();
          if (jwt != null && jwt.isNotEmpty) {
            await sl<UserSession>().saveAuthToken(jwt);
          } else if (sessionId.isNotEmpty) {
            // Fallback to sessionId if no JWT available
            await sl<UserSession>().saveAuthToken(sessionId);
          }
        }
        emit(AuthSuccess(message: result['message'] ?? 'Login successful'));
      } else if (result['requiresSecondFactor'] == true) {
        emit(AuthSecondFactorRequired(
          signInId: result['signInId'] ?? '',
          email: email,
          strategy: result['strategy'] ?? 'totp',
        ));
      } else {
        emit(AuthError(message: result['message'] ?? 'Login failed'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  // ── Sign Up ───────────────────────────────────────────────────────────────

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      final nameParts = name.trim().split(' ');
      final firstName = nameParts.first;
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      final result = await _clerkService.signUp(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );

      if (result['success'] == true) {
        if (result['requiresVerification'] == true) {
          // Email verification required — send the code then prompt user
          final signUpId = result['signUpId']?.toString() ?? '';
          await _clerkService.prepareEmailVerification(signUpId: signUpId);
          emit(AuthVerificationRequired(signUpId: signUpId, email: email));
        } else {
          final userId = result['userId']?.toString() ?? '';
          final sessionId = result['sessionId']?.toString() ?? '';
          final nameParts2 = name.trim().split(' ');
          if (userId.isNotEmpty) {
            await sl<UserSession>().saveUser(
              userId: userId,
              email: email,
              firstName: nameParts2.first,
              lastName: nameParts2.length > 1
                  ? nameParts2.sublist(1).join(' ')
                  : null,
              sessionId: sessionId.isNotEmpty ? sessionId : null,
            );
            final jwt = result['token']?.toString();
            if (jwt != null && jwt.isNotEmpty) {
              await sl<UserSession>().saveAuthToken(jwt);
            } else if (sessionId.isNotEmpty) {
              await sl<UserSession>().saveAuthToken(sessionId);
            }
          }
          await _syncBackendSession();
          emit(AuthSuccess(message: result['message'] ?? 'Sign up successful'));
        }
      } else {
        emit(AuthError(message: result['message'] ?? 'Sign up failed'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  // ── Email Verification ────────────────────────────────────────────────────

  Future<void> verifyEmailCode({
    required String signUpId,
    required String code,
    required String email,
    String? name,
  }) async {
    emit(AuthLoading());
    try {
      final result = await _clerkService.verifyEmailCode(
        signUpId: signUpId,
        code: code,
      );

      if (result['success'] == true) {
        final userId = result['userId']?.toString() ?? '';
        if (userId.isNotEmpty) {
          final parts = (name ?? '').trim().split(' ');
          await sl<UserSession>().saveUser(
            userId: userId,
            email: email,
            firstName: parts.isNotEmpty ? parts.first : null,
            lastName: parts.length > 1 ? parts.sublist(1).join(' ') : null,
          );
          final jwt = result['token']?.toString();
          if (jwt != null && jwt.isNotEmpty) {
            await sl<UserSession>().saveAuthToken(jwt);
          }
        }
        await _syncBackendSession();
        emit(const AuthSuccess(
            message: 'Account verified! Welcome to Houseiana.'));
      } else {
        emit(AuthError(message: result['message'] ?? 'Verification failed'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> resendEmailCode({required String signUpId}) async {
    emit(AuthLoading());
    try {
      final result =
          await _clerkService.prepareEmailVerification(signUpId: signUpId);
      if (result['success'] == true) {
        emit(const AuthCodeResent());
      } else {
        emit(AuthError(message: result['message'] ?? 'Failed to resend code'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  // ── Phone Verification ────────────────────────────────────────────────────

  Future<void> verifyOTP({
    required String signUpId,
    required String code,
  }) async {
    emit(AuthLoading());
    try {
      final result =
          await _clerkService.verifyOTP(signUpId: signUpId, code: code);
      if (result['success'] == true) {
        emit(AuthSuccess(
            message: result['message'] ?? 'Phone verified successfully'));
      } else {
        emit(AuthError(message: result['message'] ?? 'Verification failed'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> preparePhoneVerification({required String signUpId}) async {
    emit(AuthLoading());
    try {
      final result =
          await _clerkService.preparePhoneVerification(signUpId: signUpId);
      if (result['success'] == true) {
        emit(AuthSuccess(
            message: result['message'] ?? 'Verification code sent'));
      } else {
        emit(AuthError(message: result['message'] ?? 'Failed to send code'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  // ── Second Factor (2FA) ───────────────────────────────────────────────────

  Future<void> verifySecondFactor({
    required String signInId,
    required String strategy,
    required String code,
    required String email,
  }) async {
    emit(AuthLoading());
    try {
      final result = await _clerkService.verifySecondFactor(
        signInId: signInId,
        strategy: strategy,
        code: code,
      );
      if (result['success'] == true) {
        final data = result['data'] as Map?;
        final userId = result['userId']?.toString() ?? '';
        final sessionId = result['sessionId']?.toString() ??
            data?['created_session_id']?.toString() ??
            '';
        final userData = data?['user_data'] as Map?;
        if (userId.isNotEmpty) {
          await sl<UserSession>().saveUser(
            userId: userId,
            email: email,
            firstName: userData?['first_name']?.toString(),
            lastName: userData?['last_name']?.toString(),
            sessionId: sessionId.isNotEmpty ? sessionId : null,
          );
          final jwt = result['token']?.toString();
          if (jwt != null && jwt.isNotEmpty) {
            await sl<UserSession>().saveAuthToken(jwt);
          } else if (sessionId.isNotEmpty) {
            await sl<UserSession>().saveAuthToken(sessionId);
          }
        }
        emit(AuthSuccess(message: '2FA verified. Welcome back!'));
      } else {
        emit(
            AuthError(message: result['message'] ?? '2FA verification failed'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  // ── Password Reset ────────────────────────────────────────────────────────

  /// Sends a password reset email to the user.
  Future<void> sendPasswordResetEmail({required String email}) async {
    emit(AuthLoading());
    try {
      final result = await _clerkService.createPasswordReset(email: email);
      if (result['success'] == true) {
        emit(AuthPasswordResetEmailSent(email: email));
      } else {
        emit(AuthError(
            message: result['message'] ?? 'Failed to send reset email'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  /// Resets the password using the verification code.
  Future<void> resetPassword({
    required String signInId,
    required String code,
    required String newPassword,
  }) async {
    emit(AuthLoading());
    try {
      final result = await _clerkService.resetPassword(
        signInId: signInId,
        code: code,
        newPassword: newPassword,
      );
      if (result['success'] == true) {
        emit(const AuthPasswordResetSuccess());
      } else if (result['needsSecondFactor'] == true) {
        emit(AuthSecondFactorRequired(
          signInId: result['signInId'] ?? '',
          email: '',
          strategy: 'email_code',
        ));
      } else {
        emit(AuthError(message: result['message'] ?? 'Password reset failed'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  // ── Social Login ──────────────────────────────────────────────────────────

  /// Initiates Google OAuth flow.
  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      final result = await _googleAuthService.signInWithGoogle();
      if (result['success'] == true) {
        final userId = result['userId']?.toString() ?? '';
        final sessionId = result['sessionId']?.toString();
        if (userId.isNotEmpty) {
          await sl<UserSession>().saveUser(
            userId: userId,
            email: '',
            firstName: null,
            lastName: null,
            sessionId: sessionId,
          );
          final jwt = result['token']?.toString();
          if (jwt != null && jwt.isNotEmpty) {
            await sl<UserSession>().saveAuthToken(jwt);
          } else if (sessionId != null && sessionId.isNotEmpty) {
            await sl<UserSession>().saveAuthToken(sessionId);
          }
        }
        emit(AuthSuccess(
            message: result['message'] ?? 'Google sign-in successful'));
      } else {
        emit(AuthError(message: result['message'] ?? 'Google sign-in failed'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  /// Initiates Apple Sign In.
  Future<void> signInWithApple() async {
    emit(AuthLoading());
    try {
      final result = await _appleAuthService.signInWithApple();
      if (result['success'] == true) {
        final userId = result['userId']?.toString() ?? '';
        final sessionId = result['sessionId']?.toString();
        if (userId.isNotEmpty) {
          await sl<UserSession>().saveUser(
            userId: userId,
            email: '',
            firstName: null,
            lastName: null,
            sessionId: sessionId,
          );
          final jwt = result['token']?.toString();
          if (jwt != null && jwt.isNotEmpty) {
            await sl<UserSession>().saveAuthToken(jwt);
          } else if (sessionId != null && sessionId.isNotEmpty) {
            await sl<UserSession>().saveAuthToken(sessionId);
          }
        }
        emit(AuthSuccess(
            message: result['message'] ?? 'Apple sign-in successful'));
      } else {
        emit(AuthError(message: result['message'] ?? 'Apple sign-in failed'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  /// Logs out the current user by revoking their session.
  Future<void> logout() async {
    emit(AuthLoading());
    try {
      final sessionId = sl<UserSession>().sessionId;
      if (sessionId != null && sessionId.isNotEmpty) {
        // Revoke the current session
        await _clerkService.revokeSession(sessionId);
      }
      await sl<UserSession>().clear();
      emit(AuthInitial());
    } catch (e) {
      // Even if session revocation fails, clear local state
      await sl<UserSession>().clear();
      emit(AuthInitial());
    }
  }
}
