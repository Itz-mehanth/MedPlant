import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:medicinal_plant/utils/notification_service.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Notifications')),
        body: Center(child: Text('Please login to view notifications')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!.docs;

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No notifications yet', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final data = notification.data() as Map<String, dynamic>;
              final isRead = data['isRead'] ?? false;
              final type = data['type'] ?? 'system';
              final timestamp = data['timestamp'] as Timestamp?;
              
              IconData icon;
              Color iconColor;
              switch (type) {
                case 'like':
                  icon = Icons.favorite;
                  iconColor = Colors.red;
                  break;
                case 'comment':
                  icon = Icons.comment;
                  iconColor = Colors.blue;
                  break;
                case 'review':
                  icon = Icons.star;
                  iconColor = Colors.amber;
                  break;
                case 'message':
                  icon = Icons.chat;
                  iconColor = Colors.green;
                  break;
                default:
                  icon = Icons.notifications;
                  iconColor = Colors.grey;
              }

              return Container(
                color: isRead ? Colors.transparent : Colors.green.withOpacity(0.05),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: iconColor.withOpacity(0.1),
                    child: Icon(icon, color: iconColor),
                  ),
                  title: Text(
                    data['title'] ?? 'Notification',
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['body'] ?? ''),
                      SizedBox(height: 4),
                      Text(
                        timestamp != null 
                            ? DateFormat.yMMMd().add_jm().format(timestamp.toDate())
                            : 'Just now',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Mark as read
                    if (!isRead) {
                      NotificationService.markAsRead(user.uid, notification.id);
                    }
                    // Handle navigation based on type/relatedId if needed
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
