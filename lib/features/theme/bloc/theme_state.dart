import 'package:equatable/equatable.dart';

class ThemeState extends Equatable {
  final bool isDarkMode;
  final bool isLoading;

  const ThemeState({
    required this.isDarkMode,
    required this.isLoading,
  });

  ThemeState copyWith({
    bool? isDarkMode,
    bool? isLoading,
  }) {
    return ThemeState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object> get props => [isDarkMode, isLoading];
}