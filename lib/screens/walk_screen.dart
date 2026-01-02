import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/theme_data.dart';
import '../providers/walk_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/pet_provider.dart';
import '../providers/social_provider.dart';
import '../services/storage_service.dart';
import '../models/pet_model.dart';
import 'walk_end_dialog.dart';
import 'pet_select_dialog.dart';

/// Walk Screen with OSM Map Tracking
class WalkScreen extends StatefulWidget {
  const WalkScreen({super.key});

  @override
  State<WalkScreen> createState() => _WalkScreenState();
}

class _WalkScreenState extends State<WalkScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;
  Position? _currentPosition;
  bool _isFollowingLocation = true;
  final ImagePicker _imagePicker = ImagePicker();
  final StorageService _storageService = FirebaseStorageService();

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  /// Request location permission
  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      _startLocationTracking();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('위치 권한이 필요합니다.'),
          ),
        );
      }
    }
  }

  /// Start location tracking
  void _startLocationTracking() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // 5 meters
      ),
    ).listen((Position position) {
      setState(() {
        _currentPosition = position;
        final latLng = LatLng(position.latitude, position.longitude);
        
        // Add route point to provider
        final walkProvider = Provider.of<WalkProvider>(context, listen: false);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final socialProvider = Provider.of<SocialProvider>(context, listen: false);
        
        walkProvider.addRoutePoint(position.latitude, position.longitude);
        
        // Update user location for nearby users feature
        if (authProvider.user != null && authProvider.user!.isLocationPublic) {
          socialProvider.updateUserLocation(
            authProvider.user!.uid,
            position.latitude,
            position.longitude,
          );
        }
        
        // Auto-center map if following location
        if (_isFollowingLocation) {
          _mapController.move(latLng, _mapController.camera.zoom);
        }
      });
    });
  }

  /// Get current location
  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        if (_isFollowingLocation) {
          _mapController.move(
            LatLng(position.latitude, position.longitude),
            _mapController.camera.zoom,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('위치를 가져올 수 없습니다: $e')),
        );
      }
    }
  }

  /// Start walk
  Future<void> _startWalk() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final walkProvider = Provider.of<WalkProvider>(context, listen: false);
    final petProvider = Provider.of<PetProvider>(context, listen: false);
    
    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    // 반려동물 목록 로드
    await petProvider.loadPets(authProvider.user!.uid);
    
    if (!mounted) return;
    
    // 반려동물 선택 다이얼로그 표시
    final selectedPet = await showDialog<PetModel?>(
      context: context,
      builder: (context) => const PetSelectDialog(),
    );
    
    if (!mounted) return;

    // Get current location first
    await _getCurrentLocation();
    
    if (!mounted) return;
    
    if (_currentPosition != null) {
      final success = await walkProvider.startWalk(
        authProvider.user!.uid,
        petId: selectedPet?.petId,
      );
      if (success && mounted) {
        setState(() {
          _isFollowingLocation = true;
        });
        // Center map on current location
        _mapController.move(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          16.0,
        );
      }
    }
  }

  /// End walk
  Future<void> _endWalk() async {
    final walkProvider = Provider.of<WalkProvider>(context, listen: false);
    
    if (!walkProvider.isWalking || walkProvider.currentWalk == null) return;
    
    final distance = walkProvider.currentWalk!.distance ?? 0.0;
    final duration = walkProvider.elapsedSeconds;
    
    // 산책 종료 다이얼로그 표시
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => WalkEndDialog(
        duration: duration,
        distance: distance,
      ),
    );
    
    if (result != null && mounted) {
      final success = await walkProvider.endWalk(
        memo: result['memo'],
        mood: result['mood'],
        isPublic: true,
      );
      
      if (success && mounted) {
        setState(() {
          _isFollowingLocation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('산책이 종료되었습니다.')),
        );
      }
    }
  }

  /// Cancel walk
  Future<void> _cancelWalk() async {
    final walkProvider = Provider.of<WalkProvider>(context, listen: false);
    await walkProvider.cancelWalk();
    setState(() {
      _isFollowingLocation = false;
    });
  }

  /// Take photo during walk
  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null && mounted) {
        final walkProvider = Provider.of<WalkProvider>(context, listen: false);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        if (walkProvider.currentWalk == null || authProvider.user == null) return;
        
        // Show loading
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('사진을 업로드하는 중...')),
          );
        }
        
        try {
          // Upload photo
          final photoUrl = await _storageService.uploadWalkPhoto(
            walkProvider.currentWalk!.walkId,
            File(image.path),
          );
          
          // Add photo URL to current walk
          walkProvider.addPhotoUrl(photoUrl);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('사진이 저장되었습니다.')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('사진 업로드에 실패했습니다: $e')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진 촬영에 실패했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          _buildMap(),
          
          // Control Panel Overlay
          _buildControlPanel(),
          
          // Follow Location Button
          _buildFollowButton(),
        ],
      ),
    );
  }

  /// Build Map Widget
  Widget _buildMap() {
    final initialCenter = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(37.5665, 126.9780); // Seoul default

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 16.0,
        minZoom: 10.0,
        maxZoom: 18.0,
        onMapEvent: (event) {
          // Disable auto-follow when user drags map
          if (event is MapEventMove) {
            setState(() {
              _isFollowingLocation = false;
            });
          }
        },
      ),
      children: [
        // Tile Layer (OSM)
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.deupetwalk.app',
          maxZoom: 19,
        ),
        
        // Polyline Layer (Route)
        Consumer<WalkProvider>(
          builder: (context, walkProvider, _) {
            final currentWalk = walkProvider.currentWalk;
            if (currentWalk == null || currentWalk.routePoints.length < 2) {
              return const SizedBox.shrink();
            }
            
            final routePoints = currentWalk.routePoints
                .map((point) => LatLng(point.latitude, point.longitude))
                .toList();
            
            return PolylineLayer(
              polylines: [
                Polyline(
                  points: routePoints,
                  strokeWidth: 5.0,
                  color: AppTheme.primaryGreen,
                ),
              ],
            );
          },
        ),
        
        // Marker Layer (Current Location)
        if (_currentPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                width: 40,
                height: 40,
                child: _buildLocationMarker(),
              ),
            ],
          ),
      ],
    );
  }

  /// Build Location Marker
  Widget _buildLocationMarker() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.pets,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  /// Build Control Panel Overlay
  Widget _buildControlPanel() {
    return Consumer<WalkProvider>(
      builder: (context, walkProvider, _) {
        final isWalking = walkProvider.isWalking;
        final distance = walkProvider.currentWalk?.distance ?? 0.0;
        final formattedDistance = distance >= 1.0
            ? '${distance.toStringAsFixed(2)} km'
            : '${(distance * 1000).toStringAsFixed(0)} m';

        return Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: Card(
            elevation: 4,
            shadowColor: Colors.green.withValues(alpha: 0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.backgroundWhite,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Timer and Distance
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        icon: Icons.timer,
                        value: walkProvider.formattedElapsedTime,
                        label: '시간',
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppTheme.secondaryMint,
                      ),
                      _buildStatItem(
                        icon: Icons.straighten,
                        value: formattedDistance,
                        label: '거리',
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Control Buttons
                  if (isWalking) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _takePhoto,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('사진'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryGreen,
                              side: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _endWalk,
                            icon: const Icon(Icons.stop),
                            label: const Text('종료'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _cancelWalk,
                        icon: const Icon(Icons.cancel),
                        label: const Text('취소'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ] else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _startWalk,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('산책 시작'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build Stat Item
  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: AppTheme.primaryGreen,
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.textTitle,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textBody,
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }

  /// Build Follow Location Button
  Widget _buildFollowButton() {
    return Positioned(
      bottom: 100,
      right: 16,
      child: FloatingActionButton(
        mini: true,
        onPressed: () {
          if (_currentPosition != null) {
            setState(() {
              _isFollowingLocation = true;
            });
            _mapController.move(
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              _mapController.camera.zoom,
            );
          }
        },
        backgroundColor: _isFollowingLocation
            ? AppTheme.primaryGreen
            : AppTheme.backgroundWhite,
        child: Icon(
          Icons.my_location,
          color: _isFollowingLocation
              ? Colors.white
              : AppTheme.primaryGreen,
        ),
      ),
    );
  }
}
