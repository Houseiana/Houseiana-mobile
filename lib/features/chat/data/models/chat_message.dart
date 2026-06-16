import 'package:cloud_firestore/cloud_firestore.dart';

/// A single chat message, mirroring the exact Firestore document shape written
/// by the web app (`conversations/{id}/messages/{autoId}`).
///
/// Web reference: `src/features/chat/hooks/useFirebaseChat.ts` (sendMessage).
class ChatMessage {
  final String id;
  final String content;
  final String contentType; // TEXT | IMAGE | FILE | SYSTEM
  final String senderId;
  final String senderRole; // guest | host | admin
  final String senderName;
  final bool isRead;
  final String status; // sent | delivered | read | ...
  final DateTime createdAt;
  final DateTime? readAt;
  final bool isDeleted;
  final bool isEdited;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.contentType,
    required this.senderId,
    required this.senderRole,
    required this.senderName,
    required this.isRead,
    required this.status,
    required this.createdAt,
    this.readAt,
    required this.isDeleted,
    required this.isEdited,
  });

  factory ChatMessage.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return ChatMessage(
      id: doc.id,
      content: (d['content'] ?? '').toString(),
      contentType: (d['contentType'] ?? 'TEXT').toString(),
      senderId: (d['senderId'] ?? '').toString(),
      senderRole: (d['senderRole'] ?? '').toString(),
      senderName: (d['senderName'] ?? '').toString(),
      isRead: d['isRead'] == true,
      status: (d['status'] ?? 'sent').toString(),
      createdAt: parseFirestoreTimestamp(d['createdAt']),
      readAt: d['readAt'] == null ? null : parseFirestoreTimestamp(d['readAt']),
      isDeleted: d['isDeleted'] == true,
      isEdited: d['isEdited'] == true,
    );
  }
}

/// Safely parses any Firestore timestamp representation into a [DateTime].
///
/// Mirrors the web `parseFirestoreTimestamp` helper: a null value (a pending
/// `serverTimestamp()` local write that hasn't resolved yet) is treated as
/// "now" so just-sent messages render immediately.
DateTime parseFirestoreTimestamp(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is Map) {
    final seconds = value['seconds'];
    if (seconds is num) {
      final nanos = value['nanoseconds'];
      final ns = nanos is num ? nanos.toInt() : 0;
      return DateTime.fromMillisecondsSinceEpoch(
          seconds.toInt() * 1000 + (ns / 1000000).round());
    }
  }
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}
