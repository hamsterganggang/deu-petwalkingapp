/// Route Point Model (좌표)
class RoutePoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  RoutePoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory RoutePoint.fromJson(Map<String, dynamic> json) {
    return RoutePoint(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

/// Walk Model
class WalkModel {
  final String walkId;
  final String userId;
  final String? petId; // 반려동물 ID
  final DateTime date;
  final DateTime startTime; // 시작 시간
  final DateTime? endTime; // 종료 시간
  final int? duration; // minutes
  final double? distance; // km
  final List<RoutePoint> routePoints;
  final List<String> photoUrls;
  final String? memo;
  final String? mood; // 이모지
  final bool isPublic;

  WalkModel({
    required this.walkId,
    required this.userId,
    this.petId,
    required this.date,
    required this.startTime,
    this.endTime,
    this.duration,
    this.distance,
    List<RoutePoint>? routePoints,
    List<String>? photoUrls,
    this.memo,
    this.mood,
    this.isPublic = true,
  })  : routePoints = routePoints ?? [],
        photoUrls = photoUrls ?? [];

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'walkId': walkId,
      'userId': userId,
      'petId': petId,
      'date': date.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration,
      'distance': distance,
      'routePoints': routePoints.map((point) => point.toJson()).toList(),
      'photoUrls': photoUrls,
      'memo': memo,
      'mood': mood,
      'isPublic': isPublic,
    };
  }

  /// Create from JSON
  factory WalkModel.fromJson(Map<String, dynamic> json) {
    return WalkModel(
      walkId: json['walkId'] ?? '',
      userId: json['userId'] ?? '',
      petId: json['petId'],
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'])
          : DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'])
          : null,
      duration: json['duration'],
      distance: json['distance']?.toDouble(),
      routePoints: json['routePoints'] != null
          ? (json['routePoints'] as List)
              .map((point) => RoutePoint.fromJson(point))
              .toList()
          : [],
      photoUrls: json['photoUrls'] != null
          ? List<String>.from(json['photoUrls'])
          : [],
      memo: json['memo'],
      mood: json['mood'],
      isPublic: json['isPublic'] ?? true,
    );
  }

  /// Copy with method
  WalkModel copyWith({
    String? walkId,
    String? userId,
    String? petId,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    int? duration,
    double? distance,
    List<RoutePoint>? routePoints,
    List<String>? photoUrls,
    String? memo,
    String? mood,
    bool? isPublic,
  }) {
    return WalkModel(
      walkId: walkId ?? this.walkId,
      userId: userId ?? this.userId,
      petId: petId ?? this.petId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      distance: distance ?? this.distance,
      routePoints: routePoints ?? this.routePoints,
      photoUrls: photoUrls ?? this.photoUrls,
      memo: memo ?? this.memo,
      mood: mood ?? this.mood,
      isPublic: isPublic ?? this.isPublic,
    );
  }
}

