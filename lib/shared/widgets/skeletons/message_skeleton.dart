import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';

class MessageSkeletonItem extends StatelessWidget {
  final bool isSentByMe;

  const MessageSkeletonItem({super.key, this.isSentByMe = false});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      containersColor: AppColors.skeletonBaseColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          mainAxisAlignment:
              isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isSentByMe) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.neutral200,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.65,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.neutral200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isSentByMe ? 16 : 4),
                  bottomRight: Radius.circular(isSentByMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 120,
                    decoration: BoxDecoration(
                      color: AppColors.neutral200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 14,
                    width: 80,
                    decoration: BoxDecoration(
                      color: AppColors.neutral200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            if (isSentByMe) const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class ConversationSkeletonItem extends StatelessWidget {
  const ConversationSkeletonItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      containersColor: AppColors.skeletonBaseColor,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.neutral200,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 16,
                        width: 120,
                        decoration: BoxDecoration(
                          color: AppColors.neutral200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        height: 12,
                        width: 40,
                        decoration: BoxDecoration(
                          color: AppColors.neutral200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.neutral200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatSkeletonLoader extends StatelessWidget {
  final int messageCount;

  const ChatSkeletonLoader({super.key, this.messageCount = 8});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: messageCount,
      itemBuilder: (context, index) {
        return MessageSkeletonItem(isSentByMe: index % 3 == 0);
      },
    );
  }
}

class ConversationsSkeletonLoader extends StatelessWidget {
  final int itemCount;

  const ConversationsSkeletonLoader({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) => const ConversationSkeletonItem(),
    );
  }
}
