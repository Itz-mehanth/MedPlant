import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:medicinal_plant/splash_screen.dart';


Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options:
      const FirebaseOptions(
          apiKey: "AIzaSyCrbOmzRVSMGhKGvjdI12fVUnSDfUGfWPY",
          projectId: "medicinal-plant-82aa9",
          messagingSenderId: "1085343678758",
          appId: "1:1085343678758:android:9a2029c33b8ed1017401e7",
          storageBucket: 'medicinal-plant-82aa9.appspot.com',
          databaseURL: "https://medicinal-plant-82aa9.firebaseio.com", // Add Database URL Here
      )
  );

  runApp(
    ProviderScope(child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],

      home: const SplashScreen(), // Start with the SplashScreen
    );
  }
}
