/// 상업화 수준의 유효성 검사 유틸리티
class Validators {
  /// 이메일 유효성 검사
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return '이메일을 입력해주세요';
    }
    
    // 공백 제거
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      return '이메일을 입력해주세요';
    }
    
    // 기본 이메일 형식 검증
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(trimmedValue)) {
      return '올바른 이메일 형식이 아닙니다';
    }
    
    // 길이 제한 (RFC 5321)
    if (trimmedValue.length > 254) {
      return '이메일은 254자 이하여야 합니다';
    }
    
    // 로컬 파트 길이 제한 (RFC 5321)
    final localPart = trimmedValue.split('@')[0];
    if (localPart.length > 64) {
      return '이메일 주소가 너무 깁니다';
    }
    
    // 연속된 점(.) 검증
    if (trimmedValue.contains('..')) {
      return '이메일 형식이 올바르지 않습니다';
    }
    
    // 시작/끝 문자 검증
    if (trimmedValue.startsWith('.') || trimmedValue.startsWith('@')) {
      return '이메일 형식이 올바르지 않습니다';
    }
    
    return null;
  }

  /// 비밀번호 유효성 검사
  static String? validatePassword(String? value, {bool isConfirm = false, String? originalPassword}) {
    if (value == null || value.isEmpty) {
      return isConfirm ? '비밀번호를 다시 입력해주세요' : '비밀번호를 입력해주세요';
    }
    
    // 최소 길이
    if (value.length < 6) {
      return '비밀번호는 6자 이상이어야 합니다';
    }
    
    // 최대 길이
    if (value.length > 128) {
      return '비밀번호는 128자 이하여야 합니다';
    }
    
    // 비밀번호 재확인 시 일치 여부 확인
    if (isConfirm && originalPassword != null && value != originalPassword) {
      return '비밀번호가 일치하지 않습니다';
    }
    
    // 보안 강도 검증 (선택사항 - 필요시 활성화)
    // final hasUpperCase = value.contains(RegExp(r'[A-Z]'));
    // final hasLowerCase = value.contains(RegExp(r'[a-z]'));
    // final hasDigits = value.contains(RegExp(r'[0-9]'));
    // final hasSpecialChar = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    // 
    // if (!hasUpperCase || !hasLowerCase || !hasDigits || !hasSpecialChar) {
    //   return '비밀번호는 대문자, 소문자, 숫자, 특수문자를 포함해야 합니다';
    // }
    
    return null;
  }

  /// 닉네임 유효성 검사
  static String? validateNickname(String? value) {
    if (value == null || value.isEmpty) {
      return '닉네임을 입력해주세요';
    }
    
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      return '닉네임을 입력해주세요';
    }
    
    // 최소 길이
    if (trimmedValue.length < 2) {
      return '닉네임은 2자 이상이어야 합니다';
    }
    
    // 최대 길이
    if (trimmedValue.length > 20) {
      return '닉네임은 20자 이하여야 합니다';
    }
    
    // 허용된 문자만 사용 (한글, 영문, 숫자, 공백, 일부 특수문자)
    final nicknameRegex = RegExp(r'^[가-힣a-zA-Z0-9\s_-]+$');
    if (!nicknameRegex.hasMatch(trimmedValue)) {
      return '닉네임은 한글, 영문, 숫자, 공백, -, _ 만 사용할 수 있습니다';
    }
    
    // 연속된 공백 검증
    if (trimmedValue.contains('  ')) {
      return '연속된 공백은 사용할 수 없습니다';
    }
    
    // 시작/끝 공백 검증
    if (value != trimmedValue) {
      return '닉네임 앞뒤 공백은 제거됩니다';
    }
    
    // 금지된 단어 검증 (필요시 추가)
    final forbiddenWords = ['admin', 'administrator', '관리자', 'null', 'undefined'];
    final lowerValue = trimmedValue.toLowerCase();
    for (final word in forbiddenWords) {
      if (lowerValue.contains(word)) {
        return '사용할 수 없는 단어가 포함되어 있습니다';
      }
    }
    
    return null;
  }

  /// 펫 이름 유효성 검사
  static String? validatePetName(String? value) {
    if (value == null || value.isEmpty) {
      return '이름을 입력해주세요';
    }
    
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      return '이름을 입력해주세요';
    }
    
    // 최소 길이
    if (trimmedValue.length < 1) {
      return '이름을 입력해주세요';
    }
    
    // 최대 길이
    if (trimmedValue.length > 50) {
      return '이름은 50자 이하여야 합니다';
    }
    
    // 허용된 문자만 사용
    final nameRegex = RegExp(r'^[가-힣a-zA-Z0-9\s]+$');
    if (!nameRegex.hasMatch(trimmedValue)) {
      return '이름은 한글, 영문, 숫자, 공백만 사용할 수 있습니다';
    }
    
    return null;
  }

  /// 메모/소개 유효성 검사
  static String? validateMemo(String? value, {int maxLength = 500}) {
    if (value == null) {
      return null; // 선택사항
    }
    
    final trimmedValue = value.trim();
    
    // 최대 길이
    if (trimmedValue.length > maxLength) {
      return '${maxLength}자 이하여야 합니다';
    }
    
    return null;
  }

  /// 체중 유효성 검사
  static String? validateWeight(double? value) {
    if (value == null) {
      return '체중을 입력해주세요';
    }
    
    if (value <= 0) {
      return '체중은 0보다 커야 합니다';
    }
    
    if (value > 200) {
      return '체중은 200kg 이하여야 합니다';
    }
    
    return null;
  }

  /// 날짜 유효성 검사
  static String? validateDate(DateTime? value) {
    if (value == null) {
      return '날짜를 선택해주세요';
    }
    
    // 미래 날짜 검증
    if (value.isAfter(DateTime.now())) {
      return '미래 날짜는 선택할 수 없습니다';
    }
    
    // 너무 오래된 날짜 검증 (예: 100년 전)
    final hundredYearsAgo = DateTime.now().subtract(const Duration(days: 365 * 100));
    if (value.isBefore(hundredYearsAgo)) {
      return '유효하지 않은 날짜입니다';
    }
    
    return null;
  }

  /// URL 유효성 검사
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // 선택사항
    }
    
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      return null;
    }
    
    try {
      final uri = Uri.parse(trimmedValue);
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        return '올바른 URL 형식이 아닙니다';
      }
      return null;
    } catch (e) {
      return '올바른 URL 형식이 아닙니다';
    }
  }

  /// 숫자 유효성 검사
  static String? validateNumber(String? value, {double? min, double? max}) {
    if (value == null || value.isEmpty) {
      return '숫자를 입력해주세요';
    }
    
    final number = double.tryParse(value);
    if (number == null) {
      return '올바른 숫자가 아닙니다';
    }
    
    if (min != null && number < min) {
      return '${min} 이상이어야 합니다';
    }
    
    if (max != null && number > max) {
      return '${max} 이하여야 합니다';
    }
    
    return null;
  }

  /// 필수 필드 검증
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName을(를) 입력해주세요';
    }
    return null;
  }

  /// 여러 유효성 검사 조합
  static String? validateMultiple(List<String? Function()> validators) {
    for (final validator in validators) {
      final result = validator();
      if (result != null) {
        return result;
      }
    }
    return null;
  }
}

