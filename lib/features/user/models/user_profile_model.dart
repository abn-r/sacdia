class UserProfileModel {
  final String userId;
  final String name;
  final String paternalLastName;
  final String maternalLastName;
  final String email;
  final String? gender;
  final DateTime? birthday;
  final String? blood;
  final bool? baptism;
  final DateTime? baptismDate;
  final String? userImage;
  final int? countryId;
  final int? unionId;
  final int? localFieldId;
  final int? clubId;
  final int? clubAdvId;
  final int? clubMgId;
  final int? clubPathId;
  final bool isActive;

  const UserProfileModel({
    required this.userId,
    required this.name,
    required this.paternalLastName,
    required this.maternalLastName,
    required this.email,
    this.gender,
    this.birthday,
    this.blood,
    this.baptism,
    this.baptismDate,
    this.userImage,
    this.countryId,
    this.unionId,
    this.localFieldId,
    this.clubId,
    this.clubAdvId,
    this.clubMgId,
    this.clubPathId,
    this.isActive = false,
  });

  String get fullName => '$name $paternalLastName $maternalLastName';

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      paternalLastName: json['paternal_last_name'] ?? '',
      maternalLastName: json['mother_last_name'] ?? '',
      email: json['email'] ?? '',
      gender: json['gender'] ?? '',
      birthday:
          json['birthday'] != null ? DateTime.parse(json['birthday']) : null,
      blood: json['blood'] ?? '',
      baptism: json['baptism'] ?? false,
      baptismDate: json['baptism_date'] != null
          ? DateTime.parse(json['baptism_date'])
          : null,
      userImage: json['user_image'] ?? '',
      countryId: json['country_id'] != null ? int.parse(json['country_id'].toString()) : null,
      unionId: json['union_id'] != null ? int.parse(json['union_id'].toString()) : null,
      localFieldId: json['local_field_id'] != null ? int.parse(json['local_field_id'].toString()) : null,
      clubId: json['club_id'] != null ? int.parse(json['club_id'].toString()) : null,
      clubAdvId: json['club_adv_id'] != null ? int.parse(json['club_adv_id'].toString()) : null,
      clubMgId: json['club_mg_id'] != null ? int.parse(json['club_mg_id'].toString()) : null,
      clubPathId: json['club_pathf_id'] != null ? int.parse(json['club_pathf_id'].toString()) : null,
      isActive: json['active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'paternal_last_name': paternalLastName,
      'mother_last_name': maternalLastName,
      'email': email,
      'gender': gender,
      'birthday': birthday?.toIso8601String(),
      'blood': blood,
      'baptism': baptism,
      'baptism_date': baptismDate?.toIso8601String(),
      'user_image': userImage,
      'country_id': countryId,
      'union_id': unionId,
      'local_field_id': localFieldId,
      'club_id': clubId,
      'club_adv_id': clubAdvId,
      'club_mg_id': clubMgId,
      'club_pathf_id': clubPathId,
      'active': isActive,
    };
  }

  UserProfileModel copyWith({
    String? userId,
    String? name,
    String? paternalLastName,
    String? maternalLastName,
    String? email,
    String? gender,
    DateTime? birthday,
    String? blood,
    bool? baptism,
    DateTime? baptismDate,
    String? userImage,
    int? countryId,
    int? unionId,
    int? localFieldId,
    int? clubId,
    int? clubAdvId,
    int? clubMgId,
    int? clubPathId,
    bool? isActive,
  }) {
    return UserProfileModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      paternalLastName: paternalLastName ?? this.paternalLastName,
      maternalLastName: maternalLastName ?? this.maternalLastName,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
      blood: blood ?? this.blood,
      baptism: baptism ?? this.baptism,
      baptismDate: baptismDate ?? this.baptismDate,
      userImage: userImage ?? this.userImage,
      countryId: countryId ?? this.countryId,
      unionId: unionId ?? this.unionId,
      localFieldId: localFieldId ?? this.localFieldId,
      clubId: clubId ?? this.clubId,
      clubAdvId: clubAdvId ?? this.clubAdvId,
      clubMgId: clubMgId ?? this.clubMgId,
      clubPathId: clubPathId ?? this.clubPathId,
      isActive: isActive ?? this.isActive,
    );
  }
}
