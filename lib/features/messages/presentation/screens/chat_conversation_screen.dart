import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
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
  String _participantName = '';
  String _participantAvatar = '';
  String _propertyTitle = '';
  bool _didInitArgs = false;

  @override
  void initState() {
    super.initState();
    _session = sl<UserSession>();

    final conv = widget.conversation ?? {};
    _conversationId =
        (conv['_id'] ?? conv['id'] ?? conv['conversationId'] ?? '').toString();
    _participantName =
        (conv['name'] ?? conv['participantName'] ?? '').toString();
    _participantAvatar =
        (conv['avatar'] ?? conv['participantAvatar'] ?? '').toString();
    _propertyTitle =
        (conv['property'] ?? conv['propertyTitle'] ?? '').toString();

    final cubit = context.read<ChatCubit>();
    final token = _session.authToken;
    cubit.setCurrentUser(_session.userId);
    if (token != null && token.isNotEmpty) {
      cubit.connectToSocket(authToken: token, userId: _session.userId);
    }
    cubit.getChatMessages(_conversationId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitArgs) return;
    _didInitArgs = true;
    if (_participantName.isEmpty) {
      _participantName = context.tr('messages.hostFallback');
    }
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

    final userId = _session.userId ?? '';
    if (userId.isEmpty) return;

    _messageController.clear();
    await context.read<ChatCubit>().sendMessage(_conversationId, text);

    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  bool _isSentByMe(Map<String, dynamic> msg) {
    final senderId = (msg['senderId'] ?? msg['sender'] ?? '').toString();
    final senderObj = msg['sender'];
    final id = senderObj is Map
        ? (senderObj['_id'] ?? senderObj['id'] ?? '').toString()
        : senderId;
    return id == _session.userId;
  }

  String _formatTime(BuildContext context, String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12
          ? context.tr('messages.pmShort')
          : context.tr('messages.amShort');
      return '$h:$m $ampm';
    } catch (_) {
      return '';
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
            if (_participantAvatar.isNotEmpty)
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(_participantAvatar),
                onBackgroundImageError: (_, __) {},
              )
            else
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryColor,
                child: Icon(Icons.person, color: AppColors.charcoal, size: 20),
              ),
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
                  if (_propertyTitle.isNotEmpty)
                    Text(
                      _propertyTitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral600,
                      ),
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
                    SnackBar(content: Text(state.message)),
                  );
                } else if (state is ChatMessagesLoaded) {
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _scrollToBottom());
                }
              },
              builder: (context, state) {
                if (state is ChatLoading) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryColor));
                }

                List<dynamic> messages = [];
                if (state is ChatMessagesLoaded) {
                  messages = state.messages;
                }

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      context.tr('messages.chatEmptyMessage'),
                      style: const TextStyle(
                          color: AppColors.neutral600, fontSize: 15),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index] as Map<String, dynamic>;
                    return _buildMessageBubble(context, message);
                  },
                );
              },
            ),
          ),
          Container(
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
                          hintStyle:
                              const TextStyle(color: AppColors.neutral400),
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
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, Map<String, dynamic> message) {
    final isSent = _isSentByMe(message);
    final content = (message['content'] ?? message['text'] ?? '').toString();
    final time = _formatTime(
        context, (message['createdAt'] ?? message['timestamp'])?.toString());

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSent) ...[
            if (_participantAvatar.isNotEmpty)
              CircleAvatar(
                radius: 14,
                backgroundImage: NetworkImage(_participantAvatar),
                onBackgroundImageError: (_, __) {},
              )
            else
              const CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.neutral400,
                child: Icon(Icons.person, size: 14, color: Colors.white),
              ),
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
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.charcoal,
                  ),
                ),
                if (time.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.neutral600.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
