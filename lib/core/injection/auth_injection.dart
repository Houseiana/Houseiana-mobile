import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/features/auth/presentation/cubit/auth_cubit.dart';

void initAuth() {
  // Cubit
  sl.registerFactory(() => AuthCubit());
}
