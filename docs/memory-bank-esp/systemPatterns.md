# Patrones del Sistema de la Aplicación SACDIA

## Arquitectura del Sistema
La aplicación SACDIA apunta a un enfoque de Arquitectura Limpia, aunque la implementación varía entre módulos:
- **Capa de Presentación**: Widgets de Flutter (Pantallas, widgets personalizados). Ubicados en `features/*/presentation/screens` y `features/*/presentation/widgets` (o `features/*/widgets`).
- **Capa de Lógica de Negocio**: BLoC/Cubit para la gestión del estado. Ubicados en `features/*/bloc` o `features/*/cubit`.
- **Capa de Datos**: 
    - Repositorios (`features/*/repository`) abstraen el acceso a datos.
    - Servicios (`features/*/services`) a veces actúan como una fachada sobre los repositorios o agrupan llamadas a la API relacionadas (por ejemplo, `UserService`).
- **Capa de Dominio**: Modelos/Entidades (`features/*/models`) representan estructuras de datos.
- **Capa Core** (`lib/core`): Contiene componentes compartidos como el router, cliente HTTP, constantes, widgets base y potencialmente Blocs/Servicios principales (como `CatalogsBloc`, `AuthEventService`).

## Decisiones Técnicas Clave
1. **Gestión del Estado**: Mezcla de `flutter_bloc` (existente) y `Cubit` (planeado para nuevas características). Se usa `equatable` para comparar estados/eventos.
2. **Navegación**: `go_router` para enrutamiento declarativo, incluyendo redirección basada en autenticación y potencialmente `ShellRoute` para el diseño principal.
3. **Interacción con el Backend**: 
   * Cliente centralizado `ApiClient` (usando `dio`) en `core/http` con interceptores robustos.
   * Gestión automática de tokens JWT con renovación preventiva.
   * Manejo global de errores de autenticación integrado con `AuthEventService`.
   * Reintentos automáticos de solicitudes con tokens renovados.
   * Cierre de sesión automático para errores de autenticación irrecuperables.
4. **Autenticación**: Supabase Auth maneja la creación de usuarios (vía API NestJS para registro), inicio de sesión, restablecimiento de contraseña y gestión de sesiones. `AuthRepository` interactúa con Supabase y la API NestJS (endpoints `/auth`).
5. **Persistencia de Datos (Local)**: 
    * `shared_preferences` usado por `ThemeRepository` para almacenar preferencias de tema.
    * Se introdujo `PreferencesService` (`lib/core/services/preferences_service.dart`) para gestionar el almacenamiento y recuperación local de información relacionada con el club usando `shared_preferences`. Esto incluye `clubId`, IDs específicos de tipo de club (`clubAdvId`, `clubPathfId`, `clubGmId`), y el `clubTypeSelect` por defecto.
6. **Inyección de Dependencias**: Implementado a través de `get_it`. Todos los servicios, repositorios, blocs y cubits se registran en un contenedor central en `lib/core/di/injection_container.dart` y se acceden mediante `GetIt.I<T>()`.
7. **Manejo de Imágenes**: `image_picker` para selección, `image_cropper` para recorte, `flutter_image_compress` para optimización antes de la carga (probablemente a Supabase Storage vía API NestJS en `PostRegisterRepository`).

## Patrones de Diseño en Uso
1. **Patrón Repositorio**: Usado para abstraer fuentes de datos (API, Supabase Auth) - por ejemplo, `AuthRepository`, `UserRepository`, `PostRegisterRepository`, `ThemeRepository`, `CatalogsRepository`.
2. **Patrón BLoC/Cubit**: Para gestionar el estado de la UI y la lógica de negocio.
3. **Patrón Fachada**: `UserService` actúa como una fachada sobre los endpoints de la API relacionados con detalles del usuario (alergias, enfermedades, etc.).
4. **Patrón Singleton**: Aplicado a servicios y repositorios a través de `get_it.registerSingleton<T>()` para garantizar una única instancia compartida. Los blocs y cubits se implementan como lazySingleton para que solo se instancien cuando se necesiten.
5. **Patrón Constructor**: La UI declarativa de Flutter depende en gran medida de este.
6. **Patrón Observador**: `BlocListener`, `BlocBuilder`, `GoRouterRefreshStream` escuchan cambios de estado.

## Relaciones entre Componentes (Ejemplos)
- `LoginScreen` -> `AuthBloc` -> `AuthRepository` -> (SupabaseClient, API NestJS vía Dio)
- `PostRegisterScreen` -> `StepperContent` -> (`PhotoUploadStep`, `PersonalInfoStep`, `ClubInfoStep`) -> `PostRegisterBloc` -> (`PostRegisterRepository`, `AuthRepository`, `CatalogsBloc`, `AuthBloc`) -> (API NestJS vía Dio)
- `ProfileScreen` -> (`UserBloc`, `UserClubsCubit`, `UserClassesCubit`, `UserRolesCubit`) -> (`UserRepository`, `UserService`) -> (API NestJS vía Dio)
- Widgets Globales (`AuthEventListener`) <-> Servicios Core (`AuthEventService`) <-> Interceptor del Cliente HTTP

## Estrategia de Pruebas (Planeada/Inferida de las Dependencias de Desarrollo)
- **Pruebas Unitarias**: Para Blocs/Cubits usando `bloc_test` y `mocktail` para simular repositorios/servicios.
- **Pruebas de Widgets**: Para componentes de UI usando `flutter_test`.
- **Pruebas de Integración**: Recomendadas para interacciones con la API (nivel de módulo).