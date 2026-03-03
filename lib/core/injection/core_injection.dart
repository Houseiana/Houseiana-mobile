import 'package:dio/dio.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/network/api/dio_consumer.dart';
import 'package:houseiana_mobile_app/core/network/api/app_interceptors.dart';
import 'package:houseiana_mobile_app/core/network/connection_checker.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';

Future<void> initCore() async {
  // Dio
  sl.registerLazySingleton<Dio>(() => Dio());
  sl.registerLazySingleton<AppInterceptors>(() => AppInterceptors());
  sl.registerLazySingleton<ApiConsumer>(() => DioConsumer(client: sl()));

  // Connection
  sl.registerLazySingleton(() => InternetConnectionChecker.instance);
  sl.registerLazySingleton<ConnectionChecker>(
    () => ConnectionCheckerImpl(sl()),
  );

  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Session & API services
  sl.registerLazySingleton(() => UserSession(sl()));
  sl.registerLazySingleton(() => PropertyService(sl()));
  sl.registerLazySingleton(() => UserService(sl()));
}
