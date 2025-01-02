import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_user_storage.dart';
import 'notifications.dart';

// import 'package:http/http.dart' as http;
// import 'dart:convert' show json;

class AuthService with ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    forceCodeForRefreshToken: true,
  );

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  bool get isLoggedIn => currentUser != null;

  Future<void> signInWithGoogle() async {
    try {
      // Attempt silent sign-in
      final googleUser = await _googleSignIn.signInSilently();

      // If silent sign-in fails, prompt the user for explicit sign-in
      final GoogleSignInAccount? user = googleUser ?? await _googleSignIn.signIn();
      if (user == null) {
        print("User canceled the sign-in process.");
        return; // Exit if the user cancels the sign-in
      }

      // Proceed with authentication
      final GoogleSignInAuthentication googleAuth = await user.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      print('Signed in with email: ${userCredential.user?.email}');

      // Store user details
      try {
        await storeUserDetails(" ", userCredential.user!.email!, " ");
      } catch (e) {
        print("Error storing user details: $e");
      }

      // Get current user ID
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        // Save device token
        try {
          await saveDeviceTokenToFirestore(userId);
        } catch (e) {
          print("Error saving device token: $e");
        }
      } else {
        print("User is not signed in.");
      }

      notifyListeners(); // Notify listeners about the sign-in status
    } catch (e) {
      print('Error signing in with Google: $e');
    }

    print("Sign-in process completed.");
  }


  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      print('Signed out successfully');
      notifyListeners(); // Notify listeners about the sign-out status
    } catch (e) {
      print('Error signing out with Google: $e');
    }
  }

  // Future<void> getContactInformation() async {
  //   if (currentUser == null) return;
  //   final http.Response response = await http.get(
  //     Uri.parse('https://people.googleapis.com/v1/people/me/connections'
  //         '?requestMask.includeField=person.names'),
  //     headers: await currentUser!.authHeaders,
  //   );
  //   if (response.statusCode != 200) {
  //     print('Error getting contact information: ${response.statusCode}');
  //     return;
  //   }
  //   final Map<String, dynamic> data = json.decode(response.body);
  //   final String? namedContact = _pickFirstNamedContact(data);
  //   print('Contact information: $namedContact');
  // }

  // String? _pickFirstNamedContact(Map<String, dynamic> data) {
  //   // Implement your logic to extract the contact information
  // }
}
