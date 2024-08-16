import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medicinal_plant/login_register_page.dart';
import 'package:medicinal_plant/utils/global_functions.dart';

class Forget extends StatefulWidget {
  const Forget({super.key});

  @override
  State<Forget> createState() => _ForgetState();
}

class _ForgetState extends State<Forget> with SingleTickerProviderStateMixin {
  TextEditingController emailController = TextEditingController();
  bool isLoading = false;
  String errorMessage = '';
  late Animation<Offset> _offsetAnimation;
  late AnimationController _controller;
  bool isPass = false;

  void toggleObscureText(bool newValue) {
    setState(() {
      isPass = newValue;
    });
  }

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
    super.dispose();
  }

  Widget entryField(
      Future<String> titleFuture,
      Future<String> hintFuture,
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
            labelText: "Email",
            labelStyle: const TextStyle(fontSize: 14),
            hintText: "Enter you email",
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

  resetPassword() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: emailController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: TranslatedText(
                'Password reset link sent to ${emailController.text}')),
      );
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration:
            const BoxDecoration(color: Color.fromARGB(255, 196, 255, 255)),
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
                          offset:
                              const Offset(0, 0), // changes position of shadow
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
                                    top: 40, bottom: 10, left: 20, right: 20),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    entryField(
                                      translate('Email'),
                                      translate('Enter your email'),
                                      emailController,
                                      Icons.email,
                                      false,
                                      false,
                                      toggleObscureText,
                                    ),
                                    const SizedBox(height: 30),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Center(
                                            child: SizedBox(
                                              height: 30,
                                              width: 30,
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            50),
                                                  ),
                                                  backgroundColor:
                                                      const Color.fromARGB(
                                                          255, 222, 136, 93),
                                                  foregroundColor: Colors.white,
                                                  padding: EdgeInsets.zero,
                                                ),
                                                onPressed: () {
                                                  Navigator.pushReplacement(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            const LoginPage()),
                                                  );
                                                },
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.arrow_back,
                                                    size: 24,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 30,
                                          ),
                                          if (isLoading)
                                            const SizedBox(
                                              height: 30,
                                              width: 30,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                backgroundColor: Colors.green,
                                              ),
                                            )
                                          else
                                            SizedBox(
                                              height: 35,
                                              width: 120,
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            25),
                                                  ),
                                                  backgroundColor:
                                                      const Color.fromARGB(
                                                          255, 0, 255, 42),
                                                  foregroundColor: Colors.white,
                                                ),
                                                onPressed: resetPassword,
                                                child: const Text("Send link"),
                                              ),
                                            ),
                                          const SizedBox(
                                            width: 30,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (errorMessage.isNotEmpty)
                                      Text(
                                        errorMessage,
                                        style:
                                            const TextStyle(color: Colors.red),
                                      )
                                    else
                                      const SizedBox(height: 20),
                                    const SizedBox(height: 20),
                                  ],
                                )),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
