import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart' as app_models;
import '../utils/confirm_dialog.dart';

/// Authentication Service Interface
/// Can be implemented with Firebase or Mock
abstract class AuthService {
  Future<app_models.User?> signInWithEmail(String email, String password);
  Future<app_models.User?> signUpWithEmail(String email, String password);
  Future<void> signOut();
  app_models.User? getCurrentUser();
  Stream<app_models.User?> get authStateChanges;
}

/// Firebase Authentication Service Implementation
class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Future<app_models.User?> signInWithEmail(
      String email, String password) async {
    try {
      // 이메일 정리
      final trimmedEmail = email.trim();
      if (trimmedEmail.isEmpty) {
        throw Exception('이메일을 입력해주세요.');
      }
      
      // Firebase Auth 호출
      UserCredential? credential;
      try {
        credential = await _auth.signInWithEmailAndPassword(
          email: trimmedEmail,
          password: password,
        );
      } catch (e) {
        // 타입 캐스팅 에러가 발생할 수 있으므로 재시도
        if (e.toString().contains('PigeonUserDetails') || 
            e.toString().contains('type cast')) {
          // 잠시 대기 후 재시도
          await Future.delayed(const Duration(milliseconds: 500));
          credential = await _auth.signInWithEmailAndPassword(
            email: trimmedEmail,
            password: password,
          );
        } else {
          rethrow;
        }
      }
      
      // credential이 null인 경우
      if (credential == null) {
        throw Exception('로그인 응답을 받을 수 없습니다.');
      }
      
      // credential.user가 null인 경우, 현재 사용자 확인
      User? firebaseUser = credential.user;
      if (firebaseUser == null) {
        // credential.user가 null이면 현재 인증된 사용자 확인
        firebaseUser = _auth.currentUser;
        if (firebaseUser == null) {
          throw Exception('사용자 정보를 가져올 수 없습니다.');
        }
      }
      
      final user = _userFromFirebase(firebaseUser);
      if (user == null) {
        throw Exception('사용자 정보 변환에 실패했습니다.');
      }
      
      ErrorLogger.logSuccess('로그인 성공: ${user.email}');
      return user;
    } on FirebaseAuthException catch (e) {
      ErrorLogger.logFirebaseError('로그인', e);
      String errorMessage = '로그인에 실패했습니다.';
      switch (e.code) {
        case 'user-not-found':
          errorMessage = '등록되지 않은 이메일입니다.';
          break;
        case 'wrong-password':
          errorMessage = '비밀번호가 올바르지 않습니다.';
          break;
        case 'invalid-email':
          errorMessage = '이메일 형식이 올바르지 않습니다.';
          break;
        case 'user-disabled':
          errorMessage = '비활성화된 계정입니다.';
          break;
        case 'too-many-requests':
          errorMessage = '너무 많은 시도가 있었습니다. 나중에 다시 시도해주세요.';
          break;
        case 'operation-not-allowed':
          errorMessage = '이메일/비밀번호 로그인이 허용되지 않습니다.';
          break;
        default:
          errorMessage = '로그인에 실패했습니다: ${e.message ?? e.code}';
      }
      throw Exception(errorMessage);
    } catch (e, stackTrace) {
      ErrorLogger.logFirebaseError('로그인', e);
      ErrorLogger.logError('signInWithEmail', e, stackTrace);
      
      // 타입 캐스팅 에러인 경우 특별 처리
      if (e.toString().contains('PigeonUserDetails') || 
          e.toString().contains('type cast')) {
        // 현재 사용자로 로그인 시도
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          final user = _userFromFirebase(currentUser);
          if (user != null) {
            ErrorLogger.logSuccess('로그인 성공 (현재 사용자): ${user.email}');
            return user;
          }
        }
        throw Exception('로그인 처리 중 오류가 발생했습니다. 앱을 재시작해주세요.');
      }
      
      throw Exception('로그인에 실패했습니다: ${e.toString()}');
    }
  }

  @override
  Future<app_models.User?> signUpWithEmail(
      String email, String password) async {
    try {
      // 이메일 정리 및 기본 검증
      final trimmedEmail = email.trim();
      if (trimmedEmail.isEmpty) {
        throw Exception('이메일을 입력해주세요.');
      }
      
      // 이메일 형식 기본 검증 (Firebase Auth가 최종 검증하지만, 미리 체크)
      if (!trimmedEmail.contains('@') || !trimmedEmail.contains('.')) {
        throw Exception('올바른 이메일 형식이 아닙니다.');
      }
      
      // Firebase Auth 호출
      final credential = await _auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
      
      // credential.user가 null일 수 있으므로 체크
      if (credential.user == null) {
        throw Exception('사용자 정보를 가져올 수 없습니다.');
      }
      
      final user = _userFromFirebase(credential.user);
      if (user == null) {
        throw Exception('사용자 정보 변환에 실패했습니다.');
      }
      
      ErrorLogger.logSuccess('회원가입 성공: ${user.email}');
      return user;
    } on FirebaseAuthException catch (e) {
      ErrorLogger.logFirebaseError('회원가입', e);
      String errorMessage = '회원가입에 실패했습니다.';
      switch (e.code) {
        case 'weak-password':
          errorMessage = '비밀번호가 너무 약합니다. (최소 6자 이상)';
          break;
        case 'email-already-in-use':
          errorMessage = '이미 사용 중인 이메일입니다.';
          break;
        case 'invalid-email':
          errorMessage = '이메일 형식이 올바르지 않습니다.';
          break;
        case 'operation-not-allowed':
          errorMessage = '이메일/비밀번호 회원가입이 허용되지 않습니다.';
          break;
        case 'network-request-failed':
          errorMessage = '네트워크 연결을 확인해주세요.';
          break;
        default:
          // Firebase Auth의 실제 에러 메시지 사용
          errorMessage = e.message ?? '회원가입에 실패했습니다: ${e.code}';
      }
      throw Exception(errorMessage);
    } catch (e, stackTrace) {
      ErrorLogger.logFirebaseError('회원가입', e);
      ErrorLogger.logError('signUpWithEmail', e, stackTrace);
      
      // 에러 메시지 정리
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      
      throw Exception(errorMessage);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      ErrorLogger.logSuccess('로그아웃 시작');
      await _auth.signOut();
      ErrorLogger.logSuccess('로그아웃 완료');
    } catch (e, stackTrace) {
      ErrorLogger.logFirebaseError('로그아웃', e);
      ErrorLogger.logError('signOut', e, stackTrace);
      rethrow;
    }
  }

  @override
  app_models.User? getCurrentUser() {
    return _userFromFirebase(_auth.currentUser);
  }

  @override
  Stream<app_models.User?> get authStateChanges {
    return _auth.authStateChanges().map(_userFromFirebase);
  }

  app_models.User? _userFromFirebase(User? user) {
    if (user == null) return null;
    return app_models.User(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      updatedAt: user.metadata.lastSignInTime,
    );
  }
}

/// Mock Authentication Service for Testing
class MockAuthService implements AuthService {
  app_models.User? _currentUser;

  @override
  Future<app_models.User?> signInWithEmail(
      String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = app_models.User(
      id: 'mock_user_1',
      email: email,
      displayName: 'Mock User',
      createdAt: DateTime.now(),
    );
    return _currentUser;
  }

  @override
  Future<app_models.User?> signUpWithEmail(
      String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = app_models.User(
      id: 'mock_user_1',
      email: email,
      displayName: 'Mock User',
      createdAt: DateTime.now(),
    );
    return _currentUser;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
  }

  @override
  app_models.User? getCurrentUser() {
    return _currentUser;
  }

  @override
  Stream<app_models.User?> get authStateChanges {
    return Stream.value(_currentUser);
  }
}

