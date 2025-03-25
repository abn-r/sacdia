class LocalField {
  final int localFieldId;
  final String name;
  final String abbreviation;
  final int unionId;
  final bool active;

  const LocalField({
    required this.localFieldId,
    required this.name,
    required this.abbreviation,
    required this.unionId,
    this.active = true,
  });

  /// Crea una instancia de LocalField a partir de un objeto JSON
  factory LocalField.fromJson(Map<String, dynamic> json) {
    // Extraer unionId que puede estar anidado dentro del objeto 'unions'
    int extractedUnionId = 0;
    
    if (json.containsKey('union_id')) {
      // Si union_id está directamente en el objeto principal
      extractedUnionId = json['union_id'] ?? 0;
    } else if (json.containsKey('unions') && json['unions'] is Map<String, dynamic>) {
      // Si union_id está anidado dentro del objeto 'unions'
      extractedUnionId = json['unions']['union_id'] ?? 0;
    }
    
    return LocalField(
      localFieldId: json['local_field_id'] ?? 0,
      name: json['name'] ?? '',
      abbreviation: json['abbreviation'] ?? '',
      unionId: extractedUnionId,
      active: json['active'] ?? true,
    );
  }

  /// Convierte esta instancia de LocalField a un objeto JSON
  Map<String, dynamic> toJson() {
    return {
      'local_field_id': localFieldId,
      'name': name,
      'abbreviation': abbreviation,
      'union_id': unionId,
      'active': active,
    };
  }

  /// Crea una copia de esta instancia con los campos especificados modificados
  LocalField copyWith({
    int? localFieldId,
    String? name,
    String? abbreviation,
    int? unionId,
    bool? active,
  }) {
    return LocalField(
      localFieldId: localFieldId ?? this.localFieldId,
      name: name ?? this.name,
      abbreviation: abbreviation ?? this.abbreviation,
      unionId: unionId ?? this.unionId,
      active: active ?? this.active,
    );
  }

  @override
  String toString() => 'LocalField(localFieldId: $localFieldId, name: $name, abbreviation: $abbreviation, unionId: $unionId, active: $active)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocalField &&
        other.localFieldId == localFieldId &&
        other.name == name &&
        other.abbreviation == abbreviation &&
        other.unionId == unionId &&
        other.active == active;
  }

  @override
  int get hashCode => localFieldId.hashCode ^ name.hashCode ^ abbreviation.hashCode ^ unionId.hashCode ^ active.hashCode;
}
