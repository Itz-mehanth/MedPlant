import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import "home_page.dart";
import 'package:medicinal_plant/services/plant_classifier.dart';


const String serverUrl = 'https://medplant-backend.onrender.com';

class LiveAnalysisScreen extends StatefulWidget {
  const LiveAnalysisScreen({super.key});

  @override
  LiveAnalysisScreenState createState() => LiveAnalysisScreenState();
}

class LiveAnalysisScreenState extends State<LiveAnalysisScreen>
    with TickerProviderStateMixin {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late IO.Socket socket;
  Timer? _frameTimer;

  // Offline Classifier
  final PlantClassifier _offlineClassifier = PlantClassifier();
  bool _isOfflineMode = false;

  List<Map<String, dynamic>>? _predictionResults;
  String _serverStatus = 'Connecting...';
  bool _isAnalyzing = false;

  // Animation controllers
  late AnimationController _scanController;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _scanAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initCamera();
    _initSocket();
    _offlineClassifier.loadModel();
  }

  void _initAnimations() {
    _scanController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.elasticInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin:
          const Offset(0.0, 1.0), // Changed to slide up from bottom on mobile
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _pulseController.repeat(reverse: true);
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    setState(() {
      _initializeControllerFuture = _controller.initialize().then((_) {
        startStreaming();
      });
    });
  }

  void _initSocket() {
    socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'timeout': 5000,
    });

    // Auto-switch to offline if not connected in 5 seconds
    Timer(const Duration(seconds: 5), () {
      if (mounted && !socket.connected && !_isOfflineMode) {
        setState(() {
          _isOfflineMode = true;
          _serverStatus = 'Connection Timed Out';
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Server unreachable. Switched to Offline Mode.'),
              backgroundColor: Colors.amber,
              duration: Duration(seconds: 3),
            ),
          );
        });
      }
    });

    socket.onConnect((_) {
      if (mounted) {
        setState(() {
          _serverStatus = 'Connected';
        });
      }
    });

    socket.onConnectError((err) {
       print('Socket Connect Error: $err');
       if (mounted && !_isOfflineMode) {
         setState(() {
           _isOfflineMode = true; // Auto-switch on error
         });
       }
    });

    socket.on('prediction_result', (data) {
      if (!_isOfflineMode && data != null && data['results'] is List) {
        if (mounted) {
          setState(() {
            _predictionResults = List<Map<String, dynamic>>.from(data['results']);
            _isAnalyzing = false;
          });
          _scanController.stop();
          _slideController.forward();
        }
      }
    });

    socket.onDisconnect((_) {
      if (mounted) {
        setState(() {
          _serverStatus = 'Disconnected';
        });
      }
    });

    socket.onError((err) => print('Socket Error: $err'));
  }

  void startStreaming() {
    _frameTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!_controller.value.isInitialized) return;

      try {
        if (mounted) {
          setState(() {
            _isAnalyzing = true;
          });
        }
        _slideController.reset();
        _scanController.repeat();

        final image = await _controller.takePicture();
        
        if (_isOfflineMode) {
           // Offline Prediction
           final bytes = await image.readAsBytes();
           final predictionMap = await _offlineClassifier.predictFromBytes(bytes);
           final top5 = predictionMap['top_5'] as List<dynamic>;
           
           if (mounted) {
             setState(() {
               _predictionResults = top5.map((r) {
                 return {
                   'type': 'Plant', // Detection logic simpler here
                   'predicted_class': r['label'],
                   'binary_confidence': r['confidence'],
                   'classifier_confidence': r['confidence'],
                 };
               }).toList();
               _isAnalyzing = false;
             });
             _scanController.stop();
             _slideController.forward();
           }
        } else {
          // Online Prediction (Socket.IO)
          final bytes = await image.readAsBytes();
          final base64Image = base64Encode(bytes);

          if (socket.connected) {
            socket.emit('frame', {'image': 'data:image/jpeg;base64,$base64Image'});
          }
        }
      } catch (e) {
        print("Analysis Error: $e");
        if (mounted) {
          setState(() {
            _isAnalyzing = false;
          });
          _scanController.stop();
        }
      }
    });
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    _controller.dispose();
    socket.dispose();
    _scanController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildMobileHeader(),
            Expanded(child: _buildMobileContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 20,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: isSmallScreen ? 48 : 56,
            width: isSmallScreen ? 48 : 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              Icons.biotech,
              color: Colors.white,
              size: isSmallScreen ? 24 : 28,
            ),
          ),
          SizedBox(width: isSmallScreen ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Analysis',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'AI Plant Recognition',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _buildMobileConnectionStatus(),
        ],
      ),
    );
  }

  Widget _buildMobileConnectionStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status Text
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isOfflineMode ? 'OFFLINE' : 'ONLINE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: _isOfflineMode ? Colors.amber[800] : const Color(0xFF059669),
                  letterSpacing: 0.5,
                ),
              ),
              if (!_isOfflineMode)
                Text(
                  socket.connected ? 'Connected' : 'Connecting...',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          // Toggle Switch
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: !_isOfflineMode, // True = Online
              activeColor: const Color(0xFF059669),
              activeTrackColor: const Color(0xFF059669).withOpacity(0.2),
              inactiveThumbColor: Colors.amber[800],
              inactiveTrackColor: Colors.amber[100],
              onChanged: (bool isOnline) {
                setState(() {
                  _isOfflineMode = !isOnline;
                  _isAnalyzing = false;
                  _predictionResults = null;
                });
                
                if (isOnline) {
                   socket.connect();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileContent() {
    return Column(
      children: [
        // Camera Section (Top)
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Color(0xFF3B82F6),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Live Camera',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const Spacer(),
                      if (_isAnalyzing)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0EA5E9).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF0EA5E9),
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Analyzing',
                                style: TextStyle(
                                  color: Color(0xFF0EA5E9),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          FutureBuilder<void>(
                            future: _initializeControllerFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.done) {
                                return SizedBox.expand(
                                  child: FittedBox(
                                    fit: BoxFit.cover,
                                    child: SizedBox(
                                      width:
                                          _controller.value.previewSize!.height,
                                      height:
                                          _controller.value.previewSize!.width,
                                      child: CameraPreview(_controller),
                                    ),
                                  ),
                                );
                              } else {
                                return Container(
                                  color: const Color(0xFFF9FAFB),
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          color: Color(0xFF3B82F6),
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          'Starting Camera...',
                                          style: TextStyle(
                                            color: Color(0xFF6B7280),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                          if (_isAnalyzing) _buildMobileScannerOverlay(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Results Section (Bottom)
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.analytics,
                          color: Color(0xFF059669),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Analysis Results',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: MobileResultsWidget(
                    results: _predictionResults,
                    slideAnimation: _slideAnimation,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileScannerOverlay() {
    return AnimatedBuilder(
      animation: _scanAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Mobile scanning line
            Positioned(
              top: (_scanAnimation.value *
                      (MediaQuery.of(context).size.height * 0.3)) -
                  1,
              left: 0,
              right: 0,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFF0EA5E9),
                      Colors.transparent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0EA5E9).withOpacity(0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
            // Simplified grid for mobile
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF0EA5E9).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: List.generate(
                    2,
                    (i) => Expanded(
                          child: Row(
                            children: List.generate(
                                2,
                                (j) => Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: const Color(0xFF0EA5E9)
                                                .withOpacity(0.1),
                                            width: 0.5,
                                          ),
                                        ),
                                      ),
                                    )),
                          ),
                        )),
              ),
            ),
          ],
        );
      },
    );
  }
}

class MobileResultsWidget extends StatelessWidget {
  final List<Map<String, dynamic>>? results;
  final Animation<Offset> slideAnimation;

  const MobileResultsWidget({
    Key? key,
    this.results,
    required this.slideAnimation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (results == null || results!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.search,
                size: 40,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Awaiting Analysis',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Point your camera at a plant to begin identification',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    // Use SlideTransition only for initial appearance, then show results directly
    return ListView.builder(
      key: ValueKey(results.hashCode), // Key for AnimatedSwitcher
      padding: EdgeInsets.zero,
      itemCount: results!.length,
      itemBuilder: (context, index) {
        final result = results![index];
        return _buildMobileResultCard(result, index);
      },
    );
  }

  Widget _buildMobileResultCard(Map<String, dynamic> result, int index) {
    final type = result['type']?.toString().capitalize() ?? 'N/A';
    final predictedClass = result['predicted_class'] ?? 'Unknown';
    final binaryConfidence = (result['binary_confidence'] ?? 0.0) * 100;
    final classifierConfidence = (result['classifier_confidence'] ?? 0.0) * 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: _getTypeGradient(type),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getPlantIcon(type),
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        predictedClass,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        type,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildMobileConfidenceChip(classifierConfidence),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildMobileMetricRow('Detection', binaryConfidence),
                const SizedBox(height: 12),
                _buildMobileMetricRow('Classification', classifierConfidence),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileConfidenceChip(double confidence) {
    Color chipColor;
    String label;

    if (confidence >= 90) {
      chipColor = const Color(0xFF059669);
      label = 'Excellent';
    } else if (confidence >= 75) {
      chipColor = const Color(0xFF0EA5E9);
      label = 'Good';
    } else if (confidence >= 60) {
      chipColor = const Color(0xFFEAB308);
      label = 'Fair';
    } else {
      chipColor = const Color(0xFFDC2626);
      label = 'Low';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: chipColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildMobileMetricRow(String label, double value) {
    Color barColor;
    if (value >= 75) {
      barColor = const Color(0xFF059669);
    } else if (value >= 50) {
      barColor = const Color(0xFFEAB308);
    } else {
      barColor = const Color(0xFFDC2626);
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value / 100,
            child: Container(
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: barColor.withOpacity(0.3),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  LinearGradient _getTypeGradient(String type) {
    switch (type.toLowerCase()) {
      case 'flower':
        return const LinearGradient(
          colors: [Color(0xFFEC4899), Color(0xFFBE185D)],
        );
      case 'leaf':
        return const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF047857)],
        );
      case 'herb':
        return const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
        );
    }
  }

  IconData _getPlantIcon(String type) {
    switch (type.toLowerCase()) {
      case 'flower':
        return Icons.local_florist;
      case 'leaf':
        return Icons.eco;
      case 'herb':
        return Icons.grass;
      default:
        return Icons.nature;
    }
  }
}

// Helper extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
