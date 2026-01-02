/// Follow Model (팔로우 관계)
class FollowModel {
  final String followId;
  final String followerId; // 팔로우하는 사람
  final String followingId; // 팔로우 당하는 사람
  final DateTime createdAt;

  FollowModel({
    required this.followId,
    required this.followerId,
    required this.followingId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'followId': followId,
      'followerId': followerId,
      'followingId': followingId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FollowModel.fromJson(Map<String, dynamic> json) {
    return FollowModel(
      followId: json['followId'] ?? '',
      followerId: json['followerId'] ?? '',
      followingId: json['followingId'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

