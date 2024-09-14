import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:medicinal_plant/login_register_page.dart';
import 'package:medicinal_plant/widget_tree.dart';

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
    Timer(const Duration(seconds: 7), () {
      // Navigate to the next screen after 3 seconds
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (BuildContext context) => user == null  ? const LoginPage() : user!.emailVerified ?  const WidgetTree() : const LoginPage(),
        ),
      );
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
              child: Lottie.asset(
                  'assets/animations/plantgrowth.json',
                  fit: BoxFit.contain,
                  repeat: false
              ),
            ),
          ),
        )
    );
  }
}
