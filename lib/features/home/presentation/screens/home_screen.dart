import 'package:flutter/material.dart';
import 'package:sacdia/features/home/screens/home_screen.dart' as home;

// Este archivo es un wrapper para mantener compatibilidad con la estructura
// de directorios que espera el router.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Simplemente redirigimos al HomeScreen original
    return const home.HomeScreen();
  }
} 