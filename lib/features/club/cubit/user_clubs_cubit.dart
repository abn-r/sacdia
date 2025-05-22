import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sacdia/core/services/preferences_service.dart';
import 'package:sacdia/features/club/models/user_club_model.dart';
import 'package:sacdia/features/user/services/user_service.dart';
import 'package:get_it/get_it.dart';

// Estados
abstract class UserClubsState extends Equatable {
  const UserClubsState();
  
  @override
  List<Object?> get props => [];
}

class UserClubsInitial extends UserClubsState {}

class UserClubsLoading extends UserClubsState {}

class UserClubsLoaded extends UserClubsState {
  final List<UserClub> clubs;
  final DateTime lastUpdated;
  
  const UserClubsLoaded(this.clubs, {required this.lastUpdated});
  
  @override
  List<Object?> get props => [clubs, lastUpdated];
}

class UserClubsError extends UserClubsState {
  final String message;
  
  const UserClubsError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class UserClubsCubit extends Cubit<UserClubsState> {
  final UserService userService;
  final PreferencesService _preferencesService;
  List<UserClub> _clubs = [];
  
  // Constantes para caché
  static const Duration _cacheValidityDuration = Duration(minutes: 5);
  DateTime? _lastClubsUpdate;
  
  UserClubsCubit({required this.userService}) 
      : _preferencesService = GetIt.I<PreferencesService>(),
        super(UserClubsInitial());
  
  Future<void> getUserClubs({bool forceRefresh = false}) async {
    // Verificar si ya hay clubes cargados y si la caché todavía es válida
    if (!forceRefresh && 
        _clubs.isNotEmpty && 
        _lastClubsUpdate != null && 
        DateTime.now().difference(_lastClubsUpdate!) < _cacheValidityDuration) {
      // Devolver los clubes de la caché
      emit(UserClubsLoaded(_clubs, lastUpdated: _lastClubsUpdate!));
      return;
    }
    
    try {
      // Solo emitir estado de carga si no tenemos datos en caché
      if (_clubs.isEmpty) {
        emit(UserClubsLoading());
      }
      
      final clubs = await userService.getUserClubs();
      _clubs = clubs;
      _lastClubsUpdate = DateTime.now();
      
      emit(UserClubsLoaded(_clubs, lastUpdated: _lastClubsUpdate!));

      // Save club info to preferences
      if (_clubs.isNotEmpty) {
        final primaryClub = _clubs.first;
        await _preferencesService.saveClubId(primaryClub.clubId);
        await _preferencesService.saveClubAdvId(primaryClub.clubAdvId);
        await _preferencesService.saveClubPathfId(primaryClub.clubPathfId);
        await _preferencesService.saveClubGmId(primaryClub.clubMgId);
      }
      // Save default club type select
      await _preferencesService.saveClubTypeSelect(2);

    } catch (e) {
      emit(UserClubsError('Error al cargar los clubes: ${e.toString()}'));
    }
  }
  
  // Método auxiliar para obtener el club principal del usuario
  UserClub? getPrimaryClub() {
    return _clubs.isNotEmpty ? _clubs.first : null;
  }
  
  // Método para obtener el nombre del club principal
  String getPrimaryClubName() {
    final primaryClub = getPrimaryClub();
    return primaryClub?.clubName ?? 'No asignado';
  }
  
  // Método para verificar si el usuario tiene un club asignado
  bool hasClub() {
    return _clubs.isNotEmpty;
  }
  
  // Método para obtener el ID del club principal
  int? getPrimaryClubId() {
    final primaryClub = getPrimaryClub();
    return primaryClub?.clubId;
  }
  
  // Limpiar datos en caché
  void clearCache() {
    _clubs = [];
    _lastClubsUpdate = null;
    emit(UserClubsInitial());
  }
} 