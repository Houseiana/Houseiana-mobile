import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/models/notification_model.dart';
import 'package:houseiana_mobile_app/features/notifications/cubit/notifications_cubit.dart';
import 'package:houseiana_mobile_app/features/notifications/cubit/notifications_state.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('notifications.title'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        centerTitle: true,
        actions: [
          BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
              if (state is NotificationsLoaded && state.unreadCount > 0) {
                return TextButton(
                  onPressed: () =>
                      context.read<NotificationsCubit>().markAllAsRead(),
                  child: Text(
                    context.tr('notifications.markAllRead'),
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 14,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          if (state is NotificationsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            );
          }

          if (state is NotificationsError) {
            return _ErrorState(message: state.message);
          }

          if (state is NotificationsLoaded) {
            if (state.notifications.isEmpty) return const _EmptyState();

            return RefreshIndicator(
              onRefresh: () =>
                  context.read<NotificationsCubit>().loadNotifications(),
              color: AppColors.primaryColor,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: state.notifications.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 88, endIndent: 24),
                itemBuilder: (context, index) {
                  return _NotificationTile(
                    notification: state.notifications[index],
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final hasUnread = !notification.isRead;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        context.read<NotificationsCubit>().deleteNotification(notification.id);
      },
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: hasUnread
                ? AppColors.primaryColor.withValues(alpha: 0.1)
                : AppColors.ghostWhite,
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getIconForType(notification.type),
            color: hasUnread ? AppColors.primaryColor : AppColors.neutral600,
            size: 24,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: hasUnread ? AppColors.charcoal : AppColors.neutral600,
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
            if (notification.createdAt != null) ...[
              const SizedBox(height: 4),
              Text(
                _formatTime(context, notification.createdAt!),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.neutral600,
                ),
              ),
            ],
          ],
        ),
        onTap: () {
          if (hasUnread) {
            context.read<NotificationsCubit>().markAsRead(notification.id);
          }
        },
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'booking':
        return Icons.calendar_today;
      case 'message':
        return Icons.chat_bubble_outline;
      case 'payment':
        return Icons.payment;
      case 'review':
        return Icons.star_outline;
      case 'promo':
        return Icons.local_offer_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatTime(BuildContext context, DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return context.tr('notifications.minutesShort', args: {'n': diff.inMinutes});
    }
    if (diff.inHours < 24) {
      return context.tr('notifications.hoursShort', args: {'n': diff.inHours});
    }
    if (diff.inDays == 1) return context.tr('notifications.yesterday');
    if (diff.inDays < 7) {
      return context.tr('notifications.daysShort', args: {'n': diff.inDays});
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none,
              size: 40,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.tr('notifications.noNotifications'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('notifications.noNotificationsDescription'),
            style: const TextStyle(fontSize: 14, color: AppColors.neutral600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 60,
            color: AppColors.neutral400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                context.read<NotificationsCubit>().loadNotifications(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: AppColors.charcoal,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(context.tr('notifications.retry')),
          ),
        ],
      ),
    );
  }
}
