import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LeafPredictionApp extends StatefulWidget {
  final File image; // Changed to final
  LeafPredictionApp({super.key, required this.image});

  @override
  _LeafPredictionAppState createState() => _LeafPredictionAppState();
}

class _LeafPredictionAppState extends State<LeafPredictionApp> {
  bool _isLoading = false;
  String? _results;
  double? _confidence;

  @override
  void initState() {
    super.initState();
    setState(() {
      _isLoading = true;
      classifyImage(widget.image);
    });
  }

  Future<void> classifyImage(File image) async {
    print("Starting image classification...");
    print("Sending request to TFLite model...");
    print("Image path: ${image.path}");

    try {
      // Prepare image file for the API request
      var request = http.MultipartRequest(
          'POST', Uri.parse('http://192.168.137.131:8080/classify'));
          // 'POST', Uri.parse('http://127.0.0.1:5000/classify'));

      request.files.add(await http.MultipartFile.fromPath('file', image.path));
      print("Image file added to the request.");

      // Send request to Flask server
      print("Sending request to Flask server...");
      var response = await request.send();
      print("Response status code: ${response.statusCode}");

      // Handle the response
      if (response.statusCode == 200) {
        var responseData = await http.Response.fromStream(response);
        print("Response data received successfully.");

        var result = jsonDecode(responseData.body);

        String predictedClass = result['predicted_class'];
        double confidence = result['confidence'];
        setState(() {
          _isLoading = false;
          _results = predictedClass.toString();
          _confidence = confidence;
        });

        print('Predicted Class: $predictedClass');
      } else {
        print('Error occurred. Status code: ${response.statusCode}');
        print('Error message: ${response.reasonPhrase}');
      }
    } catch (e) {
      print("An error occurred during the request:");
      print(e.toString());
    }

    print("Image classification process completed.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Image Classification'),
        backgroundColor: const Color.fromARGB(255, 68, 255, 0), // Custom app bar color
      ),
      body: Padding(
        padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16
        ), // Padding around the entire body
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16), // Rounded corners for the container
                  color: Colors.white, // Custom background color
                  boxShadow: const [
                    BoxShadow(
                    color: Colors.black38, // Shadow color
                    blurRadius: 8, // Shadow blur radius
                    offset: Offset(0, 1), // Shadow offset
                  )
                  ] 
                ),
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                          ClipRRect(
                                borderRadius: BorderRadius.circular(16), // Rounded corners for the image
                                child: Image.file(
                                  widget.image,
                                  width: 300, // Make the image take full width
                                  height: 300, // Fixed height for the image
                                  fit: BoxFit.cover,
                                ),
                              ),
                        const SizedBox(height: 16),
                        if (_results != null) // Display results only if available
                          Column(
                            children: [
                              Text(
                                'Predicted Class: ${_results.toString()}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Column(
                                children: [
                                  Text(
                                    'Confidence Level',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  CircularProgressIndicator(
                                    value: _confidence, // Confidence level (should be between 0.0 and 1.0)
                                    backgroundColor: Colors.grey[300],
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green), // Progress color
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${(_confidence! * 100).toStringAsFixed(2)}%', // Display confidence as a percentage
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                ),
              ),
            ),
      ),
    );
  }
}
