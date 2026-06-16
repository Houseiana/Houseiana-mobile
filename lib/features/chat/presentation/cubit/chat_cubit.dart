import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/features/chat/data/firestore_chat_service.dart';
import 'package:houseiana_mobile_app/features/chat/data/models/chat_message.dart';
import 'package:houseiana_mobile_app/features/chat/presentation/cubit/chat_state.dart';

/// Drives a single chat thread (host↔guest OR support), backed by Firestore —
/// the exact same transport the web app uses. Replaces the old REST/Socket.IO
/// implementation.
class ChatCubit extends Cubit<ChatState> {
  final FirestoreChatService _service;

  StreamSubscription<List<ChatMessage>>? _sub;

  String _conversationId = '';
  String _userId = '';
  String _userName = '';
  String _role = 'guest'; // guest | host
  String _type = 'GUEST_HOST'; // GUEST_HOST | SUPPORT

  ChatCubit({FirestoreChatService? service})
      : _service = service ?? sl<FirestoreChatService>(),
        super(ChatInitial());

  /// Begins streaming the conversation. For SUPPORT it lazily creates the
  /// thread doc (guest side); for GUEST_HOST the doc is created upstream by the
  /// Contact-Host flow, so we just subscribe.
  Future<void> start({
    required String conversationId,
    required String userId,
    required String userName,
    required String role,
    required String type,
    int limit = 100,
  }) async {
    _conversationId = conversationId;
    _userId = userId;
    _userName = userName;
    _role = role;
    _type = type;

    if (conversationId.isEmpty || userId.isEmpty) {
      emit(const ChatError(message: 'Invalid conversation'));
      return;
    }

    emit(ChatLoading());

    try {
      if (type == 'SUPPORT') {
        await _service.ensureSupportConversation(
          guestId: userId,
          guestName: userName,
        );
      }

      await _sub?.cancel();
      _sub = _service
          .watchMessages(conversationId, limit: limit)
          .listen(_onMessages, onError: _onError);
    } catch (e) {
      emit(ChatError(message: _friendly(e)));
    }
  }

  Future<void> send(String content) async {
    final text = content.trim();
    if (text.isEmpty || _conversationId.isEmpty || _userId.isEmpty) return;
    try {
      await _service.sendMessage(
        conversationId: _conversationId,
        type: _type,
        senderId: _userId,
        senderRole: _role,
        senderName: _userName,
        content: text,
      );
    } catch (e) {
      emit(ChatError(message: _friendly(e)));
    }
  }

  void _onMessages(List<ChatMessage> messages) {
    emit(ChatMessagesLoaded(
      messages: messages,
      conversationId: _conversationId,
      isSupport: _type == 'SUPPORT',
    ));
    _markReadIfNeeded(messages);
  }

  Future<void> _markReadIfNeeded(List<ChatMessage> messages) async {
    final hasIncomingUnread =
        messages.any((m) => !m.isRead && m.senderId != _userId);
    if (!hasIncomingUnread) return;
    try {
      await _service.markAllAsRead(
        conversationId: _conversationId,
        currentUserId: _userId,
        role: _role,
      );
    } catch (_) {
      // Best-effort; ignore.
    }
  }

  void _onError(Object error) {
    emit(ChatError(message: _friendly(error)));
  }

  String _friendly(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'permission-denied';
        case 'unavailable':
        case 'failed-to-get-document':
          return 'offline';
      }
    }
    return error.toString();
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
