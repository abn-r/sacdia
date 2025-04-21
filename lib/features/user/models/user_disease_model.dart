class UserDisease {
  final int id;
  final String userId;
  final int diseaseId;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final bool active;
  final String name;
  final String? description;

  UserDisease({
    required this.id,
    required this.userId,
    required this.diseaseId,
    required this.createdAt,
    required this.modifiedAt,
    required this.active,
    required this.name,
    this.description,
  });

  factory UserDisease.fromJson(Map<String, dynamic> json) {
    return UserDisease(
      id: json['user_disease_id'] ?? 0,
      userId: json['user_id'] ?? '',
      diseaseId: json['disease_id'] ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      modifiedAt: json['modified_at'] != null 
          ? DateTime.parse(json['modified_at']) 
          : DateTime.now(),
      active: json['active'] ?? true,
      name: json['disease'] != null 
          ? json['disease']['name'] ?? '' 
          : json['name'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_disease_id': id,
      'user_id': userId,
      'disease_id': diseaseId,
      'created_at': createdAt.toIso8601String(),
      'modified_at': modifiedAt.toIso8601String(),
      'active': active,
      'name': name,
      'description': description,
    };
  }
} 