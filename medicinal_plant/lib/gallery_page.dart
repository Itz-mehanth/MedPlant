import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({Key? key}) : super(key: key);

  @override
  _GalleryPageState createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage>
    with TickerProviderStateMixin {
  List<List<dynamic>> combinedList = [];
  List<List<dynamic>> selectedCombinedList = [];
  List<String> plantNames = [];
  final ImagePicker _picker = ImagePicker();
  
  bool isLoading = true;
  bool isSelectionMode = false;
  late AnimationController _animationController;
  late AnimationController _selectionController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchImages();
    _fetchPlantNames();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _selectionController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _selectionController.dispose();
    super.dispose();
  }

  Future<void> _fetchPlantNames() async {
    try {
      final QuerySnapshot plantDocs =
          await FirebaseFirestore.instance.collection('plant_details').get();
      final List<String> names = plantDocs.docs.map((doc) => doc.id).toList();

      setState(() {
        plantNames = names;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load plant names: $e');
    }
  }

  Future<void> _fetchImages() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final List<dynamic>? images = userDoc.get('images') as List<dynamic>?;

        if (images != null) {
          setState(() {
            combinedList = images.map((image) {
              String downloadUrl = image['downloadUrl'] as String;
              GeoPoint location = image['location'] as GeoPoint;
              return [downloadUrl, [location.latitude, location.longitude]];
            }).toList();
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load images: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      isSelectionMode = !isSelectionMode;
      if (!isSelectionMode) {
        selectedCombinedList.clear();
      }
    });
  }

  void _toggleImageSelection(List<dynamic> entry) {
    setState(() {
      if (selectedCombinedList.contains(entry)) {
        selectedCombinedList.remove(entry);
      } else {
        selectedCombinedList.add(entry);
      }
      
      // Exit selection mode if no items are selected
      if (selectedCombinedList.isEmpty && isSelectionMode) {
        isSelectionMode = false;
      }
    });
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _showImageUploadDialog() async {
    if (selectedCombinedList.isEmpty) {
      _showErrorSnackBar('Please select images to upload first');
      return;
    }

    final colorScheme = Theme.of(context).colorScheme;
    Map<List<dynamic>, String?> selectedPlants = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cloud_upload_rounded,
                          color: colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Upload to Plant Database',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close_rounded,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: selectedCombinedList.length,
                      itemBuilder: (context, index) {
                        final entry = selectedCombinedList[index];
                        final imageUrl = entry[0];
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.shadow.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: colorScheme.errorContainer,
                                          child: Icon(
                                            Icons.error_rounded,
                                            color: colorScheme.onErrorContainer,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Select Plant Type',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: colorScheme.surface,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: colorScheme.outline.withOpacity(0.3),
                                          ),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            isExpanded: true,
                                            hint: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                              child: Text(
                                                'Choose plant...',
                                                style: TextStyle(
                                                  color: colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                            value: selectedPlants[entry],
                                            items: plantNames.map((name) {
                                              return DropdownMenuItem(
                                                value: name,
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                                  child: Text(
                                                    name,
                                                    style: TextStyle(
                                                      color: colorScheme.onSurface,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (value) {
                                              setDialogState(() {
                                                selectedPlants[entry] = value;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: selectedPlants[entry] != null
                                        ? colorScheme.primary
                                        : colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    onPressed: selectedPlants[entry] != null
                                        ? () => _uploadImage(entry, selectedPlants[entry])
                                        : null,
                                    icon: Icon(
                                      Icons.upload_rounded,
                                      color: selectedPlants[entry] != null
                                          ? colorScheme.onPrimary
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Upload all selected images with their plant assignments
                              for (var entry in selectedCombinedList) {
                                if (selectedPlants[entry] != null) {
                                  _uploadImage(entry, selectedPlants[entry]);
                                }
                              }
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Upload All'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _uploadImage(List<dynamic> entry, String? selectedPlantName) async {
    if (selectedPlantName == null) {
      _showErrorSnackBar('Please select a plant name for the image.');
      return;
    }

    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference storageRef = FirebaseStorage.instance
          .ref('images/$selectedPlantName/$fileName');

      final String imageUrl = entry[0];
      final List<double> loc = entry[1];
      final http.Response response = await http.get(Uri.parse(imageUrl));
      final Uint8List bytes = response.bodyBytes;

      await storageRef.putData(bytes);
      final String downloadUrl = await storageRef.getDownloadURL();

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('plant_details')
          .doc(selectedPlantName)
          .collection('images')
          .add({
        'url': downloadUrl,
        'uploadedAt': DateTime.now(),
      });

      final GeoPoint geoPoint = GeoPoint(loc[0], loc[1]);

      // Save the GeoPoint to the 'coordinates' collection
      await FirebaseFirestore.instance
          .collection('plant_details')
          .doc(selectedPlantName)
          .collection('coordinates')
          .add({
        'location': geoPoint,
        'addedAt': DateTime.now(),
      });

      _showSuccessSnackBar('Image uploaded to $selectedPlantName!');

      setState(() {
        selectedCombinedList.remove(entry);
        if (selectedCombinedList.isEmpty) {
          isSelectionMode = false;
        }
      });
    } catch (e) {
      _showErrorSnackBar('Upload failed: $e');
    }
  }

  Future<void> _deleteSelectedImages() async {
    if (selectedCombinedList.isEmpty) return;

    final colorScheme = Theme.of(context).colorScheme;
    
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Delete Images',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to delete ${selectedCombinedList.length} selected image(s)? This action cannot be undone.',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        for (List<dynamic> entry in selectedCombinedList) {
          final String imageUrl = entry[0];

          // Delete image from Firebase Storage
          try {
            final Reference ref = FirebaseStorage.instance.refFromURL(imageUrl);
            await ref.delete();
          } catch (e) {
            print('Failed to delete image from storage: $e');
          }

          // Remove the image reference from the user's collection
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'images': FieldValue.arrayRemove([
              {'downloadUrl': imageUrl, 'location': GeoPoint(entry[1][0], entry[1][1])},
            ]),
          });
        }

        setState(() {
          combinedList.removeWhere((entry) => selectedCombinedList.contains(entry));
          selectedCombinedList.clear();
          isSelectionMode = false;
        });

        _showSuccessSnackBar('${selectedCombinedList.length} image(s) deleted successfully');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to delete images: $e');
    }
  }

  void _openImage(String imageUrl, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImagePage(
          imageUrl: imageUrl,
          imageUrls: combinedList.map((e) => e[0] as String).toList(),
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(colorScheme),
          if (isLoading)
            _buildLoadingSliver(colorScheme)
          else if (combinedList.isEmpty)
            _buildEmptyStateSliver(colorScheme)
          else
            _buildImageGrid(colorScheme),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(colorScheme),
    );
  }

  Widget _buildAppBar(ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          isSelectionMode 
            ? '${selectedCombinedList.length} selected'
            : 'Gallery',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
      ),
      actions: [
        if (isSelectionMode) ...[
          if (selectedCombinedList.isNotEmpty) ...[
            IconButton(
              onPressed: _showImageUploadDialog,
              icon: Icon(
                Icons.cloud_upload_rounded,
                color: colorScheme.primary,
              ),
              tooltip: 'Upload to Database',
            ),
            IconButton(
              onPressed: _deleteSelectedImages,
              icon: Icon(
                Icons.delete_rounded,
                color: colorScheme.error,
              ),
              tooltip: 'Delete Selected',
            ),
          ],
          IconButton(
            onPressed: _toggleSelectionMode,
            icon: Icon(
              Icons.close_rounded,
              color: colorScheme.onSurface,
            ),
            tooltip: 'Exit Selection',
          ),
        ] else ...[
          if (combinedList.isNotEmpty)
            IconButton(
              onPressed: _toggleSelectionMode,
              icon: Icon(
                Icons.select_all_rounded,
                color: colorScheme.onSurface,
              ),
              tooltip: 'Select Images',
            ),
        ],
        const SizedBox(width: 8),
      ],
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
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading your gallery...',
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

  Widget _buildEmptyStateSliver(ColorScheme colorScheme) {
    return SliverFillRemaining(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Icon(
                    Icons.photo_library_rounded,
                    size: 60,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'No images yet',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your captured plant images will\nappear here once uploaded',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to camera or plant identification
                  },
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text('Capture Plants'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
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
      ),
    );
  }

  Widget _buildImageGrid(ColorScheme colorScheme) {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final entry = combinedList[index];
            final imageUrl = entry[0];
            final isSelected = selectedCombinedList.contains(entry);

            return ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildImageCard(
                  imageUrl,
                  index,
                  isSelected,
                  colorScheme,
                  entry,
                ),
              ),
            );
          },
          childCount: combinedList.length,
        ),
      ),
    );
  }

  Widget _buildImageCard(
    String imageUrl,
    int index,
    bool isSelected,
    ColorScheme colorScheme,
    List<dynamic> entry,
  ) {
    return GestureDetector(
      onTap: () {
        if (isSelectionMode) {
          _toggleImageSelection(entry);
        } else {
          _openImage(imageUrl, index);
        }
      },
      onLongPress: () {
        if (!isSelectionMode) {
          setState(() {
            isSelectionMode = true;
          });
        }
        _toggleImageSelection(entry);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                ? colorScheme.primary.withOpacity(0.3)
                : colorScheme.shadow.withOpacity(0.1),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? Border.all(
                        color: colorScheme.primary,
                        width: 3,
                      )
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: colorScheme.surfaceContainer,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.primary,
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: colorScheme.errorContainer,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_rounded,
                              color: colorScheme.onErrorContainer,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Failed to load',
                              style: TextStyle(
                                color: colorScheme.onErrorContainer,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: colorScheme.onPrimary,
                    size: 24,
                  ),
                ),
              ),
            if (isSelectionMode && !isSelected)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                ),
              ),
            // Gradient overlay for better text readability
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(ColorScheme colorScheme) {
    if (isSelectionMode && selectedCombinedList.isNotEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "upload_fab",
            onPressed: _showImageUploadDialog,
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            child: const Icon(Icons.cloud_upload_rounded),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "delete_fab",
            onPressed: _deleteSelectedImages,
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
            child: const Icon(Icons.delete_rounded),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

/// Full Screen Image Viewer with enhanced features
class FullScreenImagePage extends StatefulWidget {
  final String imageUrl;
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenImagePage({
    Key? key,
    required this.imageUrl,
    required this.imageUrls,
    required this.initialIndex,
  }) : super(key: key);

  @override
  _FullScreenImagePageState createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<FullScreenImagePage>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  int _currentIndex = 0;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleVisibility() {
    setState(() {
      _isVisible = !_isVisible;
    });
    
    if (_isVisible) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _isVisible ? _buildAppBar(colorScheme) : null,
      body: GestureDetector(
        onTap: _toggleVisibility,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: widget.imageUrls.length,
              itemBuilder: (context, index) {
                return Hero(
                  tag: 'gallery_image_$index',
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: Image.network(
                        widget.imageUrls[index],
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.primary,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_rounded,
                                  color: Colors.white,
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Failed to load image',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ColorScheme colorScheme) {
    return AppBar(
      backgroundColor: Colors.black.withOpacity(0.5),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: widget.imageUrls.length > 1
          ? Text(
              '${_currentIndex + 1} of ${widget.imageUrls.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            )
          : null,
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          onPressed: () {
            _showImageOptions(colorScheme);
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(
    ColorScheme colorScheme,
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showImageOptions(ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              _buildOptionItem(
                colorScheme,
                Icons.info_outline_rounded,
                'Image Details',
                'View metadata and information',
                () {
                  Navigator.pop(context);
                  _showImageDetails(colorScheme);
                },
              ),
              _buildOptionItem(
                colorScheme,
                Icons.share_rounded,
                'Share Image',
                'Share with others',
                () {
                  Navigator.pop(context);
                  // Implement share functionality
                },
              ),
              _buildOptionItem(
                colorScheme,
                Icons.download_rounded,
                'Save to Device',
                'Download to gallery',
                () {
                  Navigator.pop(context);
                  // Implement download functionality
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionItem(
    ColorScheme colorScheme,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageDetails(ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Image Details',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Image', '${_currentIndex + 1} of ${widget.imageUrls.length}'),
              const SizedBox(height: 8),
              _buildDetailRow('URL', widget.imageUrls[_currentIndex]),
              const SizedBox(height: 8),
              _buildDetailRow('Format', 'Network Image'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}