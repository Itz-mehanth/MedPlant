import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:medicinal_plant/keys.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

Future<void> sendGroupNotification(List<String> deviceTokens, String message) async {
  final String onesignalAppId = "b2b54cd9-5f66-4f46-9c2d-8a62257a702d"; // Replace with your app ID
  final String onesignalApiKey = ONE_SIGNAL_KEY; // Replace with your API key

  final url = "https://onesignal.com/api/v1/notifications";
  final headers = {
    "Content-Type": "application/json; charset=utf-8",
    "Authorization": "Basic $onesignalApiKey",
  };

  final payload = json.encode({
    "app_id": onesignalAppId,
    "include_player_ids": deviceTokens,
    "contents": {"en": message},
    "headings": {"en": "New Message in Your Group"},
    "data": {"customKey": "customValue"}, // Optional custom data
  });

  final response = await http.post(Uri.parse(url), headers: headers, body: payload);
  if (response.statusCode == 200) {
    print("Notification sent successfully!");
  } else {
    print("Failed to send notification: ${response.body}");
  }
}

Future<void> saveDeviceTokenToFirestore(String userId) async {
  // Get the device token from OneSignal
  String? deviceToken = OneSignal.User.pushSubscription.id;

  if (deviceToken != null) {
    // Store the device token in Firestore under the user's document
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'device_token': deviceToken,
    });
  } else {
    print('Device token not found');
  }
}