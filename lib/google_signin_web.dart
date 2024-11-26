import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

// import 'package:http/http.dart' as http;
// import 'dart:convert' show json;

class AuthService with ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '1085343678758-v35fjludn62fbrsgje6mkeo5tadq8049.apps.googleusercontent.com',
    scopes: ['email'],
  );

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  bool get isLoggedIn => currentUser != null;

  Future<void> signInWithGoogle() async {
    try {
      // Try signing in silently (without user interaction)
      GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();

      // If silent sign-in fails, prompt for manual sign-in
      if (googleUser == null) {
        print("Silent sign-in failed. Prompting manual sign-in.");
        googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          print("Manual sign-in was cancelled or failed.");
          return; // Stop if sign-in was cancelled
        }
        print("Manual sign-in successful.");
      } else {
        print("Silent sign-in successful.");
      }

      // Proceed only if googleUser is not null
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        // Check if authentication tokens are valid
        if (googleAuth.accessToken != null && googleAuth.idToken != null) {
          final OAuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          // Sign in to Firebase with the Google credential
          UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

          if (userCredential.user != null) {
            print('Signed in with email: ${userCredential.user?.email}');
          } else {
            print("Error: Firebase user is null.");
          }
        } else {
          print("Error: Google authentication tokens are null.");
        }
      }
      
      notifyListeners(); // Notify listeners about the sign-in status
    } catch (e) {
      print('Error signing in with Google: $e');
    }

    print("Sign-in process completed");
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
