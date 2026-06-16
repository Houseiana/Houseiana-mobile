import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/services/chat_service.dart';
import 'package:houseiana_mobile_app/core/services/socket_service.dart';
import 'package:houseiana_mobile_app/features/chat/data/firestore_chat_service.dart';
import 'package:houseiana_mobile_app/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:houseiana_mobile_app/features/chat/presentation/cubit/conversations_cubit.dart';

void initChat() {
  // Firestore-backed chat (web parity) — the live transport for messaging.
  sl.registerLazySingleton(() => FirestoreChatService());

  // Legacy REST/Socket.IO chat services — kept registered but no longer used by
  // the chat UI (the transport is now Firestore, matching the web app).
  sl.registerLazySingleton(() => SocketService());
  sl.registerLazySingleton(() => ChatService(sl<ApiConsumer>(), dio: sl()));

  // Cubits - factories since they hold per-screen state.
  sl.registerFactory(() => ChatCubit(service: sl()));
  sl.registerFactory(() => ConversationsCubit(service: sl()));
}
