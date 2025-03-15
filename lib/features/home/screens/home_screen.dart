import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sacdia/features/auth/bloc/auth_bloc.dart';
import 'package:sacdia/features/auth/bloc/auth_state.dart';
import 'package:sacdia/features/auth/bloc/auth_event.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          final user = state.user;
          // session puede ser un objeto de Supabase que tengas en el AuthState
          // (si así lo modelaste). Si no, ajusta el código para tomar la info
          // de donde la tengas.

          return Scaffold(
            appBar: AppBar(
              title: const Text('Home Screen'),
            ),
            body: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Mostramos datos del usuario (nombre, email, etc.)
                    Text(
                      'Bienvenido, ${user!.id}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text('Email: ${user.email}'),
                    const SizedBox(height: 16),

                    // (Opcional) Mostrar información de la sesión
                    // ¡Ojo! No es recomendable mostrar tokens en producción.
                    ...[
                      // Text(
                      //   'Refresh Token (debug): ${session.refreshToken}',
                      //   style: const TextStyle(fontSize: 12),
                      //   textAlign: TextAlign.center,
                      // ),
                      const SizedBox(height: 16),
                    ],

                    // Botón para cerrar sesión
                    ElevatedButton.icon(
                      onPressed: () {
                        // Disparamos el evento para hacer SignOut en el BLoC
                        context.read<AuthBloc>().add(SignOutRequested());
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar Sesión'),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          // Si el estado no es AuthAuthenticated, mostramos algo básico
          return Scaffold(
            appBar: AppBar(
              title: const Text('Home Screen'),
            ),
            body: const Center(
              child: Text('No existe un usuario autenticado'),
            ),
          );
        }
      },
    );
  }
}
