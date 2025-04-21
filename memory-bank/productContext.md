# SACDIA App Product Context

## Why This Project Exists
SACDIA exists to provide a digital tool for Adventist youth clubs (Adventurers, Pathfinders, Master Guides) and their administration. It aims to replace manual, paper-based processes with an efficient, centralized system.

## Problems It Solves
- Lack of centralized information systems for Adventist youth clubs.
- Loss of information currently managed on paper.
- Difficulty in unifying criteria for evaluating member progress (specialities, classes, attendance).
- Time-consuming administrative tasks that detract from core club activities.

## How It Should Work
The app follows a Clean Architecture pattern (though not strictly enforced everywhere yet):
- **Presentation Layer**: Flutter UI (Screens, Widgets).
- **Business Logic Layer**: BLoC/Cubit for state management.
- **Data Layer**: Repositories abstracting data sources.
- **Backend**: Custom NestJS API interacting with a Supabase PostgreSQL database.
- **Authentication**: Supabase Auth for email/password login and JWT management.
- **Navigation**: GoRouter handles routing and redirection based on auth/post-register status.
- **Core Features**: User registration, post-registration data collection, user profile view (including classes, roles), home dashboard with role-based menu options.

## User Experience Goals
- Intuitive and user-friendly interface for both members and directors.
- Fast and responsive performance.
- Clear navigation and information hierarchy.
- Consistent design language (based on Material Design with custom SACDIA branding).
- Accessible to all users.
- Localized content (currently Spanish - Mexico).

## Key Features (Implemented & Planned)
- User Authentication (Login, Register, Forgot Password)
- Post-Registration Stepper (Photo, Personal Info, Club Info)
- User Profile Display (Basic Info, Club, Role, Class, Baptism Status, Investiture Status)
- Home Dashboard with Role-Based Menu
- Theme Switching (Light/Dark)
- Club Type Selection
- *Planned/In Progress:* Activities Management, Specialities Tracking, Full Profile Editing, Configuration Options, Emergency Contact Management (UI exists, logic needed).

## Target Audience
- Members of Adventist Youth Clubs (Adventurers, Pathfinders, Master Guides).
- Directors and Leaders of these clubs.
- Church/Conference Administration overseeing the clubs. 