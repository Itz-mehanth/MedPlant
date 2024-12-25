import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:medicinal_plant/forget_password.dart';
import 'package:medicinal_plant/google_signin_web.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:medicinal_plant/home_page.dart';
import 'package:medicinal_plant/utils/global_functions.dart';
import 'package:medicinal_plant/widget_tree.dart';
import 'firebase_user_storage.dart';
import '../auth.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  bool isLogin = true;
  bool isLoading = false;
  String? _loginErrorMessage = '';
  String? _registerErrorMessage = '';

  final TextEditingController _controllerEmailLogin = TextEditingController();
  final TextEditingController _controllerpasswordLogin =
      TextEditingController();
  final TextEditingController _controllerEmailSignup = TextEditingController();
  final TextEditingController _controllerpasswordSignup =
      TextEditingController();
  final TextEditingController _controllernameSignup = TextEditingController();
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 10.0), // Slide in from the right
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.bounceIn,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel();
    super.dispose();
  }

  Future<void> signInWithEmailAndPassword() async {
    setState(() {
      isLoading = true;
      _loginErrorMessage = '';
    });

    String error;
    try {
      await Auth().signInWithEmailAndPassword(
        email: _controllerEmailLogin.text,
        password: _controllerpasswordLogin.text,
      );

      // Listen for auth state changes to confirm login
      Auth().authStateChanges.listen((User? user) {
        if (user != null && user.emailVerified) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const WidgetTree(),
            ),
          );
        }
      });
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          error = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          error = 'This account has been disabled. Please contact support.';
          break;
        case 'wrong-password':
          error = 'Incorrect password. Please try again.';
          break;
        case 'user-not-found':
          error = 'No account exists with the entered email address.';
          break;
        case 'network-request-failed':
          error = 'Network error. Please check your internet connection.';
          break;
        case 'invalid-credential':
          error = 'Please enter a valid credential';
          break;
        case 'user-mismatch':
          error = 'An error occurred during sign in. Please try again later.';
          break;
        default:
          error = 'An unknown error occurred.';
      }
      setState(() {
        _loginErrorMessage = error;
      });
      print(_loginErrorMessage);
    } catch (e) {
      switch (e.toString()) {
        case 'invalid-email':
          error = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          error = 'This account has been disabled. Please contact support.';
          break;
        case 'wrong-password':
          error = 'Incorrect password. Please try again.';
          break;
        case 'user-not-found':
          error = 'No account exists with the entered email address.';
          break;
        case 'email-already-in-use':
          error = 'An account already exists with this email.';
          break;
        case 'operation-not-allowed':
          error = 'An error occurred. Please try again later.';
          break;
        case 'weak-password': // Handle weak password before Firebase call
          error = 'Password is not strong enough.';
          break;
        case 'network-request-failed':
          error = 'Network error. Please check your internet connection.';
          break;
        case 'invalid-credential':
          error = 'Please enter a valid credential';
          break;
        case 'user-mismatch':
          error = 'An error occurred during sign in. Please try again later.';
          break;
        default:
          error = 'An unknown error occurred.';
      }
      setState(() {
        _loginErrorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> sendVerifylink() async {
    final user = FirebaseAuth.instance.currentUser!;
    try {
      await user.sendEmailVerification();
      Get.snackbar(
        'Link sent',
        'A link has been sent to your email address ${user.email}',
        margin: const EdgeInsets.all(30),
        snackPosition: SnackPosition.BOTTOM,
      );
      reloadAndNavigate();
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
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final user = FirebaseAuth.instance.currentUser!;
        await user.reload();
        if (user.emailVerified) {
          timer.cancel();
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const WidgetTree()),
          );
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
    });
  }

  Future<void> signUpWithUserEmailAndPassword() async {
    setState(() {
      isLoading = true;
      _registerErrorMessage = '';
    });
    String error;
    try {
      await Auth().signUpWithEmailandPassword(
          email: _controllerEmailSignup.text,
          password: _controllerpasswordSignup.text);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          error = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          error = 'This account has been disabled. Please contact support.';
          break;
        case 'wrong-password':
          error = 'Incorrect password. Please try again.';
          break;
        case 'user-not-found':
          error = 'No account exists with the entered email address.';
          break;
        case 'email-already-in-use':
          error = 'An account already exists with this email.';
          break;
        case 'operation-not-allowed':
          error = 'An error occurred. Please try again later.';
          break;
        case 'weak-password': // Handle weak password before Firebase call
          error = 'Password is not strong enough.';
          break;
        case 'network-request-failed':
          error = 'Network error. Please check your internet connection.';
          break;
        case 'invalid-credential':
          error = 'Please enter a valid credential';
          break;
        case 'user-mismatch':
          error = 'An error occurred during sign in. Please try again later.';
          break;
        default:
          error = 'An unknown error occurred.';
      }
      setState(() {
        _registerErrorMessage = error;
      });
    } catch (e) {
      switch (e.toString()) {
        case 'invalid-email':
          error = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          error = 'This account has been disabled. Please contact support.';
          break;
        case 'wrong-password':
          error = 'Incorrect password. Please try again.';
          break;
        case 'user-not-found':
          error = 'No account exists with the entered email address.';
          break;
        case 'email-already-in-use':
          error = 'An account already exists with this email.';
          break;
        case 'operation-not-allowed':
          error = 'An error occurred. Please try again later.';
          break;
        case 'weak-password': // Handle weak password before Firebase call
          error = 'Password is not strong enough.';
          break;
        case 'network-request-failed':
          error = 'Network error. Please check your internet connection.';
          break;
        case 'invalid-credential':
          error = 'Please enter a valid credential';
          break;
        case 'user-mismatch':
          error = 'An error occurred during sign in. Please try again later.';
          break;
        default:
          error = 'An unknown error occurred.';
      }
      setState(() {
        _registerErrorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
    storeUserDetails(_controllernameSignup.text, _controllerEmailSignup.text,
        _controllerpasswordSignup.text);

    sendVerifylink();
  }

  Widget entryField(
      String titleFuture,
      String hintFuture,
      TextEditingController controller,
      IconData iconType,
      bool isPass,
      bool obscureControl,
      Function(bool)? toggleObscureText) {
    return SizedBox(
        height: 40,
        width: 250,
        child: TextField(
          obscureText: isPass,
          controller: controller,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 2.0),
            labelText: titleFuture,
            labelStyle: const TextStyle(fontSize: 14),
            hintText: hintFuture,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            border: const OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.grey,
                width: 1.0,
              ),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            floatingLabelStyle:
                const TextStyle(color: Colors.greenAccent, fontSize: 12),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.greenAccent,
                width: 2.0,
              ),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            prefixIcon: Icon(
              iconType,
              size: 20,
            ),
            suffixIcon: obscureControl
                ? IconButton(
                    icon: Icon(
                      isPass ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        if (toggleObscureText != null) {
                          toggleObscureText(!isPass);
                        }
                      });
                    },
                  )
                : null,
          ),
        ));
  }

  // ignore: unused_element
  Widget _errorMessage(String errorMessage) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TranslatedText(
        errorMessage,
        style: const TextStyle(color: Colors.red, fontSize: 12),
      ),
    );
  }

  // Widget _googleAuthButton() {
  //   return SizedBox(
  //     height: 45,
  //     width: 300,
  //     child: ElevatedButton(
  //       onPressed: () {
  //         Auth().loginWithGoogle();
  //       },
  //       style: ElevatedButton.styleFrom(
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //         backgroundColor: const Color.fromARGB(255, 255, 255, 255),
  //         foregroundColor: Colors.black,
  //       ),
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: <Widget>[
  //           Image.asset(
  //             'assets/icons/google.png',
  //             height: 20,
  //             width: 40,
  //           ),
  //           Text(
  //             isLogin ? 'Sign in with Google' : 'Sign up with Google',
  //             style: const TextStyle(
  //               color: Colors.black,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  Widget _googleAuthButton(AuthService authService) {
    return SizedBox(
      height: 40,
      width: 250,
      child: SignInButton(
        Buttons.google,
        text: 'Sign up with Google',
        onPressed: () async {
          print("signing in with google");
          await authService.signInWithGoogle();
          print(
              "Checking signin completion"); // Await the loginWithGoogle() method
          if (FirebaseAuth.instance.currentUser != null) {
            print("Redirecting to home page");
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const WidgetTree()),
            );
            print("Redirect failed");
          } else {
            print("user is not found");
          }
        },
      ),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      height: 35,
      width: 250,
      child: ElevatedButton(
          onPressed: isLogin
              ? signInWithEmailAndPassword
              : signUpWithUserEmailAndPassword,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            backgroundColor: const Color.fromARGB(255, 0, 255, 42),
            foregroundColor: Colors.white,
          ),
          child: isLoading
              ? const CircularProgressIndicator(
                  color: Colors.white,
                )
              : isLogin
                  ? const Text(
                      'LOGIN',
                      style: TextStyle(fontSize: 14),
                    )
                  : const Text(
                      'REGISTER',
                      style: TextStyle(fontSize: 14),
                    )),
    );
  }

  void toggleObscureText(bool newValue) {
    setState(() {
      ispass = newValue;
    });
  }

  var isChecked = true;
  var _textColor = Colors.blue;
  bool ispass = true;
  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    return Scaffold(
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Container(
          decoration:
              const BoxDecoration(color: Color.fromARGB(255, 212, 255, 252)),
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Stack(
            children: <Widget>[
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 370,
                  decoration: const BoxDecoration(
                      image: DecorationImage(
                          image: AssetImage("assets/app_background.jpg"),
                          fit: BoxFit.cover)),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const WidgetTree()),
                    );
                  },
                  iconSize: 20,
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height / 3,
                left: 0,
                right: 0,
                bottom: 0,
                child: ClipRRect(
                  child: SlideTransition(
                    position: _offsetAnimation,
                    child: Container(
                      margin: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(
                                0, 0), // changes position of shadow
                          ),
                        ],
                        color: const Color.fromARGB(255, 241, 255, 254),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(70),
                          topRight: Radius.circular(70),
                        ),
                      ),
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                      child: Stack(
                        children: [
                          Positioned(
                            top: 30,
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: ClipRRect(
                              child: Container(
                                margin: const EdgeInsets.all(1),
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      spreadRadius: 2,
                                      blurRadius: 5,
                                      offset: const Offset(
                                          0, 0), // changes position of shadow
                                    ),
                                  ],
                                  color: Colors.white,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(70),
                                    topRight: Radius.circular(70),
                                  ),
                                ),
                                padding: const EdgeInsets.only(
                                    top: 50, bottom: 8, left: 20, right: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      isLogin ? 'Login Page' : 'Register Page',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (!isLogin) ...[
                                          entryField(
                                              'Name',
                                              'Enter your name',
                                              _controllernameSignup,
                                              Icons.person,
                                              false,
                                              false,
                                              toggleObscureText),
                                          const SizedBox(height: 16),
                                          entryField(
                                              'Email',
                                              'Enter your email',
                                              _controllerEmailSignup,
                                              Icons.email,
                                              false,
                                              false,
                                              toggleObscureText),
                                          const SizedBox(height: 16),
                                          entryField(
                                              'Password',
                                              'Enter your password',
                                              _controllerpasswordSignup,
                                              Icons.lock,
                                              ispass,
                                              true,
                                              toggleObscureText),
                                          if (_registerErrorMessage!.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 16.0),
                                              child: Text(
                                                _registerErrorMessage!,
                                                style: const TextStyle(
                                                    color: Colors.red),
                                              ),
                                            ),
                                        ] else ...[
                                          const SizedBox(height: 16),
                                          entryField(
                                              'Email',
                                              'Enter your email',
                                              _controllerEmailLogin,
                                              Icons.email,
                                              false,
                                              false,
                                              toggleObscureText),
                                          const SizedBox(height: 16),
                                          entryField(
                                              'Password',
                                              'Enter your password',
                                              _controllerpasswordLogin,
                                              Icons.lock,
                                              ispass,
                                              true,
                                              toggleObscureText),
                                          if (_loginErrorMessage!.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 16.0),
                                              child: Text(
                                                _loginErrorMessage!,
                                                style: const TextStyle(
                                                    color: Colors.red),
                                              ),
                                            ),
                                        ],

                                        // _errorMessage(),
                                        const SizedBox(height: 23),
                                        _submitButton(),

                                        const SizedBox(
                                          height: 33,
                                        ),

                                        SizedBox(
                                          child:
                                            _registerErrorMessage != '' ?
                                            Text(
                                                _registerErrorMessage!
                                            ) :
                                            Text("")
                                        ),
                                        if (isLogin) ...[
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              GestureDetector(
                                                onTap: () => {
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              const Forget()))
                                                },
                                                child: Text(
                                                  'Forget password',
                                                  style: TextStyle(
                                                    decoration: TextDecoration
                                                        .underline,
                                                    decorationColor:
                                                        Colors.blue,
                                                    color: _textColor,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            Text(
                                              isLogin
                                                  ? "Don't have an account? "
                                                  : 'Already have an account? ',
                                              style:
                                                  const TextStyle(fontSize: 12),
                                            ),
                                            GestureDetector(
                                              onTap: () => setState(() {
                                                isLogin = !isLogin;
                                                _textColor = Colors.lightBlue;
                                              }),
                                              child: Text(
                                                isLogin ? 'register' : 'login',
                                                style: TextStyle(
                                                  decoration:
                                                      TextDecoration.underline,
                                                  decorationColor: Colors.blue,
                                                  color: _textColor,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                        const SizedBox(height: 23),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                                child: Container(
                                                    color: Colors.grey,
                                                    height: 1)),
                                            const TranslatedText(
                                              ' Continue with ',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            Expanded(
                                                child: Container(
                                                    color: Colors.grey,
                                                    height: 1)),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        _googleAuthButton(authService)
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
