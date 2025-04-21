# SACDIA App System Patterns

## System Architecture
The SACDIA app aims for a Clean Architecture approach, although implementation varies across modules:
- **Presentation Layer**: Flutter Widgets (Screens, custom widgets). Located in `features/*/presentation/screens` and `features/*/presentation/widgets` (or `features/*/widgets`).
- **Business Logic Layer**: BLoC/Cubit for state management. Located in `features/*/bloc` or `features/*/cubit`.
- **Data Layer**: 
    - Repositories (`features/*/repository`) abstract data access.
    - Services (`features/*/services`) sometimes act as a facade over repositories or group related API calls (e.g., `UserService`).
- **Domain Layer**: Models/Entities (`features/*/models`) represent data structures.
- **Core Layer** (`lib/core`): Contains shared components like router, HTTP client, constants, base widgets, and potentially core Blocs/Services (like `CatalogsBloc`, `AuthEventService`).

## Key Technical Decisions
1.  **State Management**: Mix of `flutter_bloc` (existing) and `Cubit` (planned for new features). `equatable` used for state/event comparison.
2.  **Navigation**: `go_router` for declarative routing, including auth-based redirection and potentially `ShellRoute` for main layout.
3.  **Backend Interaction**: Centralized `ApiClient` (using `dio`) in `core/http` handles calls to the NestJS API. It likely needs interceptors for JWT token injection and potentially refresh logic (using `AuthRepository.getValidToken`?) and error handling (triggering `AuthEventService` on 401/403).
4.  **Authentication**: Supabase Auth handles user creation (via NestJS API for signup), login, password reset, and session management. `AuthRepository` interacts with both Supabase and the NestJS API (`/auth` endpoints).
5.  **Data Persistence (Local)**: `shared_preferences` used by `ThemeRepository` to store theme preference. No other local persistence observed yet.
6.  **Dependency Injection**: Currently manual instantiation in `main.dart`. Plan is to migrate to `get_it`.
7.  **Image Handling**: `image_picker` for selection, `image_cropper` for cropping, `flutter_image_compress` for optimization before upload (likely to Supabase Storage via NestJS API in `PostRegisterRepository`).

## Design Patterns in Use
1.  **Repository Pattern**: Used to abstract data sources (API, Supabase Auth) - e.g., `AuthRepository`, `UserRepository`, `PostRegisterRepository`, `ThemeRepository`, `CatalogsRepository`.
2.  **BLoC/Cubit Pattern**: For managing UI state and business logic.
3.  **Facade Pattern**: `UserService` acts as a facade over API endpoints related to user details (allergies, diseases, etc.).
4.  **Singleton Pattern**: Likely used implicitly by Supabase client and potentially intended for `get_it` singletons.
5.  **Builder Pattern**: Flutter's declarative UI heavily relies on this.
6.  **Observer Pattern**: `BlocListener`, `BlocBuilder`, `GoRouterRefreshStream` listen for state changes.

## Component Relationships (Examples)
- `LoginScreen` -> `AuthBloc` -> `AuthRepository` -> (SupabaseClient, NestJS API via Dio)
- `PostRegisterScreen` -> `StepperContent` -> (`PhotoUploadStep`, `PersonalInfoStep`, `ClubInfoStep`) -> `PostRegisterBloc` -> (`PostRegisterRepository`, `AuthRepository`, `CatalogsBloc`, `AuthBloc`) -> (NestJS API via Dio)
- `ProfileScreen` -> (`UserBloc`, `UserClubsCubit`, `UserClassesCubit`, `UserRolesCubit`) -> (`UserRepository`, `UserService`) -> (NestJS API via Dio)
- Global Widgets (`AuthEventListener`) <-> Core Services (`AuthEventService`) <-> HTTP Client Interceptor

## Testing Strategy (Planned/Inferred from Dev Dependencies)
- **Unit Tests**: For Blocs/Cubits using `bloc_test` and `mocktail` for mocking repositories/services.
- **Widget Tests**: For UI components using `flutter_test`.
- **Integration Tests**: Recommended for API interactions (module-level). 