import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// OneSignal Diagnostic Widget
/// Add this to any page to check OneSignal status
class OneSignalDiagnostic extends StatefulWidget {
  const OneSignalDiagnostic({Key? key}) : super(key: key);

  @override
  State<OneSignalDiagnostic> createState() => _OneSignalDiagnosticState();
}

class _OneSignalDiagnosticState extends State<OneSignalDiagnostic> {
  String playerId = 'Loading...';
  String userId = 'Loading...';
  String optedIn = 'Loading...';
  String token = 'Loading...';
  bool isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  void _checkStatus() {
    setState(() {
      playerId = OneSignal.User.pushSubscription.id ?? 'NULL';
      userId = FirebaseAuth.instance.currentUser?.uid ?? 'Not logged in';
      optedIn = (OneSignal.User.pushSubscription.optedIn ?? false).toString();
      token = OneSignal.User.pushSubscription.token ?? 'NULL';
      isSubscribed = playerId != 'NULL' && playerId.isNotEmpty;
    });

    print('=== OneSignal Diagnostic ===');
    print('Player ID: $playerId');
    print('User ID: $userId');
    print('Opted In: $optedIn');
    print('Token: $token');
    print('Subscribed: $isSubscribed');
    print('===========================');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSubscribed ? Icons.check_circle : Icons.error,
                  color: isSubscribed ? Colors.green : Colors.red,
                ),
                SizedBox(width: 8),
                Text(
                  'OneSignal Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(),
            SizedBox(height: 8),
            _buildStatusRow('Subscribed', isSubscribed ? 'YES ✅' : 'NO ❌'),
            _buildStatusRow('Player ID', playerId),
            _buildStatusRow('User ID', userId),
            _buildStatusRow('Opted In', optedIn),
            _buildStatusRow('Token', token.length > 20 ? '${token.substring(0, 20)}...' : token),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _checkStatus();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Status refreshed!')),
                      );
                    },
                    icon: Icon(Icons.refresh),
                    label: Text('Refresh'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final permission = await OneSignal.Notifications.requestPermission(true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(permission 
                            ? 'Permission granted!' 
                            : 'Permission denied'),
                        ),
                      );
                      _checkStatus();
                    },
                    icon: Icon(Icons.notifications),
                    label: Text('Request Permission'),
                  ),
                ),
              ],
            ),
            if (!isSubscribed) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ Not Subscribed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Push notifications will NOT work. Check:\n'
                      '1. OneSignal App ID in keys.dart\n'
                      '2. Notification permission\n'
                      '3. Internet connection\n'
                      '4. FCM configuration in OneSignal',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
