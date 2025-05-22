import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer';
import 'package:sacdia/core/constants.dart';

class ImageData {
  final String image;
  final String path;

  ImageData({required this.image, required this.path});

  factory ImageData.fromJson(Map<String, dynamic> json) {
    return ImageData(
      image: json['image'] ?? '',
      path: json['path'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'image': image,
    'path': path,
  };
}

class UserHonor {
  final int userHonorId;
  final int honorId;
  final String honorName;
  final bool validate;
  final String? certificate;
  final List<ImageData> images;
  final String? honorImage;
  final String? honorMaterial;
  final String? documentPath;
  final DateTime? completionDate;

  UserHonor({
    required this.userHonorId,
    required this.honorId,
    required this.honorName,
    this.validate = false,
    this.certificate,
    this.images = const [],
    this.honorImage,
    this.honorMaterial,
    this.documentPath,
    this.completionDate,
  });

  factory UserHonor.fromJson(Map<String, dynamic> json) {
    // Extraer los datos completos para debug
    final userHonorId = json['user_honor_id'] ?? 0;
    final honorId = json['honor_id'] ?? 0;
    final honorName = json['honor_name'] ?? '';
    final validate = json['validate'] ?? false;
    final certificate = json['certificate'];
    final honorImage = json['honor_image'];
    final honorMaterial = json['honor_material'];
    final documentPath = json['document'];
    
    // Procesamiento especial para fecha de término
    DateTime? completionDate;
    if (json['date'] != null) {
      try {
        completionDate = DateTime.parse(json['date']);
      } catch (e) {
        log('❌ [UserHonor.fromJson] Error al parsear fecha para $honorName: $e');
      }
    }
    
    List<ImageData> images = [];
    if (json['images'] != null) {
      if (json['images'] is List) {
        // Si es una lista, procesar cada elemento
        try {
          final imagesList = json['images'] as List;
          images = imagesList.map((imageData) {
            if (imageData is Map<String, dynamic>) {
              // Nuevo formato: objeto con image y path
              return ImageData.fromJson(imageData);
            } else if (imageData is String) {
              // Formato antiguo: string simple
              return ImageData(image: imageData, path: 'users-honors/$imageData');
            } else {
              log('⚠️ [UserHonor.fromJson] Formato de imagen no reconocido: $imageData');
              return ImageData(image: '', path: '');
            }
          }).toList();
        } catch (e) {
          log('❌ [UserHonor.fromJson] Error al procesar imágenes para $honorName: $e');
        }
      } else if (json['images'] is String) {
        // Si es un string, podría ser un JSON serializado
        log('⚠️ [UserHonor.fromJson] Campo images es un string para $honorName: ${json['images']}');
        try {
          // Intentar extraer si es un string que representa una lista
          if ((json['images'] as String).startsWith('[') && (json['images'] as String).endsWith(']')) {
            log('🔍 [UserHonor.fromJson] Se detectó un string con formato de lista JSON');
          }
        } catch (e) {
          log('❌ [UserHonor.fromJson] Error al analizar string de imágenes: $e');
        }
      }
    }
  
    return UserHonor(
      userHonorId: userHonorId,
      honorId: honorId,
      honorName: honorName,
      validate: validate,
      certificate: certificate,
      images: images,
      honorImage: honorImage,
      honorMaterial: honorMaterial,
      documentPath: documentPath,
      completionDate: completionDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_honor_id': userHonorId,
    'honor_id': honorId,
    'honor_name': honorName,
    'validate': validate,
    'certificate': certificate,
    'images': images.map((img) => img.toJson()).toList(),
    'honor_image': honorImage,
    'honor_material': honorMaterial,
    'document': documentPath,
    'date': completionDate?.toIso8601String(),
  };
      
  /// Obtiene la URL del certificado si existe
  String getCertificateUrl() {
    if (certificate == null || certificate!.isEmpty) {
      return '';
    }
    
    // URL pública para certificados en el bucket users-honors
    const String baseUrl = 'https://pfjdavhuriyhtqyifwky.supabase.co/storage/v1/object/sign/';
    
    // Determinar si es una ruta completa o solo un nombre de archivo
    final String fileName = certificate!.contains('/') ? certificate!.split('/').last : certificate!;
    
    log('🔍 [UserHonor.getCertificateUrl] URL del certificado $baseUrl$bucketUserHonors/$fileName');
    return '$baseUrl$bucketUserHonors/$fileName';
  }
  
  /// Obtiene las URLs públicas de las imágenes de evidencia subidas por el usuario
  List<String> getEvidenceImageUrls() {
    log('Inicia getEvidenceImageUrls');
    if (images.isEmpty) {
      return [];
    }
    
    const String baseUrl = 'https://pfjdavhuriyhtqyifwky.supabase.co/storage/v1/object/sign/';
    
    // Convertir cada objeto de imagen a URL completa
    return images.map((imageData) {
      // Usar path completo si existe, o construir uno con el nombre de la imagen
      final String fileName = imageData.image;
      final String bucketPath = imageData.path.isNotEmpty 
          ? imageData.path
          : '$bucketUserHonors/$fileName';
          
      // Si ya contiene la ruta completa del bucket, usar solo el nombre del archivo
      final String finalPath = bucketPath.contains('/') 
          ? bucketPath.split('/').last 
          : bucketPath;
          
      log('🔍 [UserHonor.getEvidenceImageUrls] URL de la imagen $baseUrl$bucketUserHonors/$finalPath');
      return '$baseUrl$bucketUserHonors/$finalPath';
    }).toList();
  }
  
  /// Obtiene los nombres de archivo de las imágenes (para usar con getUserHonorImageSignedUrl)
  List<String> getEvidenceImageNames() {
    return images.map((imageData) => imageData.image).toList();
  }
  
  /// Obtiene las rutas completas de las imágenes (para usar con getUserHonorImageSignedUrl)
  List<String> getEvidenceImagePaths() {
    return images.map((imageData) => imageData.path).toList();
  }
  
  /// Obtiene las URLs firmadas de las imágenes de evidencia subidas por el usuario
  Future<List<String>> getSignedEvidenceImageUrls(SupabaseClient supabaseClient) async {
    if (images.isEmpty) {
      return [];
    }
    
    final List<String> signedUrls = [];
    
    for (ImageData imageData in images) {
      try {
        // Extraer nombre de archivo de la ruta completa
        final String fileName = imageData.path.contains('/') 
            ? imageData.path.split('/').last 
            : imageData.image;
        
        // Generar URL firmada para acceso privado desde el bucket users-honors
        final signedUrl = await supabaseClient.storage
            .from(bucketUserHonors)
            .createSignedUrl(fileName, 60 * 60 * 24); // 24 horas
        
        signedUrls.add(signedUrl);
      } catch (e) {
        log('Error al generar URL firmada para imagen de evidencia ${imageData.image}: $e');
        // Añadir string vacío para mantener el mismo orden
        signedUrls.add('');
      }
    }
    
    return signedUrls;
  }
  
  /// Obtiene la URL firmada del certificado
  Future<String> getSignedCertificateUrl(SupabaseClient supabaseClient) async {
    if (certificate == null || certificate!.isEmpty) {
      return '';
    }
    
    try {
      // Determinar si es una ruta completa o solo un nombre de archivo
      final String fileName = certificate!.contains('/') ? certificate!.split('/').last : certificate!;
      
      // Generar URL firmada para acceso privado desde el bucket users-honors
      final signedUrl = await supabaseClient.storage
          .from(bucketUserHonors)
          .createSignedUrl(fileName, 60 * 60 * 24); // 24 horas
      
      return signedUrl;
    } catch (e) {
      log('Error al generar URL firmada para certificado $certificate: $e');
      return '';
    }
  }
  
  /// Obtiene la URL de la imagen principal de la especialidad (honor_image)
  /// Si no hay imagen, devuelve una cadena vacía
  String getHonorImageUrl() {
    if (honorImage == null || honorImage!.isEmpty) {
      return '';
    }
    
    // URL pública para imágenes de especialidades
    const String baseUrl = 'https://pfjdavhuriyhtqyifwky.supabase.co/storage/v1/object/sign/';
    return '$baseUrl$bucketHonors/$honorImage';
  }
  
  /// Obtiene la URL del material PDF de la especialidad
  /// Si no hay material, devuelve una cadena vacía
  String getHonorMaterialUrl() {
    if (honorMaterial == null || honorMaterial!.isEmpty) {
      return '';
    }
    
    // URL pública para materiales PDF de especialidades
    const String baseUrl = 'https://pfjdavhuriyhtqyifwky.supabase.co/storage/v1/object/sign/';
    return '$baseUrl$bucketHonorsPdf/$honorMaterial';
  }
  
  /// Obtiene la URL firmada de la imagen principal de la especialidad
  /// Este método debe ser llamado desde un servicio que tenga acceso al cliente de Supabase
  Future<String> getSignedHonorImageUrl(SupabaseClient supabaseClient) async {
    if (honorImage == null || honorImage!.isEmpty) {
      return '';
    }
    
    try {
      // Generar URL firmada para acceso privado
      final signedUrl = await supabaseClient.storage
          .from(bucketHonors)
          .createSignedUrl(honorImage!, 60 * 60 * 24); // 24 horas
      
      return signedUrl;
    } catch (e) {
      log('Error al generar URL firmada para $honorImage: $e');
      return '';
    }
  }
} 