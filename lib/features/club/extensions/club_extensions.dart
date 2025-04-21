import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sacdia/features/club/cubit/user_clubs_cubit.dart';
import 'package:sacdia/features/club/models/user_club_model.dart';

/// Extensiones para simplificar el acceso a los datos del club
extension ClubContextExtensions on BuildContext {
  /// Obtiene el nombre del club del usuario actual
  String get clubName {
    final cubit = read<UserClubsCubit>();
    final state = cubit.state;
    
    if (state is UserClubsLoaded) {
      return cubit.getPrimaryClubName();
    } else if (state is UserClubsLoading) {
      return 'Cargando...';
    } else if (state is UserClubsError) {
      return 'No disponible';
    }
    
    return 'No asignado';
  }
  
  /// Obtiene el club principal del usuario
  UserClub? get primaryClub {
    final cubit = read<UserClubsCubit>();
    final state = cubit.state;
    
    if (state is UserClubsLoaded && cubit.hasClub()) {
      return cubit.getPrimaryClub();
    }
    
    return null;
  }
  
  /// Verifica si el usuario tiene un club asignado
  bool get hasClub {
    final cubit = read<UserClubsCubit>();
    final state = cubit.state;
    
    return state is UserClubsLoaded && cubit.hasClub();
  }
  
  /// Verifica si los clubes están en proceso de carga
  bool get isLoadingClubs {
    return read<UserClubsCubit>().state is UserClubsLoading;
  }
  
  /// Verifica si hubo un error al cargar los clubes
  bool get hasClubError {
    return read<UserClubsCubit>().state is UserClubsError;
  }
  
  /// Obtiene el mensaje de error de clubes si existe
  String? get clubErrorMessage {
    final state = read<UserClubsCubit>().state;
    if (state is UserClubsError) {
      return state.message;
    }
    return null;
  }
} 