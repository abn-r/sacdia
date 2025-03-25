import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sacdia/core/auth_events/auth_event_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Widget que escucha eventos de autenticación y muestra notificaciones al usuario
class AuthEventListener extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSessionExpired;

  const AuthEventListener({
    super.key,
    required this.child,
    this.onSessionExpired,
  });

  @override
  State<AuthEventListener> createState() => _AuthEventListenerState();
}

class _AuthEventListenerState extends State<AuthEventListener> {
  late final AuthEventService _authEventService;
  late final StreamSubscription<AuthEvent> _subscription;

  @override
  void initState() {
    super.initState();
    _authEventService = AuthEventService();
    
    // Suscribirse al stream de eventos de autenticación
    _subscription = _authEventService.onAuthEvent.listen(_handleAuthEvent);
  }

  @override
  void dispose() {
    // Cancelar la suscripción cuando se destruye el widget
    _subscription.cancel();
    super.dispose();
  }

  /// Maneja los eventos de autenticación recibidos
  void _handleAuthEvent(AuthEvent event) {
    // No mostrar notificaciones si la aplicación está en segundo plano o en proceso de cierre
    if (!mounted) return;
    
    switch (event.type) {
      case AuthEventType.sessionExpired:
        _showAuthNotification(
          title: 'Sesión expirada',
          message: event.message ?? 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.',
          isError: true,
          onAction: _handleSessionExpired,
        );
        break;
        
      case AuthEventType.renewalFailed:
        _showAuthNotification(
          title: 'Error de renovación',
          message: event.message ?? 'No fue posible renovar tu sesión automáticamente.',
          isWarning: true,
          onAction: _handleSessionExpired,
        );
        break;
        
      case AuthEventType.unauthorized:
        _showAuthNotification(
          title: 'Acceso denegado',
          message: event.message ?? 'No tienes permiso para realizar esta acción.',
          isWarning: true,
        );
        break;
    }
  }

  /// Muestra una notificación de autenticación en la pantalla
  void _showAuthNotification({
    required String title,
    required String message,
    bool isError = false,
    bool isWarning = false,
    VoidCallback? onAction,
  }) {
    // Determinar el color de la notificación según su tipo
    Color backgroundColor = isError 
        ? Colors.red.shade800 
        : (isWarning ? Colors.orange.shade800 : Colors.blue.shade800);
        
    // Mostrar un Snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(message),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: onAction != null ? SnackBarAction(
          label: 'Iniciar sesión',
          textColor: Colors.white,
          onPressed: onAction,
        ) : null,
      ),
    );
  }
  
  /// Maneja el evento cuando la sesión ha expirado
  void _handleSessionExpired() {
    // Si se proporciona un callback personalizado, usarlo
    if (widget.onSessionExpired != null) {
      widget.onSessionExpired!();
      return;
    }
    
    // Comportamiento predeterminado: cerrar sesión y redirigir al login
    _signOut();
  }
  
  /// Cierra la sesión actual y redirige al login
  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      
      // Usar GoRouter para navegar a la pantalla de login
      GoRouter.of(context).go('/login');
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
      // Forzar redirección al login incluso si falla el cierre de sesión
      if (mounted) {
        GoRouter.of(context).go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Este widget no modifica la interfaz, solo escucha eventos
    return widget.child;
  }
} 