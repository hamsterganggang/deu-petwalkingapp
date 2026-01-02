/// Walk Model
class Walk {
  final String id;
  final String userId;
  final String? petId;
  final DateTime startTime;
  final DateTime? endTime;
  final double? distance; // km
  final int? duration; // minutes
  final String? notes;
  final List<String>? photoUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Walk({
    required this.id,
    required this.userId,
    this.petId,
    required this.startTime,
    this.endTime,
    this.distance,
    this.duration,
    this.notes,
    this.photoUrls,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'petId': petId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'distance': distance,
      'duration': duration,
      'notes': notes,
      'photoUrls': photoUrls,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create from Map (from Firestore)
  factory Walk.fromMap(Map<String, dynamic> map) {
    return Walk(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      petId: map['petId'],
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null
          ? DateTime.parse(map['endTime'])
          : null,
      distance: map['distance']?.toDouble(),
      duration: map['duration'],
      notes: map['notes'],
      photoUrls: map['photoUrls'] != null
          ? List<String>.from(map['photoUrls'])
          : null,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
    );
  }

  Walk copyWith({
    String? id,
    String? userId,
    String? petId,
    DateTime? startTime,
    DateTime? endTime,
    double? distance,
    int? duration,
    String? notes,
    List<String>? photoUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Walk(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      petId: petId ?? this.petId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
      photoUrls: photoUrls ?? this.photoUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

