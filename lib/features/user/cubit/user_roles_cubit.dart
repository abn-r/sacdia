import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sacdia/features/user/models/user_role_model.dart';
import 'package:sacdia/features/user/services/user_service.dart';

// Estados
abstract class UserRolesState extends Equatable {
  const UserRolesState();
  
  @override
  List<Object?> get props => [];
}

class UserRolesInitial extends UserRolesState {}

class UserRolesLoading extends UserRolesState {}

class UserRolesLoaded extends UserRolesState {
  final List<UserRole> roles;
  final DateTime lastUpdated;
  
  const UserRolesLoaded(this.roles, {required this.lastUpdated});
  
  @override
  List<Object?> get props => [roles, lastUpdated];
}

class UserRolesError extends UserRolesState {
  final String message;
  
  const UserRolesError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// Cubit
class UserRolesCubit extends Cubit<UserRolesState> {
  final UserService _userService;
  List<UserRole> _roles = [];
  DateTime? _lastRolesUpdate;
  
  // Constante para la validez de la caché
  static const Duration _cacheValidityDuration = Duration(minutes: 5);
  
  UserRolesCubit({required UserService userService}) : 
    _userService = userService,
    super(UserRolesInitial());
  
  Future<void> getUserRoles({bool forceRefresh = false}) async {
    // Verificar si ya hay roles cargados y si la caché todavía es válida
    if (!forceRefresh && 
        _roles.isNotEmpty && 
        _lastRolesUpdate != null && 
        DateTime.now().difference(_lastRolesUpdate!) < _cacheValidityDuration) {
      // Devolver los roles de la caché
      emit(UserRolesLoaded(_roles, lastUpdated: _lastRolesUpdate!));
      return;
    }
    
    try {
      // Solo emitir estado de carga si no tenemos datos en caché
      if (_roles.isEmpty) {
        emit(UserRolesLoading());
      }
      
      final roles = await _userService.getUserRoles();
      _roles = roles;
      _lastRolesUpdate = DateTime.now();
      
      emit(UserRolesLoaded(roles, lastUpdated: _lastRolesUpdate!));
    } catch (e) {
      emit(UserRolesError('Error al obtener los roles: ${e.toString()}'));
    }
  }
  
  // Método para verificar si el usuario tiene un rol específico
  bool hasRole(String roleName) {
    if (_roles.isEmpty) return false;
    return _roles.any((role) => role.roleName.toLowerCase() == roleName.toLowerCase());
  }
  
  // Método para obtener el rol principal del usuario (asumiendo que el primero es el principal)
  String getPrimaryRole() {
    if (_roles.isEmpty) return 'usuario';
    return _roles.first.roleName;
  }
} 