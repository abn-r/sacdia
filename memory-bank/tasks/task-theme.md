# Theme Module Tasks

- **Refactor DI**: Migrate `ThemeRepository` and `ThemeBloc` creation to use `get_it`.
- **UI Consistency**: Review all screens and widgets to ensure they correctly adapt to both light and dark themes using `Theme.of(context)` and styles defined in `theme_data.dart`.
- **Customization (Optional)**: Consider if more theme customization options are needed beyond light/dark toggle.
- **Testing**: 
    - Write Unit tests for `ThemeBloc`.
    - Write Widget tests for key screens to verify theme switching works correctly. 