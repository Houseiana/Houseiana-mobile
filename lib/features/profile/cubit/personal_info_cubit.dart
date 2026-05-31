import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/features/profile/cubit/personal_info_state.dart';

class PersonalInfoCubit extends Cubit<PersonalInfoState> {
  final UserService _userService = sl<UserService>();

  PersonalInfoCubit() : super(PersonalInfoInitial());

  Future<void> loadProfile(String userId) async {
    emit(PersonalInfoLoading());
    try {
      final user = await _userService.getUser(userId);
      if (user != null) {
        emit(PersonalInfoLoaded(user));
      } else {
        emit(const PersonalInfoError('User not found'));
      }
    } catch (e) {
      emit(PersonalInfoError(e.toString()));
    }
  }

  Future<void> saveProfile(String userId, Map<String, dynamic> data) async {
    emit(PersonalInfoSaving());
    try {
      final ok = await _userService.updateProfile(userId, data);
      if (ok) {
        final updatedUser = await _userService.getUser(userId);
        if (updatedUser != null) {
          emit(PersonalInfoSaved(updatedUser));
        } else {
          emit(const PersonalInfoError('Profile updated, but refreshed data was not available.'));
        }
      } else {
        emit(const PersonalInfoError('Failed to update profile'));
      }
    } catch (e) {
      emit(PersonalInfoError(e.toString()));
    }
  }
}
