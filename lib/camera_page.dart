import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:medicinal_plant/leaf_prediction_app.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:medicinal_plant/widget_tree.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  static Future<CameraController?> setupCameraController() async {
    PermissionStatus status = await Permission.camera.request();
    if (status.isGranted) {
      List<CameraDescription> cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        CameraController cameraController = CameraController(
          cameras.last,
          ResolutionPreset.high,
        );
        try {
          await cameraController.initialize();
          return cameraController;
        } catch (e) {
          print('Error initializing camera: $e');
        }
      } else {
        print('No cameras available');
      }
    } else {
      print('Camera permission not granted');
    }
    return null;
  }

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? cameraController;
  final ImagePicker picker = ImagePicker();
  File? image;
  bool imageSelected = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (cameraController == null ||
        cameraController?.value.isInitialized == false) return;

    if (state == AppLifecycleState.inactive) {
      cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      setupCameraController();
    }
  }

  @override
  void initState() {
    super.initState();
    setupCameraController();
  }

  Future<void> setupCameraController() async {
    CameraController? controller = await CameraPage.setupCameraController();
    if (controller != null) {
      setState(() {
        cameraController = controller;
      });
    }
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }

  Future<File?> _imageCropper(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image != null) {
      // Resize the image to a 224x224 thumbnail (for example)
      final resizedImage = img.copyResize(image, width: 224, height: 224);

      // Get the directory to save the resized image
      final directory = await getApplicationDocumentsDirectory();

      // Create a file in the directory
      final resizedImagePath = path.join(directory.path, 'resized_image.jpg');
      final resizedImageFile = File(resizedImagePath);

      // Encode the image to JPEG format and write it to the file
      await resizedImageFile.writeAsBytes(img.encodeJpg(resizedImage));

      return resizedImageFile;
    }
    return null;
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? galleryPickedFile =
    await picker.pickImage(source: ImageSource.gallery);
    if (galleryPickedFile != null) {
      print("image picked successfully");
      // File? croppedImage = await _imageCropper(File(galleryPickedFile.path));
      File galleryPickedFileAsFile = File(galleryPickedFile.path);
      setState(() {
        image = galleryPickedFileAsFile;
        imageSelected = true;
      });
      print('Gallery image selected:${image != null} ${galleryPickedFile.path}');
    } else {
      print('No image selected from gallery');
    }
  }

  Future<void> _pickImageFromCamera() async {
    if (cameraController != null && cameraController!.value.isInitialized) {
      final XFile cameraPickedFile = await cameraController!.takePicture();
      print("image picked successfully");
      // File? croppedImage = await _imageCropper(File(cameraPickedFile.path));
      File cameraPickedFileAsFile = File(cameraPickedFile.path);
      setState(() {
        image = cameraPickedFileAsFile;
        imageSelected = true;
      });
      print('Camera image selected:${image != null} ${cameraPickedFile.path}');
    } else {
      print('Camera is not initialized');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        height:MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  image != null
                      ? Expanded(
                    child: kIsWeb
                        ? Image.network(
                      image!.path,
                      fit: BoxFit.cover,
                    )
                        : Image.file(
                      image!,
                      fit: BoxFit.cover,
                    ),
                  )
                      : cameraController != null &&
                      cameraController!.value.isInitialized
                      ? Expanded(child: CameraPreview(cameraController!))
                      : Expanded(
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            style: BorderStyle.solid,
                            color: Colors.black38,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Initializing camera...',
                            style: TextStyle(
                              color: Colors.black38,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                height: 50,
                width: MediaQuery.of(context).size.width,
                alignment: Alignment.centerLeft,
                decoration: const BoxDecoration(color: Colors.black),
                padding: const EdgeInsets.all(10),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) {
                        return const WidgetTree();
                      }),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: Container(
                width:  MediaQuery.of(context).size.width,
                decoration:
                const BoxDecoration(color: Color.fromARGB(255, 0, 0, 0)),
                child: imageSelected
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.done_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        if (image != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const LeafPredictionApp(
                                // image: image!,
                              ),
                            ),
                          );
                        } else {
                          print("image not found");
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.cancel_outlined,
                        size: 40,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          imageSelected = false;
                          image = null;
                          setupCameraController();
                        });
                      },
                    ),
                  ],
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.folder,
                        size: 40,
                        color: Colors.white,
                      ),
                      onPressed: _pickImageFromGallery,
                    ),
                    IconButton(
                      onPressed: _pickImageFromCamera,
                      icon: const Icon(
                        Icons.circle,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
