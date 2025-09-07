// ignore_for_file: non_constant_identifier_names
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medicinal_plant/AyurvedaNewsWidget.dart';
import 'package:medicinal_plant/genAI.dart';
import 'package:medicinal_plant/main.dart';
import 'package:medicinal_plant/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medicinal_plant/auth.dart';
import 'package:medicinal_plant/login_register_page.dart';
import 'package:medicinal_plant/plant_details_page.dart';
import 'package:medicinal_plant/search_page.dart';
import 'package:medicinal_plant/utils/global_functions.dart';
import 'package:medicinal_plant/plant_details_initializer.dart';
import 'dart:math' as math;

// Professional Design System
class AppColors {
  static const primary = Color(0xFF2E7D32);
  static const primaryVariant = Color(0xFF1B5E20);
  static const secondary = AppColors.primary;
  static const accent = Color(0xFF66BB6A);
  static const surface = Color(0xFFFAFAFA);
  static const background = Color(0xFFFFFFFF);
  static const error = Color(0xFFE53E3E);
  static const warning = Color(0xFFFF9800);
  static const success = AppColors.primary;
  static const onPrimary = Colors.white;
  static const onSurface = Color(0xFF1A1A1A);
  static const onSurfaceVariant = Color(0xFF666666);
  static const divider = Color(0xFFE0E0E0);
  static const shimmer = Color(0xFFF0F0F0);
  static const favorite = Color(0xFFFFC107);
}

class AppTypography {
  static const TextStyle brandTitle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
    height: 1.1,
    fontFamily: 'KOULEN',
  );

  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static const TextStyle body1 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    letterSpacing: 0,
    height: 1.5,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    height: 1.4,
  );
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

// Global Functions for Compatibility
void showLoginPrompt(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.login_rounded,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.sm),
          const Text(
            'Login Required',
            style: AppTypography.heading2,
          ),
        ],
      ),
      content: const Text(
        'Please login to add plants to your favorites.',
        style: AppTypography.body1,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const TranslatedText('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/login');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const TranslatedText('Login'),
        ),
      ],
    ),
  );
}

void showErrorDialog(String errorMessage) {
  final context = MyApp().navigatorKey.currentContext;
  if (context != null) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'Error',
                style: AppTypography.heading2,
              ),
            ],
          ),
          content: Text(
            errorMessage,
            style: AppTypography.body1,
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

// Professional Search Bar Component
class ProfessionalSearchBar extends StatefulWidget {
  final VoidCallback onTap;
  final String hintText;

  const ProfessionalSearchBar({
    super.key,
    required this.onTap,
    this.hintText = 'Search medicinal plants...',
  });

  @override
  State<ProfessionalSearchBar> createState() => _ProfessionalSearchBarState();
}

class _ProfessionalSearchBarState extends State<ProfessionalSearchBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTapDown: (_) => _animationController.forward(),
        onTapUp: (_) => _animationController.reverse(),
        onTapCancel: () => _animationController.reverse(),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            height: 48,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: AppColors.onPrimary,
                    size: 20,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text(
                      widget.hintText,
                      style: AppTypography.body1.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: AppSpacing.md),
                  child: Icon(
                    Icons.mic_rounded,
                    color: AppColors.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

// Professional Tab Button Component
class ProfessionalTabButton extends StatefulWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const ProfessionalTabButton({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  State<ProfessionalTabButton> createState() => _ProfessionalTabButtonState();
}

class _ProfessionalTabButtonState extends State<ProfessionalTabButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.isSelected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 16,
                  color: widget.isSelected
                      ? AppColors.onPrimary
                      : AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                widget.title,
                style: AppTypography.body2.copyWith(
                  color: widget.isSelected
                      ? AppColors.onPrimary
                      : AppColors.onSurfaceVariant,
                  fontWeight:
                      widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

// Professional Plant Card Component
class ProfessionalPlantCard extends StatefulWidget {
  final String plantName;
  final String plantDescription;
  final String scientificName;
  final String family;
  final Future<String> imageUrl;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onTap;

  const ProfessionalPlantCard({
    super.key,
    required this.plantName,
    required this.plantDescription,
    required this.scientificName,
    required this.family,
    required this.imageUrl,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.onTap,
  });

  @override
  State<ProfessionalPlantCard> createState() => _ProfessionalPlantCardState();
}

class _ProfessionalPlantCardState extends State<ProfessionalPlantCard>
    with TickerProviderStateMixin {
  late AnimationController _heartController;
  late AnimationController _scaleController;
  late Animation<double> _heartAnimation;
  late Animation<double> _scaleAnimation;

  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;

    _heartController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _heartAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _heartController,
      curve: Curves.elasticOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    if (_isFavorite) {
      _heartController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final truncatedDescription = widget.plantDescription.length > 120
        ? '${widget.plantDescription.substring(0, 120)}... Read more'
        : widget.plantDescription;

    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.sm),
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
            child: Row(
              children: [
                _buildImageSection(),
                Expanded(child: _buildContentSection(truncatedDescription)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return SizedBox(
      width: 140,
      height: 160,
      child: Stack(
        children: [
          FutureBuilder<String>(
            future: widget.imageUrl,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildShimmerPlaceholder();
              } else if (snapshot.hasError || !snapshot.hasData) {
                return _buildErrorPlaceholder();
              } else {
                return _buildImage(snapshot.data!);
              }
            },
          ),
          _buildFavoriteButton(),
        ],
      ),
    );
  }

  Widget _buildShimmerPlaceholder() {
    return Container(
      width: 140,
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.shimmer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: 140,
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_florist_rounded,
            size: 32,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'No Image',
            style: AppTypography.caption.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: 140,
      height: 160,
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildShimmerPlaceholder(),
      errorWidget: (context, url, error) => _buildErrorPlaceholder(),
      imageBuilder: (context, imageProvider) => Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
          image: DecorationImage(
            image: imageProvider,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return Positioned(
      top: AppSpacing.sm,
      left: AppSpacing.sm,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          setState(() {
            _isFavorite = !_isFavorite;
          });

          if (_isFavorite) {
            _heartController.forward();
          } else {
            _heartController.reverse();
          }

          widget.onFavoriteToggle?.call();
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ScaleTransition(
            scale: _heartAnimation,
            child: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color:
                  _isFavorite ? AppColors.favorite : AppColors.onSurfaceVariant,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentSection(String truncatedDescription) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TranslatedText(widget.plantName,
              style: AppTypography.heading2.copyWith(
                color: AppColors.onSurface,
              )),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: TranslatedText(truncatedDescription,
                style: AppTypography.body2.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.4,
                )),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildScientificNameSection(),
        ],
      ),
    );
  }

  Widget _buildScientificNameSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.science_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TranslatedText(
                  'Scientific Name',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TranslatedText(widget.scientificName,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.onSurface,
                      fontStyle: FontStyle.italic,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _heartController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
}

// Professional FAB Component
class ProfessionalFloatingActionButton extends StatefulWidget {
  final VoidCallback onPressed;

  const ProfessionalFloatingActionButton({
    super.key,
    required this.onPressed,
  });

  @override
  State<ProfessionalFloatingActionButton> createState() =>
      _ProfessionalFloatingActionButtonState();
}

class _ProfessionalFloatingActionButtonState
    extends State<ProfessionalFloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onPressed();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: RotationTransition(
          turns: _rotationAnimation,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: AppColors.onPrimary,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

// Backward Compatible PlantBoxWidget
class PlantBoxWidget extends StatefulWidget {
  final String plantName;
  final String plantDescription;
  final String scientificName;
  final String family;
  final Future<String> imageUrl;
  bool isFav;

  PlantBoxWidget({
    super.key,
    required this.plantName,
    required this.plantDescription,
    required this.scientificName,
    required this.family,
    required this.imageUrl,
    this.isFav = false,
  });

  @override
  State<PlantBoxWidget> createState() => _PlantBoxWidgetState();
}

class _PlantBoxWidgetState extends State<PlantBoxWidget> {
  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      if (FirebaseAuth.instance.currentUser != null) {
        final userId = FirebaseAuth.instance.currentUser!.uid;
        DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (documentSnapshot.exists) {
          final favorites = documentSnapshot.get('favorites') as List<dynamic>;
          if (mounted) {
            setState(() {
              widget.isFav = favorites.contains(widget.plantName);
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking favorite status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfessionalPlantCard(
      plantName: widget.plantName,
      plantDescription: widget.plantDescription,
      scientificName: widget.scientificName,
      family: widget.family,
      imageUrl: widget.imageUrl,
      isFavorite: widget.isFav,
      onFavoriteToggle: () => _toggleFavorite(),
      onTap: () => _navigateToDetails(),
    );
  }

  void _toggleFavorite() async {
    if (FirebaseAuth.instance.currentUser == null) {
      showLoginPrompt(context);
      return;
    }

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final favorites = FirebaseFirestore.instance.collection('users');

      if (widget.isFav) {
        await favorites.doc(userId).update({
          'favorites': FieldValue.arrayRemove([widget.plantName])
        });
      } else {
        await favorites.doc(userId).update({
          'favorites': FieldValue.arrayUnion([widget.plantName])
        });
      }

      if (mounted) {
        setState(() {
          widget.isFav = !widget.isFav;
        });
      }
    } catch (e) {
      showErrorDialog('Failed to update favorites. Please try again.');
      debugPrint('Error toggling favorite: $e');
    }
  }

  void _navigateToDetails() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PlantDetailsPage(
          plantName: widget.plantName,
          plantDescription: widget.plantDescription,
          scientificName: widget.scientificName,
          family: widget.family,
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

// Backward Compatible PlantSearchBar
class PlantSearchBar extends StatefulWidget {
  final bool isEnabled;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;

  const PlantSearchBar({
    super.key,
    required this.isEnabled,
    required this.searchController,
    required this.searchFocusNode,
  });

  @override
  State<PlantSearchBar> createState() => _PlantSearchBarState();
}

class _PlantSearchBarState extends State<PlantSearchBar> {
  late final Future<String> _hintTextFuture;

  @override
  void initState() {
    super.initState();
    _hintTextFuture = translate('Search plants');
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEnabled) {
      return ProfessionalSearchBar(
        onTap: () => Navigator.pushNamed(context, '/search'),
        hintText: 'Search plants...',
      );
    }

    return FutureBuilder<String>(
      future: _hintTextFuture,
      builder: (context, snapshot) {
        return Container(
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.searchFocusNode.hasFocus
                  ? AppColors.primary
                  : AppColors.divider,
              width: widget.searchFocusNode.hasFocus ? 2 : 1,
            ),
            boxShadow: widget.searchFocusNode.hasFocus
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: AppColors.onPrimary,
                  size: 20,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: widget.searchController,
                  focusNode: widget.searchFocusNode,
                  enabled: widget.isEnabled,
                  style: AppTypography.body1,
                  decoration: InputDecoration(
                    hintText: snapshot.data ?? 'Search plants...',
                    hintStyle: AppTypography.body1.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    suffixIcon: widget.searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              widget.searchController.clear();
                              widget.searchFocusNode.unfocus();
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.onSurfaceVariant,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Global plantWidgets list for compatibility
List<PlantBoxWidget> plantWidgets = [];

// Main WelcomeScreen
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _allTabSelected = true;
  bool _gardenTabSelected = false;
  bool _plantTabSelected = false;
  final TextEditingController _searchController = TextEditingController();
  final User? user = Auth().currentUser;
  bool isFav = false;
  late AnimationController controller;
  late Animation<Color?> colorAnimation;
  late Animation<double> sizeAnimation;
  bool onHomePage = false;
  bool onProfilePage = false;
  bool onSearch = false;
  bool onCamera = false;
  double itemWidth = 350;
  double itemHeight = 140;
  double aspectRatio = 350 / 140;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _getUserLanguage();

    controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          isFav = true;
        });
      }
      if (status == AnimationStatus.dismissed) {
        isFav = false;
      }
    });

    colorAnimation = ColorTween(
      begin: Colors.black54,
      end: const Color.fromARGB(255, 255, 191, 0),
    ).animate(controller);

    sizeAnimation = TweenSequence(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.0, end: 0.7), weight: 50),
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.7, end: 1), weight: 50),
    ]).animate(controller);
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  Future<String> fetchRandomImageUrl(String plantName) async {
    try {
      final FirebaseStorage storage = FirebaseStorage.instanceFor(
        bucket: 'gs://medicinal-plant-82aa9.appspot.com',
      );

      final ListResult result =
          await storage.ref().child('images').child(plantName).listAll();
      final List<Reference> allFiles = result.items;

      if (allFiles.isEmpty) {
        return 'https://static.vecteezy.com/system/resources/previews/004/141/669/original/no-photo-or-blank-image-icon-loading-images-or-missing-image-mark-image-not-available-or-image-coming-soon-sign-simple-nature-silhouette-in-frame-isolated-illustration-vector.jpg';
      }

      final int randomIndex = DateTime.now().millisecond % allFiles.length;
      final Reference randomFile = allFiles[randomIndex];
      final String downloadUrl = await randomFile.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error fetching image URL: $e');
      return 'https://static.vecteezy.com/system/resources/previews/004/141/669/original/no-photo-or-blank-image-icon-loading-images-or-missing-image-mark-image-not-available-or-image-coming-soon-sign-simple-nature-silhouette-in-frame-isolated-illustration-vector.jpg';
    }
  }

  Future<void> _updateUserLanguage(String language) async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'language': language,
      });
    } catch (e) {
      debugPrint('Error updating user language: $e');
    }
  }

  Future<void> _getUserLanguage() async {
    try {
      if (FirebaseAuth.instance.currentUser != null) {
        final userId = FirebaseAuth.instance.currentUser!.uid;
        DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore
            .instance
            .collection('users')
            .doc(userId)
            .get();

        if (doc.exists) {
          final documentData = doc.data() as Map<String, dynamic>;
          setState(() {
            currentLocale = documentData["language"] ?? 'en';
          });
        }
      }
    } catch (e) {
      setState(() {
        currentLocale = 'en';
      });
      debugPrint('Error getting user language: $e');
    }
  }

  Future<List<String>> fetchPlantNames() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('plant_details').get();
      List<String> plantNames = querySnapshot.docs.map((doc) {
        final documentData = doc.data() as Map<String, dynamic>;
        return documentData['Common Name'] as String? ?? 'Unknown';
      }).toList();

      return plantNames;
    } catch (e) {
      debugPrint('Error fetching plant names: $e');
      return [];
    }
  }

  Future<void> fetchAndSetPlantWidgets() async {
    List<String> plantNames = await fetchPlantNames();

    for (String plantName in plantNames) {
      PlantBoxWidget? widget = await fetchPlantWidget(plantName);
      if (widget != null) {
        setState(() {
          plantWidgets.add(widget);
        });
      }
    }
  }

  Future<List<PlantBoxWidget>> fetchPlantWidgets(
      List<String> plantNames) async {
    List<PlantBoxWidget> plantWidgets = [];

    for (String plantName in plantNames) {
      PlantBoxWidget? widget = await fetchPlantWidget(plantName);
      if (widget != null) {
        plantWidgets.add(widget);
      }
    }

    return plantWidgets;
  }

  Future<PlantBoxWidget?> fetchPlantWidget(String plantNameInput) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('plant_details')
          .where('Common Name', isEqualTo: plantNameInput)
          .get();
      List<QueryDocumentSnapshot> docs = querySnapshot.docs;

      if (docs.isNotEmpty) {
        final documentData = docs.first.data() as Map<String, dynamic>;
        String plantName = documentData['Common Name'];
        String plantDescription = documentData['Description'];
        String scientificName = documentData['Scientific Name'];
        String family = documentData['Family'];
        return PlantBoxWidget(
          plantName: plantName,
          plantDescription: plantDescription.replaceAll('-', ','),
          scientificName: scientificName,
          family: family,
          imageUrl: fetchRandomImageUrl(plantName),
        );
      } else {
        return PlantBoxWidget(
          plantName: 'Document not found',
          plantDescription: 'Document not found',
          scientificName: 'Document not found',
          family: 'Document not found',
          imageUrl: Future.value(''),
        );
      }
    } catch (e) {
      debugPrint('Error fetching plant details: $e');
      return null;
    }
  }

  Future<void> signout(BuildContext context) async {
    await Auth().signOut();
    Navigator.pushNamed(context, '/login');
  }

  Widget TopNavButton(String name, bool isSelected) {
    return Container(
      width: 70,
      height: 30,
      alignment: Alignment.center,
      margin: const EdgeInsets.only(left: 10),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        color: isSelected
            ? AppColors.primary
            : const Color.fromARGB(255, 255, 255, 255),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.black26,
        ),
      ),
      child: TranslatedText(
        name,
        style: TextStyle(
          fontSize: 10,
          color: isSelected
              ? const Color.fromARGB(255, 255, 255, 255)
              : Colors.black26,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plantWidgets = ref.watch(plantWidgetsProvider);
    List<PlantBoxWidget> filteredWidgets = _gardenTabSelected
        ? plantWidgets.where((widget) => widget.isFav).toList()
        : plantWidgets;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildHeader(), // stays fixed
              // Everything below here scrolls together
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const AyurvedaNewsWidget(),
                      _buildTabBar(),
                      _buildDivider(),
                      _buildContent(
                          filteredWidgets), // No Expanded inside here!
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            backgroundColor: Colors.white,
            heroTag: "btn1",
            onPressed: () => _navigateToAI(),
            child: const Icon(
              Icons.smart_toy,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            backgroundColor: Colors.white,
            heroTag: "btn2",
            onPressed: () => Navigator.pushNamed(context, '/camera'),
            child: const Icon(
              Icons.camera_alt_rounded,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            _buildBrandSection(),
            const SizedBox(height: AppSpacing.lg),
            _buildProfileSection(),
            const SizedBox(height: AppSpacing.lg),
            _buildSearchSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    final user = FirebaseAuth.instance.currentUser;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/profile'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Profile Picture
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(23),
                child: user?.photoURL != null
                    ? CachedNetworkImage(
                        imageUrl: user!.photoURL!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: const Color(0xFFE8F5E8),
                          child: const Icon(
                            Icons.person_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: const Color(0xFFE8F5E8),
                          child: const Icon(
                            Icons.person_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                      )
                    : Container(
                        color: const Color(0xFFE8F5E8),
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? 'Guest User',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C2C2C),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'View Profile',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Arrow Icon
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  // Alternative compact version if you prefer just the profile picture
  Widget _buildCompactProfileSection() {
    final user = FirebaseAuth.instance.currentUser;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/profile'),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: AppColors.primary,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(27),
          child: user?.photoURL != null
              ? CachedNetworkImage(
                  imageUrl: user!.photoURL!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: const Color(0xFFE8F5E8),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: const Color(0xFFE8F5E8),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                )
              : Container(
                  color: const Color(0xFFE8F5E8),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildBrandSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildPlantIcon('assets/pot1.png'),
        const SizedBox(width: AppSpacing.md),
        Column(
          children: [
            Text(
              'MEDPLANT',
              style: AppTypography.brandTitle.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            Container(
              height: 3,
              width: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        _buildPlantIcon('assets/pot2.png'),
      ],
    );
  }

  Widget _buildPlantIcon(String assetPath) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Image.asset(
        assetPath,
        height: 48,
        width: 36,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.local_florist_rounded,
          size: 48,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return PlantSearchBar(
      isEnabled: false,
      searchController: _searchController,
      searchFocusNode: FocusNode(),
    );
  }

  Widget _buildTabBar() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: [
            ProfessionalTabButton(
              title: 'All',
              icon: Icons.grid_view_rounded,
              isSelected: _allTabSelected,
              onTap: () => _selectTab(true),
            ),
            const SizedBox(width: AppSpacing.md),
            ProfessionalTabButton(
              title: 'Garden',
              icon: Icons.favorite_rounded,
              isSelected: _gardenTabSelected,
              onTap: () => _selectTab(false),
            ),
            const SizedBox(width: AppSpacing.md),
            ProfessionalTabButton(
                title: 'Add Plant',
                icon: Icons.favorite_rounded,
                isSelected: _plantTabSelected,
                onTap: () {
                  _plantTabSelected = true;
                  Navigator.pushNamed(context, '/submission');
                }),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      color: AppColors.divider,
    );
  }

  Widget _buildContent(List<PlantBoxWidget> widgets) {
    if (widgets.length < 10) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: PlaceholderRedacted(),
      );
    }

    if (_gardenTabSelected && FirebaseAuth.instance.currentUser == null) {
      return _buildAuthRequiredState();
    }

    List<PlantBoxWidget> displayWidgets = widgets;
    if (_gardenTabSelected) {
      displayWidgets = widgets.where((widget) => widget.isFav).toList();
    }

    if (displayWidgets.isEmpty && _gardenTabSelected) {
      return _buildEmptyGardenState();
    }

    return _buildPlantGrid(displayWidgets);
  }

  Widget _buildAuthRequiredState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
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
                Icons.login_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Login Required',
              style: AppTypography.heading1.copyWith(
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Sign in to create your personal garden of favorite medicinal plants',
              style: AppTypography.body1.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              icon: const Icon(Icons.login_rounded),
              label: const Text('Sign In'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyGardenState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.favorite.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.favorite_outline_rounded,
                size: 64,
                color: AppColors.favorite,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Your Garden is Empty',
              style: AppTypography.heading1.copyWith(
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Start adding plants to your favorites by tapping the heart icon on plant cards',
              style: AppTypography.body1.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: () => _selectTab(true),
              icon: const Icon(Icons.explore_rounded),
              label: const Text('Explore Plants'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantGrid(List<PlantBoxWidget> widgets) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double itemWidth = 350;
          double itemHeight = 140;
          double aspectRatio = itemWidth / itemHeight;

          // Prevent division by zero or negative/zero width
          if (constraints.maxWidth <= 0) {
            return const SizedBox.shrink();
          }

          int columnCount = math.max(1, (constraints.maxWidth / itemWidth).floor());

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.sm),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columnCount,
              childAspectRatio: aspectRatio,
            ),
            itemCount: widgets.length,
            itemBuilder: (context, index) {
              return widgets[index];
            },
          );
        },
      ),
    );
  }

  void _selectTab(bool isAllTab) {
    HapticFeedback.selectionClick();
    setState(() {
      _allTabSelected = isAllTab;
      _gardenTabSelected = !isAllTab;
      _plantTabSelected = false;
    });
  }

  void _navigateToAI() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ChatBotPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 0.8,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    controller.dispose();
    super.dispose();
    ref.invalidate(plantWidgetsProvider);
  }
}
