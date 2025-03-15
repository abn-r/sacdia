import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sacdia/core/widgets/input_text_widget.dart';
import 'package:sacdia/features/auth/bloc/auth_bloc.dart';
import 'package:sacdia/features/auth/bloc/auth_event.dart';
import 'package:sacdia/features/auth/bloc/auth_state.dart';
import 'package:sacdia/core/constants.dart';
import 'package:sacdia/features/theme/theme_data.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            SignInRequested(
              _emailCtrl.text.trim(),
              _passwordCtrl.text.trim(),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: sacGreen,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        '¡BIENVENIDO!',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Image.asset(
                        logoApp,
                        height: 150,
                        width: 150,
                      ),
                      const SizedBox(height: 12),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            CustomTextField(
                              controller: _emailCtrl,
                              labelText: 'CORREO ELECTRÓNICO',
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Este campo es requerido';
                                }
                                if (!RegExp(
                                        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                    .hasMatch(value)) {
                                  return 'Ingrese un correo válido';
                                }
                                return null;
                              },
                            ),
                            CustomTextField(
                              controller: _passwordCtrl,
                              labelText: 'CONTRASEÑA',
                              obscureText: true,
                              keyboardType: TextInputType.visiblePassword,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingresa tu contraseña';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 25),
                            RichText(
                              text: TextSpan(
                                text: '¿Olvidaste tu contraseña? ',
                                style: const TextStyle(color: Colors.white),
                                children: [
                                  TextSpan(
                                    text: '¡Recupérala aquí!',
                                    style: const TextStyle(
                                        color: sacBlack,
                                        fontWeight: FontWeight.bold),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        context.go('/forgot-password');
                                      },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (state.isLoading)
                              const CircularProgressIndicator(
                                strokeWidth: 2.5,
                                backgroundColor: sacRed,
                                color: Colors.white,
                              )
                            else
                              ElevatedButton(
                                onPressed: _onLoginPressed,
                                style: ButtonStyle(
                                  backgroundColor:
                                      WidgetStateProperty.all<Color>(
                                          sacGreenLight),
                                  elevation: WidgetStateProperty.all(0),
                                ),
                                child: const Text('Iniciar Sesión',
                                    style: AppThemeData.buttonTextStyle),
                              ),
                            const SizedBox(height: 30),
                            RichText(
                              text: TextSpan(
                                text: '¿Aún no tienes cuenta? ',
                                style: const TextStyle(color: Colors.white),
                                children: [
                                  TextSpan(
                                    text: '¡Regístrate aquí!',
                                    style: const TextStyle(
                                        color: sacBlack,
                                        fontWeight: FontWeight.bold),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        context.push('/register');
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
