import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/repositories/feature_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final FeatureRepository _featureRepository;

  HomeBloc({
    required FeatureRepository featureRepository,
  })  : _featureRepository = featureRepository,
        super(const HomeState()) {
    on<LoadHomeRequested>(_onLoadHomeRequested);
    on<LoadFavoriteFeaturesRequested>(_onLoadFavoriteFeaturesRequested);
    on<UpdateFeatureOrderRequested>(_onUpdateFeatureOrderRequested);
    on<ToggleFeatureFavoriteRequested>(_onToggleFeatureFavoriteRequested);
  }

  Future<void> _onLoadHomeRequested(
    LoadHomeRequested event,
    Emitter<HomeState> emit,
  ) async {
    try {
      emit(state.copyWith(status: HomeStatus.loading, isLoading: true));

      final userRoles = await _featureRepository.getCurrentUserRoles();
      final features = await _featureRepository.getAvailableFeatures();
      final favoriteFeatures = await _featureRepository.getFavoriteFeatures();

      emit(state.copyWith(
        status: HomeStatus.loaded,
        features: features,
        favoriteFeatures: favoriteFeatures,
        userRoles: userRoles,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HomeStatus.error,
        errorMessage: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _onLoadFavoriteFeaturesRequested(
    LoadFavoriteFeaturesRequested event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final favoriteFeatures = await _featureRepository.getFavoriteFeatures();
      emit(state.copyWith(favoriteFeatures: favoriteFeatures));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Error al cargar características favoritas: ${e.toString()}',
      ));
    }
  }

  Future<void> _onUpdateFeatureOrderRequested(
    UpdateFeatureOrderRequested event,
    Emitter<HomeState> emit,
  ) async {
    try {
      await _featureRepository.updateFeatureOrder(event.featureIds);
      add(const LoadHomeRequested());
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Error al actualizar orden: ${e.toString()}',
      ));
    }
  }

  Future<void> _onToggleFeatureFavoriteRequested(
    ToggleFeatureFavoriteRequested event,
    Emitter<HomeState> emit,
  ) async {
    try {
      await _featureRepository.toggleFeatureFavorite(event.featureId);
      add(const LoadFavoriteFeaturesRequested());
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Error al actualizar favoritos: ${e.toString()}',
      ));
    }
  }
} 