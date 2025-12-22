import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class PlantClassifier {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;

  // Model configuration
  static const int inputSize = 128;
  static const int numClasses = 30;

  /// Initialize the model
  Future<void> loadModel() async {
    await initialize();
  }

  /// Initialize the model
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🌱 Loading plant classifier model...');

      // Load the TFLite model
      _interpreter = await Interpreter.fromAsset('assets/model/plant_classifier.tflite');

      // Load labels
      final labelsData = await rootBundle.loadString('assets/model/labels.txt');
      _labels = labelsData.split('\n').where((label) => label.isNotEmpty).toList();

      _isInitialized = true;
      print('✅ Model loaded successfully!');
      print('   Input shape: ${_interpreter!.getInputTensor(0).shape}');
      print('   Output shape: ${_interpreter!.getOutputTensor(0).shape}');
      print('   Classes: ${_labels.length}');
    } catch (e) {
      print('❌ Error loading model: $e');
      rethrow;
    }
  }

  /// Predict plant class from image file
  Future<Map<String, dynamic>> predict(String imagePath) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      print('🔍 Analyzing image: $imagePath');

      // Load and preprocess image
      final input = await _preprocessImage(imagePath);

      // Prepare output buffer
      var output = List.filled(1 * numClasses, 0.0).reshape([1, numClasses]);

      // Run inference
      final startTime = DateTime.now();
      _interpreter!.run(input, output);
      final inferenceTime = DateTime.now().difference(startTime).inMilliseconds;

      print('⏱️ Inference time: ${inferenceTime}ms');

      // Process results
      final predictions = output[0] as List<double>;
      final results = _processResults(predictions);

      return {
        'success': true,
        'predicted_class': results['top_prediction']['label'],
        'confidence': results['top_prediction']['confidence'],
        'inference_time_ms': inferenceTime,
        'all_predictions': results['all_predictions'],
        'top_5': results['top_5'],
      };
    } catch (e) {
      print('❌ Prediction error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Predict from image bytes (for camera/gallery)
  Future<Map<String, dynamic>> predictFromBytes(Uint8List imageBytes) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Preprocess
      final input = _preprocessImageData(image);

      // Prepare output
      var output = List.filled(1 * numClasses, 0.0).reshape([1, numClasses]);

      // Run inference
      final startTime = DateTime.now();
      _interpreter!.run(input, output);
      final inferenceTime = DateTime.now().difference(startTime).inMilliseconds;

      // Process results
      final predictions = output[0] as List<double>;
      final results = _processResults(predictions);

      return {
        'success': true,
        'predicted_class': results['top_prediction']['label'],
        'confidence': results['top_prediction']['confidence'],
        'inference_time_ms': inferenceTime,
        'all_predictions': results['all_predictions'],
        'top_5': results['top_5'],
      };
    } catch (e) {
      print('❌ Prediction error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Preprocess image from file path
  Future<List<List<List<List<double>>>>> _preprocessImage(String imagePath) async {
    final imageFile = File(imagePath);
    final imageBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(imageBytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    return _preprocessImageData(image);
  }

  /// Preprocess image data
  List<List<List<List<double>>>> _preprocessImageData(img.Image image) {
    // Resize to 128x128
    final resized = img.copyResize(
      image,
      width: inputSize,
      height: inputSize,
      interpolation: img.Interpolation.linear,
    );

    // Convert to normalized float array [1, 128, 128, 3]
    List<List<List<List<double>>>> input = List.generate(
      1,
      (batch) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
               pixel.r / 255.0,   // Normalize to 0-1 (Image v4)
               pixel.g / 255.0,
               pixel.b / 255.0,
            ];
          },
        ),
      ),
    );

    return input;
  }

  /// Process model output
  Map<String, dynamic> _processResults(List<double> predictions) {
    // Create list of (label, confidence) pairs
    final results = List.generate(
      predictions.length,
      (i) => {
        'label': _labels[i],
        'confidence': predictions[i],
        'index': i,
      },
    );

    // Sort by confidence (descending)
    results.sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));

    // Get top prediction
    final topPrediction = results[0];

    // Get top 5 predictions
    final top5 = results.take(5).toList();

    // Create map of all predictions
    final allPredictions = Map.fromIterables(
      _labels,
      predictions,
    );

    return {
      'top_prediction': topPrediction,
      'top_5': top5,
      'all_predictions': allPredictions,
    };
  }

  /// Get confidence level description
  String getConfidenceLevel(double confidence) {
    if (confidence >= 0.9) return 'Very High';
    if (confidence >= 0.7) return 'High';
    if (confidence >= 0.5) return 'Medium';
    if (confidence >= 0.3) return 'Low';
    return 'Very Low';
  }

  /// Dispose resources
  void close() {
    dispose();
  }

  /// Dispose resources
  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
    print('🗑️ Model resources disposed');
  }
}
