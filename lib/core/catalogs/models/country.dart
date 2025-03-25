class Country {
  final int countryId;
  final String name;
  final String abbreviation;
  final bool active;

  const Country({
    required this.countryId,
    required this.name,
    required this.abbreviation,
    this.active = true,
  });

  /// Crea una instancia de Country a partir de un objeto JSON
  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      countryId: json['country_id'] ?? 0,
      name: json['name'] ?? '',
      abbreviation: json['abbreviation'] ?? '',
      active: json['active'] ?? true,
    );
  }

  /// Convierte esta instancia de Country a un objeto JSON
  Map<String, dynamic> toJson() {
    return {
      'country_id': countryId,
      'name': name,
      'abbreviation': abbreviation,
      'active': active,
    };
  }

  /// Crea una copia de esta instancia con los campos especificados modificados
  Country copyWith({
    int? countryId,
    String? name,
    String? abbreviation,
    bool? active,
  }) {
    return Country(
      countryId: countryId ?? this.countryId,
      name: name ?? this.name,
      abbreviation: abbreviation ?? this.abbreviation,
      active: active ?? this.active,
    );
  }

  @override
  String toString() => 'Country(countryId: $countryId, name: $name, abbreviation: $abbreviation, active: $active)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Country &&
        other.countryId == countryId &&
        other.name == name &&
        other.abbreviation == abbreviation &&
        other.active == active;
  }

  @override
  int get hashCode => countryId.hashCode ^ name.hashCode ^ abbreviation.hashCode ^ active.hashCode;
}
