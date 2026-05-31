import 'package:equatable/equatable.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatsLoaded extends ChatState {
  final List<dynamic> chats;

  const ChatsLoaded({required this.chats});

  @override
  List<Object?> get props => [chats];
}

class ChatMessagesLoaded extends ChatState {
  final List<dynamic> messages;
  final String? conversationId;

  const ChatMessagesLoaded({
    required this.messages,
    this.conversationId,
  });

  @override
  List<Object?> get props => [messages, conversationId];
}

class ChatTypingIndicatorState extends ChatState {
  final String conversationId;
  final String userId;
  final String userName;

  const ChatTypingIndicatorState({
    required this.conversationId,
    required this.userId,
    required this.userName,
  });

  @override
  List<Object?> get props => [conversationId, userId, userName];
}

class ChatError extends ChatState {
  final String message;

  const ChatError({required this.message});

  @override
  List<Object?> get props => [message];
}
