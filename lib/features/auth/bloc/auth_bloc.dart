import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sacdia/features/auth/bloc/auth_event.dart';
import 'package:sacdia/features/auth/bloc/auth_state.dart';
import 'package:sacdia/features/auth/models/user_model.dart';
import 'package:sacdia/features/auth/repository/auth_repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository})
      : super(const AuthState(status: AuthStatus.unknown)) {
    on<AppStarted>(_onAppStarted);
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<CheckPostRegisterComplete>(_onCheckPostRegisterComplete);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<SignOutRequested>(_onSignOutRequested);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    // Verificar si hay sesión actual en Supabase:
    final session = authRepository.supabaseClient.auth.currentSession;
    if (session != null && session.user != null) {
      // Revisar si postRegisterComplete es true
      final userId = session.user!.id;
      final complete = await authRepository.checkPostRegisterComplete(userId);
      final user = UserModel(
        id: userId,
        email: session.user.email ?? '',
        postRegisterComplete: complete);
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      ));
    } else {
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
}
