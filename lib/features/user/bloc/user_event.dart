import 'package:equatable/equatable.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar el perfil del usuario
class LoadUserProfile extends UserEvent {
  const LoadUserProfile();
}

/// Evento para cambiar el tipo de club del usuario
class ChangeClubType extends UserEvent {
  final int clubTypeId;

  const ChangeClubType(this.clubTypeId);

  @override
  List<Object?> get props => [clubTypeId];
}

/// Evento cuando el perfil del usuario se carga exitosamente
class UserProfileLoaded extends UserEvent {
  const UserProfileLoaded();
}

/// Evento cuando ocurre un error al cargar el perfil del usuario
class UserProfileError extends UserEvent {
  final String message;

  const UserProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Evento para limpiar los errores del estado
class ClearUserErrors extends UserEvent {
  const ClearUserErrors();
} 