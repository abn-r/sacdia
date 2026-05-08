# Feature: Recursos

**Estado**: IMPLEMENTADO
**Fecha**: 2026-03-26
**Módulo backend**: `ResourcesModule` (`src/resources/`)

---

## Descripción

El módulo de Recursos permite gestionar y distribuir materiales digitales (documentos, audios, imágenes, enlaces de video y texto) a los usuarios de la plataforma, con control de visibilidad basado en scope organizacional (DIA, unión, campo local).

El módulo incluye:
- CRUD de categorías configurables (`resource_categories`).
- CRUD de recursos con subida de archivos a Cloudflare R2 (`resources`).
- Endpoints orientados a la app móvil con visibilidad filtrada por el scope del usuario.
- Permisos RBAC independientes para recursos y categorías.

---

## Endpoints

### Admin CRUD — Recursos (`resources.controller.ts`)

| Method | Path | Permiso | Descripción |
|--------|------|---------|-------------|
| POST | `/api/v1/resources` | `resources:create` | Crear recurso con archivo adjunto (multipart/form-data, max 50 MB) |
| GET | `/api/v1/resources` | `resources:read` | Listar recursos con paginación y filtros |
| GET | `/api/v1/resources/:id` | `resources:read` | Obtener recurso por UUID con URL firmada |
| GET | `/api/v1/resources/:id/signed-url` | `resources:read` | Generar URL firmada fresca (TTL 1 hora) |
| PATCH | `/api/v1/resources/:id` | `resources:update` | Actualizar metadatos (sin reemplazar archivo) |
| DELETE | `/api/v1/resources/:id` | `resources:delete` | Soft delete (archivo en R2 no se elimina) |

### App — Recursos visibles (`resources-app.controller.ts`)

| Method | Path | Auth | Descripción |
|--------|------|------|-------------|
| GET | `/api/v1/resources/me` | JWT | Recursos visibles según scope y tipo de club del usuario |
| GET | `/api/v1/resources/me/:id` | JWT | Recurso individual visible con URL firmada |
| GET | `/api/v1/resources/me/:id/signed-url` | JWT | URL firmada fresca para descarga |

> Los endpoints `/me` no requieren permiso RBAC explícito; solo autenticación JWT. La visibilidad se resuelve dinámicamente desde el contexto del usuario (union_id, local_field_id).

### Admin CRUD — Categorías (`resource-categories.controller.ts`)

| Method | Path | Permiso | Descripción |
|--------|------|---------|-------------|
| POST | `/api/v1/resource-categories` | `resource_categories:create` | Crear categoría |
| GET | `/api/v1/resource-categories` | `resource_categories:read` | Listar categorías activas |
| GET | `/api/v1/resource-categories/:id` | `resource_categories:read` | Obtener categoría por ID |
| PATCH | `/api/v1/resource-categories/:id` | `resource_categories:update` | Actualizar categoría |
| DELETE | `/api/v1/resource-categories/:id` | `resource_categories:delete` | Soft delete (falla si la categoría tiene recursos activos) |

**Total: 14 endpoints** (6 admin recursos + 3 app + 5 categorías)

---

## Tipos de Recurso

| Tipo | Descripción | Archivo requerido |
|------|-------------|-------------------|
| `document` | PDF, Word u otro documento | Si |
| `audio` | Archivo de audio (MP3, WAV, etc.) | Si |
| `image` | Imagen (JPG, PNG, etc.) | Si |
| `video_link` | Enlace externo a video (YouTube, Vimeo, etc.) | No (usa `external_url`) |
| `text` | Contenido de texto plano | No (usa `content`) |

---

## Scoping y Visibilidad

El campo `scope_level` controla quién puede ver el recurso:

| scope_level | Visible para | scope_id apunta a |
|-------------|-------------|-------------------|
| `system` | Todos los usuarios autenticados (DIA) | NULL |
| `union` | Usuarios de la unión y campos locales bajo ella | `union_id` |
| `local_field` | Usuarios del campo local específico | `local_field_id` |

La visibilidad es **cascading**: un recurso de scope `union` lo ven todos los campos locales de esa unión.

---

## Permisos RBAC

8 permisos nuevos registrados en el sistema:

| Permiso | Descripción |
|---------|-------------|
| `resources:create` | Crear recursos |
| `resources:read` | Ver recursos (admin) |
| `resources:update` | Actualizar metadatos de recursos |
| `resources:delete` | Eliminar recursos (soft delete) |
| `resource_categories:create` | Crear categorías |
| `resource_categories:read` | Ver categorías |
| `resource_categories:update` | Actualizar categorías |
| `resource_categories:delete` | Eliminar categorías (soft delete) |

---

## Storage

- **Bucket**: `RESOURCES_FILES` en Cloudflare R2.
- **URLs firmadas**: TTL de 1 hora. Se generan on-demand en `GET /resources/:id` y en el endpoint `/signed-url`.
- **Soft delete**: el archivo en R2 **no se elimina** al desactivar un recurso. Se mantiene para auditoría y posible reactivación.
- **Limite de archivo**: 50 MB por upload.

---

## Decisiones de Diseño

### 1. Categorías configurables (no enum)
Las categorías se gestionan como tabla (`resource_categories`) en lugar de un enum fijo. Esto permite que administradores del sistema agreguen categorías nuevas sin deployar código.

### 2. Visibilidad en cascada con scope_level
En lugar de una tabla de permisos por recurso, se usa un campo `scope_level` + `scope_id`. El servicio resuelve la visibilidad consultando el contexto del usuario (su `union_id`, `local_field_id`) y filtrando recursivamente. Esto simplifica las consultas y es suficiente para la jerarquía actual (DIA > Unión > Campo Local).

### 3. URLs firmadas con TTL corto
Los archivos en R2 no son públicos. Se generan URLs pre-firmadas con 1 hora de vigencia para cada acceso. Esto evita distribución no autorizada de materiales.

### 4. video_link como tipo nativo
En lugar de obligar a subir un archivo, el tipo `video_link` acepta una URL externa (`external_url`). Esto permite referenciar contenido en YouTube, Vimeo u otras plataformas sin duplicar el archivo.

### 5. Controladores separados admin vs app
`ResourcesController` (admin) requiere permisos RBAC explícitos. `ResourcesAppController` (app) solo requiere JWT y resuelve visibilidad por contexto. Se registra primero el controlador app para que `/resources/me` no sea capturado por el param `:id` del controlador admin.

---

## Tablas de Base de Datos

- `resource_categories` — Catálogo de categorías
- `resources` — Recursos con metadatos y referencia al archivo en R2

Ver definición completa en `docs/database/SCHEMA-REFERENCE.md` — Módulo: Resources.

---

## Implementación por Capa

| Capa | Estado | Detalle |
|------|--------|---------|
| Backend (NestJS) | IMPLEMENTADO | `ResourcesModule`, `ResourceCategoriesController`, `ResourcesController`, `ResourcesAppController` |
| Admin (Next.js) | IMPLEMENTADO | Página CRUD categorías + página gestión de recursos |
| App (Flutter) | IMPLEMENTADO | Clean Architecture completa (datasource, repository, use cases, bloc, screens) |
