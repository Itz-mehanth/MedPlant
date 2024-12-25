import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'group_details_page.dart';

class GroupsPage extends StatefulWidget {
  @override
  _GroupsPageState createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  List<Map<String, dynamic>> joinedGroups = [];
  List<Map<String, dynamic>> searchedGroups = [];
  TextEditingController searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? profilePicture;


  @override
  void initState() {
    super.initState();
    loadJoinedGroups();
  }

  Future<void> loadJoinedGroups() async {
    final User? user = FirebaseAuth.instance.currentUser;
    String? userId = user?.uid;

    if (userId == null) {
      return; // Handle case where userId is null
    }

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('groups')
        .where('members', arrayContains: userId)
        .get();

    setState(() {
      joinedGroups = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add group ID to the group data
        return data;
      }).toList();
    });
  }


  Future<void> searchGroups(String query) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('groups')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    setState(() {
      searchedGroups = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    });
  }

  Future<void> createGroup(String name, String description) async {
    final User? user = FirebaseAuth.instance.currentUser;
    String? userId = user?.uid;
    String groupId = FirebaseFirestore.instance.collection('groups').doc().id;
    String groupLink = 'https://medplant.com/group/$groupId';

    // Upload profile picture
    String profilePictureUrl = "";
    if (profilePicture != null) {
      String filePath = 'groups/$name/profile_picture/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(filePath);
      await storageRef.putFile(profilePicture!);
      profilePictureUrl = await storageRef.getDownloadURL();
    }

    // Save group data to Firestore
    await FirebaseFirestore.instance.collection('groups').doc(groupId).set({
      'name': name,
      'description': description,
      'created_by': userId,
      'members': [userId],
      'group_link': groupLink,
      'profile_picture': profilePictureUrl,
      'created_at': FieldValue.serverTimestamp(),
    });

    setState(() {
      loadJoinedGroups(); // Refresh joined groups
    });
  }

  void pickProfilePicture() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        profilePicture = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Groups"),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // Navigate to the search page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchGroupsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          ...joinedGroups.map((group) => ListTile(
            leading: CircleAvatar(
              backgroundImage: group['profile_picture'] != null
                  ? NetworkImage(group['profile_picture'])
                  : null,
              child: group['profile_picture'] == null
                  ? Icon(Icons.group)
                  : null,
            ),
            title: Text(group['name']),
            subtitle: Text(group['description']),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupDetailsPage(groupId: group['id']), // Pass the group ID
                ),
              );
            },
          )),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          showCreateGroupDialog();
        },
      ),
    );
  }


  void showCreateGroupDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Create Group"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(hintText: "Group Name"),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(hintText: "Description"),
              ),
              SizedBox(height: 10),
              TextButton.icon(
                onPressed: pickProfilePicture,
                icon: Icon(Icons.image),
                label: Text("Upload Profile Picture"),
              ),
              if (profilePicture != null)
                Image.file(
                  profilePicture!,
                  height: 100,
                  width: 100,
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                createGroup(nameController.text, descriptionController.text);
                Navigator.pop(context);
              },
              child: Text("Create"),
            ),
          ],
        );
      },
    );
  }
}


class SearchGroupsPage extends StatefulWidget {
  @override
  _SearchGroupsPageState createState() => _SearchGroupsPageState();
}

class _SearchGroupsPageState extends State<SearchGroupsPage> {
  List<Map<String, dynamic>> searchedGroups = [];
  TextEditingController searchController = TextEditingController();

  Future<void> searchGroups(String query) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('groups')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    setState(() {
      searchedGroups = snapshot.docs.map((doc) {
        // Add the document ID to the group's data
        Map<String, dynamic> groupData = doc.data() as Map<String, dynamic>;
        groupData['id'] = doc.id; // Include the document ID as a field
        return groupData;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Search Groups"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(hintText: "Enter group name"),
              onChanged: (value) async {
                await searchGroups(value);
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: searchedGroups.length,
              itemBuilder: (context, index) {
                final group = searchedGroups[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: group['profile_picture'] != null
                        ? NetworkImage(group['profile_picture'])
                        : null,
                    child: group['profile_picture'] == null
                        ? Icon(Icons.group)
                        : null,
                  ),
                  title: Text(group['name']),
                  subtitle: Text(group['description']),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupDetailsPage(groupId: group['id']),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
