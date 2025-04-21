# SACDIA App Project Brief

## Project Overview
SACDIA (Sistema Administrativo de Clubes del Ministerio Juvenil Adventista) is a Flutter-based mobile application designed to support members, directors, and administration of Adventist youth clubs (Adventurers, Pathfinders, Master Guides). It centralizes information, streamlines administrative and management processes, and aims to free up time for developmental activities.

## Core Requirements
- Flutter SDK version: >=3.6.1
- Target Platforms: Android, iOS
- Centralized information repository for club members.
- Streamlined administrative and management tasks.
- Role-based access and features (Member, Director).
- Post-registration process for collecting essential user data.
- Club hierarchy management (Country > Union > Local Field > Club).
- User profile management (personal info, medical info, club affiliation, classes, specialities, roles).
- Theme switching (Light/Dark).
- Spanish (Mexico) localization.

## Technical Stack
- Frontend: Flutter (~3.6.1)
- State Management: flutter_bloc (^9.0.0), Cubit (for newer modules)
- Routing: go_router (^14.7.2)
- Dependency Injection: Manual (Planned: get_it ^8.0.3)
- Backend: Custom NestJS REST API
- Database: PostgreSQL (hosted on Supabase)
- Auth: Supabase Auth (Email/Password, JWT)
- HTTP Client: dio (^5.8.0+1)
- Image Handling: image_picker (^1.1.2), image_cropper (^9.0.0), flutter_image_compress (^2.4.0)
- Local Storage: shared_preferences (^2.5.1) for theme
- UI Components: motion_tab_bar (^2.0.4), modal_bottom_sheet (^3.0.0), easy_date_timeline (^2.0.6), flutter_svg (^2.0.17)
- Typography: google_fonts (^6.2.1)
- Localization: intl (^0.19.0), flutter_localizations
- Testing (Dependencies present, implementation pending): flutter_test, bloc_test (^10.0.0), mocktail (^1.0.4)
- Linting: flutter_lints (^5.0.0)

## Project Goals
- Provide a unified platform for club management.
- Reduce administrative overhead for club leaders.
- Improve data consistency and accessibility.
- Offer a modern and user-friendly mobile experience.

## Success Criteria
- High adoption rate among target clubs.
- Positive feedback from users (members and directors) regarding ease of use and time savings.
- Measurable reduction in manual administrative tasks.
- Stable and performant application across supported platforms.
- Comprehensive data available for reporting and decision-making (future goal). 