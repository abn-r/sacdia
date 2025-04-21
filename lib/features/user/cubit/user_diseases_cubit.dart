import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sacdia/features/user/models/disease_model.dart';
import 'package:sacdia/features/user/models/user_disease_model.dart';
import 'package:sacdia/features/user/services/user_service.dart';

// Estados
abstract class UserDiseasesState extends Equatable {
  const UserDiseasesState();
  
  @override
  List<Object?> get props => [];
}

class UserDiseasesInitial extends UserDiseasesState {}

class UserDiseasesLoading extends UserDiseasesState {}

class UserDiseasesLoaded extends UserDiseasesState {
  final List<UserDisease> diseases;
  final DateTime lastUpdated;
  final bool isProcessing;
  
  const UserDiseasesLoaded(this.diseases, {required this.lastUpdated, this.isProcessing = false});
  
  @override
  List<Object?> get props => [diseases, lastUpdated, isProcessing];
}

class DiseaseCatalogLoaded extends UserDiseasesState {
  final List<Disease> catalogDiseases;
  final List<Disease> selectedDiseases;
  final bool isLoading;
  
  const DiseaseCatalogLoaded({
    required this.catalogDiseases,
    required this.selectedDiseases,
    this.isLoading = false,
  });
  
  @override
  List<Object?> get props => [catalogDiseases, selectedDiseases, isLoading];
}

class UserDiseasesError extends UserDiseasesState {
  final String message;
  
  const UserDiseasesError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// Cubit
class UserDiseasesCubit extends Cubit<UserDiseasesState> {
  final UserService _userService;
  List<UserDisease> _diseases = [];
  List<Disease> _catalogDiseases = [];
  List<Disease> _selectedDiseases = [];
  DateTime? _lastDiseasesUpdate;
  
  // Constante para la validez de la caché
  static const Duration _cacheValidityDuration = Duration(minutes: 5);
  
  UserDiseasesCubit({required UserService userService}) : 
    _userService = userService,
    super(UserDiseasesInitial());
  
  Future<void> getUserDiseases({bool forceRefresh = false}) async {
    // Verificar si ya hay enfermedades cargadas y si la caché todavía es válida
    if (!forceRefresh && 
        _diseases.isNotEmpty && 
        _lastDiseasesUpdate != null && 
        DateTime.now().difference(_lastDiseasesUpdate!) < _cacheValidityDuration) {
      // Devolver las enfermedades de la caché
      emit(UserDiseasesLoaded(_diseases, lastUpdated: _lastDiseasesUpdate!));
      return;
    }
    
    try {
      // Solo emitir estado de carga si no tenemos datos en caché
      if (_diseases.isEmpty) {
        emit(UserDiseasesLoading());
      }
      
      final diseases = await _userService.getUserDiseases();
      _diseases = diseases;
      _lastDiseasesUpdate = DateTime.now();
      
      emit(UserDiseasesLoaded(diseases, lastUpdated: _lastDiseasesUpdate!));
    } catch (e) {
      emit(UserDiseasesError('Error al obtener las enfermedades: ${e.toString()}'));
    }
  }

  // Método para eliminar una enfermedad del usuario
  Future<bool> deleteUserDisease(int diseaseId) async {
    try {
      // Notificar que la operación está en curso
      final currentState = state;
      if (currentState is UserDiseasesLoaded) {
        // Mantener el estado actual pero indicar que está cargando
        // para evitar múltiples solicitudes
        emit(UserDiseasesLoaded(
          currentState.diseases, 
          lastUpdated: currentState.lastUpdated,
          isProcessing: true
        ));
      }
      
      // Llamar al servicio para eliminar la enfermedad
      final result = await _userService.deleteUserDisease(diseaseId);
      
      if (result) {
        // Si la eliminación fue exitosa, recargar las enfermedades
        // pero con forceRefresh para asegurar datos actualizados
        await getUserDiseases(forceRefresh: true);
      } else {
        // Si falla, restaurar el estado anterior sin la bandera de procesamiento
        if (currentState is UserDiseasesLoaded) {
          emit(UserDiseasesLoaded(
            currentState.diseases, 
            lastUpdated: currentState.lastUpdated,
            isProcessing: false
          ));
        }
      }
      
      return result;
    } catch (e) {
      // En caso de error, restaurar el estado anterior si existía
      final currentState = state;
      if (currentState is UserDiseasesLoaded) {
        emit(UserDiseasesLoaded(
          currentState.diseases, 
          lastUpdated: currentState.lastUpdated,
          isProcessing: false
        ));
      } else {
        // Si no hay estado anterior, emitir error
        emit(UserDiseasesError('Error al eliminar enfermedad: ${e.toString()}'));
      }
      print('Error en cubit al eliminar enfermedad: $e');
      return false;
    }
  }
  
  // Método para cargar el catálogo de enfermedades
  Future<void> loadDiseaseCatalog() async {
    try {
      // Si ya estamos en estado de catálogo, actualizamos a cargando
      if (state is DiseaseCatalogLoaded) {
        emit(DiseaseCatalogLoaded(
          catalogDiseases: _catalogDiseases,
          selectedDiseases: _selectedDiseases,
          isLoading: true,
        ));
      } else {
        emit(UserDiseasesLoading());
      }
      
      // Cargar el catálogo de enfermedades
      final diseases = await _userService.getAllDiseases();
      _catalogDiseases = diseases;
      
      // Asegurarnos de que "Ninguna" sea la primera opción
      if (!_catalogDiseases.any((d) => d.diseaseId == 0)) {
        _catalogDiseases = [
          Disease(diseaseId: 0, name: 'Ninguna'),
          ..._catalogDiseases,
        ];
      }
      
      // Convertir las enfermedades del usuario a Disease para selección
      if (_diseases.isNotEmpty) {
        _selectedDiseases = _diseases.map((d) => d.toDisease()).toList();
      }
      
      emit(DiseaseCatalogLoaded(
        catalogDiseases: _catalogDiseases,
        selectedDiseases: _selectedDiseases,
        isLoading: false,
      ));
    } catch (e) {
      emit(UserDiseasesError('Error al cargar catálogo de enfermedades: ${e.toString()}'));
    }
  }
  
  // Método para actualizar las enfermedades seleccionadas
  void updateSelectedDiseases(List<Disease> selected) {
    _selectedDiseases = selected;
    
    if (state is DiseaseCatalogLoaded) {
      emit(DiseaseCatalogLoaded(
        catalogDiseases: _catalogDiseases,
        selectedDiseases: _selectedDiseases,
        isLoading: false,
      ));
    }
  }
  
  // Método para guardar enfermedades seleccionadas
  Future<bool> saveSelectedDiseases() async {
    try {
      // Actualizar estado para mostrar que está cargando
      if (state is DiseaseCatalogLoaded) {
        emit(DiseaseCatalogLoaded(
          catalogDiseases: _catalogDiseases,
          selectedDiseases: _selectedDiseases,
          isLoading: true,
        ));
      } else {
        emit(UserDiseasesLoading());
      }
      
      // Guardar las enfermedades seleccionadas
      final result = await _userService.saveUserDiseases(_selectedDiseases);
      
      if (result) {
        // Si el guardado fue exitoso, recargar las enfermedades del usuario
        await getUserDiseases(forceRefresh: true);
        return true;
      } else {
        // Si falla, restaurar el estado anterior
        emit(DiseaseCatalogLoaded(
          catalogDiseases: _catalogDiseases,
          selectedDiseases: _selectedDiseases,
          isLoading: false,
        ));
        return false;
      }
    } catch (e) {
      emit(UserDiseasesError('Error al guardar enfermedades: ${e.toString()}'));
      return false;
    }
  }
} 