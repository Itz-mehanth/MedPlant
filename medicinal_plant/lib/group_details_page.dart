import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'notifications.dart';

Map<String, dynamic>? groupData;
bool isMember = false;


class GroupChatPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatPage({required this.groupId, required this.groupName});

  @override
  _GroupChatPageState createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  TextEditingController messageController = TextEditingController();
  String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  String? profileURL = FirebaseAuth.instance.currentUser!.photoURL;

  Future<List<String>> getDeviceTokensForGroup(String groupId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .get();

    if (snapshot.exists) {
      final groupData = snapshot.data();
      final users = groupData?['members'] ?? {};

      // Assuming the user data contains a 'device_token' field for each user
      List<String> tokens = [];
      for (var userId in users) {
        final userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userSnapshot.exists) {
          final userData = userSnapshot.data();
          tokens.add(userData?['device_token']);
        }
      }
      return tokens;
    }
    return [];
  }

  void onMessageSent(String groupId, String message) async {
    // Get device tokens for the group
    List<String> deviceTokens = await getDeviceTokensForGroup(groupId);

    if (deviceTokens.isNotEmpty) {
      // Send notification to all users in the group
      await sendGroupNotification(deviceTokens, message);
    } else {
      print("No users found in the group.");
    }
  }

  Future<void> loadGroupDetails() async {
    DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .get();

    if (groupSnapshot.exists) {
      setState(() {
        groupData = groupSnapshot.data() as Map<String, dynamic>?;
        isMember = groupData?['members']?.contains(currentUserId) ?? false;
      });
    }
  }

  Future<void> joinGroup() async {
    if (currentUserId != null) {
      try {
        await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
          'members': FieldValue.arrayUnion([currentUserId]),
        });

        await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
          'joined_groups': FieldValue.arrayUnion([widget.groupId]),
        });

        setState(() {
          isMember = true;
        });
        loadGroupDetails();
      } catch (e) {
        print("Error joining group: $e");
      }
    }
  }

  @override
  void initState() {
    super.initState();
    loadGroupDetails();
  }

  Future<void> sendMessage() async {
    if (messageController.text.isNotEmpty && currentUserId != null) {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('messages')
          .add({
        'sender_id': currentUserId,
        'content': messageController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      var text = messageController.text;
      onMessageSent(widget.groupId, text);
      messageController.clear();
    }
  }

  Future<String> getUserEmail(String userId) async {
    DocumentSnapshot userSnapshot =
    await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userSnapshot.exists
        ? (userSnapshot.data() as Map<String, dynamic>)['email'] ?? 'Unknown'
        : 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () {
            // Navigate to the Group Details Page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupDetailsPage(groupId: widget.groupId),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                  backgroundImage: groupData?['profile_picture'] != null
                      ? NetworkImage(groupData!['profile_picture'])
                      : null,
                  child: groupData?['profile_picture'] == null
                      ? Icon(Icons.group, size: 40)
                      : null,
              ),
              SizedBox(width: 10),
              Text(widget.groupName),
            ],
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 68, 255, 0),
        automaticallyImplyLeading: true,
          actions: [
            if(!isMember)
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                joinGroup();
              },
            ),
          ]
      ),
      body: Column(
        children: [
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
                  return Center(child: SizedBox());
                }
                var messages = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    bool isCurrentUser = message['sender_id'] == currentUserId;

                    return FutureBuilder<String>(
                      future: getUserEmail(message['sender_id']),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return CircularProgressIndicator();
                        }
                        String senderEmail = userSnapshot.data!;

                        return Align(
                          alignment: isCurrentUser
                              ? Alignment.centerRight // Align current user's messages to the right
                              : Alignment.centerLeft, // Align others' messages to the left
                          child: Container(
                            width: MediaQuery.of(context).size.width / 2,
                            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isCurrentUser ? Colors.blue[100] : Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child:
                                Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    // Show sender email only for others' messages
                                    Row(
                                      children: [
                                        if (isCurrentUser)
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundImage: profileURL != null
                                              ? NetworkImage(profileURL!)
                                              : AssetImage('assets/userIcon.jpg') as ImageProvider, // This works fine for backgroundImage
                                        ),
                                        SizedBox(width: 5),
                                        if (!isCurrentUser)
                                        Text(
                                          senderEmail,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        if (isCurrentUser)
                                          Text(
                                            message['content'] ?? 'No message',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                      ]
                                    ),
                                  SizedBox(height: 5),
                                  if (!isCurrentUser)
                                  Text(
                                    message['content'] ?? 'No message',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          if(isMember)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      labelText: "Send a message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GroupDetailsPage extends StatefulWidget {
  final String groupId;

  GroupDetailsPage({required this.groupId});

  @override
  _GroupDetailsPageState createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  String? profileURL = FirebaseAuth.instance.currentUser!.photoURL;

  Future<void> exitGroup() async {
    if (currentUserId != null) {
      await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
        'members': FieldValue.arrayRemove([currentUserId]),
      });

      await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
        'joined_groups': FieldValue.arrayRemove([widget.groupId]),
      });

      setState(() {
        isMember = false;
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (groupData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Group Details"),
          backgroundColor: const Color.fromARGB(255, 68, 255, 0),
          automaticallyImplyLeading: true,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(groupData?['name'] ?? "Group Details"),
        backgroundColor: const Color.fromARGB(255, 68, 255, 0),
        automaticallyImplyLeading: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: groupData?['profile_picture'] != null
                  ? NetworkImage(groupData!['profile_picture'])
                  : null,
              child: groupData?['profile_picture'] == null
                  ? Icon(Icons.group, size: 40)
                  : null,
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
              "Members (${groupData?['members']?.length ?? 0}):",
              style: TextStyle(fontSize: 16),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: groupData?['members']?.length ?? 0,
                itemBuilder: (context, index) {
                  String memberId = groupData?['members'][index];
                  return ListTile(
                    title: FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(memberId).get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Text("Loading...");
                        }
                        var memberData = snapshot.data?.data() as Map<String, dynamic>?;
                        return Text(memberData?['email'] ?? "Unknown");
                      },
                    ),
                  );
                },
              ),
            ),
            if (isMember)
              ElevatedButton(
                onPressed: exitGroup,
                child: Text("Exit Group"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
