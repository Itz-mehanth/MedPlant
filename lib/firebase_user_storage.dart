import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Replace with your actual Firebase project configuration
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

Future<void> storeUserDetails(String name, String email, String password) async {
  // Get the current logged-in user
  final User? user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    // Create a new document in Firestore with the user ID
    final userDocRef = _firestore.collection('users').doc(user.uid);

    // Prepare user data
    final userData = {
      'name': name,
      'email': email,
      'password':password,
      'language': 'en'
      // Add other relevant user details here
    };

    // Update the user document with the data
    await userDocRef.set(userData);

    print('User details stored successfully!');
  } else {
    print('No user logged in!');
  }
}
