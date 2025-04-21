import 'package:supabase_flutter/supabase_flutter.dart';

class Honor {
  final int honorId;
  final String name;
  final String? description;
  final String? honorImage;
  final String? materialUrl;
  final bool active;
  final int honorsCategoryId;

  Honor({
    required this.honorId,
    required this.name,
    this.description,
    this.honorImage,
    this.materialUrl,
    this.active = true,
    required this.honorsCategoryId,
  });

  factory Honor.fromJson(Map<String, dynamic> json) {
    return Honor(
      honorId: json['honor_id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      honorImage: json['honor_image'],
      materialUrl: json['material_url'],
      active: json['active'] ?? true,
      honorsCategoryId: json['honors_category_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'honor_id': honorId,
        'name': name,
        'description': description,
        'honor_image': honorImage,
        'material_url': materialUrl,
        'active': active,
        'honors_category_id': honorsCategoryId,
      };
      
  /// Obtiene la URL de la imagen de la especialidad
  /// Si no hay imagen, devuelve una cadena vacía
  String getImageUrl() {
    if (honorImage == null || honorImage!.isEmpty) {
      return '';
    }
    
    // URL pública para imágenes públicas
    const String baseUrl = 'https://pfjdavhuriyhtqyifwky.supabase.co/storage/v1/object/sign/honors/';
    return '$baseUrl$honorImage';
  }
  
  /// Obtiene la URL firmada de la imagen de la especialidad utilizando el cliente de Supabase
  /// Este método debe ser llamado desde un servicio que tenga acceso al cliente de Supabase
  /// No usar directamente en la UI, utilizar en combinación con HonorService
  Future<String> getSignedImageUrl(SupabaseClient supabaseClient) async {
    if (honorImage == null || honorImage!.isEmpty) {
      return '';
    }
    
    try {
      // Generar URL firmada para acceso privado
      final signedUrl = await supabaseClient.storage
          .from('honors')
          .createSignedUrl(honorImage!, 60 * 60 * 24); // 24 horas
      
      return signedUrl;
    } catch (e) {
      print('Error al generar URL firmada para $honorImage: $e');
      return '';
    }
  }
} 