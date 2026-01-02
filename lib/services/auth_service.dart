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
        email: email,
        password: password,
      );
      final user = _userFromFirebase(credential.user);
      ErrorLogger.logSuccess('로그인 성공: ${user?.email}');
      return user;
    } catch (e, stackTrace) {
      ErrorLogger.logFirebaseError('로그인', e);
      ErrorLogger.logError('signInWithEmail', e, stackTrace);
      throw Exception('로그인에 실패했습니다: $e');
    }
  }

  @override
  Future<app_models.User?> signUpWithEmail(
      String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = _userFromFirebase(credential.user);
      ErrorLogger.logSuccess('회원가입 성공: ${user?.email}');
      return user;
    } catch (e, stackTrace) {
      ErrorLogger.logFirebaseError('회원가입', e);
      ErrorLogger.logError('signUpWithEmail', e, stackTrace);
      throw Exception('회원가입에 실패했습니다: $e');
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

