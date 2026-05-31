import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/version_check_service.dart';
import 'package:houseiana_mobile_app/features/splash/presentation/cubit/splash_cubit.dart';

void initSplash() {
  sl.registerLazySingleton(() => VersionCheckService(sl()));
  sl.registerFactory(() => SplashCubit(sl()));
}
