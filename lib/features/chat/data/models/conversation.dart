import 'package:cloud_firestore/cloud_firestore.dart';

import 'chat_message.dart';

/// A conversation document, mirroring the exact Firestore shape written by the
/// web app (`conversations/{id}`). One top-level collection holds BOTH chat
/// types, discriminated by [type]: `GUEST_HOST` and `SUPPORT`.
///
/// `unreadCounts` is a map keyed by ROLE string ("guest"/"host" or
/// "guest"/"admin"), never by userId — matching the web.
class Conversation {
  final String id;
  final String type; // GUEST_HOST | SUPPORT
  final String title;
  final String hostId;
  final String guestId;
  final String hostName;
  final String hostAvatar;
  final String guestName;
  final String guestAvatar;
  final String propertyId;
  final String propertyTitle;
  final String propertyImage;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCounts;
  final bool isArchived;

  const Conversation({
    required this.id,
    required this.type,
    required this.title,
    required this.hostId,
    required this.guestId,
    required this.hostName,
    required this.hostAvatar,
    required this.guestName,
    required this.guestAvatar,
    required this.propertyId,
    required this.propertyTitle,
    required this.propertyImage,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCounts,
    required this.isArchived,
  });

  bool get isSupport => type == 'SUPPORT';

  /// The role the given user plays in this conversation.
  String roleFor(String userId) {
    if (isSupport) return 'guest';
    return hostId == userId ? 'host' : 'guest';
  }

  /// Unread count for the given user (their role), with a defensive fallback to
  /// the pre-migration flat fields (`unreadCountHost` / `unreadCountGuest`).
  int unreadFor(String userId) => unreadCounts[roleFor(userId)] ?? 0;

  /// Display name of the OTHER party from the given user's perspective.
  String otherName(String userId) =>
      roleFor(userId) == 'host' ? guestName : hostName;

  String otherAvatar(String userId) =>
      roleFor(userId) == 'host' ? guestAvatar : hostAvatar;

  factory Conversation.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};

    // unreadCounts: prefer the role-keyed map; tolerate legacy flat fields.
    final rawCounts = d['unreadCounts'];
    final counts = <String, int>{};
    if (rawCounts is Map) {
      rawCounts.forEach((k, v) {
        final n = v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0;
        counts[k.toString()] = n;
      });
    }
    if (!counts.containsKey('host') && d['unreadCountHost'] != null) {
      counts['host'] =
          int.tryParse(d['unreadCountHost'].toString()) ?? 0;
    }
    if (!counts.containsKey('guest') && d['unreadCountGuest'] != null) {
      counts['guest'] =
          int.tryParse(d['unreadCountGuest'].toString()) ?? 0;
    }

    final metadata =
        d['metadata'] is Map ? Map<String, dynamic>.from(d['metadata']) : const {};

    String pick(String key) =>
        (d[key] ?? metadata[key] ?? '').toString();

    return Conversation(
      id: doc.id,
      type: (d['type'] ?? 'GUEST_HOST').toString(),
      title: (d['title'] ?? '').toString(),
      hostId: pick('hostId'),
      guestId: pick('guestId'),
      hostName: pick('hostName'),
      hostAvatar: pick('hostAvatar'),
      guestName: pick('guestName'),
      guestAvatar: pick('guestAvatar'),
      propertyId: pick('propertyId'),
      propertyTitle: pick('propertyTitle'),
      propertyImage: pick('propertyImage'),
      lastMessage: (d['lastMessage'] ?? '').toString(),
      lastMessageTime: d['lastMessageTime'] == null
          ? null
          : parseFirestoreTimestamp(d['lastMessageTime']),
      unreadCounts: counts,
      isArchived: d['isArchived'] == true,
    );
  }

  /// Arguments passed to the chat thread screen via the named route.
  Map<String, dynamic> toArgs(String userId) => {
        'id': id,
        'type': type,
        'hostId': hostId,
        'guestId': guestId,
        'name': otherName(userId),
        'avatar': otherAvatar(userId),
        'property': propertyTitle,
      };
}
