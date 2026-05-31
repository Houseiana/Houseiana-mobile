import 'package:houseiana_mobile_app/core/models/notification_model.dart';
import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';

class NotificationService {
  final ApiConsumer _api;

  NotificationService(this._api);

  Future<List<NotificationModel>> getNotifications(String userId) async {
    final response = await _api.get('/notification-manager/$userId');
    return _list(response);
  }

  Future<bool> markAsRead(String notificationId) async {
    await _api.patch('/notification-manager/$notificationId/read');
    return true;
  }

  Future<bool> deleteNotification(String notificationId) async {
    await _api.delete('/notification-manager/$notificationId');
    return true;
  }

  Future<bool> markAllAsRead(String userId) async {
    await _api.patch('/notification-manager/$userId/read-all');
    return true;
  }

  List<NotificationModel> _list(dynamic response) {
    if (response == null) return [];
    dynamic raw = response;
    if (raw is Map) raw = raw['data'] ?? raw['items'] ?? raw;
    if (raw is Map) {
      raw = raw['items'] ??
          raw['data'] ??
          raw.values.firstWhere(
            (v) => v is List,
            orElse: () => [],
          );
    }
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map((e) => NotificationModel.fromJson(e))
          .toList();
    }
    return [];
  }
}
