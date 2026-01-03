/// User Model
class UserModel {
  final String uid;
  final String email;
  final String? nickname;
  final String? intro;
  final String? photoUrl;
  final bool isLocationPublic;
  final int followerCount;
  final int followingCount;
  final double? latitude; // 현재 위치
  final double? longitude; // 현재 위치
  final DateTime? lastLocationUpdate; // 마지막 위치 업데이트 시간
  final DateTime? lastNicknameChange; // 마지막 닉네임 변경 시간

  UserModel({
    required this.uid,
    required this.email,
    this.nickname,
    this.intro,
    this.photoUrl,
    this.isLocationPublic = false,
    this.followerCount = 0,
    this.followingCount = 0,
    this.latitude,
    this.longitude,
    this.lastLocationUpdate,
    this.lastNicknameChange,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'nickname': nickname,
      'intro': intro,
      'photoUrl': photoUrl,
      'isLocationPublic': isLocationPublic,
      'followerCount': followerCount,
      'followingCount': followingCount,
      'latitude': latitude,
      'longitude': longitude,
      'lastLocationUpdate': lastLocationUpdate?.toIso8601String(),
      'lastNicknameChange': lastNicknameChange?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      nickname: json['nickname'],
      intro: json['intro'],
      photoUrl: json['photoUrl'],
      isLocationPublic: json['isLocationPublic'] ?? false,
      followerCount: json['followerCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      lastLocationUpdate: json['lastLocationUpdate'] != null
          ? DateTime.parse(json['lastLocationUpdate'])
          : null,
      lastNicknameChange: json['lastNicknameChange'] != null
          ? DateTime.parse(json['lastNicknameChange'])
          : null,
    );
  }

  /// Copy with method
  UserModel copyWith({
    String? uid,
    String? email,
    String? nickname,
    String? intro,
    String? photoUrl,
    bool? isLocationPublic,
    int? followerCount,
    int? followingCount,
    double? latitude,
    double? longitude,
    DateTime? lastLocationUpdate,
    DateTime? lastNicknameChange,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      intro: intro ?? this.intro,
      photoUrl: photoUrl ?? this.photoUrl,
      isLocationPublic: isLocationPublic ?? this.isLocationPublic,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      lastNicknameChange: lastNicknameChange ?? this.lastNicknameChange,
    );
  }
}

