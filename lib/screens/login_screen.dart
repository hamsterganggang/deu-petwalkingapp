import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_data.dart';
import '../utils/validators.dart';
import '../providers/auth_provider.dart';
import 'main_screen.dart';

/// Login Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isCheckingNickname = false;
  bool _isNicknameAvailable = false;
  Timer? _nicknameCheckTimer;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nicknameController.dispose();
    _nicknameCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkNicknameAvailability(String nickname) async {
    // 이전 타이머 취소
    _nicknameCheckTimer?.cancel();
    
    if (nickname.isEmpty || nickname.length < 2) {
      setState(() {
        _isNicknameAvailable = false;
        _isCheckingNickname = false;
      });
      return;
    }

    // Debounce: 500ms 후에 중복 체크 실행
    _nicknameCheckTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      
      setState(() {
        _isCheckingNickname = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userService = authProvider.userService;
        
        if (userService != null) {
          final isAvailable = await userService.isNicknameAvailable(nickname);
          if (mounted && _nicknameController.text == nickname) {
            setState(() {
              _isNicknameAvailable = isAvailable;
              _isCheckingNickname = false;
            });
            // 폼 재검증
            _formKey.currentState?.validate();
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isNicknameAvailable = false;
            _isCheckingNickname = false;
          });
        }
      }
    });
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      final success = _isLogin
          ? await authProvider.signIn(
              _emailController.text,
              _passwordController.text,
            )
          : await authProvider.signUp(
              _emailController.text,
              _passwordController.text,
              nickname: _nicknameController.text.trim(),
            );

      if (mounted) {
        // 로그인/회원가입 성공 시 화면 전환
        if (success && authProvider.isAuthenticated) {
          // 약간의 지연을 두어 상태 업데이트를 보장
          await Future.delayed(const Duration(milliseconds: 100));
          
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
              (route) => false, // 모든 이전 화면 제거
            );
          }
        } else if (authProvider.error != null) {
          // 에러 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.error!),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('인증 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                
                // Logo/Icon
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.secondaryMint,
                    child: Icon(
                      Icons.pets,
                      size: 50,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Title
                Text(
                  _isLogin ? '로그인' : '회원가입',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin
                      ? '반려동물과 함께하는 산책을 시작하세요'
                      : '새로운 계정을 만들어주세요',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: '이메일',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryGreen,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryGreen,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) => Validators.validatePassword(value),
                ),
                
                // 비밀번호 재확인 (회원가입 시에만 표시)
                if (!_isLogin) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: '비밀번호 재확인',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryGreen,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) => !_isLogin 
                        ? Validators.validatePassword(
                            value, 
                            isConfirm: true, 
                            originalPassword: _passwordController.text,
                          )
                        : null,
                  ),
                ],
                
                // 닉네임 (회원가입 시에만 표시)
                if (!_isLogin) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nicknameController,
                    decoration: InputDecoration(
                      labelText: '닉네임',
                      prefixIcon: const Icon(Icons.person_outlined),
                      suffixIcon: _isCheckingNickname
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : _nicknameController.text.isNotEmpty
                              ? Icon(
                                  _isNicknameAvailable
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: _isNicknameAvailable
                                      ? AppTheme.primaryGreen
                                      : Colors.red,
                                )
                              : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryGreen,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _isNicknameAvailable = false;
                      });
                      if (value.isNotEmpty) {
                        _checkNicknameAvailability(value);
                      }
                    },
                    validator: (value) {
                      if (!_isLogin) {
                        // 기본 유효성 검사
                        final basicValidation = Validators.validateNickname(value);
                        if (basicValidation != null) {
                          return basicValidation;
                        }
                        // 중복 체크 결과 확인
                        if (!_isNicknameAvailable && value != null && value.isNotEmpty) {
                          return '이미 사용 중인 닉네임입니다';
                        }
                      }
                      return null;
                    },
                  ),
                ],
                
                const SizedBox(height: 32),

                // Submit Button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _handleAuth,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              _isLogin ? '로그인' : '회원가입',
                              style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'Paperlogy',
                              ),
                            ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Toggle Login/Signup
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                      // 모드 전환 시 필드 초기화
                      if (_isLogin) {
                        _confirmPasswordController.clear();
                        _nicknameController.clear();
                        _isNicknameAvailable = false;
                        _nicknameCheckTimer?.cancel();
                      }
                    });
                    // 폼 재검증
                    _formKey.currentState?.reset();
                  },
                  child: Text(
                    _isLogin
                        ? '계정이 없으신가요? 회원가입'
                        : '이미 계정이 있으신가요? 로그인',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

