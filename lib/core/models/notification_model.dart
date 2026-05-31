import 'package:equatable/equatable.dart';

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
