import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/features/chat/presentation/cubit/chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit() : super(ChatInitial());

  Future<void> getChats() async {
    emit(ChatLoading());
    try {
      // TODO: Implement actual API call
      await Future.delayed(const Duration(seconds: 1));
      emit(const ChatsLoaded(chats: []));
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  Future<void> getChatMessages(String chatId) async {
    emit(ChatLoading());
    try {
      // TODO: Implement actual API call
      await Future.delayed(const Duration(seconds: 1));
      emit(const ChatMessagesLoaded(messages: []));
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  Future<void> sendMessage(String chatId, String content) async {
    try {
      // TODO: Implement actual API call
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }
}
