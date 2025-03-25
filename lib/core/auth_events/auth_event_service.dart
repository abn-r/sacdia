import 'dart:async';

enum AuthEventType {
  /// La sesión ha expirado y no se pudo renovar automáticamente
  sessionExpired,

  /// Falló el intento de renovar el token
  renewalFailed,
  
  /// El usuario no tiene autorización para realizar una acción (403)
  unauthorized,
}

class AuthEvent {
  final AuthEventType type;
  final String? message;
  final dynamic error;
  final DateTime timestamp;

  AuthEvent({
    required this.type,
    this.message,
    this.error,
  }) : timestamp = DateTime.now();
}

/// Servicio para manejar eventos de autenticación en toda la aplicación
class AuthEventService {
  /// Stream controller para emitir eventos de autenticación
  final _authEventController = StreamController<AuthEvent>.broadcast();
  
  /// Stream de eventos de autenticación al que los widgets pueden suscribirse
  Stream<AuthEvent> get onAuthEvent => _authEventController.stream;
  
  // Singleton para asegurar una sola instancia en toda la aplicación
  static final AuthEventService _instance = AuthEventService._internal();
  
  factory AuthEventService() {
    return _instance;
  }
  
  AuthEventService._internal();
  
  /// Emite un evento de sesión expirada
  void emitSessionExpired({String? message}) {
    _authEventController.add(
      AuthEvent(
        type: AuthEventType.sessionExpired,
        message: message ?? 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.',
      ),
    );
  }
  
  /// Emite un evento de error en la renovación de token
  void emitRenewalFailed({String? message, dynamic error}) {
    _authEventController.add(
      AuthEvent(
        type: AuthEventType.renewalFailed,
        message: message ?? 'No fue posible renovar tu sesión automáticamente.',
        error: error,
      ),
    );
  }
  
  /// Emite un evento de error de autorización
  void emitUnauthorized({String? message, dynamic error}) {
    _authEventController.add(
      AuthEvent(
        type: AuthEventType.unauthorized,
        message: message ?? 'No tienes permiso para realizar esta acción.',
        error: error,
      ),
    );
  }
  
  /// Cierra el controlador al finalizar la aplicación
  void dispose() {
    _authEventController.close();
  }
} 