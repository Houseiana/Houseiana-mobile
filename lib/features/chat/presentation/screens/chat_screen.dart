import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('messages.title')),
      ),
      body: Center(
        child: Text(context.tr('messages.chatPlaceholder')),
      ),
    );
  }
}
