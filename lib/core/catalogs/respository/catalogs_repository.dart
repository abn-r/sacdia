import 'package:dio/dio.dart';
import 'package:sacdia/core/catalogs/models/country.dart';
import 'package:sacdia/core/catalogs/models/local_field.dart';
import 'package:sacdia/core/catalogs/models/union.dart';
import 'package:sacdia/core/constants.dart';
import 'package:sacdia/core/http/api_client.dart';
import 'package:sacdia/features/post_register/models/club_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ICatalogsRepository {
  Future<List<Country>> getCountries();
  Future<List<Union>> getUnions();
  Future<List<LocalField>> getLocalFields();
  Future<List<Club>> getClubs(int localFieldId);
  Future<List<ClubType>> getClubTypes();
  Future<List<Class>> getClasses(int clubTypeId);
}

class CatalogsRepository implements ICatalogsRepository {
  final Dio _dio;
  final SupabaseClient _supabase;

  CatalogsRepository({Dio? dio})
      : _dio = dio ?? ApiClient().dio,
        _supabase = Supabase.instance.client;

  String? _getToken() {
    try {
      return _supabase.auth.currentSession?.accessToken;
    } catch (e) {
      print('Error al obtener token: ${e.toString()}');
      return null;
    }
  }

  Map<String, dynamic> _getAuthHeaders() {
    final token = _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

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
        return response;
      } catch (e) {
        attempts++;

        if (attempts > maxRetries || !retryOnError) {
          print('$errorMessage: ${e.toString()}');
          rethrow;
        }

        await Future.delayed(Duration(milliseconds: 500 * attempts));
        print('Reintentando solicitud (${attempts}/${maxRetries})...');
      }
    }
    
    throw Exception('Error inesperado en la solicitud HTTP');
  }

  @override
  Future<List<Country>> getCountries() async {
    try {
      final response = await _safeApiCall(
        apiCall: () => _dio.get(
          '$api/c/countries',
          queryParameters: {
            'take': 50,
          },
          options: Options(headers: _getAuthHeaders()),
        ),
        errorMessage: 'Error al obtener países',
        retryOnError: false,
      );

      // Verificar si la respuesta tiene la estructura esperada
      if (response.data is Map<String, dynamic> && 
          response.data['data'] is List) {
        final countriesList = response.data['data'] as List;
        print('Países obtenidos exitosamente: ${countriesList.length} registros');
        
        return countriesList
            .map((json) => Country.fromJson(json))
            .toList();
      } else if (response.data is List) {
        print('Países obtenidos exitosamente: ${response.data.length} registros');
        return (response.data as List)
            .map((json) => Country.fromJson(json))
            .toList();
      }
      
      print('Respuesta con formato inesperado: ${response.data}');
      return [];
    } catch (e) {
      print('Error al obtener países: ${e.toString()}');
      return [];
    }
  }

  @override
  Future<List<Union>> getUnions() async {
    try {
      final response = await _safeApiCall(
        apiCall: () => _dio.get(
          '$api/c/unions',
          queryParameters: {
            'take': 50,
          },
          options: Options(headers: _getAuthHeaders()),
        ),
        errorMessage: 'Error al obtener uniones',
        retryOnError: false,
      );

      // Verificar si la respuesta tiene la estructura esperada
      if (response.data is Map<String, dynamic> && 
          response.data['data'] is List) {
        final unionsList = response.data['data'] as List;
        print('Uniones obtenidas exitosamente: ${unionsList.length} registros');
        
        return unionsList
            .map((json) => Union.fromJson(json))
            .toList();
      } else if (response.data is List) {
        print('Uniones obtenidas exitosamente: ${response.data.length} registros');
        return (response.data as List)
            .map((json) => Union.fromJson(json))
            .toList();
      }
      
      print('Respuesta con formato inesperado: ${response.data}');
      return [];
    } catch (e) {
      print('Error al obtener uniones: ${e.toString()}');
      // Retornamos lista vacía en lugar de propagar el error
      return [];
    }
  }

  @override
  Future<List<LocalField>> getLocalFields() async {
    try {
      final response = await _safeApiCall(
        apiCall: () => _dio.get(
          '$api/c/lf',
          queryParameters: {
            'take': 50,
          },
          options: Options(headers: _getAuthHeaders()),
        ),
        errorMessage: 'Error al obtener campos locales',
        retryOnError: false,
      );

      // Verificar si la respuesta tiene la estructura esperada
      if (response.data is Map<String, dynamic> && 
          response.data['data'] is List) {
        final fieldsList = response.data['data'] as List;
        print('Campos locales obtenidos exitosamente: ${fieldsList.length} registros');
        print('Muestra del primer campo local: ${fieldsList.isNotEmpty ? fieldsList.first : "No hay campos"}');
        
        return fieldsList
            .map((json) => LocalField.fromJson(json))
            .toList();
      } else if (response.data is List) {
        // Compatibilidad con versiones anteriores
        print('Campos locales obtenidos exitosamente: ${response.data.length} registros');
        print('Muestra del primer campo local: ${response.data.isNotEmpty ? response.data.first : "No hay campos"}');
        
        return (response.data as List)
            .map((json) => LocalField.fromJson(json))
            .toList();
      }
      
      return [];
    } catch (e) {
      print('Error al obtener campos locales con endpoint /c/lf: ${e.toString()}');
      return [];
    }
  }

  @override
  Future<List<Club>> getClubs(int localFieldId) async {
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
            .map((json) => Club.fromJson(json))
            .toList();
      } else if (response.data is List) {
        // Compatibilidad con versiones anteriores
        return (response.data as List)
            .map((json) => Club.fromJson(json))
            .toList();
      }
      
      print('Respuesta con formato inesperado: ${response.data}');
      return [];
    } catch (e) {
      print('Error al obtener clubes: ${e.toString()}');
      return [];
    }
  }

  @override
  Future<List<ClubType>> getClubTypes() async {
    try {
      final response = await _safeApiCall(
        apiCall: () => _dio.get(
          '$api/c/club-types',
          queryParameters: {
            'take': 20,
          },
          options: Options(headers: _getAuthHeaders()),
        ),
        errorMessage: 'Error al obtener tipos de club',
        retryOnError: false,
      );

      if (response.data is Map<String, dynamic> && 
          response.data['data'] is List) {
        final clubTypesList = response.data['data'] as List;
        print('Tipos de club obtenidos exitosamente: ${clubTypesList.length} registros');
        
        return clubTypesList
            .map((json) => ClubType.fromJson(json))
            .toList();
      } else if (response.data is List) {
        // Compatibilidad con versiones anteriores
        print('Tipos de club obtenidos exitosamente: ${response.data.length} registros');
        return (response.data as List)
            .map((json) => ClubType.fromJson(json))
            .toList();
      }
      
      print('Respuesta con formato inesperado: ${response.data}');
      return [];
    } catch (e) {
      print('Error al obtener tipos de club: ${e.toString()}');
      return [];
    }
  }

  @override
  Future<List<Class>> getClasses(int clubTypeId) async {
    try {
      print('🔍 Solicitando clases para el tipo de club ID: $clubTypeId');
      
      final response = await _safeApiCall(
        apiCall: () => _dio.get(
          '$api/classes',
          queryParameters: {
            'clubTypeId': clubTypeId,
            'take': 30,
          },
          options: Options(headers: _getAuthHeaders()),
        ),
        errorMessage: 'Error al obtener clases',
        retryOnError: false,
      );

      // Verificar si la respuesta tiene la estructura esperada
      if (response.data is Map<String, dynamic> && 
          response.data['data'] is List) {
        final classesList = response.data['data'] as List;
        print('📚 Clases obtenidas exitosamente: ${classesList.length} registros');
        
        // Imprimir la estructura de la primera clase para depuración
        if (classesList.isNotEmpty) {
          print('📝 Estructura de la primera clase: ${classesList.first}');
          
          // Verificar cómo viene la información del club_type
          if (classesList.first is Map && classesList.first['club_types'] != null) {
            print('🔄 Tipo de club anidado: ${classesList.first['club_types']}');
          }
        }
        
        final classes = classesList.map((json) => Class.fromJson(json)).toList();
        
        // Verificar si se mapearon correctamente los clubTypeId
        if (classes.isNotEmpty) {
          print('✅ Clase ${classes.first.name} mapeada con clubTypeId: ${classes.first.clubTypeId}');
        }
        
        return classes;
      } else if (response.data is List) {
        // Compatibilidad con versiones anteriores
        print('📚 Clases obtenidas exitosamente: ${response.data.length} registros');
        
        // Imprimir la estructura de la primera clase para depuración
        if (response.data.isNotEmpty) {
          print('📝 Estructura de la primera clase (versión alternativa): ${response.data.first}');
        }
        
        final classes = (response.data as List).map((json) => Class.fromJson(json)).toList();
        
        // Verificar después del parseo
        if (classes.isNotEmpty) {
          classes.forEach((cls) {
            print('📋 Clase: ${cls.name}, clubTypeId: ${cls.clubTypeId}');
          });
        }
        
        return classes;
      }
      
      print('⚠️ Respuesta con formato inesperado: ${response.data}');
      return [];
    } catch (e) {
      print('❌ Error al obtener clases: ${e.toString()}');
      return [];
    }
  }
}
