# 개발 환경 설정 가이드

이 문서는 프로젝트를 처음 시작하거나 다른 컴퓨터에서 개발 환경을 설정하는 방법을 안내합니다.

## 필수 요구사항

- **Flutter SDK**: 3.35.3 (FVM 사용 권장)
- **Dart SDK**: 3.9.2 이상
- **Java**: 11 이상
- **Android Studio** 또는 **VS Code**
- **Git**

## 1. FVM 설치

FVM(Flutter Version Management)을 사용하여 프로젝트에서 지정한 Flutter 버전을 사용합니다.

### FVM 설치

```bash
dart pub global activate fvm
```

Windows의 경우 PATH에 다음 경로를 추가해야 할 수 있습니다:
```
%USERPROFILE%\AppData\Local\Pub\Cache\bin
```

### FVM 설치 확인

```bash
fvm --version
```

**Windows 사용자 주의**: FVM이 PATH에 없을 수 있습니다. 다음 경로를 시스템 PATH 환경 변수에 추가하세요:
```
C:\Users\[사용자명]\AppData\Local\Pub\Cache\bin
```

또는 PowerShell에서 임시로 사용:
```powershell
$env:Path += ";C:\Users\$env:USERNAME\AppData\Local\Pub\Cache\bin"
```

## 2. 프로젝트 Flutter 버전 설치

프로젝트 루트 디렉토리에서 다음 명령어를 실행하세요:

```bash
fvm install
```

이 명령어는 `.fvm/fvm_config.json`에 지정된 Flutter 버전(3.35.3)을 설치합니다.

## 3. FVM 사용 설정

```bash
fvm use 3.35.3
```

또는 프로젝트 루트에서:

```bash
fvm use
```

## 4. IDE 설정

### VS Code

`.vscode/settings.json` 파일이 이미 생성되어 있습니다. VS Code를 재시작하면 자동으로 FVM의 Flutter SDK를 사용합니다.

### Android Studio / IntelliJ IDEA

1. **File** > **Settings** (또는 **Preferences** on Mac)
2. **Languages & Frameworks** > **Flutter**
3. **Flutter SDK path**를 다음으로 설정:
   ```
   프로젝트경로/.fvm/flutter_sdk
   ```

## 5. 패키지 설치

FVM을 사용하여 패키지를 설치하세요:

```bash
fvm flutter pub get
```

일반 `flutter` 명령어 대신 `fvm flutter`를 사용하세요.

## 6. 프로젝트 실행

### 디버그 모드로 실행
```bash
fvm flutter run
```

### 릴리즈 모드로 빌드
```bash
fvm flutter build apk
# 또는
fvm flutter build appbundle
```

## 7. 일반적인 Flutter 명령어 (FVM 사용)

```bash
# 패키지 업데이트
fvm flutter pub upgrade

# 의존성 확인
fvm flutter pub outdated

# 코드 분석
fvm flutter analyze

# 테스트 실행
fvm flutter test

# 클린 빌드
fvm flutter clean
fvm flutter pub get
```

## 8. 문제 해결

### Windows에서 심볼릭 링크 생성 오류

Windows에서 `fvm use` 실행 시 권한 오류가 발생할 수 있습니다:

**해결 방법 1: 관리자 권한으로 실행**
1. PowerShell 또는 명령 프롬프트를 **관리자 권한**으로 실행
2. 프로젝트 디렉토리로 이동
3. `fvm use 3.35.3` 실행

**해결 방법 2: 개발자 모드 활성화 (Windows 10/11)**
1. **설정** > **개인 정보 보호 및 보안** > **개발자용**으로 이동
2. **개발자 모드** 활성화
3. 재부팅 후 다시 시도

**해결 방법 3: FVM 없이 직접 사용**
FVM 설정 파일(`.fvm/fvm_config.json`, `.fvmrc`)이 있으면, 다른 컴퓨터에서도 동일한 Flutter 버전을 사용할 수 있습니다:
```bash
# FVM 없이 직접 Flutter 3.35.3 설치 후 사용
flutter --version  # 3.35.3인지 확인
```

### FVM이 인식되지 않는 경우

1. FVM이 제대로 설치되었는지 확인:
   ```bash
   dart pub global list
   ```

2. PATH 환경 변수 확인

3. 터미널/명령 프롬프트 재시작

### Flutter 버전이 다른 경우

프로젝트 루트에서 다음 명령어로 확인:
```bash
fvm flutter --version
```

버전이 다르면:
```bash
fvm use 3.35.3
fvm flutter pub get
```

### IDE에서 Flutter SDK를 찾을 수 없는 경우

1. `.fvm/flutter_sdk` 폴더가 존재하는지 확인
2. IDE의 Flutter SDK 경로를 `.fvm/flutter_sdk`로 설정
3. IDE 재시작

## 9. Git 설정

다음 파일들은 Git에 포함되어야 합니다:
- `.fvm/fvm_config.json` ✅ (커밋 필요)
- `.vscode/settings.json` ✅ (커밋 필요)
- `pubspec.lock` ✅ (커밋 필요)

다음은 Git에서 제외됩니다:
- `.fvm/flutter_sdk/` (각자 설치)
- `.dart_tool/`
- `build/`

## 10. 팀원과 공유

새로운 팀원이 프로젝트를 클론한 후:

```bash
# 1. FVM 설치 (위의 1단계 참조)
dart pub global activate fvm

# 2. 프로젝트 클론
git clone [프로젝트 URL]
cd deu-petwalkingapp

# 3. Flutter 버전 설치
fvm install

# 4. FVM 사용 설정
fvm use

# 5. 패키지 설치
fvm flutter pub get

# 6. 실행
fvm flutter run
```

## 추가 정보

- [FVM 공식 문서](https://fvm.app/)
- [Flutter 공식 문서](https://docs.flutter.dev/)

