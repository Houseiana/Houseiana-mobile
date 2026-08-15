import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/theme/theme_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void initTheme() {
  // Cubit
  sl.registerFactory(() => ThemeCubit(sl<SharedPreferences>()));
}
