// lib/groups_page .dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'group_details_page.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  _GroupsPageState createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Groups"),
        backgroundColor: const Color.fromARGB(255, 68, 255, 0),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateGroupDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search your groups...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .where('members', arrayContains: currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: SizedBox(
                        width: 40, // Equal width
                        height: 40, // Equal height
                        child: CircularProgressIndicator(),
                      )
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "You haven't joined any groups yet.\nFind one or create your own!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                var joinedGroups = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  var name = data['name'] as String? ?? '';
                  return name.toLowerCase().contains(_searchQuery.toLowerCase());
                }).toList();

                if (joinedGroups.isEmpty) {
                  return const Center(
                    child: Text(
                      "No groups found with that name.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: joinedGroups.length,
                  itemBuilder: (context, index) {
                    var groupDoc = joinedGroups[index];
                    var group = groupDoc.data() as Map<String, dynamic>;
                    return _buildGroupCard(group, groupDoc.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.search),
        tooltip: "Find New Groups",
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SearchGroupsPage()),
          );
        },
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group, String groupId) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundImage: (group['profile_picture'] != null && group['profile_picture'].isNotEmpty)
              ? NetworkImage(group['profile_picture'])
              : null,
          child: (group['profile_picture'] == null || group['profile_picture'].isEmpty)
              ? const Icon(Icons.group, size: 25)
              : null,
        ),
        title: Text(group['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          group['description'],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupChatPage(
                groupId: groupId,
                groupName: group['name'],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    File? profilePicture;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Create a New Group"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (profilePicture != null)
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: FileImage(profilePicture!),
                      ),
                    TextButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setDialogState(() {
                            profilePicture = File(pickedFile.path);
                          });
                        }
                      },
                      icon: const Icon(Icons.image),
                      label: const Text("Select Profile Picture"),
                    ),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Group Name"),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: "Description"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      _createGroup(
                        nameController.text,
                        descriptionController.text,
                        profilePicture,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Create"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createGroup(String name, String description, File? imageFile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String groupId = FirebaseFirestore.instance.collection('groups').doc().id;
    String profilePictureUrl = "";

    if (imageFile != null) {
      String filePath = 'groups/$groupId/profile_picture.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(filePath);
      await storageRef.putFile(imageFile);
      profilePictureUrl = await storageRef.getDownloadURL();
    }

    await FirebaseFirestore.instance.collection('groups').doc(groupId).set({
      'name': name,
      'description': description,
      'created_by': user.uid,
      'members': [user.uid],
      'profile_picture': profilePictureUrl,
      'created_at': FieldValue.serverTimestamp(),
    });
  }
}

class SearchGroupsPage extends StatefulWidget {
  const SearchGroupsPage({super.key});

  @override
  _SearchGroupsPageState createState() => _SearchGroupsPageState();
}

class _SearchGroupsPageState extends State<SearchGroupsPage> {
  List<Map<String, dynamic>> _searchedGroups = [];
  final TextEditingController _searchController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _searchGroups(String query) async {
    if (query.isEmpty) {
      setState(() => _searchedGroups = []);
      return;
    }
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('groups')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    setState(() {
      _searchedGroups = snapshot.docs.map((doc) {
        Map<String, dynamic> groupData = doc.data() as Map<String, dynamic>;
        groupData['id'] = doc.id;
        return groupData;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Find Groups"),
        backgroundColor: const Color.fromARGB(255, 68, 255, 0),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(hintText: "Enter group name to find"),
              onChanged: _searchGroups,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchedGroups.length,
              itemBuilder: (context, index) {
                final group = _searchedGroups[index];
                final bool isMember = (group['members'] as List).contains(currentUser?.uid);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (group['profile_picture'] != null && group['profile_picture'].isNotEmpty)
                        ? NetworkImage(group['profile_picture'])
                        : null,
                    child: (group['profile_picture'] == null || group['profile_picture'].isEmpty)
                        ? const Icon(Icons.group)
                        : null,
                  ),
                  title: Text(group['name']),
                  subtitle: Text(group['description']),
                  trailing: isMember
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : ElevatedButton(
                    child: const Text('Join'),
                    onPressed: () => _joinGroup(group['id']),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupChatPage(
                          groupId: group['id'],
                          groupName: group['name'],
                        ),
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

  Future<void> _joinGroup(String groupId) async {
    if (currentUser != null) {
      await FirebaseFirestore.instance.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayUnion([currentUser!.uid]),
      });
      // Optionally refresh search to update UI
      _searchGroups(_searchController.text);
    }
  }
}