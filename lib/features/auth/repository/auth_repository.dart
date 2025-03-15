import 'dart:async';
import 'package:dio/dio.dart';
import 'package:sacdia/features/auth/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sacdia/core/constants.dart';

class AuthRepository {
  final Dio dio;
  final SupabaseClient supabaseClient;

  Timer? _refreshTimer;

  AuthRepository({
    required this.dio,
    required this.supabaseClient,
  });

  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session == null) {
        return null;
      }

      final userId = response.user?.id ?? '';
      final postRegisterComplete = await checkPostRegisterComplete(userId);

      return UserModel(
        id: userId,
        email: response.user?.email ?? '',
        postRegisterComplete: postRegisterComplete,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Registro nuevo usuario: 
  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String paternalSurname,
    required String maternalSurname,
  }) async {
    try {
      final singUp = await dio.post('$api/auth/signUp', data: {
        "email": email,
        "password": password,
        "name": name,
        "p_lastname": paternalSurname,
        "m_lastname": maternalSurname,
      });

      final userId = singUp.data['user_id'] as String;
      final accessToken = singUp.data['access_token'] as String;

      final postRegisterComplete = await checkPostRegisterComplete(userId);

      return UserModel(
        id: userId,
        email: email,
        postRegisterComplete: postRegisterComplete,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Verifica si el usuario ya completó el post-registro en la API
  Future<bool> checkPostRegisterComplete(String userId) async {
    try {
      final response = await dio.post('$api/auth/pr-check', data: {'user_id': userId});
      if (response.data != null && response.data['complete'] == true) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> completePostRegister(String userId) async {
    try {
      final response = await dio.post('$api/auth/pr-complete', data: {'user_id': userId});
      print('Respuesta del completePostRegister');
      print(response.statusCode);
      print(response.data);
      print('Fin de respuesta del completePostRegister');
      return;
    } catch (e) {
      rethrow;
    }
  }

  /// Recuperar contraseña (Supabase envía un correo)
  Future<void> resetPassword(String email) async {
    try {
      await supabaseClient.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    try {
      _refreshTimer?.cancel();
      await supabaseClient.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  Future<String> getValidToken() async {
    final session = supabaseClient.auth.currentSession;
    
    // Si la sesión está por expirar, renovarla
    if (session != null && 
        session.expiresAt != null && 
        DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000)
            .difference(DateTime.now())
            .inMinutes < 5) {
      await supabaseClient.auth.refreshSession();
    }
    
    return supabaseClient.auth.currentSession?.accessToken ?? '';
  }
}