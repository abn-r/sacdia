# Especialidades en módulos de clase

**Fecha**: 2026-08-28
**Estado**: APROBADO
**Alcance**: `sacdia-backend`, `sacdia-admin`, `sacdia-app`
**Dominio**: [clases-progresivas.md](../../features/clases-progresivas.md) + [honores.md](../../features/honores.md)

## 1. Objetivo

Una clase progresiva ya relaciona especialidades vía `class_honors` (nivel clase, informativo). Ahora cada relación puede anclarse a un **módulo**. El panel elige el módulo. La app muestra la especialidad **en ese módulo**, abre el PDF (`material_url`) y permite **inscribirse** con el flujo existente de `users_honors`.

No bloquea completar el módulo. No bloquea investidura. `REQUIRED` sigue siendo etiqueta.

## 2. Decisiones

1. Aditivo: columna `module_id` nullable en `class_honors`. Sin tabla nueva.
2. Informativo: no se toca `class_module_progress`, elegibilidad ni investidura.
3. Inscripción: reusar `POST /users/:userId/honors` y `honor_detail_view`. Sin enroll embebido nuevo.
4. `module_id` null = especialidad de la clase, aún sin módulo (filas actuales).
5. Borrar módulo → `ON DELETE SET NULL` (la relación sobrevive a nivel clase).
6. El módulo debe pertenecer a la misma `class_id`. Si no → `ADMIN_CLASS_MODULE_NOT_FOUND`.
7. Copy visible: **especialidad**. Contratos internos: `honor`.
8. Reusar `honors.material_url` público. No firmar URLs nuevas.
9. Unique actual `[class_id, honor_id, relation_type]` no se cambia.

## 3. Datos

`class_honors` (existente) + :

| Columna | Tipo | Notas |
| --- | --- | --- |
| `module_id` | `INT NULL FK class_modules` | `ON DELETE SET NULL`, `ON UPDATE NO ACTION` |

Índice: `@@index([module_id])`.

Relación Prisma: `class_modules.class_honors[]`.

Validación de escritura: `class_modules.class_id === class_honors.class_id` y módulo `active`.

## 4. API

### Público (sin ruta nueva de enroll)

`GET /api/v1/classes/:classId/honors` (Optional JWT) añade:

```json
{
  "class_honor_id": 1,
  "relation_type": "REQUIRED",
  "module_id": 12,
  "module_name": "Nudos y amarres",
  "honor": {
    "honor_id": 42,
    "name": "Nudos",
    "honor_image": "https://…",
    "material_url": "https://…/nudos.pdf",
    "honors_category_id": 3,
    "skill_level": 1
  },
  "user_status": "IN_PROGRESS"
}
```

- `module_id` / `module_name`: `null` si no hay módulo.
- `material_url` puede ser null.
- `user_status` igual que hoy.

`GET /api/v1/classes/:classId/modules` (y el detalle de clase que ya embebe módulos) incluye `honors[]` por módulo, misma forma compacta (`class_honor_id`, `relation_type`, `honor`, `user_status` si hay JWT).

### Admin

- `POST /api/v1/admin/classes/:classId/honors` body existente + `module_id?: number | null`. Omitir = null.
- `PATCH /api/v1/admin/classes/:classId/honors/:classHonorId` **nuevo**. Permiso `catalogs:update`. Body: `{ module_id?: number | null }` (null quita el módulo). Opcional en la misma llamada: no se cambia `relation_type` en esta fase.
- `GET` admin incluye `module_id` y `module` `{ module_id, name }` si existe.
- `DELETE` sin cambio de semántica (soft-delete).

Errores:

- Módulo inexistente, inactivo o de otra clase → `404 ADMIN_CLASS_MODULE_NOT_FOUND`.
- Duplicado activo → `409 ADMIN_CLASS_HONOR_DUPLICATE` (igual que hoy).

## 5. Admin

Detalle de clase (`ClassHonorsDialog`):

- Selector opcional de módulo (módulos activos de esa clase) + “Sin módulo”.
- Lista existente muestra el nombre del módulo o “Sin módulo”.
- Crear envía `module_id`. Mover: PATCH.

`ClassModuleTree`: bajo cada módulo, chips de especialidades asignadas (nombre). Sin segundo catálogo.

## 6. App

Fuente de lista: `GET /classes/:classId/honors` (ya usado).

- Carrusel de la clase (`_RecommendedHonorsSection`), encima de los módulos: todas las especialidades de `GET /classes/:classId/honors` (con o sin `module_id`).
- En cada módulo (progreso: agrupar por `module_id` vs `ClassModuleDetail.id`; catálogo: `honors[]` del GET modules): tarjeta imagen, nombre, tipo, PDF, CTA de inscripción. El encabezado colapsado indica cuántas especialidades tiene.

CTA:

- Hay `material_url` → “Ver material” → `SacPdfViewer.show`.
- Sin PDF → tarjeta sin ese CTA.
- `user_status` null → “Inscribirse” → `RouteNames.honorDetailPath` (flujo actual).
- Con estado → “Continuar” / badge de estado → mismo detalle.

No se llama enroll desde el módulo sin pasar por `honor_detail_view`.

i18n: `es`, `en`, `pt-BR`, `fr`.

## 7. Fuera de alcance

- Gate de módulo o investidura por `users_honors.validation_status`.
- Tabla `class_module_honors`.
- Cambiar unique de `class_honors`.
- Backfill obligatorio de `module_id` en filas existentes.
- Firmado nuevo de PDFs.
- Importador de especialidades de Aventureros (sigue creando filas sin módulo).

## 8. Criterios de aceptación

- Admin asigna una especialidad a un módulo de la misma clase, o la deja sin módulo.
- PATCH `module_id: null` la devuelve al nivel clase.
- GET público trae `material_url`, `module_id`, `module_name`.
- App: especialidad con módulo aparece en el módulo y también en el carrusel de la clase; sin módulo solo en el carrusel.
- App abre PDF y navega al flujo de inscripción existente.
- Completar secciones / investidura no consulta `class_honors`.
- Módulo de otra clase rechazado.
- Tests: create con módulo, create sin módulo, módulo ajeno, GET incluye material y módulo, PATCH quita módulo.
