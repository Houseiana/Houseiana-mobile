import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/services/notification_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/notifications/cubit/notifications_cubit.dart';

Future<void> initNotifications() async {
  sl.registerLazySingleton(() => NotificationService(sl<ApiConsumer>()));
  sl.registerFactory(() => NotificationsCubit(
        sl<NotificationService>(),
        sl<UserSession>(),
      ));
}
