import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/walk_model.dart';
import '../services/walk_service.dart';
import '../utils/confirm_dialog.dart';

/// Mock Walk Service
class MockWalkService implements WalkService {
  final List<WalkModel> _walks = [];

  @override
  Future<List<WalkModel>> getWalks(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _walks.where((walk) => walk.walkId.contains(userId)).toList();
  }

  @override
  Future<List<WalkModel>> getPublicWalks({List<String>? excludeUserIds, int limit = 50}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    var walks = _walks.where((walk) => walk.isPublic).toList();
    if (excludeUserIds != null && excludeUserIds.isNotEmpty) {
      walks = walks.where((walk) => !excludeUserIds.contains(walk.userId)).toList();
    }
    return walks.take(limit).toList();
  }

  @override
  Future<WalkModel> createWalk(WalkModel walk) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _walks.add(walk);
    return walk;
  }

  @override
  Future<WalkModel> updateWalk(WalkModel walk) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _walks.indexWhere((w) => w.walkId == walk.walkId);
    if (index != -1) {
      _walks[index] = walk;
    }
    return walk;
  }

  @override
  Future<void> deleteWalk(String walkId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _walks.removeWhere((walk) => walk.walkId == walkId);
  }
}

/// Walk Provider (ViewModel)
class WalkProvider with ChangeNotifier {
  final WalkService _walkService;
  List<WalkModel> _walks = [];
  WalkModel? _currentWalk;
  bool _isLoading = false;
  bool _isWalking = false;
  bool _isTrackingLocation = false;
  String? _error;
  
  Timer? _walkTimer;
  // _walkStartTime: 향후 정확한 시작 시간 기록에 사용 가능 (현재는 _elapsedSeconds 사용)
  // ignore: unused_field
  DateTime? _walkStartTime;
  int _elapsedSeconds = 0;

  WalkProvider(this._walkService);

  List<WalkModel> get walks => _walks;
  WalkModel? get currentWalk => _currentWalk;
  bool get isLoading => _isLoading;
  bool get isWalking => _isWalking;
  bool get isTrackingLocation => _isTrackingLocation;
  int get elapsedSeconds => _elapsedSeconds;
  String? get error => _error;

  /// Format elapsed time as MM:SS
  String get formattedElapsedTime {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Load walks for user
  Future<void> loadWalks(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final walks = await _walkService.getWalks(userId);
      
      // 데이터 무결성 확인: 모든 산책 기록의 userId가 요청한 userId와 일치하는지 확인
      final invalidWalks = walks.where((walk) => walk.userId != userId).toList();
      if (invalidWalks.isNotEmpty) {
        ErrorLogger.logError('loadWalks', 
          Exception('산책 데이터 불일치: 요청한 userId=$userId, 불일치한 산책 수=${invalidWalks.length}'), 
          StackTrace.current);
        // 불일치한 데이터 제외
        _walks = walks.where((walk) => walk.userId == userId).toList();
      } else {
        _walks = walks;
      }
      
      _walks.sort((a, b) => b.date.compareTo(a.date));

      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      ErrorLogger.logError('loadWalks', e, stackTrace);
      _error = e.toString();
      _isLoading = false;
      _walks = []; // 오류 시 산책 목록 초기화
      notifyListeners();
    }
  }

  /// Load public walks for social feed
  Future<void> loadPublicWalks({List<String>? excludeUserIds}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _walks = await _walkService.getPublicWalks(excludeUserIds: excludeUserIds);
      _walks.sort((a, b) => b.date.compareTo(a.date));

      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      ErrorLogger.logError('loadPublicWalks', e, stackTrace);
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Start walk
  Future<bool> startWalk(String userId, {String? petId}) async {
    try {
      if (_isWalking) {
        _error = '이미 산책이 진행 중입니다.';
        notifyListeners();
        return false;
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      final now = DateTime.now();
      // 고유한 walkId 생성: userId + timestamp + random suffix로 충돌 방지
      final randomSuffix = DateTime.now().microsecondsSinceEpoch % 100000;
      final walkId = '${userId}_${now.millisecondsSinceEpoch}_$randomSuffix';
      _currentWalk = WalkModel(
        walkId: walkId,
        userId: userId,
        petId: petId,
        date: now,
        startTime: now,
        routePoints: [],
        photoUrls: [],
      );

      _walkStartTime = DateTime.now();
      _elapsedSeconds = 0;
      _isWalking = true;
      _isTrackingLocation = true;

      // Start timer
      _walkTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _elapsedSeconds++;
        notifyListeners();
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      ErrorLogger.logError('startWalk', e, stackTrace);
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Add route point (location tracking)
  void addRoutePoint(double latitude, double longitude) {
    if (!_isTrackingLocation || _currentWalk == null) return;

    final routePoint = RoutePoint(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
    );

    _currentWalk = _currentWalk!.copyWith(
      routePoints: [..._currentWalk!.routePoints, routePoint],
    );

    // Calculate distance from route points
    if (_currentWalk!.routePoints.length > 1) {
      final distance = _calculateDistance(_currentWalk!.routePoints);
      _currentWalk = _currentWalk!.copyWith(distance: distance);
    }

    notifyListeners();
  }

  /// Stop location tracking
  void stopLocationTracking() {
    _isTrackingLocation = false;
    notifyListeners();
  }

  /// Resume location tracking
  void resumeLocationTracking() {
    if (_isWalking) {
      _isTrackingLocation = true;
      notifyListeners();
    }
  }

  /// Add photo URL to current walk
  void addPhotoUrl(String photoUrl) {
    if (_currentWalk != null) {
      _currentWalk = _currentWalk!.copyWith(
        photoUrls: [..._currentWalk!.photoUrls, photoUrl],
      );
      notifyListeners();
    }
  }

  /// End walk
  Future<bool> endWalk({
    String? memo,
    String? mood,
    List<String>? photoUrls,
    bool isPublic = true,
  }) async {
    try {
      if (!_isWalking || _currentWalk == null) {
        _error = '진행 중인 산책이 없습니다.';
        notifyListeners();
        return false;
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      // Stop timer
      _walkTimer?.cancel();
      _walkTimer = null;

      // Calculate duration
      final duration = _elapsedSeconds ~/ 60; // minutes
      final endTime = DateTime.now();

      // Update current walk
      _currentWalk = _currentWalk!.copyWith(
        endTime: endTime,
        duration: duration,
        memo: memo,
        mood: mood,
        photoUrls: photoUrls ?? _currentWalk!.photoUrls,
        isPublic: isPublic,
      );

      // Save walk
      final savedWalk = await _walkService.createWalk(_currentWalk!);
      _walks.insert(0, savedWalk);

      // Reset state
      _isWalking = false;
      _isTrackingLocation = false;
      _elapsedSeconds = 0;
      _walkStartTime = null;
      _currentWalk = null;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      ErrorLogger.logError('endWalk', e, stackTrace);
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cancel walk
  Future<void> cancelWalk() async {
    _walkTimer?.cancel();
    _walkTimer = null;
    _isWalking = false;
    _isTrackingLocation = false;
    _elapsedSeconds = 0;
    _walkStartTime = null;
    _currentWalk = null;
    notifyListeners();
  }

  /// Update walk
  Future<bool> updateWalk(WalkModel walk) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updatedWalk = await _walkService.updateWalk(walk);
      final index = _walks.indexWhere((w) => w.walkId == walk.walkId);
      if (index != -1) {
        _walks[index] = updatedWalk;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      ErrorLogger.logError('updateWalk', e, stackTrace);
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete walk
  Future<bool> deleteWalk(String walkId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _walkService.deleteWalk(walkId);
      _walks.removeWhere((walk) => walk.walkId == walkId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      ErrorLogger.logError('deleteWalk', e, stackTrace);
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Calculate distance from route points (Haversine formula)
  double _calculateDistance(List<RoutePoint> points) {
    if (points.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += _haversineDistance(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude,
      );
    }

    return totalDistance; // km
  }

  /// Haversine formula to calculate distance between two points
  double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (3.141592653589793 / 180);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _walkTimer?.cancel();
    super.dispose();
  }
}

