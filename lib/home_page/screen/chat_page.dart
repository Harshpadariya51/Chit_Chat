import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ChatPage extends StatefulWidget {
  final String chatRoom;
  final String currentUserEmail;
  final String username;

  const ChatPage({
    Key? key,
    required this.chatRoom,
    required this.currentUserEmail,
    required this.username,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference storageRef =
          FirebaseStorage.instance.ref().child('chatImages/$fileName');
      final UploadTask uploadTask = storageRef.putFile(File(image.path));

      final TaskSnapshot downloadUrl = await uploadTask.whenComplete(() => {});
      final String url = await downloadUrl.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(widget.chatRoom)
          .collection('messages')
          .add({
        'sender': widget.currentUserEmail,
        'imageUrl': url,
        'timestamp': Timestamp.now(),
      });
    }
  }

  void _sendMessage({String? imageUrl}) async {
    if (_messageController.text.trim().isEmpty && imageUrl == null) {
      return;
    }

    final message = _messageController.text.trim();
    final timestamp = Timestamp.now();

    await FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(widget.chatRoom)
        .collection('messages')
        .add({
      'sender': widget.currentUserEmail,
      'message': message,
      'imageUrl': imageUrl,
      'timestamp': timestamp,
    });

    _messageController.clear();
  }

  void _deleteMessage(String messageId) async {
    await FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(widget.chatRoom)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.username),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleTextStyle: const TextStyle(
            color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chatRooms')
                  .doc(widget.chatRoom)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData =
                        messages[index].data() as Map<String, dynamic>;
                    final isCurrentUser =
                        messageData['sender'] == widget.currentUserEmail;
                    final message = messageData['message'];
                    final imageUrl = messageData['imageUrl'];
                    final timestamp = messageData['timestamp'] as Timestamp;
                    final messageId = messages[index].id;

                    return _buildMessageItem(
                      message,
                      isCurrentUser,
                      timestamp.toDate(),
                      imageUrl: imageUrl,
                      messageId: messageId,
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageItem(
    String? message,
    bool isCurrentUser,
    DateTime timestamp, {
    String? imageUrl,
    required String messageId,
  }) {
    final alignment =
        isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start;
    final bgColor = isCurrentUser ? const Color(0xFFDCF8C6) : Colors.white;
    final borderRadius = isCurrentUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          );
    final textColor = isCurrentUser ? Colors.black : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Delete Message?'),
                    content: const Text(
                        'Are you sure you want to delete this message?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          _deleteMessage(messageId);
                          Navigator.of(context).pop();
                        },
                        child: const Text('Delete'),
                      ),
                    ],
                  );
                },
              );
            },
            child: Row(
              mainAxisAlignment: alignment,
              children: [
                Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: borderRadius,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 10),
                    child: imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              imageUrl,
                              loadingBuilder: (BuildContext context,
                                  Widget child,
                                  ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) {
                                  return child;
                                } else {
                                  return const CircularProgressIndicator(
                                    color: Colors.blue,
                                  );
                                }
                              },
                              errorBuilder: (BuildContext context,
                                  Object exception, StackTrace? stackTrace) {
                                return const Text('Failed to load image');
                              },
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Text(
                            message ?? '',
                            style: TextStyle(color: textColor, fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Padding(
            padding: isCurrentUser
                ? const EdgeInsets.only(right: 12.0)
                : const EdgeInsets.only(left: 12.0),
            child: Text(
              _formatTimestamp(timestamp),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.image, color: Colors.blue),
            onPressed: _pickAndUploadImage,
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF007AFF), Color(0xFF00A8FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () => _sendMessage(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return DateFormat('hh:mm a').format(timestamp);
  }
}
