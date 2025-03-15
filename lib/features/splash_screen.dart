import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sacdia/features/auth/bloc/auth_bloc.dart';
import 'package:sacdia/features/auth/bloc/auth_event.dart';
import 'package:sacdia/features/auth/bloc/auth_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _timerCompleted = false;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    // Disparar el evento que revisa si hay sesión iniciada
    context.read<AuthBloc>().add(AppStarted());
    
    // Configurar un temporizador para garantizar que la pantalla de splash
    // se muestre durante al menos 1.5 segundos
    _splashTimer = Timer(const Duration(milliseconds: 1500), () {
      // Verificar si el widget todavía está montado antes de llamar a setState
      if (mounted) {
        setState(() {
          _timerCompleted = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (_timerCompleted && state.status != AuthStatus.unknown) {
          // No hacer nada aquí, el router se encargará de la redirección
          // basándose en el estado de autenticación
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/img/LogoSACDIA.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 40.0),
                child: Text(
                  'SACDIA',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}