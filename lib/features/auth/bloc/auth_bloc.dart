import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sacdia/core/auth_events/auth_event_service.dart' as auth_service;
import 'package:sacdia/features/auth/bloc/auth_event.dart';
import 'package:sacdia/features/auth/bloc/auth_state.dart';
import 'package:sacdia/features/auth/models/user_model.dart';
import 'package:sacdia/features/auth/repository/auth_repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final auth_service.AuthEventService _authEventService;
  late final StreamSubscription<auth_service.AuthEvent> _authEventSubscription;

  AuthBloc({
    required this.authRepository, 
    auth_service.AuthEventService? authEventService,
  }) : _authEventService = authEventService ?? auth_service.AuthEventService(),
       super(const AuthState(status: AuthStatus.unknown)) {
    on<AppStarted>(_onAppStarted);
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<CheckPostRegisterComplete>(_onCheckPostRegisterComplete);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<SignOutRequested>(_onSignOutRequested);
    
    // Eventos de autenticación
    on<AuthEventReceived>(_onAuthEventReceived);
    on<ClearAuthErrorsRequested>(_onClearAuthErrorsRequested);
    on<SessionExpiredHandled>(_onSessionExpiredHandled);
    
    // Eventos de post-registro
    on<PostRegisterCompleted>(_onPostRegisterCompleted);
    on<PostRegisterFailed>(_onPostRegisterFailed);
    
    // Suscribirse a eventos de autenticación
    _authEventSubscription = _authEventService.onAuthEvent.listen((authEvent) {
      add(AuthEventReceived(authEvent));
    });
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    // Verificar si hay sesión actual
    try {
      final user = await authRepository.getCurrentUser();
      if (user != null) {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        ));
      } else {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
      }
    } catch (e) {
      debugPrint('Error al verificar sesión: $e');
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onSignInRequested(
      SignInRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final user = await authRepository.signInWithEmail(
        event.email,
        event.password,
      );
      if (user == null) {
        emit(state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
          errorMessage: 'Error al iniciar sesión',
        ));
      } else {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          isLoading: false,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSignUpRequested(
      SignUpRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final user = await authRepository.signUpWithEmail(
        email: event.email,
        password: event.password,
        name: event.name,
        paternalSurname: event.paternalSurname,
        maternalSurname: event.maternalSurname,
      );
      if (user == null) {
        emit(state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
          errorMessage: 'Error al crear cuenta',
        ));
      } else {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          isLoading: false,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCheckPostRegisterComplete(
      CheckPostRegisterComplete event, Emitter<AuthState> emit) async {
    if (state.user == null) return;
    final user = state.user!;
    final complete = await authRepository.checkPostRegisterComplete(user.id);

    final updatedUser = UserModel(
      id: user.id,
      email: user.email,
      postRegisterComplete: complete,
    );

    emit(state.copyWith(user: updatedUser));
  }

  Future<void> _onForgotPasswordRequested(
      ForgotPasswordRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      await authRepository.resetPassword(event.email);
      // Podrías emitir un estado de éxito si quieres mostrar un mensaje
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSignOutRequested(
      SignOutRequested event, Emitter<AuthState> emit) async {
    await authRepository.signOut();
    emit(state.copyWith(
      status: AuthStatus.unauthenticated,
      user: null,
    ));
  }
  
  // ---- Manejadores de eventos de autenticación ----
  
  void _onAuthEventReceived(
    AuthEventReceived event, 
    Emitter<AuthState> emit
  ) {
    final authEvent = event.authEvent;
    debugPrint('🔔 AuthBloc recibió evento: ${authEvent.type}');
    
    // Emitir un nuevo estado con la información del evento
    emit(state.withAuthEvent(authEvent));
    
    // Si el evento es de sesión expirada, manejar automáticamente
    if (authEvent.type == auth_service.AuthEventType.sessionExpired) {
      add(SessionExpiredHandled());
    }
  }
  
  void _onClearAuthErrorsRequested(
    ClearAuthErrorsRequested event, 
    Emitter<AuthState> emit
  ) {
    emit(state.clearAuthErrors());
  }
  
  Future<void> _onSessionExpiredHandled(
    SessionExpiredHandled event, 
    Emitter<AuthState> emit
  ) async {
    try {
      // Si la sesión expiró, cerrar sesión
      await authRepository.signOut();
      
      // Actualizar el estado (aunque withAuthEvent ya lo hace)
      if (state.status != AuthStatus.unauthenticated) {
        emit(state.copyWith(
          status: AuthStatus.unauthenticated,
          user: null,
        ));
      }
    } catch (e) {
      debugPrint('Error al manejar sesión expirada: $e');
      // Forzar estado de no autenticado aunque falle el cierre de sesión
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null,
      ));
    }
  }
  
  void _onPostRegisterCompleted(
    PostRegisterCompleted event,
    Emitter<AuthState> emit,
  ) async {
    // Solo proceder si el usuario está autenticado
    if (state.status != AuthStatus.authenticated || state.user == null) {
      return;
    }
    
    try {
      // Obtenemos el usuario actualizado para verificar que el post-registro esté completo
      final updatedUser = await authRepository.getCurrentUser();
      
      if (updatedUser == null) {
        emit(state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'No se pudo verificar el estado del post-registro',
        ));
        return;
      }
      
      // Actualizamos el estado con el usuario actualizado
      emit(state.copyWith(
        user: updatedUser,
        isLoading: false,
        errorMessage: null,
      ));
      
      print('✅ Post-registro completado correctamente en AuthBloc');
    } catch (e) {
      // Mantenemos el estado autenticado pero con un mensaje de error
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error al verificar el estado del post-registro: ${e.toString()}',
      ));
    }
  }

  void _onPostRegisterFailed(
    PostRegisterFailed event,
    Emitter<AuthState> emit,
  ) async {
    // Solo proceder si el usuario está autenticado
    if (state.status != AuthStatus.authenticated) {
      return;
    }
    
    // Mantenemos el estado autenticado pero con un mensaje de error
    emit(state.copyWith(
      isLoading: false,
      errorMessage: 'Error en el post-registro: ${event.error}',
    ));
    
    print('❌ Error en el post-registro: ${event.error}');
  }
  
  @override
  Future<void> close() {
    _authEventSubscription.cancel();
    return super.close();
  }
}
