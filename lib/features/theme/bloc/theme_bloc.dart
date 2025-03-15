import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sacdia/features/theme/bloc/theme_event.dart';
import 'package:sacdia/features/theme/bloc/theme_state.dart';
import 'package:sacdia/features/theme/theme_repository.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final ThemeRepository themeRepository;

  ThemeBloc({required this.themeRepository})
      : super(const ThemeState(isDarkMode: false, isLoading: true)) {
    on<LoadThemeEvent>(_onLoadThemeEvent);
    on<ToggleThemeEvent>(_onToggleThemeEvent);
  }

  Future<void> _onLoadThemeEvent(
      LoadThemeEvent event, Emitter<ThemeState> emit) async {
    emit(state.copyWith(isLoading: true));
    final isDark = await themeRepository.loadThemePreference();
    emit(state.copyWith(isDarkMode: isDark, isLoading: false));
  }

  Future<void> _onToggleThemeEvent(
      ToggleThemeEvent event, Emitter<ThemeState> emit) async {
    await themeRepository.saveThemePreference(event.isDarkMode);
    emit(state.copyWith(isDarkMode: event.isDarkMode));
  }
}