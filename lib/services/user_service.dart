import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/confirm_dialog.dart';

/// User Service Interface
abstract class UserService {
  Future<UserModel?> getUserInfo(String uid);
  Future<UserModel> updateUserInfo(UserModel user);
  Future<UserModel> createUserInfo(UserModel user);
}

/// Firebase User Service
class FirebaseUserService implements UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<UserModel?> getUserInfo(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      final user = UserModel.fromJson({
        'uid': doc.id,
        ...Map<String, dynamic>.from(data),
      });
      ErrorLogger.logSuccess('유저 정보 조회: $uid');
      return user;
    } catch (e, stackTrace) {
      ErrorLogger.logFirebaseError('유저 정보 조회', e);
      ErrorLogger.logError('getUserInfo', e, stackTrace);
      throw Exception('유저 정보를 가져오는데 실패했습니다: $e');
    }
  }

  @override
  Future<UserModel> updateUserInfo(UserModel user) async {
    try {
      ErrorLogger.logSuccess('유저 정보 수정 시작: ${user.uid}');
      
      // 기존 사용자 정보 가져오기
      final existingUser = await getUserInfo(user.uid);
      
      // 닉네임 변경 여부 확인
      if (existingUser != null && 
          existingUser.nickname != user.nickname && 
          user.nickname != null) {
        // 닉네임이 변경된 경우
        final now = DateTime.now();
        final lastChange = existingUser.lastNicknameChange;
        
        if (lastChange != null) {
          final daysSinceLastChange = now.difference(lastChange).inDays;
          if (daysSinceLastChange < 30) {
            final remainingDays = 30 - daysSinceLastChange;
            throw Exception('닉네임은 30일에 한 번만 변경할 수 있습니다. (${remainingDays}일 후 변경 가능)');
          }
        }
        
        // 닉네임 변경 시간 업데이트
        user = user.copyWith(lastNicknameChange: now);
      }
      
      await _firestore.collection('users').doc(user.uid).update(user.toJson());
      ErrorLogger.logSuccess('유저 정보 수정 완료: ${user.uid}');
      return user;
    } catch (e, stackTrace) {
      ErrorLogger.logFirebaseError('유저 정보 수정', e);
      ErrorLogger.logError('updateUserInfo', e, stackTrace);
      throw Exception('유저 정보 수정에 실패했습니다: $e');
    }
  }

  @override
  Future<UserModel> createUserInfo(UserModel user) async {
    try {
      ErrorLogger.logSuccess('유저 정보 생성 시작: ${user.uid}');
      await _firestore.collection('users').doc(user.uid).set(user.toJson());
      ErrorLogger.logSuccess('유저 정보 생성 완료: ${user.uid}');
      return user;
    } catch (e, stackTrace) {
      ErrorLogger.logFirebaseError('유저 정보 생성', e);
      ErrorLogger.logError('createUserInfo', e, stackTrace);
      throw Exception('유저 정보 생성에 실패했습니다: $e');
    }
  }
}

