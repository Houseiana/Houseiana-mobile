import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String message;

  const AuthSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Emitted after sign-up when Clerk requires email verification.
class AuthVerificationRequired extends AuthState {
  final String signUpId;
  final String email;

  const AuthVerificationRequired({
    required this.signUpId,
    required this.email,
  });

  @override
  List<Object?> get props => [signUpId, email];
}

/// Emitted after password is accepted but Clerk requires a 2FA code.
class AuthSecondFactorRequired extends AuthState {
  final String signInId;
  final String email;
  final String strategy; // 'totp' | 'phone_code' | 'email_code'

  const AuthSecondFactorRequired({
    required this.signInId,
    required this.email,
    required this.strategy,
  });

  @override
  List<Object?> get props => [signInId, email, strategy];
}
