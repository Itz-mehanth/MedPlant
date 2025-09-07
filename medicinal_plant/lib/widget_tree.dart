import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:medicinal_plant/camera_page.dart';
import 'package:medicinal_plant/home_page.dart';
import 'package:medicinal_plant/profile_page.dart';
import 'package:medicinal_plant/utils/global_functions.dart';
import 'home_page.dart';

class WidgetTree extends StatefulWidget {
  const WidgetTree({super.key});

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  bool onHomePage = true;
  bool onProfilePage = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
      ),
      body: const Stack(
        children: [
            WelcomeScreen()
        ],
      ),
    );
  }
}
