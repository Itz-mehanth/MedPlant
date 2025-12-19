import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:medicinal_plant/SocialFeedPage.dart';

class SavedPostsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Scaffold();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Saved Posts', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup('posts')
            .where('saved_by', arrayContains: user.uid)
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
             return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 48),
                      SizedBox(height: 16),
                      Text('Error loading saved posts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      SelectableText(
                        'This might require a composite index.\n\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ],
                  ),
                ),
              );
          }

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator(color: Colors.green));
          }

          final posts = snapshot.data!.docs;

          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 64, color: Colors.grey.shade300),
                  SizedBox(height: 16),
                  Text('No saved posts yet', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final doc = posts[index];
              final data = doc.data() as Map<String, dynamic>;
              
              // Extract userId safely
              final segments = doc.reference.path.split('/');
              final userIdIndex = segments.indexOf('users') + 1;
              final userId = userIdIndex > 0 && userIdIndex < segments.length
                  ? segments[userIdIndex]
                  : '';

              return PostWidget(
                post: data,
                postId: doc.id,
                userId: userId,
                currentUser: user,
              );
            },
          );
        },
      ),
    );
  }
}
