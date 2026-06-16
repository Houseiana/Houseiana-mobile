import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:houseiana_mobile_app/core/models/notification_model.dart';

/// Firestore-backed notifications, mirroring the web app exactly.
///
/// The web app reads notifications straight from the Cloud Firestore
/// `notifications` collection via the client SDK — there is NO backend REST API
/// for notification content. This service reads/writes the SAME collection the
/// web hook uses (`src/features/notifications/hooks/useNotifications.ts`), keyed
/// by the Clerk user id, so a user sees identical notifications on web and
/// mobile (same Firebase project: `houseiana`).
class FirestoreNotificationService {
  final FirebaseFirestore _db;

  FirestoreNotificationService([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection('notifications');

  /// Realtime stream of the user's notifications, newest first.
  ///
  /// Mirrors the web `query(notificationsRef, where('userId','==',uid),
  /// limit(20))` + client-side sort by `createdAt` desc. Sorting client-side
  /// (instead of `orderBy`) keeps this a single-field query, so NO Firestore
  /// composite index is required.
  Stream<List<NotificationModel>> watchNotifications(String userId,
      {int limit = 20}) {
    return _notifications
        .where('userId', isEqualTo: userId)
        .limit(limit)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => NotificationModel.fromFirestore(d.id, d.data()))
          .toList();
      list.sort((a, b) {
        final at = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final bt = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return bt.compareTo(at);
      });
      return list;
    });
  }

  /// Marks a single notification as read (web parity:
  /// `updateDoc(doc(db,'notifications',id), { isRead: true })`).
  Future<void> markAsRead(String notificationId) async {
    await _notifications.doc(notificationId).update({'isRead': true});
  }

  /// Marks the given notifications as read in one batch. The caller passes the
  /// already-known unread ids (same as the web, which loops over the unread
  /// notifications it holds in memory) so no `userId + isRead` composite query
  /// — and therefore no index — is needed.
  Future<void> markAllAsRead(List<String> notificationIds) async {
    if (notificationIds.isEmpty) return;
    final batch = _db.batch();
    for (final id in notificationIds) {
      batch.update(_notifications.doc(id), {'isRead': true});
    }
    await batch.commit();
  }

  /// Removes a notification. The web app has no delete, but the mobile list
  /// supports swipe-to-dismiss; this hard-deletes the doc. If Firestore rules
  /// reject the delete the change is simply reverted by the next snapshot.
  Future<void> deleteNotification(String notificationId) async {
    await _notifications.doc(notificationId).delete();
  }
}
