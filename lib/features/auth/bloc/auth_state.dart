import 'package:equatable/equatable.dart'; 
import 'package:sacdia/core/auth_events/auth_event_service.dart' as auth_service;
import 'package:sacdia/features/auth/models/user_model.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
  // ...
}

class AuthState extends Equatable {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  final bool isLoading;
  
  // Propiedades relacionadas a eventos de autenticación
  final bool hasAuthError;
  final auth_service.AuthEventType? authEventType;
  final DateTime? authErrorTimestamp;
  final bool isSessionExpired;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.isLoading = false,
    this.hasAuthError = false,
    this.authEventType,
    this.authErrorTimestamp,
    this.isSessionExpired = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    bool? isLoading,
    bool? hasAuthError,
    auth_service.AuthEventType? authEventType,
    DateTime? authErrorTimestamp,
    bool? isSessionExpired,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
      hasAuthError: hasAuthError ?? this.hasAuthError,
      authEventType: authEventType ?? this.authEventType,
      authErrorTimestamp: authErrorTimestamp ?? this.authErrorTimestamp,
      isSessionExpired: isSessionExpired ?? this.isSessionExpired,
    );
  }
  
  /// Crea un nuevo estado con información de un evento de autenticación
  AuthState withAuthEvent(auth_service.AuthEvent event) {
    bool isSessionExpired = false;
    if (event.type == auth_service.AuthEventType.sessionExpired) {
      isSessionExpired = true;
    }
    
    return copyWith(
      hasAuthError: true,
      errorMessage: event.message,
      authEventType: event.type,
      authErrorTimestamp: event.timestamp,
      isSessionExpired: isSessionExpired,
      // Si la sesión expiró, actualizar también el status de autenticación
      status: isSessionExpired ? AuthStatus.unauthenticated : null,
      user: isSessionExpired ? null : user,
    );
  }
  
  /// Limpia los errores de autenticación
  AuthState clearAuthErrors() {
    return copyWith(
      hasAuthError: false,
      errorMessage: null,
      authEventType: null,
      isSessionExpired: false,
    );
  }

  @override
  List<Object?> get props => [
    status, 
    user, 
    errorMessage, 
    isLoading,
    hasAuthError,
    authEventType,
    authErrorTimestamp,
    isSessionExpired,
  ];
}