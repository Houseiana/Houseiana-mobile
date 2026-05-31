import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/services/version_check_service.dart';
import 'package:houseiana_mobile_app/features/splash/presentation/cubit/splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  final VersionCheckService _versionCheckService;

  SplashCubit(this._versionCheckService) : super(const SplashInitial());

  Future<void> checkAppVersion() async {
    emit(const SplashLoading());
    try {
      final result = await _versionCheckService.checkVersion();
      if (result.forceUpdate) {
        emit(SplashForceUpdate(result.updateUrl));
      } else {
        emit(const SplashReady());
      }
    } catch (e) {
      debugPrint('[VersionCheck] failed, continuing (fail-open): $e');
      emit(const SplashReady());
    }
  }
}
