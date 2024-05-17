import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  final String chatRoom;
  final String currentUserEmail;

  const ChatPage(
      {super.key, required this.chatRoom, required this.currentUserEmail});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat"),
      ),
    );
  }
}
