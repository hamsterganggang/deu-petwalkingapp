import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'theme_data.dart';

/// 확인 다이얼로그 유틸리티
class ConfirmDialog {
  /// 확인 다이얼로그 표시
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = '확인',
    String cancelText = '취소',
    Color? confirmColor,
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Paperlogy',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Paperlogy',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              cancelText,
              style: const TextStyle(
                fontFamily: 'Paperlogy',
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: isDestructive
                  ? Colors.red
                  : (confirmColor ?? AppTheme.primaryGreen),
            ),
            child: Text(
              confirmText,
              style: const TextStyle(
                fontFamily: 'Paperlogy',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

/// 에러 로깅 유틸리티
class ErrorLogger {
  /// 에러 로그 출력
  static void logError(String context, dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('❌ [ERROR] $context');
      print('   Error: $error');
      if (stackTrace != null) {
        print('   StackTrace: $stackTrace');
      }
      print('   Time: ${DateTime.now()}');
      print('---');
    }
  }

  /// Firebase 에러 상세 로그
  static void logFirebaseError(String operation, dynamic error) {
    if (kDebugMode) {
      print('🔥 [FIREBASE ERROR] $operation');
      print('   Error Type: ${error.runtimeType}');
      print('   Error Message: $error');
      if (error is Exception) {
        print('   Exception: ${error.toString()}');
      }
      print('   Time: ${DateTime.now()}');
      print('---');
    }
  }

  /// 성공 로그
  static void logSuccess(String operation) {
    if (kDebugMode) {
      print('✅ [SUCCESS] $operation - ${DateTime.now()}');
    }
  }
}

