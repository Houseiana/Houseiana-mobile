import 'package:dio/dio.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/network/api/dio_consumer.dart';
import 'package:houseiana_mobile_app/core/network/api/app_interceptors.dart';
import 'package:houseiana_mobile_app/core/network/api/auth_interceptor.dart';
import 'package:houseiana_mobile_app/core/network/api/lang_interceptor.dart';
import 'package:houseiana_mobile_app/core/network/connection_checker.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/core/services/host_service.dart';
import 'package:houseiana_mobile_app/core/services/clerk_service.dart';
import 'package:houseiana_mobile_app/core/services/support_service.dart';

Future<void> initCore() async {
  // SharedPreferences (needed first for UserSession)
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Session & Core Services
  sl.registerLazySingleton(() => UserSession(sl()));
  sl.registerLazySingleton(() => ClerkService(sl<SharedPreferences>()));

  // Dio — with interceptors attached at creation
  final dio = Dio();
  sl.registerLazySingleton<Dio>(() => dio);

  // Interceptors
  sl.registerLazySingleton<AppInterceptors>(() => AppInterceptors());
  sl.registerLazySingleton<AuthInterceptor>(
    () => AuthInterceptor(sl(), sl()),
  );
  sl.registerLazySingleton<LangInterceptor>(
    () => LangInterceptor(sl<SharedPreferences>()),
  );

  // Attach interceptors to Dio
  dio.interceptors.addAll([
    sl<AppInterceptors>(),
    sl<LangInterceptor>(),
    sl<AuthInterceptor>(),
  ]);

  // API Consumer
  sl.registerLazySingleton<ApiConsumer>(() => DioConsumer(client: dio));

  // Connection
  sl.registerLazySingleton(() => InternetConnectionChecker.instance);
  sl.registerLazySingleton<ConnectionChecker>(
    () => ConnectionCheckerImpl(sl()),
  );

  // API Services
  sl.registerLazySingleton(() => PropertyService(sl()));
  sl.registerLazySingleton(() => UserService(sl()));
  sl.registerLazySingleton(() => HostService(dio: sl()));
  sl.registerLazySingleton(() => SupportService(dio: sl()));
}
