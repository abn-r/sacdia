class UserAllergies {
  int? userAllergyId;
  final String userId;
  final int allergyId;

  UserAllergies({
    this.userAllergyId,
    required this.userId,
    required this.allergyId,
  });

  factory UserAllergies.fromJson(Map<String, dynamic> json) {
    return UserAllergies(
      userAllergyId: json['user_allergy_id'],
      userId: json['user_id'],
      allergyId: json['allergy_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'allergy_id': allergyId,
    };
  }
}