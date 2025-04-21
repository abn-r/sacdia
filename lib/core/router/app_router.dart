import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sacdia/features/auth/bloc/auth_bloc.dart';
import 'package:sacdia/features/auth/bloc/auth_state.dart';
import 'package:sacdia/features/auth/screens/forgot_password_screen.dart';
import 'package:sacdia/features/auth/screens/login_screen.dart';
import 'package:sacdia/features/auth/screens/register_screen.dart';
import 'package:sacdia/features/main_layout/presentation/main_layout.dart';
import 'package:sacdia/features/post_register/screens/post_register_screen.dart';
import 'package:sacdia/features/splash_screen.dart';

class AppRouter {
  final AuthBloc authBloc;

  AppRouter(this.authBloc);

  late final GoRouter router = GoRouter(
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'Splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'Login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'Register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'ForgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/post-register',
        name: 'PostRegister',
        builder: (context, state) => const PostRegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'Home',
        builder: (context, state) => const MainLayout(),
      ),
    ],
    redirect: (context, state) {
      final authState = authBloc.state;

      /// Manejo básico de rutas según estado
      final loggedIn = authState.status == AuthStatus.authenticated;
      final loggingIn = state.uri.path == '/login' ||
          state.uri.path == '/register' ||
          state.uri.path == '/forgot-password';

      // Si estamos en splash, esperamos a que se resuelva:
      if (state.uri.path == '/') {
        if (authState.status == AuthStatus.unknown) {
          // Aún no carga la info, no redirigimos
          return null;
        } else if (!loggedIn) {
          return '/login';
        } else {
          // Revisar si postRegisterComplete es true
          if (authState.user != null && !authState.user!.postRegisterComplete) {
            return '/post-register';
          }
          return '/home';
        }
      }

      // Si no está logueado y no estamos en las pantallas de login/register/forgot => redirige a /login
      if (!loggedIn && !loggingIn) {
        return '/login';
      }

      // Si está logueado y está tratando de ir a /login, /register o /forgot => ve a /home o /post-register
      if (loggedIn && loggingIn) {
        if (authState.user != null && !authState.user!.postRegisterComplete) {
          return '/post-register';
        }
        return '/home';
      }

      // Si está logueado y la postRegisterComplete es false, redirige a /post-register
      if (loggedIn &&
          authState.user != null &&
          !authState.user!.postRegisterComplete &&
          state.uri.path != '/post-register') {
        return '/post-register';
      }

      // Por defecto, no se redirige
      return null;
    },
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    // La primera vez forzamos una notificación
    notifyListeners();
    // Nos suscribimos al stream para notificar cambios
    _subscription = stream.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}