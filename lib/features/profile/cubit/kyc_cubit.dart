import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/profile/cubit/kyc_state.dart';

class KycCubit extends Cubit<KycState> {
  final UserService _userService;
  final UserSession _session;

  KycCubit(this._userService, this._session) : super(KycInitial());

  void goToStep(int step) {
    if (state is KycInProgress) {
      emit((state as KycInProgress).copyWith(currentStep: step));
    } else {
      emit(KycInProgress(currentStep: step));
    }
  }

  void setDocumentType(String type) {
    if (state is KycInProgress) {
      emit((state as KycInProgress).copyWith(documentType: type));
    } else {
      emit(KycInProgress(documentType: type));
    }
  }

  void setIdNumber(String idNumber) {
    if (state is KycInProgress) {
      emit((state as KycInProgress).copyWith(idNumber: idNumber));
    } else {
      emit(KycInProgress(idNumber: idNumber));
    }
  }

  void setFrontImage(String path) {
    if (state is KycInProgress) {
      emit((state as KycInProgress).copyWith(frontImagePath: path));
    } else {
      emit(KycInProgress(frontImagePath: path));
    }
  }

  void setBackImage(String path) {
    if (state is KycInProgress) {
      emit((state as KycInProgress).copyWith(backImagePath: path));
    } else {
      emit(KycInProgress(backImagePath: path));
    }
  }

  void setSelfie(String path) {
    if (state is KycInProgress) {
      emit((state as KycInProgress).copyWith(selfiePath: path));
    } else {
      emit(KycInProgress(selfiePath: path));
    }
  }

  Future<void> submitVerification() async {
    final userId = _session.userId;
    if (userId == null) {
      emit(const KycError('Not logged in'));
      return;
    }

    final current =
        state is KycInProgress ? state as KycInProgress : KycInProgress();
    emit(KycSubmitting());

    try {
      await _userService.updatePassport(userId, {
        'documentType': current.documentType,
        if (current.idNumber.isNotEmpty) 'idNumber': current.idNumber,
        'status': 'PENDING',
      });
      emit(KycSuccess());
    } catch (e) {
      emit(KycError(e.toString()));
    }
  }
}
