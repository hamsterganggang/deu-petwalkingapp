# deupetwalk

반려동물 산책 관리 앱

## 개발 환경 설정

이 프로젝트는 **FVM(Flutter Version Management)**을 사용하여 Flutter 버전을 고정합니다.

### 빠른 시작

1. **FVM 설치**
   ```bash
   dart pub global activate fvm
   ```

2. **프로젝트 Flutter 버전 설치**
   ```bash
   fvm install
   fvm use
   ```

3. **패키지 설치**
   ```bash
   fvm flutter pub get
   ```

4. **앱 실행**
   ```bash
   fvm flutter run
   ```

### 상세 설정 가이드

자세한 환경 설정 방법은 [SETUP.md](SETUP.md) 파일을 참조하세요.

## 주요 기능

- 🐾 반려동물 등록 및 관리
- 🚶 산책 기록 및 추적
- 📊 산책 통계 및 차트
- 👥 소셜 기능 (팔로우, 좋아요, 차단)
- 🗺️ 실시간 위치 추적 및 경로 표시

## 기술 스택

- **Flutter**: 3.35.3
- **Dart**: 3.9.2
- **Firebase**: Authentication, Firestore, Storage
- **State Management**: Provider
- **지도**: flutter_map
- **차트**: fl_chart

## 프로젝트 구조

```
lib/
├── models/          # 데이터 모델
├── providers/       # 상태 관리
├── screens/         # 화면
├── services/        # 비즈니스 로직
└── utils/           # 유틸리티
```

## 참고 자료

- [Flutter 공식 문서](https://docs.flutter.dev/)
- [FVM 공식 문서](https://fvm.app/)
