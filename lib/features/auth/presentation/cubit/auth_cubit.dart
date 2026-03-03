import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/services/clerk_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/features/auth/presentation/cubit/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final ClerkService _clerkService;

  AuthCubit({ClerkService? clerkService})
      : _clerkService = clerkService ?? ClerkService(),
        super(AuthInitial());

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
        final userId = result['userId']?.toString()
            ?? data?['created_user_id']?.toString()
            ?? '';

        final userData = data?['user_data'] as Map?;
        final firstName = userData?['first_name']?.toString()
            ?? data?['first_name']?.toString();
        final lastName = userData?['last_name']?.toString()
            ?? data?['last_name']?.toString();

        if (userId.isNotEmpty) {
          await sl<UserSession>().saveUser(
            userId: userId,
            email: email,
            firstName: firstName,
            lastName: lastName,
          );
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
          final nameParts2 = name.trim().split(' ');
          if (userId.isNotEmpty) {
            await sl<UserSession>().saveUser(
              userId: userId,
              email: email,
              firstName: nameParts2.first,
              lastName: nameParts2.length > 1 ? nameParts2.sublist(1).join(' ') : null,
            );
          }
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
        }
        emit(const AuthSuccess(message: 'Account verified! Welcome to Houseiana.'));
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
        emit(const AuthSuccess(message: 'Verification code resent'));
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
        emit(AuthSuccess(message: result['message'] ?? 'Verification code sent'));
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
        final userData = data?['user_data'] as Map?;
        if (userId.isNotEmpty) {
          await sl<UserSession>().saveUser(
            userId: userId,
            email: email,
            firstName: userData?['first_name']?.toString(),
            lastName: userData?['last_name']?.toString(),
          );
        }
        emit(AuthSuccess(message: '2FA verified. Welcome back!'));
      } else {
        emit(AuthError(message: result['message'] ?? '2FA verification failed'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    emit(AuthLoading());
    await sl<UserSession>().clear();
    emit(AuthInitial());
  }
}
