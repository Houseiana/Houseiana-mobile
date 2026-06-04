import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/models/gender_option.dart';
import 'package:houseiana_mobile_app/core/models/user_model.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/features/profile/cubit/personal_info_state.dart';

class PersonalInfoCubit extends Cubit<PersonalInfoState> {
  final UserService _userService = sl<UserService>();

  /// Cached so a save can re-emit the gender options without refetching them.
  List<GenderOption> _genderOptions = GenderOption.fallback;

  PersonalInfoCubit() : super(PersonalInfoInitial());

  Future<void> loadProfile(String userId) async {
    emit(PersonalInfoLoading());
    try {
      // Gender lookup is fetched in parallel; getGenders() never throws (it
      // falls back to a static list), so it can't break profile loading.
      final results = await Future.wait([
        _userService.getUser(userId),
        _userService.getGenders(),
      ]);
      final user = results[0] as UserModel?;
      _genderOptions = results[1] as List<GenderOption>;

      if (user != null) {
        emit(PersonalInfoLoaded(user, _genderOptions));
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
          emit(PersonalInfoSaved(updatedUser, _genderOptions));
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
