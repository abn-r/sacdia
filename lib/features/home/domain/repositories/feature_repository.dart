import '../models/app_feature.dart';

/// Repositorio abstracto para manejar las características de la aplicación
abstract class FeatureRepository {
  /// Obtiene todas las características disponibles para el usuario
  Future<List<AppFeature>> getAvailableFeatures();
  
  /// Obtiene las características favoritas o más usadas por el usuario
  Future<List<AppFeature>> getFavoriteFeatures();
  
  /// Obtiene los roles del usuario actual
  Future<List<String>> getCurrentUserRoles();
  
  /// Actualiza el orden de las características para el usuario
  Future<void> updateFeatureOrder(List<String> featureIds);
  
  /// Marca una característica como favorita
  Future<void> toggleFeatureFavorite(String featureId);
} 