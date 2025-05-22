import 'package:sacdia/features/honor/models/user_honor_model.dart';
import 'package:sacdia/core/constants.dart';

/// Entidad de especialidad para un usuario
/// 
/// Esta clase es utilizada para manejar los datos de las especialidades de un usuario
/// recibidos desde la API y mapeados a objetos UserHonor para su uso en la UI
class UserHonorEntity {
  final int userHonorId;
  final int honorId;
  final String honorName;
  final bool validate;
  final String? certificate;
  final List<ImageData> images;
  final String? honorImage;
  final String? honorMaterial;
  final String? description;
  final DateTime? completionDate;

  UserHonorEntity({
    required this.userHonorId,
    required this.honorId,
    required this.honorName,
    this.validate = false,
    this.certificate,
    this.images = const [],
    this.honorImage,
    this.honorMaterial,
    this.description,
    this.completionDate,
  });

  /// Crea una instancia de UserHonorEntity desde un mapa JSON
  factory UserHonorEntity.fromJson(Map<String, dynamic> json) {
    // Procesamiento especial para la fecha de término
    DateTime? completionDate;
    if (json['date'] != null) {
      try {
        completionDate = DateTime.parse(json['date']);
      } catch (e) {
        print('❌ [UserHonorEntity.fromJson] Error al parsear fecha: $e');
      }
    }
    
    // Procesamiento especial para imágenes
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
              print('⚠️ [UserHonorEntity.fromJson] Formato de imagen no reconocido: $imageData');
              return ImageData(image: '', path: '');
            }
          }).toList();
        } catch (e) {
          print('❌ [UserHonorEntity.fromJson] Error al procesar imágenes: $e');
        }
      } else if (json['images'] is String) {
        // Si es un string, podría ser un JSON serializado
        print('⚠️ [UserHonorEntity.fromJson] Campo images es un string: ${json['images']}');
        try {
          // Intentar parsear la cadena como JSON si es necesario
          // ...
        } catch (e) {
          print('❌ [UserHonorEntity.fromJson] Error al parsear string de imágenes: $e');
        }
      }
    }

    return UserHonorEntity(
      userHonorId: json['user_honor_id'] ?? 0,
      honorId: json['honor_id'] ?? 0,
      honorName: json['honor_name'] ?? '',
      validate: json['validate'] ?? false,
      certificate: json['certificate'],
      images: images,
      honorImage: json['honor_image'],
      honorMaterial: json['honor_material'],
      description: json['document'],
      completionDate: completionDate,
    );
  }

  /// Convierte la entidad a un mapa JSON
  Map<String, dynamic> toJson() => {
        'user_honor_id': userHonorId,
        'honor_id': honorId,
        'honor_name': honorName,
        'validate': validate,
        'certificate': certificate,
        'images': images.map((img) => img.toJson()).toList(),
        'honor_image': honorImage,
        'honor_material': honorMaterial,
        'description': description,
        'date': completionDate?.toIso8601String(),
      };
      
  /// Convierte la entidad a un modelo UserHonor para uso en la UI
  UserHonor toUserHonor() {
    return UserHonor(
      userHonorId: userHonorId,
      honorId: honorId,
      honorName: honorName,
      validate: validate,
      certificate: certificate,
      images: images,
      honorImage: honorImage,
      honorMaterial: honorMaterial,
      documentPath: description,
      completionDate: completionDate,
    );
  }
  
  /// Obtiene la URL de la imagen principal de la especialidad (honor_image)
  String getHonorImageUrl() {
    if (honorImage == null || honorImage!.isEmpty) {
      return '';
    }
    
    // URL pública para imágenes de especialidades
    const String baseUrl = 'https://pfjdavhuriyhtqyifwky.supabase.co/storage/v1/object/sign/';
    return '$baseUrl$bucketHonors/$honorImage';
  }
  
  /// Obtiene la URL del material PDF de la especialidad
  String getHonorMaterialUrl() {
    if (honorMaterial == null || honorMaterial!.isEmpty) {
      return '';
    }
    
    // URL pública para materiales PDF de especialidades
    const String baseUrl = 'https://pfjdavhuriyhtqyifwky.supabase.co/storage/v1/object/sign/';
    return '$baseUrl$bucketHonorsPdf/$honorMaterial';
  }
} 