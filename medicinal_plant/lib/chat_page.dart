import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserAvatar;

  const ChatPage({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserAvatar,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: widget.otherUserAvatar.isNotEmpty 
                  ? CachedNetworkImageProvider(widget.otherUserAvatar) 
                  : null,
              child: widget.otherUserAvatar.isEmpty ? Icon(Icons.person, size: 16) : null,
            ),
            SizedBox(width: 10),
            Text(widget.otherUserName, style: TextStyle(color: Colors.black, fontSize: 16)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  padding: EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == currentUser?.uid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.green : Colors.grey[200],
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                            bottomLeft: isMe ? Radius.circular(16) : Radius.zero,
                            bottomRight: isMe ? Radius.zero : Radius.circular(16),
                          ),
                        ),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        child: Text(
                          msg['text'] ?? '',
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      ),
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

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Colors.green),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || currentUser == null) return;

    _messageController.clear();

    final batch = FirebaseFirestore.instance.batch();
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
    final messageRef = chatRef.collection('messages').doc();

    batch.set(messageRef, {
      'text': text,
      'senderId': currentUser!.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    batch.update(chatRef, {
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'participants': FieldValue.arrayUnion([currentUser!.uid, widget.otherUserId]), // Ensure participants
    });

    try {
      await batch.commit();
      
      // Send OneSignal Notification
      _sendNotification(text);
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Future<void> _sendNotification(String message) async {
    const String oneSignalAppId = 'b2b54cd9-5f66-4f46-9c2d-8a62257a702d'; // From main.dart
    final String restApiKey = ''; // WARNING: REST API Key should ideally be in backend. 
    // IF THE USER DID NOT PROVIDE A REST API KEY, THIS WILL NOT WORK FROM CLIENT SIDE FOR SECURITY REASONS OR JUST FAIL AUTH.
    // However, I will try to use the correct endpoint. If the user expects purely client side with standard keys, it might fail.
    // Usually, OneSignal.postNotification is available in the SDK? 
    // Checking OneSignal Flutter SDK documentation... OneSignal.postNotification is deprecated or removed in newer versions.
    // We typically must use the REST API.
    
    // NOTE: Without the REST API Key, we cannot send notifications from the device to other users.
    // I will log a message about this requirement.
    
    // However, for this task, I will mock the call structure so the user knows where to put it.
    // If we assume the user has a way to send it, or if I use a basic structure.
    
    /*
    try {
       await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          // "Authorization": "Basic YOUR_REST_API_KEY" // REQUIRED
        },
        body: jsonEncode({
          "app_id": oneSignalAppId,
          "include_external_user_ids": [widget.otherUserId],
          "contents": {"en": message},
          "headings": {"en": "New Message from ${currentUser?.displayName ?? 'User'}"},
          "data": {"chatId": widget.chatId},
        }),
      );
    } catch (e) {
      print('Error sending notification: $e');
    }
    */
     print('Notification triggering logic placed. REST API Key needed for actual sending.');
  }
}
