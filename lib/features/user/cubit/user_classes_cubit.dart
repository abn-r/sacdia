import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sacdia/features/user/models/user_class_model.dart';
import 'package:sacdia/features/user/services/user_service.dart';

// Estados
abstract class UserClassesState extends Equatable {
  const UserClassesState();
  
  @override
  List<Object?> get props => [];
}

class UserClassesInitial extends UserClassesState {}

class UserClassesLoading extends UserClassesState {}

class UserClassesLoaded extends UserClassesState {
  final List<UserClass> classes;
  final DateTime lastUpdated;
  
  const UserClassesLoaded(this.classes, {required this.lastUpdated});
  
  @override
  List<Object?> get props => [classes, lastUpdated];
}

class UserClassesError extends UserClassesState {
  final String message;
  
  const UserClassesError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// Cubit
class UserClassesCubit extends Cubit<UserClassesState> {
  final UserService _userService;
  List<UserClass> _classes = [];
  DateTime? _lastClassesUpdate;
  
  // Constante para la validez de la caché
  static const Duration _cacheValidityDuration = Duration(minutes: 5);
  
  UserClassesCubit({required UserService userService}) : 
    _userService = userService,
    super(UserClassesInitial());
  
  Future<void> getUserClasses({bool forceRefresh = false}) async {
    // Verificar si ya hay clases cargadas y si la caché todavía es válida
    if (!forceRefresh && 
        _classes.isNotEmpty && 
        _lastClassesUpdate != null && 
        DateTime.now().difference(_lastClassesUpdate!) < _cacheValidityDuration) {
      // Devolver las clases de la caché
      emit(UserClassesLoaded(_classes, lastUpdated: _lastClassesUpdate!));
      return;
    }
    
    try {
      // Solo emitir estado de carga si no tenemos datos en caché
      if (_classes.isEmpty) {
        emit(UserClassesLoading());
      }
      
      final classes = await _userService.getUserClasses();
      _classes = classes;
      _lastClassesUpdate = DateTime.now();
      
      emit(UserClassesLoaded(classes, lastUpdated: _lastClassesUpdate!));
    } catch (e) {
      emit(UserClassesError('Error al obtener las clases: ${e.toString()}'));
    }
  }
} 