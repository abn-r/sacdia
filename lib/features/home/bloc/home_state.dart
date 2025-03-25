import 'package:equatable/equatable.dart';
import '../domain/models/app_feature.dart';

enum HomeStatus {
  initial,
  loading,
  loaded,
  error,
}

class HomeState extends Equatable {
  final HomeStatus status;
  final List<AppFeature> features;
  final List<AppFeature> favoriteFeatures;
  final List<String> userRoles;
  final String? errorMessage;
  final bool isLoading;

  const HomeState({
    this.status = HomeStatus.initial,
    this.features = const [],
    this.favoriteFeatures = const [],
    this.userRoles = const [],
    this.errorMessage,
    this.isLoading = false,
  });

  @override
  List<Object?> get props => [
        status,
        features,
        favoriteFeatures,
        userRoles,
        errorMessage,
        isLoading,
      ];

  HomeState copyWith({
    HomeStatus? status,
    List<AppFeature>? features,
    List<AppFeature>? favoriteFeatures,
    List<String>? userRoles,
    String? errorMessage,
    bool? isLoading,
  }) {
    return HomeState(
      status: status ?? this.status,
      features: features ?? this.features,
      favoriteFeatures: favoriteFeatures ?? this.favoriteFeatures,
      userRoles: userRoles ?? this.userRoles,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
} 