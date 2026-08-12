# Handoff: Configurable Certifications Engine — Admin API Contract

- **Fecha:** 2026-08-11
- **Branch backend:** `feat/configurable-certifications`
- **Alcance:** contrato real (endpoints/DTOs/permisos/errores/estados) que `sacdia-admin` debe consumir para el editor administrativo de certificaciones configurables (Fase 6 / Task 13 del plan base).
- **Fuente:** inspección directa de `sacdia-backend/src/certifications/**` en la rama indicada (no se documenta lo teórico del plan base si divergió).

## Own review tray note

Esta feature **no** usa la bandeja de revisión propia (`evidence-review`/review tray) de otras fases de certificaciones (revisión de evidencias de participantes). El alcance de este handoff es exclusivamente el **motor de definición** (crear/editar/publicar la plantilla de una certificación), consumido por `AdminCertificationsController`. La revisión de evidencias enviadas por usuarios inscritos vive en otro controlador (`certifications.controller.ts` + servicios de revisión) y no se toca en este documento ni en la UI resultante.

---

## 1. Endpoints reales (`AdminCertificationsController`)

Base path: `/api/v1/admin/certifications` (prefijo global `api` + versión URI `v1`, ver `src/main.ts`).

Guard stack: `JwtAuthGuard`, `PermissionsGuard` + `@AuthorizationResource({ type: 'global' })` (no hay scoping por club/unión: es un recurso global de plataforma).

| Método | Path | Permiso | Servicio | Body (DTO) | Respuesta (forma) |
|---|---|---|---|---|---|
| `POST` | `/admin/certifications` | `certifications:configure` | `createCertification` | `CreateCertificationDto` | `{ certification, version }` |
| `POST` | `/admin/certifications/:certificationId/versions` | `certifications:configure` | `createDraftVersion` | — | `certification_versions` row (status `DRAFT`) |
| `POST` | `/admin/certifications/:certificationId/versions/:versionId/clone` | `certifications:configure` | `cloneVersion` | — | `certification_versions` row (status `DRAFT`); **no incluye** módulos/reglas en la respuesta (ver §6) |
| `PATCH` | `/admin/certifications/:certificationId/versions/:versionId` | `certifications:configure` | `updateVersionMetadata` | `UpsertCertificationVersionDto` | `certification_versions` row actualizado |
| `PATCH` | `/admin/certifications/:certificationId/versions/:versionId/eligibility-rules` | `certifications:configure` | `replaceEligibilityRules` | `UpsertEligibilityRulesDto` | `certification_eligibility_rules[]` (reemplazo completo, ordenado por `sort_order`) |
| `PATCH` | `/admin/certifications/:certificationId/versions/:versionId/tree` | `certifications:configure` | `replaceModulesTree` | `UpsertCertificationTreeDto` | `certification_modules[]` con `certification_sections[].certification_requirement_components[]` anidados (reemplazo completo, ordenado por `sort_order`) |
| `POST` | `/admin/certifications/:certificationId/versions/:versionId/publish` | `certifications:publish` | `publishVersion` | — | `certification_versions` row (status `PUBLISHED`) |
| `DELETE` | `/admin/certifications/:certificationId/versions/:versionId/publish` | `certifications:publish` | `retireVersion` | — | `certification_versions` row (status `RETIRED`) |

**No existen respuestas envueltas en `{ data: ... }`**: no hay `TransformInterceptor`/`ClassSerializerInterceptor` global registrado para este módulo (`src/main.ts` solo registra `AuditInterceptor` y, condicionalmente, `SentryInterceptor`). El body de éxito es el objeto/arreglo crudo devuelto por el servicio.

### 1.1 GAP CRÍTICO — No hay endpoints de lectura admin

`AdminCertificationsController` **solo expone mutaciones** (`POST`/`PATCH`/`DELETE`). No existe:

- `GET /admin/certifications` (listar certificaciones con sus versiones y estados DRAFT/PUBLISHED/RETIRED)
- `GET /admin/certifications/:certificationId/versions` (listar versiones de una certificación)
- `GET /admin/certifications/:certificationId/versions/:versionId` (detalle completo de una versión: árbol + reglas de elegibilidad)

El único endpoint de lectura disponible es el público `GET /certifications/certifications/:id` (`certifications.controller.ts`), que devuelve la certificación con sus **módulos y secciones actuales** pero:
- No expone `certification_version_id`, `status`, ni metadatos de versión (título propio de versión, duración, fechas de publicación).
- No expone `certification_eligibility_rules`.
- No expone `certification_requirement_components` (solo módulos/secciones).
- No permite distinguir una versión DRAFT de una PUBLISHED — el público solo ve lo que sea que el backend decida mostrar (normalmente la versión activa/publicada).

**Consecuencia para la UI admin:** no es posible cargar una versión DRAFT existente para reanudar su edición después de refrescar la página, ni mostrar el contenido de una versión recién clonada (el `clone` devuelve solo el stub de la nueva versión, sin su árbol/reglas copiados). La UI implementada en `sacdia-admin` documenta y mitiga esta limitación operando con estado en memoria durante la sesión de edición (ver `sacdia-admin/CLAUDE.md` / comentarios en el editor). **Se requiere trabajo de backend adicional** (fuera de este handoff) para exponer `GET /admin/certifications` y `GET /admin/certifications/:id/versions/:versionId` antes de soportar edición persistente multi-sesión.

---

## 2. DTOs reales

### 2.1 `CreateCertificationDto` (`src/certifications/dto/admin/create-certification.dto.ts`)

```ts
{
  name: string;          // requerido, string no vacío
  description?: string;  // opcional
}
```

### 2.2 `UpsertCertificationVersionDto` (`upsert-certification-version.dto.ts`)

```ts
{
  title?: string;
  description?: string;
  min_duration_months?: number;
  max_duration_months?: number;
}
```

Todos los campos son opcionales (PATCH parcial): solo se actualizan los presentes en el body.

### 2.3 `UpsertEligibilityRulesDto` (`upsert-eligibility-rules.dto.ts`)

```ts
{
  rules: UpsertEligibilityRuleDto[];
}

UpsertEligibilityRuleDto = {
  rule_type: 'MIN_AGE' | 'BAPTIZED' | 'INVESTED_CLASS' | 'ACTIVE_CLUB_TYPE' | 'ACTIVE_ROLE';
  configuration?: Record<string, unknown>;
  class_id?: number;      // FK, requerido solo si rule_type === 'INVESTED_CLASS'
  club_type_id?: number;  // FK, requerido solo si rule_type === 'ACTIVE_CLUB_TYPE'
  role_id?: string;       // UUID, requerido solo si rule_type === 'ACTIVE_ROLE'
  sort_order?: number;    // default: índice del arreglo
}
```

Es un **reemplazo total**: el servicio borra todas las reglas existentes de la versión y crea las enviadas (`DELETE` + `INSERT` transaccional). Enviar `rules: []` deja la versión sin reglas de elegibilidad.

**Validación de `configuration` por `rule_type`** (`certification-configuration.parsers.ts`, `parseEligibilityRuleConfiguration`):

| `rule_type` | Claves permitidas en `configuration` | Reglas |
|---|---|---|
| `MIN_AGE` | `min_age` | `min_age` debe ser entero ≥ 0 |
| `BAPTIZED` | (ninguna) | `configuration` debe ser `{}` u omitirse |
| `INVESTED_CLASS` | (ninguna) | requiere `class_id` (FK) |
| `ACTIVE_CLUB_TYPE` | (ninguna) | requiere `club_type_id` (FK) |
| `ACTIVE_ROLE` | (ninguna) | requiere `role_id` (FK, UUID) |

**Exclusividad de FKs** (`parseEligibilityRuleInput`): solo el FK requerido por el `rule_type` puede estar presente; enviar cualquier otro FK (`class_id`/`club_type_id`/`role_id`) cuando no corresponde lanza `400 BadRequestException` (mensaje plano, no `AppException` — sin `code` en el body, ver §4).

### 2.4 `UpsertCertificationTreeDto` (`upsert-certification-tree.dto.ts`)

```ts
{
  modules: UpsertModuleDto[];
}

UpsertModuleDto = {
  name: string;               // requerido, maxLength 255
  description?: string;
  sort_order?: number;        // default: índice del arreglo
  sections: UpsertSectionDto[];
}

UpsertSectionDto = {
  name: string;                // requerido, maxLength 255
  description?: string;
  instructions?: string;
  sort_order?: number;         // default: índice del arreglo
  required?: boolean;          // default: true
  components: UpsertComponentDto[];
}

UpsertComponentDto = {
  component_type: 'TEXT_RESPONSE' | 'FILE_EVIDENCE' | 'LINKED_HONOR' | 'LINKED_ACTIVITY' | 'ATTESTATION' | 'AUTO_VALIDATION';
  label: string;                // requerido, no vacío, maxLength 255
  instructions?: string;
  configuration?: Record<string, unknown>;
  sort_order?: number;          // default: índice del arreglo
  required?: boolean;           // default: true
  honor_id?: number;            // FK, requerido solo si component_type === 'LINKED_HONOR'
  activity_type_id?: number;    // FK, requerido solo si component_type === 'LINKED_ACTIVITY'
}
```

También es **reemplazo total**: borra todos los `certification_modules`/`certification_sections` de la versión (cascada manual: primero `certification_sections`, luego `certification_modules`) y recrea el árbol completo enviado. Enviar `modules: []` deja la versión sin estructura.

**Validación de `configuration` por `component_type`** (`parseComponentConfiguration`):

| `component_type` | Claves permitidas | Reglas |
|---|---|---|
| `TEXT_RESPONSE` | `min_length`, `max_length` | ambos opcionales, números ≥ 0; si ambos presentes, `max_length >= min_length` |
| `FILE_EVIDENCE` | `max_files`, `allowed_mime_types` | `max_files` entero ≥ 1 (opcional); `allowed_mime_types` arreglo de strings (opcional) |
| `LINKED_HONOR` | (ninguna) | requiere `honor_id` (FK) |
| `LINKED_ACTIVITY` | (ninguna) | requiere `activity_type_id` (FK) |
| `ATTESTATION` | `statement` | **requerida**, string no vacío |
| `AUTO_VALIDATION` | `criteria` | **requerida**, string no vacío |

**Exclusividad de FKs**: igual que en reglas de elegibilidad — `honor_id` solo permitido en `LINKED_HONOR`, `activity_type_id` solo en `LINKED_ACTIVITY`; cualquier otra combinación lanza `400`.

**Nota de validación de forma:** estos errores de `configuration`/FK provienen de `BadRequestException` **vanilla de NestJS** (no `AppException`), por lo que el body de error no trae `code` (ver formato "vanilla" en §4). El mensaje sí es descriptivo en texto plano (p. ej. `component "ATTESTATION": statement is required`).

---

## 3. Estados de versión y máquina de estados

`certification_versions.status`: `'DRAFT' | 'PUBLISHED' | 'RETIRED'` (enum Prisma `certification_version_status_enum`, ver `certification-definition.types.ts`).

### 3.1 Inmutabilidad — regla dura

`assertVersionMutable(status)` (`domain/certification-state-machine.ts`):

```ts
if (status !== 'DRAFT') {
  throw new AppConflictException(ErrorCode.CERT_VERSION_IMMUTABLE); // 409
}
```

Se invoca en **todas** las mutaciones de contenido de una versión: `updateVersionMetadata`, `replaceEligibilityRules`, `replaceModulesTree`, y dentro de `publishVersion` (antes de aplicar `assertPublishable`). **Una versión `PUBLISHED` o `RETIRED` nunca puede editarse** — ni metadatos, ni reglas, ni árbol. La única vía para "editar" contenido de una versión publicada es **clonarla** (crea una nueva versión `DRAFT` con `version_number` incrementado) y editar el clon.

### 3.2 Transiciones válidas

```
DRAFT ──publish──▶ PUBLISHED ──retire──▶ RETIRED
  │                    │
  └─── (mutaciones) ───┘ (ninguna mutación permitida desde aquí en adelante)
```

- `createCertification`: crea `certification` + primera `certification_versions` en `DRAFT` (`version_number = 1`), con `title = name` de la certificación.
- `createDraftVersion(certificationId)`: crea una nueva versión `DRAFT` con `version_number = max(existente) + 1`. No copia contenido (versión vacía).
- `cloneVersion(certificationId, versionId)`: la versión origen debe existir y **no puede estar en `DRAFT`** (`source.status === 'DRAFT'` → `400 CERT_VERSION_NOT_PUBLISHED`; en la práctica esto significa que solo se clona desde `PUBLISHED` o `RETIRED`). Copia metadatos (`title`, `description`, duraciones), reglas de elegibilidad y árbol completo (módulos → secciones → componentes) a la nueva versión `DRAFT` (`version_number` incrementado). La respuesta HTTP de este endpoint **solo devuelve la fila de la nueva versión**, no el árbol/reglas copiados (ver GAP §1.1).
- `publishVersion(certificationId, versionId, actorUserId)`: valida `assertVersionMutable` (debe ser `DRAFT`) y `assertPublishable` (criterio de publicación, ver §3.3). Si existe una versión `PUBLISHED` previa de la misma certificación, la retira automáticamente (`status = RETIRED`, `retired_at = now`) en la misma transacción antes de marcar la nueva como `PUBLISHED` (`published_at = now`, `published_by_id = actorUserId`). **Solo puede existir una versión `PUBLISHED` por certificación a la vez.**
- `retireVersion(certificationId, versionId)`: requiere `status === 'PUBLISHED'` (si no, `400 CERT_VERSION_NOT_PUBLISHED`). Marca `RETIRED` + `retired_at`. No aplica `assertVersionMutable` (tiene su propia guarda de estado).

### 3.3 Criterio de publicación (`assertPublishable`)

Antes de marcar una versión como `PUBLISHED`, el servicio exige (todas obligatorias, en este orden, la primera que falle corta con `400 CERT_REQUIREMENT_INCOMPLETE`):

1. Al menos **una** regla de elegibilidad (`certification_eligibility_rules.length > 0`) → si falta: `{ reason: 'missing_eligibility_rules' }`.
2. Al menos **un** módulo (`certification_modules.length > 0`) → si falta: `{ reason: 'missing_modules' }`.
3. Cada módulo debe tener **al menos una sección** → si falta: `{ reason: 'module_without_sections', moduleId }`.
4. Cada sección debe tener **al menos un componente** → si falta: `{ reason: 'section_without_components', sectionId }`.

La UI admin debe usar este criterio para el estado del diálogo de confirmación de publicación (deshabilitar/advertir si la versión en memoria no cumple aún los 4 puntos, aunque la validación autoritativa siempre ocurre en el backend al hacer `POST .../publish`).

---

## 4. Permisos

Definidos vía `@RequirePermissions(...)` + `PermissionsGuard` + `@AuthorizationResource({ type: 'global' })` (recurso global, sin scoping de club/territorio):

| Permiso | Usado en |
|---|---|
| `certifications:configure` | Crear certificación, crear versión draft, clonar, actualizar metadatos, reemplazar reglas de elegibilidad, reemplazar árbol |
| `certifications:publish` | Publicar versión, retirar versión |

Confirmado en `src/certifications/controllers/admin-certifications.controller.spec.ts` (tests de permisos por endpoint). Ambos permisos son de módulo nuevo — **no existían previamente** en `sacdia-admin/src/lib/auth/permissions.ts`; se agregan como parte de este trabajo (`CERTIFICATIONS_CONFIGURE`, `CERTIFICATIONS_PUBLISH`).

Un usuario con solo `certifications:configure` puede armar todo el contenido de una versión (metadatos, reglas, árbol) pero **no puede publicarla ni retirarla** — necesita que alguien con `certifications:publish` ejecute esa acción. La UI debe reflejar esta separación (botón "Publicar"/"Retirar" gated por `certifications:publish`; el resto del editor gated por `certifications:configure`).

---

## 5. Errores

### 5.1 Errores de dominio (`AppException`, con `code`)

Formato de body (`HttpExceptionFilter`):

```json
{
  "status": "error",
  "statusCode": 409,
  "code": "CERT_VERSION_IMMUTABLE",
  "message": "<mensaje traducido vía i18n>",
  "details": { "...": "solo fuera de producción" },
  "timestamp": "2026-08-11T00:00:00.000Z",
  "path": "/api/v1/admin/certifications/1/versions/2/tree"
}
```

Códigos relevantes para el editor admin (`src/common/errors/error-codes.ts`), con el HTTP status real emitido por el servicio:

| Código | HTTP | Cuándo | Origen |
|---|---|---|---|
| `CERT_NOT_FOUND` | 404 | Certificación o versión inexistente (`getCertificationOrThrow`, `getVersionOrThrow`, `cloneVersion`, `publishVersion`) | `AppNotFoundException` |
| `CERT_VERSION_IMMUTABLE` | 409 | Intento de mutar (`updateVersionMetadata`/`replaceEligibilityRules`/`replaceModulesTree`/`publishVersion`) una versión que no está en `DRAFT` | `AppConflictException` (`assertVersionMutable`) |
| `CERT_VERSION_NOT_PUBLISHED` | 400 | `retireVersion` sobre versión que no es `PUBLISHED`; `cloneVersion` sobre versión en `DRAFT` | `AppBadRequestException` |
| `CERT_REQUIREMENT_INCOMPLETE` | 400 | `publishVersion` sin cumplir criterio de publicación (§3.3); `details.reason` indica cuál | `AppBadRequestException` |

Otros códigos `CERT_*` existen (`CERT_ALREADY_ENROLLED`, `CERT_ELIGIBILITY_REQUIRED`, `CERT_ENROLLMENT_NOT_FOUND`, `CERT_SECTION_INVALID`, `CERT_REQUIREMENT_LOCKED`, `CERT_INVALID_TRANSITION`, `CERT_EVIDENCE_INVALID_TYPE`, `CERT_EVIDENCE_TOO_LARGE`, `CERT_REVIEW_SCOPE_FORBIDDEN`, `CERT_CLOSEOUT_INCOMPLETE`, `CERT_CONCURRENT_UPDATE`, `CERT_LEGACY_ENDPOINT_DEPRECATED`) pero pertenecen al flujo de inscripción/revisión de participantes, no al editor admin de definiciones.

### 5.2 Errores de validación "vanilla" (sin `code`)

Los `BadRequestException` lanzados directamente por `certification-configuration.parsers.ts` (configuración inválida por tipo de componente/regla, FKs mal puestos, `label` vacío) **no son `AppException`** — el filtro los trata por la rama "vanilla" y el body **no incluye `code`**, solo `message` (string plano) y, en desarrollo, `details`. El cliente admin (`extractMessage` en `src/lib/api/client.ts`) ya maneja esto correctamente (usa `message` como fallback), así que no requiere cambios adicionales, pero **la UI no puede branchear por `code` para estos casos** — debe mostrar el `message` tal cual (en inglés, generado por el backend; no está i18n-izado). Se recomienda que la UI valide client-side las mismas reglas de §2.3/§2.4 antes de enviar, para minimizar la exposición de estos mensajes en inglés al usuario final.

Los errores de validación de `class-validator` a nivel de DTO (p. ej. `name` vacío en `CreateCertificationDto`, `rule_type` no es un valor del enum) siguen el mismo formato vanilla (`ValidationPipe` global produce `message: string[]`).

---

## 6. Resumen de gaps y decisiones tomadas en la UI (`sacdia-admin`)

1. **No hay lectura admin de versiones (§1.1).** La UI opera con un "workbench" en memoria por certificación durante la sesión: al crear una certificación, crear un draft, o guardar reglas/árbol, se usa la respuesta de la propia mutación (que sí devuelve el contenido actualizado) para mantener el estado visible. Cerrar y reabrir la página, o clonar una versión, no permite recuperar el contenido existente hasta que el backend exponga los `GET` faltantes. La UI muestra un aviso explícito de esta limitación en el flujo de clonado y al reabrir el panel.
2. **Recomendación de endpoints a agregar (fuera de este handoff, a proponer en el repo backend en un commit separado):**
   - `GET /admin/certifications?status=&page=&limit=` — listado con conteo de versiones por estado.
   - `GET /admin/certifications/:certificationId/versions` — listado de versiones (metadatos únicamente).
   - `GET /admin/certifications/:certificationId/versions/:versionId` — detalle completo (árbol + reglas) para poblar el editor al reanudar edición o revisar un clon.
3. **No se modificó el backend** como parte de esta tarea (regla explícita del Step 2). Este documento sirve de base para un ticket de seguimiento.

---

## Commit sugerido

```
docs(certifications): add admin handoff for configurable engine
```

(No aplicado — el commit lo realiza el proceso padre.)
