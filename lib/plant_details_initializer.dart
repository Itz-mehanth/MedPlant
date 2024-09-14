import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medicinal_plant/home_page.dart';

class PlantWidgetsNotifier extends StateNotifier<List<PlantBoxWidget>> {
  PlantWidgetsNotifier() : super([]){
    fetchAndSetPlantWidgets();
  }

  Future<void> fetchAndSetPlantWidgets() async {
    List<String> plantNames = await fetchPlantNames();

    for (String plantName in plantNames) {
      PlantBoxWidget? widget = await fetchPlantWidget(plantName);
      if (widget != null) {
        state = [...state, widget];
        print("${state.length} widgets available");
      }
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

  Future<String> fetchRandomImageUrl(String plantName) async {
    try {
      final FirebaseStorage storage = FirebaseStorage.instanceFor(
        bucket: 'gs://medicinal-plant-82aa9.appspot.com',
      );

      final ListResult result =
      await storage.ref().child('images').child(plantName).listAll();
      final List<Reference> allFiles = result.items;

      if (allFiles.isEmpty) {
        return 'https://static.vecteezy.com/system/resources/previews/004/141/669/original/no-photo-or-blank-image-icon-loading-images-or-missing-image-mark-image-not-available-or-image-coming-soon-sign-simple-nature-silhouette-in-frame-isolated-illustration-vector.jpg';
      }

      final int randomIndex = DateTime.now().millisecond % allFiles.length;
      final Reference randomFile = allFiles[randomIndex];
      final String downloadUrl = await randomFile.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error fetching image URL: $e');
      return 'https://static.vecteezy.com/system/resources/previews/004/141/669/original/no-photo-or-blank-image-icon-loading-images-or-missing-image-mark-image-not-available-or-image-coming-soon-sign-simple-nature-silhouette-in-frame-isolated-illustration-vector.jpg';
    }
  }

  @override
  void dispose() {
    // Perform any necessary cleanup here
    super.dispose();
  }
}

final plantWidgetsProvider =
StateNotifierProvider<PlantWidgetsNotifier, List<PlantBoxWidget>>((ref) {
  return PlantWidgetsNotifier();
});
