import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:medicinal_plant/home_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class PlantSubmissionPage extends StatefulWidget {
  const PlantSubmissionPage({super.key});

  @override
  _PlantSubmissionPageState createState() => _PlantSubmissionPageState();
}

class _PlantSubmissionPageState extends State<PlantSubmissionPage>
    with TickerProviderStateMixin {
  File? _selectedImage;
  String? _selectedImageBase64;
  String? _selectedPlantId;
  Position? _currentPosition;
  List<Map<String, dynamic>> _availablePlants = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _showNewPlantForm = false;

  // Controllers for new plant request
  final TextEditingController _newPlantNameController = TextEditingController();
  final TextEditingController _scientificNameController = TextEditingController();
  final TextEditingController _familyController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _additionalNotesController = TextEditingController();

  late AnimationController _animationController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAvailablePlants();
    _getCurrentLocation();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
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
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _slideController.dispose();
    _newPlantNameController.dispose();
    _scientificNameController.dispose();
    _familyController.dispose();
    _descriptionController.dispose();
    _additionalNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailablePlants() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final QuerySnapshot plantsSnapshot = await FirebaseFirestore.instance
          .collection('plant_details')
          .orderBy('Common Name')
          .get();

      final List<Map<String, dynamic>> plants = plantsSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                'name': doc['Common Name'] ?? 'Unknown',
                'scientificName': doc['Scientific Name'] ?? '',
                'family': doc['Family'] ?? '',
              })
          .toList();

      setState(() {
        _availablePlants = plants;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load plant options: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Permission.location.request();
      if (permission.isGranted) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        final Uint8List imageBytes = await imageFile.readAsBytes();
        final String base64String = base64Encode(imageBytes);

        setState(() {
          _selectedImage = imageFile;
          _selectedImageBase64 = base64String;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  void _showImagePickerDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    
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
              Text(
                'Select Image Source',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildImageSourceOption(
                      colorScheme,
                      Icons.camera_alt_rounded,
                      'Camera',
                      'Take a photo',
                      () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildImageSourceOption(
                      colorScheme,
                      Icons.photo_library_rounded,
                      'Gallery',
                      'Choose from gallery',
                      () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageSourceOption(
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
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitPlantData() async {
    if (_selectedImage == null || _selectedImageBase64 == null) {
      _showErrorSnackBar('Please select an image first');
      return;
    }

    if (_selectedPlantId == null && !_showNewPlantForm) {
      _showErrorSnackBar('Please select a plant or request a new one');
      return;
    }

    if (_showNewPlantForm && _newPlantNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a plant name');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          _showErrorSnackBar('Please log in to submit plant data');
        }
        return;
      }

      final Map<String, dynamic> submissionData = {
        'userId': user.uid,
        'userEmail': user.email,
        'imageBase64': _selectedImageBase64,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      };

      if (_currentPosition != null) {
        submissionData['location'] = GeoPoint(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
      }

      if (_selectedPlantId != null) {
        // Existing plant submission
        submissionData['plantId'] = _selectedPlantId;
        submissionData['type'] = 'existing_plant';
        
        await FirebaseFirestore.instance
            .collection('plant_submissions')
            .add(submissionData);
        
        if (mounted) {
          _showSuccessSnackBar('Plant submission sent for review!');
          _resetForm();
        }
      } else {
        // New plant request
        submissionData.addAll({
          'type': 'new_plant_request',
          'plantName': _newPlantNameController.text.trim(),
          'scientificName': _scientificNameController.text.trim(),
          'family': _familyController.text.trim(),
          'description': _descriptionController.text.trim(),
          'additionalNotes': _additionalNotesController.text.trim(),
        });
        
        await FirebaseFirestore.instance
            .collection('plant_submissions')
            .add(submissionData);
        
        // Send email notification
        await _sendNewPlantRequestEmail();
        
        if (mounted) {
          _showSuccessSnackBar('New plant request submitted successfully!');
          _resetForm();
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to submit: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _sendNewPlantRequestEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'mehanth362@gmail.com',
      query: Uri.encodeQueryComponent(
        'subject=New Plant Addition Request&body=A new plant has been requested for addition to the database.\n\nPlant Name: ${_newPlantNameController.text}\nScientific Name: ${_scientificNameController.text}\nFamily: ${_familyController.text}\n\nPlease review the submission in the admin panel.',
      ),
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      }
    } catch (e) {
      print('Could not send email: $e');
    }
  }

  void _resetForm() {
    setState(() {
      _selectedImage = null;
      _selectedImageBase64 = null;
      _selectedPlantId = null;
      _showNewPlantForm = false;
    });
    
    _newPlantNameController.clear();
    _scientificNameController.clear();
    _familyController.clear();
    _descriptionController.clear();
    _additionalNotesController.clear();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
      ),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(colorScheme),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImageSection(colorScheme),
                      const SizedBox(height: 24),
                      _buildPlantSelectionSection(colorScheme),
                      if (_showNewPlantForm) ...[
                        const SizedBox(height: 24),
                        _buildNewPlantForm(colorScheme),
                      ],
                      const SizedBox(height: 32),
                      _buildSubmitButton(colorScheme),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
          'Submit Plant Data',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: colorScheme.onSurface,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildImageSection(ColorScheme colorScheme) {
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
              Icon(
                Icons.camera_alt_rounded,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Plant Image',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (_selectedImage != null) ...[
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showImagePickerDialog,
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Change Image'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                        _selectedImageBase64 = null;
                      });
                    },
                    icon: const Icon(Icons.delete_rounded),
                    label: const Text('Remove'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            GestureDetector(
              onTap: _showImagePickerDialog,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.3),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(
                        Icons.add_a_photo_rounded,
                        color: AppColors.primary,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tap to add plant image',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Take a photo or choose from gallery',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlantSelectionSection(ColorScheme colorScheme) {
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
              Icon(
                Icons.local_florist_rounded,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Plant Selection',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (_isLoading) ...[
            const Center(child: CircularProgressIndicator()),
          ] else ...[
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
                  hint: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Select existing plant...',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  value: _selectedPlantId,
                  items: _availablePlants.map<DropdownMenuItem<String>>((plant) {
                    return DropdownMenuItem<String>(
                      value: plant['id'] as String,
                      child: SizedBox(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              plant['name'],
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (plant['scientificName'].isNotEmpty)
                              Text(
                                plant['scientificName'],
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPlantId = value;
                      if (value != null) {
                        _showNewPlantForm = false;
                      }
                    });
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Divider(color: colorScheme.outline.withOpacity(0.3)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(color: colorScheme.outline.withOpacity(0.3)),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showNewPlantForm = !_showNewPlantForm;
                  if (_showNewPlantForm) {
                    _selectedPlantId = null;
                  }
                });
              },
              icon: Icon(
                _showNewPlantForm ? Icons.close_rounded : Icons.add_rounded,
              ),
              label: Text(
                _showNewPlantForm 
                  ? 'Cancel New Plant Request'
                  : 'Request New Plant Addition',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _showNewPlantForm 
                  ? colorScheme.surfaceContainerHighest
                  : AppColors.primary,
                foregroundColor: _showNewPlantForm 
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 0),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNewPlantForm(ColorScheme colorScheme) {
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
              Icon(
                Icons.eco_rounded,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'New Plant Request',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildTextField(
            controller: _newPlantNameController,
            label: 'Plant Name *',
            hint: 'Enter common name of the plant',
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _scientificNameController,
            label: 'Scientific Name',
            hint: 'Enter scientific name (optional)',
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _familyController,
            label: 'Family',
            hint: 'Enter plant family (optional)',
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _descriptionController,
            label: 'Description',
            hint: 'Describe the plant and its properties',
            maxLines: 3,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _additionalNotesController,
            label: 'Additional Notes',
            hint: 'Any additional information',
            maxLines: 2,
            colorScheme: colorScheme,
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.onPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your request will be reviewed and you\'ll be notified once approved.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required ColorScheme colorScheme,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        floatingLabelStyle:
                const TextStyle(color: AppColors.primary, fontSize: 12),
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      style: TextStyle(color: colorScheme.onSurface),
    );
  }

  Widget _buildSubmitButton(ColorScheme colorScheme) {
    final bool canSubmit = _selectedImage != null && 
                          (_selectedPlantId != null || 
                           (_showNewPlantForm && _newPlantNameController.text.isNotEmpty));
    
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canSubmit && !_isSubmitting ? _submitPlantData : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
        ),
        child: _isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Submitting...'),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_rounded,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _showNewPlantForm ? 'Submit New Plant Request' : 'Submit Plant Data',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// Home Page Integration - Add this method to your HomePage class
class PlantSubmissionsWidget extends StatelessWidget {
  const PlantSubmissionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
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
              Icon(
                Icons.eco_rounded,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Community Submissions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('plant_submissions')
                .where('status', isEqualTo: 'approved')
                .orderBy('timestamp', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Text(
                  'No approved submissions yet',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                  ),
                );
              }
              
              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final imageBase64 = data['imageBase64'] as String?;
                  final plantName = data['plantName'] ?? 'Unknown Plant';
                  final userEmail = data['userEmail'] ?? 'Anonymous';
                  final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: colorScheme.surfaceContainerHighest,
                          ),
                          child: imageBase64 != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    base64Decode(imageBase64),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.local_florist_rounded,
                                        color: colorScheme.onSurfaceVariant,
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  Icons.local_florist_rounded,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plantName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Submitted by ${userEmail.split('@')[0]}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (timestamp != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _formatTimestamp(timestamp),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PlantSubmissionPage(),
                  ),
                );
              },
              icon: const Icon(Icons.add_a_photo_rounded),
              label: const Text('Submit Your Plant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

// Admin Panel for reviewing submissions (optional)
class AdminSubmissionsPage extends StatelessWidget {
  const AdminSubmissionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Review Submissions'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('plant_submissions')
            .where('status', isEqualTo: 'pending')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No pending submissions'),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              return _buildSubmissionCard(context, doc.id, data, colorScheme);
            },
          );
        },
      ),
    );
  }
  
  Widget _buildSubmissionCard(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
    ColorScheme colorScheme,
  ) {
    final imageBase64 = data['imageBase64'] as String?;
    final isNewPlant = data['type'] == 'new_plant_request';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
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
              Icon(
                isNewPlant ? Icons.eco_rounded : Icons.local_florist_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                isNewPlant ? 'New Plant Request' : 'Plant Submission',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (imageBase64 != null) ...[
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  base64Decode(imageBase64),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          if (isNewPlant) ...[
            _buildInfoRow('Plant Name', data['plantName'] ?? 'N/A', colorScheme),
            _buildInfoRow('Scientific Name', data['scientificName'] ?? 'N/A', colorScheme),
            _buildInfoRow('Family', data['family'] ?? 'N/A', colorScheme),
            _buildInfoRow('Description', data['description'] ?? 'N/A', colorScheme),
          ] else ...[
            _buildInfoRow('Plant ID', data['plantId'] ?? 'N/A', colorScheme),
          ],
          
          _buildInfoRow('Submitted by', data['userEmail'] ?? 'N/A', colorScheme),
          
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _updateSubmissionStatus(docId, 'rejected'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    side: BorderSide(color: colorScheme.error),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _updateSubmissionStatus(docId, 'approved'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _updateSubmissionStatus(String docId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('plant_submissions')
          .doc(docId)
          .update({
        'status': status,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating submission status: $e');
    }
  }
}