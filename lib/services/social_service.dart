import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/confirm_dialog.dart';
import '../utils/retry_helper.dart';
import '../services/network_service.dart';

/// Social Service Interface
abstract class SocialService {
  Future<List<UserModel>> searchUsers(String query);
  Future<List<UserModel>> getNearbyUsers(double latitude, double longitude, double radiusKm);
  Future<void> followUser(String followerId, String followingId);
  Future<void> unfollowUser(String followerId, String followingId);
  Future<bool> isFollowing(String followerId, String followingId);
  Future<List<String>> getFollowingIds(String userId);
  Future<List<UserModel>> getFollowers(String userId);
  Future<List<UserModel>> getFollowing(String userId);
  Future<void> blockUser(String blockerId, String blockedId);
  Future<void> unblockUser(String blockerId, String blockedId);
  Future<bool> isBlocked(String blockerId, String blockedId);
  Future<List<String>> getBlockedIds(String userId);
  Future<void> likeWalk(String walkId, String userId);
  Future<void> unlikeWalk(String walkId, String userId);
  Future<bool> isLiked(String walkId, String userId);
  Future<int> getLikeCount(String walkId);
  Future<void> updateUserLocation(String userId, double latitude, double longitude);
}

/// Firebase Social Service
class FirebaseSocialService implements SocialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      if (query.isEmpty) return [];

      final snapshot = await _firestore
          .collection('users')
          .where('nickname', isGreaterThanOrEqualTo: query)
          .where('nickname', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      final users = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return UserModel.fromJson({
              'uid': doc.id,
              ...Map<String, dynamic>.from(data),
            });
          })
          .toList();
      
      ErrorLogger.logSuccess('사용자 검색 완료: ${users.length}명');
      return users;
    } catch (e, stackTrace) {
      ErrorLogger.logFirebaseError('사용자 검색', e);
      ErrorLogger.logError('searchUsers', e, stackTrace);
      throw Exception('사용자 검색에 실패했습니다: $e');
    }
  }

  @override
  Future<List<UserModel>> getNearbyUsers(
      double latitude, double longitude, double radiusKm) async {
    try {
      // 간단한 구현: 모든 공개 위치 사용자를 가져와서 필터링
      // 실제로는 GeoFirestore 같은 라이브러리를 사용하는 것이 좋습니다
      final snapshot = await _firestore
          .collection('users')
          .where('isLocationPublic', isEqualTo: true)
          .get();

      // 현재 산책 중인 사용자 ID 목록 가져오기 (endTime이 null인 산책)
      // 최근 1시간 이내에 시작한 산책만 확인 (오래된 미완료 산책 제외)
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      final activeWalksSnapshot = await _firestore
          .collection('walks')
          .where('endTime', isNull: true)
          .where('startTime', isGreaterThan: oneHourAgo.toIso8601String())
          .get();
      
      final walkingUserIds = activeWalksSnapshot.docs
          .map((doc) => doc.data()['userId'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();

      final nearbyUsers = <UserModel>[];
      for (var doc in snapshot.docs) {
        final user = UserModel.fromJson({
          'uid': doc.id,
          ...doc.data(),
        });

        if (user.latitude != null && user.longitude != null) {
          final distance = _calculateDistance(
            latitude,
            longitude,
            user.latitude!,
            user.longitude!,
          );

          // 반경 내에 있고, 현재 산책 중인 사용자만 추가
          if (distance <= radiusKm && walkingUserIds.contains(user.uid)) {
            nearbyUsers.add(user);
          }
        }
      }

      ErrorLogger.logSuccess('주변 사용자 검색 완료: ${nearbyUsers.length}명 (산책 중)');
      return nearbyUsers;
    } catch (e, stackTrace) {
      ErrorLogger.logFirebaseError('주변 사용자 검색', e);
      ErrorLogger.logError('getNearbyUsers', e, stackTrace);
      throw Exception('주변 사용자 검색에 실패했습니다: $e');
    }
  }

  @override
  Future<void> followUser(String followerId, String followingId) async {
    try {
      final followId = '${followerId}_$followingId';
      await _firestore.collection('follows').doc(followId).set({
        'followId': followId,
        'followerId': followerId,
        'followingId': followingId,
        'createdAt': DateTime.now().toIso8601String(),
      });

      // 팔로워/팔로잉 수 업데이트
      await _updateFollowCount(followerId, followingId, 1);
      ErrorLogger.logSuccess('팔로우 완료: $followerId -> $followingId');
    } catch (e, stackTrace) {
      ErrorLogger.logFirebaseError('팔로우', e);
      ErrorLogger.logError('followUser', e, stackTrace);
      throw Exception('팔로우에 실패했습니다: $e');
    }
  }

  @override
  Future<void> unfollowUser(String followerId, String followingId) async {
    try {
      final followId = '${followerId}_$followingId';
      await _firestore.collection('follows').doc(followId).delete();

      // 팔로워/팔로잉 수 업데이트
      await _updateFollowCount(followerId, followingId, -1);
      ErrorLogger.logSuccess('언팔로우 완료: $followerId -> $followingId');
    } catch (e, stackTrace) {
      ErrorLogger.logFirebaseError('언팔로우', e);
      ErrorLogger.logError('unfollowUser', e, stackTrace);
      throw Exception('언팔로우에 실패했습니다: $e');
    }
  }

  Future<void> _updateFollowCount(
      String followerId, String followingId, int delta) async {
    // 네트워크 연결 확인
    final networkService = NetworkService();
    if (!await networkService.checkConnection()) {
      throw Exception('네트워크에 연결되어 있지 않습니다. 인터넷 연결을 확인해주세요.');
    }

    await RetryHelper.retryWithBackoff<void>(
      operation: () async {
        // 트랜잭션을 사용하여 팔로워 수 업데이트를 원자적으로 처리
        await _firestore.runTransaction((transaction) async {
          // 팔로워의 followingCount 업데이트
          final followerRef = _firestore.collection('users').doc(followerId);
          final followerDoc = await transaction.get(followerRef);
          if (followerDoc.exists) {
            final data = followerDoc.data();
            final currentCount = (data?['followingCount'] as num?)?.toInt() ?? 0;
            final newCount = (currentCount + delta).clamp(0, double.infinity).toInt();
            transaction.update(followerRef, {'followingCount': newCount});
          }

          // 팔로우 당하는 사람의 followerCount 업데이트
          final followingRef = _firestore.collection('users').doc(followingId);
          final followingDoc = await transaction.get(followingRef);
          if (followingDoc.exists) {
            final data = followingDoc.data();
            final currentCount = (data?['followerCount'] as num?)?.toInt() ?? 0;
            final newCount = (currentCount + delta).clamp(0, double.infinity).toInt();
            transaction.update(followingRef, {'followerCount': newCount});
          }
        });
      },
      retryableErrors: RetryHelper.isRetryableError,
    );
  }

  @override
  Future<bool> isFollowing(String followerId, String followingId) async {
    try {
      final followId = '${followerId}_$followingId';
      final doc = await _firestore.collection('follows').doc(followId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<String>> getFollowingIds(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('follows')
          .where('followerId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['followingId'] as String)
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<UserModel>> getFollowers(String userId) async {
    try {
      // 나를 팔로우하는 사람들 (followerId = userId인 경우)
      final snapshot = await _firestore
          .collection('follows')
          .where('followingId', isEqualTo: userId)
          .get();

      final followerIds = snapshot.docs
          .map((doc) => doc.data()['followerId'] as String)
          .toList();

      if (followerIds.isEmpty) return [];

      // 사용자 정보 가져오기
      final users = <UserModel>[];
      for (final followerId in followerIds) {
        try {
          final userDoc = await _firestore.collection('users').doc(followerId).get();
          if (userDoc.exists) {
            final data = userDoc.data()!;
            users.add(UserModel.fromJson({
              'uid': userDoc.id,
              ...Map<String, dynamic>.from(data),
            }));
          }
        } catch (e) {
          // 개별 사용자 조회 실패는 무시
        }
      }

      ErrorLogger.logSuccess('팔로워 목록 조회: ${users.length}명');
      return users;
    } catch (e, stackTrace) {
      ErrorLogger.logFirebaseError('팔로워 목록 조회', e);
      ErrorLogger.logError('getFollowers', e, stackTrace);
      return [];
    }
  }

  @override
  Future<List<UserModel>> getFollowing(String userId) async {
    try {
      // 내가 팔로우하는 사람들 (followerId = userId인 경우)
      final snapshot = await _firestore
          .collection('follows')
          .where('followerId', isEqualTo: userId)
          .get();

      final followingIds = snapshot.docs
          .map((doc) => doc.data()['followingId'] as String)
          .toList();

      if (followingIds.isEmpty) return [];

      // 사용자 정보 가져오기
      final users = <UserModel>[];
      for (final followingId in followingIds) {
        try {
          final userDoc = await _firestore.collection('users').doc(followingId).get();
          if (userDoc.exists) {
            final data = userDoc.data()!;
            users.add(UserModel.fromJson({
              'uid': userDoc.id,
              ...Map<String, dynamic>.from(data),
            }));
          }
        } catch (e) {
          // 개별 사용자 조회 실패는 무시
        }
      }

      ErrorLogger.logSuccess('팔로잉 목록 조회: ${users.length}명');
      return users;
    } catch (e, stackTrace) {
      ErrorLogger.logFirebaseError('팔로잉 목록 조회', e);
      ErrorLogger.logError('getFollowing', e, stackTrace);
      return [];
    }
  }

  @override
  Future<void> blockUser(String blockerId, String blockedId) async {
    try {
      ErrorLogger.logSuccess('사용자 차단 시작: $blockerId -> $blockedId');
      final blockId = '${blockerId}_$blockedId';
      await _firestore.collection('blocks').doc(blockId).set({
        'blockId': blockId,
        'blockerId': blockerId,
        'blockedId': blockedId,
        'createdAt': DateTime.now().toIso8601String(),
      });
      ErrorLogger.logSuccess('사용자 차단 완료: $blockId');
    } catch (e, stackTrace) {
      ErrorLogger.logFirebaseError('사용자 차단', e);
      ErrorLogger.logError('blockUser', e, stackTrace);
      throw Exception('차단에 실패했습니다: $e');
    }
  }

  @override
  Future<void> unblockUser(String blockerId, String blockedId) async {
    try {
      ErrorLogger.logSuccess('사용자 차단 해제 시작: $blockerId -> $blockedId');
      final blockId = '${blockerId}_$blockedId';
      await _firestore.collection('blocks').doc(blockId).delete();
      ErrorLogger.logSuccess('사용자 차단 해제 완료');
    } catch (e, stackTrace) {
      ErrorLogger.logFirebaseError('사용자 차단 해제', e);
      ErrorLogger.logError('unblockUser', e, stackTrace);
      throw Exception('차단 해제에 실패했습니다: $e');
    }
  }

  @override
  Future<bool> isBlocked(String blockerId, String blockedId) async {
    try {
      final blockId = '${blockerId}_$blockedId';
      final doc = await _firestore.collection('blocks').doc(blockId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<String>> getBlockedIds(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('blocks')
          .where('blockerId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['blockedId'] as String)
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> likeWalk(String walkId, String userId) async {
    try {
      ErrorLogger.logSuccess('좋아요 시작: $walkId by $userId');
      final likeId = '${walkId}_$userId';
      await _firestore.collection('likes').doc(likeId).set({
        'likeId': likeId,
        'walkId': walkId,
        'userId': userId,
        'createdAt': DateTime.now().toIso8601String(),
      });
      ErrorLogger.logSuccess('좋아요 완료: $likeId');
    } catch (e, stackTrace) {
      ErrorLogger.logFirebaseError('좋아요', e);
      ErrorLogger.logError('likeWalk', e, stackTrace);
      throw Exception('좋아요에 실패했습니다: $e');
    }
  }

  @override
  Future<void> unlikeWalk(String walkId, String userId) async {
    try {
      ErrorLogger.logSuccess('좋아요 취소 시작: $walkId by $userId');
      final likeId = '${walkId}_$userId';
      await _firestore.collection('likes').doc(likeId).delete();
      ErrorLogger.logSuccess('좋아요 취소 완료');
    } catch (e, stackTrace) {
      ErrorLogger.logFirebaseError('좋아요 취소', e);
      ErrorLogger.logError('unlikeWalk', e, stackTrace);
      throw Exception('좋아요 취소에 실패했습니다: $e');
    }
  }

  @override
  Future<bool> isLiked(String walkId, String userId) async {
    try {
      final likeId = '${walkId}_$userId';
      final doc = await _firestore.collection('likes').doc(likeId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<int> getLikeCount(String walkId) async {
    try {
      final snapshot = await _firestore
          .collection('likes')
          .where('walkId', isEqualTo: walkId)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<void> updateUserLocation(
      String userId, double latitude, double longitude) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'latitude': latitude,
        'longitude': longitude,
        'lastLocationUpdate': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('위치 업데이트에 실패했습니다: $e');
    }
  }

  /// Haversine formula to calculate distance between two points (km)
  double _calculateDistance(
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
}

