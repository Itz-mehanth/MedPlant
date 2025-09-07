import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:lottie/lottie.dart';
import 'package:medicinal_plant/home_page.dart';
import 'package:medicinal_plant/plant_details_page.dart';
import 'package:medicinal_plant/utils/global_functions.dart';
import 'package:medicinal_plant/widget_tree.dart';
import 'package:just_audio/just_audio.dart';

// Professional Color Palette
class AppColors {
  static const primary = Color(0xFF2E7D32); // Deep forest green
  static const primaryVariant = Color(0xFF1B5E20);
  static const secondary = Color(0xFF4CAF50);
  static const surface = Color(0xFFFAFAFA);
  static const background = Color(0xFFFFFFFF);
  static const error = Color(0xFFE53E3E);
  static const onPrimary = Colors.white;
  static const onSurface = Color(0xFF1A1A1A);
  static const onSurfaceVariant = Color(0xFF666666);
  static const divider = Color(0xFFE0E0E0);
  static const shimmer = Color(0xFFF0F0F0);
}

// Professional Typography
class AppTypography {
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.2,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.3,
  );
  
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    letterSpacing: 0,
    height: 1.5,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    height: 1.4,
  );
}

// Professional Spacing
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with TickerProviderStateMixin {
  // Controllers & Services
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  // State Variables
  bool _speechEnabled = false;
  String _lastWords = '';
  List<String> plantDetails = [];
  List<String> searchSuggestions = [];
  bool _isTextFieldFocused = false;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _startListeningTimestamp;
  Timer? _timer;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeSpeech();
    _setupListeners();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start initial animations
    _fadeController.forward();
    _scaleController.forward();
    _slideController.forward();
  }

  void _setupListeners() {
    _searchController.addListener(_onSearchChanged);
    _focusNode.addListener(() {
      setState(() {
        _isTextFieldFocused = _focusNode.hasFocus;
        if (_isTextFieldFocused) {
          _lastWords = '';
          _errorMessage = null;
        }
      });
    });
  }

  void _initializeSpeech() async {
    setState(() {
      _speechEnabled = true; // Initialize based on your speech service
    });
  }

  void _playVoice() async {
    try {
      await _audioPlayer.setAsset('assets/Sounds/AI voice.mp3');
      _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing voice: $e');
    }
  }

  void _playSound() async {
    try {
      await _audioPlayer.setAsset('assets/Sounds/cling.wav');
      _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (_searchController.text.isNotEmpty) {
        _fetchSearchSuggestions(_searchController.text);
      } else {
        setState(() {
          searchSuggestions = [];
          _errorMessage = null;
        });
      }
    });
  }

  List<String> searchPlants(String query, List<String> plantNames) {
    if (query.isEmpty) return [];
    
    List<MapEntry<String, int>> scoredPlants = [];
    
    for (String plantName in plantNames) {
      int score = tokenSetRatio(plantName.toLowerCase(), query.toLowerCase());
      if (score >= 50) {
        scoredPlants.add(MapEntry(plantName, score));
      }
    }
    
    // Sort by score descending
    scoredPlants.sort((a, b) => b.value.compareTo(a.value));
    
    return scoredPlants.map((entry) => entry.key).take(8).toList();
  }

  Future<void> _fetchSearchSuggestions(String query) async {
    if (query.trim().isEmpty) return;
    
    try {
      setState(() {
        _errorMessage = null;
      });

      QuerySnapshot querySnapshot = await _firestore
          .collection('plant_details')
          .get()
          .timeout(const Duration(seconds: 10));
          
      List<String> suggestions = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['Common Name'] as String? ?? '').trim();
      }).where((name) => name.isNotEmpty).toList();

      setState(() {
        searchSuggestions = searchPlants(query, suggestions);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Unable to fetch suggestions. Please try again.';
        searchSuggestions = [];
      });
      debugPrint('Error fetching search suggestions: $e');
    }
  }

  Future<void> fetchPlantDetail(String plantName) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      DocumentSnapshot doc = await _firestore
          .collection('plant_details')
          .doc(plantName)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!doc.exists) {
        throw Exception('Plant not found: $plantName');
      }

      final documentData = doc.data() as Map<String, dynamic>;
      plantDetails = [
        documentData['Common Name']?.toString() ?? 'Unknown',
        documentData['Description']?.toString() ?? 'No description available',
        documentData['Scientific Name']?.toString() ?? 'Unknown',
        documentData['Family']?.toString() ?? 'Unknown'
      ];
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load plant details. Please try again.';
      });
      plantDetails = ['Error', 'Error', 'Error', 'Error'];
      debugPrint('Error fetching plant details: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildDivider(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildBackButton(),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: _buildSearchBar()),
          const SizedBox(width: AppSpacing.sm),
          _buildMicrophoneButton(),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: const Icon(
            Icons.arrow_back_ios_rounded,
            size: 20,
            color: AppColors.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isTextFieldFocused ? AppColors.primary : AppColors.divider,
            width: _isTextFieldFocused ? 2 : 1,
          ),
          boxShadow: _isTextFieldFocused
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          style: AppTypography.body1,
          decoration: InputDecoration(
            hintText: 'Search medicinal plants...',
            hintStyle: AppTypography.body1.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: _isTextFieldFocused 
                  ? AppColors.primary 
                  : AppColors.onSurfaceVariant,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _focusNode.unfocus();
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.onSurfaceVariant,
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty && searchSuggestions.isNotEmpty) {
              _handlePlantSelection(searchSuggestions.first);
            }
          },
        ),
      ),
    );
  }

  Widget _buildMicrophoneButton() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _startListening,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: _speechEnabled ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Icon(
              Icons.mic_rounded,
              size: 20,
              color: _speechEnabled ? AppColors.onPrimary : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: AppColors.divider,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (!_isTextFieldFocused && _searchController.text.isEmpty) {
      return _buildEmptyState();
    }

    if (searchSuggestions.isEmpty && _searchController.text.isNotEmpty) {
      return _buildNoResultsState();
    }

    return _buildSearchResults();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Loading plant information...',
            style: AppTypography.body1,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Oops! Something went wrong',
                style: AppTypography.heading2.copyWith(
                  color: AppColors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _errorMessage!,
                style: AppTypography.body1.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                  });
                  if (_searchController.text.isNotEmpty) {
                    _fetchSearchSuggestions(_searchController.text);
                  }
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.local_florist_rounded,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Discover Medicinal Plants',
                style: AppTypography.heading1.copyWith(
                  color: AppColors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Search for plants by name or use voice search to find detailed information about medicinal plants',
                style: AppTypography.body1.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 16,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Start typing or tap the microphone',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.onSurfaceVariant.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No plants found',
                style: AppTypography.heading2.copyWith(
                  color: AppColors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Try searching with different terms or check your spelling',
                style: AppTypography.body1.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: searchSuggestions.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: AppColors.divider,
            ),
            itemBuilder: (context, index) => _buildSearchResult(
              searchSuggestions[index],
              index,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResult(String plantName, int index) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handlePlantSelection(plantName),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.local_florist_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  plantName,
                  style: AppTypography.body1.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePlantSelection(String plantName) async {
    HapticFeedback.lightImpact();
    _focusNode.unfocus();
    
    await fetchPlantDetail(plantName);
    
    if (!mounted) return;
    
    if (_errorMessage == null && plantDetails.isNotEmpty) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              PlantDetailsPage(
            plantName: plantDetails[0],
            plantDescription: plantDetails[1],
            scientificName: plantDetails[2],
            family: plantDetails[3],
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  void _startListening() async {
    if (!_speechEnabled) return;
    
    HapticFeedback.mediumImpact();
    _playSound();
    
    // Implement your speech recognition logic here
    setState(() {
      _startListeningTimestamp = DateTime.now();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _audioPlayer.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _debounceTimer?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}