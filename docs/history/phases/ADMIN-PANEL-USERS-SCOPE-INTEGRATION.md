# Guía de Integración Admin Panel
## Módulo: Usuarios Administrativos con Scope por Rol

**Fecha**: 2026-02-18  
**Backend objetivo**: `sacdia-backend` (`/api/v1/admin/users`)  
**Documento canónico de endpoints**: `docs/02-API/ENDPOINTS-LIVE-REFERENCE.md`

---

## 1) Objetivo
Implementar en el panel administrativo el listado y detalle de usuarios usando los nuevos endpoints con control de alcance por rol (`super_admin`, `admin`, `coordinator`) definido en backend.

Esta guía está pensada para implementación directa en frontend (UI + data layer + manejo de errores + QA).

---

## 2) Contrato Backend (real)

### 2.1 Endpoints
- `GET /api/v1/admin/users`
- `GET /api/v1/admin/users/:userId`

### 2.2 Autenticación y autorización
- Auth: `Authorization: Bearer <token>`
- Guard backend: `JwtAuthGuard + GlobalRolesGuard`
- Roles permitidos:
- `super_admin`
- `admin`
- `coordinator`

### 2.3 Scope aplicado por backend
- `super_admin` => scope `ALL`
- `admin` => scope `UNION` si tiene `union_id`; si no, `LOCAL_FIELD` si tiene `local_field_id`; si no tiene ninguno => `403`
- `coordinator` => scope `LOCAL_FIELD` (requiere `local_field_id`); si falta => `403`

Importante: el backend SIEMPRE aplica el scope. Los filtros enviados desde UI son intersección sobre ese scope, no ampliación.

---

## 3) Request/Response para frontend

### 3.1 `GET /api/v1/admin/users`

#### Query params soportados
- `search` (string)
- `role` (string)
- `active` (boolean: `true|false`)
- `unionId` (number)
- `localFieldId` (number)
- `page` (number, default 1)
- `limit` (number, default 20, max 100)

#### Response esperada (shape)
```json
{
  "status": "success",
  "data": {
    "data": [
      {
        "user_id": "uuid",
        "email": "user@example.com",
        "name": "Juan",
        "paternal_last_name": "Perez",
        "maternal_last_name": "Lopez",
        "full_name": "Juan Perez Lopez",
        "active": true,
        "access_app": true,
        "access_panel": false,
        "country": { "country_id": 1, "name": "México" },
        "union": { "union_id": 7, "name": "UM" },
        "local_field": { "local_field_id": 11, "union_id": 7, "name": "Campo Norte" },
        "roles": ["user"],
        "post_registration": {
          "complete": true,
          "profile_picture_complete": true,
          "personal_info_complete": true,
          "club_selection_complete": true
        },
        "created_at": "2026-02-18T00:00:00.000Z"
      }
    ],
    "meta": {
      "page": 1,
      "limit": 20,
      "total": 1,
      "totalPages": 1,
      "hasNextPage": false,
      "hasPreviousPage": false,
      "scope": {
        "type": "UNION",
        "roles": ["admin"],
        "union_id": 7,
        "local_field_id": null
      }
    }
  }
}
```

### 3.2 `GET /api/v1/admin/users/:userId`

#### Response esperada (shape)
```json
{
  "status": "success",
  "data": {
    "user_id": "uuid",
    "email": "user@example.com",
    "name": "Juan",
    "paternal_last_name": "Perez",
    "maternal_last_name": "Lopez",
    "full_name": "Juan Perez Lopez",
    "active": true,
    "access_app": true,
    "access_panel": false,
    "country": { "country_id": 1, "name": "México" },
    "union": { "union_id": 7, "name": "UM" },
    "local_field": { "local_field_id": 11, "union_id": 7, "name": "Campo Norte" },
    "roles": ["user"],
    "gender": "M",
    "birthday": "2010-10-01T00:00:00.000Z",
    "blood": "A_POSITIVE",
    "baptism": false,
    "baptism_date": null,
    "user_image": null,
    "modified_at": "2026-02-18T00:00:00.000Z",
    "classes": [],
    "club_assignments": [],
    "emergency_contacts": [],
    "legal_representative": null,
    "scope": {
      "type": "UNION",
      "roles": ["admin"],
      "union_id": 7,
      "local_field_id": null
    }
  }
}
```

---

## 4) Errores que debe manejar el panel
- `401 Unauthorized`
- token inválido/expirado
- acción UI: logout + redirect login

- `403 Forbidden`
- usuario sin rol global permitido, o rol permitido pero sin scope configurado (`admin/coordinator`)
- acción UI: pantalla de acceso denegado con mensaje de configuración de alcance

- `404 Not Found` en detalle
- usuario fuera del alcance del actor o inexistente
- acción UI: estado “No encontrado o fuera de alcance”

- `429 Too Many Requests`
- rate limiting global backend
- acción UI: retry con backoff corto + mensaje no bloqueante

---

## 5) Diseño funcional recomendado (panel)

### 5.1 Página de listado `/admin/users`
- Tabla con columnas:
- Nombre completo
- Email
- Rol(es)
- País / Unión / Campo local
- Estado (`active`)
- Acceso (`access_app`, `access_panel`)
- Estado post-registro
- Fecha de creación

- Filtros UI:
- `search` (debounce 300-500ms)
- `role`
- `active`
- `unionId`
- `localFieldId`
- paginación `page/limit`

- UX de scope:
- mostrar badge visible con `meta.scope.type` (`ALL`, `UNION`, `LOCAL_FIELD`)
- si scope es `UNION`, bloquear edición de unión fuera de la del actor
- si scope es `LOCAL_FIELD`, bloquear selector de unión y fijar campo local

### 5.2 Página de detalle `/admin/users/:userId`
- Header con identidad base + roles
- bloques:
- perfil personal
- geografía
- clases
- asignaciones de club
- contactos de emergencia
- representante legal

- mostrar badge de scope retornado por backend (`data.scope`)

---

## 6) Integración técnica frontend

### 6.1 Tipos mínimos (TypeScript)
```ts
export type ScopeType = 'ALL' | 'UNION' | 'LOCAL_FIELD';

export interface ScopeMeta {
  type: ScopeType;
  roles: string[];
  union_id: number | null;
  local_field_id: number | null;
}

export interface AdminUsersListQuery {
  search?: string;
  role?: string;
  active?: boolean;
  unionId?: number;
  localFieldId?: number;
  page?: number;
  limit?: number;
}
```

### 6.2 Cliente API sugerido
```ts
// GET /api/v1/admin/users
await api.get('/admin/users', { params: query });

// GET /api/v1/admin/users/:userId
await api.get(`/admin/users/${userId}`);
```

### 6.3 Serialización de query
- enviar booleanos como `true|false`
- enviar `unionId/localFieldId/page/limit` como números
- no enviar params vacíos (`undefined`, `''`, `null`)

### 6.4 Cache y estado
- sugerido: React Query/SWR
- query key list: `['admin-users', query]`
- query key detail: `['admin-user', userId]`
- invalidación al cambiar filtros/paginación

---

## 7) Reglas de UI por rol del actor

Usar `/api/v1/auth/me` para contexto inicial del actor (roles + `union_id` + `local_field_id`) y confirmar luego con `meta.scope` devuelto por `/admin/users`.

- Si actor es `super_admin`:
- habilitar filtros de unión y campo local
- puede navegar global

- Si actor es `admin` con `union_id`:
- fijar unión por defecto a su `union_id`
- permitir elegir `localFieldId` dentro de su unión
- no permitir unión externa

- Si actor es `admin` con `local_field_id` (sin unión):
- fijar campo local
- ocultar/fijar filtros superiores

- Si actor es `coordinator`:
- fijar `local_field_id`
- listar únicamente su campo

Nota: si backend devuelve `403` por configuración incompleta, mostrar mensaje de soporte interno (no intentar bypass desde UI).

---

## 8) Checklist de implementación

- Crear servicio API `adminUsersApi` con list + detail
- Crear página listado con filtros + tabla + paginación
- Crear página detalle con secciones de datos extendidos
- Mostrar badge de scope en listado y detalle
- Implementar manejo de errores 401/403/404/429
- Integrar con permisos del panel para mostrar menú “Usuarios” solo a roles válidos
- Agregar tests unitarios de serialización query + estados UI de error
- Agregar tests e2e frontend para escenarios de scope (super_admin, admin unión, coordinator)

---

## 9) Casos QA mínimos (obligatorios)
- Super admin ve usuarios de distintas uniones/campos
- Admin con unión solo ve su unión
- Admin con unión + filtro `localFieldId` fuera de unión no expande alcance
- Coordinator solo ve su campo local
- Coordinator sin `local_field_id` recibe `403` y UI informa configuración faltante
- Detalle de usuario fuera de alcance retorna `404`

---

## 10) Mensajería recomendada en UI
- `403`: “Tu rol no tiene alcance configurado para consultar usuarios. Contacta a un super_admin.”
- `404` en detalle: “Usuario no encontrado o fuera de tu alcance.”
- `429`: “Demasiadas solicitudes. Reintentando…”

---

## 11) Referencias internas
- Backend controller: `sacdia-backend/src/admin/admin-users.controller.ts`
- Backend service: `sacdia-backend/src/admin/admin-users.service.ts`
- DTO query: `sacdia-backend/src/admin/dto/users.dto.ts`
- E2E backend: `sacdia-backend/test/admin-users-scope.e2e-spec.ts`
- Contrato canónico: `docs/02-API/ENDPOINTS-LIVE-REFERENCE.md`
