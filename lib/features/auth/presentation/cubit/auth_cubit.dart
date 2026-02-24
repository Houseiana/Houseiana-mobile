import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/features/auth/presentation/cubit/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      // TODO: Implement actual login logic
      await Future.delayed(const Duration(seconds: 2));
      emit(const AuthSuccess(message: 'Login successful'));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    emit(AuthLoading());
    try {
      // TODO: Implement actual sign up logic
      await Future.delayed(const Duration(seconds: 2));
      emit(const AuthSuccess(message: 'Sign up successful'));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> logout() async {
    emit(AuthLoading());
    try {
      // TODO: Implement actual logout logic
      emit(AuthInitial());
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }
}
