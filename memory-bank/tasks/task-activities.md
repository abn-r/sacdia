# Activities Module Tasks

- **Define Functionality**: Clarify the specific features required for activity management (e.g., View upcoming activities, View past activities, Register for activities, Track attendance, Create/Manage activities for directors?).
- **API Endpoints**: Define and implement necessary endpoints in the NestJS API for fetching and managing activity data.
- **Models**: Create Dart models (`ActivityModel`, etc.) in `features/activities/models` to represent activity data.
- **Repository/Service**: Implement `ActivitiesRepository` or `ActivitiesService` in `features/activities/repository` to interact with the API endpoints.
- **State Management**: Implement `ActivitiesBloc` or `ActivitiesCubit` in `features/activities/bloc` to manage state related to fetching, displaying, and interacting with activities.
- **Screens/UI**: 
    - Implement main screen(s) in `features/activities/presentation/screens` (e.g., `ActivitiesListScreen`, `ActivityDetailScreen`).
    - Design and implement necessary widgets in `features/activities/presentation/widgets`.
    - Integrate state management using `BlocBuilder`/`BlocListener`.
- **Navigation**: Ensure the module is accessible (e.g., via a tab in `main_layout` or a menu option in `home`) and internal navigation works correctly.
- **Refactor DI**: Use `get_it` for creating repository/service and bloc/cubit instances.
- **Testing**: Write Unit, Widget, and Integration tests for the module. 