# Contexto Activo de la Aplicación SACDIA

## Enfoque de Trabajo Actual
- Documentar el estado actual del código base utilizando el Banco de Memoria.
- Identificar las características implementadas y las tareas pendientes por módulo y pantalla.
- Prepararse para el desarrollo subsiguiente basado en el análisis.

## Cambios Recientes (Resultados del Análisis)
- **Arquitectura**: Se identificó la estructura de Arquitectura Limpia (`core`, `features`), pero la Inyección de Dependencias (DI) es manual, y la gestión del estado utiliza tanto BLoC como Cubit.
- **Core**: Router, Constantes, Cliente HTTP, widgets compartidos (`AuthEventListener`, `InputTextWidget`), y gestión de Catálogos (`CatalogsBloc`) están implementados.
- **Auth**: Inicio de sesión (Supabase), Registro (API NestJS), Olvidé Contraseña (Supabase), Cerrar Sesión (Supabase) implementados. La lógica en BLOC maneja el estado posterior al registro.
- **Post-Register**: Proceso de múltiples pasos implementado utilizando `Stepper`, `PostRegisterBloc`, y `PostRegisterRepository`. Maneja la carga de fotos, información personal y selección de información del club. Comunica el fin de este proceso a a `AuthBloc`.
- **User**: `UserBloc` gestiona la carga/actualización básica del perfil. `UserService` proporciona métodos para datos detallados (alergias, enfermedades, contactos, clubes, clases, roles, entre otros). `UserAllergiesCubit` y `UserDiseasesCubit` implementados para la gestión granular del estado de estas listas.
- **Profile**: La pantalla principal del perfil (`ProfileScreen`) integra datos de `UserBloc` y varios Cubits (`UserClubsCubit`, `UserClassesCubit`, `UserRolesCubit`). Incluye navegación a detalles de información personal y configuración. La sección de especialidades y la actualización del perfil están pendientes.
- **Home**: La pantalla del tablero (`HomeScreen`) muestra opciones de menú basadas en roles. Integra el perfil del usuario y los datos del club. La UI para la selección del tipo de club existe, pero la lógica necesita conexión.
- **Otros Módulos**: Estructuras de `main_layout`, `activities`, `club`, `theme` existen, pero la funcionalidad necesita una revisión/implementación detallada.

1. **Inyección de Dependencias**: Se ha implementado un sistema de inyección de dependencias centralizado usando `get_it`:
   - Creación de un contenedor central en `lib/core/di/injection_container.dart`
   - Registro de todos los servicios, repositorios, blocs y cubits como singleton o lazySingleton
   - Eliminación de las instanciaciones manuales en `main.dart`
   - Actualización de los BlocProviders para usar instancias de `get_it`
   - Eliminación de registros duplicados en `profile_screen.dart`

2. **Cliente API Mejorado**: Se ha refactorizado y mejorado el cliente API con interceptores robustos:
   - Gestión avanzada de JWT con renovación automática preventiva de tokens
   - Integración completa con AuthEventService para manejo global de errores de autenticación
   - Implementación de mecanismo automático de cierre de sesión para errores irrecuperables
   - Mejora en los logs y depuración con opción configurable para logs detallados
   - Mejor manejo de errores específicos (401, 403, 400) con mensajes personalizados
   - Reintentos automáticos de solicitudes cuando se renueva el token
   - Registro del cliente en el contenedor de inyección de dependencias

3. **Función de Honores/Especialidades**: Implementación completa para la gestión de especialidades:
   - Pantallas para selección y registro de especialidades
   - Soporte para carga y visualización de certificados e imágenes de evidencia
   - Actualizado modelo `UserHonor` para manejar el nuevo formato de API con objetos `ImageData`
   - Implementada nueva clase `ImageData` que contiene campos `image` y `path` para cada imagen
   - Actualizado el manejo de URLs firmadas para certificados e imágenes de evidencia
   - Las imágenes ahora se obtienen desde el bucket "users-honors" en Supabase
   - Mejorado el diálogo de detalles de especialidad para mostrar imágenes con URLs firmadas
   - Implementado caché de URLs firmadas para mejorar el rendimiento
   - Las constantes para nombres de buckets se centralizaron en `constants.dart` para facilitar cambios futuros
   - Creada nueva pantalla `UserHonorDetailScreen` para mostrar detalles de especialidad con visor de imágenes a pantalla completa

4. **Almacenamiento de Preferencias del Club**: Se implementó el almacenamiento local para identificadores esenciales del club y una selección de tipo de club por defecto:
   - Se creó `PreferencesService` (`lib/core/services/preferences_service.dart`) para manejar operaciones de `shared_preferences` para los datos del club.
   - Se integró `PreferencesService` en `UserClubsCubit` para guardar `clubId`, `clubAdvId`, `clubPathfId`, `clubGmId`, y un `clubTypeSelect` por defecto (establecido en 2 para Conquistadores) tras la carga exitosa de los clubes del usuario.
   - `PreferencesService` se registró en `get_it` para acceso en toda la aplicación.

## Próximos Pasos (Basados en el Análisis)
1. ~~**Inyección de Dependencias**: Refactorizar toda la aplicación para usar `get_it` para gestionar Repositorios, Servicios, Blocs y Cubits.~~
2. **Layout Principal**: Implementar `main_layout` con `ShellRoute` y `MotionTabBar` para una navegación más fluida entre pantallas principales.
3. **Completar Características Principales**: 
    * Implementar `main_layout` (ShellRoute con MotionTabBar).
    * Implementar el módulo `activities` (Pantallas, Gestión de Estado, Llamadas a la API).
    * Implementar `profile/ConfigurationScreen`.
    * Implementar la característica de Actualización de Perfil.
    * ~~Implementar la sección de especialidades en `ProfileScreen` (requiere Cubit, métodos de Servicio, UI).~~
    * Conectar `ClubTypeSelector` en `HomeScreen` a `UserBloc`.
4. **Refinar Módulos Existentes**: 
    * Abordar los TODOs/problemas potenciales identificados en `auth`, `post_register`, `user`, `profile`, `home` (por ejemplo, manejo de errores, retroalimentación UI/UX, configuración de navegación).
    * Implementar los Cubits de Usuario restantes (`EmergencyContacts`, `Roles`, `Classes`).
    * Completar `profile/user_personal_info_screen` para integrar la gestión de alergias/enfermedades/contactos.
5. **Pruebas**: Implementar pruebas Unitarias, de Widget y de Integración en todos los módulos.
6. ~~**Cliente API**: Asegurarse de que `ApiClient` incluya una inyección robusta de tokens JWT, lógica de actualización y manejo global de errores (conectando `_handleAuthError` en `UserService` a `AuthEventService`).~~

## Decisiones Activas
1. **Gestión del Estado**: Continuar usando BLoC para las características existentes y Cubit para las nuevas.
2. ~~**Inyección de Dependencias**: Migrar a `get_it`.~~
3. **Arquitectura**: Mantener la estructura basada en características con `core` para elementos compartidos.
4. **Backend**: Continuar usando la combinación de API NestJS + Supabase Auth/DB.
5. **Especialidades**: Usar un flujo de dos pantallas para la selección y registro de especialidades, permitiendo una experiencia de usuario más enfocada en cada paso.

## Consideraciones Actuales
1. **Técnicas**:
   - Optimización del rendimiento
   - Organización del código
   - Estrategia de pruebas
   - Implementación de seguridad

2. **Producto**:
   - Priorización de características
   - Diseño de experiencia de usuario
   - Compatibilidad de plataforma
   - Estrategia de localización

3. **Desarrollo**:
   - Colaboración en equipo
   - Proceso de revisión de código
   - Estándares de documentación
   - Flujo de trabajo de control de versiones