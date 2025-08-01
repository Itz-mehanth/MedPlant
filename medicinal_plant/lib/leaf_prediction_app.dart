import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:medicinal_plant/genAI.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LeafPredictionApp extends StatefulWidget {
  // Support multiple input types
  final String? imageUrl;
  final File? imageFile;
  final Uint8List? imageBytes;

  const LeafPredictionApp({
    super.key,
    this.imageUrl,
    this.imageFile,
    this.imageBytes,
  }) : assert(
  (imageUrl != null) ^ (imageFile != null) ^ (imageBytes != null),
  'Exactly one of imageUrl, imageFile, or imageBytes must be provided'
  );

  @override
  _LeafPredictionAppState createState() => _LeafPredictionAppState();
}

class _LeafPredictionAppState extends State<LeafPredictionApp> {
  bool _isLoading = false;
  String _selectedModel = 'leaf'; // Default model selection
  Map<String, dynamic>? _results;
  List<String> plantNames = [];
  String? selectedPlant; // To store the selected plant name
  bool _isFetchingPlants = true;
  final List<String> _models = ['leaf', 'fruit']; // Models for dropdown

  // State variable to hold the image data for display
  Uint8List? _imageBytesForDisplay;

  @override
  void initState() {
    super.initState();
    _loadImageBytes();
    _fetchPlantNames();
  }

  /// Loads the image data from the provided source into the state.
  Future<void> _loadImageBytes() async {
    try {
      if (widget.imageBytes != null) {
        setState(() {
          _imageBytesForDisplay = widget.imageBytes;
        });
        return;
      }
      if (widget.imageFile != null) {
        if (kIsWeb) {
          // On web, fetch the image data from the blob URL.
          final response = await http.get(Uri.parse(widget.imageFile!.path));
          setState(() {
            _imageBytesForDisplay = response.bodyBytes;
          });
        } else {
          // On mobile, read the file bytes directly.
          setState(() {
            _imageBytesForDisplay = widget.imageFile!.readAsBytesSync();
          });
        }
      } else if (widget.imageUrl != null) {
        // If a network URL is provided.
        final response = await http.get(Uri.parse(widget.imageUrl!));
        setState(() {
          _imageBytesForDisplay = response.bodyBytes;
        });
      }
    } catch (e) {
      print("Error loading image for display: $e");
    }
  }

  // Fetch plant names from Firestore
  Future<void> _fetchPlantNames() async {
    try {
      final QuerySnapshot plantDocs =
      await FirebaseFirestore.instance.collection('plant_details').get();
      final List<String> names = plantDocs.docs.map((doc) => doc.id).toList();

      setState(() {
        plantNames = names;
        _isFetchingPlants = false;
      });
    } catch (e) {
      print('Error fetching plant names: $e');
      setState(() {
        _isFetchingPlants = false;
      });
    }
  }

  void sharePrediction() {
    if (_results == null) return;

    String message = "🔍 **Prediction Results:**\n"
        "📌 Class: ${_results?['predicted_class']}\n"
        "📊 Confidence: ${(_results?['confidence_level'] * 100).toStringAsFixed(2)}%\n";

    if (widget.imageUrl != null) {
      message += "\n🌿 View Image: ${widget.imageUrl}";
    }

    Share.share(message);
  }

  Future<void> _predict() async {
    setState(() {
      _isLoading = true;
      _results = null;
    });

    try {
      http.Response response;

      if (widget.imageUrl != null) {
        response = await http.post(
          Uri.parse('$ngrokUrl/predict'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'image_url': widget.imageUrl,
            'type': _selectedModel,
          }),
        );
      } else {
        var request = http.MultipartRequest('POST', Uri.parse('$ngrokUrl/predict'));
        request.fields['type'] = _selectedModel;
        Uint8List? fileBytes;
        if (widget.imageFile != null) {
          if (kIsWeb) {
            var fetchedResponse = await http.get(Uri.parse(widget.imageFile!.path));
            fileBytes = fetchedResponse.bodyBytes;
          } else {
            fileBytes = await widget.imageFile!.readAsBytes();
          }
        } else if (widget.imageBytes != null) {
          fileBytes = widget.imageBytes;
        }

        if (fileBytes != null) {
          final multipartFile = http.MultipartFile.fromBytes(
            'image',
            fileBytes,
            filename: widget.imageFile?.path.split('/').last ?? 'image.jpg',
          );
          request.files.add(multipartFile);
        } else {
          throw Exception("No image data available to send.");
        }

        var streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      }

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print("JsonData received: $jsonData");
        // Store the entire JSON response from the backend.
        setState(() {
          _results = jsonData;
        });
      } else {
        print('Error: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get prediction: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error during prediction: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred while predicting')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Save feedback to Firestore
  Future<void> _saveFeedback(String? predictedClass) async {
    if (predictedClass == null) return;
    if (selectedPlant != null) {
      try {
        Map<String, dynamic> feedbackData = {
          'selectedPlant': selectedPlant,
          'predictedClass': predictedClass,
          'timestamp': FieldValue.serverTimestamp(),
        };

        if (widget.imageUrl != null) {
          feedbackData['imageUrl'] = widget.imageUrl;
        }

        await FirebaseFirestore.instance.collection('user_feedback').add(feedbackData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback submitted successfully!')),
        );
      } catch (e) {
        print('Error saving feedback: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit feedback.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a plant name!')),
      );
    }
  }

  /// Builds the image display widget.
  Widget _buildImageWidget() {
    if (_imageBytesForDisplay != null) {
      return Image.memory(
        _imageBytesForDisplay!,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
      );
    }
    return const SizedBox(
      width: double.infinity,
      height: 200,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Prediction App'),
        backgroundColor: const Color.fromARGB(255, 68, 255, 0),
      ),
      body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImageWidget(),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Model:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    DropdownButton<String>(
                      value: _selectedModel,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedModel = newValue!;
                        });
                      },
                      items: _models.map((String model) {
                        return DropdownMenuItem<String>(
                          value: model,
                          child: Text(model[0].toUpperCase() + model.substring(1)),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _predict,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    backgroundColor: const Color.fromARGB(255, 68, 255, 0),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Predict',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                if (_results != null) ...[
                  const Text(
                    'Prediction Results:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Class: ${_results?['predicted_class']}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Confidence: ${((_results?['confidence_level'] ?? 0.0) * 100).toStringAsFixed(2)}%',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: sharePrediction,
                    icon: const Icon(Icons.share),
                    label: const Text("Share Results"),
                  )
                ],
                if (_isFetchingPlants)
                  const Center(child: CircularProgressIndicator())
                else
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contribute by sharing the plant species to use:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        DropdownButton<String>(
                          value: selectedPlant,
                          hint: const Text('Choose a plant'),
                          isExpanded: true,
                          items: plantNames.map((String plantName) {
                            return DropdownMenuItem<String>(
                              value: plantName,
                              child: Text(plantName),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedPlant = newValue;
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => _saveFeedback(_results?['predicted_class']),
                          child: const Text('Submit'),
                        ),
                      ],
                    ),
                  ),
                if (_results != null && _results!.isNotEmpty)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PredictionResultsPage(_results!),
                        ),
                      );
                    },
                    child: const Text("View Prediction Results"),
                  )
              ],
            ),
          )
      ),
    );
  }
}

class PredictionResultsPage extends StatelessWidget {
  final Map<String, dynamic> results;

  const PredictionResultsPage(this.results, {super.key});

  @override
  Widget build(BuildContext context) {
    // Safely extract the detailed 'predictions' map for individual models.
    final Map<String, dynamic> predictions = Map<String, dynamic>.from(results['predictions'] ?? {});
    final String summary = results['summary'] ?? 'No summary available.';

    // Safely extract the ensembled 'class_probabilities' for the main chart.
    final Map<String, double> ensembledProbabilities = Map<String, double>.from(results['class_probabilities'] ?? {});
    final List<String> classNames = ensembledProbabilities.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Prediction Results"),
        backgroundColor: const Color.fromARGB(255, 68, 255, 0),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomPaint(
              size: Size(double.infinity, 200),
              painter: CustomCanvasPainter(),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Summary: $summary',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: List.generate(classNames.length, (index) {
                  return Text(
                    '$index = ${classNames[index]}',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.03,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }),
              ),
            ),
            // Chart for the Ensembled Prediction
            if (ensembledProbabilities.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                child: PredictionBarChart(
                  modelName: "Ensemble Prediction",
                  classNames: classNames,
                  modelProbabilities: ensembledProbabilities.values.toList(),
                ),
              ),
            // Divider
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Divider(thickness: 2),
            ),
            // Charts for Individual Models
            ...predictions.entries.map((entry) {
              final modelData = Map<String, dynamic>.from(entry.value);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                child: PredictionBarChart(
                  modelName: modelData['model'] ?? entry.key,
                  classNames: List<String>.from(modelData['class_names'] ?? []),
                  modelProbabilities: List<double>.from(modelData['probabilities'] ?? []),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

class PredictionBarChart extends StatelessWidget {
  final String modelName;
  final List<String> classNames;
  final List<double> modelProbabilities;

  const PredictionBarChart({
    super.key,
    required this.modelName,
    required this.classNames,
    required this.modelProbabilities,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Text(
            '$modelName Probabilities',
            style: TextStyle(
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
        ),
        Container(
          height: 250,
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: classNames.length * 80.0,
              child: BarChart(
                BarChartData(
                  barGroups: List.generate(
                    classNames.length,
                        (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: modelProbabilities[index],
                          width: screenWidth * 0.02,
                          gradient: const LinearGradient(
                            colors: [Colors.blue, Colors.lightBlueAccent],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 1.0,
                            color: Colors.grey[300],
                          ),
                        ),
                      ],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 0.2,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: TextStyle(fontSize: screenWidth * 0.03),
                          );
                        },
                      ),
                    ),
                    bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    horizontalInterval: 0.2,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[300]!,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 1.0,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 5,),
      ],
    );
  }
}

class CustomCanvasPainter extends CustomPainter {
  const CustomCanvasPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const Gradient gradient = LinearGradient(
      colors: [Colors.lightGreenAccent, Color.fromARGB(255, 68, 255, 0)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final Paint paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(20)),
      paint,
    );

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(20)),
      shadowPaint,
    );

    const TextSpan titleSpan = TextSpan(
      text: 'Prediction Overview',
      style: TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
    final TextPainter titlePainter = TextPainter(
      text: titleSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    titlePainter.layout();
    titlePainter.paint(
      canvas,
      Offset(
        size.width / 2 - titlePainter.width / 2,
        size.height / 2 - titlePainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}