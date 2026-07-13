# Camporee Operational Hardening Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Completar y asegurar el flujo operativo de camporees: lifecycle, templates reutilizables, eventos y rúbricas atómicos, scoring temporal auditable, admisiones tardías penalizadas, documentos privados y experiencias admin/app coherentes.

**Architecture:** Contract-first y backend-authoritative. Un `CamporeeLifecyclePolicy` concentra fechas y mutabilidad; eventos/templates usan una definición competitiva compartida; scores y penalizaciones se registran como ledgers inmutables; admin y app sólo consumen capacidades explícitas del API. La implementación es aditiva y conserva lectura de datos históricos mientras migra consumidores al contrato atómico.

**Tech Stack:** NestJS 11, Prisma 7, PostgreSQL/Supabase y Jest en `sacdia-backend`; Next.js 16, React 19, server actions, Vitest y Testing Library en `sacdia-admin`; Flutter, Riverpod, Dio y Flutter Test en `sacdia-app`; documentación canónica en `docs/`.

---

## Reglas de ejecución

1. Leer el `AGENTS.md` raíz y el `AGENTS.md`/`CLAUDE.md` del repo antes de cada batch.
2. No ejecutar builds. Sólo tests, typecheck, lint/analyze focalizados y `prisma validate`.
3. No crear commits salvo solicitud explícita. Si se solicitan, usar conventional commits, sin `Co-Authored-By` ni atribución IA.
4. No trabajar el backend en `sacdia-backend/` mientras tenga cambios ajenos. Continuar en `.worktrees/backend-camporee-operational-scoring` y comparar con `origin/development` antes de cada batch.
5. Crear worktrees aislados desde `origin/development` para admin y app al iniciar sus batches; no usar la rama admin `feat/ui-reset-maia-clubs` porque está atrasada y contiene cambios no relacionados.
6. Detenerse en cada checkpoint. Reportar archivos, decisiones, comandos/resultados y riesgos antes de continuar.
7. Aplicar migraciones sólo en una base explícitamente autorizada. `prisma validate` no implica `migrate deploy`.
8. No mezclar la remediación general de dependencias con el feature. Primero verificar reachability y abrir una unidad de trabajo separada.
9. Actualizar docs canónicas dentro de cada task/checkpoint que cambie schema, endpoint, permiso, error o flujo; la Task 18 es sólo reconciliación final.
10. En el worktree backend usar `./node_modules/.bin/jest` y `./node_modules/.bin/prisma`; el wrapper `pnpm` intenta reinstalar dependencias en este entorno no-TTY.

## Reglas de negocio innegociables

- La inscripción/asistencia no suma puntos al ranking anual.
- El ranking consume resultados oficiales por evento/sección menos ajustes de puntos activos, con piso global cero.
- Todo evento puntuable tiene rúbricas cuya suma equivale a `max_points`.
- Sólo el juez principal emite el primer resultado; ayudantes no promedian ni envían resultado oficial.
- Un candidato a juez debe ser pastor, tener al menos 18 años o tener la clase de Guía Mayor investida; la asignación exacta sigue siendo obligatoria para puntuar.
- `assistant-lf`/`director-lf` y sus equivalentes de Unión pueden registrar manualmente u override dentro de su scope; el motivo es obligatorio en correcciones.
- Un juez sólo califica una vez, dentro de la ventana del evento y para su asignación exacta.
- Todo submit reintentable usa una clave idempotente; concurrencia nunca puede reemplazar silenciosamente un resultado.
- `no_show` asigna el mínimo configurado, o cero si no existe, y conserva evidencia.
- Una admisión tardía descuenta puntos; el recargo monetario es adicional, opcional y desactivado por defecto.
- Eventos y templates admiten hasta cinco PDFs privados.
- Al iniciar el camporee se congelan datos competitivos. Durante la operación sólo cambian agenda, sede, jueces y notas operativas, con auditoría.

## Estado inicial que debe preservarse

El worktree backend `.worktrees/backend-camporee-operational-scoring` ya contiene un batch no commiteado con:

- `score_status`/`is_no_show`;
- clamp a `min_points`;
- envío one-shot del juez principal;
- override enlazado por `override_of_submission_id`;
- migración `20260708193000_camporee_score_no_show_and_lock`;
- 16 pruebas focalizadas de scoring aprobadas.

No recrear ni descartar ese diff. Integrarlo como baseline de las tareas siguientes.

---

## Batch 0 — Baseline y protección del trabajo existente

### Task 1: Revalidar el baseline de scoring operativo

**Files:**
- Inspect: `.worktrees/backend-camporee-operational-scoring/prisma/schema.prisma`
- Inspect: `.worktrees/backend-camporee-operational-scoring/prisma/migrations/20260708193000_camporee_score_no_show_and_lock/migration.sql`
- Inspect: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/camporee-scoring.service.ts`
- Test: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/camporee-scoring.service.spec.ts`
- Modify mirror: `docs/database/schema.prisma`
- Modify docs: `docs/database/SCHEMA-REFERENCE.md`
- Modify docs: `docs/features/camporees.md`
- Modify docs: `docs/features/camporee-events.md`

**Step 1: Verificar aislamiento y divergencia**

Run:

```bash
git -C .worktrees/backend-camporee-operational-scoring fetch origin development
git -C .worktrees/backend-camporee-operational-scoring rev-list --left-right --count HEAD...origin/development
git -C .worktrees/backend-camporee-operational-scoring status --short
```

Expected: la rama base no está detrás de cambios nuevos inesperados y el diff sólo contiene scoring/schema/migración. Si `origin/development` avanzó, detenerse y revisar el merge antes de editar.

**Step 2: Reejecutar las pruebas focalizadas**

Run:

```bash
cd .worktrees/backend-camporee-operational-scoring
pnpm exec jest src/camporee-scoring/camporee-scoring.service.spec.ts --runInBand
```

Expected: PASS; conservar evidencia del número de tests.

**Step 3: Validar Prisma sin aplicar migración**

Run:

```bash
cd .worktrees/backend-camporee-operational-scoring
pnpm exec prisma validate
```

Expected: `The schema ... is valid`.

**Step 4: Sincronizar el espejo documental**

Copiar únicamente los modelos/campos nuevos al schema canónico y documentar:

```text
score_status = scored | no_show
is_no_show
override_of_submission_id
```

Expected: código, migración y docs describen el mismo contrato.

### Task 1.1: Serializar e idempotentizar el scoring oficial

**Files:**
- Modify: `.worktrees/backend-camporee-operational-scoring/prisma/schema.prisma`
- Create: `.worktrees/backend-camporee-operational-scoring/prisma/migrations/20260709100000_camporee_score_idempotency/migration.sql`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/camporee-scoring.controller.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/camporee-scoring.service.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/dto/camporee-scoring.dto.ts`
- Test: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/camporee-scoring.service.spec.ts`
- Test: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/camporee-scoring.controller.spec.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/common/errors/error-codes.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/i18n/{en,es,fr,pt-BR}/errors.json`
- Modify mirror: `docs/database/schema.prisma`
- Modify docs: `docs/database/SCHEMA-REFERENCE.md`
- Modify docs: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- Modify docs: `docs/api/FRONTEND-INTEGRATION-GUIDE.md`
- Modify docs: `docs/api/SECURITY-GUIDE.md`
- Modify docs: `docs/features/camporees.md`
- Modify docs: `docs/features/camporee-events.md`

**Step 1: Escribir tests RED de idempotencia y concurrencia**

Cubrir como mínimo:

```ts
it('returns the original receipt for the same idempotency key and payload');
it('rejects the same key with a different canonical payload');
it('acquires a transaction-scoped event/section lock before reading active result');
it('allows only one of two concurrent judge submissions');
it('requires expected_active_result_id for an override');
it('rejects an override when the active result changed');
it('keeps the previous result active when a competing transaction fails');
it('denies manual scoring to actors with only camporee_events:update');
it('derives source from assignment, role and scope');
it('requires notes for an override of an active result');
it('recovers replay or conflict after an idempotency P2002');
it('fails safely when the persisted receipt has no result');
```

Run:

```bash
cd .worktrees/backend-camporee-operational-scoring
./node_modules/.bin/jest src/camporee-scoring/camporee-scoring.service.spec.ts src/camporee-scoring/camporee-scoring.controller.spec.ts --runInBand
```

Expected: FAIL por ausencia del contrato idempotente/lock.

**Step 2: Agregar el contrato persistente**

Agregar a submissions:

```text
idempotency_key UUID NULL
request_hash VARCHAR(64) NULL
raw_awarded_points DECIMAL(10,2) NOT NULL DEFAULT 0
minimum_adjustment_points DECIMAL(10,2) NOT NULL DEFAULT 0
```

Agregar índice único parcial por `(submitted_by, idempotency_key)` cuando la clave no sea nula. El controller acepta `Idempotency-Key` UUID. Durante compatibilidad puede faltar, pero sólo requests con clave reciben replay idempotente.

Después de agregar las columnas, backfillear filas históricas con `raw_awarded_points = total_awarded_points` y `minimum_adjustment_points = 0`; no inferir retroactivamente ajustes mínimos no auditados.

**Step 3: Serializar dentro de la transacción**

Con clave idempotente, adquirir primero `pg_advisory_xact_lock(hashtextextended(prefijo + actor + key, 0))` usando el overload bigint. Después adquirir `pg_advisory_xact_lock(eventId::integer, clubSectionId::integer)` con casts explícitos, porque Prisma enlaza números JavaScript como `INT8` y PostgreSQL debe resolver el overload exacto `(integer, integer)`. PostgreSQL mantiene separados ambos keyspaces; la colisión teórica del hash de 64 bits sólo puede sobre-serializar. Después de ambos locks:

1. buscar la clave idempotente y comparar hash canónico;
2. releer el resultado activo;
3. validar one-shot o `expected_active_result_id` del override;
4. crear submission/items y reemplazar resultado;
5. devolver receipt estable, incluso al reintentar.

La misma clave con payload distinto devuelve `409 IDEMPOTENCY_KEY_REUSED`; resultado cambiado devuelve `409 CAMPOREE_SCORING_RESULT_STALE`; el segundo submit no autorizado devuelve `409 CAMPOREE_SCORING_RESULT_ALREADY_SUBMITTED`.

`source` se deriva en servidor: juez principal asignado sin override explícito → `judge_primary`; gestores LF/Unión dentro de scope → `manual_lf`; `admin|assistant-admin|super-admin` → `admin_override`. `camporee_events:update` por sí solo falla con 403. Todo override sobre resultado activo exige `notes.trim()` no vacío.

Como defensa residual, capturar P2002 fuera de la transacción y releer por actor+clave: mismo hash con receipt completo retorna replay; hash distinto retorna `IDEMPOTENCY_KEY_REUSED`; fila ausente relanza el error. Un receipt sin `section_results[0]` falla con error interno canónico.

**Step 4: Ejecutar GREEN y validar Prisma**

Run:

```bash
cd .worktrees/backend-camporee-operational-scoring
./node_modules/.bin/jest src/camporee-scoring/camporee-scoring.service.spec.ts src/camporee-scoring/camporee-scoring.controller.spec.ts --runInBand
./node_modules/.bin/prisma validate
```

Expected: PASS y schema válido. No aplicar migración a una base real.

**Step 5: Actualizar contrato canónico en el mismo checkpoint**

Documentar header, source server-side, motivo de override, backfill, recuperación P2002, receipt, locks con keyspaces separados y compatibilidad temporal de clientes sin clave.

### Checkpoint 0 — Scoring autoritativo

Detenerse y reportar antes de lifecycle:

- resultado de tests y Prisma;
- columnas/índice/migración;
- evidencia de lock antes de leer el resultado activo;
- evidencia de autorización deny-by-default, motivo obligatorio y recuperación P2002;
- semántica de replay y override stale;
- docs canónicas actualizadas;
- limitación: todavía no existe ventana horaria ni cola offline móvil.

---

## Batch 1 — Lifecycle, atomicidad y autorización

### Task 2: Crear la política única de lifecycle y validación temporal

**Files:**
- Create: `.worktrees/backend-camporee-operational-scoring/src/camporees/policies/camporee-lifecycle.policy.ts`
- Create: `.worktrees/backend-camporee-operational-scoring/src/camporees/policies/camporee-lifecycle.policy.spec.ts`
- Create: `.worktrees/backend-camporee-operational-scoring/src/camporees/policies/index.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporees/camporees.module.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporees/camporees.service.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporees/camporee-late-approvals.service.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporees/camporees.controller.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporees/dto/create-camporee.dto.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporees/dto/update-camporee.dto.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporees/dto/create-union-camporee.dto.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporees/dto/update-union-camporee.dto.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/prisma/schema.prisma`
- Create: `.worktrees/backend-camporee-operational-scoring/prisma/migrations/20260709110000_camporee_lifecycle_timezone/migration.sql`
- Test: `.worktrees/backend-camporee-operational-scoring/src/camporees/camporees.service.spec.ts`
- Test: `.worktrees/backend-camporee-operational-scoring/src/camporees/camporees.controller.spec.ts`
- Test: `.worktrees/backend-camporee-operational-scoring/src/camporees/camporee-late-approvals.service.spec.ts`
- Modify mirror: `docs/database/schema.prisma`

**Step 1: Escribir tests fallidos de fases y fechas**

Cubrir como mínimo:

```ts
expect(policy.resolve(ctx, beforeDeadline)).toBe('registration_open');
expect(policy.resolve(ctx, afterDeadline)).toBe('registration_closed');
expect(policy.resolve(ctx, duringCamporee)).toBe('in_progress');
expect(policy.resolve(ctx, afterCamporee)).toBe('finished');
expect(policy.resolve(ctx, beforeClubOpening)).toBe('preparation');
expect(policy.resolveClubRegistrationDisposition(ctx, beforeClubOpening)).toBe('not_open_yet');
expect(policy.resolveClubRegistrationDisposition(ctx, manuallyClosed)).toBe('manually_frozen');
expect(policy.resolveClubRegistrationDisposition(ctx, afterDeadline)).toBe('late_approval_required');
expect(policy.resolveClubRegistrationDisposition(ctx, atDeadline)).toBe('open');
expect(policy.isClubRegistrationClosed(manuallyClosed)).toBe(true);
expect(() => policy.assertDateOrder(invalidDates)).toThrow();
expect(() => policy.assertDateOnly('2026-07-09T00:00:00Z')).toThrow();
expect(() => policy.assertOffsetTimestamp('2026-07-09')).toThrow();
expect(() => policy.assertIanaTimezone('GMT-6')).toThrow();
expect(policy.readiness(unverifiedTimezone)).toContain('timezone_unverified');
```

Agregar casos de límite exactamente en `opens_at` y `deadline`, transición por DST con `now` inyectable, cierre manual, update parcial que omite `timezone` y aprobación tardía que consulta la misma política.

Run:

```bash
cd .worktrees/backend-camporee-operational-scoring
pnpm exec jest src/camporees/policies/camporee-lifecycle.policy.spec.ts --runInBand
```

Expected: FAIL porque la política no existe.

**Step 2: Implementar el contrato mínimo**

```ts
export type CamporeePhase =
  | 'preparation'
  | 'registration_open'
  | 'registration_closed'
  | 'in_progress'
  | 'finished';

export type CamporeeLifecycleContext = {
  startDate: string; // YYYY-MM-DD; calendario, no instante
  endDate: string; // YYYY-MM-DD; calendario, no instante
  clubRegistrationOpensAt: Date | null;
  clubRegistrationDeadline: Date | null;
  memberRegistrationDeadline: Date | null;
  paymentDeadline: Date | null;
  clubRegistrationClosedAt: Date | null;
  timezone: string;
  timezoneVerifiedAt: Date | null;
};
```

La política debe usar `now` inyectable en tests, una librería de zona horaria ya presente en el backend o `Intl` puro, sin convertir `start_date`/`end_date` a medianoche. `resolvePhase` compara esos dos campos como fechas calendario en `timezone`: `in_progress` para `start_date <= localToday <= end_date` y `finished` después de `end_date`. Antes del inicio, devuelve `preparation` mientras `now < clubRegistrationOpensAt`; después devuelve `registration_open` desde la apertura (o inmediatamente si es `NULL`) hasta el deadline inclusive, y `registration_closed` después del deadline o al cierre manual.

Como una inscripción puede estar abierta el mismo día calendario en que inicia el camporee, exponer además `resolveClubRegistrationDisposition()` de forma independiente: `not_open_yet`, `open`, `late_approval_required` o `manually_frozen`. Antes de `club_registration_opens_at` devuelve `not_open_yet`; ese estado bloquea inscripción normal y tampoco habilita aprobación tardía. La fase competitiva `in_progress`/`finished` tiene prioridad para el estado operativo del camporee; la disposición conserva si el flujo normal de club aún no abrió, está abierto, requiere aprobación tardía o fue congelado manualmente. Reemplazar todos los gates locales duplicados por esta política, incluido `camporee-late-approvals.service.ts`, y mantener sincronizado el mirror/documentación de `club_registration_closed_at` y `club_registration_closed_by`.

Los DTOs deben aceptar `start_date`/`end_date` exclusivamente como `YYYY-MM-DD`; rechazar timestamps y cualquier otra forma. `club_registration_opens_at` y todos los deadlines son `TIMESTAMPTZ`: exigir ISO-8601 con `Z` u offset explícito y rechazar valores date-only. Validar `start_date <= end_date` como calendario local, `clubRegistrationOpensAt <= clubRegistrationDeadline` cuando ambos existan y que cada deadline, por su fecha calendario local, sea `<= start_date`; no inferir horas para compararlos.

**Step 3: Agregar timezone al schema**

- `local_camporees.timezone String @default("America/Mexico_City")` y `union_camporees.timezone String @default("America/Mexico_City")`
- `local_camporees.club_registration_opens_at DateTime?` y `union_camporees.club_registration_opens_at DateTime?` (`TIMESTAMPTZ NULL`; `NULL` significa apertura inmediata).
- `timezone_verified_at DateTime?` y `timezone_verified_by String? @db.Uuid` en ambas tablas.
- Dos FKs SQL nombradas, una por tabla, desde `timezone_verified_by` hacia `users(user_id)` con `ON DELETE SET NULL`, índices para ambas columnas `timezone_verified_by` y relaciones inversas nombradas en `users` para Local/Unión.
- SQL con default provisional `America/Mexico_City` para históricos y `timezone_verified_at=NULL`; readiness/scoring por ventana no se habilita hasta confirmación explícita.

En create o update, una timezone IANA explícita válida marca `timezone_verified_at` y `timezone_verified_by` con el actor autenticado. El controller debe propagar `req.user.sub` a ambos servicios y el PATCH parcial no puede borrar metadatos de verificación al omitir `timezone`.

**Step 4: Ejecutar tests y validación**

Run:

```bash
cd .worktrees/backend-camporee-operational-scoring
pnpm exec jest src/camporees/policies/camporee-lifecycle.policy.spec.ts src/camporees/camporees.service.spec.ts src/camporees/camporees.controller.spec.ts src/camporees/camporee-late-approvals.service.spec.ts --runInBand
pnpm exec prisma validate
```

Expected: PASS y schema válido. Incluir límites exactos de apertura/deadline, cierre manual, PATCH parcial, DST y fechas calendario locales.

### Task 3: Unificar validación competitiva para evento y template

**Files:**
- Create: `.worktrees/backend-camporee-operational-scoring/src/camporee-events/validation/camporee-scoring-definition.validator.ts`
- Create: `.worktrees/backend-camporee-operational-scoring/src/camporee-events/validation/camporee-scoring-definition.validator.spec.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporee-events/dto/camporee-events.dto.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporee-events/camporee-events.controller.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporee-event-templates/dto/camporee-event-templates.dto.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporee-events/camporee-events.service.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporee-event-templates/camporee-event-templates.service.ts`
- Test: `.worktrees/backend-camporee-operational-scoring/src/camporee-events/camporee-events.service.spec.ts`
- Test: `.worktrees/backend-camporee-operational-scoring/src/camporee-events/camporee-events.controller.spec.ts`
- Test: `.worktrees/backend-camporee-operational-scoring/src/camporee-event-templates/camporee-event-templates.service.spec.ts`

**Step 1: Escribir tests fallidos del invariante compartido**

Casos obligatorios para evento y template:

```ts
it('rejects scoring enabled without rubrics');
it('rejects rubric sum different from max_points');
it('rejects min_points greater than max_points');
it('accepts non-scoring definitions without rubrics');
it('persists event and rubrics in one transaction');
it('rolls back the event when rubric persistence fails');
it('uses the same validator from the legacy rubric endpoint before competitive freeze');
it('rejects the legacy rubric endpoint after competitive freeze');
```

Run:

```bash
cd .worktrees/backend-camporee-operational-scoring
pnpm exec jest src/camporee-events/validation/camporee-scoring-definition.validator.spec.ts src/camporee-events/camporee-events.service.spec.ts src/camporee-events/camporee-events.controller.spec.ts src/camporee-event-templates/camporee-event-templates.service.spec.ts --runInBand
```

Expected: FAIL por ausencia del validador/atomicidad.

**Step 2: Definir el input compartido**

```ts
export type CamporeeScoringDefinition = {
  scoring_enabled: boolean;
  min_points: number;
  max_points: number;
  rubrics: Array<{
    title: string;
    description?: string;
    max_points: number;
    display_order: number;
  }>;
};
```

Agregar `rubrics` anidado a create/update de eventos. Templates siguen usando el mismo shape. El validador será una función TypeScript pura, sin `@Injectable`, imports Nest ni wiring de módulos; ambos servicios la importan directamente para evitar ciclos. Los templates ya son transaccionales: conservar esa transacción y sólo sustituir sus reglas duplicadas por el validador compartido.

**Step 3: Hacer atómicos create/update**

Los eventos (no sólo los templates) usan una única `prisma.$transaction(async tx => ...)` para create/update + rúbricas. El endpoint legado `PUT /camporee-events/:eventId/rubrics` permanece temporalmente, llama al mismo validador y deja de exigir inscripción cerrada; sólo se permite antes del freeze competitivo.

**Step 4: Probar y validar**

Run:

```bash
cd .worktrees/backend-camporee-operational-scoring
pnpm exec jest src/camporee-events/validation/camporee-scoring-definition.validator.spec.ts src/camporee-events/camporee-events.service.spec.ts src/camporee-events/camporee-events.controller.spec.ts src/camporee-event-templates/camporee-event-templates.service.spec.ts --runInBand
```

Expected: PASS, incluida reversión simulada.

### Task 4: Congelar datos competitivos y cerrar referencias cross-scope

**Files:**
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/camporee-scoring.controller.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/camporee-scoring.service.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/dto/camporee-scoring.dto.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporee-events/camporee-events.service.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporee-events/camporee-events.controller.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporee-events/dto/camporee-events.dto.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporee-event-templates/camporee-event-templates.service.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporee-venues/camporee-venues.service.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporee-staff/camporee-staff.service.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/prisma/schema.prisma`
- Create: `.worktrees/backend-camporee-operational-scoring/prisma/migrations/20260709115000_camporee_operational_versions/migration.sql`
- Test: `.worktrees/backend-camporee-operational-scoring/src/camporee-events/camporee-events.service.spec.ts`
- Test: `.worktrees/backend-camporee-operational-scoring/src/camporee-events/camporee-events.controller.spec.ts`
- Test: `.worktrees/backend-camporee-operational-scoring/src/camporee-event-templates/camporee-event-templates.service.spec.ts`
- Test: `.worktrees/backend-camporee-operational-scoring/src/camporee-venues/camporee-venues.service.spec.ts`
- Test: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/camporee-scoring.service.spec.ts`
- Test: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/camporee-scoring.controller.spec.ts`

**Step 1: Agregar tests de freeze y tenant isolation**

```ts
it('returns not found when cloning a template outside destination visibility');
it('rejects a venue from another camporee');
it('rejects responsible users outside the camporee roster');
it('rejects judge candidates who are not pastors, adults or invested Master Guides');
it('derives camporee_club_id instead of trusting client input');
it('rejects competitive updates after camporee start');
it('rejects competitive updates after the first official result');
it('allows audited schedule and judge updates while in progress');
it('rejects an operational update with a stale expected_version');
it('applies a bulk judge assignment atomically or not at all');
it('rejects a second active primary judge for the same event and section');
it('returns 404 for scoring targets, venue, template or roster IDs outside event scope');
```

Expected security behavior: referencias fuera de scope responden `404` cuando revelar existencia sería una fuga; estados inválidos propios responden `409`/`422`.

**Step 2: Ejecutar tests y confirmar fallo**

Run:

```bash
cd .worktrees/backend-camporee-operational-scoring
pnpm exec jest src/camporee-events/camporee-events.service.spec.ts src/camporee-events/camporee-events.controller.spec.ts src/camporee-event-templates/camporee-event-templates.service.spec.ts src/camporee-venues/camporee-venues.service.spec.ts src/camporee-scoring/camporee-scoring.service.spec.ts src/camporee-scoring/camporee-scoring.controller.spec.ts --runInBand
```

Expected: FAIL en los casos nuevos.

**Step 3: Implementar guards de dominio**

Separar campos en:

```ts
const COMPETITIVE_FIELDS = [
  'scoring_enabled', 'min_points', 'max_points', 'rubrics',
  'sections', 'participants_mode', 'participants_count',
];
const OPERATIONAL_FIELDS = [
  'day_number', 'starts_at', 'ends_at', 'venue_id',
  'schedule_blocks', 'staff_assignments', 'status',
];
```

El servicio debe consultar lifecycle y existencia de resultado activo antes de aceptar cambios competitivos. Validar `scoring_enabled`, y resolver template, venue, roster, juez y targets de scoring contra el camporee/evento destino; IDs cross-scope responden `404`, mientras un estado inválido del recurso propio responde `409`/`422`. Nunca aceptar `camporee_club_id` calculable desde el cliente: derivarlo desde la inscripción/sección ya validada.

Agregar `version` a eventos y asignaciones. PATCH de evento y PATCH individual de asignación reciben `expected_version` y devuelven `409 CAMPOREE_CONFIGURATION_STALE` si cambió. Agregar el índice parcial único de DB para una asignación primaria activa por `(camporee_event_id, club_section_id)`.

Crear `POST /camporee-events/:eventId/judge-assignments:bulk` con body `{ expected_event_version, operations }`. Dentro de una transacción: bloquear el evento, comprobar CAS de su versión, prevalidar por completo todas las operaciones (principal único, elegibilidad, `scoring_enabled`, freeze competitivo, roster y scope) y sólo entonces escribir todas las asignaciones e incrementar la versión. El resultado es all-or-nothing; no reutilizar el `PUT` legado como si fuera atómico.

**Step 4: Ejecutar pruebas focalizadas**

Run: el mismo comando del Step 2.

Expected: PASS.

### Task 5a: Formalizar permisos de scoring

**Files:**
- Create: `.worktrees/backend-camporee-operational-scoring/prisma/migrations/20260709120000_camporee_scoring_permissions/migration.sql`
- Modify: `.worktrees/backend-camporee-operational-scoring/prisma/seeds/permissions.seed.sql`
- Modify: `.worktrees/backend-camporee-operational-scoring/prisma/seeds/role-permissions.seed.sql`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/camporee-scoring.controller.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/camporee-scoring.service.ts`
- Test: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/camporee-scoring.controller.spec.ts`
- Test: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/camporee-scoring.service.spec.ts`
- Test: `.worktrees/backend-camporee-operational-scoring/src/common/guards/permissions-metadata.spec.ts`
- Modify docs: `docs/api/SECURITY-GUIDE.md`

**Step 1: Escribir tests de metadata y deny-by-default**

Verificar que:

```text
POST /camporee-events/:eventId/sections/:clubSectionId/scores -> metadata `mode: any` con `camporee_scores:submit|camporee_scores:override` y resource del evento
source judge_primary -> camporee_scores:submit
source manual_lf|admin_override -> camporee_scores:override
```

Un usuario con sólo `camporee_events:update` no puede modificar puntajes.

**Step 2: Ejecutar tests y confirmar fallo**

Run:

```bash
cd .worktrees/backend-camporee-operational-scoring
pnpm exec jest src/camporee-scoring/camporee-scoring.controller.spec.ts src/common/guards/permissions-metadata.spec.ts --runInBand
```

Expected: FAIL porque el único POST de scores aún depende de permisos de eventos o carece de metadata explícita y la autorización de servicio por `source`.

**Step 3: Sembrar permisos idempotentes y asignarlos por rol**

- Sembrar `camporee_scores:submit` para `user`/`pastor`; el servicio mantiene como condiciones obligatorias la elegibilidad y asignación primaria exacta.
- Sembrar `camporee_scores:override` para roles LF, Unión y administradores según el contrato de scope.
- El controller declara ambos permisos en modo `any` sobre el recurso evento para que el guard no bloquee prematuramente el único POST.
- Después, el servicio exige `submit` para `judge_primary` y `override` para `manual_lf`/`admin_override`, además de rol, asignación y scope. El permiso nunca sustituye la validación de resource scope.

Los permisos y endpoints de penalizaciones no se declaran ni se documentan en esta task; se incorporan como Task 5b junto con el ledger y rutas realmente creadas.

**Step 4: Ejecutar pruebas**

Run: comando del Step 2 y `pnpm exec jest src/camporee-scoring/camporee-scoring.service.spec.ts --runInBand` y `pnpm exec prisma validate`.

Expected: PASS.

### Checkpoint 1

Detenerse y reportar:

- lifecycle/timezone y migraciones añadidas;
- atomicidad evento/template;
- pruebas de freeze e IDOR;
- matriz final de permisos de scoring (Task 5a), sin permisos de penalizaciones todavía;
- resultado exacto de Jest/Prisma;
- riesgo de compatibilidad del endpoint legado de rúbricas.

---

## Batch 2 — Scoring temporal, resultados y penalizaciones

### Task 6: Aplicar ventana horaria y totales explicables

**Files:**
- Create: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/camporee-scoring-window.service.ts`
- Create: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/camporee-scoring-window.service.spec.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/camporee-scoring.service.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/dto/camporee-scoring.dto.ts`
- Test: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/camporee-scoring.service.spec.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/prisma/schema.prisma`
- Create: `.worktrees/backend-camporee-operational-scoring/prisma/migrations/20260709130000_camporee_score_window/migration.sql`
- Modify mirror: `docs/database/schema.prisma`

**Step 1: Escribir tests temporales y de total**

Cubrir:

```ts
it('rejects judge submission before event starts');
it('rejects judge submission after event ends');
it('accepts judge submission at inclusive window boundaries');
it('rejects judge scoring when schedule is incomplete');
it('allows authorized override outside the window with reason');
it('returns raw_total, minimum_adjustment and official_total');
it('keeps rubric item sum equal to raw_total');
```

Usar reloj fijo y casos cerca de medianoche en `America/Mexico_City`.

**Step 2: Confirmar fallo**

Run:

```bash
cd .worktrees/backend-camporee-operational-scoring
pnpm exec jest src/camporee-scoring/camporee-scoring-window.service.spec.ts src/camporee-scoring/camporee-scoring.service.spec.ts --runInBand
```

Expected: FAIL.

**Step 3: Implementar campos y cálculo**

Reutilizar `raw_awarded_points` y `minimum_adjustment_points` creados en Task 1.1; agregar a submission/result según corresponda:

```text
window_started_at_snapshot
window_ended_at_snapshot
override_reason
```

Mantener `total_awarded` sólo como alias de lectura temporal si consumidores existentes lo requieren. El porcentaje se deriva de `official_total / max_points`; no reemplaza los límites absolutos.

**Step 4: Probar y validar schema**

Run:

```bash
cd .worktrees/backend-camporee-operational-scoring
pnpm exec jest src/camporee-scoring/camporee-scoring-window.service.spec.ts src/camporee-scoring/camporee-scoring.service.spec.ts --runInBand
pnpm exec prisma validate
```

Expected: PASS.

### Task 7: Limitar targets, guardar presencia y exponer resultado autorizado

**Files:**
- Modify: `.worktrees/backend-camporee-operational-scoring/prisma/schema.prisma`
- Create: `.worktrees/backend-camporee-operational-scoring/prisma/migrations/20260709133000_camporee_representative_presence/migration.sql`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/dto/camporee-scoring.dto.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/camporee-scoring.service.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/camporee-scoring.controller.ts`
- Test: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/camporee-scoring.service.spec.ts`
- Test: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/camporee-scoring.controller.spec.ts`

**Step 1: Escribir tests fallidos de least privilege**

```ts
it('lists only sections assigned to the current primary judge');
it('does not expose all event targets to an assigned judge');
it('marks director_present with actor and timestamp');
it('allows subdirector result access only after director absence is recorded');
it('allows section director to read score, rubric notes and global comment');
it('denies result access to unrelated club members');
```

**Step 2: Ejecutar tests y confirmar fallo**

Run:

```bash
cd .worktrees/backend-camporee-operational-scoring
pnpm exec jest src/camporee-scoring/camporee-scoring.service.spec.ts src/camporee-scoring/camporee-scoring.controller.spec.ts --runInBand
```

Expected: FAIL.

**Step 3: Implementar presencia y endpoints**

Contrato mínimo:

```ts
type RepresentativePresence =
  | 'director_present'
  | 'director_absent_subdirector_authorized';
```

Agregar endpoints resource-scoped:

```text
PUT /camporee-events/:eventId/sections/:clubSectionId/representative-presence
GET /camporee-events/:eventId/sections/:clubSectionId/result
```

La respuesta de resultado incluye score oficial, estado, comentario global, notas por rúbrica, actor y timestamps; no expone datos internos de otros clubes.

**Step 4: Ejecutar pruebas**

Run: comando del Step 2 y `pnpm exec prisma validate`.

Expected: PASS.

### Task 7.1: Crear solicitudes de aclaración sin mutar el resultado

**Files:**
- Modify: `.worktrees/backend-camporee-operational-scoring/prisma/schema.prisma`
- Create: `.worktrees/backend-camporee-operational-scoring/prisma/migrations/20260709135000_camporee_score_clarifications/migration.sql`
- Create: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/dto/camporee-score-clarifications.dto.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/dto/index.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/camporee-scoring.service.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/camporee-scoring.controller.ts`
- Test: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/camporee-scoring.service.spec.ts`
- Test: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/camporee-scoring.controller.spec.ts`

**Steps:**
1. Escribir tests RED: director/subdirector autorizado abre aclaración sobre resultado de su sección; usuario ajeno falla; juez/gestor responde; sólo gestor resuelve/rechaza; ninguna transición cambia puntos.
2. Modelar `camporee_score_clarifications` y eventos append-only con estados `open | answered | resolved | rejected`, referencia inmutable al result/submission y actores/timestamps.
3. Exponer create/list/detail/respond/resolve con scope de resultado. Un cambio de puntos sólo puede enlazar un override existente.
4. Ejecutar Jest focalizado y `prisma validate`; actualizar docs API/seguridad/feature en esta task.

### Task 5b (Batch 2): Crear ledger, rutas reales y permisos de penalizaciones tardías

**Files:**
- Modify: `.worktrees/backend-camporee-operational-scoring/prisma/schema.prisma`
- Create: `.worktrees/backend-camporee-operational-scoring/prisma/migrations/20260709140000_camporee_penalty_ledger/migration.sql`
- Create: `.worktrees/backend-camporee-operational-scoring/src/camporee-penalties/camporee-penalties.module.ts`
- Create: `.worktrees/backend-camporee-operational-scoring/src/camporee-penalties/camporee-penalties.controller.ts`
- Create: `.worktrees/backend-camporee-operational-scoring/src/camporee-penalties/camporee-penalties.controller.spec.ts`
- Create: `.worktrees/backend-camporee-operational-scoring/src/camporee-penalties/camporee-penalties.service.ts`
- Create: `.worktrees/backend-camporee-operational-scoring/src/camporee-penalties/camporee-penalties.service.spec.ts`
- Create: `.worktrees/backend-camporee-operational-scoring/src/camporee-penalties/dto/camporee-penalties.dto.ts`
- Create: `.worktrees/backend-camporee-operational-scoring/src/camporee-penalties/dto/index.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/app.module.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporees/camporee-late-approvals.service.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporees/camporees.controller.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/prisma/seeds/permissions.seed.sql`
- Modify: `.worktrees/backend-camporee-operational-scoring/prisma/seeds/role-permissions.seed.sql`
- Test: `.worktrees/backend-camporee-operational-scoring/src/camporees/camporees.service.spec.ts`
- Test: `.worktrees/backend-camporee-operational-scoring/src/camporees/camporee-late-approvals.service.spec.ts`
- Test: `.worktrees/backend-camporee-operational-scoring/src/common/guards/permissions-metadata.spec.ts`
- Modify mirror: `docs/database/schema.prisma`

**Step 1: Escribir tests del ledger antes del schema/service**

```ts
it('requires an active point-deduction rule for late approval');
it('approves enrollment and creates penalty application atomically');
it('creates one negative score adjustment per late request');
it('does not create a financial charge when financial_enabled is false');
it('creates fixed or percentage charge when enabled');
it('is idempotent for the same late request');
it('voids by reversal instead of rewriting history');
it('rejects rules and approvals outside actor scope');
it('does not advertise or protect a penalty endpoint before its route is created');
it('requires camporee_penalties:configure only on created rule routes');
it('requires camporee_penalties:approve on existing late-approval routes');
```

No inventar un monto de puntos global. Si un camporee no tiene regla activa, una aprobación tardía debe fallar con error explícito hasta que Campo Local/Unión configure la deducción. Actualmente las aprobaciones tardías existen en `camporees.controller.ts`; las rutas de reglas de penalización no existen todavía. Esta task debe crear y documentar las rutas exactas antes de aplicar metadata, sin describirlas como contratos ya disponibles.

**Step 2: Ejecutar tests y confirmar fallo**

Run:

```bash
cd .worktrees/backend-camporee-operational-scoring
pnpm exec jest src/camporee-penalties/camporee-penalties.service.spec.ts src/camporees/camporees.service.spec.ts --runInBand
```

Expected: FAIL.

**Step 3: Implementar tablas aditivas**

Modelos mínimos:

```text
camporee_penalty_rules
  scope + camporee_id + trigger
  points_deduction
  financial_enabled
  financial_mode fixed|percentage|null
  financial_value|null
  active + audit fields

camporee_penalty_applications
  request identity + rule snapshot + applied_by/at
  status active|voided + void reason/reference

camporee_score_adjustments
  club_section_id + signed_points + application_id
  status active|reversed + audit fields

camporee_financial_charges
  application_id + amount + currency + status
```

Aplicar CHECKs: `points_deduction > 0`; financial fields nulos cuando está desactivado; unicidad parcial para una aplicación activa por request. Crear la migración de permisos aquí (no en Task 5a), sembrar `camporee_penalties:configure` y `camporee_penalties:approve` de forma idempotente y asignarlos a LF/Unión/admin según scope.

**Step 4: Hacer atómica la aprobación tardía**

`camporee-late-approvals.service.ts` debe ejecutar aprobación, application, adjustment y charge en una transacción. El deadline calculado determina si es tardía; el cierre efectivo no debe impedir que un actor autorizado use el flujo especial. Proteger las rutas de aprobación tardía ya existentes con `camporee_penalties:approve`; al crear rutas de configuración de reglas, aplicar `camporee_penalties:configure` y metadata resource-scoped en el mismo cambio. No publicar referencias de API ni metadata para rutas inexistentes.

**Step 5: Ejecutar pruebas y Prisma**

Run:

```bash
cd .worktrees/backend-camporee-operational-scoring
pnpm exec jest src/camporee-penalties/camporee-penalties.service.spec.ts src/camporee-penalties/camporee-penalties.controller.spec.ts src/camporees/camporees.service.spec.ts --runInBand
pnpm exec prisma validate
```

Expected: PASS.

### Task 9: Ajustar leaderboard y ranking anual al total oficial

**Files:**
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/camporee-scoring.service.ts`
- Test: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/camporee-scoring.service.spec.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/annual-folders/score-calculators/camporee-score.ts`
- Test: `.worktrees/backend-camporee-operational-scoring/src/annual-folders/score-calculators/camporee-score.spec.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/annual-folders/rankings.service.ts`
- Test: `.worktrees/backend-camporee-operational-scoring/src/annual-folders/__tests__/rankings.service.spec.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/rankings/member-rankings/services/camporee-score.service.ts`
- Test: `.worktrees/backend-camporee-operational-scoring/src/rankings/member-rankings/services/camporee-score.service.spec.ts`

**Step 1: Escribir tests de la fórmula oficial**

```ts
expect(total({ results: [80, 70], adjustments: [-15] })).toBe(135);
expect(total({ results: [10], adjustments: [-20] })).toBe(0);
```

Agregar regresión que demuestre que inscripción/asistencia no produce puntos. Agregar caso para dos secciones del mismo club sin mezclar sus resultados.

**Step 2: Ejecutar tests y confirmar fallo**

Run:

```bash
cd .worktrees/backend-camporee-operational-scoring
pnpm exec jest src/camporee-scoring/camporee-scoring.service.spec.ts src/annual-folders/score-calculators/camporee-score.spec.ts src/annual-folders/__tests__/rankings.service.spec.ts src/rankings/member-rankings/services/camporee-score.service.spec.ts --runInBand
```

Expected: FAIL en ajustes/piso.

**Step 3: Implementar un único agregado reutilizable**

```text
official_camporee_points = max(
  0,
  sum(active official event results) + sum(active signed adjustments)
)
```

No duplicar la fórmula en cuatro servicios. Extraer query/mapper compartido o hacer que los rankings consuman un servicio único. Confirmar que `club_section_id` se selecciona explícitamente para evitar la regresión TypeScript ya observada.

**Step 4: Ejecutar pruebas**

Run: comando del Step 2.

Expected: PASS.

### Checkpoint 2

Detenerse y reportar:

- ventana temporal y estrategia timezone;
- shape final de receipt/result;
- tablas y constraints de penalizaciones;
- ejemplo de leaderboard con ajuste;
- tests exactos;
- migraciones aún no aplicadas.

---

## Batch 3 — Blueprints, documentos y lectura agregada

### Task 10: Implementar template completo de camporee

**Files:**
- Modify: `.worktrees/backend-camporee-operational-scoring/prisma/schema.prisma`
- Create: `.worktrees/backend-camporee-operational-scoring/prisma/migrations/20260709150000_camporee_blueprints/migration.sql`
- Create: `.worktrees/backend-camporee-operational-scoring/src/camporee-blueprints/camporee-blueprints.module.ts`
- Create: `.worktrees/backend-camporee-operational-scoring/src/camporee-blueprints/camporee-blueprints.controller.ts`
- Create: `.worktrees/backend-camporee-operational-scoring/src/camporee-blueprints/camporee-blueprints.service.ts`
- Create: `.worktrees/backend-camporee-operational-scoring/src/camporee-blueprints/camporee-blueprints.service.spec.ts`
- Create: `.worktrees/backend-camporee-operational-scoring/src/camporee-blueprints/dto/camporee-blueprints.dto.ts`
- Create: `.worktrees/backend-camporee-operational-scoring/src/camporee-blueprints/dto/index.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/app.module.ts`

**Step 1: Escribir tests del snapshot seguro**

```ts
it('saves club types, costs, penalty rules, relative deadlines and agenda');
it('saves event definitions, rubrics and day-based agenda');
it('does not copy enrollments, payments, scores or concrete user assignments');
it('stores operational roles as unresolved slots');
it('instantiates a camporee and all events atomically');
it('recalculates absolute deadlines from offsets and new start date');
it('rejects source or destination outside actor scope');
```

**Step 2: Ejecutar test y confirmar fallo**

Run:

```bash
cd .worktrees/backend-camporee-operational-scoring
pnpm exec jest src/camporee-blueprints/camporee-blueprints.service.spec.ts --runInBand
```

Expected: FAIL.

**Step 3: Implementar contratos y transacción**

Endpoints mínimos:

```text
POST /local-camporees/:camporeeId/blueprints
POST /union-camporees/:camporeeId/blueprints
GET  /camporee-blueprints?scope=...
POST /camporee-blueprints/:blueprintId/instantiate
```

`instantiate` recibe `start_date`, `end_date`, nombre y ubicación; aplica offsets y deja slots de jueces/personal sin resolver. Cambios futuros del blueprint no deben afectar el camporee creado. La copia de documentos se integra en la Task 11, una vez que existan assets reutilizables.

**Step 4: Ejecutar test y Prisma**

Run:

```bash
cd .worktrees/backend-camporee-operational-scoring
pnpm exec jest src/camporee-blueprints/camporee-blueprints.service.spec.ts --runInBand
pnpm exec prisma validate
```

Expected: PASS.

### Task 11: Implementar assets PDF reutilizables para templates y eventos

**Files:**
- Modify: `.worktrees/backend-camporee-operational-scoring/prisma/schema.prisma`
- Create: `.worktrees/backend-camporee-operational-scoring/prisma/migrations/20260709160000_camporee_document_assets/migration.sql`
- Create: `.worktrees/backend-camporee-operational-scoring/src/camporee-documents/camporee-documents.module.ts`
- Create: `.worktrees/backend-camporee-operational-scoring/src/camporee-documents/camporee-documents.controller.ts`
- Create: `.worktrees/backend-camporee-operational-scoring/src/camporee-documents/camporee-documents.controller.spec.ts`
- Create: `.worktrees/backend-camporee-operational-scoring/src/camporee-documents/camporee-documents.service.ts`
- Create: `.worktrees/backend-camporee-operational-scoring/src/camporee-documents/camporee-documents.service.spec.ts`
- Create: `.worktrees/backend-camporee-operational-scoring/src/camporee-documents/dto/camporee-documents.dto.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/common/services/r2-file-storage.service.ts`
- Test: `.worktrees/backend-camporee-operational-scoring/src/common/services/r2-file-storage.service.spec.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporee-blueprints/camporee-blueprints.service.ts`
- Test: `.worktrees/backend-camporee-operational-scoring/src/camporee-blueprints/camporee-blueprints.service.spec.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/app.module.ts`

**Step 1: Escribir tests de seguridad del archivo**

```ts
it('accepts a PDF only when MIME and %PDF signature match');
it('rejects a sixth active document');
it('generates object keys server-side');
it('returns short-lived signed URLs only to authorized readers');
it('rejects cross-scope event/template IDs');
it('soft-deletes an association without deleting a shared asset');
it('clones template document associations into an event snapshot');
it('preserves document associations when instantiating a camporee blueprint');
```

**Step 2: Ejecutar tests y confirmar fallo**

Run:

```bash
cd .worktrees/backend-camporee-operational-scoring
pnpm exec jest src/camporee-documents/camporee-documents.service.spec.ts src/camporee-documents/camporee-documents.controller.spec.ts src/common/services/r2-file-storage.service.spec.ts src/camporee-blueprints/camporee-blueprints.service.spec.ts --runInBand
```

Expected: FAIL.

**Step 3: Implementar assets y asociaciones**

Usar dos niveles:

```text
camporee_document_assets: immutable object metadata/hash/size
camporee_event_documents: exclusive event_id or template_id + asset_id + active/audit
```

No aceptar object keys o URLs suministradas por el cliente. Límite de tamaño configurable mediante config validada; no hardcodear secretos ni bucket URLs.

**Step 4: Ejecutar pruebas y Prisma**

Run: comando del Step 2 seguido de `pnpm exec prisma validate`.

Expected: PASS.

### Task 12: Crear endpoint agregado de configuración/readiness

**Files:**
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/camporee-scoring.controller.ts`
- Modify: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/camporee-scoring.service.ts`
- Test: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/camporee-scoring.service.spec.ts`
- Test: `.worktrees/backend-camporee-operational-scoring/src/camporee-scoring/camporee-scoring.controller.spec.ts`

**Step 1: Escribir test de una sola lectura**

Verificar que `GET /local-camporees/:id/scoring-configuration` y equivalente Unión devuelvan, con queries acotadas:

```ts
type ScoringConfiguration = {
  phase: CamporeePhase;
  effectiveRegistrationClosed: boolean;
  readiness: { ready: boolean; blockers: string[] };
  configurationVersion: number;
  liveOperations: {
    current: CamporeeEventSummary[];
    upcoming: CamporeeEventSummary[];
    missingPrimaryJudges: number;
    pendingScores: number;
    openClarifications: number;
  };
  judges: CamporeeJudge[];
  events: Array<{
    event: CamporeeEventSummary;
    rubrics: CamporeeEventRubric[];
    assignments: CamporeeEventJudgeAssignment[];
  }>;
};
```

**Step 2: Confirmar fallo**

Run:

```bash
cd .worktrees/backend-camporee-operational-scoring
pnpm exec jest src/camporee-scoring/camporee-scoring.service.spec.ts src/camporee-scoring/camporee-scoring.controller.spec.ts --runInBand
```

Expected: FAIL.

**Step 3: Implementar consulta agregada**

Evitar el fan-out admin de dos/tres requests por evento. Readiness bloquea inicio/publicación si existe evento puntuable sin horario, rúbricas válidas, targets, juez principal requerido o timezone verificado. `liveOperations` es un read model derivado; la primera entrega usa polling acotado y no requiere WebSocket/materialización.

**Step 4: Ejecutar pruebas**

Run: comando del Step 2.

Expected: PASS y aserción de número acotado de llamadas Prisma.

### Checkpoint 3

Detenerse y reportar blueprints, documentos, endpoint agregado, tests y cualquier decisión de almacenamiento R2. No avanzar al admin hasta estabilizar el contrato OpenAPI/manual.

---

## Batch 4 — Admin web

### Task 13: Aislar admin y agregar lifecycle/readiness/penalizaciones/blueprints

**Setup:**

```bash
git -C sacdia-admin fetch origin development
git -C sacdia-admin worktree add ../.worktrees/admin-camporee-operational-hardening -b codex/camporee-operational-hardening-admin origin/development
```

**Files:**
- Modify: `.worktrees/admin-camporee-operational-hardening/src/lib/api/camporees.ts`
- Modify: `.worktrees/admin-camporee-operational-hardening/src/lib/camporees/actions.ts`
- Modify: `.worktrees/admin-camporee-operational-hardening/src/components/camporees/camporee-form-dialog.tsx`
- Modify: `.worktrees/admin-camporee-operational-hardening/src/components/camporees/union-camporee-form-dialog.tsx`
- Create: `.worktrees/admin-camporee-operational-hardening/src/components/camporees/camporee-lifecycle-panel.tsx`
- Create: `.worktrees/admin-camporee-operational-hardening/src/components/camporees/camporee-lifecycle-panel.test.tsx`
- Create: `.worktrees/admin-camporee-operational-hardening/src/components/camporees/camporee-live-operations-panel.tsx`
- Create: `.worktrees/admin-camporee-operational-hardening/src/components/camporees/camporee-live-operations-panel.test.tsx`
- Create: `.worktrees/admin-camporee-operational-hardening/src/components/camporees/camporee-penalty-rules-panel.tsx`
- Create: `.worktrees/admin-camporee-operational-hardening/src/components/camporees/camporee-penalty-rules-panel.test.tsx`
- Create: `.worktrees/admin-camporee-operational-hardening/src/lib/api/camporee-blueprints.ts`
- Create: `.worktrees/admin-camporee-operational-hardening/src/lib/camporee-blueprints/actions.ts`
- Create: `.worktrees/admin-camporee-operational-hardening/src/components/camporees/camporee-blueprint-dialog.tsx`
- Create: `.worktrees/admin-camporee-operational-hardening/src/components/camporees/camporee-blueprint-dialog.test.tsx`
- Create: `.worktrees/admin-camporee-operational-hardening/src/components/camporees/camporee-blueprint-diff-preview.tsx`
- Create: `.worktrees/admin-camporee-operational-hardening/src/components/camporees/camporee-blueprint-diff-preview.test.tsx`
- Modify: `.worktrees/admin-camporee-operational-hardening/src/components/camporees/camporees-view.tsx`
- Modify: `.worktrees/admin-camporee-operational-hardening/src/components/camporees/union-camporees-view.tsx`
- Modify: `.worktrees/admin-camporee-operational-hardening/src/components/camporees/camporee-detail-tabs.tsx`
- Create: `.worktrees/admin-camporee-operational-hardening/src/components/camporees/camporee-detail-tabs.test.tsx`

**Step 1: Escribir tests de UX**

```text
- muestra timezone y deadlines con orden validado;
- distingue fase, cierre efectivo y cierre manual;
- muestra blockers de readiness antes de iniciar;
- muestra modo live sólo cuando backend devuelve phase=in_progress;
- live prioriza evento actual/próximo, jueces faltantes, scores pendientes y aclaraciones;
- exige points_deduction para habilitar aprobación tardía;
- recargo financiero inicia apagado;
- soporta fixed/percentage sólo al activarlo;
- permite guardar el camporee actual como blueprint sin datos vivos;
- permite crear desde blueprint solicitando fechas absolutas y mostrando slots sin resolver;
- obtiene el diff del blueprint desde backend y destaca datos vivos excluidos;
- respeta ?tab=events y otros tabs válidos;
- no transforma error API en estado vacío;
- usa role=alert/aria-live, foco visible y estados no dependientes sólo de color.
```

**Step 2: Ejecutar tests y confirmar fallo**

Run:

```bash
cd .worktrees/admin-camporee-operational-hardening
pnpm test -- src/components/camporees/camporee-lifecycle-panel.test.tsx src/components/camporees/camporee-penalty-rules-panel.test.tsx src/components/camporees/camporee-blueprint-dialog.test.tsx src/components/camporees/camporee-detail-tabs.test.tsx
```

Expected: FAIL.

**Step 3: Implementar contratos y paneles**

Usar estados explícitos `loading | error | empty | ready`. No usar UUIDs manuales ni ocultar errores de server actions. Deshabilitar acciones según capabilities devueltas por backend, no sólo comparando fechas del navegador. Mantener una sola navegación: el modo live vive bajo Eventos (`?tab=events&mode=live`).

**Step 4: Ejecutar tests y typecheck**

Run:

```bash
cd .worktrees/admin-camporee-operational-hardening
pnpm test -- src/components/camporees/camporee-lifecycle-panel.test.tsx src/components/camporees/camporee-penalty-rules-panel.test.tsx src/components/camporees/camporee-blueprint-dialog.test.tsx src/components/camporees/camporee-detail-tabs.test.tsx
pnpm typecheck
```

Expected: PASS. No ejecutar `pnpm build`.

### Task 14: Migrar formularios de evento/template al comando atómico y documentos

**Files:**
- Modify: `.worktrees/admin-camporee-operational-hardening/src/lib/api/camporee-events.ts`
- Modify: `.worktrees/admin-camporee-operational-hardening/src/lib/camporee-events/actions.ts`
- Modify: `.worktrees/admin-camporee-operational-hardening/src/components/camporee-events/event-form-page.tsx`
- Modify: `.worktrees/admin-camporee-operational-hardening/src/components/camporee-events/event-form-page.test.tsx`
- Modify: `.worktrees/admin-camporee-operational-hardening/src/components/camporee-events/event-template-form-page.tsx`
- Create: `.worktrees/admin-camporee-operational-hardening/src/components/camporee-events/event-template-form-page.test.tsx`
- Modify: `.worktrees/admin-camporee-operational-hardening/src/components/camporee-events/rubrics-editor.tsx`
- Modify: `.worktrees/admin-camporee-operational-hardening/src/components/camporee-events/rubrics-editor.test.tsx`
- Create: `.worktrees/admin-camporee-operational-hardening/src/components/camporee-events/event-documents-editor.tsx`
- Create: `.worktrees/admin-camporee-operational-hardening/src/components/camporee-events/event-documents-editor.test.tsx`

**Step 1: Escribir tests del flujo atómico**

```text
- envía evento + rubrics en una sola acción;
- no crea evento parcial si falla la respuesta;
- usa el mismo competitive definition en template e instancia;
- valida suma de rúbricas y min <= max antes de enviar;
- permite requisitos, desarrollo, materiales, auxiliares y penalizaciones del evento;
- lista/sube/elimina hasta cinco PDFs;
- no usa SelectItem value=""; usa un sentinel interno para "Sin sede";
- renderiza errores de backend junto al bloque que falló.
```

**Step 2: Ejecutar tests y confirmar fallo**

Run:

```bash
cd .worktrees/admin-camporee-operational-hardening
pnpm test -- src/components/camporee-events/event-form-page.test.tsx src/components/camporee-events/event-template-form-page.test.tsx src/components/camporee-events/rubrics-editor.test.tsx src/components/camporee-events/event-documents-editor.test.tsx
```

Expected: FAIL.

**Step 3: Eliminar la sincronización post-create**

La acción create/update envía `rubrics` dentro del payload. No llamar después a `replaceCamporeeEventRubricsAction`. Mantener tipos compartidos entre event y template para evitar drift.

**Step 4: Implementar documentos**

Mostrar nombre, tamaño, estado y acciones. La UI nunca construye URLs R2 ni conserva signed URLs como datos permanentes.

**Step 5: Ejecutar tests y typecheck**

Run:

```bash
cd .worktrees/admin-camporee-operational-hardening
pnpm test -- src/components/camporee-events/event-form-page.test.tsx src/components/camporee-events/event-template-form-page.test.tsx src/components/camporee-events/rubrics-editor.test.tsx src/components/camporee-events/event-documents-editor.test.tsx
pnpm typecheck
```

Expected: PASS.

### Task 15: Completar jueces, overrides, no-show y resultados en admin

**Files:**
- Modify: `.worktrees/admin-camporee-operational-hardening/src/lib/api/camporee-scoring.ts`
- Modify: `.worktrees/admin-camporee-operational-hardening/src/lib/camporee-scoring/actions.ts`
- Modify: `.worktrees/admin-camporee-operational-hardening/src/components/camporee-scoring/camporee-judges-panel.tsx`
- Modify: `.worktrees/admin-camporee-operational-hardening/src/components/camporee-scoring/camporee-judges-panel.test.tsx`
- Modify: `.worktrees/admin-camporee-operational-hardening/src/components/camporee-scoring/event-judge-assignments-panel.tsx`
- Create: `.worktrees/admin-camporee-operational-hardening/src/components/camporee-scoring/event-judge-assignments-panel.test.tsx`
- Create: `.worktrees/admin-camporee-operational-hardening/src/components/camporee-scoring/judge-assignment-matrix.tsx`
- Create: `.worktrees/admin-camporee-operational-hardening/src/components/camporee-scoring/judge-assignment-matrix.test.tsx`
- Create: `.worktrees/admin-camporee-operational-hardening/src/components/camporee-scoring/camporee-clarifications-panel.tsx`
- Create: `.worktrees/admin-camporee-operational-hardening/src/components/camporee-scoring/camporee-clarifications-panel.test.tsx`
- Modify: `.worktrees/admin-camporee-operational-hardening/src/components/camporee-scoring/event-score-entry-panel.tsx`
- Modify: `.worktrees/admin-camporee-operational-hardening/src/components/camporee-scoring/event-score-entry-panel.test.tsx`
- Modify: `.worktrees/admin-camporee-operational-hardening/src/components/camporee-scoring/camporee-leaderboard.tsx`
- Modify: `.worktrees/admin-camporee-operational-hardening/src/components/camporee-scoring/camporee-leaderboard.test.tsx`

**Step 1: Escribir tests de flujo operativo**

```text
- selector de juez muestra foto, nombre, rol/cargo y búsqueda sin overflow;
- sólo lista candidatos elegibles devueltos por backend;
- permite editar/desactivar asignación con confirmación;
- permite asignación masiva evento × sección con preview de conflictos y expected_version;
- fallo en una celda revierte toda la operación masiva;
- sólo asigna jueces a eventos puntuables;
- no-show muestra el mínimo resultante antes de confirmar;
- override exige motivo y muestra la cadena histórica;
- receipt muestra raw, minimum_adjustment y official;
- leaderboard desglosa resultados y ajustes de penalización;
- aclaración permite solicitar/responder/resolver sin editar puntos;
- una falla parcial del endpoint agregado se muestra como error, no como lista vacía.
```

**Step 2: Ejecutar tests y confirmar fallo**

Run:

```bash
cd .worktrees/admin-camporee-operational-hardening
pnpm test -- src/components/camporee-scoring/camporee-judges-panel.test.tsx src/components/camporee-scoring/event-judge-assignments-panel.test.tsx src/components/camporee-scoring/event-score-entry-panel.test.tsx src/components/camporee-scoring/camporee-leaderboard.test.tsx
```

Expected: FAIL.

**Step 3: Implementar usando capabilities del API**

No inferir autoridad desde roles renderizados. El backend decide candidatos, `canSubmit`, `canOverride`, `canEditAssignment` y scope. Limitar el popover de usuarios con alto máximo y scroll interno. En desktop usar matriz con encabezados accesibles; en móvil, acordeón por evento y tarjetas por sección.

**Step 4: Ejecutar suite focalizada y typecheck**

Run:

```bash
cd .worktrees/admin-camporee-operational-hardening
pnpm test -- src/components/camporee-events src/components/camporee-scoring src/components/camporees/camporee-detail-tabs.test.tsx
pnpm typecheck
```

Expected: PASS. No build.

### Checkpoint 4

Detenerse y reportar worktree/branch admin, tests, typecheck, payload atómico, manejo de errores y evidencia del selector sin UUID/overflow.

---

## Batch 5 — App móvil

### Task 16: Crear bandeja de evaluaciones pendientes/completadas y receipt

**Setup:**

```bash
git -C sacdia-app fetch origin development
git -C sacdia-app worktree add ../.worktrees/app-camporee-operational-hardening -b codex/camporee-operational-hardening-app origin/development
```

**Files:**
- Modify: `.worktrees/app-camporee-operational-hardening/lib/features/camporees/domain/entities/camporee_judge_assignment.dart`
- Modify: `.worktrees/app-camporee-operational-hardening/lib/features/camporees/domain/entities/camporee_score_submission.dart`
- Create: `.worktrees/app-camporee-operational-hardening/lib/features/camporees/domain/entities/camporee_score_draft.dart`
- Create: `.worktrees/app-camporee-operational-hardening/lib/features/camporees/domain/entities/camporee_score_receipt.dart`
- Modify: `.worktrees/app-camporee-operational-hardening/lib/features/camporees/data/models/camporee_judge_assignment_model.dart`
- Create: `.worktrees/app-camporee-operational-hardening/lib/features/camporees/data/models/camporee_score_receipt_model.dart`
- Create: `.worktrees/app-camporee-operational-hardening/lib/features/camporees/data/models/camporee_score_draft_model.dart`
- Create: `.worktrees/app-camporee-operational-hardening/lib/features/camporees/data/datasources/camporee_score_draft_local_data_source.dart`
- Modify: `.worktrees/app-camporee-operational-hardening/lib/features/camporees/data/datasources/camporees_remote_data_source.dart`
- Modify: `.worktrees/app-camporee-operational-hardening/lib/features/camporees/data/repositories/camporees_repository_impl.dart`
- Modify: `.worktrees/app-camporee-operational-hardening/lib/features/camporees/domain/repositories/camporees_repository.dart`
- Modify: `.worktrees/app-camporee-operational-hardening/lib/features/camporees/presentation/providers/camporees_providers.dart`
- Modify: `.worktrees/app-camporee-operational-hardening/lib/features/camporees/presentation/views/judge_assignments_view.dart`
- Modify: `.worktrees/app-camporee-operational-hardening/lib/features/camporees/presentation/views/judge_score_entry_view.dart`
- Create: `.worktrees/app-camporee-operational-hardening/test/features/camporees/presentation/views/judge_assignments_view_test.dart`
- Create: `.worktrees/app-camporee-operational-hardening/test/features/camporees/presentation/views/judge_score_entry_view_test.dart`
- Create: `.worktrees/app-camporee-operational-hardening/test/features/camporees/data/datasources/camporee_score_draft_local_data_source_test.dart`
- Modify: `.worktrees/app-camporee-operational-hardening/test/features/camporees/data/datasources/camporees_remote_data_source_test.dart`
- Modify: `.worktrees/app-camporee-operational-hardening/test/features/camporees/data/repositories/camporees_repository_impl_test.dart`

**Step 1: Escribir tests fallidos**

```text
- separa pendientes y completadas;
- no ofrece "Calificar" en completadas o fuera de ventana;
- entrada de navegación sólo aparece cuando hay assignments/capability;
- permite notas por rúbrica y comentario global;
- no-show pide confirmación irreversible y muestra mínimo;
- submit normal pide confirmación irreversible;
- receipt muestra bruto, ajuste, oficial, actor y fecha;
- guarda draft cifrado scopeado por usuario/grant/evento/sección;
- timeout conserva pending y la misma Idempotency-Key;
- sincroniza en serie al recuperar conectividad/foreground/reintento manual;
- 403 purga payload; 409 stale/finalized no reintenta silenciosamente;
- sólo marca synced después del receipt del servidor.
```

**Step 2: Ejecutar tests y confirmar fallo**

Run:

```bash
cd .worktrees/app-camporee-operational-hardening
flutter test test/features/camporees/data/datasources/camporees_remote_data_source_test.dart test/features/camporees/data/repositories/camporees_repository_impl_test.dart test/features/camporees/presentation/views/judge_assignments_view_test.dart test/features/camporees/presentation/views/judge_score_entry_view_test.dart
```

Expected: FAIL.

**Step 3: Implementar contrato y navegación discoverable**

El estado de assignment viene del backend: `pending | completed | outside_window`. No ocultar completadas; mostrarlas read-only con acceso al receipt. El botón principal sólo se habilita con `can_submit=true`.

Usar `flutter_secure_storage` y `connectivity_plus` ya instalados; no agregar Hive/SQLite ni background workers en v1. Estados locales: `draft | pending | syncing | synced | failed`. El reloj local no autoriza: un draft enviado después de ventana falla y requiere override.

**Step 4: Ejecutar tests y analyze focalizado**

Run:

```bash
cd .worktrees/app-camporee-operational-hardening
flutter test test/features/camporees
flutter analyze lib/features/camporees
```

Expected: PASS y `No issues found`. No ejecutar build Flutter.

### Task 17: Mostrar resultado a director/subdirector según presencia

**Files:**
- Create: `.worktrees/app-camporee-operational-hardening/lib/features/camporees/domain/entities/camporee_event_result.dart`
- Create: `.worktrees/app-camporee-operational-hardening/lib/features/camporees/data/models/camporee_event_result_model.dart`
- Modify: `.worktrees/app-camporee-operational-hardening/lib/features/camporees/data/datasources/camporees_remote_data_source.dart`
- Modify: `.worktrees/app-camporee-operational-hardening/lib/features/camporees/data/repositories/camporees_repository_impl.dart`
- Modify: `.worktrees/app-camporee-operational-hardening/lib/features/camporees/domain/repositories/camporees_repository.dart`
- Modify: `.worktrees/app-camporee-operational-hardening/lib/features/camporees/presentation/providers/camporees_providers.dart`
- Create: `.worktrees/app-camporee-operational-hardening/lib/features/camporees/presentation/views/camporee_event_result_view.dart`
- Create: `.worktrees/app-camporee-operational-hardening/lib/features/camporees/presentation/views/camporee_score_clarification_view.dart`
- Modify: `.worktrees/app-camporee-operational-hardening/lib/features/camporees/presentation/views/camporee_detail_view.dart`
- Modify: `.worktrees/app-camporee-operational-hardening/lib/core/config/route_names.dart`
- Modify: `.worktrees/app-camporee-operational-hardening/lib/core/config/router.dart`
- Create: `.worktrees/app-camporee-operational-hardening/test/features/camporees/presentation/views/camporee_event_result_view_test.dart`
- Create: `.worktrees/app-camporee-operational-hardening/test/features/camporees/presentation/views/camporee_score_clarification_view_test.dart`

**Step 1: Escribir tests de visibilidad**

```text
- director de sección ve resultado y comentarios;
- subdirector no ve resultado si el director está presente;
- subdirector ve resultado cuando backend autoriza por ausencia;
- usuario ajeno muestra estado forbidden, no datos parciales;
- no-show se distingue visualmente del score normal;
- desglose muestra rúbricas, notas y ajuste mínimo.
- director/subdirector autorizado solicita aclaración sin alterar el resultado;
- una corrección sólo aparece cuando existe override resuelto por gestor.
```

**Step 2: Ejecutar tests y confirmar fallo**

Run:

```bash
cd .worktrees/app-camporee-operational-hardening
flutter test test/features/camporees/presentation/views/camporee_event_result_view_test.dart
```

Expected: FAIL.

**Step 3: Implementar vista resource-driven**

La app no calcula si el usuario es director/subdirector. Solicita el resultado y renderiza según `can_view`/respuesta autorizada. No cachear resultados de otra sección al cambiar de usuario o club activo.

**Step 4: Ejecutar tests y analyze**

Run:

```bash
cd .worktrees/app-camporee-operational-hardening
flutter test test/features/camporees
flutter analyze lib/features/camporees lib/core/config/router.dart
```

Expected: PASS.

### Checkpoint 5

Detenerse y reportar tests/analyze, rutas añadidas, estados pendientes/completados, no-show/receipt y matriz director/subdirector.

---

## Batch 6 — Documentación, regresión y seguridad de suministro

### Task 18: Reconciliar documentación canónica y decisiones diferidas

**Files:**
- Modify: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- Modify: `docs/api/FRONTEND-INTEGRATION-GUIDE.md`
- Modify: `docs/api/SECURITY-GUIDE.md`
- Modify: `docs/api/ARCHITECTURE-DECISIONS.md`
- Modify: `docs/database/schema.prisma`
- Modify: `docs/database/SCHEMA-REFERENCE.md`
- Modify: `docs/features/camporees.md`
- Modify: `docs/features/camporee-events.md`
- Modify: `docs/plans/2026-07-09-camporee-operational-hardening-design.md`

**Step 1: Confirmar que cada checkpoint ya documentó sus contratos**

Incluir:

- lifecycle y mutability matrix;
- payload atómico evento/template;
- blueprints de camporee y exclusiones de datos vivos;
- permisos y resource scope;
- scoring window, no-show, receipt y resultados;
- ledger de penalizaciones/recargos;
- fórmula de leaderboard/ranking;
- PDFs privados y signed URLs;
- códigos de error relevantes (`403`, `404`, `409`, `422`).
- idempotencia, locks, expected versions y drafts offline.

Registrar explícitamente como diferidos: realtime push, QR operativo, sincronización móvil en background, SLA/adjuntos de aclaraciones y materialización del read model. No implementarlos antes de validar el scoring autoritativo.

**Step 2: Verificar que docs y rutas coinciden**

Run:

```bash
rg -n "camporee_scores:submit|camporee_scores:override|camporee_penalties:configure|camporee_penalties:approve" docs .worktrees/backend-camporee-operational-scoring/src
rg -n "scoring-configuration|representative-presence|camporee-blueprints|camporee-documents" docs .worktrees/backend-camporee-operational-scoring/src
```

Expected: cada endpoint/permiso implementado aparece en docs y no quedan rutas documentadas inexistentes.

### Task 19: Ejecutar regresión focalizada y triage de dependencias

**Files:**
- Update only if verified: `docs/audit/2026-07-09-camporee-flow-security-review.md`
- Do not modify dependency files in this feature batch unless a reachable vulnerability has a safe isolated patch.

**Step 1: Backend**

Run:

```bash
cd .worktrees/backend-camporee-operational-scoring
pnpm exec prisma validate
pnpm exec jest src/camporees src/camporee-events src/camporee-event-templates src/camporee-scoring src/camporee-penalties src/camporee-blueprints src/camporee-documents src/annual-folders/score-calculators/camporee-score.spec.ts src/annual-folders/__tests__/rankings.service.spec.ts --runInBand
```

Expected: PASS. Si Jest no acepta directorios combinados, ejecutar los specs exactos listados por batch.

**Step 2: Admin**

Run:

```bash
cd .worktrees/admin-camporee-operational-hardening
pnpm test -- src/components/camporee-events src/components/camporee-scoring src/components/camporees
pnpm typecheck
```

Expected: PASS.

**Step 3: App**

Run:

```bash
cd .worktrees/app-camporee-operational-hardening
flutter test test/features/camporees
flutter analyze lib/features/camporees
```

Expected: PASS.

**Step 4: Revisar el diff**

Run:

```bash
git diff --check
git -C .worktrees/backend-camporee-operational-scoring diff --check
git -C .worktrees/admin-camporee-operational-hardening diff --check
git -C .worktrees/app-camporee-operational-hardening diff --check
```

Expected: sin errores de whitespace.

**Step 5: Triage de supply chain separado**

Ejecutar `pnpm audit --audit-level=high` en backend/admin, identificar si Next/Better Auth/xlsx/form-data/ws son alcanzables en producción y crear un plan de upgrade separado. No mezclar upgrades mayores ni regeneraciones masivas de lockfile con este feature.

### Final checkpoint

Reportar:

- archivos por repo;
- migraciones creadas y estado de aplicación;
- endpoints/permisos finales;
- pruebas, typecheck y analyze exactos;
- riesgos residuales;
- diferencias contra `origin/development` y estrategia de integración.

No commitear, mergear ni pushar hasta que el usuario lo solicite explícitamente.
