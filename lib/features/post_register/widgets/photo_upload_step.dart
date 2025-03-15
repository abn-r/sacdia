import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sacdia/features/post_register/bloc/post_register_bloc.dart';
import 'package:sacdia/features/post_register/bloc/post_register_event.dart';
import 'package:sacdia/features/post_register/bloc/post_register_state.dart';
import 'package:sacdia/features/post_register/models/photo_upload_data.dart';
import 'package:sacdia/features/theme/theme_data.dart';

class PhotoUploadStep extends StatelessWidget {
  const PhotoUploadStep({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<PostRegisterBloc, PostRegisterState, PhotoUploadData>(
      selector: (state) => PhotoUploadData(
        selectedPhoto: state.selectedPhoto,
        isUploading: state.isUploading,
        isUploaded: state.isUploaded,
        errorMessage: state.errorMessage,
      ),
      builder: (context, data) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Sube tu foto de perfil',
              style: AppThemeData.titleStyle,
            ),
            const SizedBox(height: 20),
            if (data.selectedPhoto == null)
              _SelectPhotoButton(
                onPressed: () => context.read<PostRegisterBloc>().add(
                      const PickPhotoRequested(),
                    ),
              )
            else
              _PhotoPreview(
                photo: data.selectedPhoto!,
                isUploading: data.isUploading,
                isUploaded: data.isUploaded,
                onReset: () => context.read<PostRegisterBloc>().add(
                      const ResetPhotoRequested(),
                    ),
                onUpload: () => context.read<PostRegisterBloc>().add(
                      const UploadPhotoRequested(),
                    ),
              ),
            const SizedBox(height: 30),
            if (data.errorMessage != null)
              _ErrorMessage(message: data.errorMessage!),
            if (data.isUploaded) const _SuccessMessage(),
          ],
        );
      },
    );
  }
}

class _SelectPhotoButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SelectPhotoButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: AppThemeData.primaryButtonStyle,
      child: const Text('Seleccionar', style: AppThemeData.buttonTextStyle),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  final File photo;
  final bool isUploading;
  final bool isUploaded;
  final VoidCallback onReset;
  final VoidCallback onUpload;

  const _PhotoPreview({
    required this.photo,
    required this.isUploading,
    required this.isUploaded,
    required this.onReset,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 100,
          backgroundImage: FileImage(photo),
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: onReset,
              style: AppThemeData.secondaryButtonStyle,
              child: Text('Cambiar',
                  style: AppThemeData.buttonBlackTextStyle
                      .copyWith(inherit: false)),
            ),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: isUploaded ? null : onUpload,
              style: AppThemeData.primaryButtonStyle,
              child: isUploading
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    )
                  : Text('Guardar',
                      style: AppThemeData.buttonTextStyle
                          .copyWith(inherit: false)),
            ),
          ],
        ),
      ],
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  final String message;

  const _ErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        message,
        style: const TextStyle(
            color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _SuccessMessage extends StatelessWidget {
  const _SuccessMessage();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Text(
        '¡Foto subida exitosamente!',
        style: TextStyle(
            color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
