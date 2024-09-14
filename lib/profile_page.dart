import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medicinal_plant/auth.dart';
import 'package:medicinal_plant/google_signin_web.dart';
import 'package:medicinal_plant/home_page.dart';
import 'package:medicinal_plant/login_register_page.dart';
import 'package:medicinal_plant/splash_screen.dart';
import 'package:medicinal_plant/utils/global_functions.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  User? user;
  @override
  void initState() {
    super.initState();
    user = Auth().currentUser;

    // Listen to auth state changes
    Auth().authStateChanges.listen((User? newUser) {
      setState(() {
        user = newUser;
        // print(user?.email);
      });
    });
  }

  Color buttonColor = Colors.white;
  Auth auth = Auth();

  // final userId = FirebaseAuth.instance.currentUser!.uid;

  int _selectedOption = 0;
  List<String> languages = [
    'English (en)',
    'Tamil (ta)',
    'Telugu (te)',
    'Kannada (kn)',
    'Malayalam (ml)',
    'Hindi (hi)',
    'Gujarati (gu)',
    'Oriya (or)',
    'Spanish (es)',
    'French (fr)',
    'German (de)',
    'Italian (it)',
    'Portuguese (pt)',
    'Chinese (Simplified) (zh_CN)',
    'Chinese (Traditional) (zh_TW)',
    'Japanese (ja)',
    'Korean (ko)',
    'Arabic (ar)',
    'Russian (ru)',
    'Bengali (bn)',
    'Polish (pl)',
    'Turkish (tr)',
    'Thai (th)',
    'Vietnamese (vi)',
    'Indonesian (id)',
    'Malay (ms)',
    'Swedish (sv)',
    'Danish (da)',
    'Norwegian (no)',
    'Dutch (nl)',
    'Greek (el)',
    'Hebrew (he)',
    'Romanian (ro)',
    'Czech (cs)',
    'Hungarian (hu)',
    'Finnish (fi)',
    'Slovak (sk)',
    'Ukrainian (uk)',
    'Croatian (hr)',
    'Bulgarian (bg)',
    'Slovenian (sl)',
    'Estonian (et)',
    'Latvian (lv)',
    'Lithuanian (lt)',
  ];

  List<String> locales = [
    'en',
    'ta',
    'te',
    'kn',
    'ml',
    'hi',
    'gu',
    'or',
    'es',
    'fr',
    'de',
    'it',
    'pt',
    'zh_CN',
    'zh_TW',
    'ja',
    'ko',
    'ar',
    'ru',
    'bn',
    'pl',
    'tr',
    'th',
    'vi',
    'id',
    'ms',
    'sv',
    'da',
    'no',
    'nl',
    'el',
    'he',
    'ro',
    'cs',
    'hu',
    'fi',
    'sk',
    'uk',
    'hr',
    'bg',
    'sl',
    'et',
    'lv',
    'lt',
  ];

  Future<void> _updateUserLanguage(String language) async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'language': language,
      });
    } catch (e) {
      print('Error updating user language: $e');
    }
  }

  void _showRadioDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const TranslatedText('Select an Option'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: languages.map((option) {
                  int index = languages.indexOf(option);
                  return RadioListTile(
                    title: Text(option),
                    value: index,
                    // groupValue: locales.indexOf(currentLocale),
                    groupValue: locales.indexOf(currentLocale),
                    onChanged: (int? value) async {
                      setState(() {
                        _selectedOption = value!;
                      });
                      _updateUserLanguage(locales[_selectedOption]);
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SplashScreen()));
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  void _sendFeedback() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'mehanth362@example.com',
      query: 'subject=Feedback&body=Your feedback here',
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      throw 'Could not launch $emailLaunchUri';
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    return Scaffold(
      body: Container(
        color: Colors.white,
        margin: const EdgeInsets.all(10),
        height: double.infinity,
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              alignment: Alignment.bottomLeft,
              decoration: const BoxDecoration(),
              height: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(
                      right: 5,
                    ),
                    clipBehavior: Clip.none,
                    height: 30,
                    width: 30,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: const DecorationImage(
                            image: AssetImage(
                              "assets/userIcon.jpg",
                            ),
                            fit: BoxFit.fill)),
                  ),
                  Text(
                    user?.email ?? "Guest",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 5),
            const Divider(height: 1),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  if (user?.email != null) {
                    auth.signOut();
                  } else if (authService.isLoggedIn) {
                    authService.signOut();
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
                    );
                  }
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                      if (states.contains(WidgetState.hovered)) {
                        return const Color.fromARGB(221, 228, 228, 228);
                      }
                      return Colors.white;
                    },
                  ),
                  foregroundColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                      if (states.contains(WidgetState.hovered)) {
                        return Colors.black;
                      }
                      return Colors.black;
                    },
                  ),
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero),
                  ),
                  padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                    EdgeInsets.zero,
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 10,
                    ),
                    Icon(
                      user?.email != null ? Icons.logout : Icons.login,
                      size: 20,
                      color: user?.email != null
                          ? const Color.fromARGB(255, 255, 17, 0)
                          : Colors.black,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    user != null
                        ? const TranslatedText("Log out",
                        style: TextStyle(
                            color: Color.fromARGB(255, 255, 17, 0)))
                        : const TranslatedText(
                      "Log in",
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    )
                  ],
                ),
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 40,
              child: ElevatedButton(
                onPressed: user != null
                    ? () => _showRadioDialog()
                    : () => showLoginPrompt(context),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                      if (states.contains(WidgetState.hovered)) {
                        return const Color.fromARGB(221, 228, 228, 228);
                      }
                      return Colors.white;
                    },
                  ),
                  foregroundColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                      if (states.contains(WidgetState.hovered)) {
                        return Colors.black;
                      }
                      return Colors.black;
                    },
                  ),
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero),
                  ),
                  padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                    EdgeInsets.zero,
                  ),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 10,
                    ),
                    Icon(Icons.language),
                    SizedBox(
                      width: 10,
                    ),
                    TranslatedText('Languages'),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 40,
              child: ElevatedButton(
                onPressed: _sendFeedback,
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                      if (states.contains(WidgetState.hovered)) {
                        return const Color.fromARGB(221, 228, 228, 228);
                      }
                      return Colors.white;
                    },
                  ),
                  foregroundColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                      if (states.contains(WidgetState.hovered)) {
                        return Colors.black;
                      }
                      return Colors.black;
                    },
                  ),
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero),
                  ),
                  padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                    EdgeInsets.zero,
                  ),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 10,
                    ),
                    Icon(Icons.feedback),
                    SizedBox(
                      width: 10,
                    ),
                    TranslatedText('Send Feedback'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
