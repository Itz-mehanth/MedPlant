import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:medicinal_plant/login_register_page.dart';
import 'package:medicinal_plant/widget_tree.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class SplashScreen extends StatefulWidget {
  // ignore: use_key_in_widget_constructors
  const SplashScreen({Key? key});

  @override
  // ignore: library_private_types_in_public_api
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // Start the timer to navigate after a few seconds
    Timer(const Duration(seconds: 7), () async {
      // Navigate to the next screen after 3 seconds == n
      if (user != null && user!.emailVerified) {
        // Log in to OneSignal for persisted session
        print('🔔 [Splash] Persisted user found. Logging into OneSignal: ${user!.uid}');
        
        // CRITICAL: Request permission first
        print('🔔 [Splash] Requesting notification permission...');
        final hasPermission = await OneSignal.Notifications.requestPermission(true);
        print('🔔 [Splash] Permission granted: $hasPermission');
        
        // Login to OneSignal
        OneSignal.login(user!.uid);
        
        // Wait for login to complete
        await Future.delayed(Duration(seconds: 3));
        
        // Check subscription status
        final playerId = OneSignal.User.pushSubscription.id;
        final isSubscribed = OneSignal.User.pushSubscription.optedIn ?? false;
        
        print('🔔 [Splash] OneSignal Status:');
        print('   Player ID: $playerId');
        print('   Subscribed: $isSubscribed');
        
        if (playerId == null || playerId.isEmpty) {
          print('❌ [Splash] ERROR: Player ID is null/empty! OneSignal not working.');
          print('   This means push notifications will NOT work.');
          print('   Check: 1) Notification permission 2) OneSignal App ID 3) Internet connection');
        }
        
        Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (BuildContext context) => const WidgetTree()
              ),
            );
      } else {
        Navigator.pushNamed(context, '/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      color: Colors.white,
      child: SizedBox(
        height: double.infinity,
        width: MediaQuery.of(context).size.width,
        child: Center(
          child: Lottie.asset('assets/animations/plantgrowth.json',
              fit: BoxFit.contain, repeat: false),
        ),
      ),
    ));
  }
}
