import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sacdia/core/constants.dart';
import 'package:sacdia/features/post_register/bloc/post_register_bloc.dart';
import 'package:sacdia/features/post_register/bloc/post_register_state.dart';
import 'package:sacdia/features/post_register/widgets/stepper_content.dart';
import 'package:sacdia/features/theme/theme_data.dart';

class PostRegisterScreen extends StatelessWidget {
  const PostRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostRegisterBloc, PostRegisterState>(
      builder: (context, state) {
        return const PostRegisterView();
      },
    );
  }
}

class PostRegisterView extends StatelessWidget {
  const PostRegisterView({super.key});

  @override 
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'COMPLETAR REGISTRO',
          style: AppThemeData.appBarTitleStyle,
        ),
        backgroundColor: sacRed,
      ),
      body: const SafeArea(
        child: StepperContent(),
      ),
    );
  }
}