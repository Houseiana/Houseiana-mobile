import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/errors/exceptions.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/profile/cubit/identity_verification_state.dart';

/// Drives the Identity Verification screen — the mobile parity of the web's
/// personal-info identity sections (Government ID + Emergency Contact).
///
/// Each section saves independently against its own backend endpoint:
///   passport          → POST /users/{id}/passport
///   national id       → POST /users/{id}/national-id   (multipart, with photos)
///   emergency contact → POST /users/{id}/emergency-contact
class IdentityVerificationCubit extends Cubit<IdentityVerificationState> {
  final UserService _userService;
  final UserSession _session;

  IdentityVerificationCubit(this._userService, this._session)
      : super(const IdentityVerificationState());

  String? get _userId => _session.userId;

  /// Loads all three records plus the relationship lookup concurrently. A
  /// missing record (404 / empty) is not an error — it just means the section
  /// is empty, so each record fetch is guarded individually.
  Future<void> load() async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      emit(state.copyWith(
        status: IdentityLoadStatus.error,
        loadError: 'profile.identitySignInRequired',
      ));
      return;
    }

    emit(state.copyWith(status: IdentityLoadStatus.loading));

    // Kick all requests off before awaiting so they run in parallel.
    final passportF = _safe(() => _userService.getPassport(userId));
    final nationalF = _safe(() => _userService.getNationalId(userId));
    final emergencyF = _safe(() => _userService.getEmergencyContact(userId));
    final relationshipsF = _userService.getRelationshipOptions();

    try {
      emit(state.copyWith(
        status: IdentityLoadStatus.ready,
        passport: await passportF,
        nationalId: await nationalF,
        emergencyContact: await emergencyF,
        relationshipOptions: await relationshipsF,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: IdentityLoadStatus.error,
        loadError: _errorText(e, 'common.error'),
      ));
    }
  }

  Future<void> savePassport(Map<String, dynamic> body) async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) return _emitSignInRequired();

    emit(state.copyWith(savingSection: 'passport'));
    try {
      await _userService.updatePassport(userId, body);
      final refreshed = await _safe(() => _userService.getPassport(userId));
      emit(_feedback(
        state.copyWith(savingSection: null, passport: refreshed ?? state.passport),
        'profile.identitySavedSuccess',
        isError: false,
      ));
    } catch (e) {
      emit(_feedback(state.copyWith(savingSection: null),
          _errorText(e, 'profile.identitySaveFailed'),
          isError: true));
    }
  }

  Future<void> saveNationalId({
    required Map<String, dynamic> fields,
    String? frontPhotoPath,
    String? backPhotoPath,
  }) async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) return _emitSignInRequired();

    emit(state.copyWith(savingSection: 'nationalId'));
    try {
      await _userService.addNationalId(
        userId,
        fields: fields,
        frontPhotoPath: frontPhotoPath,
        backPhotoPath: backPhotoPath,
      );
      final refreshed = await _safe(() => _userService.getNationalId(userId));
      emit(_feedback(
        state.copyWith(
            savingSection: null, nationalId: refreshed ?? state.nationalId),
        'profile.identitySavedSuccess',
        isError: false,
      ));
    } catch (e) {
      emit(_feedback(state.copyWith(savingSection: null),
          _errorText(e, 'profile.identitySaveFailed'),
          isError: true));
    }
  }

  Future<void> saveEmergencyContact(Map<String, dynamic> body) async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) return _emitSignInRequired();

    emit(state.copyWith(savingSection: 'emergencyContact'));
    try {
      await _userService.addEmergencyContact(userId, body);
      final refreshed =
          await _safe(() => _userService.getEmergencyContact(userId));
      emit(_feedback(
        state.copyWith(
            savingSection: null,
            emergencyContact: refreshed ?? state.emergencyContact),
        'profile.identitySavedSuccess',
        isError: false,
      ));
    } catch (e) {
      emit(_feedback(state.copyWith(savingSection: null),
          _errorText(e, 'profile.identitySaveFailed'),
          isError: true));
    }
  }

  void _emitSignInRequired() =>
      emit(_feedback(state, 'profile.identitySignInRequired', isError: true));

  /// Resolves a user-facing error string. A [ServerException] already carries a
  /// human message (the backend message, surfaced by DioConsumer); anything else
  /// falls back to a localized key. We never use `e.toString()` here — that
  /// yields the useless "Instance of 'ServerException'".
  String _errorText(Object e, String fallbackKey) {
    if (e is ServerException && e.message.trim().isNotEmpty) return e.message;
    return fallbackKey;
  }

  IdentityVerificationState _feedback(
    IdentityVerificationState base,
    String message, {
    required bool isError,
  }) {
    return base.copyWith(
      message: message,
      messageIsError: isError,
      messageId: base.messageId + 1,
    );
  }

  /// Wraps a record fetch so a missing record (or transient error) yields null
  /// instead of failing the whole screen load.
  Future<Map<String, dynamic>?> _safe(
    Future<Map<String, dynamic>?> Function() fn,
  ) async {
    try {
      return await fn();
    } catch (_) {
      return null;
    }
  }
}
