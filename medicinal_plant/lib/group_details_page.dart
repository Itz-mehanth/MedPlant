// lib/group_details_page.dart

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'notifications.dart';

class GroupChatPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatPage({super.key, required this.groupId, required this.groupName});

  @override
  _GroupChatPageState createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  File? _imageFile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        backgroundColor: const Color.fromARGB(255, 68, 255, 0),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupDetailsPage(groupId: widget.groupId),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .doc(widget.groupId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Center(
                      child: SizedBox(
                        width: 40, // Equal width
                        height: 40, // Equal height
                        child: CircularProgressIndicator(),
                      )));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No messages yet. Say hello!"),
                  );
                }
                var messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index].data() as Map<String, dynamic>;
                    return _buildMessageBubble(message);
                  },
                );
              },
            ),
          ),
          if (_imageFile != null) _buildImagePreview(),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final bool isCurrentUser = message['sender_id'] == currentUser?.uid;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(message['sender_id']).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                  var userData = snapshot.data!.data() as Map<String, dynamic>?;
                  var photoURL = userData?['photoURL'] as String?;
                  return CircleAvatar(
                    backgroundImage: (photoURL != null && photoURL.isNotEmpty) ? NetworkImage(photoURL) : null,
                    child: (photoURL == null || photoURL.isEmpty) ? const Icon(Icons.person) : null,
                  );
                }
                return const CircleAvatar(child: Icon(Icons.person));
              },
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: isCurrentUser ? Theme.of(context).primaryColorLight : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message['image_url'] != null && (message['image_url'] as String).isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: message['image_url'],
                        placeholder: (context, url) => const Center(
                          child: SizedBox(
                            width: 40, // Equal width
                            height: 40, // Equal height
                            child: CircularProgressIndicator(),
                          )),
                        errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
                        width: 200,
                      ),
                    ),
                  if (message['content'] != null && (message['content'] as String).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Text(
                        message['content'],
                        style: TextStyle(color: isCurrentUser ? Colors.white : Colors.black87),
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

  Widget _buildImagePreview() {
    return Stack(
      alignment: AlignmentDirectional.topEnd,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            image: DecorationImage(
              image: FileImage(_imageFile!),
              fit: BoxFit.cover,
            ),
          ),
        ),
        IconButton(
          icon: const CircleAvatar(
            backgroundColor: Colors.black54,
            child: Icon(Icons.close, color: Colors.white, size: 18),
          ),
          onPressed: () => setState(() => _imageFile = null),
        ),
      ],
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      height: 70.0,
      color: Colors.white,
      child: Row(
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.photo, color: Theme.of(context).primaryColor),
            onPressed: _pickImage,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration.collapsed(
                hintText: 'Send a message...',
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty && _imageFile == null) return;

    _messageController.clear();
    final tempImageFile = _imageFile;
    setState(() => _imageFile = null);

    String? imageUrl;
    if (tempImageFile != null) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_images/${widget.groupId}/${DateTime.now().toIso8601String()}');
      await storageRef.putFile(tempImageFile);
      imageUrl = await storageRef.getDownloadURL();
    }

    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('messages')
        .add({
      'sender_id': currentUser?.uid,
      'content': messageText,
      'image_url': imageUrl ?? '',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Handle notifications
  }
}

class GroupDetailsPage extends StatelessWidget {
  final String groupId;

  const GroupDetailsPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('groups').doc(groupId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: Center(
                child: SizedBox(
                  width: 40, // Equal width
                  height: 40, // Equal height
                  child: CircularProgressIndicator(),
                )));
          }

          final groupData = snapshot.data!.data() as Map<String, dynamic>;
          final members = (groupData['members'] as List<dynamic>).cast<String>();
          final bool isMember = members.contains(FirebaseAuth.instance.currentUser?.uid);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200.0,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(groupData['name'] ?? 'Group Details'),
                  background: (groupData['profile_picture'] != null &&
                      (groupData['profile_picture'] as String).isNotEmpty)
                      ? CachedNetworkImage(
                    imageUrl: groupData['profile_picture'],
                    fit: BoxFit.cover,
                    color: Colors.black.withOpacity(0.4),
                    colorBlendMode: BlendMode.darken,
                  )
                      : Container(color: Colors.grey),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Description', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(groupData['description'] ?? 'No description provided.'),
                        const Divider(height: 32),
                        Text('Members (${members.length})', style: Theme.of(context).textTheme.titleLarge),
                      ],
                    ),
                  ),
                  ...members.map((memberId) => FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(memberId).get(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) return const ListTile(title: Text("Loading..."));
                      final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                      final photoURL = userData?['photoURL'] as String?;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: (photoURL != null && photoURL.isNotEmpty) ? NetworkImage(photoURL) : null,
                          child: (photoURL == null || photoURL.isEmpty) ? const Icon(Icons.person) : null,
                        ),
                        title: Text(userData?['email'] ?? 'Unknown User'),
                      );
                    },
                  )),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: isMember
                        ? ElevatedButton.icon(
                      onPressed: () => _exitGroup(context, groupId),
                      icon: const Icon(Icons.exit_to_app),
                      label: const Text('Exit Group'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    )
                        : const SizedBox.shrink(),
                  ),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _exitGroup(BuildContext context, String groupId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayRemove([user.uid]),
      });
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}