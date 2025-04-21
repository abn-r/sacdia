class UserClass {
  final int id;
  final String userId;
  final int classId;
  final bool investiture;
  final bool advanced;
  final DateTime? dateInvestiture;
  final String className;
  final int clubTypeId;
  final String clubTypeName;

  UserClass({
    required this.id,
    required this.userId,
    required this.classId,
    required this.investiture,
    required this.advanced,
    this.dateInvestiture,
    required this.className,
    required this.clubTypeId,
    required this.clubTypeName,
  });

  factory UserClass.fromJson(Map<String, dynamic> json) {
    return UserClass(
      id: json['user_class_id'] ?? 0,
      userId: json['user_id'] ?? '',
      classId: json['class_id'] ?? 0,
      investiture: json['investiture'] ?? false,
      advanced: json['advanced'] ?? false,
      dateInvestiture: json['date_investiture'] != null 
          ? DateTime.parse(json['date_investiture'])
          : null,
      className: json['class_name'] ?? '',
      clubTypeId: json['club_type_id'] ?? 0,
      clubTypeName: json['club_type_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_class_id': id,
      'user_id': userId,
      'class_id': classId,
      'investiture': investiture,
      'advanced': advanced,
      'date_investiture': dateInvestiture?.toIso8601String(),
      'class_name': className,
      'club_type_id': clubTypeId,
      'club_type_name': clubTypeName,
    };
  }
} 