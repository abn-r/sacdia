# User Module Tasks

- **Refactor DI**: Migrate `UserRepository`, `UserService`, `UserBloc`, and all User Cubits creation to use `get_it`.
- **Implement Missing Cubits**: Create `UserEmergencyContactsCubit`, following the pattern of `UserAllergiesCubit`/`UserDiseasesCubit` (including state management, caching, and `UserService` interaction).
- **Implement Screens**: Create necessary screens within `features/user/screens` or `features/profile/presentation/screens` for:
    - Managing Emergency Contacts (View, Add, Delete - using the new Cubit).
    - Viewing User Roles (using `UserRolesCubit`).
    - Viewing User Classes (using `UserClassesCubit`).
- **Integrate into Profile**: Ensure `UserPersonalInfoScreen` (in `profile` module) correctly displays and allows navigation to manage Allergies, Diseases, and Emergency Contacts.
- **Refine Caching**: Review and potentially improve the caching strategy in the Cubits (e.g., invalidate cache on add/delete actions automatically).
- **Error Handling**: Improve error handling in `UserService` (implement `_handleAuthError`) and ensure Cubits/Bloc handle errors gracefully in the UI.
- **Testing**: 
    - Write Unit tests for `UserBloc` and all User Cubits.
    - Write Integration tests for `UserRepository` and `UserService` methods. 