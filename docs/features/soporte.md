# Soporte (reportes de problemas)

**Estado**: IMPLEMENTADO PARCIAL
**Verificado contra código**: 2026-10-04 (rama `development`)

## Descripcion de dominio

Desde la app, cualquier usuario autenticado puede enviar un reporte de problema o una sugerencia. El reporte guarda la categoría, el texto, datos del dispositivo y contexto de la app. El equipo administrativo y los responsables territoriales consultan los reportes de su ámbito y cambian su estado.

## Que existe (verificado contra codigo)

### Backend (`src/support/`)

| Método | Ruta (`/api/v1`) | Autorización |
|---|---|---|
| POST | `/support/reports` | `JwtAuthGuard` + `@SkipPermissions`; límite 5 por hora |
| GET | `/admin/support/reports` | `GlobalRolesGuard`: `admin`, `coordinator` |
| GET | `/admin/support/reports/:reportId` | `admin`, `coordinator` |
| PATCH | `/admin/support/reports/:reportId/status` | `admin`, `coordinator` |

`GlobalRoles('admin', 'coordinator')` admite, por alias del guard, `admin`, `assistant-admin`, `coordinator`, `zone-coordinator`, `general-coordinator`, `director-lf` y `assistant-lf`; `super-admin` pasa siempre.

Reglas verificadas en `support.service.ts` y DTOs:

- **Categorías**: `bug`, `feature_request`, `account`, `data_issue`, `performance`, `other`. Título hasta 120 caracteres y descripción hasta 2000. `device_info` es obligatorio; `user_context` es opcional.
- **Estados**: `open` (inicial), `in_progress`, `resolved`, `closed`. No hay máquina de estados: el PATCH acepta cualquiera de los cuatro.
- **Ámbito de lectura**: `admin`, `assistant-admin` y `super-admin` ven todo. `director-lf` y `assistant-lf` ven reportes de usuarios de su campo local (`users.local_field_id`). Los coordinadores ven reportes de usuarios con asignación activa en sus secciones coordinadas. Sin ámbito: `ADMIN_USER_SCOPE_MISSING`. Cualquier otro rol: `GUARD_PERMISSION_DENIED`.
- **Listado**: filtros `status`, `category`, `userId` y `search` (título, descripción, email y nombre del usuario, sin distinguir mayúsculas); paginado (`limit` máximo 100), orden por fecha descendente.
- Al crear, agrega un *breadcrumb* de Sentry; un fallo de Sentry no afecta la creación.

### App móvil (`sacdia-app/lib/features/support/`)

- `SupportView` (centro de ayuda), `FaqView`, `ContactView` y `ReportProblemView` (formulario que llama a `POST /support/reports`).

### Admin

- Sin pantalla: el panel no consume `/admin/support/reports`.

### Base de datos

- `support_reports`: `category`, `title`, `description`, `device_info` (JSON), `user_context` (JSON), `status` (texto, por defecto `open`). Índices por usuario y por `(status, created_at)`; índice GIN de trigramas sobre título y descripción (migración `20260818190000`). Borrado en cascada con el usuario.

## Gaps y pendientes

- No hay bandeja en el admin para los endpoints `/admin/support/reports`.
- El usuario no puede ver el estado de sus reportes ni recibe aviso cuando cambian.
- `status` es texto libre en base de datos; la validación vive solo en el DTO.
