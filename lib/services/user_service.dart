import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/confirm_dialog.dart';
import '../utils/retry_helper.dart';
import '../services/network_service.dart';

/// User Service Interface
abstract class UserService {
  Future<UserModel?> getUserInfo(String uid);
  Future<UserModel> updateUserInfo(UserModel user);
  Future<UserModel> createUserInfo(UserModel user);
  Future<bool> isNicknameAvailable(String nickname);
}

/// Firebase User Service
class FirebaseUserService implements UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<UserModel?> getUserInfo(String uid) async {
    // 읽기 작업은 Firestore 오프라인 캐시를 사용할 수 있으므로 네트워크 확인 생략
    // Firestore가 자동으로 오프라인 모드를 처리합니다

    return await RetryHelper.retryWithBackoff<UserModel?>(
      operation: () async {
        try {
          final doc = await _firestore.collection('users').doc(uid).get();
          if (!doc.exists) return null;
          final data = doc.data();
          if (data == null) return null;
          
          final user = UserModel.fromJson({
            'uid': doc.id,
            ...Map<String, dynamic>.from(data),
          });
          
          // 데이터 무결성 확인
          if (user.uid != uid) {
            throw Exception('사용자 데이터 불일치: 요청한 UID=$uid, 반환된 UID=${user.uid}');
          }
          
          ErrorLogger.logSuccess('유저 정보 조회: $uid');
          return user;
        } catch (e, stackTrace) {
          ErrorLogger.logFirebaseError('유저 정보 조회', e);
          ErrorLogger.logError('getUserInfo', e, stackTrace);
          rethrow;
        }
      },
      retryableErrors: RetryHelper.isRetryableError,
    );
  }

  @override
  Future<UserModel> updateUserInfo(UserModel user) async {
    // 네트워크 연결 확인 (업데이트는 네트워크 필요)
    final networkService = NetworkService();
    final isConnected = await networkService.checkConnection();
    if (!isConnected) {
      // 업데이트는 네트워크가 필요하므로 에러 발생
      throw Exception('네트워크에 연결되어 있지 않습니다. 인터넷 연결을 확인해주세요.');
    }

    return await RetryHelper.retryWithBackoff<UserModel>(
      operation: () async {
        try {
          ErrorLogger.logSuccess('유저 정보 수정 시작: ${user.uid}');
          
          // 트랜잭션을 사용하여 데이터 무결성 보장
          return await _firestore.runTransaction<UserModel>((transaction) async {
            // 기존 사용자 정보 가져오기
            final docRef = _firestore.collection('users').doc(user.uid);
            final docSnapshot = await transaction.get(docRef);
            
            if (!docSnapshot.exists) {
              throw Exception('사용자를 찾을 수 없습니다: ${user.uid}');
            }
            
            final existingData = docSnapshot.data();
            if (existingData == null) {
              throw Exception('사용자 데이터가 없습니다: ${user.uid}');
            }
            
            final existingUser = UserModel.fromJson({
              'uid': docSnapshot.id,
              ...Map<String, dynamic>.from(existingData),
            });
            
            // 닉네임 변경 여부 확인
            UserModel updatedUser = user;
            if (existingUser.nickname != user.nickname && user.nickname != null) {
              // 닉네임이 변경된 경우
              final now = DateTime.now();
              final lastChange = existingUser.lastNicknameChange;
              
              if (lastChange != null) {
                final daysSinceLastChange = now.difference(lastChange).inDays;
                if (daysSinceLastChange < 30) {
                  final remainingDays = 30 - daysSinceLastChange;
                  throw Exception('닉네임은 30일에 한 번만 변경할 수 있습니다. ($remainingDays일 후 변경 가능)');
                }
              }
              
              // 닉네임 중복 체크 (트랜잭션 내에서)
              final nicknameCheck = await _firestore
                  .collection('users')
                  .where('nickname', isEqualTo: user.nickname)
                  .where(FieldPath.documentId, isNotEqualTo: user.uid)
                  .limit(1)
                  .get();
              
              if (nicknameCheck.docs.isNotEmpty) {
                throw Exception('이미 사용 중인 닉네임입니다.');
              }
              
              // 닉네임 변경 시간 업데이트
              updatedUser = user.copyWith(lastNicknameChange: now);
            }
            
            // 데이터 업데이트
            final userData = updatedUser.toJson();
            transaction.update(docRef, userData);
            
            return updatedUser;
          });
        } catch (e, stackTrace) {
          ErrorLogger.logFirebaseError('유저 정보 수정', e);
          ErrorLogger.logError('updateUserInfo', e, stackTrace);
          rethrow;
        }
      },
      retryableErrors: RetryHelper.isRetryableError,
    ).then((updatedUser) {
      ErrorLogger.logSuccess('유저 정보 수정 완료: ${updatedUser.uid}');
      return updatedUser;
    });
  }

  @override
  Future<UserModel> createUserInfo(UserModel user) async {
    // 네트워크 연결 확인 (생성은 네트워크 필요)
    final networkService = NetworkService();
    final isConnected = await networkService.checkConnection();
    if (!isConnected) {
      // 생성은 네트워크가 필요하므로 에러 발생
      throw Exception('네트워크에 연결되어 있지 않습니다. 인터넷 연결을 확인해주세요.');
    }

    return await RetryHelper.retryWithBackoff<UserModel>(
      operation: () async {
        try {
          ErrorLogger.logSuccess('유저 정보 생성 시작: ${user.uid}');
          
          // 트랜잭션을 사용하여 닉네임 중복 체크와 생성을 원자적으로 처리
          return await _firestore.runTransaction<UserModel>((transaction) async {
            final docRef = _firestore.collection('users').doc(user.uid);
            final docSnapshot = await transaction.get(docRef);
            
            // 이미 존재하는 경우
            if (docSnapshot.exists) {
              final existingData = docSnapshot.data();
              if (existingData != null) {
                return UserModel.fromJson({
                  'uid': docSnapshot.id,
                  ...Map<String, dynamic>.from(existingData),
                });
              }
            }
            
            // 닉네임 중복 체크 (트랜잭션 내에서)
            if (user.nickname != null && user.nickname!.isNotEmpty) {
              final nicknameCheck = await _firestore
                  .collection('users')
                  .where('nickname', isEqualTo: user.nickname)
                  .limit(1)
                  .get();
              
              if (nicknameCheck.docs.isNotEmpty) {
                throw Exception('이미 사용 중인 닉네임입니다.');
              }
            }
            
            // 사용자 정보 생성
            final userData = user.toJson();
            transaction.set(docRef, userData);
            
            return user;
          });
        } catch (e, stackTrace) {
          ErrorLogger.logFirebaseError('유저 정보 생성', e);
          ErrorLogger.logError('createUserInfo', e, stackTrace);
          rethrow;
        }
      },
      retryableErrors: RetryHelper.isRetryableError,
    ).then((createdUser) {
      ErrorLogger.logSuccess('유저 정보 생성 완료: ${createdUser.uid}');
      return createdUser;
    });
  }

  @override
  Future<bool> isNicknameAvailable(String nickname) async {
    if (nickname.isEmpty) return false;
    
    // 네트워크 연결 확인 (중복 체크는 네트워크 필요)
    final networkService = NetworkService();
    final isConnected = await networkService.checkConnection();
    if (!isConnected) {
      // 네트워크 없으면 사용 불가로 간주 (안전을 위해)
      return false;
    }

    return await RetryHelper.retryWithBackoff<bool>(
      operation: () async {
        try {
          final snapshot = await _firestore
              .collection('users')
              .where('nickname', isEqualTo: nickname)
              .limit(1)
              .get();
          
          return snapshot.docs.isEmpty;
        } catch (e, stackTrace) {
          ErrorLogger.logFirebaseError('닉네임 중복 체크', e);
          ErrorLogger.logError('isNicknameAvailable', e, stackTrace);
          rethrow;
        }
      },
      maxRetries: 2, // 중복 체크는 재시도 횟수 줄임
      retryableErrors: RetryHelper.isRetryableError,
    );
  }
}

