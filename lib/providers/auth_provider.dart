import 'package:flutter/foundation.dart';
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
    final currentUser = _user;
    final userService = _userService;
    if (currentUser == null || userService == null) return;

    try {
      _isLoadingUserInfo = true;
      _error = null;
      notifyListeners();
      
      final userData = await userService.getUserInfo(currentUser.uid);
      if (userData != null) {
        _user = userData;
      } else {
        // 유저 정보가 없으면 생성
        final newUser = UserModel(
          uid: currentUser.uid,
          email: currentUser.email,
          nickname: currentUser.nickname,
          photoUrl: currentUser.photoUrl,
        );
        _user = await userService.createUserInfo(newUser);
      }

      _isLoadingUserInfo = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoadingUserInfo = false;
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
        _user = UserModel(
          uid: authUser.id,
          email: authUser.email,
          nickname: authUser.displayName,
          photoUrl: authUser.photoUrl,
        );
        // 로그인 후 유저 정보 로드
        await loadUserInfo();
      }

      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e, stackTrace) {
      ErrorLogger.logError('signIn', e, stackTrace);
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final authUser = await _authService.signUpWithEmail(email, password);
      if (authUser != null) {
        _user = UserModel(
          uid: authUser.id,
          email: authUser.email,
          nickname: authUser.displayName,
          photoUrl: authUser.photoUrl,
        );
        // 회원가입 후 유저 정보 로드
        await loadUserInfo();
      }

      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e, stackTrace) {
      ErrorLogger.logError('signUp', e, stackTrace);
      _error = e.toString();
      _isLoading = false;
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
