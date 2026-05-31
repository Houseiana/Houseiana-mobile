import 'package:get_it/get_it.dart';
import 'package:houseiana_mobile_app/core/injection/core_injection.dart';
import 'package:houseiana_mobile_app/core/injection/auth_injection.dart';
import 'package:houseiana_mobile_app/core/injection/splash_injection.dart';
import 'package:houseiana_mobile_app/core/injection/booking_injection.dart';
import 'package:houseiana_mobile_app/core/injection/chat_injection.dart';
import 'package:houseiana_mobile_app/core/injection/i18n_injection.dart';
import 'package:houseiana_mobile_app/core/injection/properties_injection.dart';
import 'package:houseiana_mobile_app/core/injection/host_injection.dart';
import 'package:houseiana_mobile_app/core/injection/notifications_injection.dart';
import 'package:houseiana_mobile_app/core/injection/profile_injection.dart';
import 'package:houseiana_mobile_app/core/injection/support_injection.dart';

final GetIt sl = GetIt.instance;

Future<void> init() async {
  // Core
  await initCore();

  // Features
  initAuth();
  initSplash();
  initBooking();
  initChat();
  initI18n();
  initProperties();
  await initHost();
  await initNotifications();
  await initProfile();
  initSupport();
}
