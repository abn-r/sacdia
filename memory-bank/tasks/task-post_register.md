# Post-Register Module Tasks

- **Refactor DI**: Migrate `PostRegisterRepository`, `PostRegisterBloc` creation to use `get_it`.
- **Complete `ClubInfoStep`**: Review and ensure `ClubInfoStep` widget correctly implements the UI for selecting Country -> Union -> Field -> Club -> Class, including loading indicators and error handling for cascaded catalog calls.
- **Review Final Step Logic**: Verify the logic in `_StepperControls` for the "Continuar" button on the last step. Ensure it doesn't conflict with the completion logic in `PostRegisterBloc._onCompletePostRegisterRequested`.
- **UI/UX Improvements**:
    - Add clear loading indicators within each step (e.g., during photo upload, saving personal info, loading catalogs).
    - Provide specific user feedback for API errors (e.g., "User already registered in this club").
    - Improve catalog selection UI if needed (e.g., search, better empty states).
- **Error Handling**: Enhance error handling in `PostRegisterBloc` and `PostRegisterRepository` to provide more context.
- **Catalog Optimization**: Consider pre-loading stable catalogs (like Countries) globally instead of within this flow.
- **Testing**: 
    - Write Unit tests for `PostRegisterBloc`, mocking dependencies.
    - Write Widget tests for `StepperContent` and individual step widgets (`PhotoUploadStep`, `PersonalInfoStep`, `ClubInfoStep`).
    - Write Integration tests for `PostRegisterRepository` methods. 