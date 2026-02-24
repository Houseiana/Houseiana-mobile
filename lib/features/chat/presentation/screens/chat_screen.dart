import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_strings.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.chat),
      ),
      body: const Center(
        child: Text('Chat conversations will appear here'),
      ),
    );
  }
}
