import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sacdia/features/user/models/user_allergy_model.dart';
import 'package:sacdia/features/user/services/user_service.dart';
import 'package:sacdia/features/post_register/models/allergy_model.dart';

// Estados
abstract class UserAllergiesState extends Equatable {
  const UserAllergiesState();
  
  @override
  List<Object?> get props => [];
}

class UserAllergiesInitial extends UserAllergiesState {}

class UserAllergiesLoading extends UserAllergiesState {}

class UserAllergiesLoaded extends UserAllergiesState {
  final List<UserAllergy> allergies;
  final DateTime lastUpdated;
  
  const UserAllergiesLoaded(this.allergies, {required this.lastUpdated});
  
  @override
  List<Object?> get props => [allergies, lastUpdated];
}

class UserAllergiesError extends UserAllergiesState {
  final String message;
  
  const UserAllergiesError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class CatalogAllergiesLoading extends UserAllergiesState {}

class CatalogAllergiesLoaded extends UserAllergiesState {
  final List<Allergy> allergies;
  
  const CatalogAllergiesLoaded(this.allergies);
  
  @override
  List<Object?> get props => [allergies];
}

class CatalogAllergiesError extends UserAllergiesState {
  final String message;
  
  const CatalogAllergiesError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class AllergyAdded extends UserAllergiesState {}

class AllergyAddError extends UserAllergiesState {
  final String message;
  
  const AllergyAddError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class AllergyDeleted extends UserAllergiesState {}

class AllergyDeleteError extends UserAllergiesState {
  final String message;
  
  const AllergyDeleteError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// Cubit
class UserAllergiesCubit extends Cubit<UserAllergiesState> {
  final UserService _userService;
  List<UserAllergy> _allergies = [];
  List<Allergy> _catalogAllergies = [];
  DateTime? _lastAllergiesUpdate;
  
  // Constante para la validez de la caché
  static const Duration _cacheValidityDuration = Duration(minutes: 5);
  
  UserAllergiesCubit({required UserService userService}) : 
    _userService = userService,
    super(UserAllergiesInitial());
  
  Future<void> getUserAllergies({bool forceRefresh = false}) async {
    // Verificar si ya hay alergias cargadas y si la caché todavía es válida
    if (!forceRefresh && 
        _allergies.isNotEmpty && 
        _lastAllergiesUpdate != null && 
        DateTime.now().difference(_lastAllergiesUpdate!) < _cacheValidityDuration) {
      // Devolver las alergias de la caché
      emit(UserAllergiesLoaded(_allergies, lastUpdated: _lastAllergiesUpdate!));
      return;
    }
    
    try {
      // Solo emitir estado de carga si no tenemos datos en caché
      if (_allergies.isEmpty) {
        emit(UserAllergiesLoading());
      }
      
      final allergies = await _userService.getUserAllergies();
      _allergies = allergies;
      _lastAllergiesUpdate = DateTime.now();
      
      emit(UserAllergiesLoaded(allergies, lastUpdated: _lastAllergiesUpdate!));
    } catch (e) {
      emit(UserAllergiesError('Error al obtener las alergias: ${e.toString()}'));
    }
  }
  
  Future<void> getCatalogAllergies() async {
    try {
      emit(CatalogAllergiesLoading());
      
      final allergies = await _userService.getAllAllergies();
      _catalogAllergies = allergies;
      
      emit(CatalogAllergiesLoaded(allergies));
    } catch (e) {
      emit(CatalogAllergiesError('Error al obtener el catálogo de alergias: ${e.toString()}'));
    }
  }
  
  Future<void> addUserAllergy(Allergy allergy) async {
    try {
      final result = await _userService.saveUserAllergies([allergy]);
      
      if (result) {
        emit(AllergyAdded());
        // Refrescar la lista de alergias
        getUserAllergies(forceRefresh: true);
      } else {
        emit(AllergyAddError('No se pudo agregar la alergia'));
      }
    } catch (e) {
      emit(AllergyAddError('Error al agregar la alergia: ${e.toString()}'));
    }
  }
  
  Future<void> deleteUserAllergy(int allergyId) async {
    try {
      final result = await _userService.deleteUserAllergy(allergyId);
      
      if (result) {
        emit(AllergyDeleted());
        // Refrescar la lista de alergias
        getUserAllergies(forceRefresh: true);
      } else {
        emit(AllergyDeleteError('No se pudo eliminar la alergia'));
      }
    } catch (e) {
      emit(AllergyDeleteError('Error al eliminar la alergia: ${e.toString()}'));
    }
  }
} 