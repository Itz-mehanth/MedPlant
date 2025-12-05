import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:medicinal_plant/MarketPlaceProfilePage.dart';
import 'package:medicinal_plant/NewsDetailsPage.dart';
import 'package:medicinal_plant/PlantSubmissionPage.dart';
import 'package:medicinal_plant/SocialFeedPage.dart';
import 'package:medicinal_plant/gallery_page.dart';
import 'package:medicinal_plant/camera_page.dart';
import 'package:medicinal_plant/groups_page .dart';
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
import 'package:medicinal_plant/LiveAnalysisScreen.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:medicinal_plant/main_layout.dart';
import 'package:medicinal_plant/cart_page.dart';

import 'package:medicinal_plant/AyurvedaQAPage.dart';

const String serverUrl = 'https://medplant-backend.onrender.com';

Future<void> wakeServer() async {
  try {
    final uri = Uri.parse('$serverUrl/health');
    final response = await http.get(uri).timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      debugPrint('✅ Backend is awake');
    } else {
      debugPrint('⚠️ Backend responded with ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('⚠️ Failed to wake server: $e');
  }
}

Future<void> main() async {
  await wakeServer();

  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: 'AIzaSyAr3a6eqdxaCsxbC5x2vsnM6t1tqlSg_vI',
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
          apiKey: 'AIzaSyCrbOmzRVSMGhKGvjdI12fVUnSDfUGfWPY',
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
        '/main': (context) => const MainLayout(),
        '/gallery': (context) => const GalleryPage(),
        '/camera': (context) => const LiveAnalysisScreen(),
        '/login': (context) => const LoginPage(),
        '/profile': (context) => const MarketplaceProfilePage(),
        '/groups': (context) => GroupsPage(),
        '/search': (context) => const SearchPage(),
        '/submission': (context) => const PlantSubmissionPage(),
        '/news_detail': (context) => const NewsDetailPage(),
        '/all_news': (context) => const AllNewsPage(),
        '/social_feed': (context) => SocialFeedPage(),
        '/Q&A': (context) => const AyurvedaQAPage(),
        '/cart': (context) => const CartPage(),
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
