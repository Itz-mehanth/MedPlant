import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:medicinal_plant/chat_page.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Messages', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUser?.uid)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading messages'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No messages yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final chat = docs[index].data() as Map<String, dynamic>;
              final chatId = docs[index].id;
              
              // Identify the other user
              final participants = List<String>.from(chat['participants'] ?? []);
              final otherUserId = participants.firstWhere((id) => id != currentUser?.uid, orElse: () => '');
              
              final participantDetails = chat['participantDetails'] as Map<String, dynamic>? ?? {};
              final otherUserDetails = participantDetails[otherUserId] as Map<String, dynamic>? ?? {};
              
              final otherUserName = otherUserDetails['name'] ?? 'User';
              final otherUserAvatar = otherUserDetails['avatar'] ?? '';
              
              final lastMessage = chat['lastMessage'] ?? '';
              final time = chat['lastMessageTime'] != null 
                  ? (chat['lastMessageTime'] as Timestamp).toDate() 
                  : DateTime.now();
                  
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: otherUserAvatar.isNotEmpty ? CachedNetworkImageProvider(otherUserAvatar) : null,
                  child: otherUserAvatar.isEmpty ? Icon(Icons.person) : null,
                ),
                title: Text(otherUserName, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Text(
                  DateFormat('MMM d, h:mm a').format(time),
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        chatId: chatId,
                        otherUserId: otherUserId,
                        otherUserName: otherUserName,
                        otherUserAvatar: otherUserAvatar,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
