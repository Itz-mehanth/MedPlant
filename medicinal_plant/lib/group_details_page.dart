import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupDetailsPage extends StatefulWidget {
  final String groupId;

  GroupDetailsPage({required this.groupId});

  @override
  _GroupDetailsPageState createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  Map<String, dynamic>? groupData;
  bool isMember = false;
  String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  TextEditingController messageController = TextEditingController();

  Future<void> loadGroupDetails() async {
    DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .get();

    if (groupSnapshot.exists) {
      setState(() {
        groupData = groupSnapshot.data() as Map<String, dynamic>?;
        groupData?['id'] = widget.groupId; // Add group ID to the group data
        isMember = groupData?['members']?.contains(currentUserId) ?? false;
      });
    }
  }

  Future<void> joinGroup() async {
    if (currentUserId != null) {
      await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
        'members': FieldValue.arrayUnion([currentUserId]),
      });

      // Update user's joined groups in their document
      await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
        'joined_groups': FieldValue.arrayUnion([widget.groupId]),
      });

      setState(() {
        isMember = true;
        loadGroupDetails();
      });
    }
  }

  // Sending a message
  Future<void> sendMessage() async {
    if (messageController.text.isNotEmpty && currentUserId != null) {
      await FirebaseFirestore.instance.collection('groups')
          .doc(widget.groupId)
          .collection('messages')
          .add({
        'sender_id': currentUserId,
        'content': messageController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      messageController.clear();
    }
  }

  // Uploading a file (image, PDF, Word)
  Future<void> uploadFile() async {
    // Open file picker
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      // Get the picked file
      File file = File(result.files.single.path!);

      // Upload the file to Firebase Storage
      try {
        // Create a reference to the Firebase Storage location
        final storageRef = FirebaseStorage.instance.ref().child('groups/${groupData?['name']}/${DateTime.now().millisecondsSinceEpoch}');

        // Upload the file
        await storageRef.putFile(file);

        // Get the file's URL after upload
        String fileUrl = await storageRef.getDownloadURL();

        // Send message with the file URL
        await FirebaseFirestore.instance.collection('groups')
            .doc(widget.groupId)
            .collection('messages')
            .add({
          'sender_id': currentUserId,
          'content': 'Sent an image', // Or other file description
          'file_url': fileUrl,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print("File upload failed: $e");
      }
    } else {
      print("No file selected");
    }
  }

  @override
  void initState() {
    super.initState();
    if (currentUserId != null) {
      loadGroupDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (groupData == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Group Details")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(groupData?['name'] ?? "Unknown Group"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: groupData?['profile_picture'] != null
                    ? NetworkImage(groupData!['profile_picture'])
                    : null,
                child: groupData?['profile_picture'] == null
                    ? Icon(Icons.group, size: 50)
                    : null,
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Group Name: ${groupData?['name'] ?? "N/A"}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Description: ${groupData?['description'] ?? "N/A"}",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              "Created By: ${groupData?['created_by'] ?? "Unknown"}",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              "Members: ${groupData?['members']?.length ?? 0}",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            if (!isMember)
              Center(
                child: ElevatedButton(
                  onPressed: joinGroup,
                  child: Text("Join Group"),
                ),
              ),
            if (isMember)
              Center(
                child: Text(
                  "You are a member of this group",
                  style: TextStyle(color: Colors.green, fontSize: 16),
                ),
              ),
            SizedBox(height: 30),
            // Chat Section
            if (isMember)
            TextField(
              controller: messageController,
              decoration: InputDecoration(
                labelText: "Send a message...",
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ),
            ),
            SizedBox(height: 10),
            // Here, you could implement a file picker for PDFs/Images
            if (isMember)
            ElevatedButton(
              onPressed: () => uploadFile,
              child: Text("Send File (Image/PDF)"),
            ),
            SizedBox(height: 20),
            // Displaying chat messages
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('groups')
                    .doc(widget.groupId)
                    .collection('messages')
                    .orderBy('timestamp')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  var messages = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var message = messages[index];
                      return ListTile(
                        title: Text(message['content'] ?? 'No message'),
                        subtitle: Text('Sender ID: ${message['sender_id']}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
