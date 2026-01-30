# Guía de Implementación: Nuevo Sistema de Roles y Permisos para la Aplicación Móvil Flutter

## 1. Introducción

Este documento detalla la integración del nuevo sistema de roles y permisos del backend (NestJS con Prisma) en la aplicación móvil desarrollada en Flutter (utilizando Cubit/BLoC como gestores de estado). El propósito es habilitar una gestión de acceso granular y precisa, distinguiendo entre roles aplicables globalmente en el sistema y roles específicos asignados dentro de las diferentes instancias de club (Aventureros, Conquistadores, Guías Mayores).

## 2. Resumen de Cambios Clave en el Backend

La arquitectura de roles y permisos en el backend ha sido refactorizada para incorporar los siguientes conceptos fundamentales:

*   **Categorización de Roles (`Roles`):**
    *   Cada rol posee un campo `role_category` que lo clasifica como:
        *   `GLOBAL`: Aplica a todo el sistema (ej. "SuperAdmin", "Coordinador de Asociación").
        *   `CLUB`: Específico para una instancia de club (ej. "Director de Club de Aventureros", "Consejero de Unidad de Conquistadores").
*   **Estructura de Clubes e Instancias:**
    *   El modelo `clubs` actúa como un contenedor general para la información básica de un club.
    *   Las operaciones, datos específicos y la membresía detallada residen en tablas de "instancia de club": `club_adventurers`, `club_pathfinders`, `club_master_guild`. Cada una de estas instancias se vincula al `clubs` contenedor principal.
*   **Asignación de Roles de Club (`club_role_assignments`):**
    *   Este es el modelo central para los roles de club. Vincula:
        *   Un `users` (usuario).
        *   Un `roles` (que debe tener `role_category: 'CLUB'`).
        *   Una instancia de club específica (a través de `club_adv_id?`, `club_pathf_id?`, o `club_mg_id?` - solo uno de estos campos tendrá valor por asignación).
        *   Un `ecclesiastical_year` (año eclesiástico).
    *   Un usuario puede tener múltiples asignaciones de roles: en diferentes instancias de club, diferentes roles en la misma instancia, o el mismo rol en diferentes años eclesiásticos.
    *   Cada asignación tiene un estado `active`, y fechas `start_date` y `end_date` (opcional).
*   **Permisos (`permissions` y `role_permissions`):**
    *   Los permisos (`permissions`) definen acciones granulares en el sistema.
    *   Estos permisos se vinculan a los roles (`roles`) a través de la tabla `role_permissions`.
    *   La capacidad de un usuario para realizar una acción se deriva de la suma de todos los permisos asociados a todos sus roles activos (tanto `GLOBAL` como `CLUB`).
*   **Asignación de Roles Globales (`users_roles`):**
    *   Esta tabla continúa gestionando la asignación de roles de categoría `GLOBAL` a los usuarios.

## 3. Modelos de Datos Relevantes para la Aplicación Móvil

La aplicación móvil interactuará principalmente con las siguientes estructuras de datos (JSON), que recibirá de la API.

### 3.1. Modelo de Usuario (`User`) - Perfil Detallado con Roles

Este modelo se obtendría típicamente después del inicio de sesión o al consultar el perfil del usuario.

**Ejemplo de estructura JSON:**
```json
{
  "user_id": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
  "name": "Juan",
  "paternal_last_name": "Pérez",
  "mother_last_name": "Gómez",
  "email": "juan.perez@example.com",
  "active": true,
  "user_image": "https://ruta.com/imagen.jpg",
  // ... otros campos del perfil del usuario ...
  "global_roles": [ // Roles asignados directamente al usuario con categoría GLOBAL
    {
      "role_id": "r1o2l3e4-g5l6-7890-1234-globalabcdef",
      "role_name": "Coordinador General",
      "role_category": "GLOBAL",
      "permissions": [ // Opcional: si el backend decide anidar permisos directamente
        {
          "permission_id": "p1e2r3m4-a5b6-7890-1234-verreportes",
          "permission_name": "reports.view.global",
          "description": "Permite ver reportes globales"
        }
      ]
    }
  ],
  "club_role_assignments": [ // Asignaciones de roles específicos a instancias de club
    {
      "assignment_id": "as1g2n3m-e4n5-t678-9012-clubabcdef",
      "role": { // Información del rol asignado
        "role_id": "r1o2l3e4-c5l6-7890-1234-clubdirector",
        "role_name": "Director Club Aventureros",
        "role_category": "CLUB"
        // "permissions": [ ... ] // Opcional: permisos específicos del rol de club
      },
      "ecclesiastical_year": { // Año eclesiástico de la asignación
        "year_id": 1,
        "start_date": "2024-01-01",
        "end_date": "2024-12-31"
      },
      // Identificador de la instancia de club específica:
      // Solo uno de los siguientes tres bloques estará presente y con valor.
      "club_adventurers": {
        "club_adv_id": 10,
        // "main_club_name": "Club Aventureros Los Valientes" // Nombre del club contenedor
      },
      "club_pathfinders": null,
      "club_master_guild": null,
      // Fin de identificadores de instancia
      "active": true, // Si la asignación está activa
      "start_date": "2024-03-01",
      "end_date": null // Puede ser null si no tiene fecha de fin
    },
    {
      "assignment_id": "as1g2n3m-e4n5-t678-9012-clubdefghi",
      "role": {
        "role_id": "r1o2l3e4-c5l6-7890-1234-conquistador",
        "role_name": "Consejero Unidad Conquistadores",
        "role_category": "CLUB"
      },
      "ecclesiastical_year": {
        "year_id": 1,
        "start_date": "2024-01-01",
        "end_date": "2024-12-31"
      },
      "club_adventurers": null,
      "club_pathfinders": {
        "club_pathf_id": 15,
        // "main_club_name": "Club Conquistadores Centinelas"
      },
      "club_master_guild": null,
      "active": true,
      "start_date": "2024-03-01",
      "end_date": null
    }
  ]
}
```

### 3.2. Modelo de Rol (`Role`)

Utilizado cuando se listan roles disponibles.

**Ejemplo de estructura JSON:**
```json
{
  "role_id": "uuid-string-del-rol",
  "role_name": "Nombre Descriptivo del Rol",
  "role_category": "GLOBAL" | "CLUB", // GLOBAL o CLUB
  "active": true
  // "permissions": [ Permiso... ] // Opcional, si se envían anidados al listar roles
}
```

### 3.3. Modelo de Permiso (`Permission`)

Representa una acción específica que un rol puede permitir.

**Ejemplo de estructura JSON:**
```json
{
  "permission_id": "uuid-string-del-permiso",
  "permission_name": "modulo.entidad.accion", // Ej: "activities.create", "users.edit.profile"
  "description": "Descripción legible del permiso"
}
```

### 3.4. Modelo de Asignación de Rol de Club (`ClubRoleAssignment`)

Esta es la estructura que se recibe al listar las asignaciones a través del endpoint `/club-role-assignments`. Es muy similar al objeto dentro del array `club_role_assignments` del Modelo de Usuario.

**Ejemplo de estructura JSON (para un solo elemento de la lista):**
```json
{
  "assignment_id": "as1g2n3m-e4n5-t678-9012-clubabcdef",
  "users": { // Usuario al que se asigna el rol
    "user_id": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
    "name": "Juan",
    "paternal_last_name": "Pérez",
    "email": "juan.perez@example.com"
  },
  "roles": { // Rol asignado
    "role_id": "r1o2l3e4-c5l6-7890-1234-clubdirector",
    "role_name": "Director Club Aventureros",
    "role_category": "CLUB"
  },
  "ecclesiastical_year": { // Año eclesiástico
    "year_id": 1,
    "start_date": "2024-01-01",
    "end_date": "2024-12-31"
  },
  // Instancia de Club (solo uno de estos campos tendrá datos):
  "club_adventurers": { "club_adv_id": 10 },
  "club_pathfinders": null,
  "club_master_guild": null,
  // ---
  "start_date": "2024-03-01",
  "end_date": null,
  "active": true,
  "created_at": "2024-03-01T10:00:00.000Z",
  "modified_at": "2024-03-01T10:00:00.000Z"
}
```

## 4. Endpoints de la API y su Consumo

Todos los endpoints descritos a continuación requieren un token JWT válido, el cual debe ser enviado en el header `Authorization` de la solicitud: `Authorization: Bearer <JWT_TOKEN>`.

### 4.1. Obtener Perfil del Usuario Autenticado (Incluyendo Roles y Asignaciones)

*   **Propósito:** Esencial para que la app conozca quién es el usuario y qué puede hacer. Se llama tras el login y potencialmente al iniciar la app si hay una sesión activa.
*   **Endpoint:** `GET /auth/profile` (o el endpoint actualmente definido para obtener el perfil).
*   **Puntos de Entrada (Parámetros):** Ninguno. El usuario se identifica por el token JWT.
*   **Puntos de Salida (Respuesta Éxito `200 OK`):**
    *   Un objeto JSON con la estructura definida en la sección `3.1. Modelo de Usuario (User)`.
*   **Respuestas de Error Comunes:**
    *   `401 Unauthorized`: Token no proporcionado, inválido o expirado.

### 4.2. Listar Todos los Roles Disponibles

*   **Propósito:** Útil para contextos administrativos dentro de la app (si los hubiere) o para mostrar listados de roles disponibles (ej. al asignar un rol).
*   **Endpoint:** `GET /roles`
*   **Puntos de Entrada (Query Parameters):**
    *   `page?: number` - Para paginación (ej. `1`).
    *   `limit?: number` - Cantidad de resultados por página (ej. `20`).
    *   `role_category?: 'GLOBAL' | 'CLUB'` - Para filtrar roles por su categoría.
    *   `active?: boolean` - Para filtrar por estado activo/inactivo.
    *   `role_name?: string` - Para buscar por nombre de rol.
*   **Puntos de Salida (Respuesta Éxito `200 OK`):**
    ```json
    {
      "data": [ // Array de objetos Role (ver sección 3.2)
        {
          "role_id": "uuid-rol-1",
          "role_name": "Director",
          "role_category": "CLUB",
          "active": true
        },
        // ... más roles
      ],
      "total": 50, // Total de roles que coinciden con el filtro
      "page": 1,
      "limit": 20,
      "totalPages": 3
    }
    ```
*   **Respuestas de Error Comunes:**
    *   `401 Unauthorized`.

### 4.3. Listar Asignaciones de Roles de Club

*   **Propósito:** Permite obtener un listado detallado de qué usuarios tienen qué roles en qué instancias de club y años eclesiásticos. Principalmente para vistas administrativas o perfiles muy detallados.
*   **Endpoint:** `GET /club-role-assignments`
*   **Puntos de Entrada (Query Parameters - `FindClubRoleAssignmentsQueryDto`):**
    *   `page?: number`
    *   `limit?: number`
    *   `user_id?: string` (UUID del usuario)
    *   `role_id?: string` (UUID del rol)
    *   `club_adv_id?: number` (ID de instancia Club Aventureros)
    *   `club_pathf_id?: number` (ID de instancia Club Conquistadores)
    *   `club_mg_id?: number` (ID de instancia Club Guías Mayores)
    *   `ecclesiastical_year_id?: number` (ID del año eclesiástico)
    *   `active?: boolean` (Estado de la asignación)
*   **Puntos de Salida (Respuesta Éxito `200 OK`):**
    ```json
    {
      "data": [ // Array de objetos ClubRoleAssignment (ver sección 3.4)
        // ...
      ],
      "total": 100,
      "page": 1,
      "limit": 10,
      "totalPages": 10
    }
    ```
*   **Respuestas de Error Comunes:**
    *   `401 Unauthorized`.
    *   `400 Bad Request`: Si los parámetros de filtro son inválidos.

### 4.4. Crear una Nueva Asignación de Rol de Club (Uso Administrativo)

*   **Propósito:** Generalmente utilizado desde un panel de administración, pero si la app móvil tuviera esta capacidad para ciertos usuarios (ej. un coordinador asignando directores), este sería el endpoint.
*   **Endpoint:** `POST /club-role-assignments`
*   **Puntos de Entrada (Request Body - `CreateClubRoleAssignmentDto`):**
    ```json
    {
      "user_id": "uuid-del-usuario-a-asignar", // Requerido
      "role_id": "uuid-del-rol-categoria-CLUB", // Requerido, debe ser un rol 'CLUB'
      // Proporcionar solo UNO de los siguientes tres:
      "club_adv_id": 10, // ID de instancia Club Aventureros
      // "club_pathf_id": null,
      // "club_mg_id": null,
      // ---
      "ecclesiastical_year_id": 3, // Requerido
      "start_date": "YYYY-MM-DD", // Requerido
      "end_date": "YYYY-MM-DD", // Opcional
      "active": true // Opcional, default: true
    }
    ```
*   **Puntos de Salida (Respuesta Éxito `201 Created`):**
    *   El objeto `ClubRoleAssignment` recién creado (estructura de la sección 3.4).
*   **Respuestas de Error Comunes:**
    *   `401 Unauthorized`.
    *   `403 Forbidden`: Si el usuario autenticado no tiene permiso para realizar esta acción.
    *   `400 Bad Request`: Datos de entrada inválidos (ej. rol no es 'CLUB', más de una instancia de club proporcionada, campos requeridos faltantes, formato de fecha incorrecto).
    *   `404 Not Found`: Si el `user_id`, `role_id`, `ecclesiastical_year_id` o la instancia de club especificada no existen.
    *   `409 Conflict`: Si ya existe una asignación activa idéntica para el mismo usuario, rol, instancia de club y año eclesiástico.

### 4.5. Actualizar una Asignación de Rol de Club (Uso Administrativo)

*   **Propósito:** Modificar una asignación existente.
*   **Endpoint:** `PATCH /club-role-assignments/{assignment_id}`
*   **Puntos de Entrada (Path Parameter):**
    *   `assignment_id: string` (UUID de la asignación a actualizar).
*   **Puntos de Entrada (Request Body - `UpdateClubRoleAssignmentDto`):**
    *   Contiene solo los campos que se desean modificar. Las validaciones son similares al DTO de creación.
    ```json
    {
      // Ejemplo: Cambiar el estado y la fecha de finalización
      "active": false,
      "end_date": "2024-10-31"
      // Ejemplo: Cambiar la instancia de club (desconectará la anterior automáticamente)
      // "club_pathf_id": 25
    }
    ```
*   **Puntos de Salida (Respuesta Éxito `200 OK`):**
    *   El objeto `ClubRoleAssignment` actualizado.
*   **Respuestas de Error Comunes:**
    *   `401 Unauthorized`, `403 Forbidden`, `400 Bad Request`, `404 Not Found` (si `assignment_id` no existe o una entidad relacionada en la actualización no se encuentra), `409 Conflict`.

### 4.6. Eliminar una Asignación de Rol de Club (Uso Administrativo)

*   **Propósito:** Remover una asignación de rol de club.
*   **Endpoint:** `DELETE /club-role-assignments/{assignment_id}`
*   **Puntos de Entrada (Path Parameter):**
    *   `assignment_id: string` (UUID de la asignación a eliminar).
*   **Puntos de Salida (Respuesta Éxito `200 OK` o `204 No Content`):**
    *   Generalmente un mensaje de confirmación o una respuesta vacía.
    ```json
    {
      "message": "Asignación de rol de club con ID ... eliminada exitosamente."
    }
    ```
*   **Respuestas de Error Comunes:**
    *   `401 Unauthorized`, `403 Forbidden`, `404 Not Found` (si `assignment_id` no existe).

## 5. Lógica de Uso y Consideraciones para la Aplicación Móvil (Flutter con Cubit/BLoC)

### 5.1. Flujo de Obtención Inicial y Almacenamiento de Datos del Usuario

1.  **Tras Login Exitoso / Inicio de App con Sesión Activa:**
    *   Invocar el endpoint `GET /auth/profile` (o equivalente).
    *   La respuesta (Modelo de Usuario, sección 3.1) contiene los `global_roles` y `club_role_assignments` del usuario.
2.  **Gestión de Estado (Ej. `AuthCubit` o `UserProfileCubit`):**
    *   Almacenar el objeto `User` completo en el estado de este Cubit/BLoC.
    *   Este estado se convierte en la fuente de verdad para los roles y permisos del usuario a través de la aplicación.
    *   El token JWT debe ser almacenado de forma segura (ej. `flutter_secure_storage`) y cargado por el `AuthCubit` al inicio.
3.  **Persistencia Local (Opcional):**
    *   Para mejorar la experiencia de usuario en inicios subsecuentes (offline-first parcial), se podría persistir una versión simplificada del perfil del usuario (sin datos sensibles, quizás solo IDs de roles y nombres) usando `sembast`, `hive` o `shared_preferences`. Sin embargo, siempre se debe intentar obtener la versión más reciente del backend al estar online.

### 5.2. Lógica para Determinar Permisos y Controlar Acceso en la UI

La estrategia principal es que **el backend ya aplique la seguridad y filtre los datos** según los permisos del usuario. Por ejemplo, si un usuario solicita una lista de actividades, el backend solo debería devolver aquellas que el usuario tiene permiso para ver.

Sin embargo, la UI móvil necesita su propia lógica para:
*   **Mostrar/Ocultar elementos de UI:** Botones, opciones de menú, secciones completas.
*   **Habilitar/Deshabilitar funcionalidad:** Un botón de "Crear" podría estar visible pero deshabilitado.

**Enfoques para la lógica de permisos en el móvil:**

1.  **Basado en Roles (Común y práctico):**
    *   El móvil conoce los roles del usuario a través del `UserProfileCubit`.
    *   Se implementan funciones o getters en el `UserProfileState` (o en clases helper) para verificar si el usuario posee ciertos roles o combinaciones de roles que habilitan una acción.
    *   **Ejemplo en Dart (conceptual, dentro de un `UserProfileState` o clase similar):**
        ```dart
        class UserProfile { // Asumiendo que tienes este modelo parseado
          final List<GlobalRole> globalRoles;
          final List<ClubRoleAssignment> clubRoleAssignments;
          // ... otros campos ...

          UserProfile({required this.globalRoles, required this.clubRoleAssignments});

          bool isSuperAdmin() {
            return globalRoles.any((role) => role.roleName == 'SuperAdmin');
          }

          bool hasGlobalRole(String roleName) {
            return globalRoles.any((role) => role.roleName == roleName);
          }

          // Verifica si el usuario tiene un rol específico activo en una instancia de club dada
          bool hasClubRoleInInstance({
            required String roleName,
            required String clubInstanceType, // 'adventurers', 'pathfinders', 'master_guild'
            required int clubInstanceId,
            int? ecclesiasticalYearId, // Opcional, para ser más específico
          }) {
            return clubRoleAssignments.any((assignment) {
              if (!assignment.active) return false;

              bool instanceMatch = false;
              if (clubInstanceType == 'adventurers' && assignment.clubAdventurers?.clubAdvId == clubInstanceId) {
                instanceMatch = true;
              } else if (clubInstanceType == 'pathfinders' && assignment.clubPathfinders?.clubPathfId == clubInstanceId) {
                instanceMatch = true;
              } else if (clubInstanceType == 'master_guild' && assignment.clubMasterGuild?.clubMgId == clubInstanceId) {
                instanceMatch = true;
              }

              bool yearMatch = ecclesiasticalYearId == null || assignment.ecclesiasticalYear.yearId == ecclesiasticalYearId;

              return assignment.role.roleName == roleName && instanceMatch && yearMatch;
            });
          }
        }
        ```
2.  **Permisos Explícitos (Si el backend los provee de forma consolidada):**
    *   Si el endpoint `/auth/profile` (o uno dedicado) devolviera una lista plana de `permission_name` que el usuario posee (derivados de todos sus roles), la verificación sería más directa:
        ```dart
        // Asumiendo que el UserProfile tiene una lista `List<String> effectivePermissions`
        bool canPerformAction(String permissionName) {
          return userProfile.effectivePermissions.contains(permissionName);
        }
        ```
    *   Esto simplifica la lógica en el móvil pero requiere más trabajo en el backend para calcular estos permisos efectivos.

### 5.3. Manejo del Contexto de Club Específico

*   **Navegación y Estado de Contexto:** Cuando un usuario navega a la sección de un club específico (ej. la vista del "Club de Aventureros Los Valientes"), la aplicación debe mantener el contexto de qué instancia de club se está visualizando (ej. `club_adv_id = 10`). Esto podría ser parte del estado de un BLoC/Cubit de la pantalla o una sección específica.
*   **Filtrado de Acciones:** La lógica de `hasClubRoleInInstance` (del ejemplo anterior) se usaría pasando el `clubInstanceType` y `clubInstanceId` del contexto actual para determinar si se muestran/habilitan botones de acción específicos para ESE club.
*   **Envío de IDs en Peticiones:** Al realizar operaciones que son específicas de una instancia de club (ej. crear una actividad para el Club de Aventureros X), el móvil DEBE incluir el identificador de esa instancia (`club_adv_id`, `club_pathf_id`, o `club_mg_id`) en el payload de la petición al backend.

### 5.4. Interacción con Cubits/BLoCs

*   **`AuthCubit / UserProfileCubit`:**
    *   Mantiene el estado del usuario autenticado, incluyendo sus roles (`global_roles`, `club_role_assignments`).
    *   Provee métodos/getters para consultar los roles y permisos (como los ejemplos en 5.2.1).
    *   Debe ser actualizado al hacer login/logout o al refrescar el perfil.
*   **Cubits/BLoCs de Funcionalidad (ej. `ActivityCubit`, `ClubDashboardCubit`, `MembersCubit`):**
    *   Pueden escuchar (`BlocListener`, `select`) al `UserProfileCubit` para acceder a la información de roles y permisos.
    *   Utilizan esta información para:
        *   Determinar si se deben realizar ciertas llamadas a la API.
        *   Adaptar los parámetros de las llamadas a la API (ej. enviar `club_instance_id` si la acción es contextual).
        *   Emitir estados que la UI usará para renderizar condicionalmente elementos.
    *   Ejemplo: Un `ActivityFormCubit` podría verificar `userProfileCubit.state.canCreateActivityInInstance(...)` antes de permitir la sumisión del formulario.

### 5.5. Actualización y Refresco de Roles/Permisos

*   Los roles de un usuario pueden cambiar en el backend por acciones administrativas.
*   La app móvil debería refrescar la información del perfil del usuario (`GET /auth/profile`):
    *   **Al inicio de la app:** Para asegurar datos frescos.
    *   **Tras ciertas acciones críticas:** Si una acción podría implicar un cambio de roles (poco común que sea iniciado desde el móvil, más bien desde un panel admin).
    *   **Navegación a secciones sensibles:** Antes de entrar a una sección donde los permisos son cruciales.
    *   **Mecanismo de "Pull to refresh"** en la pantalla de perfil del usuario.
*   No suele ser necesario un sistema de push en tiempo real para cambios de roles, a menos que la inmediatez sea absolutamente crítica.

## 6. Puntos Clave y Consideraciones Adicionales

*   **Nomenclatura de Permisos:** Si se opta por usar permisos explícitos, es vital una nomenclatura clara y consistente (ej. `recurso.subrecurso.accion` -> `club.activity.create`, `user.profile.edit`).
*   **Manejo Detallado de Errores HTTP:**
    *   `401 Unauthorized`: Redirigir a login.
    *   `403 Forbidden`: Mostrar un mensaje claro al usuario de que no tiene permiso para la acción o vista. No simplemente ocultar, sino informar si intenta acceder directamente.
    *   `404 Not Found`: Manejarlo adecuadamente (recurso no existe).
    *   `400 Bad Request`: Útil para errores de validación en formularios, mostrar mensajes específicos del backend si los provee.
*   **Experiencia de Usuario (UX):**
    *   Mostrar de forma transparente los roles del usuario en su perfil.
    *   Si el usuario está asociado a múltiples clubes/instancias con diferentes roles, la navegación y el cambio de contexto deben ser intuitivos.
    *   La UI debe ser reactiva a los permisos: no mostrar opciones que el usuario no puede usar o deshabilitarlas claramente.
*   **Pruebas Exhaustivas:** Probar diferentes combinaciones de roles (globales, de club, múltiples asignaciones) para asegurar que la lógica de permisos funciona correctamente en todas las capas de la app móvil.

Esta guía tiene como objetivo proporcionar una base sólida y detallada. El desarrollador Flutter deberá adaptar y refinar la implementación según las necesidades específicas de la UI/UX y las particularidades del proyecto. La comunicación continua con el equipo de backend será clave durante este proceso.