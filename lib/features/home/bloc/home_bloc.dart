import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sacdia/features/user/bloc/user_bloc.dart';
import 'package:sacdia/features/user/bloc/user_event.dart';
import 'package:sacdia/features/user/models/user_profile_model.dart';

// Eventos para HomeBloc
abstract class HomeEvent {}

class LoadHomeData extends HomeEvent {}

// Estados para HomeBloc
class HomeState {
  final bool isLoading;
  final String? errorMessage;
  final UserProfileModel? userProfile;

  HomeState({
    this.isLoading = false,
    this.errorMessage,
    this.userProfile,
  });

  HomeState copyWith({
    bool? isLoading,
    String? errorMessage,
    UserProfileModel? userProfile,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      userProfile: userProfile ?? this.userProfile,
    );
  }
}

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final UserBloc _userBloc;

  HomeBloc({required UserBloc userBloc})
      : _userBloc = userBloc,
        super(HomeState()) {
    on<LoadHomeData>(_onLoadHomeData);
  }

  Future<void> _onLoadHomeData(
    LoadHomeData event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    
    try {
      // Delegamos la carga del perfil al UserBloc
      _userBloc.add(const LoadUserProfile());
      
      // Emitimos un estado con el perfil actualizado
      emit(state.copyWith(
        isLoading: false,
        userProfile: _userBloc.state.userProfile,
      ));
    } catch (e) {
      debugPrint('Error en HomeBloc: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar datos: ${e.toString()}',
      ));
    }
  }
} 