import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/google_auth_service.dart';
import 'package:houseiana_mobile_app/core/services/apple_auth_service.dart';
import 'package:houseiana_mobile_app/features/auth/presentation/cubit/auth_cubit.dart';

void initAuth() {
  sl.registerLazySingleton(() => GoogleAuthService());
  sl.registerLazySingleton(() => AppleAuthService());

  sl.registerFactory(() => AuthCubit(
        clerkService: sl(),
        appleAuthService: sl(),
      ));
}
