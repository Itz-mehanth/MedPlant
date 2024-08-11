import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

// import 'package:http/http.dart' as http;
// import 'dart:convert' show json;

class AuthService with ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  bool get isLoggedIn => currentUser != null;

  Future<void> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signInSilently();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase with the Google credential
        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);

        print('Signed in with email: ${userCredential.user?.email}');
      }
      notifyListeners(); // Notify listeners about the sign-in status
    } catch (e) {
      print('Error signing in with Google: $e');
    }
    print("signin process completed");
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
