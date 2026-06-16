import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/chat_message.dart';
import 'models/conversation.dart';

/// Firestore-backed chat transport, mirroring the web app exactly.
///
/// The web app's chat (both host↔guest and user↔admin support) runs entirely on
/// Cloud Firestore via the client SDK — there is NO backend REST API for chat
/// content. This service reads/writes the SAME `conversations` collection +
/// `messages` subcollection the web hooks use, keyed by the Clerk user id, so
/// threads line up across web and mobile (same Firebase project: `houseiana`).
///
/// Web references:
/// - `src/features/chat/hooks/useFirebaseChat.ts` (host↔guest)
/// - `src/features/chat/hooks/useSupportChat.ts` (user↔admin support)
/// - `src/features/chat/services/chat-conversation.service.ts`
class FirestoreChatService {
  final FirebaseFirestore _db;

  FirestoreChatService([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _db.collection('conversations');

  CollectionReference<Map<String, dynamic>> _messagesRef(String conversationId) =>
      _conversations.doc(conversationId).collection('messages');

  // ── Conversation id schemes (deterministic, web parity) ──────────────────

  /// One support thread per user, exactly like the web `support_{guestId}_chat`
  /// so the mobile user lands in the thread the web admin console answers.
  String supportConversationId(String guestId) => 'support_${guestId}_chat';

  /// Deterministic host↔guest id. Web's live flow keys by trip
  /// (`trip_{tripId}_chat`); mobile's entry points are property/host based, so
  /// we key by property+guest (or host+guest when there is no property) to
  /// guarantee a single thread per pair and avoid duplicates.
  String guestHostConversationId({
    required String hostId,
    required String guestId,
    String? propertyId,
  }) {
    if (propertyId != null && propertyId.isNotEmpty) {
      return 'prop_${propertyId}_${guestId}_chat';
    }
    return 'host_${hostId}_${guestId}_chat';
  }

  // ── Messages ─────────────────────────────────────────────────────────────

  /// Realtime stream of a conversation's messages, ordered oldest→newest.
  /// Mirrors the web `onSnapshot(query(messagesRef, orderBy('createdAt','asc'),
  /// limit(...)))`. Pending (just-sent) messages have a null serverTimestamp;
  /// they are parsed as "now" and re-sorted client-side so they stay at the
  /// bottom instead of jumping to the top.
  Stream<List<ChatMessage>> watchMessages(String conversationId,
      {int limit = 100}) {
    return _messagesRef(conversationId)
        .orderBy('createdAt')
        .limit(limit)
        .snapshots()
        .map((snap) {
      final msgs = snap.docs.map(ChatMessage.fromDoc).toList();
      msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return msgs;
    });
  }

  /// Sends a message and updates the parent conversation, mirroring the web
  /// `sendMessage`: add the message doc, then merge `lastMessage`,
  /// `lastMessageTime`, and atomically increment the OTHER role's unread count.
  Future<void> sendMessage({
    required String conversationId,
    required String type, // GUEST_HOST | SUPPORT
    required String senderId,
    required String senderRole, // guest | host | admin
    required String senderName,
    required String content,
    String contentType = 'TEXT',
  }) async {
    final convRef = _conversations.doc(conversationId);

    await _messagesRef(conversationId).add({
      'content': content,
      'contentType': contentType,
      'senderId': senderId,
      'senderRole': senderRole,
      'senderName': senderName,
      'isRead': false,
      'status': 'sent',
      'createdAt': FieldValue.serverTimestamp(),
      'attachments': <dynamic>[],
      'isDeleted': false,
      'isEdited': false,
    });

    final targetRole = type == 'SUPPORT'
        ? (senderRole == 'admin' ? 'guest' : 'admin')
        : (senderRole == 'host' ? 'guest' : 'host');

    final update = <String, dynamic>{
      'lastMessage': content,
      'lastMessageTime': FieldValue.serverTimestamp(),
      // Atomic increment (web -improved pattern) avoids the read-then-write race.
      'unreadCounts': {targetRole: FieldValue.increment(1)},
    };
    // Web's host↔guest send deliberately omits updatedAt (to keep ordering
    // stable); the support send sets it. Match that.
    if (type == 'SUPPORT') {
      update['updatedAt'] = FieldValue.serverTimestamp();
    }

    await convRef.set(update, SetOptions(merge: true));
  }

  /// Marks every message from the OTHER party as read and resets the reader's
  /// unread counter to 0. Uses a single-field equality query (`isRead == false`)
  /// + client-side sender filter, so NO Firestore composite index is required.
  Future<void> markAllAsRead({
    required String conversationId,
    required String currentUserId,
    required String role,
  }) async {
    final convRef = _conversations.doc(conversationId);
    final snap =
        await _messagesRef(conversationId).where('isRead', isEqualTo: false).get();

    final batch = _db.batch();
    for (final doc in snap.docs) {
      if ((doc.data()['senderId'] ?? '').toString() == currentUserId) continue;
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    batch.set(
      convRef,
      {
        'unreadCounts': {role: 0}
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  /// Soft-delete (web parity): never hard-delete; the UI shows a placeholder.
  Future<void> deleteMessage(String conversationId, String messageId) async {
    await _messagesRef(conversationId).doc(messageId).update({
      'isDeleted': true,
      'content': '[Message deleted]',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Conversation lifecycle (lazy get-or-create) ──────────────────────────

  /// Creates the host↔guest conversation doc if missing, seeded from metadata,
  /// or refreshes the denormalized metadata if it already exists. Writes BOTH
  /// the root `hostId`/`guestId` AND a `participants` array so every web query
  /// path finds the doc, plus denormalized names/avatars for inbox display.
  Future<void> ensureGuestHostConversation({
    required String conversationId,
    required String hostId,
    required String guestId,
    String hostName = '',
    String hostAvatar = '',
    String guestName = '',
    String guestAvatar = '',
    String propertyId = '',
    String propertyTitle = '',
    String propertyImage = '',
  }) async {
    final ref = _conversations.doc(conversationId);
    final snap = await ref.get();

    final base = <String, dynamic>{
      'id': conversationId,
      'type': 'GUEST_HOST',
      'title': propertyTitle.isNotEmpty ? propertyTitle : 'Chat',
      'participants': [hostId, guestId],
      'hostId': hostId,
      'guestId': guestId,
      'hostName': hostName,
      'hostAvatar': hostAvatar,
      'guestName': guestName,
      'guestAvatar': guestAvatar,
      'propertyId': propertyId,
      'propertyTitle': propertyTitle,
      'propertyImage': propertyImage,
      'metadata': {
        'hostId': hostId,
        'guestId': guestId,
        'propertyId': propertyId,
        'propertyTitle': propertyTitle,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!snap.exists) {
      await ref.set({
        ...base,
        'unreadCounts': {'guest': 0, 'host': 0},
        'typingUsers': <dynamic>[],
        'isArchived': false,
        'isPinned': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      await ref.set(base, SetOptions(merge: true));
    }
  }

  /// Creates the SUPPORT conversation doc if missing. Only the guest is a
  /// participant (admin is a pure role string, exactly like the web).
  Future<void> ensureSupportConversation({
    required String guestId,
    String guestName = '',
    String guestAvatar = '',
  }) async {
    final id = supportConversationId(guestId);
    final ref = _conversations.doc(id);
    final snap = await ref.get();
    if (snap.exists) return;

    await ref.set({
      'id': id,
      'type': 'SUPPORT',
      'title': 'Live Support Chat',
      'participants': [
        {
          'userId': guestId,
          'role': 'guest',
          'name': guestName,
          'joinedAt': FieldValue.serverTimestamp(),
        }
      ],
      'guestId': guestId,
      'guestName': guestName,
      'guestAvatar': guestAvatar,
      'metadata': {'guestId': guestId, 'guestName': guestName},
      'unreadCounts': {'guest': 0, 'admin': 0},
      'typingUsers': <dynamic>[],
      'isArchived': false,
      'isPinned': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── Conversation list (inbox) ────────────────────────────────────────────

  /// Realtime stream of the user's host↔guest conversations (SUPPORT threads
  /// are excluded — they're reached via the dedicated Live Chat entry). Merges
  /// the role-id queries (`guestId == me`, `hostId == me`) with the legacy
  /// `participants array-contains` query, dedupes by doc id, and sorts by
  /// `lastMessageTime` desc — client-side, so no composite index is needed.
  Stream<List<Conversation>> watchConversations(String userId) {
    return _merged([
      _conversations.where('guestId', isEqualTo: userId),
      _conversations.where('hostId', isEqualTo: userId),
      _conversations.where('participants', arrayContains: userId),
    ]);
  }

  /// Realtime global unread badge: sum of the user's unread across all their
  /// (non-support) conversations.
  Stream<int> watchTotalUnread(String userId) =>
      watchConversations(userId).map((convs) =>
          convs.fold<int>(0, (total, c) => total + c.unreadFor(userId)));

  Stream<List<Conversation>> _merged(
      List<Query<Map<String, dynamic>>> queries) {
    final controller = StreamController<List<Conversation>>();
    final latest =
        List<List<QueryDocumentSnapshot<Map<String, dynamic>>>?>.filled(
            queries.length, null);
    final subs = <StreamSubscription>[];

    void emit() {
      final byId = <String, Conversation>{};
      for (final docs in latest) {
        if (docs == null) continue;
        for (final doc in docs) {
          final c = Conversation.fromDoc(doc);
          if (c.isSupport) continue; // never leak support into the inbox
          if (c.isArchived) continue;
          byId[doc.id] = c;
        }
      }
      final list = byId.values.toList()
        ..sort((a, b) {
          final at = a.lastMessageTime?.millisecondsSinceEpoch ?? 0;
          final bt = b.lastMessageTime?.millisecondsSinceEpoch ?? 0;
          return bt.compareTo(at);
        });
      if (!controller.isClosed) controller.add(list);
    }

    for (var i = 0; i < queries.length; i++) {
      final index = i;
      subs.add(queries[i].snapshots().listen(
        (snap) {
          latest[index] = snap.docs;
          emit();
        },
        // A single query may fail (e.g. a missing field on legacy docs) without
        // taking down the others.
        onError: (Object _) {
          latest[index] = const [];
          emit();
        },
      ));
    }

    controller.onCancel = () async {
      for (final s in subs) {
        await s.cancel();
      }
    };

    return controller.stream;
  }
}
