import 'package:equatable/equatable.dart';
import '../domain/models/app_feature.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadHomeRequested extends HomeEvent {
  const LoadHomeRequested();
}

class LoadFavoriteFeaturesRequested extends HomeEvent {
  const LoadFavoriteFeaturesRequested();
}

class UpdateFeatureOrderRequested extends HomeEvent {
  final List<String> featureIds;

  const UpdateFeatureOrderRequested(this.featureIds);

  @override
  List<Object?> get props => [featureIds];
}

class ToggleFeatureFavoriteRequested extends HomeEvent {
  final String featureId;

  const ToggleFeatureFavoriteRequested(this.featureId);

  @override
  List<Object?> get props => [featureId];
}

class NavigateToFeatureRequested extends HomeEvent {
  final AppFeature feature;

  const NavigateToFeatureRequested(this.feature);

  @override
  List<Object?> get props => [feature];
} 