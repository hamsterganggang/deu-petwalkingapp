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
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // credential.user가 null일 수 있으므로 체크
      if (credential.user == null) {
        throw Exception('사용자 정보를 가져올 수 없습니다.');
      }
      
      final user = _userFromFirebase(credential.user);
      ErrorLogger.logSuccess('로그인 성공: ${user?.email}');
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
      throw Exception('로그인에 실패했습니다: ${e.toString()}');
    }
  }

  @override
  Future<app_models.User?> signUpWithEmail(
      String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // credential.user가 null일 수 있으므로 체크
      if (credential.user == null) {
        throw Exception('사용자 정보를 가져올 수 없습니다.');
      }
      
      final user = _userFromFirebase(credential.user);
      ErrorLogger.logSuccess('회원가입 성공: ${user?.email}');
      return user;
    } on FirebaseAuthException catch (e) {
      ErrorLogger.logFirebaseError('회원가입', e);
      String errorMessage = '회원가입에 실패했습니다.';
      switch (e.code) {
        case 'weak-password':
          errorMessage = '비밀번호가 너무 약합니다.';
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
        default:
          errorMessage = '회원가입에 실패했습니다: ${e.message ?? e.code}';
      }
      throw Exception(errorMessage);
    } catch (e, stackTrace) {
      ErrorLogger.logFirebaseError('회원가입', e);
      ErrorLogger.logError('signUpWithEmail', e, stackTrace);
      throw Exception('회원가입에 실패했습니다: ${e.toString()}');
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

