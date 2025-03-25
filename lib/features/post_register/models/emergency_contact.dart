class EmergencyContact {
  final int emergencyId;
  final String name;
  final String phone;
  final int? relationship;

  EmergencyContact({
    required this.emergencyId,
    required this.name,
    required this.phone,
    this.relationship,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    try {
      // Verificar si hay un objeto 'data' anidado y usarlo si existe
      final Map<String, dynamic> data = json.containsKey('data') && json['data'] is Map<String, dynamic> 
          ? json['data'] as Map<String, dynamic>
          : json;
      
      return EmergencyContact(
        emergencyId: data['emergency_id'] is int ? data['emergency_id'] : 0,
        name: data['name']?.toString() ?? 'Sin nombre',
        phone: data['phone']?.toString() ?? '0000000000',
        relationship: data['relationship_type'] is int ? data['relationship_type'] : null,
      );
    } catch (e) {
      print('❌ Error al procesar JSON para EmergencyContact: $e');
      print('JSON problemático: $json');
      // Devolver un objeto vacío en caso de error
      return EmergencyContact(
        emergencyId: 0,
        name: 'Error de procesamiento',
        phone: '0000000000',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'emergency_id': emergencyId,
      'name': name,
      'phone': phone,
      'relationship_type': relationship,
    };
  }
}

class RelationshipType {
  final int relationshipTypeId;
  final String name;

  RelationshipType({
    required this.relationshipTypeId,
    required this.name,
  });

  factory RelationshipType.fromJson(Map<String, dynamic> json) {
    try {
      return RelationshipType(
        relationshipTypeId: json['relationship_type_id'] is int ? json['relationship_type_id'] : 0,
        name: json['name']?.toString() ?? 'Desconocido',
      );
    } catch (e) {
      print('❌ Error al procesar JSON para RelationshipType: $e');
      return RelationshipType(
        relationshipTypeId: 0,
        name: 'Error',
      );
    }
  }
}
