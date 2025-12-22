import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      await _sendOneSignalPush(recipientId, title, body, type: type, relatedId: relatedId);
      
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  static Future<void> _sendOneSignalPush(String externalUserId, String title, String message, {String? type, String? relatedId}) async {
      try {
        print('🔔 Attempting to send OneSignal notification...');
        print('   Recipient External ID: $externalUserId');
        print('   Title: $title');
        print('   Message: $message');
        
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
          "data": {
            "type": type ?? "system",
            "relatedId": relatedId ?? "",
          },
          "small_icon": "ic_stat_onesignal_default",
          "android_accent_color": "FF2E7D32"
        };
        
        // DEBUG: Check if we can target by Player ID directly for testing
        // Only works if we are sending to ourselves or have the player ID stored
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null && externalUserId == currentUser.uid) {
           print('🔔 Sending to self: Adding player_id fallback');
           final playerId = OneSignal.User.pushSubscription.id;
           if (playerId != null) {
              // Add player_id to target specific device
              request['include_player_ids'] = [playerId];
              // Remove aliases if using player_ids to avoid conflict (optional, but safer)
              request.remove('include_aliases');
              print('   Using Player ID: $playerId');
           }
        }

        print('📤 OneSignal Request: ${json.encode(request)}');

        var client = http.Client();
        var response = await client.post(
          Uri.parse('https://onesignal.com/api/v1/notifications'),
          headers: header,
          body: json.encode(request),
        );
        
        print('📥 OneSignal Response Status: ${response.statusCode}');
        print('📥 OneSignal Response Body: ${response.body}');
        
        if (response.statusCode != 200) {
           print("❌ OneSignal Error: ${response.body}");
           final errorData = json.decode(response.body);
           print("   Error Details: ${errorData['errors']}");
        } else {
           final responseData = json.decode(response.body);
           print("✅ OneSignal Success!");
           print("   Recipients: ${responseData['recipients']}");
           print("   External User IDs: ${responseData['external_id']}");
           
           if (responseData['recipients'] == 0) {
             print("⚠️ WARNING: 0 recipients! User may not be subscribed to OneSignal.");
             print("   Check OneSignal Dashboard → Audience for external_id: $externalUserId");
             
             // Debug Subscription Status
             print('   Current Player ID: ${OneSignal.User.pushSubscription.id}');
             print('   Current OptedIn: ${OneSignal.User.pushSubscription.optedIn}');
           }
        }

      } catch (e) {
        print("❌ OneSignal Exception: $e");
        print("   Stack trace: ${StackTrace.current}");
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
