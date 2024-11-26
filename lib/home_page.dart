// ignore_for_file: non_constant_identifier_names
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medicinal_plant/genAI.dart';
import 'package:medicinal_plant/main.dart';
import 'package:medicinal_plant/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medicinal_plant/auth.dart';
import 'package:medicinal_plant/login_register_page.dart';
import 'package:medicinal_plant/plant_details_page.dart';
import 'package:medicinal_plant/search_page.dart';
import 'package:medicinal_plant/utils/global_functions.dart';
import 'package:medicinal_plant/plant_details_initializer.dart';

class PlantSearchBar extends StatefulWidget {
  final bool isEnabled;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  const PlantSearchBar({
    super.key,
    required this.isEnabled,
    required this.searchController,
    required this.searchFocusNode,
  });
  @override
  _SearchBarWidgetState createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<PlantSearchBar> {
  bool isFocused = false;
  late final Future<String> _hintTextFuture;

  @override
  void initState() {
    super.initState();
    _hintTextFuture = translate('Search plants');
    widget.searchFocusNode.addListener(() {
      setState(() {
        isFocused = widget.searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    widget.searchController.dispose();
    widget.searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: ((context) => const SearchPage())));
      },
      child: Container(
        width: 280,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              height: 34,
              width: 280,
              child: FutureBuilder(
                  future: _hintTextFuture,
                  builder: (context, value) {
                    return TextField(
                      enabled: widget.isEnabled,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                      ),
                      controller: widget.searchController,
                      focusNode: widget.searchFocusNode,
                      textAlign: TextAlign.start,
                      cursorColor: Colors.green, // Change the cursor color here
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.all(1),
                        // Adjust padding as needed
                        prefixIcon: Container(
                          margin: const EdgeInsets.only(
                            right: 5,
                          ),
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              bottomLeft: Radius.circular(30),
                            ),
                            color: Color.fromARGB(255, 0, 255, 0),
                          ),
                          width: 34,
                          height: 31,
                          child: IconButton(
                            padding: const EdgeInsets.all(3),
                            icon: const Icon(Icons.search),
                            onPressed: () => {},
                            color: Colors.white,
                            iconSize: 24,
                          ),
                        ),
                        suffixIcon: isFocused // Check if the field is focused
                            ? IconButton(
                          icon: const Icon(Icons.cancel),
                          onPressed: () {
                            widget.searchController.clear();
                            isFocused = false;
                            // Unfocus the current FocusNode
                            FocusScope.of(context).unfocus();
                          },
                          iconSize: 18,
                          color: const Color.fromARGB(255, 0, 255, 0),
                        )
                            : null, // No suffix icon when not focused
                        hintText: value.data ?? '',
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Color.fromARGB(255, 21, 255, 0),
                            width: 1.0,
                          ), // Change the color and width as needed
                          borderRadius: BorderRadius.circular(30),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.black12,
                            width: 1.0,
                          ), // Default border color
                          borderRadius: BorderRadius.circular(30),
                        ),
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.black12,
                            width: 1.0,
                          ), // Default border color
                          borderRadius: BorderRadius.circular(30),
                        ),
                        hintStyle: const TextStyle(
                          color: Colors.black26,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }),
            ),
          ],
        ),
      ),
    );
  }
}

void showErrorDialog(String errorMessage) {
  showDialog(
    context: MyApp().navigatorKey.currentContext!,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Error'),
        content: Text(errorMessage),
        actions: <Widget>[
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

void showLoginPrompt(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Login Required'),
      content: const Text('Please login to add plants to your favorites.'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const TranslatedText('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
          child: const TranslatedText('Login'),
        ),
      ],
    ),
  );
}

// ignore: must_be_immutable
class PlantBoxWidget extends StatefulWidget {
  late String plantName;
  late String plantDescription;
  late String scientificName;
  late String family;
  late Future<String> imageUrl;
  bool isFav = false;

  PlantBoxWidget({
    super.key,
    required this.plantName,
    required this.plantDescription,
    required this.scientificName,
    required this.family,
    required this.imageUrl,
  });

  @override
  _PlantBoxWidgetState createState() => _PlantBoxWidgetState();
}

class _PlantBoxWidgetState extends State<PlantBoxWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> sizeAnimation;
  late Animation<Color?> colorAnimation;

  @override
  void initState() {
    super.initState();
    isFavourite();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    colorAnimation = ColorTween(
      begin: Colors.black54,
      end: const Color.fromARGB(255, 255, 191, 0),
    ).animate(controller);

    sizeAnimation = TweenSequence(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.0, end: 0.7), weight: 50),
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.7, end: 1), weight: 50),
    ]).animate(controller);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> isFavourite() async {
    try {
      // Get the current user's ID
      final userId = FirebaseAuth.instance.currentUser!.uid;

      // Check if the plant is already in the user's favorites collection
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get()
          .then((DocumentSnapshot documentSnapshot) {
        if (documentSnapshot.exists) {
          final favorites = documentSnapshot.get('favorites') as List<dynamic>;
          widget.isFav = favorites.contains(widget.plantName);
        }
      });
    } catch (e) {
      print('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    String truncatedPlantDescription = widget.plantDescription.length > 176
        ? widget.plantDescription.substring(0, 176)
        : widget.plantDescription;

    return Container(
      height: 142,
      width: 370,
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          FutureBuilder(
            future: widget.imageUrl,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 142,
                  width: 134,
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (snapshot.connectionState == ConnectionState.done) {
                return Stack(
                  children: [
                    Container(
                      width: 134,
                      height: 142,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          bottomLeft: Radius.circular(10),
                        ),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          bottomLeft: Radius.circular(10),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: snapshot.data!,
                          placeholder: (context, url) => const SizedBox(
                            height: 142,
                            width: 134,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) {
                            print('Error loading image: $error');
                            return const Icon(Icons.error);
                          },
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        child: AnimatedBuilder(
                          animation: controller,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: sizeAnimation.value,
                              child: IconButton(
                                  padding: const EdgeInsets.all(2),
                                  icon: Icon(Icons.star_sharp,
                                    color: (widget.isFav && FirebaseAuth.instance.currentUser != null)
                                        ? const Color.fromARGB(255, 255, 191, 0) // Yellow if favorite and user exists
                                        : Colors.black54, // Otherwise black54
                                  ),
                                  color: colorAnimation.value,
                                  iconSize: 24,
                                  onPressed: (FirebaseAuth.instance.currentUser != null) ?
                                      () async {
                                    final userId = FirebaseAuth.instance.currentUser!.uid;

                                    final favorites = FirebaseFirestore.instance
                                        .collection('users');
                                    if (widget.isFav) {
                                      // Remove plant from favorites
                                      favorites.doc(userId).update({
                                        'favorites': FieldValue.arrayRemove(
                                            [widget.plantName])
                                      });
                                      controller.reverse();
                                    } else {
                                      // Add plant to favorites
                                      favorites.doc(userId).update({
                                        'favorites': FieldValue.arrayUnion(
                                            [widget.plantName])
                                      });
                                      controller.forward();
                                    }
                                    setState(() {
                                      widget.isFav = !widget.isFav;
                                    });
                                  } :
                                      () => showLoginPrompt(context)
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                return const SizedBox(
                  height: 142,
                  width: 134,
                  child: Icon(Icons.error),
                );
              }
            },
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlantDetailsPage(
                      plantName: widget.plantName,
                      plantDescription: widget.plantDescription,
                      scientificName: widget.scientificName,
                      family: widget.family,
                    ),
                  ),
                );
              },
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.black12),
                    right: BorderSide(color: Colors.black12),
                    bottom: BorderSide(color: Colors.black12),
                  ),
                ),
                height: 140,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(
                          left: 5, right: 5, top: 2, bottom: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TranslatedText(
                            widget.plantName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'KOULEN',
                            ),
                          ),
                          SizedBox(
                            height: 70,
                            child: TranslatedText(
                              "$truncatedPlantDescription ... Read more",
                              style: const TextStyle(
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.only(
                          left: 10, right: 10, top: 2, bottom: 1),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.black12)),
                      ),
                      height: 33,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      color: Colors.green,
                                      Icons.medical_information,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          const TranslatedText(
                                            "Scientific name",
                                            style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          TranslatedText(
                                            widget.scientificName,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              overflow: TextOverflow
                                                  .ellipsis, // Add this line
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<PlantBoxWidget> plantWidgets = [];

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  bool allTabSelected = true; // Default to allTabSelected
  bool gardenTabSelected = false;
  final TextEditingController searchController = TextEditingController();
  final User? user = Auth().currentUser;
  bool isFav = false;
  late AnimationController controller;
  late Animation<Color?> colorAnimation;
  late Animation<double> sizeAnimation;
  bool onHomePage = false;
  bool onProfilePage = false;
  bool onSearch = false;
  bool onCamera = false;
  double itemWidth = 350;
  double itemHeight = 140;
  double aspectRatio = 350 / 140;

  @override
  void initState() {
    super.initState();

    // fetchAndSetPlantWidgets();

    _getUserLanguage();
    controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          isFav = true;
        });
      }
      if (status == AnimationStatus.dismissed) {
        isFav = false;
      }
    });

    colorAnimation = ColorTween(
      begin: Colors.black54,
      end: const Color.fromARGB(255, 255, 191, 0),
    ).animate(controller);

    sizeAnimation = TweenSequence(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.0, end: 0.7), weight: 50),
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.7, end: 1), weight: 50),
    ]).animate(controller);
  }

  Future<String> fetchRandomImageUrl(String plantName) async {
    try {
      final FirebaseStorage storage = FirebaseStorage.instanceFor(
        bucket:
        'gs://medicinal-plant-82aa9.appspot.com', // Replace with your bucket
      );

      final ListResult result =
      await storage.ref().child('images').child(plantName).listAll();
      final List<Reference> allFiles = result.items;

      if (allFiles.isEmpty) {
        // Handle the case where no images are found
        return 'https://static.vecteezy.com/system/resources/previews/004/141/669/original/no-photo-or-blank-image-icon-loading-images-or-missing-image-mark-image-not-available-or-image-coming-soon-sign-simple-nature-silhouette-in-frame-isolated-illustration-vector.jpgg'; // Use your default placeholder image
      }

      final int randomIndex = DateTime.now().millisecond % allFiles.length;
      final Reference randomFile = allFiles[randomIndex];
      final String downloadUrl = await randomFile.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error fetching image URL: $e');
      return 'https://static.vecteezy.com/system/resources/previews/004/141/669/original/no-photo-or-blank-image-icon-loading-images-or-missing-image-mark-image-not-available-or-image-coming-soon-sign-simple-nature-silhouette-in-frame-isolated-illustration-vector.jpg'; // Use your default placeholder image
    }
  }

  // Method to update the user's language preference in Firestore
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

  // Method to update the user's language preference in Firestore
  Future<void> _getUserLanguage() async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(userId)
          .get();
      final documentData = doc.data() as Map<String, dynamic>;
      setState(() {
        currentLocale = documentData["language"];
      });
    } catch (e) {
      setState(() {
        currentLocale = 'en';
      });
      print('Error updating user language: $e');
    }
  }

  Future<List<String>> fetchPlantNames() async {
    try {
      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('plant_details').get();
      List<String> plantNames = querySnapshot.docs.map((doc) {
        final documentData = doc.data() as Map<String, dynamic>;
        return documentData['Common Name'] as String? ?? 'Unknown';
      }).toList();

      return plantNames;
    } catch (e) {
      print('Error fetching plant names: $e');
      return [];
    }
  }

  Future<void> fetchAndSetPlantWidgets() async {
    List<String> plantNames = await fetchPlantNames(); // Fetch plant names

    for (String plantName in plantNames) {
      PlantBoxWidget? widget = await fetchPlantWidget(plantName);
      if (widget != null) {
        setState(() {
          plantWidgets.add(widget);
        });
      }
    }
  }

  Future<List<PlantBoxWidget>> fetchPlantWidgets(
      List<String> plantNames) async {
    List<PlantBoxWidget> plantWidgets = [];

    for (String plantName in plantNames) {
      PlantBoxWidget? widget = await fetchPlantWidget(plantName);
      if (widget != null) {
        plantWidgets.add(widget);
      }
    }

    return plantWidgets;
  }

  Future<PlantBoxWidget?> fetchPlantWidget(String plantNameInput) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('plant_details')
          .where('Common Name', isEqualTo: plantNameInput)
          .get();
      List<QueryDocumentSnapshot> docs = querySnapshot.docs;

      if (docs.isNotEmpty) {
        final documentData = docs.first.data() as Map<String, dynamic>;
        String plantName = documentData['Common Name'];
        String plantDescription = documentData['Description'];
        String scientificName = documentData['Scientific Name'];
        String family = documentData['Family'];
        return PlantBoxWidget(
          plantName: plantName,
          plantDescription: plantDescription.replaceAll('-', ','),
          scientificName: scientificName,
          family: family,
          imageUrl: fetchRandomImageUrl(plantName),
        );
      } else {
        return PlantBoxWidget(
          plantName: 'Document not found',
          plantDescription: 'Document not found',
          scientificName: 'Document not found',
          family: 'Document not found',
          imageUrl: Future.value(''),
        );
      }
    } catch (e) {
      print('Error fetching plant details: $e');
      return null;
    }
  }

  Future<void> signout(BuildContext context) async {
    await Auth().signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
    );
  }

  Widget TopNavButton(String name, bool isSelected) {
    return Container(
      width: 70,
      height: 30,
      alignment: Alignment.center,
      margin: const EdgeInsets.only(left: 10),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        color: isSelected
            ? const Color.fromARGB(255, 0, 255, 34)
            : const Color.fromARGB(255, 255, 255, 255),
        border: Border.all(
          color: isSelected
              ? const Color.fromARGB(255, 0, 255, 34)
              : Colors.black26,
        ),
      ),
      child: TranslatedText(
        name,
        style: TextStyle(
          fontSize: 10,
          color: isSelected
              ? const Color.fromARGB(255, 255, 255, 255)
              : Colors.black26,
        ),
        // textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<PlantBoxWidget> filteredWidgets;
    final plantWidgets = ref.watch(plantWidgetsProvider);
    filteredWidgets = plantWidgets.where((widget) => widget.isFav).map((el) {
      el.isFav = true;
      return el;
    }).toList();

    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        color: Colors.white,
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 130,
              child: Container(
                alignment: Alignment.bottomCenter,
                padding: const EdgeInsets.all(5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Image.asset(
                          "assets/pot1.png",
                          height: 76,
                          width: 55,
                          fit: BoxFit.fill,
                        ),
                        const Text(
                          "MEDPLANT",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'KOULEN',
                          ),
                        ),
                        Image.asset(
                          "assets/pot2.png",
                          height: 76,
                          width: 55,
                          fit: BoxFit.fill,
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    PlantSearchBar(
                      searchFocusNode: FocusNode(),
                      isEnabled: false,
                      searchController: searchController,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(thickness: 1),
            SizedBox(
              height: 30,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        gardenTabSelected = false;
                        allTabSelected = true;
                      });
                    },
                    child: TopNavButton(
                      "All",
                      allTabSelected,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        gardenTabSelected = true;
                        allTabSelected = false;
                      });
                    },
                    child: TopNavButton(
                      "Garden",
                      gardenTabSelected,
                    ),
                  ),
                  FloatingActionButton(
                    onPressed: () {
                      // Navigate to GenAIPage when button is clicked
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatBotPage(),
                        ),
                      );
                    },
                    child: Icon(Icons.question_answer), // Icon for FAB
                  ),
                ],
              ),
            ),
            const Divider(thickness: 1),
            plantWidgets.length < 10
                ? (const Expanded(child: PlaceholderRedacted()))
                : (allTabSelected
                ? Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate item width
                  double itemWidth = 350;

                  // Define item height based on the aspect ratio
                  double itemHeight =
                  140; // This can be adjusted based on your design
                  double aspectRatio = itemWidth / itemHeight;

                  // Calculate the number of columns based on available width
                  int columnCount =
                  (constraints.maxWidth / (itemWidth)).floor();

                  return GridView.builder(
                    padding: const EdgeInsets.all(10),
                    shrinkWrap: true,
                    gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                      columnCount, // Number of columns
                      childAspectRatio:
                      aspectRatio, // Maintain item aspect ratio
                    ),
                    itemCount: plantWidgets.length,
                    itemBuilder: (context, index) {
                      return Center(
                        child: SizedBox(
                            width: itemWidth,
                            child: plantWidgets[index]),
                      );
                    },
                  );
                },
              ),
            )
                : (FirebaseAuth.instance.currentUser != null) ? Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate item width
                  double itemWidth = 350;

                  // Define item height based on the aspect ratio
                  double itemHeight =
                  140; // This can be adjusted based on your design
                  double aspectRatio = itemWidth / itemHeight;

                  // Calculate the number of columns based on available width
                  int columnCount =
                  (constraints.maxWidth / (itemWidth)).floor();

                  return GridView.builder(
                    padding: const EdgeInsets.all(10),
                    shrinkWrap: true,
                    gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                      columnCount, // Number of columns
                      childAspectRatio:
                      aspectRatio, // Maintain item aspect ratio
                    ),
                    itemCount: filteredWidgets.length,
                    itemBuilder: (context, index) {
                      return Center(
                        child: SizedBox(
                            width: itemWidth,
                            child: filteredWidgets[index]),
                      );
                    },
                  );
                },
              ),
            ) :
            const Expanded(child: SizedBox())
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
    ref.invalidate(plantWidgetsProvider);
  }
}
