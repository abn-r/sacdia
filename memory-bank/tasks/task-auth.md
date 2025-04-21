# Auth Module Tasks

- **Refactor DI**: Migrate `AuthRepository`, `AuthBloc`, `AuthEventService` creation to use `get_it`.
- **Login Social**: Implement login with Google/Facebook/etc. if required (requires backend and frontend changes).
- **Email Verification**: Implement email verification flow during signup (check Supabase settings, potentially add UI feedback/step).
- **Error Handling**: 
    - Map Supabase/API specific errors to user-friendly messages in `AuthBloc`.
    - Improve visual feedback for errors in `LoginScreen`, `RegisterScreen`, `ForgotPasswordScreen`.
- **Refine Signup**: Clarify if user creation happens solely in NestJS API or if Supabase Auth signup is also needed. Ensure consistency.
- **Token Refresh Logic**: Verify where `AuthRepository.getValidToken` is used (likely needs integration into `ApiClient` interceptor).
- **Testing**: Write Unit tests for `AuthBloc` and Integration tests for `AuthRepository` methods. 