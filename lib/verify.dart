import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:medicinal_plant/home_page.dart';

class Verify extends StatefulWidget {
  const Verify({super.key});

  @override
  State<Verify> createState() => VerifyState();
}

class VerifyState extends State<Verify> {
  @override
  void initState() {
    sendVerifylink();
    super.initState();
  }

  Future<void> sendVerifylink() async {
    final user = FirebaseAuth.instance.currentUser!;
    try {
      await user.sendEmailVerification();
      Get.snackbar(
        'Link sent',
        'A link has been sent to your email address',
        margin: const EdgeInsets.all(30),
        snackPosition: SnackPosition.BOTTOM,
      );
    } on FirebaseAuthException catch (e) {
      // Handle verification email sending errors (optional)
      print('Error sending verification link: $e');
      Get.snackbar(
        'Error',
        e.message!,
        margin: const EdgeInsets.all(30),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> reloadAndNavigate() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.reload();
      if (user.emailVerified) {
        Get.offAll(() => const WelcomeScreen()); // Navigate and remove previous screens
      } else {
        // Handle the case where the email is still not verified (optional)
        Get.snackbar(
          'Verification Pending',
          'Please check your email and verify your account.',
          margin: const EdgeInsets.all(30),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } on FirebaseAuthException catch (e) {
      // Handle errors during reload (optional)
      print('Error reloading user: $e');
      Get.snackbar(
        'Error',
        e.message!,
        margin: const EdgeInsets.all(30),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... rest of your Verify screen UI
      floatingActionButton: FloatingActionButton.extended(
        onPressed: reloadAndNavigate, // Call the combined reload and navigate method
        label: const Text('Verify and Continue'),
        icon: const Icon(Icons.check),
      ),
    );
  }
}
