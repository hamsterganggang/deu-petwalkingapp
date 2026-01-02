/// Pet Model
class Pet {
  final String id;
  final String userId;
  final String name;
  final String? breed;
  final String? species; // dog, cat, etc.
  final DateTime? birthDate;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Pet({
    required this.id,
    required this.userId,
    required this.name,
    this.breed,
    this.species,
    this.birthDate,
    this.photoUrl,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'breed': breed,
      'species': species,
      'birthDate': birthDate?.toIso8601String(),
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create from Map (from Firestore)
  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      breed: map['breed'],
      species: map['species'],
      birthDate: map['birthDate'] != null
          ? DateTime.parse(map['birthDate'])
          : null,
      photoUrl: map['photoUrl'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
    );
  }

  Pet copyWith({
    String? id,
    String? userId,
    String? name,
    String? breed,
    String? species,
    DateTime? birthDate,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Pet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      species: species ?? this.species,
      birthDate: birthDate ?? this.birthDate,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

