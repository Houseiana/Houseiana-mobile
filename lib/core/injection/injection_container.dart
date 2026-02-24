import 'package:get_it/get_it.dart';
import 'package:houseiana_mobile_app/core/injection/core_injection.dart';
import 'package:houseiana_mobile_app/core/injection/auth_injection.dart';
import 'package:houseiana_mobile_app/core/injection/splash_injection.dart';

final GetIt sl = GetIt.instance;

Future<void> init() async {
  // Core
  await initCore();

  // Features
  initAuth();
  initSplash();
}
