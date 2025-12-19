import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicinal_plant/keys.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:intl/intl.dart';

class NotificationService {
  static const String _oneSignalAppId = Keys.oneSignalAppId;

  // Add Notification to Firestore and (mock) send OneSignal
  static Future<void> sendNotification({
    required String recipientId,
    required String title,
    required String body,
    required String type, // 'like', 'comment', 'review', 'system'
    String? relatedId, // postId or productId
  }) async {
    try {
      // 1. Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(recipientId)
          .collection('notifications')
          .add({
        'title': title,
        'body': body,
        'type': type,
        'relatedId': relatedId,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Send OneSignal Push (Needs REST API Key for real sending from device)
      // Since we don't have the key, we'll log it. 
      // In a real app with backend, you'd trigger a Cloud Function here.
      print('Notification saved for $recipientId: $title - $body');
      
      // If we could, we would do:
      // await OneSignal.postNotification(...); 
      
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  static Future<void> markAsRead(String userId, String notificationId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }
}
