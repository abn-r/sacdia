# General Tasks

- **Dependency Injection**: Refactor entire application to use `get_it` for managing Repositories, Services, Blocs, and Cubits. Replace manual instantiation in `main.dart`.
- **Testing Setup**: 
    - Configure base test environment (if not already done).
    - Establish testing strategy/conventions (Unit, Widget, Integration).
    - Implement initial tests for critical flows (e.g., Auth, PostRegister).
- **API Client Enhancements**:
    - Implement robust JWT token injection in `ApiClient` interceptor.
    - Implement token refresh logic in `ApiClient` interceptor (potentially using `AuthRepository.getValidToken` and retrying requests).
    - Implement global auth error handling: Ensure 401/403 responses trigger `AuthEventService` correctly, and connect `_handleAuthError` in `UserService`.
- **Error Handling**: Review and improve error handling across all modules. Provide user-friendly messages instead of raw exceptions. Ensure loading/error states are handled gracefully in the UI.
- **Navigation**: Define and implement all necessary routes for menu options and intra-module navigation, likely requiring updates to `AppRouter` (potentially using `ShellRoute` for `main_layout`).
- **Code Quality**: 
    - Address any linter warnings/errors.
    - Ensure consistency in applying Clean Architecture principles.
    - Refactor complex widgets/methods where necessary. 