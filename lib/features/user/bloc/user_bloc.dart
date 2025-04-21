import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sacdia/features/user/bloc/user_event.dart';
import 'package:sacdia/features/user/bloc/user_state.dart';
import 'package:sacdia/features/user/repository/user_repository.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final IUserRepository _userRepository;
  
  UserBloc({
    required IUserRepository userRepository,
  }) : _userRepository = userRepository,
       super(const UserState()) {
    on<LoadUserProfile>(_onLoadUserProfile);
    on<ChangeClubType>(_onChangeClubType);
    on<ClearUserErrors>(_onClearUserErrors);
  }
  
  Future<void> _onLoadUserProfile(
    LoadUserProfile event,
    Emitter<UserState> emit,
  ) async {
    emit(state.copyWith(status: UserStatus.loading));
    
    try {
      final userProfile = await _userRepository.getUserProfile();
      emit(state.copyWith(
        status: UserStatus.loaded,
        userProfile: userProfile,
      ));
    } catch (e) {
      debugPrint('Error al cargar perfil de usuario: $e');
      emit(state.copyWith(
        status: UserStatus.error,
        errorMessage: 'No se pudo cargar el perfil: ${e.toString()}',
      ));
    }
  }
  
  Future<void> _onChangeClubType(
    ChangeClubType event,
    Emitter<UserState> emit,
  ) async {
    emit(state.copyWith(isChangingClubType: true));
    
    try {
      final updatedProfile = await _userRepository.changeClubType(event.clubTypeId);
      emit(state.copyWith(
        isChangingClubType: false,
        userProfile: updatedProfile,
      ));
    } catch (e) {
      debugPrint('Error al cambiar tipo de club: $e');
      emit(state.copyWith(
        isChangingClubType: false,
        errorMessage: 'No se pudo cambiar el tipo de club: ${e.toString()}',
      ));
    }
  }
  
  void _onClearUserErrors(
    ClearUserErrors event,
    Emitter<UserState> emit,
  ) {
    emit(state.clearErrors());
  }
} 