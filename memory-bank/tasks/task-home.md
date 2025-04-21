# Home Module Tasks

- **Refactor DI**: Migrate `HomeBloc` creation to use `get_it`.
- **Implement Navigation**: Ensure all routes defined in `MenuOptions` are correctly set up in `AppRouter` (or a nested router) and lead to implemented screens.
- **Connect Club Type Selector**: 
    - Implement the UI/logic within `ClubTypeSelector` modal.
    - Connect the selection action to `UserBloc`'s `ChangeClubType` event.
    - Ensure `HomeHeader` and potentially the menu options update based on the selected club type stored in `UserState`.
- **Define Menu Options**: Finalize the `MenuOptions.getOptionsForRole` logic to ensure correct options and routes are provided for 'member' and 'director' roles.
- **Implement Destination Screens**: Build the screens corresponding to each menu option route (e.g., Activities, Specialities, Club Management, etc.).
- **Refine Role Logic**: Review `_determineUserRole` logic. If roles are more complex than just having a `club*Id` assigned, update it to use `UserRolesCubit` or fetched role data.
- **UI/UX**: Improve loading/error states, ensure header updates correctly on profile/club changes.
- **Testing**: 
    - Write Unit tests for `HomeBloc`.
    - Write Widget tests for `HomeScreen`, `HomeHeader`, `MenuOptionCard`, `ClubTypeSelector`. 