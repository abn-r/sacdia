class UserDiseases {
  int? userDiseaseId;
  final String userId;
  final int diseaseId;

  UserDiseases({
    this.userDiseaseId,
    required this.userId,
    required this.diseaseId,
  });

  factory UserDiseases.fromJson(Map<String, dynamic> json) {
    return UserDiseases(
      userDiseaseId: json['user_disease_id'],
      userId: json['user_id'],
      diseaseId: json['disease_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'disease_id': diseaseId,
    };
  }
}
