# SACDIA App Technical Context

## Technologies Used
- Flutter SDK: ^3.6.1
- Dart SDK: ^3.6.1
- Backend API: NestJS (Node.js framework)
- Database: PostgreSQL (hosted on Supabase)
- ORM: Prisma (used in NestJS API)
- Authentication Provider: Supabase Auth (Email/Password, JWT)
- HTTP Client: Dio (^5.8.0+1)
- State Management: flutter_bloc (^9.0.0), Cubit
- Routing: go_router (^14.7.2)
- Dependency Injection: get_it (^8.0.3) (Planned)
- Image Handling: image_picker (^1.1.2), image_cropper (^9.0.0), flutter_image_compress (^2.4.0)
- Local Storage: shared_preferences (^2.5.1)
- Core Dependencies: equatable (^2.0.7), http_parser (^4.1.2), intl (^0.19.0), flutter_localizations
- UI Libraries: google_fonts (^6.2.1), motion_tab_bar (^2.0.4), modal_bottom_sheet (^3.0.0), easy_date_timeline (^2.0.6), flutter_svg (^2.0.17), cupertino_icons (^1.0.8)
- Utility: url_launcher (^6.3.1)

## Development Setup
1.  **Environment Requirements**:
    *   Flutter SDK >= 3.6.1
    *   Dart SDK >= 3.6.1
    *   Android Studio / VS Code with Flutter/Dart extensions
    *   Access to the NestJS API endpoint (currently `http://127.0.0.1:3000` in `constants.dart`)
    *   Supabase Project URL and Anon Key (configured in `main.dart`)
2.  **Project Structure**:
    *   `lib/`: Main application code.
        *   `core/`: Shared utilities, widgets, services, constants, router.
        *   `features/`: Modules representing application features (auth, home, profile, user, post_register, club, activities, theme, main_layout).
            *   Each feature typically contains subdirectories like `bloc`/`cubit`, `models`, `repository`/`services`, `screens`/`presentation`, `widgets`.
        *   `main.dart`: App entry point, Supabase init, manual DI (currently), MultiBlocProvider setup, MaterialApp.router setup.
    *   `test/`: Unit, widget, and integration tests (implementation pending).
    *   `assets/`: Static assets (images, SVGs, icons).
    *   `memory-bank/`: Project documentation.
    *   `pubspec.yaml`: Dependency management.
    *   `.cursorrules`: AI assistant guidelines.
    *   `analysis_options.yaml`: Linter rules (`flutter_lints`).
3.  **Key Files/Folders**:
    *   `lib/main.dart`: Entry point & Root Configuration.
    *   `lib/core/router/app_router.dart`: Routing logic.
    *   `lib/core/http/api_client.dart`: Centralized HTTP client.
    *   `lib/core/constants.dart`: App-wide constants (colors, API URL, asset paths).
    *   `features/*/bloc/ | cubit/`: State management logic.
    *   `features/*/repository/ | services/`: Data access logic.
    *   `pubspec.yaml`: Dependencies.

## Technical Constraints
1.  **Platform Support**: Android, iOS.
2.  **Backend Dependency**: Requires the NestJS API to be running and accessible.
3.  **Supabase Dependency**: Requires Supabase for Auth and Database hosting.
4.  **State Management Mix**: Need to manage the co-existence of BLoC and Cubit patterns.
5.  **Manual DI**: Current DI approach is manual and error-prone; migration to `get_it` is needed.

## Development Tools
1.  **IDE**: Android Studio / VS Code.
2.  **Testing**: flutter_test, bloc_test, mocktail (frameworks in place, tests need writing).
3.  **Code Quality**: flutter_lints.
4.  **Version Control**: Git.
5.  **API Testing**: Postman / Insomnia (recommended for testing NestJS API).

## Build and Deployment
1.  **Build Process**: Standard `flutter build apk` / `flutter build ipa`.
2.  **Configuration**: API endpoint in `constants.dart` needs to be updated for different environments (Dev, Prod).
3.  **Deployment**: Standard App Store / Play Store deployment procedures.
4.  **CI/CD**: Not implemented yet. 