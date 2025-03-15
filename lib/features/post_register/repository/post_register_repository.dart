import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:sacdia/features/post_register/models/allergy_model.dart';
import 'package:sacdia/features/post_register/models/personal_info_user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;
import 'package:sacdia/core/constants.dart';
import 'package:sacdia/features/post_register/models/disease_model.dart';
import 'package:sacdia/features/post_register/models/emergency_contact.dart';
import 'package:sacdia/features/post_register/models/user_allergies_model.dart';
import 'package:sacdia/features/post_register/models/user_diseases_model.dart';

abstract class IPostRegisterRepository {
  Future<String> uploadProfilePicture(File photo);
  Future<void> updateUserInfo(PersonalInfoUser user);
  Future<List<Disease>> getDiseases();
  Future<List<Allergy>> getAllergies();
  Future<List<EmergencyContact>> getEmergencyContacts();
  Future<List<RelationshipType>> getRelationshipTypes();
  Future<EmergencyContact> addEmergencyContact(
      String name, String phone, int? relationshipTypeId);
}

class PostRegisterRepository implements IPostRegisterRepository {
  final Dio dio;
  final SupabaseClient supabaseClient;

  PostRegisterRepository({
    required this.dio,
    required this.supabaseClient,
  });

  String? _getToken() {
    return supabaseClient.auth.currentSession?.accessToken;
  }

  String? _getUserId() {
    return supabaseClient.auth.currentUser?.id;
  }

  // Método para validar que el usuario esté autenticado
  void _validateAuthentication() {
    final userId = _getUserId();
    if (userId == null) throw Exception('Usuario no autenticado');
  }

  // Método para obtener headers de autenticación
  Map<String, String> _getAuthHeaders({bool isMultipart = false}) {
    final token = _getToken();
    if (token == null) throw Exception('No hay sesión activa válida');

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': isMultipart ? 'multipart/form-data' : 'application/json',
    };

    return headers;
  }

  // *****************************************************
  // Upload Photo
  // *****************************************************
  @override
  Future<String> uploadProfilePicture(File photo) async {
    try {
      final userId = _getUserId();
      _validateAuthentication();

      final String fileName = photo.path.split('/').last;

      final FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          photo.path,
          filename: fileName,
          contentType: MediaType('image', photo.path.split('.').last),
        ),
      });

      final response = await dio.post(
        '$api/fu/pp/$userId',
        data: formData,
        options: Options(
          headers: _getAuthHeaders(isMultipart: true),
        ),
      );

      return response.data['url'] ?? '';
    } catch (e) {
      throw Exception('Error al subir la foto: ${e.toString()}');
    }
  }

  // *****************************************************
  // Personal Info
  // *****************************************************

  @override
  Future<void> updateUserInfo(PersonalInfoUser user) async {
    print('updateUserInfo');
    try {
      final userId = _getUserId();
      _validateAuthentication();

      final String nonNullUserId = userId!;
      print('nonNullUserId: $nonNullUserId');

      final dataUser = {
        'gender': user.gender,
        'birth_date': user.birthDate?.toIso8601String(),
        'is_baptized': user.isBaptized,
        'baptism_date': user.baptismDate?.toIso8601String(),
      };
      print('dataUser: $dataUser');

      final bool hasNoneDisease =
          user.diseases.any((disease) => disease.diseaseId == 0);
      final bool hasNoneAllergy =
          user.allergies.any((allergy) => allergy.allergyId == 0);

      final List<Map<String, dynamic>> diseasesArray = !hasNoneDisease
          ? user.diseases
              .map((disease) => UserDiseases(
                    userId: nonNullUserId,
                    diseaseId: disease.diseaseId,
                  ).toJson())
              .toList()
          : [];

      final List<Map<String, dynamic>> allergiesArray = !hasNoneAllergy
          ? user.allergies
              .map((allergy) => UserAllergies(
                    userId: nonNullUserId,
                    allergyId: allergy.allergyId,
                  ).toJson())
              .toList()
          : [];

      print('dataUser: $dataUser');
      print('¿Tiene opción Ninguna en enfermedades?: $hasNoneDisease');
      print('¿Tiene opción Ninguna en alergias?: $hasNoneAllergy');
      print('diseasesArray: $diseasesArray');
      print('allergiesArray: $allergiesArray');

      try {
        print('Enviando datos del usuario a: $api/users/$nonNullUserId');
        final response = await dio.put(
          '$api/users/$nonNullUserId',
          data: dataUser,
          options: Options(
            headers: _getAuthHeaders(),
          ),
        );
        print('Respuesta actualizar usuario: ${response.statusCode}');

        if (!hasNoneDisease && diseasesArray.isNotEmpty) {
          try {
            print('Enviando enfermedades a: $api/u/diseases/many');
            print('diseasesArray: $diseasesArray');
            final responseDiseases = await dio.post(
              '$api/u/diseases/many',
              data: diseasesArray,
              options: Options(
                headers: _getAuthHeaders(),
              ),
            );
            print('Respuesta al guardar enfermedades: ${responseDiseases.statusCode}');
          } catch (e) {
            print('Error al guardar enfermedades: ${e.toString()}');
            try {
              print('Intentando ruta alternativa: $api/u/diseases');
              final responseDiseases = await dio.post(
                '$api/u/diseases',
                data: diseasesArray,
                options: Options(
                  headers: _getAuthHeaders(),
                ),
              );
              print('Respuesta al guardar enfermedades (ruta alternativa): ${responseDiseases.statusCode}');
            } catch (altE) {
              print('Error también en ruta alternativa: ${altE.toString()}');
            }
          }
        } else {
          print('No se guardan enfermedades porque el usuario seleccionó "Ninguna" o no seleccionó ninguna opción');
        }

        // Actualizar las alergias del usuario solo si no seleccionó "Ninguna"
        if (!hasNoneAllergy && allergiesArray.isNotEmpty) {
          try {
            print('Enviando alergias a: $api/u/allergies/many');
            print('allergiesArray: $allergiesArray');
            final responseAllergies = await dio.post(
              '$api/u/allergies/many',
              data: allergiesArray,
              options: Options(
                headers: _getAuthHeaders(),
              ),
            );
            print('Respuesta al guardar alergias: ${responseAllergies.statusCode}');
          } catch (e) {
            print('Error al guardar alergias: ${e.toString()}');
            // Intentar ruta alternativa sin /many
            try {
              print('Intentando ruta alternativa: $api/u/allergies');
              final responseAllergies = await dio.post(
                '$api/u/allergies',
                data: allergiesArray,
                options: Options(
                  headers: _getAuthHeaders(),
                ),
              );
              print('Respuesta al guardar alergias (ruta alternativa): ${responseAllergies.statusCode}');
            } catch (altE) {
              print('Error también en ruta alternativa: ${altE.toString()}');
            }
          }
        } else {
          print('No se guardan alergias porque el usuario seleccionó "Ninguna" o no seleccionó ninguna opción');
        }

        if (response.statusCode != 200) {
          throw Exception(response.data['message'] ?? 'Error al actualizar usuario');
        }
      } catch (apiError) {
        print('Error específico de API: ${apiError.toString()}');
        // Si el error es 404, podría ser un problema de ruta
        if (apiError.toString().contains('404')) {
          throw Exception('La URL solicitada no existe. Verifica que los endpoints estén configurados correctamente. + ${apiError.toString()}');
        }
        // Reenviar la excepción original
        throw apiError;
      }
    } catch (e) {
      print('Error detallado: ${e.toString()}');
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<List<Disease>> getDiseases() async {
    try {
      final response = await dio.get(
        '$api/c/diseases',
        queryParameters: {'take': 100},
        options: Options(
          headers: _getAuthHeaders(),
        ),
      );

      if (response.statusCode == 200) {
        if (response.data is List) {
          final List diseasesList = response.data;

          return diseasesList.map((item) {
            if (item is Map<String, dynamic>) {
              return Disease.fromJson(item);
            } else {
              return Disease(diseaseId: 0, name: item.toString());
            }
          }).toList();
        }
        return [];
      }
      throw Exception('Error al obtener enfermedades');
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<List<Allergy>> getAllergies() async {
    try {
      final response = await dio.get(
        '$api/c/allergies',
        queryParameters: {'take': 100},
        options: Options(
          headers: _getAuthHeaders(),
        ),
      );

      if (response.statusCode == 200) {
        if (response.data is List) {
          final List allergiesList = response.data;

          return allergiesList.map((item) {
            if (item is Map<String, dynamic>) {
              return Allergy.fromJson(item);
            } else {
              return Allergy(allergyId: 0, name: item.toString());
            }
          }).toList();
        }
        return [];
      }
      throw Exception('Error al obtener alergias');
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<List<EmergencyContact>> getEmergencyContacts() async {
    final userId = _getUserId();
    _validateAuthentication();

    try {
      final response = await dio.get(
        '$api/u/emergency_contact/all',
        queryParameters: {'userId': userId},
        options: Options(
          headers: _getAuthHeaders(),
        ),
      );

      print('getEmergencyContacts - Respuesta completa:');
      print(response.data);

      if (response.statusCode == 200) {
        // Verificar si la respuesta es un mapa con propiedad emergency_contacts
        if (response.data is Map<String, dynamic> &&
            response.data.containsKey('emergency_contacts')) {
          final List contactsList = response.data['emergency_contacts'];
          print(
              'getEmergencyContacts - Encontrados ${contactsList.length} contactos dentro de emergency_contacts');

          return contactsList.map((item) {
            if (item is Map<String, dynamic>) {
              print(
                  'getEmergencyContacts - Procesando contacto: ${item['name']}');
              return EmergencyContact.fromJson(item);
            } else {
              print('getEmergencyContacts - Item no es un mapa: $item');
              return EmergencyContact(
                emergencyId: 0,
                name: item.toString(),
                phone: '0000000000',
              );
            }
          }).toList();
        }
        // Mantener el caso de una lista directa por compatibilidad
        else if (response.data is List) {
          final List contactsList = response.data;
          print(
              'getEmergencyContacts - Respuesta directa como lista: ${contactsList.length} contactos');

          return contactsList.map((item) {
            if (item is Map<String, dynamic>) {
              return EmergencyContact.fromJson(item);
            } else {
              return EmergencyContact(
                emergencyId: 0,
                name: item.toString(),
                phone: '0000000000',
              );
            }
          }).toList();
        }
        // Si no es ninguno de los formatos esperados
        print(
            'getEmergencyContacts - Formato de respuesta no reconocido: ${response.data.runtimeType}');
        return [];
      }
      throw Exception('Error al obtener contactos de emergencia');
    } catch (e) {
      print('Error al obtener contactos de emergencia: ${e.toString()}');
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<List<RelationshipType>> getRelationshipTypes() async {
    try {
      final response = await dio.get(
        '$api/c/relationship_types',
        options: Options(
          headers: _getAuthHeaders(),
        ),
      );

      if (response.statusCode == 200) {
        // Verificar si la respuesta es un mapa con una propiedad 'data'
        if (response.data is Map<String, dynamic> &&
            response.data.containsKey('data')) {
          // Extraer la lista de 'data'
          final List typesList = response.data['data'];
          final resultList = typesList.map((item) {
            if (item is Map<String, dynamic>) {
              return RelationshipType.fromJson(item);
            } else {
              return RelationshipType(
                relationshipTypeId: 0,
                name: item.toString(),
              );
            }
          }).toList();

          return resultList;
        } else if (response.data is List) {
          final List typesList = response.data;

          final resultList = typesList.map((item) {
            if (item is Map<String, dynamic>) {
              return RelationshipType.fromJson(item);
            } else {
              return RelationshipType(
                relationshipTypeId: 0,
                name: item.toString(),
              );
            }
          }).toList();

          return resultList;
        } else {
          print(
              'getRelationshipTypes - Formato de respuesta no reconocido: ${response.data.runtimeType}');
          return [];
        }
      }

      throw Exception(
          'Error al obtener tipos de relación: Código ${response.statusCode}');
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<EmergencyContact> addEmergencyContact(
      String name, String phone, int? relationshipTypeId) async {
    final userId = _getUserId();
    _validateAuthentication();

    // Validar que los datos necesarios estén presentes
    if (name.isEmpty) {
      throw Exception('El nombre no puede estar vacío');
    }
    if (phone.isEmpty) {
      throw Exception('El teléfono no puede estar vacío');
    }
    if (relationshipTypeId == null) {
      throw Exception('Debe seleccionar un tipo de relación');
    }

    try {
      print(
          '📞 Enviando solicitud para agregar contacto: $name, $phone, tipo=$relationshipTypeId, usuario=$userId');

      final response = await dio.post(
        '$api/u/emergency_contact/',
        data: {
          'name': name,
          'phone': phone,
          'relationship_type': relationshipTypeId,
          'owner_id': userId,
        },
        queryParameters: {'user_id': userId},
        options: Options(
          headers: _getAuthHeaders(),
        ),
      );

      print(
          '🟢 Respuesta del servidor (${response.statusCode}): ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Extraer correctamente los datos del contacto de la respuesta
        final contactData = response.data;

        // Verificar si la respuesta contiene un objeto 'data' anidado
        if (contactData is Map<String, dynamic> &&
            contactData.containsKey('data')) {
          print('🔍 La respuesta contiene un objeto data anidado');
          // Crear el contacto desde el objeto data anidado
          final EmergencyContact contact = EmergencyContact(
            emergencyId: contactData['data']['emergency_id'],
            name: contactData['data']['name'],
            phone: contactData['data']['phone'],
            relationship: contactData['data']['relationship_type'],
          );
          print(
              '✅ Contacto creado exitosamente: ${contact.name}, ID: ${contact.emergencyId}');
          return contact;
        } else {
          // Si no hay objeto data anidado, usar la estructura directa
          print('🆕 Usando estructura directa para crear el contacto');
          return EmergencyContact.fromJson(contactData);
        }
      }

      print('🔴 Error al registrar contacto: Código ${response.statusCode}');
      throw Exception(
          'Error al registrar contacto de emergencia: Código ${response.statusCode}');
    } catch (e) {
      print('❌ Excepción al agregar contacto: ${e.toString()}');
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }
}
