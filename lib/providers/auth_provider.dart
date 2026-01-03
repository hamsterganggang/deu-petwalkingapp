import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../utils/confirm_dialog.dart';

/// Authentication Provider (ViewModel)
class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  final UserService? _userService;
  UserModel? _user;
  bool _isLoading = false;
  bool _isLoadingUserInfo = false;
  String? _error;

  AuthProvider(this._authService, [this._userService]) {
    _init();
  }

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoadingUserInfo => _isLoadingUserInfo;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  UserService? get userService => _userService;

  void _init() {
    final currentUser = _authService.getCurrentUser();
    if (currentUser != null) {
      _user = UserModel(
        uid: currentUser.id,
        email: currentUser.email,
        nickname: currentUser.displayName,
        photoUrl: currentUser.photoUrl,
      );
    }
    
    _authService.authStateChanges.listen((user) {
      if (user != null) {
        _user = UserModel(
          uid: user.id,
          email: user.email,
          nickname: user.displayName,
          photoUrl: user.photoUrl,
        );
        // 로그인 후 유저 정보 로드
        loadUserInfo();
      } else {
        _user = null;
      }
      notifyListeners();
    });
  }

  /// Load user information from Firestore
  Future<void> loadUserInfo() async {
    // 현재 인증된 사용자의 UID를 직접 가져옴 (데이터 무결성 보장)
    final authUser = _authService.getCurrentUser();
    final userService = _userService;
    if (authUser == null || userService == null) {
      _user = null;
      notifyListeners();
      return;
    }

    final currentUserId = authUser.id; // 인증된 사용자의 실제 UID 사용

    try {
      _isLoadingUserInfo = true;
      _error = null;
      notifyListeners();
      
      // Firestore에서 사용자 정보 가져오기 (명시적으로 userId 사용)
      final userData = await userService.getUserInfo(currentUserId);
      if (userData != null) {
        // 데이터 무결성 확인: 가져온 데이터의 UID가 현재 인증된 사용자와 일치하는지 확인
        if (userData.uid == currentUserId) {
          _user = userData;
        } else {
          ErrorLogger.logError('loadUserInfo', 
            Exception('사용자 데이터 불일치: 요청한 UID=$currentUserId, 반환된 UID=${userData.uid}'), 
            StackTrace.current);
          throw Exception('사용자 데이터가 일치하지 않습니다.');
        }
      } else {
        // 유저 정보가 없으면 생성 (현재 인증된 사용자의 정보 사용)
        final newUser = UserModel(
          uid: currentUserId,
          email: authUser.email,
          nickname: authUser.displayName,
          photoUrl: authUser.photoUrl,
        );
        _user = await userService.createUserInfo(newUser);
      }

      _isLoadingUserInfo = false;
      notifyListeners();
    } catch (e) {
      ErrorLogger.logError('loadUserInfo', e, StackTrace.current);
      _error = e.toString();
      _isLoadingUserInfo = false;
      _user = null; // 오류 시 사용자 정보 초기화
      notifyListeners();
    }
  }

  /// Update user information
  Future<bool> updateUserInfo(UserModel updatedUser) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_userService != null) {
        _user = await _userService.updateUserInfo(updatedUser);
      } else {
        _user = updatedUser;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      ErrorLogger.logError('updateUserInfo', e, stackTrace);
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final authUser = await _authService.signInWithEmail(email, password);
      if (authUser != null) {
        // 임시 사용자 정보 설정 (loadUserInfo에서 실제 데이터로 교체됨)
        _user = UserModel(
          uid: authUser.id,
          email: authUser.email,
          nickname: authUser.displayName,
          photoUrl: authUser.photoUrl,
        );
        // 로그인 후 유저 정보 로드 (데이터 무결성 보장)
        await loadUserInfo();
      } else {
        _user = null;
      }

      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e, stackTrace) {
      ErrorLogger.logError('signIn', e, stackTrace);
      _error = e.toString();
      _isLoading = false;
      _user = null; // 오류 시 사용자 정보 초기화
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password, {String? nickname}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Firebase Auth 회원가입 시도
      final authUser = await _authService.signUpWithEmail(email, password);
      
      if (authUser == null) {
        _error = '회원가입에 실패했습니다.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Firebase Auth 회원가입 성공 후 Firestore에 사용자 정보 생성
      final userService = _userService;
      if (userService == null) {
        _error = '서비스 초기화에 실패했습니다.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 회원가입 시 닉네임이 제공된 경우 유저 정보 생성
      if (nickname != null && nickname.isNotEmpty) {
        // 닉네임 중복 체크
        try {
          final isAvailable = await userService.isNicknameAvailable(nickname);
          if (!isAvailable) {
            // 닉네임이 중복된 경우 Firebase Auth 사용자 삭제 시도
            try {
              await _authService.signOut();
            } catch (e) {
              ErrorLogger.logError('signUp - 사용자 삭제 실패', e, StackTrace.current);
            }
            _error = '이미 사용 중인 닉네임입니다.';
            _isLoading = false;
            notifyListeners();
            return false;
          }
        } catch (e) {
          // 닉네임 중복 체크 실패 시에도 계속 진행 (네트워크 문제일 수 있음)
          ErrorLogger.logError('signUp - 닉네임 중복 체크 실패', e, StackTrace.current);
        }
        
        // 유저 정보 생성 (닉네임 포함)
        try {
          final newUser = UserModel(
            uid: authUser.id,
            email: authUser.email,
            nickname: nickname,
            photoUrl: authUser.photoUrl,
          );
          _user = await userService.createUserInfo(newUser);
        } catch (e) {
          // Firestore 사용자 정보 생성 실패 시에도 Firebase Auth는 성공했으므로 계속 진행
          ErrorLogger.logError('signUp - Firestore 사용자 정보 생성 실패', e, StackTrace.current);
          // 임시 사용자 정보 설정
          _user = UserModel(
            uid: authUser.id,
            email: authUser.email,
            nickname: nickname,
            photoUrl: authUser.photoUrl,
          );
        }
      } else {
        // 닉네임이 없는 경우 기본 유저 정보 생성
        try {
          final newUser = UserModel(
            uid: authUser.id,
            email: authUser.email,
            nickname: authUser.displayName,
            photoUrl: authUser.photoUrl,
          );
          _user = await userService.createUserInfo(newUser);
        } catch (e) {
          // Firestore 사용자 정보 생성 실패 시에도 Firebase Auth는 성공했으므로 계속 진행
          ErrorLogger.logError('signUp - Firestore 사용자 정보 생성 실패', e, StackTrace.current);
          // 임시 사용자 정보 설정
          _user = UserModel(
            uid: authUser.id,
            email: authUser.email,
            nickname: authUser.displayName,
            photoUrl: authUser.photoUrl,
          );
        }
      }

      _isLoading = false;
      notifyListeners();
      return _user != null;
    } on FirebaseAuthException catch (e, stackTrace) {
      ErrorLogger.logError('signUp FirebaseAuthException', e, stackTrace);
      
      // Firebase Auth 에러 메시지 처리
      String errorMessage = '회원가입에 실패했습니다.';
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = '이미 사용 중인 이메일입니다. 로그인을 시도해주세요.';
          break;
        case 'weak-password':
          errorMessage = '비밀번호가 너무 약합니다. (최소 6자 이상)';
          break;
        case 'invalid-email':
          errorMessage = '이메일 형식이 올바르지 않습니다.';
          break;
        default:
          errorMessage = e.message ?? '회원가입에 실패했습니다: ${e.code}';
      }
      
      _error = errorMessage;
      _isLoading = false;
      _user = null;
      notifyListeners();
      return false;
    } catch (e, stackTrace) {
      ErrorLogger.logError('signUp', e, stackTrace);
      
      // 에러 메시지에서 "Exception: " 접두사 제거
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      
      _error = errorMessage;
      _isLoading = false;
      _user = null; // 오류 시 사용자 정보 초기화
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.signOut();
      _user = null;
      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      ErrorLogger.logError('signOut', e, stackTrace);
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
