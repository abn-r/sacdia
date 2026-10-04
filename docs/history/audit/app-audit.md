# App Audit — SACDIA
Fecha: 2026-03-14
Fuente: sacdia-app/ (Flutter + Clean Architecture)
Metodo: Scan automatico de codigo fuente

## Resumen
- Screens: 55
- Features: 15
- Endpoints consumidos: 80
- Dependencias principales: 26

---

## Screens

Views (pantallas) encontradas en `lib/features/**/presentation/views/` y widgets que actuan como pantallas en el router.

| # | Screen | Feature | File Path | Descripcion |
|---|--------|---------|-----------|-------------|
| 1 | SplashView | auth | lib/features/auth/presentation/views/splash_view.dart | Splash inicial mientras se resuelve auth state |
| 2 | LoginView | auth | lib/features/auth/presentation/views/login_view.dart | Login con email/password |
| 3 | RegisterView | auth | lib/features/auth/presentation/views/register_view.dart | Registro de nuevo usuario |
| 4 | ForgotPasswordView | auth | lib/features/auth/presentation/views/forgot_password_view.dart | Recuperacion de contrasena |
| 5 | AuthGate | auth | lib/features/auth/presentation/widgets/auth_gate.dart | Widget gate que redirige segun auth state |
| 6 | PostRegistrationShell | post_registration | lib/features/post_registration/presentation/views/post_registration_shell.dart | Shell/stepper del post-registro |
| 7 | PhotoStepView | post_registration | lib/features/post_registration/presentation/views/photo_step_view.dart | Paso 1: foto de perfil |
| 8 | PersonalInfoStepView | post_registration | lib/features/post_registration/presentation/views/personal_info_step_view.dart | Paso 2: info personal |
| 9 | EmergencyContactsView | post_registration | lib/features/post_registration/presentation/views/emergency_contacts_view.dart | Contactos de emergencia |
| 10 | AddEditContactView | post_registration | lib/features/post_registration/presentation/views/add_edit_contact_view.dart | Agregar/editar contacto de emergencia |
| 11 | LegalRepresentativeView | post_registration | lib/features/post_registration/presentation/views/legal_representative_view.dart | Representante legal (menores) |
| 12 | AllergiesSelectionView | post_registration | lib/features/post_registration/presentation/views/allergies_selection_view.dart | Seleccion de alergias |
| 13 | DiseasesSelectionView | post_registration | lib/features/post_registration/presentation/views/diseases_selection_view.dart | Seleccion de enfermedades |
| 14 | ClubSelectionStepView | post_registration | lib/features/post_registration/presentation/views/club_selection_step_view.dart | Paso 3: seleccion de club |
| 15 | DashboardView | dashboard | lib/features/dashboard/presentation/views/dashboard_view.dart | Dashboard principal / Home |
| 16 | HomeView | home | lib/features/home/presentation/views/home_view.dart | Vista home (legacy o alternativa) |
| 17 | ResourcesSection | home | lib/features/home/presentation/widgets/resources_section.dart | Seccion de recursos (registrada como ruta) |
| 18 | ClassesListView | classes | lib/features/classes/presentation/views/classes_list_view.dart | Listado de clases progresivas |
| 19 | ClassDetailView | classes | lib/features/classes/presentation/views/class_detail_view.dart | Detalle de clase |
| 20 | ClassDetailWithProgressView | classes | lib/features/classes/presentation/views/class_detail_with_progress_view.dart | Detalle de clase con progreso |
| 21 | ClassModulesView | classes | lib/features/classes/presentation/views/class_modules_view.dart | Modulos de una clase |
| 22 | SectionDetailView | classes | lib/features/classes/presentation/views/section_detail_view.dart | Detalle de seccion de clase |
| 23 | RequirementDetailView | classes | lib/features/classes/presentation/views/requirement_detail_view.dart | Detalle de requerimiento de clase |
| 24 | ActivitiesListView | activities | lib/features/activities/presentation/views/activities_list_view.dart | Listado de actividades del club |
| 25 | ActivityDetailView | activities | lib/features/activities/presentation/views/activity_detail_view.dart | Detalle de una actividad |
| 26 | CreateActivityView | activities | lib/features/activities/presentation/views/create_activity_view.dart | Crear nueva actividad |
| 27 | LocationPickerView | activities | lib/features/activities/presentation/views/location_picker_view.dart | Selector de ubicacion en mapa |
| 28 | HonorsCatalogView | honors | lib/features/honors/presentation/views/honors_catalog_view.dart | Catalogo de especialidades |
| 29 | HonorDetailView | honors | lib/features/honors/presentation/views/honor_detail_view.dart | Detalle de una especialidad |
| 30 | MyHonorsView | honors | lib/features/honors/presentation/views/my_honors_view.dart | Especialidades del usuario |
| 31 | AddHonorView | honors | lib/features/honors/presentation/views/add_honor_view.dart | Registrar nueva especialidad |
| 32 | ProfileView | profile | lib/features/profile/presentation/views/profile_view.dart | Perfil del usuario |
| 33 | EditProfileView | profile | lib/features/profile/presentation/views/edit_profile_view.dart | Editar perfil |
| 34 | SettingsView | profile | lib/features/profile/presentation/views/settings_view.dart | Configuracion de la app |
| 35 | TemplateView | profile | lib/features/profile/presentation/views/template_view.dart | Vista template (posible preview) |
| 36 | Template1View | profile | lib/features/profile/presentation/views/template_1_view.dart | Template variante 1 |
| 37 | Template2View | profile | lib/features/profile/presentation/views/template_2_view.dart | Template variante 2 |
| 38 | MembersView | members | lib/features/members/presentation/views/members_view.dart | Listado de miembros del club |
| 39 | MemberProfileView | members | lib/features/members/presentation/views/member_profile_view.dart | Perfil de un miembro |
| 40 | RoleAssignmentView | members | lib/features/members/presentation/views/role_assignment_view.dart | Asignacion de roles |
| 41 | ClubView | club | lib/features/club/presentation/views/club_view.dart | Vista de informacion del club |
| 42 | UnitsListView | units | lib/features/units/presentation/views/units_list_view.dart | Listado de unidades |
| 43 | UnitDetailView | units | lib/features/units/presentation/views/unit_detail_view.dart | Detalle de una unidad |
| 44 | EvidenceFolderView | evidence_folder | lib/features/evidence_folder/presentation/views/evidence_folder_view.dart | Carpeta de evidencias |
| 45 | EvidenceSectionDetailView | evidence_folder | lib/features/evidence_folder/presentation/views/evidence_section_detail_view.dart | Detalle de seccion de evidencia |
| 46 | FinancesView | finances | lib/features/finances/presentation/views/finances_view.dart | Vista de finanzas del club |
| 47 | AddTransactionSheet | finances | lib/features/finances/presentation/views/add_transaction_sheet.dart | Sheet para agregar transaccion |
| 48 | TransactionDetailView | finances | lib/features/finances/presentation/views/transaction_detail_view.dart | Detalle de transaccion |
| 49 | InventoryView | inventory | lib/features/inventory/presentation/views/inventory_view.dart | Vista de inventario del club |
| 50 | InventoryItemDetailView | inventory | lib/features/inventory/presentation/views/inventory_item_detail_view.dart | Detalle de item de inventario |
| 51 | AddInventoryItemSheet | inventory | lib/features/inventory/presentation/views/add_inventory_item_sheet.dart | Sheet para agregar item |
| 52 | InventoryFilterSheet | inventory | lib/features/inventory/presentation/views/inventory_filter_sheet.dart | Sheet de filtros de inventario |
| 53 | InsuranceView | insurance | lib/features/insurance/presentation/views/insurance_view.dart | Vista de seguros del club |
| 54 | InsuranceDetailView | insurance | lib/features/insurance/presentation/views/insurance_detail_view.dart | Detalle de seguro de miembro |
| 55 | InsuranceFormSheet | insurance | lib/features/insurance/presentation/views/insurance_form_sheet.dart | Sheet para crear/editar seguro |

**Total screens: 55** (incluye views, shells y bottom sheets registrados como vistas independientes)

---

## Consumo de API por Feature

### auth
| DataSource | Metodo | Endpoint |
|------------|--------|----------|
| AuthRemoteDataSourceImpl | GET | /auth/me |
| AuthRemoteDataSourceImpl | POST | /auth/login |
| AuthRemoteDataSourceImpl | POST | /auth/register |
| AuthRemoteDataSourceImpl | POST | /auth/logout |
| AuthRemoteDataSourceImpl | POST | /auth/request-password-reset |
| AuthRemoteDataSourceImpl | POST | /auth/update-password |
| AuthRemoteDataSourceImpl | POST | /auth/pr-check |
| AuthRemoteDataSourceImpl | GET | /auth/profile/completion-status |
| AuthRemoteDataSourceImpl | PATCH | /auth/me/context |

### activities
| DataSource | Metodo | Endpoint |
|------------|--------|----------|
| ActivitiesRemoteDataSourceImpl | GET | /clubs/:clubId/activities |
| ActivitiesRemoteDataSourceImpl | GET | /activities/:activityId |
| ActivitiesRemoteDataSourceImpl | POST | /clubs/:clubId/activities |
| ActivitiesRemoteDataSourceImpl | PATCH | /activities/:activityId |
| ActivitiesRemoteDataSourceImpl | DELETE | /activities/:activityId |
| ActivitiesRemoteDataSourceImpl | GET | /activities/:activityId/attendance |
| ActivitiesRemoteDataSourceImpl | POST | /activities/:activityId/attendance |

### classes
| DataSource | Metodo | Endpoint |
|------------|--------|----------|
| ClassesRemoteDataSourceImpl | GET | /classes |
| ClassesRemoteDataSourceImpl | GET | /classes/:classId |
| ClassesRemoteDataSourceImpl | GET | /classes/:classId/modules |
| ClassesRemoteDataSourceImpl | GET | /users/:userId/classes |
| ClassesRemoteDataSourceImpl | GET | /users/:userId/classes/:classId/progress |
| ClassesRemoteDataSourceImpl | PATCH | /users/:userId/classes/:classId/progress |
| ClassesRemoteDataSourceImpl | POST | /users/:userId/classes/:classId/sections/:requirementId/files |
| ClassesRemoteDataSourceImpl | DELETE | /users/:userId/classes/:classId/sections/:requirementId/files/:fileId |

### club
| DataSource | Metodo | Endpoint |
|------------|--------|----------|
| ClubRemoteDataSourceImpl | GET | /clubs/:clubId |
| ClubRemoteDataSourceImpl | GET | /clubs/:clubId/instances/:instanceType/:instanceId |
| ClubRemoteDataSourceImpl | PATCH | /clubs/:clubId/instances/:instanceType/:instanceId |

### dashboard
| DataSource | Metodo | Endpoint |
|------------|--------|----------|
| DashboardRemoteDataSourceImpl | (ninguno) | No hace llamadas HTTP; construye datos desde metadata local |

### honors
| DataSource | Metodo | Endpoint |
|------------|--------|----------|
| HonorsRemoteDataSourceImpl | GET | /honors/categories |
| HonorsRemoteDataSourceImpl | GET | /honors |
| HonorsRemoteDataSourceImpl | GET | /honors/:honorId |
| HonorsRemoteDataSourceImpl | GET | /honors/grouped-by-category |
| HonorsRemoteDataSourceImpl | GET | /users/:userId/honors |
| HonorsRemoteDataSourceImpl | GET | /users/:userId/honors/stats |
| HonorsRemoteDataSourceImpl | POST | /users/:userId/honors/:honorId |
| HonorsRemoteDataSourceImpl | POST | /users/:userId/honors |
| HonorsRemoteDataSourceImpl | PATCH | /users/:userId/honors/:honorId |
| HonorsRemoteDataSourceImpl | DELETE | /users/:userId/honors/:honorId |

### members
| DataSource | Metodo | Endpoint |
|------------|--------|----------|
| MembersRemoteDataSourceImpl | GET | /clubs/:clubId/instances/:instanceType/:instanceId/members |
| MembersRemoteDataSourceImpl | GET | /clubs/:clubId/instances/:instanceType/:instanceId/members?status=pending |
| MembersRemoteDataSourceImpl | GET | /users/:userId |
| MembersRemoteDataSourceImpl | GET | /catalogs/roles?category=CLUB |
| MembersRemoteDataSourceImpl | POST | /clubs/:clubId/instances/:instanceType/:instanceId/roles |
| MembersRemoteDataSourceImpl | PATCH | /club-roles/:assignmentId |
| MembersRemoteDataSourceImpl | DELETE | /club-roles/:assignmentId |

### post_registration
| DataSource | Metodo | Endpoint |
|------------|--------|----------|
| PostRegistrationRemoteDataSourceImpl | GET | /auth/profile/completion-status |
| PostRegistrationRemoteDataSourceImpl | POST | /users/:userId/profile-picture |
| PostRegistrationRemoteDataSourceImpl | DELETE | /users/:userId/profile-picture |
| PostRegistrationRemoteDataSourceImpl | GET | /users/:userId/post-registration/photo-status |
| PostRegistrationRemoteDataSourceImpl | POST | /users/:userId/post-registration/step-1/complete |
| PersonalInfoRemoteDataSourceImpl | PATCH | /users/:userId |
| PersonalInfoRemoteDataSourceImpl | GET | /users/:userId/emergency-contacts |
| PersonalInfoRemoteDataSourceImpl | POST | /users/:userId/emergency-contacts |
| PersonalInfoRemoteDataSourceImpl | PATCH | /emergency-contacts/:contactId |
| PersonalInfoRemoteDataSourceImpl | DELETE | /emergency-contacts/:contactId |
| PersonalInfoRemoteDataSourceImpl | GET | /catalogs/relationship-types |
| PersonalInfoRemoteDataSourceImpl | GET | /users/:userId/requires-legal-representative |
| PersonalInfoRemoteDataSourceImpl | POST | /users/:userId/legal-representative |
| PersonalInfoRemoteDataSourceImpl | GET | /users/:userId/legal-representative |
| PersonalInfoRemoteDataSourceImpl | PATCH | /users/:userId/legal-representative |
| PersonalInfoRemoteDataSourceImpl | GET | /catalogs/allergies |
| PersonalInfoRemoteDataSourceImpl | GET | /users/:userId/allergies |
| PersonalInfoRemoteDataSourceImpl | PUT | /users/:userId/allergies |
| PersonalInfoRemoteDataSourceImpl | DELETE | /users/:userId/allergies/:allergyId |
| PersonalInfoRemoteDataSourceImpl | GET | /catalogs/diseases |
| PersonalInfoRemoteDataSourceImpl | GET | /users/:userId/diseases |
| PersonalInfoRemoteDataSourceImpl | PUT | /users/:userId/diseases |
| PersonalInfoRemoteDataSourceImpl | DELETE | /users/:userId/diseases/:diseaseId |
| PersonalInfoRemoteDataSourceImpl | POST | /users/:userId/post-registration/step-2/complete |
| ClubSelectionRemoteDataSourceImpl | GET | /catalogs/countries |
| ClubSelectionRemoteDataSourceImpl | GET | /catalogs/unions?countryId=:id |
| ClubSelectionRemoteDataSourceImpl | GET | /catalogs/local-fields?unionId=:id |
| ClubSelectionRemoteDataSourceImpl | GET | /clubs?localFieldId=:id |
| ClubSelectionRemoteDataSourceImpl | GET | /clubs/:clubId/instances |
| ClubSelectionRemoteDataSourceImpl | GET | /classes?clubTypeId=:id |
| ClubSelectionRemoteDataSourceImpl | POST | /users/:userId/post-registration/step-3/complete |

### profile
| DataSource | Metodo | Endpoint |
|------------|--------|----------|
| ProfileRemoteDataSourceImpl | GET | /auth/me |
| ProfileRemoteDataSourceImpl | PATCH | /users/:userId |
| ProfileRemoteDataSourceImpl | POST | /users/:userId/profile-picture |

### evidence_folder
| DataSource | Metodo | Endpoint |
|------------|--------|----------|
| EvidenceFolderRemoteDataSourceImpl | GET | /club-instances/:id/evidence-folder |
| EvidenceFolderRemoteDataSourceImpl | POST | /club-instances/:id/evidence-folder/sections/:sectionId/submit |
| EvidenceFolderRemoteDataSourceImpl | POST | /club-instances/:id/evidence-folder/sections/:sectionId/files |
| EvidenceFolderRemoteDataSourceImpl | DELETE | /club-instances/:id/evidence-folder/sections/:sectionId/files/:fileId |

### finances
| DataSource | Metodo | Endpoint |
|------------|--------|----------|
| FinancesRemoteDataSourceImpl | GET | /clubs/:clubId/finances?year=&month= |
| FinancesRemoteDataSourceImpl | GET | /clubs/:clubId/finances/summary |
| FinancesRemoteDataSourceImpl | GET | /finances/:financeId |
| FinancesRemoteDataSourceImpl | POST | /clubs/:clubId/finances |
| FinancesRemoteDataSourceImpl | PATCH | /finances/:financeId |
| FinancesRemoteDataSourceImpl | DELETE | /finances/:financeId |
| FinancesRemoteDataSourceImpl | GET | /finances/categories |

### inventory
| DataSource | Metodo | Endpoint |
|------------|--------|----------|
| InventoryRemoteDataSourceImpl | GET | /inventory/catalogs/inventory-categories |
| InventoryRemoteDataSourceImpl | GET | /inventory/clubs/:clubId/inventory |
| InventoryRemoteDataSourceImpl | GET | /inventory/inventory/:id |
| InventoryRemoteDataSourceImpl | POST | /inventory/clubs/:clubId/inventory |
| InventoryRemoteDataSourceImpl | PATCH | /inventory/inventory/:id |
| InventoryRemoteDataSourceImpl | DELETE | /inventory/inventory/:id |

### insurance
| DataSource | Metodo | Endpoint |
|------------|--------|----------|
| InsuranceRemoteDataSourceImpl | GET | /clubs/:clubId/instances/:type/:instanceId/members/insurance |
| InsuranceRemoteDataSourceImpl | GET | /users/:memberId/insurance |
| InsuranceRemoteDataSourceImpl | POST | /users/:memberId/insurance |
| InsuranceRemoteDataSourceImpl | PATCH | /insurance/:insuranceId |

### shared (catalogs)
| DataSource | Metodo | Endpoint |
|------------|--------|----------|
| CatalogsRemoteDataSourceImpl | GET | /catalogs/club-types |
| CatalogsRemoteDataSourceImpl | GET | /catalogs/activity-types |
| CatalogsRemoteDataSourceImpl | GET | /catalogs/districts |
| CatalogsRemoteDataSourceImpl | GET | /catalogs/churches |
| CatalogsRemoteDataSourceImpl | GET | /catalogs/roles |
| CatalogsRemoteDataSourceImpl | GET | /catalogs/ecclesiastical-years |

**Total endpoints unicos consumidos: 80** (excluyendo dashboard que no hace HTTP)

---

## Estado de Auth

| Feature | Auth Required | Guard/Check | Notes |
|---------|--------------|-------------|-------|
| auth (splash) | No | GoRouter redirect | Transitorio; redirige segun auth state |
| auth (login) | No | Ruta publica | |
| auth (register) | No | Ruta publica | |
| auth (forgot-password) | No | Ruta publica | |
| post_registration | Si | GoRouter redirect | Requiere login + post_register_complete == false |
| dashboard | Si | GoRouter redirect | Requiere login + post_register_complete == true |
| classes | Si | GoRouter redirect (ShellRoute) | Dentro del shell autenticado |
| activities | Si | GoRouter redirect (ShellRoute) | Dentro del shell autenticado |
| profile | Si | GoRouter redirect (ShellRoute) | Dentro del shell autenticado |
| members | Si | GoRouter redirect (ShellRoute) | Dentro del shell autenticado |
| club | Si | GoRouter redirect (ShellRoute) | Dentro del shell autenticado |
| evidence_folder | Si | GoRouter redirect (ShellRoute) | Dentro del shell autenticado |
| finances | Si | GoRouter redirect (ShellRoute) | Dentro del shell autenticado |
| units | Si | GoRouter redirect (ShellRoute) | Dentro del shell autenticado |
| honors | Si | GoRouter redirect (ShellRoute) | No tiene ruta propia en router; accedido desde otras vistas |
| inventory | Si | GoRouter redirect (ShellRoute) | Dentro del shell autenticado |
| insurance | Si | GoRouter redirect (ShellRoute) | Dentro del shell autenticado |

**Mecanismo**: GoRouter redirect centralizado en `lib/core/config/router.dart`. Lee `authNotifierProvider` (Riverpod). Si no autenticado y ruta no publica, redirige a `/login`. Si autenticado con post-registro incompleto, redirige a `/post-registration`.

**Token storage**: `FlutterSecureStorage` (keys: `auth_token`, `auth_refresh_token`, `auth_expires_at`, `auth_token_type`).

**Auth state stream**: `AuthRemoteDataSource.authStateChanges` (StreamController broadcast).

---

## Navegacion

Router: GoRouter v15.2.0 definido en `lib/core/config/router.dart`.

| Route | Screen | Auth Required | Deep Link | Notes |
|-------|--------|--------------|-----------|-------|
| `/` | SplashView | No | No | Ruta inicial, transitoria |
| `/login` | LoginView | No | No | |
| `/register` | RegisterView | No | No | |
| `/forgot-password` | ForgotPasswordView | No | No | |
| `/post-registration` | PostRegistrationShell | Si | No | Slide-up transition |
| `/home/dashboard` | DashboardView | Si | No | Tab principal (bottom nav index 0) |
| `/home/classes` | ClassesListView | Si | No | Tab (bottom nav index 1) |
| `/home/activities` | ActivitiesListView | Si | No | Tab (bottom nav index 2) |
| `/home/profile` | ProfileView | Si | No | Tab (bottom nav index 3) |
| `/home/members` | MembersView | Si | No | Quick access desde dashboard |
| `/home/club` | ClubView | Si | No | Quick access desde dashboard |
| `/home/evidences` | EvidenceFolderShell | Si | No | Requiere club instance activo |
| `/home/finances` | FinancesView | Si | No | Quick access desde dashboard |
| `/home/units` | UnitsListView | Si | No | Quick access desde dashboard |
| `/home/grouped-class` | ClassDetailWithProgressView | Si | No | Hardcoded classId=1 |
| `/home/insurance` | InsuranceView | Si | No | Quick access desde dashboard |
| `/home/inventory` | InventoryView | Si | No | Quick access desde dashboard |
| `/home/resources` | ResourcesSection | Si | No | Recursos del club |
| `/club/:clubId` | PlaceholderScreen | Si | Si | Detalle de club (placeholder) |
| `/class/:classId` | ClassDetailWithProgressView | Si | Si | Detalle de clase con parametro |
| `/honor/:honorId` | PlaceholderScreen | Si | Si | Detalle de honor (placeholder) |

**Shell adaptativo**: `_MainShell` en router.dart. NavigationBar (bottom) en phones (<600dp), NavigationRail en tablets (>=600dp). 4 tabs: Inicio, Clases, Actividades, Perfil.

---

## Dependencias Principales

| Package | Version | Proposito |
|---------|---------|-----------|
| flutter_riverpod | ^2.6.1 | State management |
| supabase_flutter | ^2.9.1 | Supabase Auth client |
| dio | ^5.8.0+1 | HTTP client |
| go_router | ^15.2.0 | Navegacion declarativa |
| shared_preferences | ^2.5.3 | Almacenamiento local key-value |
| flutter_secure_storage | ^9.2.4 | Almacenamiento seguro de tokens |
| connectivity_plus | ^6.1.4 | Deteccion de conectividad |
| cached_network_image | ^3.4.1 | Cache de imagenes de red |
| flutter_svg | ^2.2.0 | Renderizado de SVGs |
| hugeicons | ^1.1.5 | Iconografia |
| loading_animation_widget | ^1.3.0 | Animaciones de carga |
| image_picker | ^1.0.7 | Seleccion de imagenes |
| image_cropper | ^5.0.1 | Recorte de imagenes |
| permission_handler | ^11.3.0 | Manejo de permisos del sistema |
| flutter_map | ^7.0.1 | Mapas (OpenStreetMap) |
| latlong2 | ^0.9.1 | Coordenadas geograficas |
| geocoding | ^3.0.0 | Geocodificacion |
| dartz | ^0.10.1 | Functional programming (Either) |
| equatable | ^2.0.7 | Comparacion de objetos |
| intl | ^0.20.1 | Internacionalizacion y formato de fechas |
| url_launcher | ^6.3.1 | Abrir URLs externas |
| firebase_core | ^3.8.0 | Firebase core |
| firebase_messaging | ^15.1.6 | Push notifications (FCM) |
| freezed | ^3.0.6 | Code generation (dev) |
| json_serializable | ^6.9.5 | Serializacion JSON (dev) |
| mockito | ^5.4.4 | Mocking para tests (dev) |

---

## Features Detectados

| # | Feature | Data Layer | Presentation Layer | Domain Layer |
|---|---------|------------|--------------------|--------------|
| 1 | auth | Si (1 datasource, 1 repo, 1 model) | Si (4 views, 3 widgets, 1 provider) | Si |
| 2 | activities | Si (1 datasource, 1 repo, 3 models) | Si (5 views, 3 widgets, 1 provider) | Si |
| 3 | classes | Si (1 datasource, 1 repo, 8 models) | Si (6 views, 4 widgets, 1 provider) | Si |
| 4 | club | Si (1 datasource, 1 repo, 1 model) | Si (1 view, 0 widgets, 1 provider) | Si |
| 5 | dashboard | Si (1 datasource, 1 repo, 1 model) | Si (1 view, 5 widgets, 1 provider) | Si |
| 6 | evidence_folder | Si (1 datasource, 1 repo, 3 models) | Si (2 views, 2 widgets, 1 provider) | Si |
| 7 | finances | Si (1 datasource, 1 repo, 4 models) | Si (3 views, 2 widgets, 1 provider) | Si |
| 8 | home | No | Si (1 view, 3 widgets, 1 provider) | No |
| 9 | honors | Si (1 datasource, 1 repo, 4 models) | Si (4 views, 3 widgets, 1 provider) | Si |
| 10 | insurance | Si (1 datasource, 1 repo, 1 model) | Si (3 views, 1 widget, 1 provider) | Si |
| 11 | inventory | Si (1 datasource, 1 repo, 2 models) | Si (4 views, 1 widget, 1 provider) | Si |
| 12 | members | Si (1 datasource, 1 repo, 2 models) | Si (3 views, 3 widgets, 1 provider) | Si |
| 13 | post_registration | Si (3 datasources, 1 repo, 11 models) | Si (8 views, 5 widgets, 3 providers) | Si |
| 14 | profile | Si (1 datasource, 1 repo, 1 model) | Si (6 views, 4 widgets, 1 provider) | Si |
| 15 | units | No | Si (2 views, 0 widgets, 1 provider) | No |

**Features sin data layer**: home, units (solo presentacion, sin consumo de API propio).

---

## Providers Globales

Ubicados en `lib/providers/`:

| Provider | Archivo | Proposito |
|----------|---------|-----------|
| dioProvider | lib/providers/dio_provider.dart | Instancia Dio compartida |
| storageProvider | lib/providers/storage_provider.dart | FlutterSecureStorage compartido |
| supabaseProvider | lib/providers/supabase_provider.dart | Supabase client |
| catalogsProvider | lib/providers/catalogs_provider.dart | Catalogos del sistema |

---

## Core Widgets Compartidos

Ubicados en `lib/core/widgets/`:

| Widget | Archivo | Proposito |
|--------|---------|-----------|
| SacButton | sac_button.dart | Boton personalizado |
| SacBadge | sac_badge.dart | Badge de estado |
| SacProgressRing | sac_progress_ring.dart | Anillo de progreso |
| SacProgressBar | sac_progress_bar.dart | Barra de progreso |
| SacLoading | sac_loading.dart | Indicador de carga |
| SacDialog | sac_dialog.dart | Dialogo personalizado |
| SacCard | sac_card.dart | Card personalizado |
| SacTextField | sac_text_field.dart | Campo de texto |
| SacDropdownField | sac_dropdown_field.dart | Dropdown personalizado |
| SacWidgets | sac_widgets.dart | Barrel file de widgets |
| CustomButton | custom_button.dart | Boton legacy |
| CustomTextField | custom_text_field.dart | Campo de texto legacy |
| ThemeToggle | theme/widgets/theme_toggle.dart | Toggle de tema claro/oscuro |

---

## Shared Layer

Ubicado en `lib/shared/`:

### Modelos compartidos
- `api_response.dart` - Modelo de respuesta API generica
- `paginated_response.dart` - Modelo de respuesta paginada
- `catalogs/` - Modelos de catalogos: ClubType, ActivityType, District, Church, Role, EcclesiasticalYear

### Data sources compartidos
- `catalogs_remote_data_source.dart` - Data source para catalogos del sistema

### Widgets compartidos
- `empty_state_widget.dart` - Estado vacio
- `error_display.dart` - Display de errores
- `loading_overlay.dart` - Overlay de carga

---

## Notas

1. **Dashboard no consume API**: `DashboardRemoteDataSourceImpl` construye datos desde metadata del usuario (pasada como parametro). No hace llamadas HTTP.
2. **Rutas placeholder**: `/club/:clubId` y `/honor/:honorId` usan `_PlaceholderScreen` (no implementados).
3. **Hardcoded values**: `/home/grouped-class` tiene `classId: 1` hardcodeado. `/home/activities` tiene `clubId: 1` hardcodeado.
4. **OAuth no implementado**: `signInWithGoogle()` y `signInWithApple()` lanzan excepcion "no disponible aun".
5. **Units sin data layer**: El feature `units` solo tiene presentation; no consume API. Probablemente obtiene datos del provider de members o club.
6. **Home sin data layer**: El feature `home` solo tiene presentation; actua como contenedor de otros widgets.
