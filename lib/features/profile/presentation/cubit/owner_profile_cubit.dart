import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/features/profile/presentation/cubit/owner_profile_state.dart';

/// Loads another user's public profile (the property owner / host) from
/// `GET /users/{id}`. Mirrors [ProfileCubit]'s sl-in-constructor style.
class OwnerProfileCubit extends Cubit<OwnerProfileState> {
  final UserService _userService;

  OwnerProfileCubit()
      : _userService = sl<UserService>(),
        super(OwnerProfileInitial());

  Future<void> load(String userId) async {
    if (userId.isEmpty) {
      emit(const OwnerProfileError('ownerProfile.profileNotFound'));
      return;
    }
    emit(OwnerProfileLoading());
    try {
      final profile = await _userService.getPublicProfile(userId);
      if (profile == null) {
        emit(const OwnerProfileError('ownerProfile.profileNotFound'));
      } else {
        emit(OwnerProfileLoaded(profile));
      }
    } catch (_) {
      emit(const OwnerProfileError('ownerProfile.profileNotFound'));
    }
  }
}
