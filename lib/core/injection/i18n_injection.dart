import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/i18n/locale_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void initI18n() {
  // Cubit
  sl.registerFactory(() => LocaleCubit(sl<SharedPreferences>()));
}
