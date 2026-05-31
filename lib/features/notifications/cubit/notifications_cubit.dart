import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/services/notification_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/notifications/cubit/notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationService _notificationService;
  final UserSession _userSession;

  NotificationsCubit(this._notificationService, this._userSession)
      : super(NotificationsInitial());

  Future<void> loadNotifications() async {
    emit(NotificationsLoading());
    final userId = _userSession.userId;
    if (userId == null) {
      emit(const NotificationsError('User not found'));
      return;
    }
    final notifications = await _notificationService.getNotifications(userId);
    emit(NotificationsLoaded(notifications));
  }

  Future<void> markAsRead(String notificationId) async {
    final currentState = state;
    if (currentState is! NotificationsLoaded) return;
    final notifications = currentState.notifications;

    await _notificationService.markAsRead(notificationId);
    final updated = notifications.map((n) {
      if (n.id == notificationId) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    emit(NotificationsLoaded(updated));
  }

  Future<void> markAllAsRead() async {
    final currentState = state;
    if (currentState is! NotificationsLoaded) return;
    final userId = _userSession.userId;
    if (userId == null) return;

    await _notificationService.markAllAsRead(userId);
    final updated = currentState.notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    emit(NotificationsLoaded(updated));
  }

  Future<void> deleteNotification(String notificationId) async {
    final currentState = state;
    if (currentState is! NotificationsLoaded) return;

    await _notificationService.deleteNotification(notificationId);
    final updated = currentState.notifications
        .where((n) => n.id != notificationId)
        .toList();
    emit(NotificationsLoaded(updated));
  }
}
