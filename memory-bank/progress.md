# SACDIA App Progress

## What Works
- **Core Setup**: Project initialization, Flutter setup, dependencies, assets.
- **Architecture Base**: Feature-based structure (`core`, `features`), use of BLoC/Cubit, Repositories.
- **Authentication**: Email/Password Login, Signup (via API), Forgot Password, Signout. Auth state management and routing based on auth status.
- **Post-Registration**: Multi-step flow (Photo, Personal Info, Club Selection) is functional, including API interactions for data saving and catalog loading.
- **User Profile (Partial)**: Loading and displaying basic profile info, club, role, class, baptism/investiture status. Granular state management for Allergies & Diseases (via Cubits).
- **Home Screen**: Basic dashboard structure, role-based menu display.
- **Core Components**: HTTP Client (`ApiClient`), Constants, Router (`go_router`), Theme management.
- **Basic UI**: Several screens implemented (`Login`, `Register`, `PostRegister`, `Profile`, `Home`, etc.) with custom styles.

## What's Left to Build
1.  **Dependency Injection**: Refactor entire app to use `get_it`.
2.  **Core Features**: 
    *   `main_layout` (ShellRoute with MotionTabBar & Navigation).
    *   `activities` module functionality.
    *   `profile/ConfigurationScreen` functionality.
    *   Profile Update feature.
    *   Specialities feature (Data loading, UI in Profile, potentially dedicated screen).
    *   Emergency Contact management (UI/Cubits needed).
    *   Connect Club Type selection in Home to state management.
3.  **Module Refinements**: 
    *   Address TODOs/potential issues identified during analysis (error handling, UX feedback, navigation setup, etc.).
    *   Implement missing User Cubits (`EmergencyContacts`, `Roles`, `Classes` - *Correction: Classes/Roles Cubits exist, need EmergencyContacts*).
    *   Integrate Allergy/Disease/Contact management into `UserPersonalInfoScreen`.
    *   Review/complete `ClubInfoStep` in post-register.
    *   Refine role/club/class logic if multiple are possible per user.
4.  **Testing**: Implement comprehensive Unit, Widget, and Integration tests.
5.  **API Client Enhancements**: Implement robust JWT injection, token refresh, and global auth error handling (`AuthEventService` integration).
6.  **Detailed Feature Screens**: Implement screens navigated to from the Home menu.

## Current Status
- **Project**: Post-initial setup, core features partially implemented.
- **Architecture**: Foundation laid, needs DI refactoring and consistent pattern application.
- **Core Modules (Auth, PostRegister, User, Profile, Home)**: Partially functional, require completion and refinement.
- **Other Modules (MainLayout, Activities, Club)**: Structure exists, implementation pending.
- **Testing**: Infrastructure (dependencies) present, implementation pending.
- **Documentation**: Memory Bank updated based on current analysis.

## Known Issues
- Manual Dependency Injection is fragile.
- Inconsistent use/enforcement of Clean Architecture layers in some areas.
- Error handling can be improved (more specific messages, global auth handling).
- Several key features are not yet implemented (Activities, Specialities, Main Layout Navigation, Profile Update).
- Testing coverage is minimal/non-existent.
- Potential logic issues (e.g., `_determineUserRole`, `ProfileScreen` loading, `StepperControls` logic).

## Next Milestones
1.  **DI Refactoring**: Implement `get_it` throughout the application.
2.  **Main Layout Implementation**: Build `ShellRoute` with `MotionTabBar` and connect main screens (Home, Activities, Profile).
3.  **Activities Module**: Implement core functionality for viewing/managing activities.
4.  **Profile Completion**: Implement Specialities section, Profile Update, Configuration screen, and integrate Allergy/Disease/Contact management.
5.  **Testing Foundation**: Set up base test configurations and write initial tests for critical flows (Auth, PostRegister). 