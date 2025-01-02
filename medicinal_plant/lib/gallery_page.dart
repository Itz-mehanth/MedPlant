import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({Key? key}) : super(key: key);

  @override
  _GalleryPageState createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  List<List<dynamic>> combinedList = [];
  List<List<dynamic>> selectedCombinedList = [];
  List<String> plantNames = [];
  final ImagePicker _picker = ImagePicker();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchImages();
    _fetchPlantNames();
  }

  Future<void> _fetchPlantNames() async {
    final QuerySnapshot plantDocs =
    await FirebaseFirestore.instance.collection('plant_details').get();
    final List<String> names = plantDocs.docs.map((doc) => doc.id).toList();

    setState(() {
      plantNames = names;
      isLoading = false;
    });
  }

  Future<void> _fetchImages() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final List<dynamic>? images = userDoc.get('images') as List<dynamic>?;

      if (images != null) {
        setState(() {
          combinedList = images.map((image) {
            String downloadUrl = image['downloadUrl'] as String;
            GeoPoint location = image['location'] as GeoPoint;
            return [downloadUrl, [location.latitude, location.longitude]];
          }).toList();
          print(combinedList);
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _showImageUploadPopup() async {
    Map<List<dynamic>, String?> selectedPlants = {}; // Track selected plant for each entry

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Upload Images'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: selectedCombinedList.length,
              itemBuilder: (context, index) {
                final entry = selectedCombinedList[index];
                final imageUrl = entry[0];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 75,
                      height: 80,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Image.network(imageUrl, fit: BoxFit.cover),
                    ),
                    Expanded(
                      child: DropdownButton<String>(
                        hint: const Text('Select Plant'),
                        value: selectedPlants[entry],
                        items: plantNames.map((name) {
                          return DropdownMenuItem(
                            value: name,
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedPlants[entry] = value;
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.upload),
                      color: Colors.blue,
                      onPressed: () {
                        _uploadImage(entry, selectedPlants[entry]);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadImage(List<dynamic> entry, String? selectedPlantName) async {
    if (selectedPlantName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a plant name for all images.')),
      );
      return;
    }

    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference storageRef = FirebaseStorage.instance
          .ref('images/$selectedPlantName/$fileName');

      final String imageUrl = entry[0];
      final List<double> loc = entry[1];
      final http.Response response = await http.get(Uri.parse(imageUrl));
      final Uint8List bytes = response.bodyBytes;

      await storageRef.putData(bytes); // Upload as bytes
      final String downloadUrl = await storageRef.getDownloadURL();

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('plant_details')
          .doc(selectedPlantName)
          .collection('images')
          .add({
        'url': downloadUrl,
        'uploadedAt': DateTime.now(),
      });

      final GeoPoint geoPoint = GeoPoint(loc[0], loc[1]);

      // Save the GeoPoint to the 'coordinates' collection
      await FirebaseFirestore.instance
          .collection('plant_details')
          .doc(selectedPlantName)
          .collection('coordinates')
          .add({
        'location': geoPoint,
        'addedAt': DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image uploaded to $selectedPlantName!')),
      );

      setState(() {
        selectedCombinedList.remove(entry); // Remove from the list after uploading
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  Future<void> _deleteSelectedImages() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null && selectedCombinedList.isNotEmpty) {
      for (List<dynamic> entry in selectedCombinedList) {
        final String imageUrl = entry[0];

        // Delete image from Firebase Storage
        final Reference ref = FirebaseStorage.instance.refFromURL(imageUrl);
        await ref.delete();

        // Remove the image reference from the user's collection
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'images': FieldValue.arrayRemove([
            {'downloadUrl': imageUrl, 'location': entry[1]},
          ]),
        });
      }

      setState(() {
        combinedList.removeWhere((entry) => selectedCombinedList.contains(entry));
        selectedCombinedList.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected images and associated plants deleted successfully.')),
      );
    }
  }

  void _openImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => FullScreenImage(imageUrl: imageUrl)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
        actions: [
          if (selectedCombinedList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelectedImages,
            ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showImageUploadPopup,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: combinedList.length,
        itemBuilder: (context, index) {
          final entry = combinedList[index];
          final imageUrl = entry[0];
          final isSelected = selectedCombinedList.contains(entry);

          return GestureDetector(
            onDoubleTap: () {
              setState(() {
                isSelected
                    ? selectedCombinedList.remove(entry)
                    : selectedCombinedList.add(entry);
              });
            },
            onTap: () => _openImage(imageUrl),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image
                      .network(imageUrl, fit: BoxFit.cover),
                      ),
                      if (isSelected)
                        Positioned(
                          top: 5,
                          right: 5,
                          child: Icon(Icons.check_circle,
                              color: Colors.green.withOpacity(0.8), size: 24),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('View Image')),
      body: Center(child: Image.network(imageUrl)),
    );
  }
}

class _SelectedImage {
  final File file;
  String? selectedPlantName;

  _SelectedImage({required this.file, this.selectedPlantName});
}
