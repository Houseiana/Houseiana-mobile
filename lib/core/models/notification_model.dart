import 'package:equatable/equatable.dart';
import 'package:houseiana_mobile_app/features/chat/data/models/chat_message.dart'
    show parseFirestoreTimestamp;

class NotificationModel extends Equatable {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final String? data;
  final bool isRead;
  final DateTime? createdAt;
  final DateTime? readAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.isRead = false,
    this.createdAt,
    this.readAt,
  });

  /// Builds a model from a Firestore `notifications` document, mirroring the
  /// shape the web app reads (`src/features/notifications/hooks/useNotifications.ts`):
  /// `{ userId, title, message, type, isRead, createdAt, link, data }`.
  factory NotificationModel.fromFirestore(String id, Map<String, dynamic> data) {
    return NotificationModel(
      id: id,
      userId: (data['userId'] ?? data['user_id'] ?? '').toString(),
      type: (data['type'] ?? 'general').toString(),
      title: (data['title'] ?? '').toString(),
      body: (data['body'] ?? data['message'] ?? '').toString(),
      data: data['link']?.toString() ?? data['data']?.toString(),
      isRead: data['isRead'] == true || data['read'] == true,
      createdAt: data['createdAt'] == null
          ? null
          : parseFirestoreTimestamp(data['createdAt']),
      readAt:
          data['readAt'] == null ? null : parseFirestoreTimestamp(data['readAt']),
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      type: json['type'] as String? ?? 'general',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? json['message'] as String? ?? '',
      data: json['data'] as String?,
      isRead: json['isRead'] as bool? ?? json['read'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'userId': userId,
        'type': type,
        'title': title,
        'body': body,
        'data': data,
        'isRead': isRead,
        'createdAt': createdAt?.toIso8601String(),
        'readAt': readAt?.toIso8601String(),
      };

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? body,
    String? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, type, title, body, isRead];
}
