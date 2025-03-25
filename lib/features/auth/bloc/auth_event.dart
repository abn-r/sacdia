import 'package:equatable/equatable.dart';
import 'package:sacdia/core/auth_events/auth_event_service.dart' as auth_service;

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {} // Para checar si hay sesión activa al abrir la app

class SignInRequested extends AuthEvent {
  final String email;
  final String password;

  SignInRequested(this.email, this.password);

  @override
  List<Object?> get props => [email, password];
}

class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String paternalSurname;
  final String maternalSurname;

  SignUpRequested({
    required this.email,
    required this.password,
    required this.name,
    required this.paternalSurname,
    required this.maternalSurname,
  });

  @override
  List<Object?> get props => [
        email,
        password,
        name,
        paternalSurname,
        maternalSurname,
      ];
}

class ForgotPasswordRequested extends AuthEvent {
  final String email;

  ForgotPasswordRequested(this.email);

  @override
  List<Object?> get props => [email];
}

/// Este evento se usa después de que el usuario completa la info de post registro
/// para volver a checar si "complete" ya es true en el backend
class CheckPostRegisterComplete extends AuthEvent {}

class SignOutRequested extends AuthEvent {}

// ---- Eventos nuevos relacionados con errores de autenticación ----

/// Evento que se emite cuando se recibe un evento de autenticación del servicio
class AuthEventReceived extends AuthEvent {
  final auth_service.AuthEvent authEvent;

  AuthEventReceived(this.authEvent);

  @override
  List<Object?> get props => [authEvent];
}

/// Evento para limpiar los errores de autenticación
class ClearAuthErrorsRequested extends AuthEvent {}

/// Evento para manejar una sesión expirada (logout forzado)
class SessionExpiredHandled extends AuthEvent {}

// Eventos para el post-registro
class PostRegisterCompleted extends AuthEvent {}

class PostRegisterFailed extends AuthEvent {
  final String error;
  
  PostRegisterFailed(this.error);
}