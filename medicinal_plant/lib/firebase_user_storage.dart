import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Replace with your actual Firebase project configuration
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

Future<void> storeUserDetails(String name, String email, String password) async {
  // Get the current logged-in user
  final User? user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    // Reference to the user document in Firestore
    final userDocRef = _firestore.collection('users').doc(user.uid);

    // Prepare user data
    final userData = {
      'name': name,
      'email': email,
      'password': password, // Remove password field if not needed
      'language': 'en',
      // Add other relevant user details here
    };

    try {
      // Attempt to update the user document
      await userDocRef.update(userData);
      print('User details updated successfully!');
    } catch (e) {
      // If the document does not exist, create it with set()
      if (e.toString().contains("NOT_FOUND")) {
        await userDocRef.set(userData);
        print('Document did not exist. User details set successfully!');
      } else {
        print('Error updating user details: $e');
      }
    }
  } else {
    print('No user logged in!');
  }
}
