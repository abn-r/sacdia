class Country {
  final String id;
  final String name;
  final String abbreviation;
  final bool active;

  Country(
      {required this.id,
      required this.name,
      required this.abbreviation,
      required this.active});

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
        id: json['country_id'],
        name: json['name'],
        abbreviation: json['abbreviation'],
        active: json['active']);
  }
}
