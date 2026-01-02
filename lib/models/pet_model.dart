/// Pet Model
class PetModel {
  final String petId;
  final String ownerId;
  final String name; // 필수
  final String? breed;
  final DateTime? birthDate;
  final String? gender; // 'male', 'female', 'unknown'
  final double? weight; // kg
  final String? photoUrl;
  final bool isPrimary; // 대표 여부
  final bool? isNeutered; // 중성화 여부

  PetModel({
    required this.petId,
    required this.ownerId,
    required this.name,
    this.breed,
    this.birthDate,
    this.gender,
    this.weight,
    this.photoUrl,
    this.isPrimary = false,
    this.isNeutered,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'petId': petId,
      'ownerId': ownerId,
      'name': name,
      'breed': breed,
      'birthDate': birthDate?.toIso8601String(),
      'gender': gender,
      'weight': weight,
      'photoUrl': photoUrl,
      'isPrimary': isPrimary,
      'isNeutered': isNeutered,
    };
  }

  /// Create from JSON
  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      petId: json['petId'] ?? '',
      ownerId: json['ownerId'] ?? '',
      name: json['name'] ?? '',
      breed: json['breed'],
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'])
          : null,
      gender: json['gender'],
      weight: json['weight']?.toDouble(),
      photoUrl: json['photoUrl'],
      isPrimary: json['isPrimary'] ?? false,
      isNeutered: json['isNeutered'],
    );
  }

  /// Copy with method
  PetModel copyWith({
    String? petId,
    String? ownerId,
    String? name,
    String? breed,
    DateTime? birthDate,
    String? gender,
    double? weight,
    String? photoUrl,
    bool? isPrimary,
    bool? isNeutered,
  }) {
    return PetModel(
      petId: petId ?? this.petId,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      weight: weight ?? this.weight,
      photoUrl: photoUrl ?? this.photoUrl,
      isPrimary: isPrimary ?? this.isPrimary,
      isNeutered: isNeutered ?? this.isNeutered,
    );
  }
}

