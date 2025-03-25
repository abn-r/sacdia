import 'package:equatable/equatable.dart';

class Club extends Equatable {
  final int clubId;
  final String name;
  final int? localFieldId;
  
  const Club({
    required this.clubId,
    required this.name,
    this.localFieldId,
  });
  
  /// Crea una instancia de Club a partir de un objeto JSON
  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      clubId: json['club_id'] ?? 0,
      name: json['name'] ?? '',
      localFieldId: json['local_field_id'],
    );
  }
  
  /// Convierte esta instancia de Club a un objeto JSON
  Map<String, dynamic> toJson() {
    return {
      'club_id': clubId,
      'name': name,
      if (localFieldId != null) 'local_field_id': localFieldId,
    };
  }
  
  /// Crea una copia de esta instancia con los campos especificados modificados
  Club copyWith({
    int? clubId,
    String? name,
    int? localFieldId,
    bool clearLocalFieldId = false,
  }) {
    return Club(
      clubId: clubId ?? this.clubId,
      name: name ?? this.name,
      localFieldId: clearLocalFieldId ? null : (localFieldId ?? this.localFieldId),
    );
  }
  
  @override
  String toString() => 'Club(clubId: $clubId, name: $name, localFieldId: $localFieldId)';
  
  @override
  List<Object?> get props => [clubId, name, localFieldId];
}

class ClubType extends Equatable {
  final int clubTypeId;
  final String name;
  
  const ClubType({
    required this.clubTypeId,
    required this.name,
  });
  
  /// Crea una instancia de ClubType a partir de un objeto JSON
  factory ClubType.fromJson(Map<String, dynamic> json) {
    return ClubType(
      clubTypeId: json['ct_id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
  
  /// Convierte esta instancia de ClubType a un objeto JSON
  Map<String, dynamic> toJson() {
    return {
      'ct_id': clubTypeId,
      'name': name,
    };
  }
  
  /// Crea una copia de esta instancia con los campos especificados modificados
  ClubType copyWith({
    int? clubTypeId,
    String? name,
  }) {
    return ClubType(
      clubTypeId: clubTypeId ?? this.clubTypeId,
      name: name ?? this.name,
    );
  }
  
  @override
  String toString() => 'ClubType(clubTypeId: $clubTypeId, name: $name)';
  
  @override
  List<Object?> get props => [clubTypeId, name];
}

class Class extends Equatable {
  final int classId;
  final String name;
  final int? clubTypeId;
  
  const Class({
    required this.classId,
    required this.name,
    this.clubTypeId,
  });
  
  /// Crea una instancia de Class a partir de un objeto JSON
  factory Class.fromJson(Map<String, dynamic> json) {
    // Obtener clubTypeId desde diferentes ubicaciones posibles
    int? ctId;
    
    if (json.containsKey('club_types')) {
      final clubTypes = json['club_types'];
      
      // Verificar si es Map<String, dynamic> o similar
      if (clubTypes is Map) {
        // Intentar extraer ct_id como entero
        final rawCtId = clubTypes['ct_id'];
        if (rawCtId != null) {
          // Forzar conversión a entero si es necesario
          ctId = rawCtId is int ? rawCtId : int.tryParse(rawCtId.toString());
          print('📋 Extrayendo ctId de club_types: $ctId');
        }
      }
    } else if (json.containsKey('ct_id')) {
      // Si viene directamente como ct_id
      final rawCtId = json['ct_id'];
      ctId = rawCtId is int ? rawCtId : int.tryParse(rawCtId.toString());
      print('📋 Extrayendo ctId directo: $ctId');
    } else if (json.containsKey('club_type_id')) {
      // Alternativa con nombre completo
      final rawCtId = json['club_type_id'];
      ctId = rawCtId is int ? rawCtId : int.tryParse(rawCtId.toString());
      print('📋 Extrayendo club_type_id: $ctId');
    }
    
    final result = Class(
      classId: json['class_id'] ?? 0,
      name: json['name'] ?? '',
      clubTypeId: ctId,
    );
    
    print('🔄 Clase ${result.name} creada con clubTypeId: ${result.clubTypeId}');
    return result;
  }
  
  /// Convierte esta instancia de Class a un objeto JSON
  Map<String, dynamic> toJson() {
    return {
      'class_id': classId,
      'name': name,
      if (clubTypeId != null) 'ct_id': clubTypeId,
    };
  }
  
  /// Crea una copia de esta instancia con los campos especificados modificados
  Class copyWith({
    int? classId,
    String? name,
    int? clubTypeId,
    bool clearClubTypeId = false,
  }) {
    return Class(
      classId: classId ?? this.classId,
      name: name ?? this.name,
      clubTypeId: clearClubTypeId ? null : (clubTypeId ?? this.clubTypeId),
    );
  }
  
  @override
  String toString() => 'Class(classId: $classId, name: $name, clubTypeId: $clubTypeId)';
  
  @override
  List<Object?> get props => [classId, name, clubTypeId];
} 