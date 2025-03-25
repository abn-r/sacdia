import 'package:sacdia/features/post_register/models/allergy_model.dart';
import 'package:sacdia/features/post_register/models/disease_model.dart';

class PersonalInfoUser {
  String gender;
  DateTime? birthDate;
  bool isBaptized;
  DateTime? baptismDate;
  List<Disease> diseases;
  List<Allergy> allergies;
  String bloodType;

  PersonalInfoUser({
    required this.gender,
    required this.birthDate,
    required this.isBaptized,
    required this.baptismDate,
    required this.diseases,
    required this.allergies,
    required this.bloodType,
  });

  Map<String, dynamic> toJson() {
    return {
      'gender': gender,
      'birthDate': birthDate?.toIso8601String().split('T').first ?? '',
      'isBaptized': isBaptized,
      'baptismDate': baptismDate?.toIso8601String().split('T').first ?? '',
      'diseases': diseases.map((disease) => disease.toJson()).toList(),
      'allergies': allergies.map((allergy) => allergy.toJson()).toList(),
      'bloodType': bloodType,
    };
  }

  factory PersonalInfoUser.fromJson(Map<String, dynamic> json) {
    List<Disease> diseasesFromJson = [];
    if (json['diseases'] is List) {
      diseasesFromJson = (json['diseases'] as List)
          .map((item) => Disease.fromJson(item))
          .toList();
    }

    List<Allergy> allergiesFromJson = [];
    if (json['allergies'] is List) {
      allergiesFromJson = (json['allergies'] as List)
          .map((item) => Allergy.fromJson(item))
          .toList();
    }

    return PersonalInfoUser(
      gender: json['gender'],
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'])
          : null,
      isBaptized: json['is_baptized'],
      baptismDate: json['baptism_date'] != null
          ? DateTime.parse(json['baptism_date'])
          : null,
      diseases: diseasesFromJson,
      allergies: allergiesFromJson,
      bloodType: json['blood_type'],
    );
  }
}
