import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'home_page.dart';

class AppTypography {
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
}

// Custom Map Marker Widget
class ProfessionalMapMarker extends StatefulWidget {
  final String plantName;
  final VoidCallback? onTap;
  final bool isSelected;

  const ProfessionalMapMarker({
    super.key,
    required this.plantName,
    this.onTap,
    this.isSelected = false,
  });

  @override
  State<ProfessionalMapMarker> createState() => _ProfessionalMapMarkerState();
}

class _ProfessionalMapMarkerState extends State<ProfessionalMapMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
    ));

    _animationController.forward();
    if (widget.isSelected) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ProfessionalMapMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value * (widget.isSelected ? _pulseAnimation.value : 1.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ripple effect for selected marker
                if (widget.isSelected)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                // Shadow
                Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.2),
                  ),
                ),
                // Main marker
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.accent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.onPrimary,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.local_florist_rounded,
                    color: AppColors.onPrimary,
                    size: 18,
                  ),
                ),
                // Plant name tooltip (shown when selected)
                if (widget.isSelected)
                  Positioned(
                    top: -35,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.onSurface,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.plantName,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

// Map Controls Widget
class MapControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onMyLocation;
  final VoidCallback onToggleMapType;
  final String currentMapType;

  const MapControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onMyLocation,
    required this.onToggleMapType,
    required this.currentMapType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildControlButton(
          icon: Icons.add_rounded,
          onTap: onZoomIn,
          tooltip: 'Zoom In',
        ),
        const SizedBox(height: AppSpacing.xs),
        _buildControlButton(
          icon: Icons.remove_rounded,
          onTap: onZoomOut,
          tooltip: 'Zoom Out',
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildControlButton(
          icon: Icons.my_location_rounded,
          onTap: onMyLocation,
          tooltip: 'My Location',
        ),
        const SizedBox(height: AppSpacing.xs),
        _buildControlButton(
          icon: currentMapType == 'satellite' 
              ? Icons.map_rounded 
              : Icons.satellite_alt_rounded,
          onTap: onToggleMapType,
          tooltip: 'Toggle Map Type',
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: AppColors.onSurface,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: AppColors.onSurface,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// Bottom Sheet for Plant Information
class PlantInfoBottomSheet extends StatelessWidget {
  final String plantName;
  final LatLng location;
  final VoidCallback? onViewDetails;

  const PlantInfoBottomSheet({
    super.key,
    required this.plantName,
    required this.location,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Plant info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.local_florist_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plantName,
                      style: AppTypography.heading2.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Found at this location',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Location details
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.onSurface,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Close'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.onSurfaceVariant,
                    side: BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onViewDetails?.call();
                  },
                  icon: const Icon(Icons.info_rounded),
                  label: const Text('View Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

// Main Map Page
class MapPage extends StatefulWidget {
  final List<List<double>> markers;
  final List<String>? plantNames;
  
  const MapPage(
    this.markers, {
    super.key,
    this.plantNames,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  late MapController _mapController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  String _selectedMarkerId = '';
  String _mapType = 'street';
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    // Simulate loading time for map tiles
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _fadeController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            _buildMap(),
            _buildHeader(),
            if (_isLoading) _buildLoadingOverlay(),
            _buildMapControls(),
            _buildMarkerCount(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_back_ios_rounded,
                size: 20,
                color: AppColors.onSurface,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Plant Locations',
                  style: AppTypography.heading2.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  'Discover medicinal plants near you',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialZoom: 15.0,
          initialCenter: widget.markers.isNotEmpty 
              ? LatLng(widget.markers.first[0], widget.markers.first[1])
              : const LatLng(12.751824, 80.23277),
          minZoom: 3.0,
          maxZoom: 18.0,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: _mapType == 'satellite'
                ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.medplant.flutter_map',
          ),
          MarkerLayer(
            markers: widget.markers.asMap().entries.map((entry) {
              final index = entry.key;
              final marker = entry.value;
              final markerId = 'marker_$index';
              final plantName = widget.plantNames != null && 
                  index < widget.plantNames!.length
                  ? widget.plantNames![index]
                  : 'Plant ${index + 1}';
              
              return Marker(
                point: LatLng(marker[0], marker[1]),
                width: 80,
                height: 80,
                child: ProfessionalMapMarker(
                  plantName: plantName,
                  isSelected: _selectedMarkerId == markerId,
                  onTap: () => _onMarkerTapped(markerId, plantName, LatLng(marker[0], marker[1])),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: AppColors.background,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'Loading map...',
              style: AppTypography.body1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      right: AppSpacing.md,
      bottom: AppSpacing.xl + 60, // Above marker count
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: MapControls(
          onZoomIn: () => _mapController.move(
            _mapController.camera.center,
            _mapController.camera.zoom + 1,
          ),
          onZoomOut: () => _mapController.move(
            _mapController.camera.center,
            _mapController.camera.zoom - 1,
          ),
          onMyLocation: _centerOnUserLocation,
          onToggleMapType: () {
            setState(() {
              _mapType = _mapType == 'street' ? 'satellite' : 'street';
            });
          },
          currentMapType: _mapType,
        ),
      ),
    );
  }

  Widget _buildMarkerCount() {
    return Positioned(
      right: AppSpacing.md,
      bottom: AppSpacing.md,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: AppColors.onSurface,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_florist_rounded,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${widget.markers.length} plants found',
                style: AppTypography.body2.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onMarkerTapped(String markerId, String plantName, LatLng location) {
    setState(() {
      _selectedMarkerId = _selectedMarkerId == markerId ? '' : markerId;
    });
    
    if (_selectedMarkerId == markerId) {
      _showPlantInfo(plantName, location);
    }
  }

  void _showPlantInfo(String plantName, LatLng location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlantInfoBottomSheet(
        plantName: plantName,
        location: location,
        onViewDetails: () {
          // Navigate to plant details page
          // You can implement this based on your navigation structure
        },
      ),
    );
  }

  void _centerOnUserLocation() {
    // You can implement geolocation here
    // For now, center on the first marker if available
    if (widget.markers.isNotEmpty) {
      _mapController.move(
        LatLng(widget.markers.first[0], widget.markers.first[1]),
        15.0,
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }
}