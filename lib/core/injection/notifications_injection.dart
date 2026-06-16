import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/firestore_notification_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/notifications/cubit/notifications_cubit.dart';

Future<void> initNotifications() async {
  sl.registerLazySingleton(() => FirestoreNotificationService());
  sl.registerFactory(() => NotificationsCubit(
        sl<FirestoreNotificationService>(),
        sl<UserSession>(),
      ));
}
