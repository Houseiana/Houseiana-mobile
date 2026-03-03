import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

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
        title: const Text(
          'Messages',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _conversations.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          return _buildConversationTile(context, conversation);
        },
      ),
    );
  }

  Widget _buildConversationTile(BuildContext context, Map<String, dynamic> conversation) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: NetworkImage(conversation['avatar']),
          ),
          if (conversation['unread'] > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  '${conversation['unread']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
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
              conversation['name'],
              style: TextStyle(
                fontSize: 15,
                fontWeight: conversation['unread'] > 0 ? FontWeight.w700 : FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
          ),
          Text(
            conversation['time'],
            style: TextStyle(
              fontSize: 12,
              color: conversation['unread'] > 0 ? AppColors.primaryColor : AppColors.neutral600,
              fontWeight: conversation['unread'] > 0 ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            conversation['property'],
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.neutral600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            conversation['lastMessage'],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: conversation['unread'] > 0 ? AppColors.charcoal : AppColors.neutral600,
              fontWeight: conversation['unread'] > 0 ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      ),
      onTap: () {
        Navigator.pushNamed(
          context,
          '/chat-conversation',
          arguments: conversation,
        );
      },
    );
  }

  static final List<Map<String, dynamic>> _conversations = [
    {
      'name': 'Sarah Johnson',
      'avatar': 'https://i.pravatar.cc/150?img=1',
      'property': 'Luxury Villa West Bay',
      'lastMessage': 'The check-in process was smooth, thank you!',
      'time': '10:30 AM',
      'unread': 2,
    },
    {
      'name': 'Ahmed Al-Thani',
      'avatar': 'https://i.pravatar.cc/150?img=12',
      'property': 'Modern Apartment Lusail',
      'lastMessage': 'Is early check-in available?',
      'time': 'Yesterday',
      'unread': 0,
    },
    {
      'name': 'Emily Chen',
      'avatar': 'https://i.pravatar.cc/150?img=5',
      'property': 'Beachfront Villa The Pearl',
      'lastMessage': 'Thank you for hosting us!',
      'time': '2 days ago',
      'unread': 0,
    },
    {
      'name': 'Mohammed Rahman',
      'avatar': 'https://i.pravatar.cc/150?img=13',
      'property': 'Penthouse Doha Downtown',
      'lastMessage': 'Can I extend my stay by one more night?',
      'time': '3 days ago',
      'unread': 1,
    },
    {
      'name': 'Lisa Anderson',
      'avatar': 'https://i.pravatar.cc/150?img=9',
      'property': 'Family House Al Wakrah',
      'lastMessage': 'The location is perfect for our family!',
      'time': '1 week ago',
      'unread': 0,
    },
  ];
}
