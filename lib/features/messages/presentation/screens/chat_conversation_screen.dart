import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/chat/data/models/chat_message.dart';
import 'package:houseiana_mobile_app/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:houseiana_mobile_app/features/chat/presentation/cubit/chat_state.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class ChatConversationScreen extends StatefulWidget {
  final Map<String, dynamic>? conversation;

  const ChatConversationScreen({
    super.key,
    this.conversation,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final UserSession _session;
  String _conversationId = '';
  String _type = 'GUEST_HOST';
  String _role = 'guest';
  String _participantName = '';
  String _participantAvatar = '';
  String _propertyTitle = '';
  bool _isSupport = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _session = sl<UserSession>();

    final conv = widget.conversation ?? {};
    _conversationId =
        (conv['id'] ?? conv['_id'] ?? conv['conversationId'] ?? '').toString();
    _type = (conv['type'] ?? 'GUEST_HOST').toString();
    _isSupport = _type == 'SUPPORT';

    final myId = _session.userId ?? '';
    _role = _isSupport
        ? 'guest'
        : ((conv['hostId'] ?? '').toString() == myId ? 'host' : 'guest');

    _participantName = (conv['name'] ?? conv['participantName'] ?? '').toString();
    _participantAvatar =
        (conv['avatar'] ?? conv['participantAvatar'] ?? '').toString();
    _propertyTitle = (conv['property'] ?? conv['propertyTitle'] ?? '').toString();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (_isSupport) {
      _participantName = context.tr('messages.supportTitle');
    } else if (_participantName.isEmpty) {
      _participantName = context.tr('messages.hostFallback');
    }

    context.read<ChatCubit>().start(
          conversationId: _conversationId,
          userId: _session.userId ?? '',
          userName: _session.fullName,
          role: _role,
          type: _type,
          limit: _isSupport ? 200 : 100,
        );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _conversationId.isEmpty) return;
    final myId = _session.userId ?? '';
    if (myId.isEmpty) return;

    _messageController.clear();
    await context.read<ChatCubit>().send(text);

    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  String _formatTime(BuildContext context, DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12
        ? context.tr('messages.pmShort')
        : context.tr('messages.amShort');
    return '$h:$m $ampm';
  }

  String _friendlyError(BuildContext context, String message) {
    switch (message) {
      case 'permission-denied':
        return context.tr('messages.permissionDenied');
      case 'offline':
        return context.tr('messages.connectionOffline');
      default:
        return message;
    }
  }

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
        title: Row(
          children: [
            _headerAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _participantName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                  ),
                  if (_isSupport)
                    Text(
                      context.tr('messages.supportTeam'),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.neutral600),
                    )
                  else if (_propertyTitle.isNotEmpty)
                    Text(
                      _propertyTitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.neutral600),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatCubit, ChatState>(
              listener: (context, state) {
                if (state is ChatError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text(_friendlyError(context, state.message))),
                  );
                } else if (state is ChatMessagesLoaded) {
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _scrollToBottom());
                }
              },
              builder: (context, state) {
                if (state is ChatLoading || state is ChatInitial) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryColor),
                  );
                }

                final messages = state is ChatMessagesLoaded
                    ? state.messages
                    : <ChatMessage>[];

                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        _isSupport
                            ? context.tr('messages.supportWelcome')
                            : context.tr('messages.chatEmptyMessage'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.neutral600, fontSize: 15),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) =>
                      _buildMessageBubble(context, messages[index]),
                );
              },
            ),
          ),
          _buildComposer(context),
        ],
      ),
    );
  }

  Widget _headerAvatar() {
    if (_isSupport) {
      return const CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.primaryColor,
        child: Icon(Icons.support_agent, color: AppColors.charcoal, size: 20),
      );
    }
    if (_participantAvatar.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: NetworkImage(_participantAvatar),
        onBackgroundImageError: (_, __) {},
      );
    }
    return const CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.primaryColor,
      child: Icon(Icons.person, color: AppColors.charcoal, size: 20),
    );
  }

  Widget _buildComposer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.ghostWhite,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: context.tr('messages.typeMessage'),
                    border: InputBorder.none,
                    hintStyle: const TextStyle(color: AppColors.neutral400),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: AppColors.charcoal),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage message) {
    final isSent = message.senderId == (_session.userId ?? '');
    final content = message.isDeleted
        ? context.tr('messages.messageDeleted')
        : message.content;
    final time = _formatTime(context, message.createdAt);
    final italic = message.isDeleted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSent) ...[
            _bubbleAvatar(),
            const SizedBox(width: 8),
          ],
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.68,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSent ? AppColors.primaryColor : AppColors.ghostWhite,
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomRight: isSent ? const Radius.circular(4) : null,
                bottomLeft: !isSent ? const Radius.circular(4) : null,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.charcoal,
                    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
                if (time.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.neutral600.withValues(alpha: 0.8),
                        ),
                      ),
                      if (isSent && !message.isDeleted) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 13,
                          color: message.isRead
                              ? AppColors.charcoal
                              : AppColors.neutral600.withValues(alpha: 0.8),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubbleAvatar() {
    if (_isSupport) {
      return const CircleAvatar(
        radius: 14,
        backgroundColor: AppColors.primaryColor,
        child: Icon(Icons.support_agent, size: 14, color: AppColors.charcoal),
      );
    }
    if (_participantAvatar.isNotEmpty) {
      return CircleAvatar(
        radius: 14,
        backgroundImage: NetworkImage(_participantAvatar),
        onBackgroundImageError: (_, __) {},
      );
    }
    return const CircleAvatar(
      radius: 14,
      backgroundColor: AppColors.neutral400,
      child: Icon(Icons.person, size: 14, color: Colors.white),
    );
  }
}
