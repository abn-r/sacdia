import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:sacdia/core/catalogs/models/country.dart';
import 'package:sacdia/core/catalogs/models/local_field.dart';
import 'package:sacdia/core/catalogs/models/union.dart';
import 'package:sacdia/core/http/api_client.dart';
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
  Future<void> addUserClubInfo(int countryId, int unionId,
      int localFieldId, int clubId, int classId);
  Future<List<Country>> getCountries();
  Future<List<Union>> getUnions(int countryId);
  Future<List<LocalField>> getLocalFields(int unionId);
  Future<List<dynamic>> getClubs(int localFieldId);
}

class PostRegisterRepository implements IPostRegisterRepository {
  final Dio _dio;
  final SupabaseClient _supabaseClient;

  PostRegisterRepository({
    Dio? dio,
    SupabaseClient? supabaseClient,
  })  : _dio = dio ?? ApiClient().dio,
        _supabaseClient = supabaseClient ?? Supabase.instance.client;

  String? _getToken() {
    return _supabaseClient.auth.currentSession?.accessToken;
  }

  String? _getUserId() {
    return _supabaseClient.auth.currentUser?.id;
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

  // Método para realizar una solicitud HTTP segura con reintentos
  Future<Response<T>> _safeApiCall<T>({
    required Future<Response<T>> Function() apiCall,
    String errorMessage = 'Error en la solicitud HTTP',
    bool retryOnError = false,
    int maxRetries = 1,
  }) async {
    int attempts = 0;

    while (attempts <= maxRetries) {
      try {
        final response = await apiCall();

        // Verificar códigos de estado HTTP
        if (response.statusCode == 401) {
          // Error de autenticación - posiblemente token vencido
          throw Exception(
              'Sesión expirada. Por favor, inicie sesión nuevamente.');
        } else if (response.statusCode == 404) {
          // Recurso no encontrado
          throw Exception(
              'El recurso solicitado no existe: ${response.requestOptions.path}');
        } else if (response.statusCode == 409) {
          // Conflicto - Extraer mensaje específico de la API
          final String message = response.data is Map<String, dynamic>
              ? (response.data as Map<String, dynamic>)['message'] ??
                  'El usuario ya está registrado en este club o existe un conflicto'
              : 'El usuario ya está registrado en este club o existe un conflicto';
          throw Exception(message);
        } else if (response.statusCode != null && response.statusCode! >= 400) {
          // Otros errores HTTP
          final String message = response.data is Map<String, dynamic>
              ? (response.data as Map<String, dynamic>)['message'] ??
                  errorMessage
              : errorMessage;
          throw Exception('$errorMessage: ${response.statusCode} - $message');
        }

        return response;
      } catch (e) {
        attempts++;

        // Si ya intentamos el máximo de veces o no queremos reintentar, propagamos el error
        if (attempts > maxRetries || !retryOnError) {
          print('$errorMessage: ${e.toString()}');
          rethrow;
        }

        // Esperar antes de reintentar
        await Future.delayed(Duration(milliseconds: 500 * attempts));
        print('Reintentando solicitud (${attempts}/${maxRetries})...');
      }
    }

    // Nunca debería llegar aquí, pero TypeScript necesita un return
    throw Exception('Error inesperado en la solicitud HTTP');
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

      final response = await _safeApiCall(
        apiCall: () => _dio.post(
          '$api/fu/pp/$userId',
          data: formData,
          options: Options(headers: _getAuthHeaders(isMultipart: true)),
        ),
        errorMessage: 'Error al subir la foto',
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
    try {
      final userId = _getUserId();
      _validateAuthentication();

      final String nonNullUserId = userId!;

      final dataUser = {
        'gender': user.gender,
        'birthday': user.birthDate?.toIso8601String(),
        'baptism': user.isBaptized,
        'baptism_date': user.baptismDate?.toIso8601String(),
        'blood_type': user.bloodType,
      };

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

      // Actualizar información del usuario
      await _safeApiCall(
        apiCall: () => _dio.patch(
          '$api/users/$nonNullUserId',
          data: dataUser,
          options: Options(
            headers: _getAuthHeaders(),
            validateStatus: (status) => true,
          ),
        ),
        errorMessage: 'Error al actualizar usuario',
      );

      print('✅ Actualización de usuario completada con éxito');

      if (!hasNoneDisease && diseasesArray.isNotEmpty) {
        try {
          await _safeApiCall(
            apiCall: () => _dio.post(
              '$api/u/diseases/many',
              data: diseasesArray,
              options: Options(
                headers: _getAuthHeaders(),
                validateStatus: (status) => true,
              ),
            ),
            errorMessage: 'Error al guardar enfermedades',
          );

          print('✅ Enfermedades guardadas exitosamente');
        } catch (e) {
          print('Error al guardar enfermedades: ${e.toString()}');
          // No propagamos este error para que no afecte el flujo principal
        }
      } else {
        print(
            'No se guardan enfermedades porque el usuario seleccionó "Ninguna" o no seleccionó ninguna opción');
      }

      if (!hasNoneAllergy && allergiesArray.isNotEmpty) {
        try {
          await _safeApiCall(
            apiCall: () => _dio.post(
              '$api/u/allergies/many',
              data: allergiesArray,
              options: Options(
                headers: _getAuthHeaders(),
                validateStatus: (status) => true,
              ),
            ),
            errorMessage: 'Error al guardar alergias',
          );

          print('✅ Alergias guardadas exitosamente');
        } catch (e) {
          print('Error al guardar alergias: ${e.toString()}');
          // No propagamos este error para que no afecte el flujo principal
        }
      } else {
        print(
            'No se guardan alergias porque el usuario seleccionó "Ninguna" o no seleccionó ninguna opción');
      }

      return;
    } catch (e) {
      print('Error detallado en updateUserInfo: ${e.toString()}');
      throw Exception(
          'Error al actualizar información del usuario: ${e.toString()}');
    }
  }

  @override
  Future<List<Disease>> getDiseases() async {
    try {
      final response = await _safeApiCall(
        apiCall: () => _dio.get(
          '$api/c/diseases',
          queryParameters: {'take': 100},
          options: Options(headers: _getAuthHeaders()),
        ),
        errorMessage: 'Error al obtener enfermedades',
      );

      // Verificar si la respuesta es un mapa con una propiedad 'data'
      if (response.data is Map<String, dynamic>) {
        if (response.data.containsKey('data')) {
          final List diseasesList = response.data['data'];

          return diseasesList.map((item) {
            if (item is Map<String, dynamic>) {
              return Disease.fromJson(item);
            } else {
              return Disease(diseaseId: 0, name: item.toString());
            }
          }).toList();
        }
      }
      // Mantener compatibilidad con respuesta de lista directa
      else if (response.data is List) {
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
    } catch (e) {
      print('Error al obtener enfermedades: ${e.toString()}');
      // Retornamos lista vacía en lugar de propagar el error
      return [];
    }
  }

  @override
  Future<List<Allergy>> getAllergies() async {
    try {
      final response = await _safeApiCall(
        apiCall: () => _dio.get(
          '$api/c/allergies',
          queryParameters: {'take': 100},
          options: Options(headers: _getAuthHeaders()),
        ),
        errorMessage: 'Error al obtener alergias',
      );

      // Verificar si la respuesta es un mapa con una propiedad 'data'
      if (response.data is Map<String, dynamic>) {
        if (response.data.containsKey('data')) {
          final List allergiesList = response.data['data'];
          print(
              '📊 Procesando ${allergiesList.length} alergias desde campo data');

          return allergiesList.map((item) {
            if (item is Map<String, dynamic>) {
              return Allergy.fromJson(item);
            } else {
              return Allergy(allergyId: 0, name: item.toString());
            }
          }).toList();
        }
      }
      // Mantener compatibilidad con respuesta de lista directa
      else if (response.data is List) {
        final List allergiesList = response.data;
        print(
            '📊 Procesando ${allergiesList.length} alergias desde lista directa');

        return allergiesList.map((item) {
          if (item is Map<String, dynamic>) {
            return Allergy.fromJson(item);
          } else {
            return Allergy(allergyId: 0, name: item.toString());
          }
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error al obtener alergias: ${e.toString()}');
      // Retornamos lista vacía en lugar de propagar el error
      return [];
    }
  }

  @override
  Future<List<EmergencyContact>> getEmergencyContacts() async {
    try {
      final userId = _getUserId();
      _validateAuthentication();

      final response = await _safeApiCall(
        apiCall: () => _dio.get(
          '$api/u/emergency-contacts/all',
          queryParameters: {'userId': userId},
          options: Options(headers: _getAuthHeaders()),
        ),
        errorMessage: 'Error al obtener contactos de emergencia',
      );

      // Verificar si la respuesta es un mapa con propiedad 'data'
      if (response.data is Map<String, dynamic>) {
        if (response.data.containsKey('data')) {
          final List contactsList = response.data['data'];

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
        } else if (response.data.containsKey('emergency_contacts')) {
          final List contactsList = response.data['emergency_contacts'];

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
      }
      // Mantener el caso de una lista directa por compatibilidad
      else if (response.data is List) {
        final List contactsList = response.data;

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
      return [];
    } catch (e) {
      print('Error al obtener contactos de emergencia: ${e.toString()}');
      // Retornamos lista vacía en lugar de propagar el error
      return [];
    }
  }

  @override
  Future<List<RelationshipType>> getRelationshipTypes() async {
    try {
      final response = await _safeApiCall(
        apiCall: () => _dio.get(
          '$api/c/relationship_types',
          options: Options(headers: _getAuthHeaders()),
        ),
        errorMessage: 'Error al obtener tipos de relación',
      );

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
        return [];
      }
    } catch (e) {
      print('Error al obtener tipos de relación: ${e.toString()}');
      // Retornamos lista vacía en lugar de propagar el error
      return [];
    }
  }

  @override
  Future<EmergencyContact> addEmergencyContact(
      String name, String phone, int? relationshipTypeId) async {
    try {
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

      final response = await _safeApiCall(
        apiCall: () => _dio.post(
          '$api/u/emergency_contact/',
          data: {
            'name': name,
            'phone': phone,
            'relationship_type': relationshipTypeId,
            'owner_id': userId,
          },
          queryParameters: {'user_id': userId},
          options: Options(headers: _getAuthHeaders()),
        ),
        errorMessage: 'Error al registrar contacto de emergencia',
        retryOnError: true, // Intentar nuevamente en caso de error
      );

      final contactData = response.data;

      // Verifica si la respuesta contiene un objeto 'data' anidado
      if (contactData is Map<String, dynamic> &&
          contactData.containsKey('data')) {
        // Crear el contacto desde el objeto data anidado
        final EmergencyContact contact = EmergencyContact(
          emergencyId: contactData['data']['emergency_id'],
          name: contactData['data']['name'],
          phone: contactData['data']['phone'],
          relationship: contactData['data']['relationship_type'],
        );
        return contact;
      } else {
        // Si no hay objeto data anidado, usar la estructura directa
        return EmergencyContact.fromJson(contactData);
      }
    } catch (e) {
      print('Error al agregar contacto de emergencia: ${e.toString()}');
      rethrow; // Aquí sí propagamos el error porque es una acción explícita del usuario
    }
  }

  // *****************************************************
  // Club Info
  // *****************************************************

  @override
  Future<void> addUserClubInfo(int countryId, int unionId,
      int localFieldId, int clubId, int classId) async {
    print('Agregando información de club y clase al usuario');
    print('countryId: $countryId');
    print('unionId: $unionId');
    print('localFieldId: $localFieldId');
    print('clubId: $clubId');
    print('classId: $classId');

    try {
      final userId = _getUserId();
      _validateAuthentication();

      final String nonNullUserId = userId!;

      final dataUser = {
        'country_id': int.parse(countryId.toString()),
        'union_id': int.parse(unionId.toString()),
        'local_field_id': int.parse(localFieldId.toString()),
        'club_id': int.parse(clubId.toString()),
      };

      final dataClub = {
        'user_id': nonNullUserId,
        'club_id': int.parse(clubId.toString()),
      };

      final dataClass = {
        'user_id': nonNullUserId,
        'class_id': int.parse(classId.toString()),
      };

      // PASO 1: Actualizar información del usuario
      print('🔄 Actualizando información básica del usuario...');
      await _safeApiCall(
        apiCall: () => _dio.patch(
          '$api/users/$nonNullUserId',
          data: dataUser,
          options: Options(
            headers: _getAuthHeaders(),
            validateStatus: (status) => status! < 500,
          ),
        ),
        errorMessage: 'Error al actualizar usuario',
      );
      print('✅ Información del usuario actualizada exitosamente');

      // PASO 2: Agregar usuario a club
      print('🔄 Registrando usuario en club...');
      try {
        await _safeApiCall(
          apiCall: () => _dio.post(
            '$api/u/users-clubs/add/',
            data: dataClub,
            options: Options(
              headers: _getAuthHeaders(),
              // No validamos aquí para poder capturar el error específico
              validateStatus: null,
            ),
          ),
          errorMessage: 'Error al agregar usuario a club',
        );
        print('✅ Usuario agregado al club exitosamente');
      } catch (e) {
        // Si el error es porque el usuario ya está en el club, continuamos con el proceso
        if (e.toString().contains('ya está registrado') || 
            e.toString().contains('already exists')) {
          print('⚠️ El usuario ya está registrado en este club. Continuando con el proceso...');
        } else {
          // Para otros errores, propagamos la excepción
          rethrow;
        }
      }

      // PASO 3: Agregar usuario a clase
      print('🔄 Registrando usuario en clase...');
      try {
        await _safeApiCall(
          apiCall: () => _dio.post(
            '$api/u/users-classes/add/',
            data: dataClass,
            options: Options(
              headers: _getAuthHeaders(),
              // No validamos aquí para poder capturar el error específico
              validateStatus: null,
            ),
          ),
          errorMessage: 'Error al agregar usuario a clase',
        );
        print('✅ Usuario agregado a la clase exitosamente');
      } catch (e) {
        // Si el error es porque el usuario ya está en la clase, continuamos
        if (e.toString().contains('ya está registrado') || 
            e.toString().contains('already exists')) {
          print('⚠️ El usuario ya está registrado en esta clase. Continuando con el proceso...');
        } else {
          // Para otros errores, propagamos la excepción
          rethrow;
        }
      }

      return;
    } catch (e) {
      print('❌ Error al actualizar información del club: ${e.toString()}');
      throw Exception(e.toString());
    }
  }

  // *****************************************************
  // Métodos para obtener catálogos geográficos
  // *****************************************************
  
  @override
  Future<List<Country>> getCountries() async {
    try {
      final response = await _safeApiCall(
        apiCall: () => _dio.get(
          '$api/c/countries',
          options: Options(headers: _getAuthHeaders()),
        ),
        errorMessage: 'Error al obtener países',
      );
      
      // Verificar si la respuesta es un mapa con una propiedad 'data'
      if (response.data is Map<String, dynamic>) {
        if (response.data.containsKey('data')) {
          final List countriesList = response.data['data'];
          print('📊 Procesando ${countriesList.length} países desde campo data');
          
          return countriesList.map((item) {
            if (item is Map<String, dynamic>) {
              return Country.fromJson(item);
            } else {
              return Country(
                countryId: 0,
                name: item.toString(),
                abbreviation: '',
              );
            }
          }).toList();
        }
      }
      // Mantener compatibilidad con respuesta de lista directa
      else if (response.data is List) {
        final List countriesList = response.data;
        print('📊 Procesando ${countriesList.length} países desde lista directa');
        
        return countriesList.map((item) {
          if (item is Map<String, dynamic>) {
            return Country.fromJson(item);
          } else {
            return Country(
              countryId: 0,
              name: item.toString(),
              abbreviation: '',
            );
          }
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error al obtener países: ${e.toString()}');
      // Retornamos lista vacía en lugar de propagar el error
      return [];
    }
  }

  @override
  Future<List<Union>> getUnions(int countryId) async {
    try {
      final response = await _safeApiCall(
        apiCall: () => _dio.get(
          '$api/c/unions',
          queryParameters: {'where': '{"country_id": $countryId}'},
          options: Options(headers: _getAuthHeaders()),
        ),
        errorMessage: 'Error al obtener uniones',
      );
      
      // Verificar si la respuesta es un mapa con una propiedad 'data'
      if (response.data is Map<String, dynamic>) {
        if (response.data.containsKey('data')) {
          final List unionsList = response.data['data'];
          print('📊 Procesando ${unionsList.length} uniones desde campo data');
          
          return unionsList.map((item) {
            if (item is Map<String, dynamic>) {
              return Union.fromJson(item);
            } else {
              return Union(
                unionId: 0,
                name: item.toString(),
                abbreviation: '',
                countryId: countryId,
              );
            }
          }).toList();
        }
      }
      // Mantener compatibilidad con respuesta de lista directa
      else if (response.data is List) {
        final List unionsList = response.data;
        print('📊 Procesando ${unionsList.length} uniones desde lista directa');
        
        return unionsList.map((item) {
          if (item is Map<String, dynamic>) {
            return Union.fromJson(item);
          } else {
            return Union(
              unionId: 0,
              name: item.toString(),
              abbreviation: '',
              countryId: countryId,
            );
          }
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error al obtener uniones: ${e.toString()}');
      // Retornamos lista vacía en lugar de propagar el error
      return [];
    }
  }

  @override
  Future<List<LocalField>> getLocalFields(int unionId) async {
    try {
      final response = await _safeApiCall(
        apiCall: () => _dio.get(
          '$api/c/lf',
          queryParameters: {'where': '{"union_id": $unionId}'},
          options: Options(headers: _getAuthHeaders()),
        ),
        errorMessage: 'Error al obtener campos locales',
      );
      
      // Verificar si la respuesta es un mapa con una propiedad 'data'
      if (response.data is Map<String, dynamic>) {
        if (response.data.containsKey('data')) {
          final List localFieldsList = response.data['data'];
          print('📊 Procesando ${localFieldsList.length} campos locales desde campo data');
          
          return localFieldsList.map((item) {
            if (item is Map<String, dynamic>) {
              return LocalField.fromJson(item);
            } else {
              return LocalField(
                localFieldId: 0,
                name: item.toString(),
                abbreviation: '',
                unionId: unionId,
              );
            }
          }).toList();
        }
      }
      // Mantener compatibilidad con respuesta de lista directa
      else if (response.data is List) {
        final List localFieldsList = response.data;
        print('📊 Procesando ${localFieldsList.length} campos locales desde lista directa');
        
        return localFieldsList.map((item) {
          if (item is Map<String, dynamic>) {
            return LocalField.fromJson(item);
          } else {
            return LocalField(
              localFieldId: 0,
              name: item.toString(),
              abbreviation: '',
              unionId: unionId,
            );
          }
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error al obtener campos locales: ${e.toString()}');
      // Retornamos lista vacía en lugar de propagar el error
      return [];
    }
  }

  // Método para obtener clubes por campo local
  @override
  Future<List<dynamic>> getClubs(int localFieldId) async {
    try {
      final response = await _safeApiCall(
        apiCall: () => _dio.get(
          '$api/clubs',
          queryParameters: {
            'localFieldId': localFieldId,
            'take': 100,
          },
          options: Options(headers: _getAuthHeaders()),
        ),
        errorMessage: 'Error al obtener clubes',
        retryOnError: false,
      );

      // Verificar si la respuesta tiene la estructura esperada
      if (response.data is Map<String, dynamic> && 
          response.data['data'] is List) {
        final clubsList = response.data['data'] as List;
        print('Clubes obtenidos exitosamente: ${clubsList.length} registros');
        
        return clubsList
            .map((json) => json)
            .toList();
      } else if (response.data is List) {
        // Compatibilidad con versiones anteriores
        return response.data as List;
      }
      
      print('Respuesta con formato inesperado en getClubs: ${response.data}');
      return [];
    } catch (e) {
      print('Error al obtener clubes en PostRegisterRepository: ${e.toString()}');
      return [];
    }
  }
}
