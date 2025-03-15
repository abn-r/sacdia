class LocalField {
  final String id;
  final String name;
  final String abbreviation;
  final String unionId;
  final bool active;

  LocalField(
      {required this.abbreviation,
      required this.active,
      required this.id,
      required this.name,
      required this.unionId});

  factory LocalField.fromJson(Map<String, dynamic> json) {
    return LocalField(
      id: json['local_field_id'],
      name: json['name'],
      abbreviation: json['abbreviation'],
      unionId: json['union_id'],
      active: json['active'],
    );
  }
}
