import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sacdia/features/honor/models/user_honor_category_model.dart';
import 'package:sacdia/features/honor/services/honor_service.dart';

// Estados
abstract class UserHonorsState extends Equatable {
  const UserHonorsState();

  @override
  List<Object?> get props => [];
}

class UserHonorsInitial extends UserHonorsState {}

class UserHonorsLoading extends UserHonorsState {}

class UserHonorsLoaded extends UserHonorsState {
  final List<UserHonorCategory> categories;

  const UserHonorsLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}

class UserHonorsError extends UserHonorsState {
  final String message;

  const UserHonorsError(this.message);

  @override
  List<Object?> get props => [message];
}

class UserHonorSaving extends UserHonorsState {}

class UserHonorSaved extends UserHonorsState {}

class UserHonorError extends UserHonorsState {
  final String message;

  const UserHonorError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class UserHonorsCubit extends Cubit<UserHonorsState> {
  final HonorService _honorService;

  UserHonorsCubit({required HonorService honorService})
      : _honorService = honorService,
        super(UserHonorsInitial());

  Future<void> getUserHonors() async {
    try {
      emit(UserHonorsLoading());
      final categories = await _honorService.getUserHonorsByCategory();
      emit(UserHonorsLoaded(categories));
    } catch (e) {
      emit(UserHonorsError(e.toString()));
    }
  }

  Future<void> createUserHonor({
    required int honorId,
    File? certificateFile,
    List<File> images = const [],
  }) async {
    try {
      emit(UserHonorSaving());
      
      final success = await _honorService.createUserHonor(
        honorId: honorId,
        certificateFile: certificateFile,
        images: images,
      );
      
      if (success) {
        // Recargar las especialidades del usuario
        await getUserHonors();
        emit(UserHonorSaved());
      } else {
        emit(const UserHonorError('Error al guardar la especialidad'));
      }
    } catch (e) {
      emit(UserHonorError(e.toString()));
    }
  }

  Future<void> updateUserHonor({
    required int userHonorId,
    File? certificateFile,
    List<File> images = const [],
  }) async {
    try {
      emit(UserHonorSaving());
      
      final success = await _honorService.updateUserHonor(
        userHonorId: userHonorId,
        certificateFile: certificateFile,
        images: images,
      );
      
      if (success) {
        // Recargar las especialidades del usuario
        await getUserHonors();
        emit(UserHonorSaved());
      } else {
        emit(const UserHonorError('Error al actualizar la especialidad'));
      }
    } catch (e) {
      emit(UserHonorError(e.toString()));
    }
  }

  Future<void> deleteUserHonor(int userHonorId) async {
    try {
      emit(UserHonorSaving());
      
      final success = await _honorService.deleteUserHonor(userHonorId);
      
      if (success) {
        // Recargar las especialidades del usuario
        await getUserHonors();
        emit(UserHonorSaved());
      } else {
        emit(const UserHonorError('Error al eliminar la especialidad'));
      }
    } catch (e) {
      emit(UserHonorError(e.toString()));
    }
  }
} 