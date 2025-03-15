class Union {
  final String id;
  final String name;
  final String abbreviation;
  final int countryId;
  final bool active;
 
  Union(
      {required this.id,
      required this.name,
      required this.abbreviation,
      required this.countryId,
      required this.active});

  factory Union.fromJson(Map<String, dynamic> json) {
    return Union(
      id: json['union_id'],
      name: json['name'],
      abbreviation: json['abbreviation'],
      countryId: json['country_id'],
      active: json['active'],
    );
  }
}
