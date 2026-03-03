import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/clerk_service.dart';
import 'package:houseiana_mobile_app/features/auth/presentation/cubit/auth_cubit.dart';

void initAuth() {
  // Services
  sl.registerLazySingleton(() => ClerkService());

  // Cubit
  sl.registerFactory(() => AuthCubit(clerkService: sl()));
}
