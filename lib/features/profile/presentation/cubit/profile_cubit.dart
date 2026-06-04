import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/profile/presentation/cubit/profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final UserService _userService;
  final UserSession _session;

  ProfileCubit()
      : _userService = sl<UserService>(),
        _session = sl<UserSession>(),
        super(ProfileInitial());

  Future<void> getProfile() async {
    if (!_session.isLoggedIn) {
      emit(const ProfileLoaded(user: null));
      return;
    }
    emit(ProfileLoading());
    try {
      final user = await _userService.getUser(_session.userId!);
      emit(ProfileLoaded(user: user));
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (!_session.isLoggedIn) return;
    emit(ProfileLoading());
    try {
      final ok = await _userService.updateProfile(_session.userId!, data);
      if (ok) {
        final user = await _userService.getUser(_session.userId!);
        emit(ProfileLoaded(user: user));
      } else {
        emit(const ProfileError(message: 'profile.profileUpdateFailed'));
      }
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }
}
