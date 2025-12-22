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
import 'package:medicinal_plant/keys.dart';

import 'package:medicinal_plant/AyurvedaQAPage.dart';
import 'package:medicinal_plant/messages_page.dart';
import 'package:medicinal_plant/notifications_page.dart';

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
      options: const FirebaseOptions(
          apiKey: Keys.firebaseWebApiKey,
          authDomain: Keys.firebaseWebAuthDomain,
          databaseURL: Keys.firebaseWebDatabaseURL,
          projectId: Keys.firebaseWebProjectId,
          storageBucket: Keys.firebaseWebStorageBucket,
          messagingSenderId: Keys.firebaseWebMessagingSenderId,
          appId: Keys.firebaseWebAppId,
          measurementId: Keys.firebaseWebMeasurementId
      ),
    );
  } else{
    await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: Keys.firebaseAndroidApiKey,
          projectId: Keys.firebaseAndroidProjectId,
          messagingSenderId: Keys.firebaseAndroidMessagingSenderId,
          appId: Keys.firebaseAndroidAppId,
          storageBucket: Keys.firebaseAndroidStorageBucket,
          databaseURL: Keys.firebaseAndroidDatabaseURL,
        )
    );
  }

  runApp(
    ProviderScope(child: MyApp()),
  );

  // OneSignal Setup
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize(Keys.oneSignalAppId);
  OneSignal.Notifications.requestPermission(true);
  
  // Handle notification clicks
  OneSignal.Notifications.addClickListener((event) {
    print('OneSignal: Notification clicked!');
    print('Notification data: ${event.notification.additionalData}');
    
    // Navigate based on notification type
    final data = event.notification.additionalData;
    if (data != null) {
      final type = data['type'] as String?;
      final relatedId = data['relatedId'] as String?;
      
      // Wait a bit for app to be ready
      Future.delayed(Duration(milliseconds: 500), () {
        if (type == 'like' || type == 'comment' || type == 'share') {
          navigatorKey.currentState?.pushNamed('/social_feed');
        } else if (type == 'review' || type == 'follow') {
          navigatorKey.currentState?.pushNamed('/profile');
        } else if (type == 'system') {
          navigatorKey.currentState?.pushNamed('/notifications');
        }
      });
    }
  });
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  MyApp({super.key});

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
        '/messages': (context) => const MessagesPage(),
        '/notifications': (context) => const NotificationsPage(),
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
