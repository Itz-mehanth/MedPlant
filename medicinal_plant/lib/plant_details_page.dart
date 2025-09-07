import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:medicinal_plant/map.dart';
import 'package:medicinal_plant/utils/global_functions.dart';
import 'home_page.dart';
class PlantDetailsPage extends StatefulWidget {
  final String plantName;
  final String plantDescription;
  final String scientificName;
  final String family;

  const PlantDetailsPage({
    super.key,
    required this.plantName,
    required this.plantDescription,
    required this.scientificName,
    required this.family,
  });

  @override
  _PlantDetailsPageState createState() => _PlantDetailsPageState();
}

class _PlantDetailsPageState extends State<PlantDetailsPage>
    with TickerProviderStateMixin {
  List<String> imageUrls = [];
  List<List<double>> coordinatesList = [];
  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fabAnimation;
  
  bool _isLoading = true;
  bool _hasError = false;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadPlantData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    ));

    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  Future<void> _loadPlantData() async {
    try {
      await Future.wait([
        _fetchImageUrls(),
        _fetchPlantCoordinates(),
      ]);
      
      setState(() {
        _isLoading = false;
      });
      
      // Start FAB animation after data loads
      _fabAnimationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _fetchImageUrls() async {
    try {
      final FirebaseStorage storage = FirebaseStorage.instanceFor(
        bucket: 'gs://medicinal-plant-82aa9.appspot.com',
      );

      final ListResult result = await storage
          .ref()
          .child('images')
          .child(widget.plantName)
          .listAll();

      if (result.items.isEmpty) {
        throw Exception('No images found for plant: ${widget.plantName}');
      }

      final List<String> urls = await Future.wait(
        result.items.map((file) => file.getDownloadURL()),
      );

      setState(() {
        imageUrls = urls;
      });
    } catch (e) {
      print('Error fetching image URLs: $e');
      // Set a placeholder or handle error gracefully
    }
  }

  Future<void> _fetchPlantCoordinates() async {
    try {
      final QuerySnapshot coordinatesSnapshot = await FirebaseFirestore.instance
          .collection('plant_details')
          .doc(widget.plantName)
          .collection('coordinates')
          .get();

      final List<List<double>> coordinates = [];
      for (var doc in coordinatesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final GeoPoint geoPoint = data['location'];
        coordinates.add([geoPoint.latitude, geoPoint.longitude]);
      }

      setState(() {
        coordinatesList = coordinates;
      });
    } catch (e) {
      print('Error fetching plant coordinates: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(colorScheme),
          if (_isLoading)
            _buildLoadingSliver(colorScheme)
          else if (_hasError)
            _buildErrorSliver(colorScheme)
          else
            _buildContentSliver(colorScheme),
        ],
      ),
      floatingActionButton: coordinatesList.isNotEmpty
          ? ScaleTransition(
              scale: _fabAnimation,
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapPage(coordinatesList),
                    ),
                  );
                },
                backgroundColor: AppColors.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 8,
                icon: const Icon(Icons.map_rounded),
                label: const TranslatedText('View Location'),
              ),
            )
          : null,
    );
  }

  Widget _buildAppBar(ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: imageUrls.isNotEmpty ? 400 : 200,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: colorScheme.surface.withOpacity(0.9),
      surfaceTintColor: Colors.transparent,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.surface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.favorite_border_rounded,
              color: colorScheme.onSurface,
            ),
            onPressed: () {
              // Add to favorites functionality
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: imageUrls.isNotEmpty
            ? _buildImageCarousel(colorScheme)
            : _buildPlaceholderImage(colorScheme),
      ),
    );
  }

  Widget _buildImageCarousel(ColorScheme colorScheme) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
            });
          },
          itemCount: imageUrls.length,
          itemBuilder: (context, index) {
            return Hero(
              tag: 'plant_image_$index',
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(imageUrls[index]),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (imageUrls.length > 1) ...[
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                imageUrls.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentImageIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == index
                        ? AppColors.primary
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 16,
            bottom: 0,
            child: GestureDetector(
              onTap: () {
                if (_currentImageIndex < imageUrls.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: Container(
                width: 40,
                color: Colors.transparent,
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 16,
            bottom: 0,
            child: GestureDetector(
              onTap: () {
                if (_currentImageIndex > 0) {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: Container(
                width: 40,
                color: Colors.transparent,
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlaceholderImage(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainer,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_florist_rounded,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'No images available',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSliver(ColorScheme colorScheme) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading plant details...',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorSliver(ColorScheme colorScheme) {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 80,
                color: colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Error loading plant details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please try again later',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _hasError = false;
                  });
                  _loadPlantData();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentSliver(ColorScheme colorScheme) {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPlantHeader(colorScheme),
                const SizedBox(height: 24),
                _buildPlantInfo(colorScheme),
                const SizedBox(height: 24),
                _buildPlantDetails(colorScheme),
                const SizedBox(height: 100), // Space for FAB
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlantHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TranslatedText(
                      widget.plantName,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Medicinal Plant',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.local_florist_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TranslatedText(
            widget.plantDescription,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantInfo(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            colorScheme,
            'Scientific Name',
            widget.scientificName,
            Icons.science_rounded,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoCard(
            colorScheme,
            'Family',
            widget.family,
            Icons.category_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    ColorScheme colorScheme,
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TranslatedText(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantDetails(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Plant Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow(
            colorScheme,
            'Images Available',
            '${imageUrls.length} photos',
            Icons.photo_library_rounded,
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            colorScheme,
            'Locations Found',
            coordinatesList.isNotEmpty 
              ? '${coordinatesList.length} locations'
              : 'Location data not available',
            Icons.location_on_rounded,
          ),
          if (coordinatesList.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.onSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.map_rounded,
                    color: AppColors.onSurface,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'View exact locations where this plant has been found on the map',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    ColorScheme colorScheme,
    String title,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}