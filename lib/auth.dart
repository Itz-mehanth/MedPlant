import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => null;


  Future<void> loginWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    final GoogleSignInAuthentication? googleAuth =
    await googleUser?.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<UserCredential?> signInWithEmailAndPassword(
      {required String email, required String password}) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential') {
        print(
            'The supplied auth credential is incorrect, malformed or has expired.');
        // Handle reauthentication or ask the user to input correct credentials.
      } else {
        print('An unknown error occurred: ${e.message}');
      }
    }
    return null;
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      print('Successfully signed out'); // Optional: Log success message
    } on Exception catch (e) {
      print('Error signing out: $e'); // Log error message for debugging
      // Handle errors here (optional)
    }
  }

  Future<UserCredential?> signUpWithEmailandPassword(
      {required String email, required String password}) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      // ignore: avoid_print
      // print(e);
    }
    return null;
  }
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

}
