import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sacdia/features/honor/models/honor_category_model.dart';
import 'package:sacdia/features/honor/services/honor_service.dart';

// Estados
abstract class HonorCategoriesState extends Equatable {
  const HonorCategoriesState();

  @override
  List<Object?> get props => [];
}

class HonorCategoriesInitial extends HonorCategoriesState {}

class HonorCategoriesLoading extends HonorCategoriesState {}

class HonorCategoriesLoaded extends HonorCategoriesState {
  final List<HonorCategory> categories;

  const HonorCategoriesLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}

class HonorCategoriesError extends HonorCategoriesState {
  final String message;

  const HonorCategoriesError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class HonorCategoriesCubit extends Cubit<HonorCategoriesState> {
  final HonorService _honorService;

  HonorCategoriesCubit({required HonorService honorService})
      : _honorService = honorService,
        super(HonorCategoriesInitial());

  Future<void> getHonorCategories() async {
    try {
      emit(HonorCategoriesLoading());
      final categories = await _honorService.getHonorsByCategory();
      emit(HonorCategoriesLoaded(categories));
    } catch (e) {
      emit(HonorCategoriesError(e.toString()));
    }
  }
  
  // Método para obtener la URL firmada de la imagen de una especialidad
  Future<String> getHonorImageSignedUrl(String? imagePath) {
    return _honorService.getHonorImageSignedUrl(imagePath);
  }
} 