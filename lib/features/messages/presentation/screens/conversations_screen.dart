import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/chat_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:houseiana_mobile_app/shared/widgets/skeletons/message_skeleton.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final _chatService = sl<ChatService>();
  final _session = sl<UserSession>();

  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    if (!_session.isLoggedIn) {
      setState(() {
        _isLoading = false;
        _conversations = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final convs = await _chatService.getConversations(_session.userId!);
      if (mounted) {
        setState(() {
          _conversations = convs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  String _participantName(BuildContext context, Map<String, dynamic> c) {
    final participants = c['participants'] as List?;
    if (participants != null && participants.isNotEmpty) {
      for (final p in participants) {
        if (p is Map) {
          final id = (p['id'] ?? p['userId'] ?? '').toString();
          if (id != _session.userId) {
            final first = p['firstName'] ?? p['name'] ?? '';
            final last = p['lastName'] ?? '';
            final full = '$first $last'.trim();
            if (full.isNotEmpty) return full;
          }
        }
      }
    }
    return (c['participantName'] ??
            c['hostName'] ??
            c['guestName'] ??
            context.tr('messages.userFallback'))
        .toString();
  }

  String _participantAvatar(Map<String, dynamic> c) {
    final participants = c['participants'] as List?;
    if (participants != null && participants.isNotEmpty) {
      for (final p in participants) {
        if (p is Map) {
          final id = (p['id'] ?? p['userId'] ?? '').toString();
          if (id != _session.userId) {
            return (p['profilePhoto'] ?? p['avatar'] ?? '').toString();
          }
        }
      }
    }
    return (c['participantAvatar'] ?? c['hostAvatar'] ?? '').toString();
  }

  String _lastMessage(Map<String, dynamic> c) {
    final last = c['lastMessage'];
    if (last is Map) return (last['content'] ?? last['text'] ?? '').toString();
    if (last is String) return last;
    return (c['lastMessageText'] ?? '').toString();
  }

  String _propertyTitle(Map<String, dynamic> c) =>
      (c['propertyTitle'] ?? c['property']?['title'] ?? '').toString();

  String _timeLabel(BuildContext context, Map<String, dynamic> c) {
    final raw = c['updatedAt'] ?? c['lastMessageTime'] ?? '';
    if (raw.toString().isEmpty) return '';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) {
        return context.tr('notifications.minutesShort',
            args: {'n': diff.inMinutes});
      }
      if (diff.inHours < 24) {
        return context.tr('notifications.hoursShort',
            args: {'n': diff.inHours});
      }
      if (diff.inDays == 1) return context.tr('notifications.yesterday');
      if (diff.inDays < 7) {
        return context.tr('notifications.daysShort',
            args: {'n': diff.inDays});
      }
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }

  int _unreadCount(Map<String, dynamic> c) {
    final count = c['unreadCount'] ?? c['unread'] ?? 0;
    if (count is int) return count;
    return int.tryParse(count.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          context.tr('messages.title'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (!_session.isLoggedIn) {
      return _buildSignInPrompt(context);
    }
    if (_isLoading) {
      return const ConversationsSkeletonLoader(itemCount: 6);
    }
    if (_hasError) {
      return _buildErrorState(context);
    }
    if (_conversations.isEmpty) {
      return _buildEmptyState(context);
    }
    return RefreshIndicator(
      onRefresh: _loadConversations,
      color: AppColors.primaryColor,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _conversations.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: 88, endIndent: 24),
        itemBuilder: (context, index) {
          return _buildConversationTile(context, _conversations[index]);
        },
      ),
    );
  }

  Widget _buildConversationTile(BuildContext context, Map<String, dynamic> c) {
    final name = _participantName(context, c);
    final avatar = _participantAvatar(c);
    final lastMsg = _lastMessage(c);
    final property = _propertyTitle(c);
    final time = _timeLabel(context, c);
    final unread = _unreadCount(c);
    final hasUnread = unread > 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.ghostWhite,
            backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
            child: avatar.isEmpty
                ? Text(
                    name.isNotEmpty
                        ? name[0].toUpperCase()
                        : context
                            .tr('messages.userFallback')[0]
                            .toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                  )
                : null,
          ),
          if (hasUnread)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  '$unread',
                  style: const TextStyle(
                    color: AppColors.charcoal,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
          ),
          if (time.isNotEmpty)
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                color:
                    hasUnread ? AppColors.primaryColor : AppColors.neutral600,
                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (property.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                property,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.neutral600),
              ),
            ),
          if (lastMsg.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                lastMsg,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: hasUnread ? AppColors.charcoal : AppColors.neutral600,
                  fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
        ],
      ),
      onTap: () => Navigator.pushNamed(
        context,
        Routes.chatConversation,
        arguments: {
          ...c,
          'name': name,
          'avatar': avatar,
          'property': property,
        },
      ).then((_) => _loadConversations()),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
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
                Icons.chat_bubble_outline_rounded,
                size: 40,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('messages.noMessages'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('messages.noMessagesYetDescription'),
              style:
                  const TextStyle(fontSize: 14, color: AppColors.neutral600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 60, color: AppColors.neutral400),
            const SizedBox(height: 16),
            Text(
              context.tr('messages.failedToLoad'),
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadConversations,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.charcoal,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(context.tr('messages.retry')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
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
              child: const Icon(Icons.person_outline,
                  size: 40, color: AppColors.primaryColor),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('messages.signInToView'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('messages.signInToViewDescription'),
              style:
                  const TextStyle(fontSize: 14, color: AppColors.neutral600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, Routes.login)
                    .then((_) => _loadConversations()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.charcoal,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  context.tr('messages.signIn'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
