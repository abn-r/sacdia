# Admin Config Gaps Roadmap

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cerrar los 19 huecos de configuración detectados en `docs/guides/FRESH-ENVIRONMENT-SETUP.md` (Parte 3) para que un ambiente nuevo se configure completo desde el admin, sin SQL manual.

**Architecture:** Cuatro olas de PRs encadenados (≤400 líneas cada uno, skill `chained-pr`). Ola 0 = datos y bugs de código sin UI. Ola 1 = endpoints que la UI necesita. Ola 2 = arreglos de pantallas existentes. Ola 3 = pantallas nuevas (checklist de configuración, hub reorganizado, inscripción anual). Cada PR es independiente y desplegable; las dependencias se marcan explícitas.

**Tech Stack:** NestJS 11 + Prisma 7 (backend, Jest), Next.js 16 + shadcn/ui + Vitest (admin). Permisos vía `@RequirePermissions` + screen catalog del admin.

**Cómo usar este documento:** es el roadmap. Cada PR de abajo se expande a un plan TDD detallado (pasos de 2-5 min con código) al momento de ejecutarlo. Aquí van: archivos exactos, enfoque, pruebas que deben existir, criterio de aceptación y tamaño estimado.

---

## Mapa de huecos → PR

| # hueco (guía §3) | Descripción corta | PR |
|---|---|---|
| 1 | Sin checklist de puesta en marcha | 3.1 |
| 2 | `system_config` solo PATCH, llaves sin sembrar | 0.1, 1.1, 2.2 |
| 3 | Territorio del usuario no editable | 1.2, 2.3 |
| 4 | Timezone de campo local sin captura | 2.1 |
| 5 | Config de seguros 403 para admin | 1.3, 2.4 |
| 6 | `club_enrollments` sin UI admin | 1.4, 3.3 |
| 7 | Primer super-admin solo seed/API | 0.3 |
| 8, 9 | Config regada; hub incompleto | 3.2 |
| 10 | Dos pantallas idénticas camporee config | 2.6 |
| 11 | Pago del campo en Seguros, no en Campo local | 2.6 |
| 12 | Redirects y duplicados en sidebar | 2.6 |
| 13 | Dos nociones de año actual sin aviso | 2.7 |
| 14 | `role_slot_limits` sin UI | 3.4 (diferido) |
| 15 | `honor_requirements` sin UI | diferido (fuera de alcance) |
| 16 | Tabs scoring unión/campo no montados | 2.5 |
| 17 | `/rbac/user-permissions` huérfano | 2.6 |
| 18 | Permisos `investiture_config:*` zombis en seed | 0.4 |
| 19 | Roles inexistentes en reportes | 0.2 |
| — | `classes` sin seed versionado | 0.5 (requiere decisión) |

---

## Ola 0 · Datos y bugs sin UI (backend, bajo riesgo)

Sin dependencias entre sí. Se pueden abrir en paralelo.

### PR 0.1 · Sembrar todas las llaves `system_config`

**Files:**
- Modify: `sacdia-backend/prisma/seeds/system-config.seed.sql`
- Create: `sacdia-backend/prisma/seeds/system-config.seed.spec.ts` (test de contrato: toda llave leída en `src/` está en el seed)

**Enfoque:** agregar al `INSERT ... ON CONFLICT DO UPDATE` las llaves que hoy solo existen como default en código. Valores = default actual del código para no cambiar comportamiento.

```sql
  ('membership.pending_timeout_days', '8', 'Días antes de expirar solicitudes de membresía pendientes', 'int'),
  ('ranking.finance_closing_deadline_day', '5', 'Día del mes siguiente considerado a tiempo para cierre financiero', 'int'),
  ('ranking.recalculation_enabled', 'true', 'Kill-switch del recálculo de rankings de club', 'boolean'),
  ('ranking.activities_registered_target', '12', 'Meta anual de actividades registradas para el score', 'int'),
  ('member_ranking.recalculation_enabled', 'true', 'Kill-switch del recálculo de rankings de miembros', 'boolean'),
  ('member_ranking.member_visibility', 'self_only', 'Visibilidad del ranking de miembros: self_only | all | hidden', 'string'),
  ('member_ranking.top_n', '5', 'Cantidad de miembros en el top del ranking', 'int'),
  ('reports.annual_auto_generate_enabled', 'false', 'Autogenerar informe anual', 'boolean'),
  ('reports.quarterly_auto_generate_enabled', 'false', 'Autogenerar informe trimestral', 'boolean'),
  ('reports.reminders_enabled', 'true', 'Recordatorios de informe mensual', 'boolean'),
  ('activity_reminder_minutes_before', '60', 'Minutos de anticipación del recordatorio de actividad', 'int'),
  ('field_payment_orders_v1', '[]', 'Campos locales con órdenes de pago habilitadas (array JSON de local_field_id)', 'json'),
  ('camporee_orders.expiry_days', '15', 'Días para expirar pedidos de camporee sin pago', 'int')
```

Quitar `investiture.min_monthly_reports` (llave muerta, sin lectura en `src/`). Verificar antes con `rg "min_monthly_reports" sacdia-backend/src` y también en `sacdia-app/lib` y `sacdia-admin/src`; si alguien la lee, conservarla.

**Test de contrato** (Jest, `prisma/seeds/system-config.seed.spec.ts`): parsear con regex todas las llaves `'[a-z_]+\.[a-z_.]+'` o constantes `*_KEY` usadas en `src/**/*.ts` (excluyendo spec) junto a `systemConfig`/`getConfig`/`getValue`, y asegurar que cada una esté en el SQL. Falla si aparece una llave nueva sin sembrar. Confirmar antes el nombre real del método del servicio con `graft skeleton sacdia-backend/src/system-config/system-config.service.ts`.

**Aceptación:** `psql -f` idempotente; `/dashboard/configuration/variables` muestra las 18 llaves; test de contrato verde.
**Tamaño:** ~80 líneas.

### PR 0.2 · Corregir nombres de rol inexistentes en reportes

**Files:**
- Modify: `sacdia-backend/src/member-of-month/member-of-month.service.ts:552,634`
- Modify: `sacdia-backend/src/quarterly-reports/quarterly-reports.service.ts:136-138`
- Modify: `sacdia-backend/src/monthly-reports/monthly-reports.service.ts:1373-1375`
- Modify: `sacdia-backend/src/annual-reports/annual-reports.service.ts:127-129`
- Create: `sacdia-backend/src/common/constants/club-board-roles.ts`
- Test: `sacdia-backend/src/common/constants/club-board-roles.spec.ts` + ajustar specs existentes de los 4 servicios

**Enfoque:** una constante única con los nombres canónicos sembrados (`prisma/seed.ts`) y usarla en los cuatro servicios.

```ts
// src/common/constants/club-board-roles.ts
/** Roles CLUB canónicos que forman la directiva. Fuente: prisma/seed.ts. */
export const CLUB_DIRECTOR_ROLE_NAMES = ['director', 'deputy-director'] as const;
export const CLUB_BOARD_ROLE_NAMES = [
  'director',
  'deputy-director',
  'secretary',
  'treasurer',
  'secretary-treasurer',
] as const;
```

Test de contrato: cada nombre de `CLUB_BOARD_ROLE_NAMES` aparece como `role_name:` literal en `prisma/seed.ts` con `role_category: 'CLUB'`. `CLUB_ROLE_ALIASES` de `club-roles.guard.ts` se queda (normaliza entrada externa, no consultas a DB).

**Aceptación:** reportes mensual/trimestral/anual y miembro del mes devuelven directiva con datos sembrados por `core.ts`.
**Tamaño:** ~60 líneas.

### PR 0.3 · Seed de admin seguro para producción

**Files:**
- Modify: `sacdia-backend/prisma/seed.ts:256-330`
- Modify: `sacdia-backend/.env.example` (nueva var)
- Modify: `sacdia-backend/prisma/seeds/README.md`

**Enfoque:**
- Contraseña del admin desde `SEED_ADMIN_PASSWORD`; si no está definida, no crear el admin y loguear que se use `bootstrap-admin`.
- Usuario de prueba `testuser.gm@sacdia.test`, clase `Guía Mayor - Nivel 1 (Seed)` y el año 2026 solo si `SEED_INCLUDE_TEST_FIXTURES=1`.
- El año eclesiástico de prueba ya no se crea por default; la guía indica crearlo desde el admin.

```ts
const adminPassword = process.env.SEED_ADMIN_PASSWORD;
if (!adminPassword) {
  console.log('⏭️  SEED_ADMIN_PASSWORD no definido: omito admin@sacdia.com. Usa POST /admin/rbac/bootstrap-admin.');
} else if (!existingAdmin) {
  const hashedPassword = await bcrypt.hash(adminPassword, 12);
  // ...resto igual
}
const includeFixtures = process.env.SEED_INCLUDE_TEST_FIXTURES === '1';
if (includeFixtures) { /* bloque test user + clase + año + enrollment */ }
```

**Aceptación:** `npx tsx prisma/seed.ts` sin env extra siembra solo catálogos; con ambas env reproduce el comportamiento actual (los e2e que dependen del test user deben setear `SEED_INCLUDE_TEST_FIXTURES=1`; revisar `.github/workflows/ci.yml`).
**Tamaño:** ~50 líneas.

### PR 0.4 · Limpiar permisos zombis `investiture_config:*`

**Files:**
- Modify: `sacdia-backend/prisma/seeds/permissions.seed.sql`, `role-permissions.seed.sql`
- Create: `sacdia-backend/prisma/migrations/<ts>_drop_investiture_config_permissions/migration.sql`

**Enfoque:** `rg "investiture_config:" sacdia-backend/src` debe devolver 0 decoradores (las rutas responden 410). Si es así: migración `DELETE FROM role_permissions WHERE permission_id IN (SELECT permission_id FROM permissions WHERE permission_name LIKE 'investiture_config:%'); DELETE FROM permissions WHERE permission_name LIKE 'investiture_config:%';` y quitar las 4 filas de los seeds. Si algún decorador sigue usándolo, cancelar este PR.

**Tamaño:** ~30 líneas.

### PR 0.5 · Seed versionado de `classes` (requiere decisión)

**Decisión previa del dueño:** hoy las clases solo entran por `import:legacy-catalogs` desde respaldos fuera del repo. Opciones con tradeoff:

- **A. Seed TS en repo** (`prisma/seeds/classes.seed.ts`, upsert por `name`): datos canónicos de las 6 clases Conquistadores, 6 Aventureros, GM, con `club_type` por nombre, `minimum_age`, `display_order`, `active: true`. Luego reescribir `docs/working/seed-*-modules-sections.sql` para resolver `class_id` por `name` en vez de hardcodear 7-12. Pro: ambiente nuevo reproducible. Contra: ~600 líneas de datos a mantener; los módulos/secciones son ~3 archivos SQL grandes.
- **B. Documentar el importador** y versionar los respaldos en un bucket privado. Pro: cero código. Contra: sigue dependiendo de archivos externos.

Recomendación: **A** para clases (pocas filas, estables), **B** para módulos/secciones por ahora. Sin la decisión no se ejecuta.

---

## Ola 1 · Endpoints que la UI necesita (backend)

### PR 1.1 · `POST /system-config` (crear llave)

**Files:**
- Modify: `sacdia-backend/src/system-config/system-config.controller.ts` (nuevo `@Post()`)
- Modify: `sacdia-backend/src/system-config/system-config.service.ts` (`create`)
- Modify: `sacdia-backend/src/system-config/dto/*.ts` (`CreateSystemConfigDto`: `config_key` regex `^[a-z_]+(\.[a-z_]+)+$`, `config_value` string, `config_type` enum `string|int|number|boolean|json`, `description`)
- Modify: `sacdia-backend/src/common/errors/error-codes.ts` (`SYSTEM_CONFIG_ALREADY_EXISTS`) + `src/i18n/{es,en}/errors.json`
- Modify: `sacdia-backend/prisma/seeds/permissions.seed.sql` + `role-permissions.seed.sql` (`system_config:create` → `super-admin`) + migración de datos equivalente
- Test: `system-config.controller.spec.ts`, `system-config.service.spec.ts`

**Enfoque:** mismo guard que el `PATCH` existente (leer qué `@RequirePermissions` y `@GlobalRoles` usa y replicar) más el nuevo permiso. Conflicto 409 si la llave existe. Validar `config_value` contra `config_type` (reusar el validador que ya usa el PATCH; si no existe, crear `assertValueMatchesType(type, value)` en el service y usarlo en ambos).

**Aceptación:** 201 con body; 409 duplicado; 400 tipo/valor inconsistente; 403 sin permiso.
**Tamaño:** ~150 líneas.

### PR 1.2 · Editar territorio del usuario desde admin

**Files:**
- Modify: `sacdia-backend/src/admin/dto/users.dto.ts:337` (`UpdateAdminUserDto` + `country_id?`, `union_id?`, `local_field_id?` como `Int | null`)
- Modify: `sacdia-backend/src/admin/admin-users.service.ts:709` (`updateUser`)
- Test: `admin-users.service.spec.ts`

**Reglas en `updateUser`:**
1. Si viene `local_field_id`, cargar `local_fields.union_id` y exigir que coincida con `union_id` resultante (el enviado o el actual). Si no, 400 `ADMIN_USER_TERRITORY_MISMATCH` (nuevo error code).
2. Si viene `union_id` sin `local_field_id` y el usuario tenía campo de otra unión → poner `local_field_id = null`.
3. Autorización: quien edita debe poder administrar tanto el territorio origen como el destino. Reusar la lógica de alcance que ya aplica `createUser` para validar `union_id`/`local_field_id` (leer `admin-users.service.ts:960-1010` y extraer helper `assertTerritoryWithinActorScope(actor, { unionId, localFieldId })` si no existe).
4. Al final `authorizationContext.invalidateUserAuthorizationCache(userId)` (el scope sale de estas columnas).
5. Efecto colateral documentado: trigger `trg_users_drop_district_pastors_on_field_change` desactiva asignaciones de pastor al cambiar de campo. Mencionarlo en la respuesta (`warnings: ['district_pastor_assignments_dropped']` si había filas activas).

**Aceptación:** PATCH con `local_field_id` de otra unión → 400; cambio válido actualiza columnas e invalida cache; actor LF no puede mover usuarios fuera de su campo.
**Tamaño:** ~180 líneas.

### PR 1.3 · Config de seguros para admin con campo explícito

**Files:**
- Modify: `sacdia-backend/src/insurance/insurance-config-scope.ts`
- Modify: `sacdia-backend/src/insurance/insurance.controller.ts:438` (pasar `localFieldId` de query/body)
- Test: `insurance-config-scope.spec.ts`

**Enfoque:**

```ts
const INSURANCE_CONFIG_FIELD_ROLES = new Set(['director-lf', 'assistant-lf']);
const INSURANCE_CONFIG_ADMIN_ROLES = new Set(['super-admin', 'admin']);

resolve(profile, requestedLocalFieldId?: number): InsuranceConfigScope {
  const roles = ...;
  if (has(INSURANCE_CONFIG_FIELD_ROLES)) {
    const own = profile.authorization.effective.scope.global.local_field?.id;
    if (typeof own !== 'number') throw Forbidden(INSURANCE_CONFIG_LOCAL_FIELD_SCOPE_REQUIRED);
    if (requestedLocalFieldId !== undefined && requestedLocalFieldId !== own) throw Forbidden(INSURANCE_CONFIG_ROLE_FORBIDDEN);
    return { localFieldId: own };
  }
  if (has(INSURANCE_CONFIG_ADMIN_ROLES)) {
    if (typeof requestedLocalFieldId !== 'number') throw BadRequest(INSURANCE_CONFIG_LOCAL_FIELD_ID_REQUIRED);
    return { localFieldId: requestedLocalFieldId };
  }
  throw Forbidden(INSURANCE_CONFIG_ROLE_FORBIDDEN);
}
```

Nuevo error code `INSURANCE_CONFIG_LOCAL_FIELD_ID_REQUIRED` + i18n. En el controller, los endpoints de productos/ciclos aceptan `?local_field_id=` (GET) o `local_field_id` en body (POST/PATCH). Decisión de alcance: director-union **no** entra en esta ola (su scope de unión → múltiples campos; se evalúa después).

**Aceptación:** admin sin `local_field_id` → 400; con él → 200; director-lf con `local_field_id` ajeno → 403; director-lf sin parámetro → su campo.
**Tamaño:** ~120 líneas.

### PR 1.4 · Inscripción anual de club desde admin

**Files:**
- Modify: `sacdia-backend/src/club-enrollments/club-enrollments.controller.ts:39` (`@Post()`), `:127` (`@Patch`)
- Test: `club-enrollments.controller.spec.ts`

**Enfoque:** verificar qué `@RequirePermissions` y `@AuthorizationResource` tienen hoy `POST` y `PATCH` (`graft skeleton` del controller). Si solo permiten roles de club, ampliar la metadata para que `club_instances:create|update` con alcance territorial (director-lf, admin, super-admin sobre secciones de su campo) pase el `PermissionsGuard`. Si ya pasan, este PR es solo tests + nota en `docs/api/ENDPOINTS-LIVE-REFERENCE.md`. Sin cambios de schema.

**Aceptación:** director-lf crea `club_enrollments` de una sección de su campo; de otro campo → 403.
**Tamaño:** ~60 líneas.

---

## Ola 2 · Arreglos a pantallas existentes (admin)

### PR 2.1 · Timezone en el formulario de campo local

Depende de: nada (el backend ya exige `timezone` cuando `active`).

**Files:**
- Modify: `sacdia-admin/src/components/catalogs/local-fields/local-field-form-dialog.tsx`
- Modify: `sacdia-admin/src/components/catalogs/local-fields/local-fields-columns.tsx` (columna timezone)
- Modify: `sacdia-admin/src/lib/catalogs/entities.ts` (campo `timezone` en la entidad local field)
- Create: `sacdia-admin/src/lib/geography/iana-timezones.ts` (lista de zonas de América + helper `isCanonicalIanaTimezone` usando `Intl.supportedValuesOf('timeZone')` con fallback a lista estática)
- Test: `local-field-form-dialog.test.tsx` (si no existe, crearlo), `iana-timezones.test.ts`

**Enfoque:** `Select` con búsqueda (Combobox shadcn) de zonas IANA; obligatorio cuando `active = true`; default sugerido `America/Mexico_City`. Validación Zod espejo del DTO backend (`geography.dto.ts:267-289`).

**Aceptación:** crear campo activo sin timezone → error de formulario; con timezone → 201; la tabla muestra la zona.
**Tamaño:** ~200 líneas.

### PR 2.2 · Crear llaves en Variables

Depende de: PR 1.1.

**Files:**
- Create: `sacdia-admin/src/components/system-config/system-config-create-dialog.tsx`
- Modify: `sacdia-admin/src/components/system-config/system-config-client-page.tsx` (botón "Nueva variable" + EmptyState con acción)
- Modify: `sacdia-admin/src/lib/api/system-config.ts` (`createSystemConfig`)
- Modify: `sacdia-admin/src/lib/auth/screen-catalog/screens/admin-system.ts` (capability `create` → `system_config:create`, super-admin)
- Test: `system-config-create-dialog.test.tsx`

**Enfoque:** Dialog (≤4 campos planos: cumple DS §6.1.1). Campos: llave (regex del DTO), tipo (select), valor (input que cambia según tipo: switch para boolean, number para int/number, textarea para json), descripción.

**Aceptación:** tabla vacía muestra botón; crear duplicado muestra mensaje 409 traducido.
**Tamaño:** ~220 líneas.

### PR 2.3 · Editar territorio en detalle de usuario

Depende de: PR 1.2.

**Files:**
- Modify: `sacdia-admin/src/lib/api/admin-users.ts:833` (`UpdateAdminUserPayload` + `country_id`, `union_id`, `local_field_id`)
- Create: `sacdia-admin/src/components/users/user-territory-card.tsx`
- Modify: página `sacdia-admin/src/app/(dashboard)/dashboard/users/[userId]/page.tsx` (montar la card en la pestaña Roles o nueva pestaña "Territorio")
- Modify: `sacdia-admin/src/components/users/new-user-form.tsx:78-100` (hacer `local_field_id` obligatorio cuando el rol es `director-lf` o `assistant-lf`)
- Test: `user-territory-card.test.tsx`, ajustar `new-user-form.test.tsx`

**Enfoque:** reutilizar los selects en cascada país → unión → campo que ya usa `new-user-form.tsx` (extraer a `territory-cascade-fields.tsx` si están inline). Gate: `users:update_admin` + roles `admin|super-admin` (igual que las banderas). Mostrar aviso del trigger de pastores cuando cambia el campo.

**Aceptación:** cambiar campo del usuario refleja en la tabla; director-lf nuevo sin campo no se puede guardar.
**Tamaño:** ~250 líneas.

### PR 2.4 · Selector de campo en Configuración de seguros

Depende de: PR 1.3.

**Files:**
- Modify: `sacdia-admin/src/app/(dashboard)/dashboard/insurance/config/page.tsx:50-60`
- Modify: componente de pestañas de seguros (ubicar con `rg "requiresLocalFieldId" sacdia-admin/src/components/insurance`)
- Modify: `sacdia-admin/src/lib/api/insurance*.ts` (pasar `local_field_id` en productos y ciclos cuando el actor no es LF)
- Test: test del page/componente

**Enfoque:** el picker que hoy solo alimenta la pestaña de pago alimenta las tres pestañas. Para `territory.level === 'union' | 'division'` (director-union, director-dia) ocultar productos/ciclos con nota "solo campo local o administrador" hasta que el backend lo soporte.

**Aceptación:** super-admin elige campo y hace CRUD de productos/ciclos; director-lf no ve picker.
**Tamaño:** ~150 líneas.

### PR 2.5 · Montar scoring de unión y campo

**Files:**
- Modify: `sacdia-admin/src/app/(dashboard)/dashboard/settings/scoring-categories/page.tsx`
- Create: `sacdia-admin/src/components/scoring-categories/scoring-categories-page.tsx` (Tabs: División / Unión / Campo local, según `resolveAdminTerritoryScope`)
- Reuse: `union-scoring-categories-tab.tsx`, `local-field-scoring-categories-tab.tsx`, `division-scoring-categories-page.tsx`
- Modify: `sacdia-admin/src/lib/auth/screen-catalog/screens/admin-system.ts` (o donde viva `admin-settings-scoring-categories`: abrir `viewAny` a `director-union`, `director-lf`, `assistant-*` con capability `scoring_categories:*`)
- Modify: `sacdia-admin/src/navigation/sidebar/sidebar-items.ts` (el ítem deja de ser solo "Administración"; ver PR 2.6)
- Test: `scoring-categories-page.test.tsx`

**Enfoque:** los tabs ya existen y los endpoints `unions/:unionId/scoring-categories` y `local-fields/:fieldId/scoring-categories` también. Verificar primero que los componentes compilan contra la API actual (llevan meses sin montarse): correr `pnpm tsc --noEmit` tras montarlos. Scope: super-admin ve los tres tabs con picker; director-union ve División (solo lectura) y Unión; director-lf ve División y Unión (lectura) y Campo.

**Aceptación:** director-lf crea categoría de campo; aparece en el registro semanal de sus clubes.
**Tamaño:** ~180 líneas (más correcciones si los tabs están desactualizados).

### PR 2.6 · Limpieza del sidebar y menús de configuración

**Files:**
- Modify: `sacdia-admin/src/navigation/sidebar/sidebar-items.ts`
- Modify: `sacdia-admin/src/components/campamentos/camporee-scope-config-page.tsx` (una sola pantalla; eliminar la ruta `/union` o convertirla en redirect)
- Delete/Modify: `sacdia-admin/src/app/(dashboard)/dashboard/campamentos/configuracion/union/page.tsx`
- Modify: `sacdia-admin/src/lib/auth/screen-catalog/screens/*.ts` (ids retirados)
- Test: `sacdia-admin/src/navigation/sidebar/filter-sidebar.test.ts` (ids esperados)

**Cambios concretos:**
1. Quitar `annual-folders-templates` y `annual-folders-categories` (redirects) del grupo Carpetas anuales; dejar un solo "Plantillas" bajo Evidencias.
2. Agregar `admin-system-user-permissions` → `/dashboard/rbac/user-permissions` bajo Sistema, debajo de "Matriz de seguridad".
3. Mover `payment-orders` (Órdenes de pago) fuera de Seguros a Operaciones raíz y agregar `admin-local-field-payment-orders-config` → `/dashboard/insurance/config?tab=payment` bajo **Campo local** junto a Métodos de pago (la URL se mantiene; solo cambia la entrada).
4. `admin-campamentos-config`: un solo hijo "Tipos de evento" → `/dashboard/catalogs/camporee-event-types`; eliminar los dos ítems duplicados.
5. Mover `admin-settings-scoring-categories` a **Campo local / Mi territorio** (se concreta en PR 3.2; aquí solo renombrar "Categorías scoring" → "Categorías de puntuación").

**Aceptación:** snapshot del sidebar actualizado; `/dashboard/campamentos/configuracion/union` redirige; cero rutas 404 desde el menú (correr `scripts/e2e-smoke.mjs` si cubre navegación).
**Tamaño:** ~150 líneas netas (más borrados).

### PR 2.7 · Aviso de inconsistencia del año eclesiástico

**Files:**
- Create: `sacdia-admin/src/lib/ecclesiastical-years/year-consistency.ts` (`evaluateYearConsistency(years, today)` → `{ status: 'ok' | 'no_current' | 'active_not_current' | 'current_not_active' | 'multiple_active', activeYear?, currentYear? }`)
- Create: `sacdia-admin/src/components/catalogs/ecclesiastical-years/year-consistency-banner.tsx`
- Modify: página `/dashboard/catalogs/ecclesiastical-years` (montar banner arriba de la tabla)
- Modify: `sacdia-admin/src/lib/prerequisites/annual-folder-gaps.ts` y `club-create-gaps.ts` (usar `evaluateYearConsistency` en vez de solo "current")
- Test: `year-consistency.test.ts` (5 casos), `year-consistency-banner.test.tsx`

**Enfoque:** función pura con fecha inyectada. Banner `destructive` para `no_current` y `multiple_active`; `warning` para los desalineados, con texto que explica qué usa cada noción y botón "Activar año actual" (PATCH `active: true` sobre el año por fechas; el backend ya desactiva los demás).

**Aceptación:** con año `active` distinto al que cubre hoy, el banner aparece y el botón lo corrige en un clic.
**Tamaño:** ~200 líneas.

---

## Ola 3 · Pantallas nuevas

### PR 3.1 · Estado de configuración (checklist por capas)

Depende de: Ola 0 y 1 completas (para que los ítems detectados tengan dónde resolverse).

**Backend — `GET /api/v1/admin/setup-status`**
- Create: `sacdia-backend/src/admin/setup-status/{setup-status.module.ts,setup-status.controller.ts,setup-status.service.ts,setup-status.types.ts}`
- Permiso nuevo `setup_status:read` (admin, super-admin, director-dia, director-union, director-lf, assistant-*). Seeds + migración.
- Respuesta: `{ scope: { level, id }, layers: [{ key: 'core'|'catalogs'|'territory', items: [{ key, status: 'ok'|'missing'|'warning', count?, href_hint, blocking: boolean }] }] }`.
- Checks de capa 1 (global): roles ≥ 22, permisos > 0, `role_permissions` > 0, `club_types` = 3 nombres exactos, año actual por fechas y `active` coinciden, ≥1 país activo, división `DIA`, `relationship_types` > 0, `ranking_tiers` > 0.
- Checks de capa 2 (global): `classes` activas por tipo de club, `honors` > 0, `system_config` cubre la lista de llaves de PR 0.1, ≥1 `certification_versions` PUBLISHED.
- Checks de capa 3 (por `local_field_id` del scope; para unión/división iterar sus campos y resumir): timezone válido, ≥1 distrito y ≥1 iglesia, `local_field_investiture_windows` del año actual, `district_investiture_pastors` activos ≥1, `insurance_cycle_configs` del año, `field_payment_order_configs` activa + flag `field_payment_orders_v1` incluye el campo, `MaterialConfig`, `folder_templates` PUBLISHED por tipo de club × año (propio o de la unión), `annual_ranking_configs` activa por tipo × año (propio o de la unión), ≥1 `coordination_zones`.
- Cada check es una función `(ctx) => Promise<SetupItem>` en su propio archivo bajo `setup-status/checks/`, con spec unitario usando Prisma mock. Cache en memoria 60 s por `(level,id)` como los dashboards SLA.

**Admin — `/dashboard/setup`**
- Create: `sacdia-admin/src/app/(dashboard)/dashboard/setup/page.tsx`
- Create: `sacdia-admin/src/components/setup/{setup-status-page.tsx,setup-layer-section.tsx,setup-item-row.tsx}`
- Create: `sacdia-admin/src/lib/api/setup-status.ts`
- Modify: `sacdia-admin/src/lib/prerequisites/resolve-prerequisite-href.ts` (mapear `href_hint` → ruta del admin; ya existe la lógica para gaps)
- Modify: `sidebar-items.ts` (ítem "Estado de configuración" al inicio del grupo Administración) y screen catalog.
- Modify: `sacdia-admin/src/app/(dashboard)/dashboard/page.tsx` (card "Configuración pendiente: N bloqueantes" cuando `blocking` > 0).
- Test: `setup-status-page.test.tsx` con fixture de respuesta.

**Aceptación:** super-admin ve las tres capas globales + resumen de campos; director-lf ve capa 1-2 en solo lectura y su capa 3 con enlaces a cada pantalla; un ambiente recién sembrado muestra exactamente los faltantes de la guía.
**Tamaño:** backend ~400 líneas (PR propio), admin ~350 líneas (PR propio). Dos PRs encadenados.

### PR 3.2 · Hub de configuración por niveles

Depende de: PR 2.6, 3.1.

**Files:**
- Modify: `sacdia-admin/src/app/(dashboard)/dashboard/configuration/page.tsx`
- Create: `sacdia-admin/src/lib/configuration/configuration-sections.ts` (declarativo: `{ level: 'system'|'catalogs'|'territory', items: [{ id, title, description, href, screenId }] }`; filtrado con `canViewScreen`)
- Modify: `sidebar-items.ts`: grupo **Administración** queda con tres padres: **Sistema**, **Catálogos**, **Mi territorio** (este último absorbe Campo local, Config. campamentos, Categorías de puntuación, Investidura → ventana/pastores, Seguros → configuración, Plantilla de carpeta, Config. de clasificación, Coordinación). Las pantallas no se mueven de URL; solo cambian las entradas.
- Test: `configuration-sections.test.ts` (cada `href` existe en el screen catalog), snapshot del sidebar.

**Aceptación:** el hub lista todo lo configurable del scope del usuario; ninguna pantalla de configuración queda sin entrada.
**Tamaño:** ~250 líneas.

### PR 3.3 · Inscripción anual de club en el admin

Depende de: PR 1.4.

**Files:**
- Create: `sacdia-admin/src/components/clubs/detail/club-enrollment-card.tsx` (en la pestaña Secciones del detalle de club, por sección: estado del año actual, botón "Abrir año" → formulario)
- Create: `sacdia-admin/src/components/clubs/detail/club-enrollment-form-sheet.tsx` (página/sheet dedicada: >4 campos — directiva, horario, cuota, dirección; DS §6.1.1)
- Modify: `sacdia-admin/src/lib/api/club-enrollments.ts:44-60` (`createClubEnrollment`, `updateClubEnrollment`)
- Modify: `screen-catalog/screens/clubs.ts` (capability `club_instances:create|update`)
- Test: ambos componentes.

**Aceptación:** director-lf abre el año de una sección sin app; la carpeta anual se autogenera si hay plantilla publicada (o muestra el aviso de PR 3.1).
**Tamaño:** ~350 líneas.

### PR 3.4 · `role_slot_limits` en Roles (diferido, bajo)

Agregar campo "Máximo por sección" en `/dashboard/configuration/roles/[roleId]` para roles CLUB, con endpoint `PATCH /admin/rbac/roles/:id/slot-limit`. Solo si el dueño confirma que los cupos cambian en la práctica; hoy el fallback en código basta.

---

## Orden de ejecución sugerido

```text
Semana 1  Ola 0: 0.1 ‖ 0.2 ‖ 0.3 ‖ 0.4   (paralelo, 4 PRs chicos)   + decisión 0.5
Semana 2  Ola 1: 1.1 ‖ 1.2 ‖ 1.3 ‖ 1.4   (paralelo)
Semana 3  Ola 2: 2.1 ‖ 2.5 ‖ 2.6 ‖ 2.7  luego 2.2 → 2.3 → 2.4 (dependen de Ola 1)
Semana 4-5 Ola 3: 3.1 backend → 3.1 admin → 3.2 → 3.3
```

Riesgo principal: PR 2.5 (tabs de scoring sin montar por meses) puede destapar deuda en esos componentes. Si `tsc` falla al montarlos, dividir en "reparar tabs" + "montar".

## Decisiones pendientes del dueño

1. PR 0.5: opción A, B o ambas.
2. PR 1.3: ¿director-union debe configurar seguros de sus campos? (hoy: no).
3. PR 3.4: ¿se ejecuta o se descarta?

---

## Self-review

- **Cobertura:** los 19 huecos de la guía tienen PR o están marcados diferidos (14, 15) con razón.
- **Placeholders:** cada PR tiene archivos exactos, enfoque y aceptación. Los fragmentos de código cubren lo no obvio (constante de roles, scope de seguros, seed condicional, SQL de llaves). El detalle paso a paso TDD se genera por PR al ejecutarlo.
- **Consistencia:** `CLUB_BOARD_ROLE_NAMES` (0.2) usa los mismos nombres que `role-slot-limits.seed.sql`; `evaluateYearConsistency` (2.7) alimenta tanto el banner como `lib/prerequisites` y el check de capa 1 de 3.1; `system_config:create` se usa en 1.1 y 2.2; `INSURANCE_CONFIG_LOCAL_FIELD_ID_REQUIRED` se usa en 1.3 y el mensaje en 2.4.
