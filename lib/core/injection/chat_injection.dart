import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/services/chat_service.dart';
import 'package:houseiana_mobile_app/core/services/socket_service.dart';
import 'package:houseiana_mobile_app/features/chat/presentation/cubit/chat_cubit.dart';

void initChat() {
  // Services
  sl.registerLazySingleton(() => SocketService());
  sl.registerLazySingleton((() => ChatService(sl<ApiConsumer>(), dio: sl())));

  // Cubit - factory since it holds state
  sl.registerFactory(() => ChatCubit(
        chatService: sl(),
        socketService: sl(),
      ));
}
