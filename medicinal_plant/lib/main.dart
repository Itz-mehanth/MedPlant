import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:medicinal_plant/gallery_page.dart';
import 'package:medicinal_plant/camera_page.dart';
import 'package:medicinal_plant/groups_page%20.dart';
import 'package:medicinal_plant/home_page.dart';
import 'package:medicinal_plant/leaf_prediction_app.dart';
import 'package:medicinal_plant/login_register_page.dart';
import 'package:medicinal_plant/map.dart';
import 'package:medicinal_plant/plant_details_page.dart';
import 'package:medicinal_plant/profile_page.dart';
import 'package:medicinal_plant/search_page.dart';
import 'package:medicinal_plant/splash_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:medicinal_plant/widget_tree.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';



Future<void> main() async {


  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: dotenv.env['FIREBASE_API_KEY_WEB']!,
          projectId: "medicinal-plant-82aa9",
          messagingSenderId: "1085343678758",
          appId: "1:1085343678758:android:9a2029c33b8ed1017401e7",
          storageBucket: 'medicinal-plant-82aa9.appspot.com',
          databaseURL: "https://medicinal-plant-82aa9.firebaseio.com",
        )
    );
  } else{
    await Firebase.initializeApp(
      options: FirebaseOptions(
          apiKey: dotenv.env['FIREBASE_API_KEY_ANDROID']!,
          authDomain: "medicinal-plant-82aa9.firebaseapp.com",
          databaseURL: "https://medicinal-plant-82aa9-default-rtdb.asia-southeast1.firebasedatabase.app",
          projectId: "medicinal-plant-82aa9",
          storageBucket: "medicinal-plant-82aa9.appspot.com",
          messagingSenderId: "1085343678758",
          appId: "1:1085343678758:web:436daced9d3bd3b37401e7",
          measurementId: "G-7BH4LJYG5R"
      ),
    );
  }

  runApp(
    ProviderScope(child: MyApp()),
  );

  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize('b2b54cd9-5f66-4f46-9c2d-8a62257a702d');
  OneSignal.Notifications.requestPermission(true);
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/home': (context) => const WelcomeScreen(),
        '/gallery': (context) => const GalleryPage(),
        '/camera': (context) => const CameraPage(),
        '/login': (context) => const LoginPage(),
        '/profile': (context) => const ProfilePage(),
        '/groups': (context) => GroupsPage(),
        '/search': (context) => const SearchPage(),
      },

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
