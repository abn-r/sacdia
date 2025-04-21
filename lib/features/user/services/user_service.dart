import 'package:dio/dio.dart';
import 'package:sacdia/core/constants.dart';
import 'package:sacdia/features/user/models/emergency_contact_model.dart';
import 'package:sacdia/features/user/models/user_allergy_model.dart';
import 'package:sacdia/features/user/models/user_class_model.dart';
import 'package:sacdia/features/user/models/user_disease_model.dart';
import 'package:sacdia/features/user/models/user_role_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sacdia/core/http/api_client.dart';
import 'package:sacdia/features/club/models/user_club_model.dart';
import 'package:sacdia/features/user/models/disease_model.dart';
import 'package:sacdia/features/post_register/models/allergy_model.dart';

class UserService {
  final Dio _dio;
  final SupabaseClient _supabaseClient;

  UserService({
    Dio? dio,
    SupabaseClient? supabaseClient,
  })  : _dio = dio ?? ApiClient().dio,
        _supabaseClient = supabaseClient ?? Supabase.instance.client;

  /// Obtiene el ID del usuario autenticado o lanza una excepción si no existe
  String _getUserId() {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }
    return userId;
  }

  void _validateAuthentication() {
    final userId = _getUserId();
    if (userId == null) throw Exception('Usuario no autenticado');
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    // Obtener el token de autenticación del cliente de Supabase
    final token = _supabaseClient.auth.currentSession?.accessToken;
    if (token == null) {
      throw Exception('No se encontró un token de autenticación');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<Response> _safeApiCall({
    required Future<Response> Function() apiCall,
    required String errorMessage,
  }) async {
    try {
      return await apiCall();
    } catch (e) {
      if (e is DioException) {
        print('$errorMessage: ${e.message}');
        // Se puede registrar o manejar el error específico de Dio aquí
      } else {
        print('$errorMessage: ${e.toString()}');
      }
      rethrow;
    }
  }

  Future<List<UserAllergy>> getUserAllergies() async {
    final userId = _getUserId();

    try {
      final response = await _safeApiCall(
        apiCall: () async => _dio.get(
          '$api/u/allergies/by-user/$userId',
          options: Options(headers: await _getAuthHeaders()),
        ),
        errorMessage: 'Error al obtener alergias del usuario',
      );

      List<UserAllergy> allergies = [];

      // Procesamiento de la respuesta
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('data')) {
        final List allergiesList = response.data['data'];
        allergies = _processAllergiesList(allergiesList);
      } else if (response.data is List) {
        final List allergiesList = response.data;
        allergies = _processAllergiesList(allergiesList);
      }

      return allergies;
    } catch (e) {
      print('Error al obtener alergias del usuario: ${e.toString()}');
      return [];
    }
  }

  List<UserAllergy> _processAllergiesList(List allergiesList) {
    return allergiesList.map((item) {
      if (item is Map<String, dynamic>) {
        return UserAllergy.fromJson(item);
      } else {
        return UserAllergy(
          id: 0,
          userId: '',
          allergyId: 0,
          name: item.toString(),
          description: null,
        );
      }
    }).toList();
  }

  Future<List<UserDisease>> getUserDiseases() async {
    final userId = _getUserId();
    try {
      final response = await _safeApiCall(
        apiCall: () async => _dio.get(
          '$api/u/diseases/by-user/$userId',
          options: Options(headers: await _getAuthHeaders()),
        ),
        errorMessage: 'Error al obtener enfermedades del usuario',
      );

      List<UserDisease> diseases = [];

      // Procesamiento de la respuesta paginada
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('data')) {
        final List diseasesList = response.data['data'];
        diseases = _processDiseasesList(diseasesList);
      }
      // Mantener compatibilidad con respuestas no paginadas (por si acaso)
      else if (response.data is List) {
        final List diseasesList = response.data;
        diseases = _processDiseasesList(diseasesList);
      }

      return diseases;
    } catch (e) {
      print('Error al obtener enfermedades del usuario: ${e.toString()}');
      return [];
    }
  }

  // Método para obtener todas las enfermedades del catálogo
  Future<List<Disease>> getAllDiseases() async {
    try {
      final response = await _safeApiCall(
        apiCall: () async => _dio.get(
          '$api/c/diseases',
          queryParameters: {'take': 100},
          options: Options(headers: await _getAuthHeaders()),
        ),
        errorMessage: 'Error al obtener catálogo de enfermedades',
      );

      List<Disease> diseases = [];

      // Procesamiento de la respuesta paginada
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('data')) {
        final List diseasesList = response.data['data'];
        diseases = diseasesList.map((item) {
          if (item is Map<String, dynamic>) {
            return Disease.fromJson(item);
          } else {
            return Disease(
              diseaseId: 0,
              name: item.toString(),
            );
          }
        }).toList();
      }
      // Mantener compatibilidad con respuestas no paginadas
      else if (response.data is List) {
        final List diseasesList = response.data;
        diseases = diseasesList.map((item) {
          if (item is Map<String, dynamic>) {
            return Disease.fromJson(item);
          } else {
            return Disease(
              diseaseId: 0,
              name: item.toString(),
            );
          }
        }).toList();
      }

      return diseases;
    } catch (e) {
      print('Error al obtener catálogo de enfermedades: ${e.toString()}');
      return [];
    }
  }

  // Método para obtener todas las alergias del catálogo
  Future<List<Allergy>> getAllAllergies() async {
    try {
      final response = await _safeApiCall(
        apiCall: () async => _dio.get(
          '$api/c/allergies',
          queryParameters: {'take': 100},
          options: Options(headers: await _getAuthHeaders()),
        ),
        errorMessage: 'Error al obtener catálogo de alergias',
      );

      List<Allergy> allergies = [];

      // Procesamiento de la respuesta paginada
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('data')) {
        final List allergiesList = response.data['data'];
        allergies = allergiesList.map((item) {
          if (item is Map<String, dynamic>) {
            return Allergy.fromJson(item);
          } else {
            return Allergy(
              allergyId: 0,
              name: item.toString(),
            );
          }
        }).toList();
      }
      // Mantener compatibilidad con respuestas no paginadas
      else if (response.data is List) {
        final List allergiesList = response.data;
        allergies = allergiesList.map((item) {
          if (item is Map<String, dynamic>) {
            return Allergy.fromJson(item);
          } else {
            return Allergy(
              allergyId: 0,
              name: item.toString(),
            );
          }
        }).toList();
      }

      return allergies;
    } catch (e) {
      print('Error al obtener catálogo de alergias: ${e.toString()}');
      return [];
    }
  }

  // Método para guardar múltiples enfermedades del usuario
  Future<bool> saveUserDiseases(List<Disease> diseases) async {
    try {
      final userId = _getUserId();
      final List<Map<String, dynamic>> diseasesArray = [];

      // Si la lista contiene el elemento "Ninguna" (diseaseId = 0), no mandamos nada
      final hasNoneDisease = diseases.any((d) => d.diseaseId == 0);
      if (!hasNoneDisease && diseases.isNotEmpty) {
        // Preparar el array con los datos necesarios para el API
        for (var disease in diseases) {
          diseasesArray.add({
            'user_id': userId,
            'disease_id': disease.diseaseId,
            'active': true,
          });
        }

        // Enviar la solicitud al API
        await _safeApiCall(
          apiCall: () async => _dio.post(
            '$api/u/diseases/many',
            data: diseasesArray,
            options: Options(
              headers: await _getAuthHeaders(),
              validateStatus: (status) => true,
            ),
          ),
          errorMessage: 'Error al guardar enfermedades',
        );

        return true;
      }
      
      // Si no hay enfermedades que guardar o se seleccionó "Ninguna"
      return true;
    } catch (e) {
      print('Error al guardar enfermedades: ${e.toString()}');
      return false;
    }
  }

  // Método para guardar múltiples alergias del usuario
  Future<bool> saveUserAllergies(List<Allergy> allergies) async {
    try {
      final userId = _getUserId();
      final List<Map<String, dynamic>> allergiesArray = [];

      // Si la lista contiene el elemento "Ninguna" (allergyId = 0), no mandamos nada
      final hasNoneAllergy = allergies.any((a) => a.allergyId == 0);
      if (!hasNoneAllergy && allergies.isNotEmpty) {
        // Preparar el array con los datos necesarios para el API
        for (var allergy in allergies) {
          allergiesArray.add({
            'user_id': userId,
            'allergy_id': allergy.allergyId,
            'active': true,
          });
        }

        // Enviar la solicitud al API
        await _safeApiCall(
          apiCall: () async => _dio.post(
            '$api/u/allergies/many',
            data: allergiesArray,
            options: Options(
              headers: await _getAuthHeaders(),
              validateStatus: (status) => true,
            ),
          ),
          errorMessage: 'Error al guardar alergias',
        );

        return true;
      }
      
      // Si no hay alergias que guardar o se seleccionó "Ninguna"
      return true;
    } catch (e) {
      print('Error al guardar alergias: ${e.toString()}');
      return false;
    }
  }

  List<UserDisease> _processDiseasesList(List diseasesList) {
    return diseasesList.map((item) {
      if (item is Map<String, dynamic>) {
        return UserDisease.fromJson(item);
      } else {
        return UserDisease(
            id: 0,
            userId: '',
            diseaseId: 0,
            createdAt: DateTime.now(),
            modifiedAt: DateTime.now(),
            active: true,
            name: item.toString());
      }
    }).toList();
  }

  Future<bool> deleteUserDisease(int diseaseId) async {
    final headers = await _getAuthHeaders();
    print('Headers: $headers');
    try {
      
      final response = await _safeApiCall(
        apiCall: () async => _dio.delete(
          '$api/u/diseases/$diseaseId',
          options: Options(headers: await _getAuthHeaders()),
        ),
        errorMessage: 'Error al eliminar enfermedad del usuario',
      );

      // Verificar si la respuesta es exitosa (códigos 200, 201, 204)
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      // Identificar específicamente errores de autenticación
      if (e is DioException && e.response?.statusCode == 403) {
        try {
          // Intentar notificar sobre el error de autenticación
          // Este bloque try-catch es para evitar excepciones adicionales
          _handleAuthError();
        } catch (_) {}
      }
      print('Error al eliminar enfermedad del usuario: $e');
      return false;
    }
  }
  
  Future<bool> deleteUserAllergy(int allergyId) async {
    try {
      final response = await _safeApiCall(
        apiCall: () async => _dio.delete(
          '$api/u/allergies/$allergyId',
          options: Options(headers: await _getAuthHeaders()),
        ),
        errorMessage: 'Error al eliminar alergia del usuario',
      );

      // Verificar si la respuesta es exitosa (códigos 200, 201, 204)
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      // Identificar específicamente errores de autenticación
      if (e is DioException && e.response?.statusCode == 403) {
        try {
          _handleAuthError();
        } catch (_) {}
      }
      print('Error al eliminar alergia del usuario: $e');
      return false;
    }
  }
  
  void _handleAuthError() {
    // Aquí puedes disparar eventos para manejar errores de autenticación
    // Por ejemplo, podrías notificar a un AuthBloc para redireccionar al login
    // Ten cuidado con este método para evitar errores de ScaffoldMessenger
  }

  Future<List<EmergencyContact>> getEmergencyContacts() async {
    final userId = _getUserId();
    _validateAuthentication();

    try {
      final response = await _safeApiCall(
        apiCall: () async => _dio.get(
          '$api/u/emergency-contacts/all',
          queryParameters: {'userId': userId},
          options: Options(headers: await _getAuthHeaders()),
        ),
        errorMessage: 'Error al obtener contactos de emergencia',
      );

      if (response.data == null) {
        return [];
      }

      // Usar el nuevo método fromJsonList para procesar la respuesta
      return EmergencyContact.fromJsonList(response.data);
    } catch (e) {
      print('Error al obtener contactos de emergencia: $e');
      return [];
    }
  }

  Future<List<RelationshipType>> getRelationshipTypes() async {
    try {
      final response = await _safeApiCall(
        apiCall: () async => _dio.get(
          '$api/c/relationship_types',
          options: Options(headers: await _getAuthHeaders()),
        ),
        errorMessage: 'Error al obtener tipos de relación',
      );

      // Usar el nuevo método fromJsonList para procesar la respuesta
      return RelationshipType.fromJsonList(response.data);
    } catch (e) {
      print('Error al obtener tipos de relación: $e');
      return [];
    }
  }

  Future<EmergencyContact?> addEmergencyContact({
    required String name,
    required String phone,
    required int relationshipTypeId,
  }) async {
    try {
      final response = await _safeApiCall(
        apiCall: () async => _dio.post(
          '$api/u/emergency-contacts',
          data: {
            'name': name,
            'phone': phone,
            'relationship_type': relationshipTypeId,
          },
          options: Options(headers: await _getAuthHeaders()),
        ),
        errorMessage: 'Error al añadir contacto de emergencia',
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error al añadir contacto: ${response.statusCode}');
      }

      if (response.data != null) {
        if (response.data is Map<String, dynamic>) {
          return EmergencyContact.fromJson(response.data);
        }
      }

      return null;
    } catch (e) {
      // Log the error
      print('Error al añadir contacto de emergencia: $e');
      return null;
    }
  }

  Future<bool> deleteEmergencyContact(int contactId) async {
    try {
      final response = await _safeApiCall(
        apiCall: () async => _dio.delete(
          '$api/u/emergency-contacts/$contactId',
          options: Options(headers: await _getAuthHeaders()),
        ),
        errorMessage: 'Error al eliminar contacto de emergencia',
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      // Log the error
      print('Error al eliminar contacto de emergencia: $e');
      return false;
    }
  }

  Future<List<UserClub>> getUserClubs() async {
    final userId = _getUserId();
    _validateAuthentication();

    try {
      final response = await _safeApiCall(
        apiCall: () async => _dio.get(
          '$api/u/users-clubs/by-user/$userId',
          options: Options(headers: await _getAuthHeaders()),
        ),
        errorMessage: 'Error al obtener los clubes del usuario',
      );

      if (response.data == null) {
        return [];
      }

      // Usar el método fromJsonList para procesar la respuesta
      return UserClub.fromJsonList(response.data);
    } catch (e) {
      print('Error al obtener clubes del usuario: $e');
      return [];
    }
  }

  Future<List<UserClass>> getUserClasses() async {
    final userId = _getUserId();
    try {
      final response = await _safeApiCall(
        apiCall: () async => _dio.get(
          '$api/u/users-classes/by-user/$userId',
          options: Options(headers: await _getAuthHeaders()),
        ),
        errorMessage: 'Error al obtener clases del usuario',
      );

      List<UserClass> classes = [];

      // Procesamiento de la respuesta paginada
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('data')) {
        final List classesList = response.data['data'];
        classes = classesList.map((item) {
          if (item is Map<String, dynamic>) {
            return UserClass.fromJson(item);
          } else {
            return UserClass(
              id: 0,
              userId: '',
              classId: 0,
              investiture: false,
              advanced: false,
              className: '',
              clubTypeId: 0,
              clubTypeName: '',
            );
          }
        }).toList();
      }

      return classes;
    } catch (e) {
      print('Error al obtener clases del usuario: ${e.toString()}');
      return [];
    }
  }

  Future<List<UserRole>> getUserRoles() async {
    final userId = _getUserId();
    try {
      final response = await _safeApiCall(
        apiCall: () async => _dio.get(
          '$api/c/users-roles/by-user/$userId',
          options: Options(headers: await _getAuthHeaders()),
        ),
        errorMessage: 'Error al obtener roles del usuario',
      );

      List<UserRole> roles = [];

      // Procesamiento de la respuesta paginada
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('data')) {
        final List rolesList = response.data['data'];
        roles = rolesList.map((item) {
          if (item is Map<String, dynamic>) {
            return UserRole.fromJson(item);
          } else {
            return UserRole(
              id: '',
              userId: '',
              roleId: '',
              roleName: item.toString(),
            );
          }
        }).toList();
      }

      return roles;
    } catch (e) {
      print('Error al obtener roles del usuario: ${e.toString()}');
      return [];
    }
  }
}
