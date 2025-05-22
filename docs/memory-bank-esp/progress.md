# Progreso de la Aplicación SACDIA

## Lo Que Funciona
- **Configuración Principal**: Inicialización del proyecto, configuración de Flutter, dependencias, activos.
- **Base de Arquitectura**: Estructura basada en características (`core`, `features`), uso de BLoC/Cubit, Repositorios.
- **Autenticación**: Inicio de sesión con correo/contraseña, Registro (vía API), Olvidé Contraseña, Cerrar Sesión. Gestión del estado de autenticación y enrutamiento basado en el estado de autenticación.
- **Post-Registro**: Flujo de múltiples pasos (Foto, Información Personal, Selección de Club) es funcional, incluyendo interacciones con la API para guardar datos y cargar catálogos.
- **Perfil de Usuario (Parcial)**: Carga y visualización de información básica del perfil, club, rol, clase, estado de bautismo/investidura. Gestión granular del estado para Clases, Alergias y Enfermedades (vía Cubits).
- **Pantalla de Inicio**: Estructura básica del tablero, visualización de menú basado en roles.
- **Componentes Principales**: Cliente HTTP (`ApiClient`), Constantes, Router (`go_router`), Gestión de Temas.
- **UI Básica**: Varias pantallas implementadas (`Login`, `Register`, `PostRegister`, `Profile`, `Home`, etc.) con estilos personalizados.
- **Especialidades/Honores**: Sistema completo de gestión de honores implementado, incluyendo:
  - Pantalla de selección de especialidades con categorías y funcionalidad de búsqueda (`AddHonorScreen`)
  - Pantalla detallada para el registro de especialidades (`AddUserHonorScreen`)
  - Funcionalidad para agregar/tomar fotos para certificados y evidencias
  - Gestión de imágenes (agregar, eliminar, previsualizar)
  - Validación y diálogo de confirmación para el registro
  - Integración con `UserHonorsCubit` para la gestión del estado
  - Soporte para recuperar imágenes de certificados y evidencias desde el almacenamiento Supabase (bucket "users-honors")
  - Firma de URL y caché para carga eficiente de imágenes
  - Actualizado modelo `UserHonor` para manejar el nuevo formato de respuesta API con objetos `ImageData`
  - Mejorada la visualización de imágenes en el diálogo de detalles de especialidad con URLs firmadas
  - Añadida pantalla dedicada `UserHonorDetailScreen` con visor de imágenes a pantalla completa para certificados e imágenes de evidencia
- **Persistencia de Datos del Club**:
  - Se implementó `PreferencesService` para almacenar identificadores clave del club (`clubId`, `clubAdvId`, `clubPathfId`, `clubGmId`) y el tipo de club seleccionado por defecto (`clubTypeSelect` = 2) en `shared_preferences`.
  - Se integró este mecanismo de guardado en `UserClubsCubit` tras la recuperación exitosa de los datos del club.

## Lo Que Falta por Construir
1. **Características Principales**: 
    * `main_layout` (ShellRoute con MotionTabBar y Navegación).
    * Funcionalidad del módulo `activities`.
    * Funcionalidad de `profile/ConfigurationScreen`.
    * Característica de Actualización del Perfil.
    * Gestión de Contactos de Emergencia (UI/Cubits necesarios).
    * Conectar la selección de Tipo de Club en Inicio a la gestión del estado.
2. **Refinamientos de Módulos**: 
    * Abordar TODOs/problemas potenciales identificados durante el análisis (manejo de errores, retroalimentación UX, configuración de navegación, etc.).
    * Implementar Cubits de Usuario faltantes (`EmergencyContacts`).
    * Integrar la gestión de Alergias/Enfermedades/Contactos en `UserPersonalInfoScreen`. *En proceso*
    * Refinar la lógica de rol/club/clase si múltiples son posibles por usuario(por definir).
3. **Pruebas**: Implementar pruebas Unitarias, de Widget y de Integración comprensivas.
4. **Mejoras del Cliente API**: Implementar inyección robusta de JWT, actualización de token y manejo global de errores de autenticación (integración de `AuthEventService`).
5. **Pantallas Detalladas de Características**: Implementar pantallas navegadas desde el menú de Inicio.

## Estado Actual
- **Proyecto**: Post-configuración inicial, características principales parcialmente implementadas.
- **Arquitectura**: Fundación establecida, necesita refactorización de DI y aplicación consistente de patrones.
- **Módulos Principales (Auth, PostRegister, User, Profile, Home)**: Parcialmente funcionales, requieren completación y refinamiento.
- **Especialidades (Honor)**: Completamente implementado el flujo de registro de especialidades.
- **Otros Módulos (MainLayout, Activities, Club)**: Estructura existe, implementación pendiente.
- **Pruebas**: Infraestructura (dependencias) presente, implementación pendiente.
- **Documentación**: Banco de Memoria actualizado basado en el análisis actual.

## Problemas Conocidos
- Uso/inconsistencia en la aplicación de capas de Arquitectura Limpia en algunas áreas.
- El manejo de errores puede mejorarse (mensajes más específicos, manejo global de autenticación).
- Varias características clave aún no están implementadas (Actividades, Navegación del Layout Principal, Actualización del Perfil).
- La cobertura de pruebas es mínima/inexistente.
- Posibles problemas lógicos (por ejemplo, `_determineUserRole`, carga de `ProfileScreen`, lógica de `StepperControls`).

## Tareas Prioritarias

1. **Características Principales**: 
    * `main_layout` (ShellRoute con MotionTabBar y Navegación).
    * Funcionalidad del módulo `activities`.
    * Funcionalidad de `profile/ConfigurationScreen`.
    * Característica de Actualización del Perfil.
    * Gestión de Contactos de Emergencia (UI/Cubits necesarios).
    * Conectar la selección de Tipo de Club en Inicio a la gestión del estado.
2. **Refinamientos de Módulos**: 
    * Abordar TODOs/problemas potenciales identificados durante el análisis (manejo de errores, retroalimentación UX, configuración de navegación, etc.).
    * Implementar Cubits de Usuario faltantes (`EmergencyContacts`).
    * Integrar la gestión de Alergias/Enfermedades/Contactos en `UserPersonalInfoScreen`. *En proceso*
    * Refinar la lógica de rol/club/clase si múltiples son posibles por usuario(por definir).
3. **Pruebas**: Implementar pruebas Unitarias, de Widget y de Integración comprensivas.
4. **Pantallas Detalladas de Características**: Implementar pantallas navegadas desde el menú de Inicio.

## Progreso Reciente

1. **Implementación del Layout Principal**: Construir `ShellRoute` con `MotionTabBar` y conectar pantallas principales (Inicio, Actividades, Perfil).
2. **Módulo de Actividades**: Implementar funcionalidad principal para ver/gestionar actividades.
3. **Completación del Perfil**: Implementar Actualización del Perfil, pantalla de Configuración e integrar gestión de Alergias/Enfermedades/Contactos.
4. **Fundación de Pruebas**: Configurar bases de pruebas y escribir pruebas iniciales para flujos críticos (Auth, PostRegister).
5. **Cliente API Mejorado**: Implementar interceptores robustos para JWT, renovación automática de tokens y manejo global de errores de autenticación.
6. **Característica de Especialidades**: Implementación completa del flujo de registro de especialidades, incluyendo selección, detalle y gestión de imágenes.