import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/features/chat/presentation/cubit/chat_state.dart';
import 'package:houseiana_mobile_app/core/services/chat_service.dart';
import 'package:houseiana_mobile_app/core/services/socket_service.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatService _chatService;
  final SocketService _socketService;

  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  StreamSubscription<Map<String, dynamic>>? _typingSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  String? _currentUserId;
  String? _currentConversationId;

  ChatCubit({
    ChatService? chatService,
    SocketService? socketService,
  })  : _chatService = chatService ?? sl<ChatService>(),
        _socketService = socketService ?? sl<SocketService>(),
        super(ChatInitial());

  /// Connects to the socket server with the user's auth token.
  void connectToSocket({required String authToken, String? userId}) {
    _currentUserId = userId;
    _socketService.connect(authToken: authToken);

    _connectionSubscription = _socketService.onConnectionStatus.listen((isConnected) {
      if (isConnected && _currentConversationId != null) {
        _socketService.joinConversation(_currentConversationId!);
      }
    });

    _messageSubscription = _socketService.onMessage.listen((event) {
      final type = event['type'] as String?;
      final data = event['data'] as Map<String, dynamic>?;

      if (type == 'new_message' && data != null) {
        _handleNewMessage(data);
      } else if (type == 'message_read' && data != null) {
        _handleMessageRead(data);
      }
    });

    _typingSubscription = _socketService.onTyping.listen((event) {
      final type = event['type'] as String?;
      final data = event['data'] as Map<String, dynamic>?;

      if (data != null) {
        if (type == 'typing') {
          emit(ChatTypingIndicatorState(
            conversationId: data['conversationId']?.toString() ?? '',
            userId: data['userId']?.toString() ?? '',
            userName: data['userName']?.toString() ?? '',
          ));
        }
      }
    });
  }

  void setCurrentUser(String? userId) {
    _currentUserId = userId;
  }

  /// Disconnects from the socket server.
  void disconnectFromSocket() {
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _connectionSubscription?.cancel();
    _socketService.disconnect();
  }

  /// Loads all conversations for a user.
  Future<void> getChats() async {
    emit(ChatLoading());
    try {
      if (_currentUserId == null) {
        emit(const ChatsLoaded(chats: []));
        return;
      }

      final conversations = await _chatService.getConversations(_currentUserId!);
      emit(ChatsLoaded(chats: conversations));
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  /// Loads messages for a specific conversation.
  Future<void> getChatMessages(String conversationId) async {
    emit(ChatLoading());
    try {
      _currentConversationId = conversationId;

      // Join the conversation room for real-time updates
      if (_socketService.isConnected) {
        _socketService.joinConversation(conversationId);
      }

      // Load message history
      final messages = await _chatService.getMessages(conversationId);
      emit(ChatMessagesLoaded(
        messages: messages,
        conversationId: conversationId,
      ));
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  /// Sends a message in the current conversation.
  Future<void> sendMessage(String conversationId, String content) async {
    try {
      if (_currentUserId == null) return;

      // Send via socket for real-time delivery
      if (_socketService.isConnected) {
        _socketService.sendMessage(
          conversationId: conversationId,
          content: content,
        );
      } else {
        // Fallback to REST API
        await _chatService.sendMessage(
          conversationId: conversationId,
          senderId: _currentUserId!,
          content: content,
        );
      }
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  /// Sends a typing indicator.
  void sendTypingIndicator(String conversationId) {
    if (_socketService.isConnected) {
      _socketService.startTyping(conversationId);
    }
  }

  /// Stops the typing indicator.
  void stopTypingIndicator(String conversationId) {
    if (_socketService.isConnected) {
      _socketService.stopTyping(conversationId);
    }
  }

  /// Marks a message as read.
  void markAsRead(String conversationId, String messageId) {
    if (_socketService.isConnected) {
      _socketService.markAsRead(
        conversationId: conversationId,
        messageId: messageId,
      );
    }
  }

  /// Creates a new conversation with a host.
  Future<String?> createConversation({
    required String propertyId,
    required String hostId,
    required String guestId,
    String? initialMessage,
  }) async {
    try {
      final result = await _chatService.createConversation(
        propertyId: propertyId,
        hostId: hostId,
        guestId: guestId,
        initialMessage: initialMessage,
      );

      if (result != null) {
        final data = result['data'] is Map ? result['data'] as Map : result;
        return data['conversationId']?.toString() ??
            data['_id']?.toString() ??
            data['id']?.toString();
      }
      return null;
    } catch (e) {
      emit(ChatError(message: e.toString()));
      return null;
    }
  }

  // ── Socket Event Handlers ───────────────────────────────────────────────

  void _handleNewMessage(Map<String, dynamic> data) {
    final currentState = state;
    if (currentState is ChatMessagesLoaded &&
        currentState.conversationId == data['conversationId']) {
      // Add message to the list
      final newMessage = data['message'] as Map<String, dynamic>?;
      if (newMessage != null) {
        final updatedMessages = [...currentState.messages, newMessage];
        emit(ChatMessagesLoaded(
          messages: updatedMessages,
          conversationId: currentState.conversationId,
        ));
      }
    }
  }

  void _handleMessageRead(Map<String, dynamic> data) {
    final currentState = state;
    if (currentState is ChatMessagesLoaded &&
        currentState.conversationId == data['conversationId']) {
      // Update message as read
      final updatedMessages = currentState.messages.map((msg) {
        if (msg['id'] == data['messageId']) {
          return {...msg, 'isRead': true, 'readAt': data['readAt']};
        }
        return msg;
      }).toList();

      emit(ChatMessagesLoaded(
        messages: updatedMessages,
        conversationId: currentState.conversationId,
      ));
    }
  }

  @override
  Future<void> close() {
    disconnectFromSocket();
    return super.close();
  }
}
