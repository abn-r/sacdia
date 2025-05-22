import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sacdia/core/auth_events/auth_event_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:sacdia/features/auth/bloc/auth_bloc.dart';
import 'package:sacdia/features/auth/bloc/auth_event.dart';

/// Cliente API centralizado que maneja automáticamente la renovación de tokens
/// y proporciona gestión global de errores de autenticación
class ApiClient {
  final Dio _dio;
  final SupabaseClient _supabase;
  final _tokenRefreshLock = Lock();
  bool _enableDetailedLogs;
  
  // Controla los reintentos máximos de renovación de token antes de considerar el error irrecuperable
  final int _maxRenewalRetries = 3;
  int _renewalAttempts = 0;
  
  // Utiliza GetIt para obtener una instancia de AuthEventService
  AuthEventService get _authEventService => GetIt.I<AuthEventService>();
  
  // Singleton para asegurar una sola instancia
  static final ApiClient _instance = ApiClient._internal();
  
  factory ApiClient({bool enableDetailedLogs = false}) {
    _instance._enableDetailedLogs = enableDetailedLogs;
    return _instance;
  }
  
  ApiClient._internal()
      : _dio = Dio(),
        _supabase = Supabase.instance.client,
        _enableDetailedLogs = false {
    _configureInterceptors();
  }
  
  Dio get dio => _dio;
  
  /// Configura todos los interceptores necesarios
  void _configureInterceptors() {
    // Interceptor para manejo de request/response/error
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
    
    // Añadir interceptor de logs para facilitar depuración si está habilitado
    if (_enableDetailedLogs) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) {
          debugPrint('🌐 DIO: $object');
        }
      ));
    }
  }
  
  /// Interceptor para añadir el token de autenticación a cada solicitud
  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (_enableDetailedLogs) {
      debugPrint('📤 API Request: ${options.method} ${options.path}');
    }
    
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
          debugPrint('⚠️ Error preventivo al renovar token: $e');
          // Continuamos con el token actual aunque esté por expirar
        }
      }
      
      // Añadir el token (renovado o el actual) a la solicitud
      final token = _supabase.auth.currentSession?.accessToken;
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
        
        if (_enableDetailedLogs) {
          final truncatedToken = token.length > 15 
            ? '${token.substring(0, 10)}...${token.substring(token.length - 5)}'
            : token;
          debugPrint('🔑 Token añadido a la solicitud: $truncatedToken');
        }
      }
    }
    
    // Añadir Content-Type común
    options.headers['Content-Type'] = 'application/json';
    
    // Continuar con la solicitud
    handler.next(options);
  }
  
  /// Interceptor para manejar respuestas exitosas
  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    if (_enableDetailedLogs) {
      debugPrint('📥 API Response [${response.statusCode}]: ${response.requestOptions.path}');
    }
    
    // Reiniciar contador de intentos después de una respuesta exitosa
    if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
      _renewalAttempts = 0;
    }
    
    handler.next(response);
  }
  
  /// Interceptor para manejar errores, especialmente 401 (token expirado) y 403 (no autorizado)
  Future<void> _onError(DioException error, ErrorInterceptorHandler handler) async {
    if (_enableDetailedLogs) {
      debugPrint('❌ API Error [${error.response?.statusCode}]: ${error.requestOptions.path}');
      debugPrint('Error detalle: ${error.message}');
    }
    
    // Manejar código 401 - Token expirado / Sesión inválida
    if (error.response?.statusCode == 401) {
      await _handle401Error(error, handler);
      return;
    } 
    // Manejar código 403 - Acceso denegado / Permisos insuficientes
    else if (error.response?.statusCode == 403) {
      _handle403Error(error, handler);
      return;
    }
    // Si hay una respuesta con código 400 (Bad Request), revisar si es un problema de formato 
    // o validación, y formatear un mensaje más amigable
    else if (error.response?.statusCode == 400 && error.response?.data is Map) {
      final data = error.response?.data as Map;
      if (data.containsKey('message')) {
        final errorMessage = data['message'];
        debugPrint('🛑 Error de validación API: $errorMessage');
      }
    }
    
    // Si llegamos aquí, no pudimos manejar el error, continuamos con el flujo de error normal
    handler.next(error);
  }
  
  /// Maneja específicamente los errores 401 (Unauthorized)
  Future<void> _handle401Error(DioException error, ErrorInterceptorHandler handler) async {
    try {
      final request = error.requestOptions;
      
      // Verificar si ya hemos intentado demasiadas veces
      if (_renewalAttempts >= _maxRenewalRetries) {
        // Intentar cerrar sesión automáticamente si es un error persistente
        _forceLogout(
          'No fue posible renovar la sesión después de $_maxRenewalRetries intentos',
          error
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
        
        if (_enableDetailedLogs) {
          debugPrint('🔄 Reintentando solicitud con nuevo token');
        }
        
        // Crear una nueva solicitud con las mismas opciones
        final response = await _dio.fetch(request);
        handler.resolve(response);
        return;
      }
    } catch (e) {
      debugPrint('❌ Error al renovar token: $e');
      
      // Emitir evento de error de renovación
      _authEventService.emitRenewalFailed(
        message: 'Error al renovar la sesión: ${e.toString()}',
        error: e
      );
      
      // Si los reintentos superan el máximo, forzar logout
      if (_renewalAttempts >= _maxRenewalRetries) {
        _forceLogout(
          'No fue posible renovar la sesión después de $_maxRenewalRetries intentos',
          error
        );
      }
    }
    
    // Si llegamos aquí, no pudimos resolver el error
    handler.next(error);
  }
  
  /// Maneja errores 403 (Forbidden)
  void _handle403Error(DioException error, ErrorInterceptorHandler handler) {
    // Extraer mensaje de error si está disponible
    String message = 'No tienes permiso para realizar esta acción';
    if (error.response?.data is Map && error.response!.data.containsKey('message')) {
      message = error.response!.data['message'];
    }
    
    // Emitir evento de error de autorización
    _authEventService.emitUnauthorized(
      message: message,
      error: error
    );
    
    // Continuar con el flujo de error
    handler.next(error);
  }
  
  /// Fuerza el cierre de sesión en caso de errores de autenticación irrecuperables
  void _forceLogout(String message, dynamic error) {
    debugPrint('🔐 Forzando cierre de sesión por error irrecuperable');
    
    // Emitir evento de sesión expirada
    _authEventService.emitSessionExpired(
      message: message
    );
    
    // Intentar cerrar sesión a través del AuthBloc
    try {
      final authBloc = GetIt.I<AuthBloc>();
      authBloc.add(SignOutRequested());
    } catch (e) {
      debugPrint('⚠️ No se pudo acceder al AuthBloc para cerrar sesión: $e');
    }
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
      if (_enableDetailedLogs) {
        debugPrint('🔄 Iniciando renovación de token...');
      }
      
      // Supabase renueva automáticamente el token con refreshSession
      final response = await _supabase.auth.refreshSession();
      final newSession = response.session;
      
      if (newSession != null) {
        final expiresAt = newSession.expiresAt;
        if (expiresAt != null) {
          final expiresAtDateTime = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
          debugPrint('✅ Token renovado exitosamente. Nuevo vencimiento: $expiresAtDateTime');
        } else {
          debugPrint('✅ Token renovado exitosamente, pero no tiene fecha de expiración definida');
        }
      } else {
        debugPrint('⚠️ La renovación del token no generó una nueva sesión');
        
        // Emitir evento de sesión expirada si no se pudo renovar
        _authEventService.emitSessionExpired();
        throw Exception('No se pudo renovar el token');
      }
    } catch (e) {
      debugPrint('❌ Error al renovar token: $e');
      
      // Emitir evento de error de renovación
      _authEventService.emitRenewalFailed(
        message: 'No se pudo renovar la sesión automáticamente',
        error: e
      );
      
      // Propagar el error para que pueda ser manejado por quien llama a este método
      rethrow;
    }
  }
  
  /// Método público para forzar la renovación del token
  /// Útil cuando se necesita asegurar un token fresco para operaciones críticas
  Future<bool> forceTokenRenewal() async {
    try {
      await _refreshToken();
      return true;
    } catch (e) {
      debugPrint('⚠️ Error al forzar renovación de token: $e');
      return false;
    }
  }
  
  /// Método público para obtener el token actual o renovarlo si está por expirar
  /// Útil para operaciones manuales que requieren el token
  Future<String?> getValidToken() async {
    if (_isTokenExpired() || _isTokenExpiringSoon()) {
      try {
        await _refreshToken();
      } catch (e) {
        debugPrint('⚠️ Error al obtener token válido: $e');
        return null;
      }
    }
    return _supabase.auth.currentSession?.accessToken;
  }
  
  /// Verifica si el token expirará pronto (en menos de 5 minutos)
  bool _isTokenExpiringSoon() {
    final session = _supabase.auth.currentSession;
    if (session == null) return true;
    
    final expiresAt = session.expiresAt;
    if (expiresAt == null) return false;
    
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return expiresAt - now < 300; // 300 segundos = 5 minutos
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