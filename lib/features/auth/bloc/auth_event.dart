import 'package:equatable/equatable.dart';

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