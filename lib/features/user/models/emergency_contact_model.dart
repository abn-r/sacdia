class EmergencyContact {
  final int id;
  final String name;
  final String phone;
  final int relationshipTypeId;
  final String? relationshipTypeName;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationshipTypeId,
    this.relationshipTypeName,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    try {
      // Si tiene data, extraer la respuesta individual del array data
      if (json.containsKey('data') && json['data'] is List) {
        // Si tratamos de parsear la respuesta completa, devolver el primer contacto
        final List contactsList = json['data'];
        if (contactsList.isNotEmpty && contactsList[0] is Map<String, dynamic>) {
          return EmergencyContact.fromJson(contactsList[0]);
        }
      }

      return EmergencyContact(
        id: json['emergency_id'] as int? ?? json['id'] as int? ?? 0,
        name: json['name'] as String? ?? 'Sin nombre',
        phone: json['phone'] as String? ?? 'Sin teléfono',
        relationshipTypeId: json['relationship_type'] as int? ?? 
                          json['relationship_type_id'] as int? ?? 0,
        relationshipTypeName: json['relationship_type_name'] as String? ?? 
            (json['relationship'] != null && json['relationship'] is Map<String, dynamic> 
              ? json['relationship']['name'] as String? 
              : null),
      );
    } catch (e) {
      print('❌ Error al parsear contacto de emergencia: $e');
      print('JSON recibido: $json');
      return EmergencyContact(
        id: 0,
        name: 'Error de formato',
        phone: '',
        relationshipTypeId: 0,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'emergency_id': id,
      'name': name,
      'phone': phone,
      'relationship_type': relationshipTypeId,
      'relationship_type_name': relationshipTypeName,
    };
  }

  // Método estático para procesar una lista de contactos de la respuesta API
  static List<EmergencyContact> fromJsonList(dynamic json) {
    List<EmergencyContact> contacts = [];
    
    try {
      // Caso 1: La respuesta es un objeto con propiedad 'data' que contiene una lista
      if (json is Map<String, dynamic> && json.containsKey('data')) {
        if (json['data'] is List) {
          final List contactsList = json['data'];
          contacts = contactsList
              .map((contact) => EmergencyContact.fromJson(contact))
              .toList();
        }
      } 
      // Caso 2: La respuesta es directamente una lista
      else if (json is List) {
        contacts = json
            .map((contact) => EmergencyContact.fromJson(contact))
            .toList();
      }
    } catch (e) {
      print('❌ Error al procesar lista de contactos: $e');
    }
    
    return contacts;
  }
}

class RelationshipType {
  final int id;
  final String name;

  RelationshipType({
    required this.id,
    required this.name,
  });

  factory RelationshipType.fromJson(Map<String, dynamic> json) {
    try {
      return RelationshipType(
        id: json['relationship_type_id'] as int? ?? 
           json['relationship_type'] as int? ??
           json['id'] as int? ?? 0,
        name: json['relationship_type_name'] as String? ?? 
              json['name'] as String? ?? 'Desconocido',
      );
    } catch (e) {
      print('❌ Error al parsear tipo de relación: $e');
      print('JSON recibido: $json');
      return RelationshipType(
        id: 0,
        name: 'Error de formato',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'relationship_type': id,
      'name': name,
    };
  }
  
  // Método estático para procesar una lista de tipos de relación
  static List<RelationshipType> fromJsonList(dynamic json) {
    List<RelationshipType> types = [];
    
    try {
      // Caso 1: La respuesta es un objeto con propiedad 'data' que contiene una lista
      if (json is Map<String, dynamic> && json.containsKey('data')) {
        if (json['data'] is List) {
          final List typesList = json['data'];
          types = typesList
              .map((type) => RelationshipType.fromJson(type))
              .toList();
        }
      } 
      // Caso 2: La respuesta es directamente una lista
      else if (json is List) {
        types = json
            .map((type) => RelationshipType.fromJson(type))
            .toList();
      }
    } catch (e) {
      print('❌ Error al procesar lista de tipos de relación: $e');
    }
    
    return types;
  }
} 