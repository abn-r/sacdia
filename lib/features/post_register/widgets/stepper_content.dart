import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sacdia/core/constants.dart';
import 'package:sacdia/features/post_register/bloc/post_register_bloc.dart';
import 'package:sacdia/features/post_register/bloc/post_register_event.dart';
import 'package:sacdia/features/post_register/bloc/post_register_state.dart';
import 'package:sacdia/features/post_register/widgets/photo_upload_step.dart';
import 'package:sacdia/features/post_register/widgets/personal_info_step.dart';
import 'package:sacdia/features/post_register/widgets/contact_info_step.dart';
import 'package:sacdia/features/theme/theme_data.dart';

class StepperContent extends StatelessWidget {
  const StepperContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostRegisterBloc, PostRegisterState>(
      builder: (context, state) {
        return Stack(
          children: [
            Transform.translate(
              offset: const Offset(0, -25),
              child: Stepper(
                currentStep: state.currentStep,
                onStepContinue: () => context.read<PostRegisterBloc>().add(
                      const NextStepRequested(),
                    ),
                onStepCancel: () => context.read<PostRegisterBloc>().add(
                      const PreviousStepRequested(),
                    ),
                steps: _buildSteps(context, state),
                type: StepperType.horizontal,
                elevation: 0,
                connectorColor:
                    WidgetStateProperty.all<Color>(sacRed),
                controlsBuilder: (_, __) => const SizedBox.shrink(),
              ),
            ),
            _StepperControls(state: state),
          ],
        );
      },
    );
  }

  List<Step> _buildSteps(BuildContext context, PostRegisterState state) {
    return [
      Step(
        title: const SizedBox.shrink(),
        label: const Text('Paso 1'),
        content: const PhotoUploadStep(),
        isActive: state.currentStep >= 0,
        state: state.currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const SizedBox.shrink(),
        label: const Text('Paso 2'),
        content: const PersonalInfoStep(),
        isActive: state.currentStep >= 1,
        state: state.currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const SizedBox.shrink(),
        label: const Text('Paso 3'),
        content: const ContactInfoStep(),
        isActive: state.currentStep >= 2,
        state: state.currentStep == 2 ? StepState.indexed : StepState.complete,
      ),
    ];
  }
}

class _StepperControls extends StatelessWidget {
  final PostRegisterState state;

  const _StepperControls({required this.state});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (state.currentStep > 0)
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.read<PostRegisterBloc>().add(
                        const PreviousStepRequested(),
                      ),
                  style: AppThemeData.secondaryButtonStyle.copyWith(
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    minimumSize: WidgetStateProperty.all(
                      const Size.fromHeight(50),
                    ),
                  ),
                  child: const Text('Atrás', style: AppThemeData.buttonTextStyle),
                ),
              ),
            if (state.currentStep > 0) 
              const SizedBox(width: 15),
            Expanded(
              child: ElevatedButton(
                onPressed: state.canContinue
                    ? () => context.read<PostRegisterBloc>().add(
                          const NextStepRequested(),
                        )
                    : null,
                style: (state.canContinue
                    ? AppThemeData.primaryButtonStyle
                    : AppThemeData.disabledButtonStyle).copyWith(
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  minimumSize: WidgetStateProperty.all(
                    const Size.fromHeight(50),
                  ),
                ),
                child: const Text('Continuar', style: AppThemeData.buttonTextStyle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
