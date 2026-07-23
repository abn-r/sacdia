# Institutional History Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implementar en SACDIA un histórico institucional transversal que preserve nombres, relaciones, linaje, atribución oficial, autorización histórica y gobernanza de datos sensibles sin reinterpretar el pasado.

**Architecture:** Mantener las tablas institucionales y sus FKs como proyección vigente; agregar versiones efectivas y bitemporales, comandos de reorganización transaccionales, auditoría obligatoria, snapshots inmutables en raíces oficiales y políticas de acceso separadas para historia no sensible y datos sensibles. La adopción será incremental mediante PRs encadenados; ningún módulo podrá cerrar un acto oficial sin fijar o heredar su contexto institucional.

**Tech Stack:** PostgreSQL, Prisma 7, NestJS 11, TypeScript 6, Jest/Supertest, Next.js 16/Vitest, Flutter/Riverpod/Dio/flutter_test.

---

## Fuente de verdad y límites

- ADR aprobado: `docs/plans/2026-07-23-institutional-history-architecture-decision.md`.
- Decisión canónica: `docs/canon/decisiones-clave.md` §25.
- Schema runtime: `sacdia-backend/prisma/schema.prisma`.
- No se adopta event sourcing global.
- No se reemplazan `divisions`, `unions`, `local_fields`, `districts`,
  `churches` ni `clubs` por un `organization_node`.
- No se exige evidencia, adjunto ni número de resolución. La fuente almacenada
  será `WORLD_CHURCH_EXECUTIVE`.
- No se ejecutarán builds. La verificación usa tests, validación de Prisma,
  lint dirigido, typecheck y analyze.
- El checkout actual contiene cambios ajenos. Cada PR debe implementarse en un
  worktree limpio creado desde `origin/development`.

## Brechas verificadas que condicionan la implementación

1. `InstitutionalHierarchyService.resolveAsOf()` une relaciones históricas con
   nombres actuales.
2. Una ausencia de historia activa un fallback silencioso a la jerarquía actual
   con precisión `unknown`.
3. Solo `union -> division` actualiza su historial desde el CRUD geográfico.
4. Campo local, distrito e iglesia cambian sus FKs directamente.
5. `clubs` inicializa su relación sin crear `club_institutional_history`; la
   auditoría actual es fire-and-forget.
6. `users_roles` no conserva período ni scope territorial del cargo. El scope
   global se deriva de `users.union_id` y `users.local_field_id` vigentes.
7. `canAccessHierarchyScope(..., 'historical-read')` aplica en la práctica la
   misma regla que la lectura actual.
8. Los subrecursos sensibles aceptan propietario o permisos globales; una
   asignación activa de sección no concede acceso contextual.
9. `hierarchy_contexts` puede modificarse o eliminarse y sus referencias
   oficiales usan `ON DELETE SET NULL`.
10. Carpetas anuales y rankings ya usan snapshots; el resto de los actos
    oficiales todavía resuelve jerarquía vigente o no fija contexto.

## Invariantes de implementación

1. Toda fecha efectiva usa intervalos `[valid_from, valid_to)`.
2. Toda consulta oficial `as_of` falla cerrada si no existe historia; nunca usa
   la proyección vigente como sustituto.
3. Toda revisión vigente de una relación o nombre tiene
   `recorded_to IS NULL`; las revisiones anteriores permanecen consultables.
4. La proyección vigente coincide con exactamente una revisión efectiva que
   cubre `CURRENT_DATE`; una revisión futura abierta todavía no es la proyección.
5. Ningún comando crítico confirma si falla relación, proyección, snapshot o
   auditoría.
6. Los snapshots y emisiones son inmutables a nivel de base de datos.
7. Un snapshot no contiene salud, contacto de emergencia, representante legal,
   documentos privados ni payload sensible.
8. La autoridad anterior solo lee registros no sensibles creados dentro de su
   período; nunca obtiene escritura.
9. La nueva autoridad puede leer la trayectoria no sensible completa de la
   entidad que administra actualmente.
10. Un permiso sensible es necesario, pero NUNCA suficiente sin relación,
    finalidad, scope y vigencia.

## Estrategia de entrega

El cambio excede ampliamente 400 líneas y cruza tres repos. Debe entregarse en
PRs encadenados:

1. **PR 1 — Base temporal e integridad**: schema, migración, resolver y auditoría.
2. **PR 2 — Comandos, linaje y API**: reorganizaciones, write paths y consultas.
3. **PR 3 — Autorización histórica y datos sensibles**.
4. **PR 4 — Snapshots y emisiones oficiales, oleada A**.
5. **PR 5 — Cobertura de agregados restante, oleada B**.
6. **PR 6 — Admin y app móvil**, después de estabilizar el contrato backend.

Cada PR parte del anterior, tiene tests propios y actualiza la documentación
canónica que modifica. No mezclar remediaciones ajenas.

---

## PR 1 — Base temporal e integridad

### Task 1: Congelar el contrato temporal con pruebas puras

**Files:**
- Create: `sacdia-backend/src/institutional-history/domain/temporal-interval.policy.ts`
- Test: `sacdia-backend/src/institutional-history/domain/temporal-interval.policy.spec.ts`
- Create: `sacdia-backend/src/institutional-history/domain/institutional-history.types.ts`

**Step 1: Escribir tests que fallen**

Cubrir:

- `[from, to)` incluye `from` y excluye `to`;
- `valid_to <= valid_from` es inválido;
- precisión solo admite `exact`, `day`, `month`, `year`,
  `system_backfill`, `unknown`;
- una corrección crea una nueva revisión y no muta la revisión anterior;
- el parser de fecha rechaza timestamps en comandos que requieren `YYYY-MM-DD`.

**Step 2: Ejecutar el test y confirmar RED**

Run:

```bash
cd sacdia-backend
pnpm test -- --runInBand src/institutional-history/domain/temporal-interval.policy.spec.ts
```

Expected: FAIL porque la política todavía no existe.

**Step 3: Implementar la política mínima**

Definir tipos compartidos:

```ts
type InstitutionalEntityType =
  | 'division'
  | 'union'
  | 'local_field'
  | 'district'
  | 'church'
  | 'club';

type HistoricalPrecision =
  | 'exact'
  | 'day'
  | 'month'
  | 'year'
  | 'system_backfill'
  | 'unknown';
```

No incluir acceso a Prisma en esta capa.

**Step 4: Ejecutar el test y confirmar GREEN**

Run el mismo comando. Expected: PASS.

**Step 5: Commit**

```bash
git add src/institutional-history/domain
git commit -m "test(history): define temporal invariants"
```

### Task 2: Agregar persistencia bitemporal, reorganizaciones y linaje

**Files:**
- Modify: `sacdia-backend/prisma/schema.prisma`
- Create: `sacdia-backend/prisma/migrations/20260723120000_institutional_history_foundation/migration.sql`
- Create: `sacdia-backend/src/institutional-history/institutional-history.schema.spec.ts`
- Modify: `docs/database/schema.prisma`
- Modify: `docs/database/SCHEMA-REFERENCE.md`
- Modify: `docs/database/migrations/README.md`

**Step 1: Escribir una prueba estructural RED**

La prueba debe leer la migración y exigir:

- `institutional_reorganizations`;
- `institutional_reorganization_participants`;
- `institutional_lineage_edges`;
- `institutional_name_versions`;
- `institutional_name_version_translations`;
- columnas bitemporales en las cinco tablas de relaciones;
- constraints XOR para FKs tipadas;
- índices de una sola revisión abierta;
- exclusiones de solapamiento solo sobre revisiones vigentes;
- protección append-only para reorganizaciones aplicadas, participantes y
  linaje;
- ausencia de columnas `evidence`, `attachment`, `resolution_number` o
  `document_reference`.

Run:

```bash
cd sacdia-backend
pnpm test -- --runInBand src/institutional-history/institutional-history.schema.spec.ts
```

Expected: FAIL.

**Step 2: Extender las relaciones existentes**

Agregar a:

- `union_division_history`;
- `local_field_union_history`;
- `district_local_field_history`;
- `church_district_history`;
- `club_institutional_history`.

Campos:

```text
recorded_from          TIMESTAMPTZ NOT NULL DEFAULT NOW()
recorded_to            TIMESTAMPTZ NULL
supersedes_history_id  BIGINT NULL
reorganization_id      UUID NULL
```

`supersedes_history_id` será una FK self-referential tipada por tabla.
`reorganization_id` será FK a `institutional_reorganizations`.

La migración inicial usa `created_at` como `recorded_from`. No debe inferir
fechas efectivas desde `modified_at`.

**Step 3: Crear versiones de nombre referencialmente seguras**

Usar una tabla de soporte común sin `entity_id` polimórfico:

```text
institutional_name_versions
  name_version_id UUID PK
  division_id | union_id | local_field_id |
  districlub_type_id | church_id | club_id
  name
  abbreviation
  valid_from
  valid_to
  precision
  recorded_from
  recorded_to
  supersedes_name_version_id
  reorganization_id
  recorded_by
```

Un CHECK debe exigir exactamente una FK tipada. Crear índices/exclusiones
parciales por cada FK. Las traducciones apuntan a `name_version_id` y son
inmutables dentro de esa versión.

**Step 4: Crear el ledger de reorganización**

`institutional_reorganizations` almacena únicamente:

- `reorganization_id`;
- `type`: `ESTABLISHMENT`, `RENAME`, `TRANSFER`, `SPLIT`, `MERGE`, `CLOSURE`,
  `CORRECTION`;
- `effective_on`;
- `description`;
- `authority_source = WORLD_CHURCH_EXECUTIVE`;
- `idempotency_key`;
- `approved_by`;
- `recorded_at`;
- `corrects_reorganization_id`, nullable.

Los participantes usan FKs tipadas XOR. Las aristas conectan participantes de
la misma reorganización con `SPLIT_FROM`, `MERGED_FROM`,
`CONTINUES_AS` o `CORRECTS`.

**Step 5: Cambiar constraints de revisión**

La revisión lógica vigente usa `recorded_to IS NULL`. Para una corrección:

1. cerrar tiempo de registro de la revisión anterior;
2. insertar la nueva revisión con `supersedes_*`;
3. recalcular los intervalos efectivos vigentes;
4. conservar la revisión reemplazada.

Los constraints anti-overlap deben considerar solo `recorded_to IS NULL`.

**Step 6: Validar schema y pruebas**

Run:

```bash
cd sacdia-backend
pnpm exec prisma validate
pnpm test -- --runInBand src/institutional-history/institutional-history.schema.spec.ts
```

Expected: ambos PASS.

**Step 7: Commit**

```bash
git add prisma src/institutional-history/institutional-history.schema.spec.ts
git commit -m "feat(history): add bitemporal institutional schema"

cd ..
git add docs/database
git commit -m "docs(database): document institutional history schema"
```

### Task 3: Backfill conservador y verificador read-only

**Files:**
- Modify: `sacdia-backend/prisma/migrations/20260723120000_institutional_history_foundation/migration.sql`
- Modify: `sacdia-backend/scripts/verify-institutional-hierarchy-migration.ts`
- Create: `sacdia-backend/scripts/verify-institutional-hierarchy-migration.spec.ts`
- Modify: `sacdia-backend/package.json`

**Step 1: Escribir tests RED del verificador**

Exigir checks para:

- una revisión efectiva abierta por entidad;
- una versión de nombre abierta por entidad;
- proyección vigente = relación/nombre que cubre `CURRENT_DATE`;
- cero solapamientos vigentes;
- cero participantes con FK ambigua;
- cero snapshots sin JSON o con `precision` nula;
- cero reorganizaciones aplicadas sin participante ni auditoría;
- cero contenido sensible por claves prohibidas en `hierarchy_contexts.context`.

**Step 2: Implementar backfill**

- Conservar los rangos existentes.
- Crear versiones de nombre actuales como `system_backfill`.
- Marcar las revisiones existentes con `recorded_from = created_at`.
- No crear reorganizaciones ficticias para historia desconocida.
- No reescribir snapshots oficiales existentes.

**Step 3: Mantener seguridad operacional del script**

El script:

- solo acepta `INSTITUTIONAL_HIERARCHY_VERIFY_DATABASE_URL`;
- usa `BEGIN READ ONLY`;
- conserva `--dry-run`;
- rechaza Neon salvo opt-in explícito;
- imprime conteos antes de fallar.

**Step 4: Ejecutar**

```bash
cd sacdia-backend
pnpm test -- --runInBand scripts/verify-institutional-hierarchy-migration.spec.ts
pnpm verify:institutional-hierarchy-migration -- --dry-run
```

Expected: PASS y listado de checks sin conexión.

**Step 5: Commit**

```bash
git add prisma/migrations/20260723120000_institutional_history_foundation \
  scripts/verify-institutional-hierarchy-migration.ts \
  scripts/verify-institutional-hierarchy-migration.spec.ts package.json
git commit -m "feat(history): add conservative backfill verification"
```

### Task 4: Convertir auditoría crítica en transaccional y append-only

**Files:**
- Modify: `sacdia-backend/prisma/schema.prisma`
- Modify: `sacdia-backend/src/audit-logs/audit-logs.service.ts`
- Modify: `sacdia-backend/src/audit-logs/audit-logs.service.spec.ts`
- Create: `sacdia-backend/src/audit-logs/audit-redaction.policy.ts`
- Create: `sacdia-backend/src/audit-logs/audit-redaction.policy.spec.ts`
- Modify: `sacdia-backend/prisma/migrations/20260723120000_institutional_history_foundation/migration.sql`

**Step 1: Escribir tests RED**

Cubrir:

- `recordCriticalEvent(tx, dto)` usa el `TransactionClient`;
- un error se propaga;
- `recordEvent()` legacy puede seguir siendo best-effort durante la migración;
- el redactor elimina valores de salud, teléfono, representante, documentos,
  tokens y payloads arbitrarios marcados como sensibles;
- UPDATE y DELETE de `audit_logs` son rechazados por trigger.

**Step 2: Extender metadata**

Agregar a `audit_logs`:

- `reorganization_id UUID NULL`;
- `request_id UUID NULL`;
- `purpose VARCHAR(80) NULL`;
- `scope_context JSONB NULL`;

Ampliar `action` y su tipo TypeScript para eventos explícitos como
`REORGANIZATION_RECORDED`, `SNAPSHOT_CREATED`, `ISSUANCE_SUPERSEDED`,
`SENSITIVE_ACCESS_GRANTED`, `SENSITIVE_ACCESS_DENIED` y
`RETENTION_ACTION_APPLIED`; no codificar acciones de negocio como `UPDATED`
genérico.

No guardar body HTTP completo. `changes` solo acepta diffs explícitamente
permitidos y redactados.

**Step 3: Implementar dos caminos deliberados**

```ts
recordCriticalEvent(tx: Prisma.TransactionClient, event: CriticalAuditEvent)
recordEvent(event: LegacyAuditEvent)
```

Los comandos institucionales solo usan `recordCriticalEvent`.

**Step 4: Ejecutar**

```bash
cd sacdia-backend
pnpm test -- --runInBand \
  src/audit-logs/audit-redaction.policy.spec.ts \
  src/audit-logs/audit-logs.service.spec.ts
```

Expected: PASS.

**Step 5: Commit**

```bash
git add prisma src/audit-logs
git commit -m "feat(audit): make critical events transactional"
```

### Task 5: Hacer fiel y fail-closed el resolver histórico

**Files:**
- Modify: `sacdia-backend/src/common/services/institutional-hierarchy.service.ts`
- Modify: `sacdia-backend/src/common/services/institutional-hierarchy.service.spec.ts`
- Modify: `sacdia-backend/src/common/errors/error-codes.ts`
- Modify: `sacdia-backend/src/i18n/es/errors.json`
- Modify: `sacdia-backend/src/i18n/en/errors.json`
- Modify: `sacdia-backend/src/i18n/fr/errors.json`
- Modify: `sacdia-backend/src/i18n/pt-BR/errors.json`

**Step 1: Reemplazar el test de fallback**

El test actual que espera `precision: unknown` debe pasar a esperar
`HIERARCHY_HISTORY_NOT_FOUND`. Agregar casos:

- renombre posterior no cambia `union_name` anterior;
- traducción se resuelve desde la versión vigente en `asOf`;
- `knowledgeAt` permite leer una revisión corregida;
- la lectura vigente sigue usando proyecciones.

**Step 2: Ejecutar RED**

```bash
cd sacdia-backend
pnpm test -- --runInBand src/common/services/institutional-hierarchy.service.spec.ts
```

Expected: FAIL con el fallback actual.

**Step 3: Corregir queries**

Toda query `resolve*AsOf` debe:

- filtrar `recorded_to IS NULL` o el rango de `knowledgeAt`;
- unir `institutional_name_versions`, no `*.name` vigente;
- resolver traducción por `locale`, con fallback a nombre base de ESA versión;
- devolver `source`, `precision`, `as_of` y `recorded_at`;
- lanzar error si falta cualquier eslabón requerido.

**Step 4: Ejecutar GREEN**

Run el mismo test. Expected: PASS.

**Step 5: Commit**

```bash
git add src/common/services/institutional-hierarchy.service* \
  src/common/errors src/i18n
git commit -m "fix(history): resolve names from temporal versions"
```

---

## PR 2 — Comandos, linaje y API

### Task 6: Definir DTOs discriminados e idempotencia

**Files:**
- Create: `sacdia-backend/src/institutional-history/dto/institutional-reorganization.dto.ts`
- Create: `sacdia-backend/src/institutional-history/dto/institutional-reorganization.dto.spec.ts`
- Create: `sacdia-backend/src/institutional-history/domain/institutional-reorganization.policy.ts`
- Create: `sacdia-backend/src/institutional-history/domain/institutional-reorganization.policy.spec.ts`

**Step 1: Tests RED por tipo**

Validar:

- `effective_on` obligatorio;
- `description` obligatoria y acotada;
- `Idempotency-Key` UUID obligatorio;
- `RENAME` conserva identidad;
- `TRANSFER` exige padre destino del tipo correcto;
- `SPLIT` exige al menos una fuente y dos destinos/continuaciones;
- `MERGE` exige dos o más fuentes y un destino;
- `CLOSURE` no acepta descendientes activos sin destino o cierre explícito;
- `CORRECTION` exige `corrects_reorganization_id`;
- ningún DTO acepta evidencia documental.

**Step 2: Implementar discriminated union**

El endpoint recibe:

```json
{
  "type": "TRANSFER",
  "effective_on": "2026-01-01",
  "description": "Traslado aprobado por decisión ejecutiva mundial",
  "command": {
    "entity": { "type": "local_field", "id": 10 },
    "new_parent": { "type": "union", "id": 2 }
  }
}
```

`authority_source` y actor se fijan en servidor.

Contrato de `command` por tipo:

| Tipo | Shape mínima |
|---|---|
| `ESTABLISHMENT` | `entity_type`, `identity`, `initial_name`, `translations`, `parent` |
| `RENAME` | `entity`, `new_name`, `new_abbreviation?`, `translations` |
| `TRANSFER` | `entity`, `new_parent` |
| `SPLIT` | `source`, `successors[]`, `moves[]`, `close_source` |
| `MERGE` | `sources[]`, `destination`, `moves[]`, `close_sources` |
| `CLOSURE` | `entity`, `descendant_dispositions[]` |
| `CORRECTION` | `corrects_reorganization_id`, `replacement_command` |

Un `successor` o `destination` puede referenciar una entidad existente o
declarar `create` con identidad inicial y padre. `moves[]` enumera los hijos que
cambian de autoridad. El backend rechaza splits, merges o cierres que dejen
descendientes activos sin disposición explícita.

**Step 3: Ejecutar**

```bash
cd sacdia-backend
pnpm test -- --runInBand \
  src/institutional-history/dto/institutional-reorganization.dto.spec.ts \
  src/institutional-history/domain/institutional-reorganization.policy.spec.ts
```

Expected: PASS.

**Step 4: Commit**

```bash
git add src/institutional-history/dto src/institutional-history/domain
git commit -m "feat(history): define reorganization commands"
```

### Task 7: Implementar el comando transaccional de reorganización

**Files:**
- Create: `sacdia-backend/src/institutional-history/services/institutional-reorganization.service.ts`
- Create: `sacdia-backend/src/institutional-history/services/institutional-reorganization.service.spec.ts`
- Create: `sacdia-backend/src/institutional-history/repositories/institutional-history.repository.ts`
- Create: `sacdia-backend/src/institutional-history/repositories/institutional-history.repository.spec.ts`
- Create: `sacdia-backend/src/institutional-history/services/institutional-projection.service.ts`
- Create: `sacdia-backend/src/institutional-history/services/institutional-projection.service.spec.ts`
- Create: `sacdia-backend/src/institutional-history/jobs/institutional-projection.job.ts`
- Create: `sacdia-backend/src/institutional-history/jobs/institutional-projection.job.spec.ts`

**Step 1: Tests RED de atomicidad**

Cubrir:

- retry con el mismo `Idempotency-Key` retorna la misma reorganización;
- nombre, traducciones, relación, proyección, participante, linaje y auditoría
  ocurren en una sola transacción;
- un fallo de auditoría revierte todo;
- transferir un campo actualiza el historial completo de sus clubes;
- transferir distrito o iglesia mantiene consistencia del árbol;
- split/merge no reatribuye snapshots;
- corrección cierra `recorded_to` e inserta revisión;
- fecha efectiva futura no cambia la proyección actual hasta ser vigente;
- el refresco idempotente aplica proyecciones vencidas y alerta divergencias.

**Step 2: Implementar una sola frontera de escritura**

El repository debe aceptar siempre `Prisma.TransactionClient`. El service:

1. valida autoridad y topología;
2. crea o recupera idempotentemente la reorganización;
3. fija `set_config('sacdia.institutional_reorganization_id', id, true)`;
4. escribe revisiones temporales;
5. actualiza proyecciones solo si corresponden a `CURRENT_DATE`;
6. inserta participantes/aristas;
7. registra auditoría crítica;
8. invalida cachés DESPUÉS del commit.

Las fechas futuras crean la revisión efectiva, pero no cambian la proyección.
`InstitutionalProjectionJob` ejecuta diariamente en UTC el refresco idempotente
de revisiones cuyo `valid_from <= CURRENT_DATE`. El verificador read-only detecta
si el job no aplicó una proyección ya vigente.

**Step 3: Usar operaciones set-based para descendientes**

No hacer loops N+1 para clubes afectados por un traslado superior. Usar SQL
parametrizado dentro de la transacción para cerrar/abrir revisiones en bloque.

**Step 4: Ejecutar**

```bash
cd sacdia-backend
pnpm test -- --runInBand \
  src/institutional-history/repositories/institutional-history.repository.spec.ts \
  src/institutional-history/services/institutional-reorganization.service.spec.ts \
  src/institutional-history/services/institutional-projection.service.spec.ts \
  src/institutional-history/jobs/institutional-projection.job.spec.ts
```

Expected: PASS.

**Step 5: Commit**

```bash
git add src/institutional-history/repositories \
  src/institutional-history/services
git commit -m "feat(history): execute reorganizations atomically"
```

### Task 8: Migrar todos los write paths institucionales

**Files:**
- Modify: `sacdia-backend/src/admin/admin-geography.service.ts`
- Modify: `sacdia-backend/src/admin/admin-geography.service.spec.ts`
- Modify: `sacdia-backend/src/admin/dto/geography.dto.ts`
- Modify: `sacdia-backend/src/clubs/clubs.service.ts`
- Modify: `sacdia-backend/src/clubs/clubs.service.spec.ts`
- Modify: `sacdia-backend/src/clubs/dto/club.dto.ts`
- Modify: `sacdia-backend/src/rbac/rbac.service.ts`
- Modify: `sacdia-backend/src/rbac/rbac.service.spec.ts`
- Modify: `sacdia-backend/src/admin/admin-users.service.ts`
- Modify: `sacdia-backend/src/admin/admin-users.service.spec.ts`
- Modify: `sacdia-backend/src/users/users.service.ts`
- Modify: `sacdia-backend/src/users/users.service.spec.ts`

**Step 1: Tests RED**

Exigir que:

- crear una entidad inicializa nombre y relación efectiva en la misma transacción;
- PATCH geográfico rechaza nombre, abreviatura, padre o `active`;
- los cambios estructurales responden
  `INSTITUTIONAL_CHANGE_REQUIRES_REORGANIZATION`;
- crear club inicializa `club_institutional_history`;
- `UpdateClubDto` no puede alterar jerarquía;
- cambios de scope institucional de un usuario no borran el scope anterior.

**Step 2: Retirar writers directos**

Eliminar `reassignUnionDivisionHistory` del CRUD. El CRUD queda para metadata no
estructural; renombre, traslado y cierre usan el comando dedicado.

**Step 3: Inicialización transaccional**

La creación normal usa el mismo núcleo con tipo `ESTABLISHMENT`. No usar
fire-and-forget. No permitir que exista la entidad sin historia abierta al commit.

**Step 4: Ejecutar**

```bash
cd sacdia-backend
pnpm test -- --runInBand \
  src/admin/admin-geography.service.spec.ts \
  src/clubs/clubs.service.spec.ts \
  src/rbac/rbac.service.spec.ts \
  src/admin/admin-users.service.spec.ts \
  src/users/users.service.spec.ts
```

Expected: PASS.

**Step 5: Commit**

```bash
git add src/admin src/clubs src/rbac src/users
git commit -m "refactor(history): route structural writes through commands"
```

### Task 9: Activar barreras de base de datos contra bypass

**Files:**
- Create: `sacdia-backend/prisma/migrations/20260723130000_institutional_history_enforcement/migration.sql`
- Modify: `sacdia-backend/src/institutional-history/institutional-history.schema.spec.ts`
- Modify: `sacdia-backend/scripts/verify-institutional-hierarchy-migration.ts`

**Step 1: Tests RED**

Exigir triggers que:

- bloqueen UPDATE estructural de proyecciones sin
  `sacdia.institutional_reorganization_id`;
- validen al commit exactamente una relación/nombre vigente;
- bloqueen UPDATE/DELETE de nombres, participantes, aristas y snapshots
  históricos;
- permitan cambios desde el comando autorizado;
- no confíen únicamente en el controller.

**Step 2: Implementar triggers diferibles**

Proteger:

- `divisions.name/abbreviation/active`;
- `unions.name/abbreviation/division_id/active`;
- `local_fields.name/abbreviation/union_id/active`;
- `districts.name/local_field_id/active`;
- `churches.name/districlub_type_id/active`;
- `clubs.name/local_field_id/districlub_type_id/church_id/active`.

**Step 3: Ejecutar validación estática y dry-run**

```bash
cd sacdia-backend
pnpm test -- --runInBand src/institutional-history/institutional-history.schema.spec.ts
pnpm verify:institutional-hierarchy-migration -- --dry-run
```

Expected: PASS.

**Step 4: Commit**

```bash
git add prisma/migrations/20260723130000_institutional_history_enforcement \
  src/institutional-history/institutional-history.schema.spec.ts \
  scripts/verify-institutional-hierarchy-migration.ts
git commit -m "feat(history): enforce institutional write boundary"
```

### Task 10: Exponer mutaciones y consultas canónicas

**Files:**
- Create: `sacdia-backend/src/institutional-history/institutional-history.module.ts`
- Create: `sacdia-backend/src/institutional-history/institutional-reorganizations.controller.ts`
- Create: `sacdia-backend/src/institutional-history/institutional-history.controller.ts`
- Create: `sacdia-backend/src/institutional-history/institutional-history.controller.spec.ts`
- Modify: `sacdia-backend/src/app.module.ts`
- Modify: `sacdia-backend/src/common/common.module.ts`
- Modify: `sacdia-backend/src/admin/admin.module.ts`
- Modify: `sacdia-backend/src/common/errors/error-codes.ts`
- Modify: `sacdia-backend/prisma/seeds/permissions.seed.sql`
- Modify: `sacdia-backend/prisma/seeds/role-permissions.seed.sql`
- Create: `sacdia-backend/prisma/migrations/20260723131000_institutional_history_permissions/migration.sql`

**Step 1: Tests RED de contrato**

Endpoints:

```text
POST /api/v1/admin/institutional-reorganizations
GET  /api/v1/admin/institutional-reorganizations/:id
GET  /api/v1/institutional-history/:entityType/:entityId/context
GET  /api/v1/institutional-history/:entityType/:entityId/timeline
GET  /api/v1/institutional-history/:entityType/:entityId/lineage
```

Query params de `context`: `at`, `knowledge_at`, `locale`.

Permisos:

- `institutional_reorganizations:approve`;
- `institutional_history:read`;
- `institutional_history:read_audit`.

Solo `director-dia`, `admin` y `super-admin` reciben `approve`.

**Step 2: Implementar controller**

El controller:

- obtiene actor desde JWT;
- exige `Idempotency-Key` en POST;
- nunca recibe `approved_by` ni `authority_source` del cliente;
- pagina timelines;
- devuelve `source`, `precision`, fechas efectiva/de registro;
- no mezcla snapshot con consulta `as_of`.

**Step 3: Ejecutar**

```bash
cd sacdia-backend
pnpm test -- --runInBand \
  src/institutional-history/institutional-history.controller.spec.ts \
  src/common/seeds/__tests__/permissions-cleanup.spec.ts
```

Expected: PASS.

**Step 4: Commit**

```bash
git add src/institutional-history src/app.module.ts src/common \
  src/admin/admin.module.ts prisma
git commit -m "feat(history): expose reorganization and history API"
```

---

## PR 3 — Autorización histórica y datos sensibles

### Task 11: Versionar cargos y scope institucional

**Files:**
- Modify: `sacdia-backend/prisma/schema.prisma`
- Create: `sacdia-backend/prisma/migrations/20260723140000_institutional_authority_history/migration.sql`
- Create: `sacdia-backend/src/institutional-history/services/institutional-authority.service.ts`
- Create: `sacdia-backend/src/institutional-history/services/institutional-authority.service.spec.ts`
- Modify: `sacdia-backend/src/rbac/rbac.service.ts`
- Modify: `sacdia-backend/src/admin/admin-users.service.ts`
- Modify: `sacdia-backend/src/common/services/authorization-context.service.ts`

**Step 1: Tests RED**

Cubrir:

- asignar rol global abre un período de autoridad con scope tipado;
- remover rol cierra el período y no lo borra;
- mover el scope del usuario cierra y abre la asignación;
- backfill actual usa `system_backfill`;
- `permissions_snapshot` guarda solo nombres de permisos de lectura;
- una desactivación global del permiso sigue bloqueando su uso histórico.

**Step 2: Crear `institutional_authority_assignments`**

Campos mínimos:

```text
authority_assignment_id
user_id
role_id
role_name_snapshot
permissions_snapshot
division_id | union_id | local_field_id
valid_from
valid_to
precision
recorded_from
recorded_to
supersedes_assignment_id
recorded_by
```

Exigir una FK de scope acorde al rol. `admin`/`super-admin` pueden usar scope
global explícito; no inferirlo con IDs nulos ambiguos.

**Step 3: Migrar writers**

`RbacService` y `AdminUsersService` escriben proyección + autoridad temporal en
una sola transacción. Invalidar cache después del commit.

**Step 4: Ejecutar**

```bash
cd sacdia-backend
pnpm exec prisma validate
pnpm test -- --runInBand \
  src/institutional-history/services/institutional-authority.service.spec.ts \
  src/rbac/rbac.service.spec.ts \
  src/admin/admin-users.service.spec.ts \
  src/common/services/authorization-context.service.spec.ts
```

Expected: PASS.

**Step 5: Commit**

```bash
git add prisma src/institutional-history src/rbac src/admin \
  src/common/services/authorization-context.service.ts
git commit -m "feat(history): preserve authority scope periods"
```

### Task 12: Implementar lectura histórica no sensible

**Files:**
- Create: `sacdia-backend/src/institutional-history/services/historical-access-policy.service.ts`
- Create: `sacdia-backend/src/institutional-history/services/historical-access-policy.service.spec.ts`
- Modify: `sacdia-backend/src/common/services/authorization-context.service.ts`
- Modify: `sacdia-backend/src/institutional-history/institutional-history.controller.ts`

**Step 1: Tests RED de matriz**

| Caso | Resultado |
|---|---|
| autoridad vigente administra hoy la entidad | trayectoria completa no sensible |
| autoridad anterior, registro dentro de su período | lectura |
| autoridad anterior, registro posterior | deny |
| autoridad anterior intenta escribir | deny |
| actor sin relación institucional | deny |
| dato sensible por endpoint histórico genérico | deny |

**Step 2: Separar políticas**

No reutilizar un booleano ambiguo. Crear métodos explícitos:

```ts
canWriteCurrent(...)
canReadCurrent(...)
canReadHistoricalNonSensitive(...)
```

La lectura histórica recibe tanto la entidad cuya trayectoria se consulta como
el contexto/fecha del registro.

**Step 3: Ejecutar**

```bash
cd sacdia-backend
pnpm test -- --runInBand \
  src/institutional-history/services/historical-access-policy.service.spec.ts \
  src/common/services/authorization-context.service.spec.ts \
  src/institutional-history/institutional-history.controller.spec.ts
```

Expected: PASS.

**Step 4: Commit**

```bash
git add src/institutional-history src/common/services/authorization-context.service*
git commit -m "feat(history): enforce historical custody periods"
```

### Task 13: Modelar grants excepcionales y auditoría sensible

**Files:**
- Modify: `sacdia-backend/prisma/schema.prisma`
- Create: `sacdia-backend/prisma/migrations/20260723150000_sensitive_data_governance/migration.sql`
- Create: `sacdia-backend/src/sensitive-data/sensitive-data.module.ts`
- Create: `sacdia-backend/src/sensitive-data/sensitive-access-policy.service.ts`
- Create: `sacdia-backend/src/sensitive-data/sensitive-access-policy.service.spec.ts`
- Create: `sacdia-backend/src/sensitive-data/sensitive-access-grants.service.ts`
- Create: `sacdia-backend/src/sensitive-data/sensitive-access-grants.service.spec.ts`
- Create: `sacdia-backend/src/sensitive-data/sensitive-access.controller.ts`

**Step 1: Tests RED**

Cubrir:

- titular lee y actualiza lo propio;
- representante legal vigente lee/actualiza al representado;
- director de sección activa lee solo un miembro de ESA sección;
- sección no puede actualizar;
- Campo Local requiere permiso fino + scope vigente + finalidad;
- Unión requiere grant específico, justificación y expiración;
- autoridad anterior siempre pierde payload sensible;
- admin técnico sin relación/grant no puede leer;
- cada intento exitoso o denegado registra metadata sin payload.

**Step 2: Crear tablas**

- `sensitive_access_grants`: actor, sujeto, familia, operación `READ`, propósito,
  justificación, scope de unión, `valid_from`, `expires_at`, granted/revoked.
- `sensitive_access_events`: actor, sujeto, familia, operación, propósito,
  grant, resultado, timestamp, request id.

Los eventos son append-only. No guardar nombre, teléfono, enfermedad,
medicamento, sangre ni documento.

**Step 3: Permisos**

- `sensitive_access:grant`;
- `sensitive_access:audit`;
- mantener permisos finos por familia.

`director-dia`, `admin` y `super-admin` pueden otorgar/revocar grants, pero ese
permiso NO les concede lectura del contenido.

**Step 4: Ejecutar**

```bash
cd sacdia-backend
pnpm exec prisma validate
pnpm test -- --runInBand \
  src/sensitive-data/sensitive-access-policy.service.spec.ts \
  src/sensitive-data/sensitive-access-grants.service.spec.ts
```

Expected: PASS.

**Step 5: Commit**

```bash
git add prisma src/sensitive-data
git commit -m "feat(security): add contextual sensitive access"
```

### Task 14: Migrar salud, emergencia, representante y post-registro

**Files:**
- Modify: `sacdia-backend/src/common/decorators/sensitive-user-subresource.decorator.ts`
- Modify: `sacdia-backend/src/common/guards/sensitive-user-subresource-policy.ts`
- Modify: `sacdia-backend/src/common/guards/permissions.guard.ts`
- Modify: `sacdia-backend/src/common/guards/permissions.guard.spec.ts`
- Modify: `sacdia-backend/src/users/users.controller.ts`
- Modify: `sacdia-backend/src/users/users.controller.spec.ts`
- Modify: `sacdia-backend/src/emergency-contacts/emergency-contacts.controller.ts`
- Modify: `sacdia-backend/src/emergency-contacts/emergency-contacts.controller.spec.ts`
- Modify: `sacdia-backend/src/legal-representatives/legal-representatives.controller.ts`
- Modify: `sacdia-backend/src/legal-representatives/legal-representatives.controller.spec.ts`
- Modify: `sacdia-backend/src/post-registration/post-registration.controller.ts`

**Step 1: Reemplazar fallback global**

Eliminar `users:read_detail` / `users:update_profile` como equivalencia
automática para terceros sensibles.

**Step 2: Exigir finalidad**

Para acceso de terceros, aceptar un header canónico:

```text
X-Sensitive-Access-Purpose
```

La finalidad se valida por familia y se envía al audit event. El titular no
necesita declarar una finalidad operativa de tercero.

**Step 3: Limitar campos devueltos**

La sección y Campo Local reciben DTOs de mínimo necesario. El endpoint no debe
reutilizar la respuesta completa de admin. Las mutaciones de terceros devuelven
403.

**Step 4: Ejecutar**

```bash
cd sacdia-backend
pnpm test -- --runInBand \
  src/common/guards/permissions.guard.spec.ts \
  src/users/users.controller.spec.ts \
  src/emergency-contacts/emergency-contacts.controller.spec.ts \
  src/legal-representatives/legal-representatives.controller.spec.ts
```

Expected: PASS.

**Step 5: Commit**

```bash
git add src/common src/users src/emergency-contacts \
  src/legal-representatives src/post-registration
git commit -m "fix(security): scope sensitive user resources"
```

### Task 15: Implementar retención versionada sin plazos hardcodeados

**Files:**
- Modify: `sacdia-backend/prisma/schema.prisma`
- Modify: `sacdia-backend/prisma/migrations/20260723150000_sensitive_data_governance/migration.sql`
- Create: `sacdia-backend/src/sensitive-data/sensitive-retention.service.ts`
- Create: `sacdia-backend/src/sensitive-data/sensitive-retention.service.spec.ts`
- Create: `sacdia-backend/src/sensitive-data/sensitive-retention.job.ts`
- Create: `sacdia-backend/src/sensitive-data/sensitive-retention.job.spec.ts`
- Modify: `sacdia-backend/src/config/env.validation.ts`

**Step 1: Tests RED**

Cubrir:

- sin política activa no borra nada y genera alerta;
- política se selecciona por familia + jurisdicción + vigencia;
- `block` precede a `delete` o `anonymize`;
- el tratamiento que depende de consentimiento exige versión de aviso y
  consentimiento vigentes;
- revocar consentimiento cierra su vigencia sin borrar el evento anterior;
- cada run es idempotente y auditable;
- dry-run no muta;
- payload sensible nunca aparece en logs.

**Step 2: Crear tablas**

- `sensitive_retention_policies`;
- `sensitive_retention_runs`;
- `sensitive_retention_run_items` con IDs técnicos y resultado, sin contenido.
- `privacy_notice_versions`;
- `sensitive_data_consents`, con titular, representante cuando aplique, familia,
  versión de aviso, base de tratamiento, vigencia y revocación.

Los plazos viven en datos versionados. No sembrar un número legal supuesto.
Tampoco asumir que consentimiento es la única base: la política versionada
declara la base aplicable por familia y jurisdicción.

**Step 3: Crear adaptadores por familia**

Implementar adaptadores explícitos para:

- salud;
- contactos de emergencia;
- representante legal;
- post-registro/documentos privados.

No usar SQL dinámico construido desde nombres de tabla recibidos por API.

**Step 4: Ejecutar**

```bash
cd sacdia-backend
pnpm test -- --runInBand \
  src/sensitive-data/sensitive-retention.service.spec.ts \
  src/sensitive-data/sensitive-retention.job.spec.ts
```

Expected: PASS.

**Step 5: Commit**

```bash
git add prisma src/sensitive-data src/config/env.validation*
git commit -m "feat(privacy): add versioned sensitive retention"
```

---

## PR 4 — Snapshots y emisiones oficiales, oleada A

### Task 16: Endurecer `hierarchy_contexts`

**Files:**
- Modify: `sacdia-backend/prisma/schema.prisma`
- Create: `sacdia-backend/prisma/migrations/20260723160000_immutable_hierarchy_contexts/migration.sql`
- Modify: `sacdia-backend/src/common/services/institutional-hierarchy.service.ts`
- Modify: `sacdia-backend/src/common/services/institutional-hierarchy.service.spec.ts`
- Modify: `sacdia-backend/src/annual-folders/evaluation.service.ts`
- Modify: `sacdia-backend/src/annual-folders/__tests__/evaluation.service.spec.ts`
- Modify: `sacdia-backend/src/year-end/year-end.service.ts`
- Modify: `sacdia-backend/src/year-end/year-end.service.spec.ts`

**Step 1: Tests RED**

Exigir:

- `snapshotForClub(tx, ...)` participa en la transacción del agregado;
- snapshot usa el resolver fail-closed;
- `context` es NOT NULL, versionado y tiene hash estable;
- no contiene claves sensibles;
- UPDATE/DELETE se rechaza;
- FKs oficiales usan `ON DELETE RESTRICT`;
- cerrar carpeta no puede limpiar un snapshot ya fijado.

**Step 2: Agregar metadata**

- `schema_version`;
- `content_hash`;
- `locale`;
- `context NOT NULL`.

El JSON incluye IDs y nombres versionados exactos.

**Step 3: Corregir consumers existentes**

Eliminar caminos que vuelven `hierarchy_context_id` a `NULL` después del cierre.
Carpetas, rankings y year-end deben reutilizar el snapshot raíz, no crear
versiones contradictorias.

**Step 4: Ejecutar**

```bash
cd sacdia-backend
pnpm test -- --runInBand \
  src/common/services/institutional-hierarchy.service.spec.ts \
  src/annual-folders/__tests__/evaluation.service.spec.ts \
  src/year-end/year-end.service.spec.ts
```

Expected: PASS.

**Step 5: Commit**

```bash
git add prisma src/common/services/institutional-hierarchy.service* \
  src/annual-folders/evaluation.service* src/year-end/year-end.service*
git commit -m "feat(history): make hierarchy snapshots immutable"
```

### Task 17: Adoptar snapshots en inscripciones, validaciones y rankings

**Files:**
- Modify: `sacdia-backend/prisma/schema.prisma`
- Create: `sacdia-backend/prisma/migrations/20260723161000_wave_a_enrollment_snapshots/migration.sql`
- Modify: `sacdia-backend/src/club-enrollments/club-enrollments.service.ts`
- Modify: `sacdia-backend/src/club-enrollments/club-enrollments.service.spec.ts`
- Modify: `sacdia-backend/src/investiture/investiture.service.ts`
- Modify: `sacdia-backend/src/investiture/investiture.service.spec.ts`
- Modify: `sacdia-backend/src/annual-folders/rankings.service.ts`
- Modify: `sacdia-backend/src/annual-folders/__tests__/rankings.service.spec.ts`
- Modify: `sacdia-backend/src/rankings/member-rankings/member-rankings.service.ts`
- Create: `sacdia-backend/src/rankings/member-rankings/member-rankings.service.spec.ts`

**Step 1: Tests RED por transición**

- `club_enrollments.approve` fija snapshot;
- investidura aprobada hereda snapshot de inscripción o fija uno si es legacy;
- ranking oficial hereda snapshot del folder/enrollment;
- una reorganización posterior no cambia las respuestas históricas;
- un registro legacy sin snapshot se muestra como legacy/unknown, no se
  reatribuye silenciosamente.

**Step 2: Añadir FKs nullable para legacy**

Las nuevas filas oficiales exigen snapshot desde el service. Las filas antiguas
permanecen nullable y explícitamente marcadas como legacy.

**Step 3: Ejecutar**

```bash
cd sacdia-backend
pnpm test -- --runInBand \
  src/club-enrollments/club-enrollments.service.spec.ts \
  src/investiture/investiture.service.spec.ts \
  src/annual-folders/__tests__/rankings.service.spec.ts \
  src/rankings/member-rankings/member-rankings.service.spec.ts
```

Expected: PASS.

**Step 4: Commit**

```bash
git add prisma src/club-enrollments src/investiture \
  src/annual-folders/rankings.service* src/rankings/member-rankings
git commit -m "feat(history): snapshot enrollment and validation acts"
```

### Task 18: Adoptar snapshots en finanzas, seguros y materiales

**Files:**
- Modify: `sacdia-backend/prisma/schema.prisma`
- Create: `sacdia-backend/prisma/migrations/20260723162000_wave_a_operational_snapshots/migration.sql`
- Modify: `sacdia-backend/src/finances/finance-period.service.ts`
- Modify: `sacdia-backend/src/finances/finance-period.service.spec.ts`
- Modify: `sacdia-backend/src/insurance/insurance.service.ts`
- Modify: `sacdia-backend/src/insurance/insurance.service.spec.ts`
- Modify: `sacdia-backend/src/materials/orders/orders.service.ts`
- Create: `sacdia-backend/src/materials/orders/orders.service.spec.ts`
- Modify: `sacdia-backend/src/materials/receipts/receipts.service.ts`
- Create: `sacdia-backend/src/materials/receipts/receipts.service.spec.ts`

**Step 1: Tests RED**

- cerrar período financiero fija snapshot en la misma transacción;
- seguro confirmado fija snapshot institucional sin copiar salud;
- orden aprobada fija contexto comprador además del config snapshot existente;
- receipt hereda el snapshot de la orden;
- reimpresión usa snapshot, no jerarquía actual.

**Step 2: Implementar por raíz**

No snapshotear cada movimiento financiero ni cada línea de orden. Enlazar hijos
con el snapshot de la raíz oficial.

**Step 3: Ejecutar**

```bash
cd sacdia-backend
pnpm test -- --runInBand \
  src/finances/finance-period.service.spec.ts \
  src/insurance/insurance.service.spec.ts \
  src/materials/orders/orders.service.spec.ts \
  src/materials/receipts/receipts.service.spec.ts
```

Expected: PASS.

**Step 4: Commit**

```bash
git add prisma src/finances src/insurance src/materials
git commit -m "feat(history): snapshot finance insurance and orders"
```

### Task 19: Adoptar snapshots en camporees y reportes oficiales

**Files:**
- Modify: `sacdia-backend/prisma/schema.prisma`
- Create: `sacdia-backend/prisma/migrations/20260723163000_wave_a_camporee_report_snapshots/migration.sql`
- Modify: `sacdia-backend/src/camporees/camporees.service.ts`
- Modify: `sacdia-backend/src/camporees/camporees.service.spec.ts`
- Modify: `sacdia-backend/src/camporees/camporee-late-approvals.service.ts`
- Modify: `sacdia-backend/src/monthly-reports/monthly-reports.service.ts`
- Modify: `sacdia-backend/src/monthly-reports/monthly-reports-pdf.service.ts`
- Modify: `sacdia-backend/src/monthly-reports/monthly-reports.service.spec.ts`
- Modify: `sacdia-backend/src/quarterly-reports/quarterly-reports-pdf.service.ts`
- Modify: `sacdia-backend/src/annual-reports/annual-reports-pdf.service.ts`

**Step 1: Tests RED**

- aprobación de inscripción a camporee fija snapshot;
- aprobación tardía usa el mismo contrato;
- resultado cerrado hereda contexto de inscripción/evento;
- `monthly-reports.generate` fija contexto junto a `snapshot_data`;
- PDF mensual, trimestral y anual usa snapshot almacenado;
- regenerar un PDF histórico no consulta nombres actuales.

**Step 2: Ejecutar**

```bash
cd sacdia-backend
pnpm test -- --runInBand \
  src/camporees/camporees.service.spec.ts \
  src/monthly-reports/monthly-reports.service.spec.ts
```

Expected: PASS.

**Step 3: Commit**

```bash
git add prisma src/camporees src/monthly-reports \
  src/quarterly-reports src/annual-reports
git commit -m "feat(history): snapshot camporee and report outputs"
```

### Task 20: Crear registro inmutable de emisiones y reemplazos

**Files:**
- Modify: `sacdia-backend/prisma/schema.prisma`
- Create: `sacdia-backend/prisma/migrations/20260723164000_issued_artifacts/migration.sql`
- Create: `sacdia-backend/src/issued-artifacts/issued-artifacts.module.ts`
- Create: `sacdia-backend/src/issued-artifacts/issued-artifacts.service.ts`
- Create: `sacdia-backend/src/issued-artifacts/issued-artifacts.service.spec.ts`
- Modify: `sacdia-backend/src/certifications/certifications.service.ts`
- Modify: `sacdia-backend/src/certifications/certifications.service.spec.ts`
- Modify: `sacdia-backend/src/data-export/data-export.service.ts`
- Modify: `sacdia-backend/src/data-export/data-export.service.spec.ts`

**Step 1: Tests RED**

- emisión original es inmutable;
- descarga reproduce representación original;
- error material crea emisión nueva con `replaces_issuance_id`;
- original pasa a `SUPERSEDED` o `REVOKED` mediante evento, no overwrite;
- snapshot institucional queda enlazado;
- hash detecta alteración;
- export/report derivado enlaza la fuente.

**Step 2: Crear ledger**

`issued_artifacts` guarda tipo, raíz, versión, status, representación, hash,
snapshot, actor y fechas. `issued_artifact_events` conserva transiciones. No usar
esta tabla para drafts.

**Step 3: Ejecutar**

```bash
cd sacdia-backend
pnpm test -- --runInBand \
  src/issued-artifacts/issued-artifacts.service.spec.ts \
  src/certifications/certifications.service.spec.ts \
  src/data-export/data-export.service.spec.ts
```

Expected: PASS.

**Step 4: Commit**

```bash
git add prisma src/issued-artifacts src/certifications src/data-export
git commit -m "feat(history): preserve immutable issued artifacts"
```

---

## PR 5 — Cobertura restante, oleada B

### Task 21: Actividades e inventario

**Files:**
- Modify: `sacdia-backend/src/activities/activities.service.ts`
- Modify: `sacdia-backend/src/activities/activities.service.spec.ts`
- Modify: `sacdia-backend/src/activities/activities.controller.ts`
- Create: `sacdia-backend/src/activities/activities.controller.spec.ts`
- Create: `sacdia-backend/src/activities/dto/complete-activity.dto.ts`
- Modify: `sacdia-backend/src/inventory/inventory.service.ts`
- Modify: `sacdia-backend/src/inventory/inventory.service.spec.ts`
- Modify: `sacdia-backend/src/inventory/inventory.controller.ts`
- Create: `sacdia-backend/src/inventory/dto/transfer-inventory-item.dto.ts`
- Modify: `sacdia-backend/prisma/schema.prisma`
- Create: `sacdia-backend/prisma/migrations/20260723170000_wave_b_activity_inventory_history/migration.sql`
- Modify: `docs/features/actividades.md`
- Modify: `docs/features/inventario.md`

**Step 1: Definir transición oficial antes de escribir**

- actividad: snapshot solo al marcarla `COMPLETED`; draft/update no snapshot;
- inventario: alta/update conservan auditoría; transferencia/baja registran
  ubicación efectiva y contexto, no snapshot por cada edición.

Agregar una transición explícita `POST /activities/:activityId/complete`. Para
inventario, agregar una operación de transferencia que reciba destino y motivo;
no modelar una transferencia como un UPDATE genérico del item.

**Step 2: Tests RED**

- completar actividad fija un snapshot una sola vez;
- reabrir requiere evento correctivo, no borrar snapshot;
- transferencia de inventario preserva origen/destino;
- baja no elimina `inventory_history`;
- historial usa contexto del evento y no la ubicación actual.

**Step 3: Implementar y ejecutar**

```bash
cd sacdia-backend
pnpm test -- --runInBand \
  src/activities/activities.service.spec.ts \
  src/inventory/inventory.service.spec.ts
```

Expected: PASS.

**Step 4: Commit**

```bash
git add prisma src/activities src/inventory
git commit -m "feat(history): preserve activity and inventory context"

cd ..
git add docs/features/actividades.md docs/features/inventario.md
git commit -m "docs(history): document activity and inventory context"
```

### Task 22: Membresía, cargos, clases, honores y reconocimientos

**Files:**
- Modify: `sacdia-backend/src/clubs/clubs.service.ts`
- Modify: `sacdia-backend/src/requests/requests.service.ts`
- Modify: `sacdia-backend/src/membership-requests/membership-requests.service.ts`
- Modify: `sacdia-backend/src/classes/classes.service.ts`
- Modify: `sacdia-backend/src/honors/honors.service.ts`
- Modify: `sacdia-backend/src/member-of-month/member-of-month.service.ts`
- Modify: corresponding `*.spec.ts` files
- Modify: `docs/features/gestion-clubs.md`
- Modify: `docs/features/clases-progresivas.md`
- Modify: `docs/features/honores.md`
- Modify: `docs/features/member-of-month.md`

**Step 1: Tests RED**

- asignaciones y transferencias conservan `start_date/end_date`;
- cambio de sección no borra trayectoria previa;
- validación de clase/honor hereda snapshot del enrollment;
- miembro del mes conserva sección/contexto del período;
- acceso histórico no sensible respeta el período de autoridad.

**Step 2: Implementar sin duplicar payload**

Usar relaciones temporales para cargos/membresía y snapshot en el acto oficial.
No copiar el contexto completo en cada progreso interno.

**Step 3: Ejecutar suites dirigidas**

```bash
cd sacdia-backend
pnpm test -- --runInBand \
  src/clubs/clubs.service.spec.ts \
  src/requests/requests.service.spec.ts \
  src/membership-requests/membership-requests.service.spec.ts \
  src/member-of-month/member-of-month.service.spec.ts
```

Expected: PASS.

**Step 4: Commit**

```bash
git add src/clubs src/requests src/membership-requests src/classes \
  src/honors src/member-of-month
git commit -m "feat(history): preserve member institutional trajectory"

cd ..
git add docs/features/gestion-clubs.md docs/features/clases-progresivas.md \
  docs/features/honores.md docs/features/member-of-month.md
git commit -m "docs(history): document member trajectory coverage"
```

### Task 23: Auditoría final de cobertura backend

**Files:**
- Create: `sacdia-backend/scripts/audit-institutional-history-coverage.ts`
- Create: `sacdia-backend/scripts/audit-institutional-history-coverage.spec.ts`
- Modify: `sacdia-backend/package.json`
- Create: `docs/audit/institutional-history-coverage-matrix.md`

**Step 1: Escribir prueba RED**

El auditor debe listar:

- tablas con FKs territoriales;
- servicios que mutan esas tablas;
- transición oficial;
- estrategia `effective`, `snapshot`, `audit` o `not-applicable`;
- test responsable;
- estado de cobertura.

Falla si aparece un write path institucional sin clasificación.

**Step 2: Implementar análisis conservador**

No pretender AST perfecto. Combinar una allowlist versionada con búsqueda de
campos estructurales y exigir revisión humana de nuevos hallazgos.

**Step 3: Ejecutar**

```bash
cd sacdia-backend
pnpm test -- --runInBand scripts/audit-institutional-history-coverage.spec.ts
pnpm exec tsx scripts/audit-institutional-history-coverage.ts
```

Expected: PASS y matriz sin `UNCLASSIFIED`.

**Step 4: Commit**

```bash
git add scripts package.json
git commit -m "test(history): enforce aggregate coverage matrix"

cd ..
git add docs/audit/institutional-history-coverage-matrix.md
git commit -m "docs(audit): record institutional history coverage"
```

---

## PR 6 — Admin y app móvil

### Task 24: Publicar contrato y handoff del admin

**Files:**
- Modify: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- Modify: `docs/api/FRONTEND-INTEGRATION-GUIDE.md`
- Modify: `docs/api/SECURITY-GUIDE.md`
- Modify: `docs/api/ARCHITECTURE-DECISIONS.md`
- Create: `docs/features/institutional-history.md`
- Create: `docs/handoffs/institutional-history-admin-handoff.md`

**Step 1: Documentar contrato final**

Incluir payloads, respuestas, permisos, errores, idempotencia, paginación,
`source`, `precision`, `at`, `knowledge_at` y reglas sensibles.

**Step 2: Handoff implementable a Cursor Composer**

Debe especificar:

- cliente API en `sacdia-admin/src/lib/api/institutional-history.ts`;
- tipos en `sacdia-admin/src/lib/types/institutional-history.ts`;
- formularios de renombre/traslado/split/merge/cierre/corrección;
- timeline y lineage read-only;
- badges de precisión;
- ninguna entrada de evidencia documental;
- separación visual de datos sensibles;
- tests Vitest.

La UI no se inicia hasta que el contrato backend quede estable.

**Step 3: Verificar docs**

```bash
git diff --check
```

Expected: sin errores.

**Step 4: Commit**

```bash
git add docs/api docs/features/institutional-history.md \
  docs/handoffs/institutional-history-admin-handoff.md
git commit -m "docs(history): publish integration contract"
```

### Task 25: Implementar cliente y superficies admin

> Ownership: ejecutar en `sacdia-admin` con el handoff aprobado; Codex valida
> contrato e integración, Cursor Composer realiza diseño visual y polish.

**Files:**
- Create: `sacdia-admin/src/lib/api/institutional-history.ts`
- Create: `sacdia-admin/src/lib/api/institutional-history.test.ts`
- Create: `sacdia-admin/src/lib/types/institutional-history.ts`
- Create: `sacdia-admin/src/app/(dashboard)/dashboard/institutional-history/page.tsx`
- Create: `sacdia-admin/src/components/institutional-history/institutional-history-page-client.tsx`
- Create: `sacdia-admin/src/components/institutional-history/reorganization-form.tsx`
- Create: `sacdia-admin/src/components/institutional-history/history-timeline.tsx`
- Create: `sacdia-admin/src/components/institutional-history/lineage-view.tsx`
- Modify: `sacdia-admin/src/components/catalogs/unions/union-form-dialog.tsx`
- Modify: `sacdia-admin/src/components/catalogs/local-fields/local-field-form-dialog.tsx`

**Step 1: Tests RED**

- serialización del comando discriminado;
- envío de `Idempotency-Key`;
- no existe campo de evidencia;
- timeline muestra fecha efectiva y de registro;
- precision `unknown/system_backfill` se presenta como advertencia;
- acciones estructurales salen del CRUD ordinario;
- usuario sin permiso no ve controles.

**Step 2: Implementar cliente y UI**

No replicar autorización en frontend como control de seguridad; usarla solo para
visibilidad. Backend sigue siendo autoridad.

**Step 3: Ejecutar**

```bash
cd sacdia-admin
pnpm test -- src/lib/api/institutional-history.test.ts \
  src/components/institutional-history
pnpm typecheck
pnpm lint src/lib/api/institutional-history.ts \
  src/components/institutional-history
```

Expected: PASS. No ejecutar `pnpm build`.

**Step 4: Commit**

```bash
git add src
git commit -m "feat(history): add institutional history admin"
```

### Task 26: Implementar lectura segura en app móvil

**Files:**
- Create: `sacdia-app/lib/features/institutional_history/data/datasources/institutional_history_remote_data_source.dart`
- Create: `sacdia-app/lib/features/institutional_history/data/models/institutional_history_model.dart`
- Create: `sacdia-app/lib/features/institutional_history/data/repositories/institutional_history_repository_impl.dart`
- Create: `sacdia-app/lib/features/institutional_history/domain/entities/institutional_history_entry.dart`
- Create: `sacdia-app/lib/features/institutional_history/domain/repositories/institutional_history_repository.dart`
- Create: `sacdia-app/lib/features/institutional_history/presentation/providers/institutional_history_providers.dart`
- Create: `sacdia-app/lib/features/institutional_history/presentation/views/institutional_history_view.dart`
- Modify: `sacdia-app/lib/features/profile/data/datasources/profile_remote_data_source.dart`
- Modify: `sacdia-app/lib/features/members/presentation/views/member_profile_view.dart`
- Modify: `sacdia-app/lib/features/profile/presentation/views/medical_info_view.dart`
- Create: `sacdia-app/lib/features/post_registration/presentation/views/sensitive_data_notice_view.dart`
- Test: `sacdia-app/test/features/institutional_history/`
- Test: `sacdia-app/test/features/profile/data/datasources/profile_remote_data_source_test.dart`

**Step 1: Tests RED**

- parseo de `source/precision/effective/recorded`;
- pantalla read-only;
- no permite acceder a payload sensible fuera del endpoint dedicado;
- finalidad sensible se envía solo en flujos de terceros autorizados;
- aviso y consentimiento muestran la versión aplicable y representación legal;
- logout invalida providers/caché;
- 403 no conserva datos de otro usuario en memoria.

**Step 2: Implementar Clean Architecture**

La app consume historia; no expone comandos ejecutivos salvo decisión posterior.
Los datos sensibles usan datasource separado y no se cachean de forma
persistente.

**Step 3: Ejecutar**

```bash
cd sacdia-app
flutter test test/features/institutional_history \
  test/features/profile/data/datasources/profile_remote_data_source_test.dart
flutter analyze
```

Expected: PASS. No ejecutar build.

**Step 4: Commit**

```bash
git add lib/features/institutional_history lib/features/profile \
  lib/features/members test/features
git commit -m "feat(history): add secure mobile history views"
```

---

## Verificación final cross-repo

### Task 27: Ejecutar matriz de aceptación

**Backend**

```bash
cd sacdia-backend
pnpm exec prisma validate
pnpm test -- --runInBand \
  src/institutional-history \
  src/sensitive-data \
  src/audit-logs \
  src/common/services/institutional-hierarchy.service.spec.ts
pnpm verify:institutional-hierarchy-migration -- --dry-run
pnpm exec tsx scripts/audit-institutional-history-coverage.ts
```

**Admin**

```bash
cd sacdia-admin
pnpm test -- src/lib/api/institutional-history.test.ts \
  src/components/institutional-history
pnpm typecheck
```

**App**

```bash
cd sacdia-app
flutter test test/features/institutional_history
flutter analyze
```

**Docs y whitespace**

```bash
cd ..
git diff --check
git -C sacdia-backend diff --check
git -C sacdia-admin diff --check
git -C sacdia-app diff --check
```

Expected: todos PASS; ningún build.

### Task 28: Validación funcional en base efímera

Ejecutar en una base PostgreSQL efímera, nunca en producción:

1. crear Unión 1, Campo A y club;
2. emitir un registro oficial con snapshot;
3. renombrar Unión 1;
4. verificar que el snapshot conserva el nombre anterior;
5. trasladar Campo A a Unión 2;
6. verificar nueva autoridad, autoridad anterior y límites temporales;
7. dividir y fusionar entidades de prueba;
8. aplicar corrección retroactiva y consultar con dos `knowledge_at`;
9. comprobar que un admin técnico no lee salud;
10. otorgar un grant temporal a Unión y comprobar expiración;
11. ejecutar retención en dry-run;
12. intentar UPDATE/DELETE directo sobre historia, auditoría y snapshots.

Guardar el resultado en:

`docs/audit/institutional-history-acceptance-YYYY-MM-DD.md`.

No desplegar enforcement hasta que el verificador reporte cero divergencias.

## Criterio de cierre

El trabajo se considera completo únicamente cuando:

- todos los write paths estructurales pasan por comandos;
- nombres y relaciones resuelven por fecha efectiva y fecha de registro;
- las autoridades anterior y vigente cumplen la matriz acordada;
- los datos sensibles aplican contexto, finalidad y vigencia;
- cada acto oficial clasificado posee snapshot o relación efectiva correcta;
- emisiones antiguas se reproducen sin consultar catálogos actuales;
- auditoría, snapshots y linaje son inmutables;
- la matriz de cobertura no contiene módulos sin clasificar;
- docs, backend, admin y app describen el mismo contrato.
