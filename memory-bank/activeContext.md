# SACDIA App Active Context

## Current Work Focus
- Documenting the existing codebase state using the Memory Bank.
- Identifying implemented features and pending tasks per module.
- Preparing for subsequent development based on the analysis.

## Recent Changes (Analysis Results)
- **Architecture**: Clean Architecture structure identified (`core`, `features`), but DI is manual, and state management uses both BLoC and Cubit.
- **Core**: Router, Constants, HTTP Client, shared widgets (`AuthEventListener`, `InputTextWidget`), and Catalog management (`CatalogsBloc`) are in place.
- **Auth**: Login (Supabase), Signup (NestJS API), Forgot Password (Supabase), Signout implemented. Logic handles post-register status.
- **Post-Register**: Multi-step process implemented using `Stepper`, `PostRegisterBloc`, and `PostRegisterRepository`. Handles photo upload, personal info, and club info selection. Communicates completion to `AuthBloc`.
- **User**: `UserBloc` manages basic profile loading/updating. `UserService` provides methods for detailed data (allergies, diseases, contacts, clubs, classes, roles). `UserAllergiesCubit` & `UserDiseasesCubit` implemented for granular state management of these lists.
- **Profile**: Main profile screen (`ProfileScreen`) integrates data from `UserBloc` and several Cubits (`UserClubsCubit`, `UserClassesCubit`, `UserRolesCubit`). Includes navigation to personal info details and configuration. Specialities section and profile update are pending.
- **Home**: Dashboard screen (`HomeScreen`) shows role-based menu options. Integrates user profile and club data. Club type selection UI exists but logic needs connection.
- **Other Modules**: `main_layout`, `activities`, `club`, `theme` structures exist but functionality needs detailed review/implementation.

## Next Steps (Based on Analysis)
1.  **Dependency Injection**: Refactor entire application to use `get_it` for managing Repositories, Services, Blocs, and Cubits.
2.  **Complete Core Features**: 
    *   Implement `main_layout` (ShellRoute with MotionTabBar).
    *   Implement `activities` module (Screens, State Management, API calls).
    *   Implement `profile/ConfigurationScreen`.
    *   Implement profile update functionality.
    *   Implement specialities section in `ProfileScreen` (requires Cubit, Service methods, UI).
    *   Connect `ClubTypeSelector` in `HomeScreen` to `UserBloc`.
3.  **Refine Existing Modules**: 
    *   Address identified TODOs/potential issues in `auth`, `post_register`, `user`, `profile`, `home` (e.g., error handling, UI/UX feedback, navigation setup).
    *   Implement remaining User Cubits (`EmergencyContacts`, `Roles`, `Classes`).
    *   Complete `profile/user_personal_info_screen` to integrate allergy/disease/contact management.
4.  **Testing**: Implement Unit, Widget, and Integration tests across modules.
5.  **API Client**: Ensure `ApiClient` includes robust JWT token injection, refresh logic, and global error handling (connecting `_handleAuthError` in `UserService` to `AuthEventService`).

## Active Decisions
1.  **State Management**: Continue using BLoC for existing features and Cubit for new ones.
2.  **Dependency Injection**: Migrate to `get_it`.
3.  **Architecture**: Maintain the feature-based structure with `core` for shared elements.
4.  **Backend**: Continue using the NestJS API + Supabase Auth/DB combination.

## Current Considerations
1.  **Technical**: Managing the mix of BLoC/Cubit, ensuring robust error handling (especially auth errors from API), implementing comprehensive tests.
2.  **Product**: Prioritizing the implementation of core missing features (Activities, Specialities, Main Layout) vs. refining existing ones.
3.  **Development**: Need for clear task breakdown based on the generated `task-*.md` files.

## Current Considerations
1. Technical
   - Performance optimization
   - Code organization
   - Testing strategy
   - Security implementation

2. Product
   - Feature prioritization
   - User experience design
   - Platform compatibility
   - Localization strategy

3. Development
   - Team collaboration
   - Code review process
   - Documentation standards
   - Version control workflow 