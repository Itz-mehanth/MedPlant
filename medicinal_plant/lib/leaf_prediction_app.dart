import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:medicinal_plant/genAI.dart';

class LeafPredictionApp extends StatefulWidget {
  LeafPredictionApp({super.key});

  @override
  _LeafPredictionAppState createState() => _LeafPredictionAppState();
}

class _LeafPredictionAppState extends State<LeafPredictionApp> {
  bool _isLoading = true;
  XFile? _image;
  Map<String, dynamic>? _results;

  @override
  void initState() {
    super.initState();
    setState(() {
      _isLoading = true;
    });
  }

  Future<void> classifyImage(String imageUrl) async {
    var url = ngrokUrl + '/predict'; // Replace with your FastAPI endpoint URL
    final request = http.MultipartRequest('POST', Uri.parse(url));

    // Pass the image URL as part of the request body (not as a file)
    request.fields['image_url'] = imageUrl;

    final response = await request.send();
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(await response.stream.bytesToString());

      // Extract predicted class and confidence level from the response
      final String predictedClass = jsonData['predicted_class'];  // Adjust key name based on the API response
      final double confidenceLevel = jsonData['confidence'];  // Adjust key name based on the API response
      setState(() {
        _isLoading = false;
        _results = {
          'class': predictedClass,
          'confidence': confidenceLevel,
        };
      });
    } else {
      print('Error: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String imageUrl = ModalRoute.of(context)?.settings.arguments as String;

    // Classify the image if it's not already being processed
    if (imageUrl.isNotEmpty) {
      classifyImage(imageUrl);
    }

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
                    ? Column(
                  children: [
                        Text('Predicted Class: ${_results?['class']}'),
                        Text('Confidence: ${_results?['confidence'].toStringAsFixed(2)}'),
                      ],
                    )
                    : Container(),
                const SizedBox(height: 16),
              ],
            ),
    );
  }
}