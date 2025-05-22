import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sacdia/core/widgets/input_text_widget.dart';
import 'package:sacdia/features/auth/bloc/auth_bloc.dart';
import 'package:sacdia/features/auth/bloc/auth_event.dart';
import 'package:sacdia/features/auth/bloc/auth_state.dart';
import 'package:sacdia/core/constants.dart';
import 'package:sacdia/features/theme/theme_data.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  void _onResetPressed() {
    if (_formKey.currentState!.validate()) {
      context
          .read<AuthBloc>()
          .add(ForgotPasswordRequested(_emailCtrl.text.trim()));
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        } else if (!state.isLoading) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Se ha enviado un correo de recuperación.'),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
            title: const Text(
              'RECUPERAR CONTRASEÑA',
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
            padding: const EdgeInsets.all(20),
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                return Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text(
                          'Si olvidaste tu contraseña, ingresa tu correo y te enviaremos un enlace para restablecerla',
                          textAlign: TextAlign.center),
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 20),
                      if (state.isLoading)
                        const CupertinoActivityIndicator(
                          color: sacRed,
                        )
                      else
                        ElevatedButton(
                          onPressed: _onResetPressed,
                          style: AppThemeData.primaryButtonStyle,
                          child: const Text(
                            'Enviar correo',
                            style: AppThemeData.buttonTextStyle,
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
