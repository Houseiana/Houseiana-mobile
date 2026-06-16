import 'package:equatable/equatable.dart';

import 'package:houseiana_mobile_app/features/chat/data/models/chat_message.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatMessagesLoaded extends ChatState {
  final List<ChatMessage> messages;
  final String conversationId;
  final bool isSupport;

  const ChatMessagesLoaded({
    required this.messages,
    required this.conversationId,
    this.isSupport = false,
  });

  @override
  List<Object?> get props => [messages, conversationId, isSupport];
}

class ChatError extends ChatState {
  final String message;

  const ChatError({required this.message});

  @override
  List<Object?> get props => [message];
}
