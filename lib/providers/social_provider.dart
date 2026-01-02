import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/social_service.dart';
import '../utils/confirm_dialog.dart';

/// Social Provider (ViewModel)
class SocialProvider with ChangeNotifier {
  final SocialService _socialService;
  List<UserModel> _searchResults = [];
  List<UserModel> _nearbyUsers = [];
  final Map<String, bool> _followingStatus = {}; // userId -> isFollowing
  final Map<String, bool> _likedStatus = {}; // walkId -> isLiked
  final Map<String, int> _likeCounts = {}; // walkId -> count
  bool _isLoading = false;
  String? _error;

  SocialProvider(this._socialService);

  List<UserModel> get searchResults => _searchResults;
  List<UserModel> get nearbyUsers => _nearbyUsers;
  List<UserModel> _followers = [];
  List<UserModel> _following = [];
  List<UserModel> get followers => _followers;
  List<UserModel> get following => _following;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool isFollowing(String userId) => _followingStatus[userId] ?? false;
  bool isLiked(String walkId) => _likedStatus[walkId] ?? false;
  int getLikeCount(String walkId) => _likeCounts[walkId] ?? 0;

  /// Search users by nickname
  Future<void> searchUsers(String query) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _searchResults = await _socialService.searchUsers(query);

      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      ErrorLogger.logError('searchUsers', e, stackTrace);
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get nearby users (within radius)
  Future<void> getNearbyUsers(
      double latitude, double longitude, double radiusKm) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _nearbyUsers =
          await _socialService.getNearbyUsers(latitude, longitude, radiusKm);

      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      ErrorLogger.logError('getNearbyUsers', e, stackTrace);
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Follow user
  Future<bool> followUser(String followerId, String followingId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _socialService.followUser(followerId, followingId);
      _followingStatus[followingId] = true;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Unfollow user
  Future<bool> unfollowUser(String followerId, String followingId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _socialService.unfollowUser(followerId, followingId);
      _followingStatus[followingId] = false;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      ErrorLogger.logError('unfollowUser', e, stackTrace);
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Check if following
  Future<void> checkFollowingStatus(
      String followerId, String followingId) async {
    try {
      final isFollowing = await _socialService.isFollowing(followerId, followingId);
      _followingStatus[followingId] = isFollowing;
      notifyListeners();
    } catch (e) {
      // Ignore error
    }
  }

  /// Like walk
  Future<bool> likeWalk(String walkId, String userId) async {
    try {
      await _socialService.likeWalk(walkId, userId);
      _likedStatus[walkId] = true;
      _likeCounts[walkId] = (_likeCounts[walkId] ?? 0) + 1;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      ErrorLogger.logError('likeWalk', e, stackTrace);
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Unlike walk
  Future<bool> unlikeWalk(String walkId, String userId) async {
    try {
      await _socialService.unlikeWalk(walkId, userId);
      _likedStatus[walkId] = false;
      _likeCounts[walkId] = (_likeCounts[walkId] ?? 1) - 1;
      if (_likeCounts[walkId]! < 0) _likeCounts[walkId] = 0;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      ErrorLogger.logError('unlikeWalk', e, stackTrace);
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Check if liked and get like count
  Future<void> checkLikeStatus(String walkId, String userId) async {
    try {
      final isLiked = await _socialService.isLiked(walkId, userId);
      final count = await _socialService.getLikeCount(walkId);
      _likedStatus[walkId] = isLiked;
      _likeCounts[walkId] = count;
      notifyListeners();
    } catch (e) {
      // Ignore error
    }
  }

  /// Block user
  Future<bool> blockUser(String blockerId, String blockedId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _socialService.blockUser(blockerId, blockedId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      ErrorLogger.logError('blockUser', e, stackTrace);
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Unblock user
  Future<bool> unblockUser(String blockerId, String blockedId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _socialService.unblockUser(blockerId, blockedId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      ErrorLogger.logError('unblockUser', e, stackTrace);
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update user location
  Future<void> updateUserLocation(
      String userId, double latitude, double longitude) async {
    try {
      await _socialService.updateUserLocation(userId, latitude, longitude);
    } catch (e) {
      // Ignore error
    }
  }

  /// Get blocked user IDs
  Future<List<String>> getBlockedIds(String userId) async {
    try {
      return await _socialService.getBlockedIds(userId);
    } catch (e) {
      return [];
    }
  }

  /// Load followers list
  Future<void> loadFollowers(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _followers = await _socialService.getFollowers(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      ErrorLogger.logError('loadFollowers', e, stackTrace);
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load following list
  Future<void> loadFollowing(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _following = await _socialService.getFollowing(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      ErrorLogger.logError('loadFollowing', e, stackTrace);
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

