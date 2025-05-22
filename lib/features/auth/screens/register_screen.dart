import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sacdia/core/widgets/input_text_widget.dart';
import 'package:sacdia/features/auth/bloc/auth_bloc.dart';
import 'package:sacdia/features/auth/bloc/auth_event.dart';
import 'package:sacdia/features/auth/bloc/auth_state.dart';
import 'package:sacdia/core/constants.dart';
import 'package:sacdia/features/theme/theme_data.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _paternalCtrl = TextEditingController();
  final _maternalCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  void _onRegisterPressed() {
    if (_formKey.currentState!.validate()) {
      print('Registering...');
      context.read<AuthBloc>().add(
            SignUpRequested(
              email: _emailCtrl.text.trim(),
              password: _passwordCtrl.text.trim(),
              name: _nameCtrl.text.trim(),
              paternalSurname: _paternalCtrl.text.trim(),
              maternalSurname: _maternalCtrl.text.trim(),
            ),
          );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _paternalCtrl.dispose();
    _maternalCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
            title: const Text(
              'CREAR CUENTA',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            backgroundColor: sacRed,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () {
                context.pushReplacement('/login');
              },
            )),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                return Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      CustomTextField(
                        controller: _nameCtrl,
                        labelText: 'NOMBRE',
                        keyboardType: TextInputType.text,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa tu nombre';
                          }
                          return null;
                        },
                      ),
                      CustomTextField(
                        controller: _paternalCtrl,
                        labelText: 'APELLIDO PATERNO',
                        keyboardType: TextInputType.name,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa tu apellido paterno';
                          }
                          return null;
                        },
                      ),
                      CustomTextField(
                        controller: _maternalCtrl,
                        labelText: 'APELLIDO MATERNO',
                        keyboardType: TextInputType.name,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa tu apellido materno';
                          }
                          return null;
                        },
                      ),
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
                            return 'Este campo es requerido';
                          }
                          if (value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      CustomTextField(
                        controller: _confirmPasswordCtrl,
                        labelText: 'CONFIRMAR CONTRASEÑA',
                        obscureText: true,
                        keyboardType: TextInputType.visiblePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirma tu contraseña';
                          }
                          if (value != _passwordCtrl.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      if (state.isLoading)
                        const Center(
                            child: CupertinoActivityIndicator(
                          color: sacRed,
                        ))
                      else
                        ElevatedButton(
                          onPressed: _onRegisterPressed,
                          style: AppThemeData.primaryButtonStyle,
                          child: const Text(
                            'Crear Cuenta',
                            style: AppThemeData.buttonTextStyle,
                          ),
                        ),
                      const SizedBox(height: 16),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text: '¿Ya tienes cuenta? ',
                          style: const TextStyle(color: sacBlack),
                          children: [
                            TextSpan(
                              text: 'Iniciar sesión',
                              style: const TextStyle(
                                  color: sacBlack, fontWeight: FontWeight.bold),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  context.go('/login');
                                },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
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
