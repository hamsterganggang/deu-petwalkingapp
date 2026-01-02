import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/walk_model.dart';
import '../utils/confirm_dialog.dart';

/// Walk Service Interface
abstract class WalkService {
  Future<List<WalkModel>> getWalks(String userId);
  Future<List<WalkModel>> getPublicWalks({List<String>? excludeUserIds, int limit = 50});
  Future<WalkModel> createWalk(WalkModel walk);
  Future<WalkModel> updateWalk(WalkModel walk);
  Future<void> deleteWalk(String walkId);
}

/// Firebase Walk Service
class FirebaseWalkService implements WalkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<WalkModel>> getWalks(String userId) async {
    try {
      // 인덱스가 없을 경우를 대비해 클라이언트 측에서 정렬
      // Firebase Console에서 인덱스를 생성하면 더 효율적입니다:
      // Collection: walks
      // Fields: userId (Ascending), date (Descending)
      final snapshot = await _firestore
          .collection('walks')
          .where('userId', isEqualTo: userId)
          .get();

      final walks = snapshot.docs
          .map((doc) {
            final data = doc.data();
            // walkId는 document ID와 일치해야 함
            // 만약 데이터에 walkId가 있으면 사용하고, 없으면 document ID 사용
            final walkId = data['walkId'] as String? ?? doc.id;
            return WalkModel.fromJson({
              'walkId': walkId,
              ...Map<String, dynamic>.from(data),
            });
          })
          .toList();
      
      // 클라이언트 측에서 날짜순 정렬 (인덱스가 없을 경우)
      walks.sort((a, b) => b.date.compareTo(a.date));
      
      ErrorLogger.logSuccess('산책 목록 조회: ${walks.length}개');
      return walks;
    } catch (e, stackTrace) {
      ErrorLogger.logFirebaseError('산책 목록 조회', e);
      ErrorLogger.logError('getWalks', e, stackTrace);
      throw Exception('산책 목록을 가져오는데 실패했습니다: $e');
    }
  }

  @override
  Future<WalkModel> createWalk(WalkModel walk) async {
    try {
      ErrorLogger.logSuccess('산책 저장 시작: ${walk.userId}');
      
      // walkId를 Firestore document ID로 직접 사용하여 충돌 방지
      final walkData = walk.toJson();
      // walkId는 document ID로 사용하므로 JSON에서 제거
      walkData.remove('walkId');
      
      // walkId를 document ID로 사용하여 저장
      await _firestore.collection('walks').doc(walk.walkId).set(walkData);
      
      ErrorLogger.logSuccess('산책 저장 완료: ${walk.walkId}');
      return walk;
    } catch (e, stackTrace) {
      ErrorLogger.logFirebaseError('산책 저장', e);
      ErrorLogger.logError('createWalk', e, stackTrace);
      throw Exception('산책 저장에 실패했습니다: $e');
    }
  }

  @override
  Future<WalkModel> updateWalk(WalkModel walk) async {
    try {
      ErrorLogger.logSuccess('산책 수정 시작: ${walk.walkId}');
      
      // walkId가 Firestore document ID와 일치해야 함
      final walkData = walk.toJson();
      // walkId는 document ID이므로 JSON에서 제거
      walkData.remove('walkId');
      
      // document 존재 여부 확인
      final docRef = _firestore.collection('walks').doc(walk.walkId);
      final docSnapshot = await docRef.get();
      
      if (!docSnapshot.exists) {
        throw Exception('산책 기록을 찾을 수 없습니다: ${walk.walkId}');
      }
      
      await docRef.update(walkData);
      
      ErrorLogger.logSuccess('산책 수정 완료: ${walk.walkId}');
      return walk;
    } catch (e, stackTrace) {
      ErrorLogger.logFirebaseError('산책 수정', e);
      ErrorLogger.logError('updateWalk', e, stackTrace);
      throw Exception('산책 수정에 실패했습니다: $e');
    }
  }

  @override
  Future<void> deleteWalk(String walkId) async {
    try {
      ErrorLogger.logSuccess('산책 삭제 시작: $walkId');
      
      // document 존재 여부 확인
      final docRef = _firestore.collection('walks').doc(walkId);
      final docSnapshot = await docRef.get();
      
      if (!docSnapshot.exists) {
        throw Exception('산책 기록을 찾을 수 없습니다: $walkId');
      }
      
      // 관련된 좋아요도 삭제
      final likesSnapshot = await _firestore
          .collection('likes')
          .where('walkId', isEqualTo: walkId)
          .get();
      
      final batch = _firestore.batch();
      for (var likeDoc in likesSnapshot.docs) {
        batch.delete(likeDoc.reference);
      }
      batch.delete(docRef);
      await batch.commit();
      
      ErrorLogger.logSuccess('산책 삭제 완료: $walkId (좋아요 ${likesSnapshot.docs.length}개도 삭제)');
    } catch (e, stackTrace) {
      ErrorLogger.logFirebaseError('산책 삭제', e);
      ErrorLogger.logError('deleteWalk', e, stackTrace);
      throw Exception('산책 삭제에 실패했습니다: $e');
    }
  }

  @override
  Future<List<WalkModel>> getPublicWalks({List<String>? excludeUserIds, int limit = 50}) async {
    try {
      // 인덱스가 없을 경우를 대비해 클라이언트 측에서 정렬
      // Firebase Console에서 인덱스를 생성하면 더 효율적입니다:
      // Collection: walks
      // Fields: isPublic (Ascending), date (Descending)
      Query query = _firestore
          .collection('walks')
          .where('isPublic', isEqualTo: true)
          .limit(limit * 2); // 정렬을 위해 더 많이 가져옴

      final snapshot = await query.get();

      var walks = snapshot.docs
          .map((doc) {
            final data = doc.data();
            if (data == null) {
              return WalkModel.fromJson({
                'walkId': doc.id,
                'userId': '',
                'date': DateTime.now().toIso8601String(),
                'startTime': DateTime.now().toIso8601String(),
              });
            }
            // 명시적으로 Map으로 변환
            final dataMap = data as Map<String, dynamic>;
            // walkId는 document ID와 일치해야 함
            // 만약 데이터에 walkId가 있으면 사용하고, 없으면 document ID 사용
            final walkId = dataMap['walkId'] as String? ?? doc.id;
            final jsonData = <String, dynamic>{
              'walkId': walkId,
              ...dataMap,
            };
            return WalkModel.fromJson(jsonData);
          })
          .toList();

      // 차단된 사용자의 산책 제외
      if (excludeUserIds != null && excludeUserIds.isNotEmpty) {
        walks = walks.where((walk) => !excludeUserIds.contains(walk.userId)).toList();
      }

      // 클라이언트 측에서 날짜순 정렬 (인덱스가 없을 경우)
      walks.sort((a, b) => b.date.compareTo(a.date));
      
      // limit 적용
      if (walks.length > limit) {
        walks = walks.take(limit).toList();
      }

      ErrorLogger.logSuccess('공개 산책 목록 조회: ${walks.length}개');
      return walks;
    } catch (e, stackTrace) {
      ErrorLogger.logFirebaseError('공개 산책 목록 조회', e);
      ErrorLogger.logError('getPublicWalks', e, stackTrace);
      throw Exception('공개 산책 목록을 가져오는데 실패했습니다: $e');
    }
  }
}

