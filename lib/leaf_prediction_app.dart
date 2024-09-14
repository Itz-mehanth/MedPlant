import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LeafPredictionApp extends StatefulWidget {
  const LeafPredictionApp({super.key});

  @override
  _LeafPredictionAppState createState() => _LeafPredictionAppState();
}

class _LeafPredictionAppState extends State<LeafPredictionApp> {
  bool _isLoading = true;
  XFile? _image;
  List<dynamic>? _results;

  @override
  void initState() {
    super.initState();
    setState(() {
      _isLoading = true;
    });
  }

  Future<void> classifyImage(XFile image) async {
    const url = 'http://localhost:8000/classify'; // Replace with your FastAPI endpoint URL
    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.files.add(await http.MultipartFile.fromPath('image', image.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(await response.stream.bytesToString());
      setState(() {
        _isLoading = false;
        _results = jsonData;
      });
    } else {
      print('Error: ${response.statusCode}');
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _isLoading = true;
        _image = pickedImage;
      });
      classifyImage(pickedImage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TFLite Image Classification'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: <Widget>[
          _image == null
              ? const Text('No image selected.')
              : Image.file(File(_image!.path)),
          const SizedBox(height: 16),
          _results != null
              ? Text('Results: ${_results.toString()}')
              : Container(),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: pickImage,
            child: const Text('Pick Image'),
          ),
        ],
      ),
    );
  }
}