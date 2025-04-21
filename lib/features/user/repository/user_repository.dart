import 'package:dio/dio.dart';
import 'package:sacdia/core/constants.dart';
import 'package:sacdia/core/http/api_client.dart';
import 'package:sacdia/features/user/models/user_profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Interfaz para el repositorio de usuario
abstract class IUserRepository {
  /// Obtiene el perfil completo del usuario actual
  Future<UserProfileModel> getUserProfile();
  
  /// Cambia el tipo de club del usuario
  Future<UserProfileModel> changeClubType(int clubTypeId);
}

/// Implementación del repositorio de usuario
class UserRepository implements IUserRepository {
  final Dio _dio;
  final SupabaseClient _supabaseClient;
  
  UserRepository({
    Dio? dio,
    SupabaseClient? supabaseClient,
  }) : _dio = dio ?? ApiClient().dio,
       _supabaseClient = supabaseClient ?? Supabase.instance.client;
  
  /// Obtiene el ID del usuario autenticado o lanza una excepción si no existe
  String _getUserId() {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }
    return userId;
  }
  
  /// Obtiene los encabezados de autenticación para las peticiones a la API
  Map<String, String> _getAuthHeaders() {
    final String? token = _supabaseClient.auth.currentSession?.accessToken;
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
  
  @override
  Future<UserProfileModel> getUserProfile() async {
    try {
      final userId = _getUserId();
      final response = await _dio.get(
        '$api/users/$userId',
        options: Options(headers: _getAuthHeaders()),
      );
            
      if (response.statusCode == 200 && response.data != null) {
        if (response.data['status'] == true && response.data['data'] != null) {
          return UserProfileModel.fromJson(response.data['data']);
        } else {
          throw Exception('Formato de respuesta inválido');
        }
      } else {
        throw Exception('Error al obtener el perfil del usuario');
      }
    } catch (e) {
      print('Error obteniendo perfil: $e');
      rethrow;
    }
  }
  
  @override
  Future<UserProfileModel> changeClubType(int clubTypeId) async {
    try {
      final userId = _getUserId();
      final response = await _dio.patch(
        '$api/users/$userId/club-type',
        data: {'club_type_id': clubTypeId},
        options: Options(headers: _getAuthHeaders()),
      );
      
      if (response.statusCode == 200 && response.data != null) {
        return UserProfileModel.fromJson(response.data);
      } else {
        throw Exception('Error al cambiar el tipo de club');
      }
    } catch (e) {
      print('Error cambiando tipo de club: $e');
      rethrow;
    }
  }
} 