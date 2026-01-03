import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// 네트워크 연결 상태 모니터링 서비스
class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  
  ConnectivityResult _currentStatus = ConnectivityResult.none;
  bool _isConnected = false;
  
  // 연결 상태 변경 스트림
  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;
  
  bool get isConnected => _isConnected;
  ConnectivityResult get currentStatus => _currentStatus;

  /// 네트워크 서비스 초기화
  Future<void> initialize() async {
    // 초기 연결 상태 확인
    await checkConnection();
    
    // 연결 상태 변경 모니터링
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) {
        _updateConnectionStatus(result);
      },
    );
  }

  /// 연결 상태 확인
  Future<bool> checkConnection() async {
    try {
      // checkConnectivity()의 반환 타입 확인 및 처리
      final connectivityResult = await _connectivity.checkConnectivity();
      
      ConnectivityResult result;
      
      // connectivity_plus 버전에 따라 List 또는 단일 값 반환
      if (connectivityResult is List<ConnectivityResult>) {
        // List인 경우
        final results = connectivityResult as List<ConnectivityResult>;
        result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      } else if (connectivityResult is ConnectivityResult) {
        // 단일 값인 경우
        result = connectivityResult;
      } else {
        result = ConnectivityResult.none;
      }
      
      _updateConnectionStatus(result);
      
      // none이 아닌 경우 연결된 것으로 간주 (실제 인터넷 연결 여부는 확인하지 않음)
      // Firestore는 오프라인 모드를 지원하므로 연결 상태만 확인
      return _isConnected;
    } catch (e) {
      debugPrint('네트워크 상태 확인 실패: $e');
      // 에러 발생 시에도 true 반환 (Firestore 오프라인 모드 지원)
      // 실제 네트워크 연결은 Firestore가 처리
      _isConnected = true; // Firestore 오프라인 모드 사용 가능
      return true;
    }
  }

  /// 연결 상태 업데이트
  void _updateConnectionStatus(ConnectivityResult result) {
    final previousStatus = _currentStatus;
    final previousConnected = _isConnected;
    
    // 연결 상태 확인
    _currentStatus = result;
    _isConnected = result != ConnectivityResult.none;
    
    // 상태가 변경된 경우에만 스트림에 알림
    if (previousStatus != _currentStatus || previousConnected != _isConnected) {
      _connectionController.add(_isConnected);
      debugPrint('네트워크 상태 변경: ${_isConnected ? "연결됨" : "연결 끊김"} ($_currentStatus)');
    }
  }

  /// 연결 대기 (최대 대기 시간 설정)
  Future<bool> waitForConnection({Duration timeout = const Duration(seconds: 10)}) async {
    if (_isConnected) {
      return true;
    }
    
    try {
      await connectionStream
          .where((connected) => connected)
          .timeout(timeout)
          .first;
      return true;
    } catch (e) {
      debugPrint('연결 대기 시간 초과: $e');
      return false;
    }
  }

  /// 연결 해제
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionController.close();
  }
}

