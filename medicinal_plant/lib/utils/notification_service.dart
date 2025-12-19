import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicinal_plant/keys.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationService {
  static const String _oneSignalAppId = Keys.oneSignalAppId;
  static const String _oneSignalApiKey = Keys.oneSignalApiKey;

  // Add Notification to Firestore and send OneSignal
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

      // 2. Send OneSignal Push via REST API
      // Note: In production, this should be done via a backend (Cloud Functions)
      // to avoid exposing the API Key. For this prototype, we do it client-side.
      await _sendOneSignalPush(recipientId, title, body);
      
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  static Future<void> _sendOneSignalPush(String externalUserId, String title, String message) async {
      try {
        var header = {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Basic $_oneSignalApiKey"
        };

        var request = {
          "app_id": _oneSignalAppId,
          "include_aliases": {
            "external_id": [externalUserId]
          },
          "target_channel": "push",
          "headings": {"en": title},
          "contents": {"en": message},
          "small_icon": "ic_stat_onesignal_default", // Ensure you have this icon resource or use default
          "android_accent_color": "FF2E7D32" // Green color
        };

        var client = http.Client();
        var response = await client.post(
          Uri.parse('https://onesignal.com/api/v1/notifications'),
          headers: header,
          body: json.encode(request),
        );
        
        if (response.statusCode != 200) {
           print("OneSignal Error: ${response.body}");
           // Fallback: Try targeting by Player ID if stored, currently simplified to alias.
        } else {
           print("OneSignal Success: ${response.body}");
        }

      } catch (e) {
        print("OneSignal Exception: $e");
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
