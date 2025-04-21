import 'package:sacdia/features/post_register/models/allergy_model.dart';

class UserAllergy {
  final int id;
  final String userId;
  final int allergyId;
  final String name;
  final String? description;

  UserAllergy({
    required this.id,
    required this.userId,
    required this.allergyId,
    required this.name,
    this.description,
  });

  factory UserAllergy.fromJson(Map<String, dynamic> json) {
    return UserAllergy(
      id: json['user_allergies_id'] ?? 0,
      userId: json['user_id'] ?? '',
      allergyId: json['allergy_id'] ?? 0,
      name: json['allergy'] != null 
          ? json['allergy']['name'] ?? '' 
          : json['name'] ?? '',
      description: json['allergy'] != null 
          ? json['allergy']['description'] 
          : json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_allergies_id': id,
      'user_id': userId,
      'allergy_id': allergyId,
      'name': name,
      'description': description,
    };
  }
}

extension UserAllergyExtension on UserAllergy {
  Allergy toAllergy() {
    return Allergy(
      allergyId: allergyId,
      name: name,
      description: description,
    );
  }
}

extension AllergyExtension on Allergy {
  UserAllergy toUserAllergy({required int id, required String userId}) {
    return UserAllergy(
      id: id,
      userId: userId,
      allergyId: allergyId,
      name: name,
      description: description,
    );
  }
} 