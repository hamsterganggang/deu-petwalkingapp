/// Like Model (좋아요)
class LikeModel {
  final String likeId;
  final String walkId; // 산책 기록 ID
  final String userId; // 좋아요 누른 사용자 ID
  final DateTime createdAt;

  LikeModel({
    required this.likeId,
    required this.walkId,
    required this.userId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'likeId': likeId,
      'walkId': walkId,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LikeModel.fromJson(Map<String, dynamic> json) {
    return LikeModel(
      likeId: json['likeId'] ?? '',
      walkId: json['walkId'] ?? '',
      userId: json['userId'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

