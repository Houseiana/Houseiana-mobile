import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/models/notification_model.dart';
import 'package:houseiana_mobile_app/core/services/firestore_notification_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/notifications/cubit/notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final FirestoreNotificationService _notificationService;
  final UserSession _userSession;

  StreamSubscription<List<NotificationModel>>? _sub;

  NotificationsCubit(this._notificationService, this._userSession)
      : super(NotificationsInitial());

  /// Subscribes to the realtime Firestore notifications stream (web parity).
  /// Returns a Future that completes on the first emission/error so the
  /// pull-to-refresh gesture still has something to await.
  Future<void> loadNotifications() async {
    final userId = _userSession.userId;
    if (userId == null) {
      emit(const NotificationsError('notifications.loadError'));
      return;
    }

    // Keep the existing list visible during a manual refresh; only show the
    // spinner on the very first load.
    if (state is! NotificationsLoaded) emit(NotificationsLoading());

    await _sub?.cancel();
    final firstEvent = Completer<void>();

    _sub = _notificationService.watchNotifications(userId).listen(
      (notifications) {
        emit(NotificationsLoaded(notifications));
        if (!firstEvent.isCompleted) firstEvent.complete();
      },
      onError: (_) {
        // Without surfacing the error the screen would sit on a spinner forever.
        emit(const NotificationsError('notifications.loadError'));
        if (!firstEvent.isCompleted) firstEvent.complete();
      },
    );

    return firstEvent.future;
  }

  /// Marks one notification as read. Firestore's local latency compensation
  /// updates the snapshot immediately, so no manual optimistic emit is needed;
  /// a rejected write is reverted by the next snapshot.
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
    } catch (_) {/* snapshot reflects the source of truth */}
  }

  Future<void> markAllAsRead() async {
    final currentState = state;
    if (currentState is! NotificationsLoaded) return;
    final unreadIds = currentState.notifications
        .where((n) => !n.isRead)
        .map((n) => n.id)
        .toList();
    if (unreadIds.isEmpty) return;

    try {
      await _notificationService.markAllAsRead(unreadIds);
    } catch (_) {/* snapshot reflects the source of truth */}
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
    } catch (_) {/* snapshot reflects the source of truth */}
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
