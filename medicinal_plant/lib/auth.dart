import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => null;


  Future<void> loginWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn(
      scopes: ['email'],
      forceCodeForRefreshToken: true,
    ).signIn();

    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Attempt to sign in with the provided credentials
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('Sign-in successful for user: ${userCredential.user?.email}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle FirebaseAuth-specific errors
      switch (e.code) {
        case 'user-not-found':
          print('Error: No user found for that email.');
          break;
        case 'wrong-password':
          print('Error: Incorrect password provided for that email.');
          break;
        case 'user-disabled':
          print('Error: This user account has been disabled.');
          break;
        case 'invalid-email':
          print('Error: The email address is not valid.');
          break;
        default:
          print('FirebaseAuthException: ${e.message}');
      }
    } catch (e) {
      // Handle unexpected errors
      print('Unexpected error: $e');
    }

    // Return null if sign-in fails
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

  Future<UserCredential?> signUpWithEmailandPassword({
    required String email,
    required String password,
  }) async {
      // Attempt to create user
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('User created successfully: ${userCredential.user?.email}');
      return userCredential;

  }

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

}
