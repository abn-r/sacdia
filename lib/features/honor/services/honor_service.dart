import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:sacdia/core/constants.dart';
import 'package:sacdia/core/http/api_client.dart';
import 'package:sacdia/features/honor/models/honor_category_model.dart';
import 'package:sacdia/features/honor/models/user_honor_category_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HonorService {
  final dio.Dio _dio;
  final SupabaseClient _supabaseClient;

  HonorService({
    dio.Dio? dio,
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

  Future<dio.Response> _safeApiCall({
    required Future<dio.Response> Function() apiCall,
    required String errorMessage,
  }) async {
    try {
      return await apiCall();
    } catch (e) {
      if (e is dio.DioException) {
        print('$errorMessage: ${e.message}');
      } else {
        print('$errorMessage: ${e.toString()}');
      }
      rethrow;
    }
  }

  /// Obtiene todas las especialidades disponibles organizadas por categoría
  Future<List<HonorCategory>> getHonorsByCategory() async {
    try {
      final response = await _safeApiCall(
        apiCall: () async => _dio.get(
          '$api/c/honors/by-category',
          options: dio.Options(headers: await _getAuthHeaders()),
        ),
        errorMessage: 'Error al obtener especialidades por categoría',
      );

      List<HonorCategory> categories = [];

      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('data')) {
        final List categoriesList = response.data['data'];
        categories = categoriesList
            .map((item) => HonorCategory.fromJson(item))
            .toList();
      }

      return categories;
    } catch (e) {
      print('Error al obtener especialidades por categoría: ${e.toString()}');
      return [];
    }
  }

  /// Obtiene las especialidades del usuario organizadas por categoría
  Future<List<UserHonorCategory>> getUserHonorsByCategory() async {
    final userId = _getUserId();
    print('$api/u/users-honors/$userId/by-category');
    
    try {
      final response = await _safeApiCall(
        apiCall: () async => _dio.get(
          '$api/u/users-honors/$userId/by-category',
          queryParameters: {
            'take': 1000,
          },
          options: dio.Options(headers: await _getAuthHeaders()),
        ),
        errorMessage: 'Error al obtener especialidades del usuario',
      );

      List<UserHonorCategory> categories = [];

      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('data')) {
        final List categoriesList = response.data['data'];
        categories = categoriesList
            .map((item) => UserHonorCategory.fromJson(item))
            .toList();
      }

      return categories;
    } catch (e) {
      print('Error al obtener especialidades del usuario: ${e.toString()}');
      return [];
    }
  }

  /// Registra una nueva especialidad para el usuario
  Future<bool> createUserHonor({
    required int honorId,
    File? certificateFile,
    List<File> images = const [],
  }) async {
    final userId = _getUserId();

    try {
      // Primero crear el registro básico
      final response = await _safeApiCall(
        apiCall: () async => _dio.post(
          '$api/u/users-honors',
          data: {
            'user_id': userId,
            'honor_id': honorId,
            'active': true,
            'validate': false,
          },
          options: dio.Options(headers: await _getAuthHeaders()),
        ),
        errorMessage: 'Error al registrar especialidad',
      );

      if (response.data['status'] == true && 
          response.data.containsKey('data') &&
          response.data['data'].containsKey('user_honor_id')) {
        
        final userHonorId = response.data['data']['user_honor_id'];
        
        // Si hay archivos, subirlos
        if (certificateFile != null || images.isNotEmpty) {
          await _uploadUserHonorFiles(
            userHonorId: userHonorId,
            certificateFile: certificateFile,
            images: images,
          );
        }
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error al registrar especialidad: ${e.toString()}');
      return false;
    }
  }

  /// Actualiza una especialidad existente del usuario
  Future<bool> updateUserHonor({
    required int userHonorId,
    File? certificateFile,
    List<File> images = const [],
  }) async {
    try {
      // Si hay archivos, subirlos
      if (certificateFile != null || images.isNotEmpty) {
        await _uploadUserHonorFiles(
          userHonorId: userHonorId,
          certificateFile: certificateFile,
          images: images,
        );
      }
      
      // Actualizar el registro
      final response = await _safeApiCall(
        apiCall: () async => _dio.put(
          '$api/u/users-honors/$userHonorId',
          options: dio.Options(headers: await _getAuthHeaders()),
        ),
        errorMessage: 'Error al actualizar especialidad',
      );

      return response.data['status'] == true;
    } catch (e) {
      print('Error al actualizar especialidad: ${e.toString()}');
      return false;
    }
  }

  /// Elimina una especialidad del usuario
  Future<bool> deleteUserHonor(int userHonorId) async {
    try {
      final response = await _safeApiCall(
        apiCall: () async => _dio.delete(
          '$api/u/users-honors/$userHonorId',
          options: dio.Options(headers: await _getAuthHeaders()),
        ),
        errorMessage: 'Error al eliminar especialidad',
      );

      return response.data['status'] == true;
    } catch (e) {
      print('Error al eliminar especialidad: ${e.toString()}');
      return false;
    }
  }

  /// Sube archivos relacionados con una especialidad
  Future<bool> _uploadUserHonorFiles({
    required int userHonorId,
    File? certificateFile,
    List<File> images = const [],
  }) async {
    try {
      final formData = dio.FormData();
      
      // Agregar el certificado si existe
      if (certificateFile != null) {
        formData.files.add(MapEntry(
          'certificate',
          await dio.MultipartFile.fromFile(
            certificateFile.path,
            filename: 'certificate_${userHonorId}.pdf',
          ),
        ));
      }
      
      // Agregar imágenes si existen
      for (int i = 0; i < images.length; i++) {
        formData.files.add(MapEntry(
          'images',
          await dio.MultipartFile.fromFile(
            images[i].path,
            filename: 'image_${userHonorId}_$i.jpg',
          ),
        ));
      }
      
      await _safeApiCall(
        apiCall: () async => _dio.post(
          '$api/u/users-honors/$userHonorId/files',
          data: formData,
          options: dio.Options(headers: await _getAuthHeaders()),
        ),
        errorMessage: 'Error al subir archivos de especialidad',
      );
      
      return true;
    } catch (e) {
      print('Error al subir archivos de especialidad: ${e.toString()}');
      return false;
    }
  }
  
  /// Obtiene la URL firmada para la imagen de una especialidad
  /// Utiliza el cliente de Supabase para generar la URL
  Future<String> getHonorImageSignedUrl(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }
    
    try {
      // Generar URL firmada con expiración de 24 horas
      final signedUrl = await _supabaseClient.storage
          .from('honors')
          .createSignedUrl(imagePath, 60 * 60 * 24);
      
      return signedUrl;
    } catch (e) {
      print('Error al generar URL firmada para $imagePath: $e');
      return '';
    }
  }
} 