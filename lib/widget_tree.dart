import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:medicinal_plant/camera_page.dart';
import 'package:medicinal_plant/home_page.dart';
import 'package:medicinal_plant/profile_page.dart';
import 'package:medicinal_plant/utils/global_functions.dart';

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
        backgroundColor: const Color.fromARGB(255, 68, 255, 0),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          if (onHomePage)
            const WelcomeScreen()
          else if (onProfilePage)
            const ProfilePage(),
          Positioned(
            bottom: -1,
            // left: (MediaQuery.of(context).size.width - 100) / 2,
            child: Container(
              width: (MediaQuery.of(context).size.width),
              height: 70,
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.black12)),
                color: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 50, right: 50),
                    child: Column(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              onHomePage = true;
                              onProfilePage = false;
                              print("onHomePage");
                            });
                          },
                          icon: Icon(
                            Icons.home_filled,
                            size: 24,
                            color: onHomePage
                                ? const Color.fromARGB(255, 0, 255, 13)
                                : Colors.black38,
                          ),
                        ),
                        TranslatedText(
                          "Home",
                          style: TextStyle(
                            fontSize: 8,
                            color: onHomePage
                                ? const Color.fromARGB(255, 0, 255, 13)
                                : Colors.black38,
                          ),
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 50, right: 50),
                    child: Column(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              onProfilePage = true;
                              onHomePage = false;
                              print("onProfilePage");
                            });
                          },
                          icon: Icon(
                            Icons.person,
                            size: 24,
                            color: onProfilePage
                                ? const Color.fromARGB(255, 0, 255, 13)
                                : Colors.black38,
                          ),
                        ),
                        TranslatedText(
                          "Profile",
                          style: TextStyle(
                            fontSize: 8,
                            color: onProfilePage
                                ? const Color.fromARGB(255, 0, 255, 13)
                                : Colors.black38,
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: (MediaQuery.of(context).size.width - 100) / 2,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
              ),
              height: 80,
              width: 80,
              child: IconButton(
                icon: Image.asset(
                  "assets/cameraLogo.png",
                  width: 80,
                  height: 80,
                ),
                onPressed: () async {
                  CameraController? controller =
                  await CameraPage.setupCameraController();
                  if (controller != null) {
                    Navigator.push(
                      // ignore: use_build_context_synchronously
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CameraPage()),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
