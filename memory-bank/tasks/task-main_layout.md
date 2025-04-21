# Main Layout Module Tasks

- **Implement Main Layout Widget**: Create the main screen structure (likely using `Scaffold`) within this module (`presentation/screens/main_layout_screen.dart`?)
- **Integrate MotionTabBar**: Add the `MotionTabBar` widget as the `bottomNavigationBar`.
- **Define Tabs**: Configure the tabs (e.g., Home, Activities, Profile) with appropriate icons and labels.
- **Implement ShellRoute**: Use `go_router`'s `ShellRoute` to manage the persistent bottom navigation bar and swap the content area based on the selected tab.
- **Connect Screens**: Ensure the `ShellRoute` correctly routes to the main screens for each tab (e.g., `HomeScreen`, `ActivitiesScreen`, `ProfileScreen`).
- **State Management (Optional)**: Consider if a local Bloc/Cubit is needed for managing the active tab index or other layout-specific state, or if `go_router` state is sufficient.
- **Testing**: Write Widget tests for the main layout structure and tab navigation. 