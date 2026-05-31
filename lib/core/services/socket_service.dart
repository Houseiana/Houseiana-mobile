import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:houseiana_mobile_app/core/config/app_config.dart';

/// Socket.IO service for real-time chat and messaging.
/// Implements the same event protocol as the web client.
class SocketService {
  io.Socket? _socket;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();

  bool _isConnected = false;

  // ── Stream Accessors ──────────────────────────────────────────────────────

  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;
  Stream<Map<String, dynamic>> get onTyping => _typingController.stream;
  Stream<bool> get onConnectionStatus => _connectionStatusController.stream;
  bool get isConnected => _isConnected;

  // ── Connection ─────────────────────────────────────────────────────────────

  /// Connects to the Socket.IO server with optional auth token.
  void connect({String? authToken}) {
    final socketUrl = AppConfig.backendApiUrl.replaceFirst('/api', '');

    _socket = io.io(
      socketUrl,
      io.OptionBuilder()
          .setAuth({'token': authToken ?? ''})
          .setTransports(['websocket'])
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[Socket] Connected: ${_socket!.id}');
      _isConnected = true;
      _connectionStatusController.add(true);
    });

    _socket!.onDisconnect((reason) {
      debugPrint('[Socket] Disconnected: $reason');
      _isConnected = false;
      _connectionStatusController.add(false);
    });

    _socket!.onError((error) {
      debugPrint('[Socket] Error: $error');
    });

    // Listen for new messages
    _socket!.on('new_message', (data) {
      if (data is Map<String, dynamic>) {
        _messageController.add({
          'type': 'new_message',
          'data': data,
        });
      }
    });

    // Listen for message read events
    _socket!.on('message_read', (data) {
      if (data is Map<String, dynamic>) {
        _messageController.add({
          'type': 'message_read',
          'data': data,
        });
      }
    });

    // Listen for typing indicators
    _socket!.on('user_typing', (data) {
      if (data is Map<String, dynamic>) {
        _typingController.add({
          'type': 'typing',
          'data': data,
        });
      }
    });

    _socket!.on('user_stopped_typing', (data) {
      if (data is Map<String, dynamic>) {
        _typingController.add({
          'type': 'stopped_typing',
          'data': data,
        });
      }
    });

    _socket!.connect();
  }

  /// Disconnects from the Socket.IO server.
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  // ── Conversation Events ─────────────────────────────────────────────────

  /// Joins a conversation room.
  void joinConversation(String conversationId) {
    _socket?.emit('join_conversation', conversationId);
  }

  /// Leaves a conversation room.
  void leaveConversation(String conversationId) {
    _socket?.emit('leave_conversation', conversationId);
  }

  // ── Message Events ───────────────────────────────────────────────────────

  /// Sends a message in a conversation.
  void sendMessage({
    required String conversationId,
    required String content,
    String contentType = 'TEXT',
    List<Map<String, dynamic>>? attachments,
  }) {
    _socket?.emit('send_message', {
      'conversationId': conversationId,
      'content': content,
      'contentType': contentType,
      'attachments': attachments ?? [],
    });
  }

  /// Marks a message as read.
  void markAsRead({
    required String conversationId,
    required String messageId,
  }) {
    _socket?.emit('mark_as_read', {
      'conversationId': conversationId,
      'messageId': messageId,
    });
  }

  // ── Typing Indicators ─────────────────────────────────────────────────────

  /// Signals that the current user is typing in a conversation.
  void startTyping(String conversationId) {
    _socket?.emit('typing', conversationId);
  }

  /// Signals that the current user has stopped typing.
  void stopTyping(String conversationId) {
    _socket?.emit('stop_typing', conversationId);
  }

  // ── Cleanup ──────────────────────────────────────────────────────────────

  void dispose() {
    disconnect();
    _messageController.close();
    _typingController.close();
    _connectionStatusController.close();
  }
}
