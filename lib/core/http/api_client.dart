import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sacdia/core/auth_events/auth_event_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Cliente API centralizado que maneja automáticamente la renovación de tokens
class ApiClient {
  final Dio _dio;
  final SupabaseClient _supabase;
  final _tokenRefreshLock = Lock();
  final AuthEventService _authEventService = AuthEventService();
  
  // Controla los reintentos máximos de renovación de token antes de considerar el error irrecuperable
  final int _maxRenewalRetries = 3;
  int _renewalAttempts = 0;
  
  // Singleton para asegurar una sola instancia
  static final ApiClient _instance = ApiClient._internal();
  
  factory ApiClient() {
    return _instance;
  }
  
  ApiClient._internal()
      : _dio = Dio(),
        _supabase = Supabase.instance.client {
    // Configurar interceptores para manejar tokens
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }
  
  Dio get dio => _dio;
  
  /// Interceptor para añadir el token de autenticación a cada solicitud
  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Verificar si el token está por expirar (menos de 5 minutos de vida)
    final session = _supabase.auth.currentSession;
    if (session != null) {
      final expiresAt = session.expiresAt;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      // Si el token expira en menos de 5 minutos, intentar renovarlo antes de la solicitud
      if (expiresAt != null && expiresAt - now < 300) { // 300 segundos = 5 minutos
        try {
          await _refreshToken();
          // Reiniciar contador de intentos si la renovación fue exitosa
          _renewalAttempts = 0;
        } catch (e) {
          print('⚠️ Error preventivo al renovar token: $e');
          // Continuamos con el token actual aunque esté por expirar
        }
      }
      
      // Añadir el token (renovado o el actual) a la solicitud
      final token = _supabase.auth.currentSession?.accessToken;
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    
    // Añadir Content-Type común
    options.headers['Content-Type'] = 'application/json';
    
    // Continuar con la solicitud
    handler.next(options);
  }
  
  /// Interceptor para manejar errores, especialmente 401 (token expirado)
  Future<void> _onError(DioException error, ErrorInterceptorHandler handler) async {
    if (error.response?.statusCode == 401) {
      // Token expirado, intentar renovarlo
      try {
        final request = error.requestOptions;
        
        // Verificar si ya hemos intentado demasiadas veces
        if (_renewalAttempts >= _maxRenewalRetries) {
          // Emitir evento de error irrecuperable
          _authEventService.emitRenewalFailed(
            message: 'No fue posible renovar la sesión después de $_maxRenewalRetries intentos',
            error: error
          );
          
          // Reiniciar contador para futuros intentos
          _renewalAttempts = 0;
          
          // Continuar con el flujo de error
          handler.next(error);
          return;
        }
        
        // Incrementar contador de intentos
        _renewalAttempts++;
        
        // Usar lock para evitar múltiples renovaciones simultáneas
        await _tokenRefreshLock.synchronized(() async {
          // Verificar si el token ya fue renovado por otra solicitud mientras esperaba
          if (_isTokenExpired()) {
            await _refreshToken();
          }
        });
        
        // Volver a intentar la solicitud original con el nuevo token
        final token = _supabase.auth.currentSession?.accessToken;
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
          
          // Crear una nueva solicitud con las mismas opciones
          final response = await _dio.fetch(request);
          handler.resolve(response);
          return;
        }
      } catch (e) {
        print('❌ Error al renovar token: $e');
        
        // Emitir evento de error de renovación
        _authEventService.emitRenewalFailed(
          message: 'Error al renovar la sesión: ${e.toString()}',
          error: e
        );
      }
    } else if (error.response?.statusCode == 403) {
      // xsxError de autorización (permiso revocado o insuficiente)
      _authEventService.emitUnauthorized(
        message: 'No tienes permiso para realizar esta acción',
        error: error
      );
    }
    
    // Si llegamos aquí, no pudimos manejar el error, continuamos con el flujo de error normal
    handler.next(error);
  }
  
  /// Comprueba si el token actual está expirado
  bool _isTokenExpired() {
    final session = _supabase.auth.currentSession;
    if (session == null) return true;
    
    final expiresAt = session.expiresAt;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    return expiresAt == null || expiresAt <= now;
  }
  
  /// Renueva el token de autenticación
  Future<void> _refreshToken() async {
    try {
      print('🔄 Iniciando renovación de token...');
      
      // Supabase renueva automáticamente el token con refreshSession
      final response = await _supabase.auth.refreshSession();
      final newSession = response.session;
      
      if (newSession != null) {
        final expiresAt = newSession.expiresAt;
        if (expiresAt != null) {
          print('✅ Token renovado exitosamente. Nuevo vencimiento: ${DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000)}');
        } else {
          print('✅ Token renovado exitosamente, pero no tiene fecha de expiración definida');
        }
      } else {
        print('⚠️ La renovación del token no generó una nueva sesión');
        
        // Emitir evento de sesión expirada si no se pudo renovar
        _authEventService.emitSessionExpired();
        throw Exception('No se pudo renovar el token');
      }
    } catch (e) {
      print('❌ Error al renovar token: $e');
      
      // Emitir evento de error de renovación
      _authEventService.emitRenewalFailed(
        message: 'No se pudo renovar la sesión automáticamente',
        error: e
      );
      
      // Propagar el error para que pueda ser manejado por quien llama a este método
      rethrow;
    }
  }
}

/// Lock simple para sincronización
class Lock {
  Completer<void>? _completer;
  
  Future<T> synchronized<T>(Future<T> Function() action) async {
    // Esperar si hay un lock activo
    if (_completer != null) {
      await _completer!.future;
    }
    
    // Crear nuevo lock
    _completer = Completer<void>();
    
    try {
      // Ejecutar la acción
      final result = await action();
      // Liberar el lock
      _completer!.complete();
      return result;
    } catch (e) {
      // Liberar el lock incluso en caso de error
      _completer!.complete();
      rethrow;
    }
  }
} 