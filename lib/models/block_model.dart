/// Block Model (차단 관계)
class BlockModel {
  final String blockId;
  final String blockerId; // 차단하는 사람
  final String blockedId; // 차단 당하는 사람
  final DateTime createdAt;

  BlockModel({
    required this.blockId,
    required this.blockerId,
    required this.blockedId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'blockId': blockId,
      'blockerId': blockerId,
      'blockedId': blockedId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BlockModel.fromJson(Map<String, dynamic> json) {
    return BlockModel(
      blockId: json['blockId'] ?? '',
      blockerId: json['blockerId'] ?? '',
      blockedId: json['blockedId'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

