// ignore_for_file: empty_catches
import 'dart:developer';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sacdia/core/constants.dart';
import 'package:sacdia/features/honor/models/user_honor_category_model.dart';
import 'package:sacdia/features/honor/models/user_honor_model.dart';
import 'package:sacdia/features/honor/services/honor_service.dart';

// Estados
abstract class UserHonorsState extends Equatable {
  const UserHonorsState();

  @override
  List<Object?> get props => [];
}

class UserHonorsInitial extends UserHonorsState {}

class UserHonorsLoading extends UserHonorsState {}

class UserHonorsLoaded extends UserHonorsState {
  final List<UserHonorCategory> categories;
  final bool fromCache;

  const UserHonorsLoaded(this.categories, {this.fromCache = false});

  @override
  List<Object?> get props => [categories, fromCache];
}

class UserHonorsError extends UserHonorsState {
  final String message;

  const UserHonorsError(this.message);

  @override
  List<Object?> get props => [message];
}

class UserHonorSaving extends UserHonorsState {}

class UserHonorSaved extends UserHonorsState {}

class UserHonorError extends UserHonorsState {
  final String message;

  const UserHonorError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class UserHonorsCubit extends Cubit<UserHonorsState> {
  final HonorService _honorService;

  // Caché para las especialidades del usuario
  List<UserHonorCategory>? _cachedCategories;

  // Caché para las URLs firmadas de imágenes
  final Map<String, String> _imageUrlCache = {};

  // Timestamp de la última actualización
  DateTime? _lastUpdateTime;

  UserHonorsCubit({required HonorService honorService})
      : _honorService = honorService,
        super(UserHonorsInitial());

  Future<void> getUserHonors({bool forceRefresh = false}) async {
    try {
      // Si ya tenemos datos en caché y no se fuerza actualización, usarlos
      if (!forceRefresh &&
          _cachedCategories != null &&
          _cachedCategories!.isNotEmpty) {
        emit(UserHonorsLoaded(_cachedCategories!, fromCache: true));
        return;
      }

      emit(UserHonorsLoading());

      // Obtener datos de especialidades del usuario
      final categories = await _honorService.getUserHonorsByCategory();

      // Ya no es necesario consultar getAllHonors porque ahora la API ya devuelve honor_image directamente
      // para cada especialidad del usuario

      // Actualizar caché
      _cachedCategories = categories;
      _lastUpdateTime = DateTime.now();

      emit(UserHonorsLoaded(categories));
    } catch (e) {
      emit(UserHonorsError(e.toString()));
    }
  }

  Future<void> createUserHonor({
    required int honorId,
    File? certificateFile,
    List<File> images = const [],
    DateTime? completionDate,
  }) async {
    try {
      emit(UserHonorSaving());

      final success = await _honorService.createUserHonor(
        honorId: honorId,
        certificateFile: certificateFile,
        images: images,
        completionDate: completionDate,
      );

      if (success) {
        // Invalidar caché para forzar recarga
        _cachedCategories = null;
        _imageUrlCache.clear();

        // Recargar las especialidades del usuario
        await getUserHonors(forceRefresh: true);
        emit(UserHonorSaved());
      } else {
        emit(const UserHonorError('Error al guardar la especialidad'));
      }
    } catch (e) {
      emit(UserHonorError(e.toString()));
    }
  }

  Future<void> updateUserHonor({
    required int userHonorId,
    File? certificateFile,
    List<File> images = const [],
    DateTime? completionDate,
  }) async {
    try {
      emit(UserHonorSaving());

      final success = await _honorService.updateUserHonor(
        userHonorId: userHonorId,
        certificateFile: certificateFile,
        images: images,
        completionDate: completionDate,
      );

      if (success) {
        // Invalidar caché para forzar recarga
        _cachedCategories = null;
        _imageUrlCache.clear();

        // Recargar las especialidades del usuario
        await getUserHonors(forceRefresh: true);
        emit(UserHonorSaved());
      } else {
        emit(const UserHonorError('Error al actualizar la especialidad'));
      }
    } catch (e) {
      emit(UserHonorError(e.toString()));
    }
  }

  Future<void> deleteUserHonor(int userHonorId) async {
    try {
      emit(UserHonorSaving());

      final success = await _honorService.deleteUserHonor(userHonorId);

      if (success) {
        // Invalidar caché para forzar recarga
        _cachedCategories = null;
        _imageUrlCache.clear();

        // Recargar las especialidades del usuario
        await getUserHonors(forceRefresh: true);
        emit(UserHonorSaved());
      } else {
        emit(const UserHonorError('Error al eliminar la especialidad'));
      }
    } catch (e) {
      emit(UserHonorError(e.toString()));
    }
  }

  // Método para obtener URL firmada con caché
  Future<String> getHonorImageSignedUrl(String? imagePath,
      {int? honorId, String? bucketName}) async {
    // Caso 1: Si tenemos una ruta de imagen, intentar obtener la URL
    if (imagePath != null && imagePath.isNotEmpty) {
      // Crear una clave de caché que incluya el bucket si se especifica
      final cacheKey = bucketName != null 
          ? '${bucketName}_$imagePath' 
          : imagePath;
          
      // Si ya está en caché, retornarla
      if (_imageUrlCache.containsKey(cacheKey)) {
        return _imageUrlCache[cacheKey]!;
      }

      // Si no, obtenerla del servicio y guardarla en caché
      try {
        final url = await _honorService.getHonorImageSignedUrl(
          imagePath, 
          bucketName: bucketName ?? bucketHonors // Usar bucketName si se proporciona, de lo contrario usar honors
        );

        if (url.isNotEmpty) {
          _imageUrlCache[cacheKey] = url;
          return url;
        }
      } catch (e) {
        log('❌ Error obteniendo URL firmada: $e');
      }
    } else {}

    // Caso 2: Si tenemos el honorId, intentar buscar la imagen en la caché de Honor
    if (honorId != null) {
      // Clave para caché basada en el ID
      final cacheKey = 'honor_id_$honorId';

      // Verificar si ya tenemos la URL en caché
      if (_imageUrlCache.containsKey(cacheKey)) {
        return _imageUrlCache[cacheKey]!;
      }

      // Si no, buscar la imagen de la especialidad
      try {
        final honorImagePath = await _honorService.getHonorImageById(honorId);

        if (honorImagePath != null && honorImagePath.isNotEmpty) {
          // Obtener URL firmada para esta imagen
          final url =
              await _honorService.getHonorImageSignedUrl(honorImagePath);

          if (url.isNotEmpty) {
            // Guardar en caché
            _imageUrlCache[cacheKey] = url;
            _imageUrlCache[honorImagePath] = url; // También guardar por path
            return url;
          }
        } else {}
      } catch (e) {}
    }

    // Si llegamos aquí, no pudimos obtener la imagen
    return '';
  }

  // Método para limpiar caché manualmente
  void clearCache() {
    _cachedCategories = null;
    _imageUrlCache.clear();
    _lastUpdateTime = null;
  }

  // Getter para verificar si hay datos en caché
  bool get hasCachedData =>
      _cachedCategories != null && _cachedCategories!.isNotEmpty;

  // Getter para obtener la última actualización
  DateTime? get lastUpdateTime => _lastUpdateTime;

  // Método para obtener URL firmada de una imagen de certificado o evidencia de usuario
  Future<String> getUserHonorImageSignedUrl(String? imagePath) async {
    // Si es nulo o vacío, retornar cadena vacía
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }

    // Clave para caché
    final cacheKey = 'user_honor_$imagePath';

    // Si ya está en caché, retornarla
    if (_imageUrlCache.containsKey(cacheKey)) {
      return _imageUrlCache[cacheKey]!;
    }

    // Si no, obtenerla del servicio y guardarla en caché
    try {
      final url = await _honorService.getUserHonorImageSignedUrl(imagePath);

      if (url.isNotEmpty) {
        _imageUrlCache[cacheKey] = url;
        return url;
      }
    } catch (e) {}

    return '';
  }

  // Método para obtener URLs firmadas para varias imágenes de evidencia
  Future<List<String>> getSignedEvidenceImageUrls(
      List<ImageData> images) async {
    final List<String> signedUrls = [];

    // Si es una lista vacía, devolver una lista vacía
    if (images.isEmpty) {
      return signedUrls;
    }

    // Obtener todas las rutas
    for (ImageData imageData in images) {
      try {
        // Preferir la ruta completa si está disponible
        final String pathToUse =
            imageData.path.isNotEmpty ? imageData.path : imageData.image;
        final String fileName =
            pathToUse.contains('/') ? pathToUse.split('/').last : pathToUse;

        // Obtener URL firmada
        final url = await getUserHonorImageSignedUrl(fileName);
        signedUrls.add(url);
      } catch (e) {
        signedUrls.add(''); // Añadir string vacío para mantener el índice
      }
    }

    return signedUrls;
  }

  // Método para mantener compatibilidad con código existente usando listas de strings
  Future<List<String>> getSignedEvidenceImageUrlsFromPaths(
      List<String> imagePaths) async {
    final List<String> signedUrls = [];

    for (String path in imagePaths) {
      final url = await getUserHonorImageSignedUrl(path);
      signedUrls.add(url);
    }

    return signedUrls;
  }
}
