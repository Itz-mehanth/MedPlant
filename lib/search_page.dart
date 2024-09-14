import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:lottie/lottie.dart';
import 'package:medicinal_plant/home_page.dart';
import 'package:medicinal_plant/plant_details_page.dart';
import 'package:medicinal_plant/utils/global_functions.dart';
import 'package:medicinal_plant/widget_tree.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:just_audio/just_audio.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final AudioPlayer _audioPlayer =
  AudioPlayer(); // Declare and initialize the AudioPlayer
  final SpeechToText _speechToText = SpeechToText();
  final FocusNode _focusNode = FocusNode();
  bool _speechEnabled = false;
  // bool _isListening = false;
  String _lastWords = '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> plantDetails = [];
  List<String> searchSuggestions = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isTextFieldFocused = false;
  bool _isLoading = false; // Add loading state
  DateTime? _startListeningTimestamp; // Timestamp for when listening started
  Timer? _timer; // Timer for auto-stopping listening

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _searchController.addListener(_onSearchChanged);
    // Add a listener to the FocusNode
    _focusNode.addListener(() {
      setState(() {
        _isTextFieldFocused = _focusNode.hasFocus;
        if (_isTextFieldFocused) {
          _stopListening();
          _lastWords = '';
        }
      });
    });
  }

  void _playVoice() async {
    try {
      await _audioPlayer.setAsset('assets/Sounds/AI voice.mp3');
      _audioPlayer.play();
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  void _playSound() async {
    try {
      await _audioPlayer.setAsset('assets/Sounds/cling.wav');
      _audioPlayer.play();
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {
      print('Speech initialized: $_speechEnabled');
    });
  }

  void _onSearchChanged() {
    if (_searchController.text.isNotEmpty) {
      _fetchSearchSuggestions(_searchController.text);
    } else {
      setState(() {
        searchSuggestions = [];
      });
    }
  }

  List<String> searchPlants(String query, List<String> plantNames) {
    List<String> filteredPlants = [];

    for (String plantName in plantNames) {
      if(tokenSetRatio(plantName, query) >= 50.0){
        filteredPlants.add(plantName);
      }
    }
    return filteredPlants;
  }

  Future<void> _fetchSearchSuggestions(String query) async {
    try {
      QuerySnapshot querySnapshot =
      await _firestore.collection('plant_details').get();
      List<String> suggestions = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['Common Name'] as String;
      }).toList();

      setState(() {
        searchSuggestions = searchPlants(query, suggestions);
      });
    } catch (e) {
      print('Error fetching search suggestions: $e');
    }
  }

  Future<void> fetchPlantDetail(String plantName) async {
    setState(() {
      print("Fetching plant");
      _isLoading = true; // Start loading
    });
    try {
      DocumentSnapshot doc =
      await _firestore.collection('plant_details').doc(plantName).get();

      if (!doc.exists) {
        throw Exception('No plant details found for: $plantName');
      }

      final documentData = doc.data() as Map<String, dynamic>;

      // Check for required keys and handle missing keys
      String plantCommonName = documentData['Common Name'] ?? 'N/A';
      String plantDescription = documentData['Description'] ?? 'N/A';
      String scientificName = documentData['Scientific Name'] ?? 'N/A';
      String family = documentData['Family'] ?? 'N/A';

      plantDetails = [
        plantCommonName,
        plantDescription,
        scientificName,
        family
      ];
    } catch (e) {
      // Handle errors
      print('Error fetching plant details: $e');
      plantDetails = [
        'Error',
        'Error',
        'Error',
        'Error'
      ]; // Return a list indicating an error
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  Widget searchResult(String recommendation) {
    return Container(
      height: 30,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>(
                (Set<WidgetState> states) {
              if (states.contains(WidgetState.hovered)) {
                return const Color.fromARGB(221, 228, 228, 228);
              }
              return Colors.white;
            },
          ),
          foregroundColor: WidgetStateProperty.resolveWith<Color>(
                (Set<WidgetState> states) {
              if (states.contains(WidgetState.hovered)) {
                return Colors.black;
              }
              return Colors.black;
            },
          ),
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
            const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
          padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
            EdgeInsets.zero,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Icon(Icons.search, color: Colors.black),
            const SizedBox(width: 20),
            Text(
              recommendation,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        onPressed: () async {
          setState(() {
            print("is loading");
            _isLoading = true;
          });
          await fetchPlantDetail(recommendation).then((_) {
            setState(() {
              _isLoading = false;
              print("is not loading");
            });
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlantDetailsPage(
                  plantName: plantDetails[0],
                  plantDescription: plantDetails[1],
                  scientificName: plantDetails[2],
                  family: plantDetails[3],
                ),
              ),
            );
          });
        },
      ),
    );
  }

  void _startListening() async {
    // Check if speech recognition is already active
    if (_speechToText.isListening) {
      print('Speech recognition is already active.');
      return; // Exit the function if it's already listening
    }

    if (_speechEnabled) {
      _startListeningTimestamp = DateTime.now();
      try {
        await _speechToText.listen(
          localeId: currentLocale,
          onResult: _onSpeechResult,
          listenFor: const Duration(seconds: 20),
          pauseFor: const Duration(microseconds: 0),
          listenOptions: SpeechListenOptions(
            listenMode: ListenMode.search,
            autoPunctuation: true,
            // Replace with your preferred language code
          ),
        );
        _playSound();
        setState(() {
          print('Started listening');
        });

        // Start a timer to stop listening after a certain period
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_speechToText.isListening) {
            final elapsed =
            DateTime.now().difference(_startListeningTimestamp!);
            if (elapsed.inSeconds >= 10) {
              if (_lastWords.isEmpty) {
                _playVoice();
              }
              _stopListening();
              timer.cancel();
            }
          } else {
            timer.cancel();
          }
        });
      } catch (e) {
        print('Error starting listening: $e');
      }
    } else {
      print('Speech recognition is not enabled.');
    }
  }

  void _stopListening() async {
    if (_speechToText.isListening && _speechEnabled) {
      try {
        await _speechToText.stop();
        _timer?.cancel();
        setState(() {
          print('Stopped listening');
        });
      } catch (e) {
        print('Error stopping listening: $e');
      }
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
      _searchController.text = _lastWords;
      _startListeningTimestamp =
          DateTime.now(); // Reset the timestamp on new input
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromARGB(255, 68, 255, 0),
      ),
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            SizedBox(
              height: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const WidgetTree()),
                      );
                    },
                    iconSize: 20,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  PlantSearchBar(
                    isEnabled: true,
                    searchController: _searchController,
                    searchFocusNode: _focusNode,
                  ),
                  IconButton(
                    iconSize: 20,
                    icon: Icon(
                        !_speechToText.isListening ? Icons.mic_off : Icons.mic),
                    onPressed: () {
                      if (_speechToText.isListening) {
                        _stopListening();
                      } else {
                        _startListening();
                      }
                    },
                  ),
                ],
              ),
            ),
            const Divider(thickness: 1),
            !_isTextFieldFocused &&
                _searchController.text.isEmpty &&
                !_isLoading
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(16),
                  child: TranslatedText(
                    _speechToText.isListening
                        ? _lastWords
                        : _speechEnabled
                        ? 'Tap the microphone to start listening...'
                        : 'Speech not available',
                  ),
                ),
                _speechToText.isListening
                    ? SizedBox(
                  height: 200,
                  width: 200,
                  child: Center(
                    child: Lottie.asset(
                      'assets/animations/microphone.json',
                      fit: BoxFit.contain,
                    ),
                  ),
                )
                    : const SizedBox(height: 0),
              ],
            )
                : _isLoading
                ? SizedBox(
              height: MediaQuery.of(context).size.height / 2 - 51,
              child: const Center(child: CircularProgressIndicator()),
            )
                : Container(
              height: min((30.0 * searchSuggestions.length),
                  (MediaQuery.of(context).size.height / 2)),
              width: MediaQuery.of(context).size.width * 0.8,
              decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black38),
                  ],
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  )),
              child: ListView.builder(
                shrinkWrap: true,
                scrollDirection: Axis.vertical,
                itemCount: searchSuggestions.length,
                itemBuilder: (context, index) {
                  return searchResult(searchSuggestions[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _audioPlayer.dispose(); // Dispose of the player when the widget is removed
    super.dispose();
  }
}
