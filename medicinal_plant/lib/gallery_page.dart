import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get_connect/http/src/response/response.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({Key? key}) : super(key: key);

  @override
  _GalleryPageState createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  List<String> imageUrls = [
    'https://tse1.mm.bing.net/th?id=OIP.cfxVoPK-zXAsxKiTmA3qVwHaFj&pid=Api&P=0&h=180',
    'https://tse4.mm.bing.net/th?id=OIP.rvSWtRd_oPRTwDoTCmkP5gHaE8&pid=Api&P=0&h=180'
  ];

  List<_SelectedImage> selectedImages = [];
  List<String> selectedImageUrls = []; // Separate selected URLs for deletion
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
          imageUrls =
              images.map((image) => image['downloadUrl'] as String).toList();
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
    Map<String, String?> selectedPlants = {}; // Track selected plant for each URL

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Upload Images'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: selectedImageUrls.length,
              itemBuilder: (context, index) {
                final imageUrl = selectedImageUrls[index];
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
                        value: selectedPlants[imageUrl],
                        items: plantNames.map((name) {
                          return DropdownMenuItem(
                            value: name,
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            print("Selected Plant: $value"); // Debugging line
                            selectedPlants[imageUrl] = value;
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.upload),
                      color: Colors.blue,
                      onPressed: () {
                        _uploadImage(imageUrl, selectedPlants[imageUrl]);
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


  Future<void> _uploadImage(String imageUrl, String? selectedPlantName) async {
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

      // Use the image URL directly (for Flutter Web: fetch and upload bytes)
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image uploaded to $selectedPlantName!')),
      );

      setState(() {
        selectedImageUrls.remove(imageUrl); // Remove from the list after uploading
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  Future<void> _deleteSelectedImages() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null && selectedImageUrls.isNotEmpty) {
      for (String imageUrl in selectedImageUrls) {
        // Delete image from Firebase Storage

        final Reference ref = FirebaseStorage.instance.refFromURL(imageUrl);
        await ref.delete();

        // Remove the image reference from the user's collection
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'images': FieldValue.arrayRemove([{'downloadUrl': imageUrl}]),
        });

      }

      // Update UI to reflect changes
      setState(() {
        imageUrls.removeWhere((url) => selectedImageUrls.contains(url));
        selectedImageUrls.clear();
      });

      // Show confirmation to the user
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
          if (selectedImageUrls.isNotEmpty)
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
              itemCount: imageUrls.length,
              itemBuilder: (context, index) {
                final imageUrl = imageUrls[index];
                final isSelected = selectedImageUrls.contains(imageUrl);

                return GestureDetector(
                  onDoubleTap: () {
                    setState(() {
                      isSelected
                          ? selectedImageUrls.remove(imageUrl)
                          : selectedImageUrls.add(imageUrl);
                    });
                  },
                  onTap: () => _openImage(imageUrl),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(imageUrl, fit: BoxFit.cover),
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
