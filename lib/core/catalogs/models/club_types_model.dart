class ClubTypes {
  final int clubTypeId;
  final String name;
  final bool active;

  ClubTypes({
    required this.clubTypeId,
    required this.name,
    required this.active,
  });

  factory ClubTypes.fromJson(Map<String, dynamic> json) {
    return ClubTypes(
      clubTypeId: json['club_type_id'],
      name: json['name'],
      active: json['active'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'active': active,
    };
  }
}