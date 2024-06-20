import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'fullscreen_image_page.dart';

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
  String _selectedBackground = 'assets/img/chit_chat.png';
  String? _replyMessage;
  String? _replyMessageId;
  bool isTextFieldEmpty = true;

  @override
  void initState() {
    super.initState();
    _loadSelectedBackground();
  }

  Future<void> _loadSelectedBackground() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedBackground =
          prefs.getString('selectedBackground') ?? 'assets/img/chit_chat.png';
    });
  }

  Future<void> _saveSelectedBackground(String background) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedBackground', background);
  }

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
        'replyToMessageId': _replyMessageId, // Add reply message ID
        'replyToMessage': _replyMessage, // Add reply message
      });

      // Clear reply state
      setState(() {
        _replyMessage = null;
        _replyMessageId = null;
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
      'replyToMessageId': _replyMessageId, // Add reply message ID
      'replyToMessage': _replyMessage, // Add reply message
    });

    _messageController.clear();

    // Clear reply state
    setState(() {
      _replyMessage = null;
      _replyMessageId = null;
    });
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
        title: Text(
          widget.username,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (String value) {
              setState(() {
                _selectedBackground = value;
                _saveSelectedBackground(value);
              });
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'assets/img/background.jpg',
                  child: Text('Dark'),
                ),
                const PopupMenuItem<String>(
                  value: 'assets/img/1131w-pbKa9sEjgiE.webp',
                  child: Text('Light'),
                ),
                const PopupMenuItem<String>(
                  value: 'assets/img/61Ntv7+SIjL.jpg',
                  child: Text('Wooden'),
                ),
                const PopupMenuItem<String>(
                  value: 'assets/img/gray-light.jpg',
                  child: Text('Gray-Light'),
                ),
                const PopupMenuItem<String>(
                  value: 'assets/img/i5dEZA.jpg',
                  child: Text('Blue'),
                ),
                const PopupMenuItem<String>(
                  value: 'assets/img/images.jpg',
                  child: Text('Friends'),
                ),
                const PopupMenuItem<String>(
                  value: 'assets/img/images (1).jpg',
                  child: Text('Pikachu'),
                ),
                const PopupMenuItem<String>(
                  value: 'assets/img/istockphoto-462187905-612x612.jpg',
                  child: Text('Lofi-Love'),
                ),
                const PopupMenuItem<String>(
                  value: 'assets/img/love.jpg',
                  child: Text('Soft-Love'),
                ),
                const PopupMenuItem<String>(
                  value: 'assets/img/simple-dark.jpg',
                  child: Text('Dark'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_selectedBackground),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
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
                        replyToMessage: messageData['replyToMessage'],
                      );
                    },
                  );
                },
              ),
            ),
            if (_replyMessage != null) _buildReplyPreview(),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(
    String? message,
    bool isCurrentUser,
    DateTime timestamp, {
    String? imageUrl,
    required String messageId,
    String? replyToMessage,
  }) {
    final alignment =
        isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start;
    final bgColor = isCurrentUser ? const Color(0xFFDCF8C6) : Colors.white;
    final borderRadius = isCurrentUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
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
            onDoubleTap: () {
              setState(() {
                _replyMessage = message;
                _replyMessageId = messageId;
              });
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: alignment,
              children: [
                isCurrentUser
                    ? Container()
                    : Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: CircleAvatar(
                          radius: 12,
                          child: Text(
                            widget.username[0].toUpperCase(),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    child: imageUrl != null
                        ? GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      FullscreenImagePage(imageUrl: imageUrl),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Image.network(
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
                                        Object exception,
                                        StackTrace? stackTrace) {
                                      return const Text('Failed to load image');
                                    },
                                    width: 150,
                                    height: 150,
                                    fit: BoxFit.cover,
                                  ),
                                  Text(
                                    _formatTimestamp(timestamp),
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (replyToMessage != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 5),
                                  margin: const EdgeInsets.only(bottom: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    replyToMessage,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      message ?? '',
                                      style: TextStyle(
                                          color: textColor, fontSize: 16),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Text(
                                    _formatTimestamp(timestamp),
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 10),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),
                isCurrentUser
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: CircleAvatar(
                          radius: 12,
                          child: Text(
                            widget.currentUserEmail[0].toUpperCase(),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      )
                    : Container(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      color: Colors.grey[300],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Replying to: $_replyMessage',
              style: const TextStyle(color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black54),
            onPressed: () {
              setState(() {
                _replyMessage = null;
                _replyMessageId = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    bool isTextFieldEmpty = _messageController.text.trim().isEmpty;

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(35),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
                onChanged: (text) {
                  setState(() {
                    isTextFieldEmpty = text.trim().isEmpty;
                  });
                },
                onTap: () {
                  setState(() {
                    isTextFieldEmpty = _messageController.text.trim().isEmpty;
                  });
                },
                onSubmitted: (text) {
                  setState(() {
                    isTextFieldEmpty = true;
                  });
                },
              ),
            ),
            if (isTextFieldEmpty)
              IconButton(
                icon: const Icon(Icons.image_outlined, color: Colors.blue),
                onPressed: _pickAndUploadImage,
              ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blue),
              onPressed: () => _sendMessage(),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return DateFormat('hh:mm a').format(timestamp);
  }
}

// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:io';
//
// class ChatPage extends StatefulWidget {
//   final String chatRoom;
//   final String currentUserEmail;
//   final String username;
//
//   const ChatPage({
//     Key? key,
//     required this.chatRoom,
//     required this.currentUserEmail,
//     required this.username,
//   }) : super(key: key);
//
//   @override
//   State<ChatPage> createState() => _ChatPageState();
// }
//
// class _ChatPageState extends State<ChatPage> {
//   final TextEditingController _messageController = TextEditingController();
//   final ImagePicker _picker = ImagePicker();
//
//   String _selectedBackground = 'assets/img/chit_chat.png';
//
//   @override
//   void initState() {
//     super.initState();
//     _loadSelectedBackground();
//   }
//
//   Future<void> _loadSelectedBackground() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _selectedBackground =
//           prefs.getString('selectedBackground') ?? 'assets/img/chit_chat.png';
//     });
//   }
//
//   Future<void> _saveSelectedBackground(String background) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('selectedBackground', background);
//   }
//
//   Future<void> _pickAndUploadImage() async {
//     final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
//
//     if (image != null) {
//       final fileName = DateTime.now().millisecondsSinceEpoch.toString();
//       final Reference storageRef =
//           FirebaseStorage.instance.ref().child('chatImages/$fileName');
//       final UploadTask uploadTask = storageRef.putFile(File(image.path));
//
//       final TaskSnapshot downloadUrl = await uploadTask.whenComplete(() => {});
//       final String url = await downloadUrl.ref.getDownloadURL();
//
//       await FirebaseFirestore.instance
//           .collection('chatRooms')
//           .doc(widget.chatRoom)
//           .collection('messages')
//           .add({
//         'sender': widget.currentUserEmail,
//         'imageUrl': url,
//         'timestamp': Timestamp.now(),
//       });
//     }
//   }
//
//   void _sendMessage({String? imageUrl}) async {
//     if (_messageController.text.trim().isEmpty && imageUrl == null) {
//       return;
//     }
//
//     final message = _messageController.text.trim();
//     final timestamp = Timestamp.now();
//
//     await FirebaseFirestore.instance
//         .collection('chatRooms')
//         .doc(widget.chatRoom)
//         .collection('messages')
//         .add({
//       'sender': widget.currentUserEmail,
//       'message': message,
//       'imageUrl': imageUrl,
//       'timestamp': timestamp,
//     });
//
//     _messageController.clear();
//   }
//
//   void _deleteMessage(String messageId) async {
//     await FirebaseFirestore.instance
//         .collection('chatRooms')
//         .doc(widget.chatRoom)
//         .collection('messages')
//         .doc(messageId)
//         .delete();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           widget.username,
//           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         elevation: 1,
//         centerTitle: true,
//         leading: IconButton(
//           icon: const Icon(
//             Icons.arrow_back,
//           ),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//         actions: [
//           PopupMenuButton<String>(
//             icon: const Icon(Icons.menu),
//             onSelected: (String value) {
//               setState(() {
//                 _selectedBackground = value;
//                 _saveSelectedBackground(value);
//               });
//             },
//             itemBuilder: (BuildContext context) {
//               return [
//                 const PopupMenuItem<String>(
//                   value: 'assets/img/background.jpg',
//                   child: Text('Dark'),
//                 ),
//                 const PopupMenuItem<String>(
//                   value: 'assets/img/1131w-pbKa9sEjgiE.webp',
//                   child: Text('Light'),
//                 ),
//                 const PopupMenuItem<String>(
//                   value: 'assets/img/61Ntv7+SIjL.jpg',
//                   child: Text('Wooden'),
//                 ),
//                 const PopupMenuItem<String>(
//                   value: 'assets/img/gray-light.jpg',
//                   child: Text('Gray-Light'),
//                 ),
//                 const PopupMenuItem<String>(
//                   value: 'assets/img/i5dEZA.jpg',
//                   child: Text('Blue'),
//                 ),
//                 const PopupMenuItem<String>(
//                   value: 'assets/img/images.jpg',
//                   child: Text('Friends'),
//                 ),
//                 const PopupMenuItem<String>(
//                   value: 'assets/img/images (1).jpg',
//                   child: Text('Pikachu'),
//                 ),
//                 const PopupMenuItem<String>(
//                   value: 'assets/img/istockphoto-462187905-612x612.jpg',
//                   child: Text('Lofi-Love'),
//                 ),
//                 const PopupMenuItem<String>(
//                   value: 'assets/img/love.jpg',
//                   child: Text('Soft-Love'),
//                 ),
//                 const PopupMenuItem<String>(
//                   value: 'assets/img/simple-dark.jpg',
//                   child: Text('Dark'),
//                 ),
//               ];
//             },
//           ),
//         ],
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           image: DecorationImage(
//             image: AssetImage(_selectedBackground),
//             fit: BoxFit.cover,
//           ),
//         ),
//         child: Column(
//           children: [
//             Expanded(
//               child: StreamBuilder<QuerySnapshot>(
//                 stream: FirebaseFirestore.instance
//                     .collection('chatRooms')
//                     .doc(widget.chatRoom)
//                     .collection('messages')
//                     .orderBy('timestamp', descending: true)
//                     .snapshots(),
//                 builder: (context, snapshot) {
//                   if (!snapshot.hasData) {
//                     return const Center(child: CircularProgressIndicator());
//                   }
//
//                   final messages = snapshot.data!.docs;
//
//                   return ListView.builder(
//                     reverse: true,
//                     itemCount: messages.length,
//                     itemBuilder: (context, index) {
//                       final messageData =
//                           messages[index].data() as Map<String, dynamic>;
//                       final isCurrentUser =
//                           messageData['sender'] == widget.currentUserEmail;
//                       final message = messageData['message'];
//                       final imageUrl = messageData['imageUrl'];
//                       final timestamp = messageData['timestamp'] as Timestamp;
//                       final messageId = messages[index].id;
//
//                       return _buildMessageItem(
//                         message,
//                         isCurrentUser,
//                         timestamp.toDate(),
//                         imageUrl: imageUrl,
//                         messageId: messageId,
//                       );
//                     },
//                   );
//                 },
//               ),
//             ),
//             _buildMessageInput(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMessageItem(
//     String? message,
//     bool isCurrentUser,
//     DateTime timestamp, {
//     String? imageUrl,
//     required String messageId,
//   }) {
//     final alignment =
//         isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start;
//     final bgColor = isCurrentUser ? const Color(0xFFDCF8C6) : Colors.white;
//     final borderRadius = isCurrentUser
//         ? const BorderRadius.only(
//             topLeft: Radius.circular(12),
//             topRight: Radius.circular(12),
//             bottomLeft: Radius.circular(12),
//           )
//         : const BorderRadius.only(
//             topLeft: Radius.circular(12),
//             topRight: Radius.circular(12),
//             bottomRight: Radius.circular(12),
//           );
//     final textColor = isCurrentUser ? Colors.black : Colors.black87;
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//       child: Column(
//         crossAxisAlignment:
//             isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//         children: [
//           GestureDetector(
//             onLongPress: () {
//               showDialog(
//                 context: context,
//                 builder: (BuildContext context) {
//                   return AlertDialog(
//                     title: const Text('Delete Message?'),
//                     content: const Text(
//                         'Are you sure you want to delete this message?'),
//                     actions: <Widget>[
//                       TextButton(
//                         onPressed: () {
//                           Navigator.of(context).pop();
//                         },
//                         child: const Text('Cancel'),
//                       ),
//                       TextButton(
//                         onPressed: () {
//                           _deleteMessage(messageId);
//                           Navigator.of(context).pop();
//                         },
//                         child: const Text('Delete'),
//                       ),
//                     ],
//                   );
//                 },
//               );
//             },
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               mainAxisAlignment: alignment,
//               children: [
//                 isCurrentUser
//                     ? Container()
//                     : Padding(
//                         padding: const EdgeInsets.only(right: 8.0),
//                         child: CircleAvatar(
//                           radius: 12,
//                           child: Text(
//                             widget.username[0].toUpperCase(),
//                             style: const TextStyle(fontSize: 12),
//                           ),
//                         ),
//                       ),
//                 Flexible(
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: bgColor,
//                       borderRadius: borderRadius,
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.1),
//                           spreadRadius: 2,
//                           blurRadius: 5,
//                           offset: const Offset(0, 3),
//                         ),
//                       ],
//                     ),
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
//                     child: imageUrl != null
//                         ? ClipRRect(
//                             borderRadius: BorderRadius.circular(12),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.end,
//                               children: [
//                                 Image.network(
//                                   imageUrl,
//                                   loadingBuilder: (BuildContext context,
//                                       Widget child,
//                                       ImageChunkEvent? loadingProgress) {
//                                     if (loadingProgress == null) {
//                                       return child;
//                                     } else {
//                                       return const CircularProgressIndicator(
//                                         color: Colors.blue,
//                                       );
//                                     }
//                                   },
//                                   errorBuilder: (BuildContext context,
//                                       Object exception,
//                                       StackTrace? stackTrace) {
//                                     return const Text('Failed to load image');
//                                   },
//                                   width: 150,
//                                   height: 150,
//                                   fit: BoxFit.cover,
//                                 ),
//                                 Text(
//                                   _formatTimestamp(timestamp),
//                                   style: const TextStyle(
//                                       color: Colors.grey, fontSize: 10),
//                                 ),
//                               ],
//                             ),
//                           )
//                         : Row(
//                             crossAxisAlignment: CrossAxisAlignment.end,
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Flexible(
//                                 child: Text(
//                                   message ?? '',
//                                   style:
//                                       TextStyle(color: textColor, fontSize: 16),
//                                 ),
//                               ),
//                               const SizedBox(width: 15),
//                               Text(
//                                 _formatTimestamp(timestamp),
//                                 style: const TextStyle(
//                                     color: Colors.grey, fontSize: 10),
//                               ),
//                             ],
//                           ),
//                   ),
//                 ),
//                 isCurrentUser
//                     ? Padding(
//                         padding: const EdgeInsets.only(left: 8.0),
//                         child: CircleAvatar(
//                           radius: 12,
//                           child: Text(
//                             widget.currentUserEmail[0].toUpperCase(),
//                             style: const TextStyle(fontSize: 12),
//                           ),
//                         ),
//                       )
//                     : Container(),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildMessageInput() {
//     bool isTextFieldEmpty = _messageController.text.trim().isEmpty;
//
//     return Padding(
//       padding: const EdgeInsets.all(10.0),
//       child: Container(
//         height: 50,
//         decoration: BoxDecoration(
//           color: Colors.black.withOpacity(0.3),
//           borderRadius: BorderRadius.circular(35),
//         ),
//         child: Row(
//           children: [
//             Expanded(
//               child: TextField(
//                 controller: _messageController,
//                 decoration: const InputDecoration(
//                   hintText: 'Type a message...',
//                   border: InputBorder.none,
//                   contentPadding: EdgeInsets.symmetric(
//                     horizontal: 20,
//                     vertical: 15,
//                   ),
//                 ),
//                 onChanged: (text) {
//                   setState(() {
//                     isTextFieldEmpty = text.trim().isEmpty;
//                   });
//                 },
//                 onTap: () {
//                   setState(() {
//                     isTextFieldEmpty = _messageController.text.trim().isEmpty;
//                   });
//                 },
//                 onSubmitted: (text) {
//                   setState(() {
//                     isTextFieldEmpty = true;
//                   });
//                 },
//               ),
//             ),
//             if (isTextFieldEmpty)
//               IconButton(
//                 icon: const Icon(Icons.image_outlined, color: Colors.blue),
//                 onPressed: _pickAndUploadImage,
//               ),
//             IconButton(
//               icon: const Icon(Icons.send, color: Colors.blue),
//               onPressed: () => _sendMessage(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   String _formatTimestamp(DateTime timestamp) {
//     return DateFormat('hh:mm a').format(timestamp);
//   }
// }
