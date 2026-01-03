import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 재시도 로직 헬퍼 클래스
class RetryHelper {
  /// 지수 백오프를 사용한 재시도
  /// 
  /// [operation]: 실행할 비동기 작업
  /// [maxRetries]: 최대 재시도 횟수 (기본값: 3)
  /// [initialDelay]: 초기 지연 시간 (기본값: 1초)
  /// [maxDelay]: 최대 지연 시간 (기본값: 10초)
  /// [backoffMultiplier]: 백오프 배수 (기본값: 2)
  /// [retryableErrors]: 재시도 가능한 에러 타입
  static Future<T> retryWithBackoff<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    Duration maxDelay = const Duration(seconds: 10),
    double backoffMultiplier = 2.0,
    bool Function(dynamic error)? retryableErrors,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;
    final random = Random();

    while (attempt <= maxRetries) {
      try {
        return await operation();
      } catch (e) {
        // 재시도 불가능한 에러인지 확인
        if (retryableErrors != null && !retryableErrors(e)) {
          rethrow;
        }

        // 최대 재시도 횟수에 도달한 경우
        if (attempt >= maxRetries) {
          rethrow;
        }

        attempt++;
        
        // 지수 백오프 + jitter (랜덤 지연 추가로 동시 요청 충돌 방지)
        final jitter = Duration(milliseconds: random.nextInt(500));
        final totalDelay = Duration(
          milliseconds: (delay.inMilliseconds * pow(backoffMultiplier, attempt - 1)).toInt(),
        );
        final finalDelay = totalDelay > maxDelay 
            ? maxDelay 
            : totalDelay + jitter;

        await Future.delayed(finalDelay);
        delay = finalDelay;
      }
    }

    throw Exception('재시도 실패: 최대 재시도 횟수 초과');
  }

  /// Firestore 관련 에러가 재시도 가능한지 확인
  static bool isRetryableFirestoreError(dynamic error) {
    if (error is FirebaseException) {
      // 재시도 가능한 Firestore 에러 코드
      final retryableCodes = [
        'unavailable',
        'deadline-exceeded',
        'resource-exhausted',
        'internal',
        'aborted',
        'cancelled',
      ];
      
      return retryableCodes.contains(error.code);
    }
    
    // 네트워크 관련 에러
    if (error.toString().contains('network') || 
        error.toString().contains('connection') ||
        error.toString().contains('timeout')) {
      return true;
    }
    
    return false;
  }

  /// 일반적인 네트워크 에러가 재시도 가능한지 확인
  static bool isRetryableNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    return errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('timeout') ||
           errorString.contains('socket') ||
           errorString.contains('unavailable');
  }

  /// 재시도 가능한 모든 에러 확인
  static bool isRetryableError(dynamic error) {
    return isRetryableFirestoreError(error) || 
           isRetryableNetworkError(error);
  }
}

