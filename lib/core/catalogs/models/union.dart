class Union {
  final int unionId;
  final String name;
  final String abbreviation;
  final int countryId;
  final bool active;
 
  const Union({
    required this.unionId,
    required this.name,
    required this.abbreviation,
    required this.countryId,
    this.active = true,
  });

  /// Crea una instancia de Union a partir de un objeto JSON
  factory Union.fromJson(Map<String, dynamic> json) {
    return Union(
      unionId: json['union_id'] ?? 0,
      name: json['name'] ?? '',
      abbreviation: json['abbreviation'] ?? '',
      countryId: json['country_id'] ?? 0,
      active: json['active'] ?? true,
    );
  }

  /// Convierte esta instancia de Union a un objeto JSON
  Map<String, dynamic> toJson() {
    return {
      'union_id': unionId,
      'name': name,
      'abbreviation': abbreviation,
      'country_id': countryId,
      'active': active,
    };
  }

  /// Crea una copia de esta instancia con los campos especificados modificados
  Union copyWith({
    int? unionId,
    String? name,
    String? abbreviation,
    int? countryId,
    bool? active,
  }) {
    return Union(
      unionId: unionId ?? this.unionId,
      name: name ?? this.name,
      abbreviation: abbreviation ?? this.abbreviation,
      countryId: countryId ?? this.countryId,
      active: active ?? this.active,
    );
  }

  @override
  String toString() => 'Union(unionId: $unionId, name: $name, abbreviation: $abbreviation, countryId: $countryId, active: $active)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Union &&
        other.unionId == unionId &&
        other.name == name &&
        other.abbreviation == abbreviation &&
        other.countryId == countryId &&
        other.active == active;
  }

  @override
  int get hashCode => unionId.hashCode ^ name.hashCode ^ abbreviation.hashCode ^ countryId.hashCode ^ active.hashCode;
}
