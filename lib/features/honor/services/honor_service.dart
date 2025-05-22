import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:sacdia/core/constants.dart';
import 'package:sacdia/core/http/api_client.dart';
import 'package:sacdia/features/honor/models/honor_category_model.dart';
import 'package:sacdia/features/honor/models/user_honor_category_model.dart';
import 'package:sacdia/features/honor/models/user_honor_entity.dart';
import 'package:sacdia/features/honor/models/user_honor_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class HonorService {
  final dio.Dio _dio;
  final SupabaseClient _supabaseClient;

  HonorService({
    dio.Dio? dio,
    SupabaseClient? supabaseClient,
  })  : _dio = dio ?? ApiClient().dio,
        _supabaseClient = supabaseClient ?? Supabase.instance.client;

  String _getUserId() {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }
    return userId;
  }

  Future<Map<String, String>> _getAuthHeaders({bool isMultipart = false}) async {
    final token = _supabaseClient.auth.currentSession?.accessToken;
    if (token == null) {
      throw Exception('No se encontró un token de autenticación');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': isMultipart ? 'multipart/form-data' : 'application/json',
    };
  }

  Future<dio.Response<dynamic>> _safeApiCall({
    required Future<dio.Response<dynamic>> Function() apiCall,
    required String errorMessage,
  }) async {
    try {
      return await apiCall();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$errorMessage: ${e.toString()}');
      }
      
      if (e is dio.DioException) {
        if (kDebugMode) {
          debugPrint('$errorMessage: ${e.message}');
        }
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
      if (kDebugMode) {
        debugPrint('Error al obtener especialidades por categoría: ${e.toString()}');
      }
      return [];
    }
  }

  /// Obtiene las especialidades del usuario organizadas por categoría
  Future<List<UserHonorCategory>> getUserHonorsByCategory() async {
    final userId = _getUserId();    
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
      if (kDebugMode) {
        debugPrint('❌ Error al obtener especialidades del usuario: ${e.toString()}');
      }
      return [];
    }
  }

  /// Subir archivos al bucket de Supabase
  Future<Map<String, dynamic>> _uploadFilesToBucket({
    required int honorId,
    File? certificateFile,
    List<File> images = const [],
    String? customCertificateName,
    String? customImagePrefix,
  }) async {
    final userId = _getUserId();
    final result = {
      'certificateUrl': '',
      'imageUrls': <String>[],
      'imagePaths': <String>[],
      'certificatePath': '',
      'imageNames': <String>[],
      'certificateName': '',
    };

    try {
      // Subir certificado al bucket si existe
      if (certificateFile != null) {
        final extension = certificateFile.path.split('.').last.toLowerCase();
        
        // Usar nombre personalizado si se proporciona, o el predeterminado
        final certificateFileName = customCertificateName != null
            ? '$customCertificateName.$extension'
            : 'cert-$userId-$honorId.$extension';
            
        final certificatePath = '$bucketUserHonors/$certificateFileName';
        
        // Subir archivo al bucket de Supabase
        await _supabaseClient.storage
            .from(bucketUserHonors)
            .upload(
              certificateFileName,
              certificateFile,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true,
              ),
            );
        
        // Obtener URL pública del archivo subido
        final certificateUrl = await _supabaseClient.storage
            .from(bucketUserHonors)
            .createSignedUrl(certificateFileName, 60 * 60 * 24 * 365); // URL válida por 1 año
        
        result['certificateUrl'] = certificateUrl;
        result['certificatePath'] = certificatePath;
        result['certificateName'] = certificateFileName;
      }

      // Subir imágenes al bucket si existen
      if (images.isNotEmpty) {
        for (int i = 0; i < images.length; i++) {
          final extension = images[i].path.split('.').last.toLowerCase();
          
          // Usar prefijo personalizado si se proporciona, o el predeterminado
          final imageFileName = customImagePrefix != null
              ? '$customImagePrefix-$i.$extension'
              : 'img-$honorId-$userId-$i.$extension';
              
          final imagePath = '$bucketUserHonors/$imageFileName';
          
          // Subir archivo al bucket de Supabase
          await _supabaseClient.storage
              .from(bucketUserHonors)
              .upload(
                imageFileName,
                images[i],
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: true,
                ),
              );
          
          // Obtener URL pública del archivo subido
          final imageUrl = await _supabaseClient.storage
              .from(bucketUserHonors)
              .createSignedUrl(imageFileName, 60 * 60 * 24 * 365); // URL válida por 1 año
          
          // Acceder de forma segura a las listas
          (result['imageUrls'] as List<String>).add(imageUrl);
          (result['imagePaths'] as List<String>).add(imagePath);
          (result['imageNames'] as List<String>).add(imageFileName);
        }
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al subir archivos al bucket: ${e.toString()}');
      }
      rethrow;
    }
  }

  /// Registra una nueva especialidad para el usuario
  Future<bool> createUserHonor({
    required int honorId,
    File? certificateFile,
    List<File> images = const [],
    String? customCertificateName,
    String? customImagePrefix,
    DateTime? completionDate,
  }) async {
    final userId = _getUserId();

    try {
      // Primero, subir el certificado
      String certificateName = '';
      String certificateUrl = '';
      if (certificateFile != null) {
        final extension = certificateFile.path.split('.').last.toLowerCase();
        certificateName = customCertificateName != null 
            ? '$customCertificateName.$extension'
            : 'cert-$userId-$honorId.$extension';
            
        // Subir el certificado al bucket
        await _supabaseClient.storage
            .from(bucketUserHonors)
            .upload(
              certificateName,
              certificateFile,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true,
              ),
            );
        
        // Obtener la URL firmada
        certificateUrl = await _supabaseClient.storage
            .from(bucketUserHonors)
            .createSignedUrl(certificateName, 60 * 60 * 24 * 365); // URL válida por 1 año
      }

      // Ahora, subir cada imagen del array
      final List<String> imageUrls = [];
      final List<String> imagePaths = [];
      final List<Map<String, dynamic>> imagesJson = []; // Lista para objetos JSON
      
      if (images.isNotEmpty) {
        for (int i = 0; i < images.length; i++) {
          final extension = images[i].path.split('.').last.toLowerCase();
          final imageName = customImagePrefix != null
              ? '$customImagePrefix-$i.$extension'
              : 'img-$honorId-$userId-$i.$extension';
              
          // Subir la imagen al bucket
          await _supabaseClient.storage
              .from(bucketUserHonors)
              .upload(
                imageName,
                images[i],
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: true,
                ),
              );
          
          // Obtener la URL firmada
          final imageUrl = await _supabaseClient.storage
              .from(bucketUserHonors)
              .createSignedUrl(imageName, 60 * 60 * 24 * 365);
            
          imageUrls.add(imageUrl);
          imagePaths.add('$bucketUserHonors/$imageName');
          
          // Crear objeto JSON para esta imagen
          imagesJson.add({
            'image': imageName,
            'path': '$bucketUserHonors/$imageName',
          });
        }
      }

      // Convertir la lista de objetos JSON a una cadena JSON formateada correctamente
      final String imagesJsonString = json.encode(imagesJson);
      
      log("imagesJson: $imagesJsonString");
      log("certificateName: $certificateName");

      // Crear el registro de especialidad con las URLs de los archivos
      log("Inicia registro de especialidad");
      final response = await _safeApiCall(
        apiCall: () async => _dio.post(
          '$api/u/users-honors',
          data: {
            'user_id': userId,
            'honor_id': honorId,
            'images': imagesJsonString, // Enviar como cadena JSON
            'certificate': certificateName,
            'date': completionDate != null ? DateFormat('yyyy-MM-dd').format(completionDate) : null,
          },
          options: dio.Options(headers: await _getAuthHeaders()),
        ),
        errorMessage: 'Error al registrar especialidad',
      );

      log("response: ${response.data}");

      if (response.data['status'] == true) {
        return true;
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al registrar especialidad: ${e.toString()}');
      }
      return false;
    }
  }

  /// Actualiza una especialidad existente del usuario
  Future<bool> updateUserHonor({
    required int userHonorId,
    File? certificateFile,
    List<File> images = const [],
    DateTime? completionDate,

  }) async {
    try {
      // Obtener el honorId asociado al userHonorId
      final honorId = await _getHonorIdFromUserHonor(userHonorId);
      if (honorId == null) {
        throw Exception('No se pudo obtener el ID de la especialidad');
      }

      // Subir archivos al bucket primero
      final uploadResult = await _uploadFilesToBucket(
        honorId: honorId,
        certificateFile: certificateFile,
        images: images,
      );
      
      // Actualizar el registro con las URLs de los archivos
      final response = await _safeApiCall(
        apiCall: () async => _dio.patch(
          '$api/u/users-honors/$userHonorId',
          data: {
            'date': completionDate != null ? DateFormat('yyyy-MM-dd').format(completionDate) : null,
            'images': uploadResult['imageUrls'],
            'certificate': uploadResult['certificateUrl'],
            'validated': false,
          },
          options: dio.Options(headers: await _getAuthHeaders()),
        ),
        errorMessage: 'Error al actualizar especialidad',
      );

      log("response: ${response.data}");

      return response.data['status'] == true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al actualizar especialidad: ${e.toString()}');
      }
      return false;
    }
  }

  /// Obtiene el honorId asociado a un userHonorId
  Future<int?> _getHonorIdFromUserHonor(int userHonorId) async {
    try {
      final response = await _safeApiCall(
        apiCall: () async => _dio.get(
          '$api/u/users-honors/$userHonorId',
          options: dio.Options(headers: await _getAuthHeaders()),
        ),
        errorMessage: 'Error al obtener detalles de la especialidad',
      );

      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('data') &&
          response.data['data'] is Map<String, dynamic> &&
          response.data['data'].containsKey('honor_id')) {
        return response.data['data']['honor_id'];
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al obtener honorId: ${e.toString()}');
      }
      return null;
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
      if (kDebugMode) {
        debugPrint('Error al eliminar especialidad: ${e.toString()}');
      }
      return false;
    }
  }
  
  /// Obtiene la URL firmada para la imagen de una especialidad
  /// Utiliza el cliente de Supabase para generar la URL
  Future<String> getHonorImageSignedUrl(String? imagePath, {String? bucketName}) async {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }
    
    // Determinar qué bucket usar
    final bucket = bucketName ?? bucketHonors;
        
    try {
      // Generar URL firmada con expiración de 24 horas      
      final signedUrl = await _supabaseClient.storage
          .from(bucket)
          .createSignedUrl(imagePath, 60 * 60 * 24);
      
      return signedUrl;
    } catch (e) {
      log('❌ HonorService.getHonorImageSignedUrl: Error al generar URL firmada para $imagePath desde bucket $bucket: $e');
      
      // Intentar con una ruta alternativa si falla
      try {        
        // Extraer el nombre del archivo del path completo (por si incluye la carpeta)
        final fileName = imagePath.split('/').last;
        
        final signedUrl = await _supabaseClient.storage
            .from(bucket)
            .createSignedUrl(fileName, 60 * 60 * 24);
        
        return signedUrl;
      } catch (e2) {
        log('❌❌ HonorService.getHonorImageSignedUrl: Error también con path alternativo: $e2');
        
        if (kDebugMode) {
          debugPrint('Error al generar URL firmada para $imagePath: $e');
        }
        return '';
      }
    }
  }

  /// Obtener todas las categorías de especialidades
  Future<List<Map<String, dynamic>>> getAllCategories() async {
    try {
      final response = await _dio.get(
        '$api/honor/categories',
        options: dio.Options(headers: await _getAuthHeaders()),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        if (kDebugMode) {
          debugPrint('Error al obtener categorías: ${response.statusMessage}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al obtener categorías: ${e.toString()}');
      }
      return [];
    }
  }

  /// Obtener todas las especialidades
  Future<List<Map<String, dynamic>>> getAllHonors() async {
    try {
      final response = await _dio.get(
        '$api/honor',
        options: dio.Options(headers: await _getAuthHeaders()),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        if (kDebugMode) {
          debugPrint('Error al obtener especialidades: ${response.statusMessage}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al obtener especialidades: ${e.toString()}');
      }
      return [];
    }
  }

  /// Obtener las especialidades de un usuario
  Future<List<UserHonorEntity>> getUserHonors(int userId) async {
    try {
      final response = await _dio.get(
        '$api/user-honor/user/$userId',
        options: dio.Options(headers: await _getAuthHeaders()),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((item) => UserHonorEntity.fromJson(item)).toList();
      } else {
        if (kDebugMode) {
          debugPrint('Error al obtener especialidades del usuario: ${response.statusMessage}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al obtener especialidades del usuario: ${e.toString()}');
      }
      return [];
    }
  }
  
  /// Obtener la imagen base de una especialidad específica por ID
  Future<String?> getHonorImageById(int honorId) async {
    try {
      final response = await _safeApiCall(
        apiCall: () async => _dio.get(
          '$api/c/honors/$honorId',
          options: dio.Options(headers: await _getAuthHeaders()),
        ),
        errorMessage: 'Error al obtener detalles de la especialidad',
      );

      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('data') &&
          response.data['data'] is Map<String, dynamic> &&
          response.data['data'].containsKey('honor_image')) {
        return response.data['data']['honor_image'];
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al obtener imagen de especialidad: ${e.toString()}');
      }
      return null;
    }
  }

  /// Obtiene la URL firmada para la imagen de un certificado o evidencia de especialidad de usuario
  /// Utiliza el cliente de Supabase para generar la URL desde el bucket "users-honors"
  Future<String> getUserHonorImageSignedUrl(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }
    
    try {
      // Extraer el nombre del archivo (por si el path incluye la carpeta)
      final String fileName = imagePath.contains('/') ? imagePath.split('/').last : imagePath;
      
      // Generar URL firmada con expiración de 24 horas
      final signedUrl = await _supabaseClient.storage
          .from(bucketUserHonors)
          .createSignedUrl(fileName, 60 * 60 * 24);
      
      return signedUrl;
    } catch (e) {
      log('❌ HonorService.getUserHonorImageSignedUrl: Error generando URL firmada para $imagePath: $e');
      return '';
    }
  }

  /// Obtiene una lista de URLs firmadas para un conjunto de imagenes
  /// Útil para obtener URLs firmadas para imágenes de evidencia
  Future<List<String>> getUserHonorImagesSignedUrls(List<ImageData> images) async {
    final List<String> signedUrls = [];
    
    for (final imageData in images) {
      // Preferir la ruta completa si está disponible
      final String pathToUse = imageData.path.isNotEmpty ? imageData.path : imageData.image;
      final String fileName = pathToUse.contains('/') ? pathToUse.split('/').last : pathToUse;
      
      final signedUrl = await getUserHonorImageSignedUrl(fileName);
      signedUrls.add(signedUrl);
    }
    
    return signedUrls;
  }
  
  /// Versión del método anterior que mantiene compatibilidad con código antiguo
  Future<List<String>> getUserHonorImagesSignedUrlsFromPaths(List<String> imagePaths) async {
    final List<String> signedUrls = [];
    
    for (final imagePath in imagePaths) {
      final signedUrl = await getUserHonorImageSignedUrl(imagePath);
      signedUrls.add(signedUrl);
    }
    
    return signedUrls;
  }
} 