# Plan: integridad de clases progresivas + prerrequisitos + especialidades recomendadas

> **Para el agente ejecutor:** sigue este plan tarea por tarea, en orden. Cada tarea termina en commit. Si un supuesto del plan no coincide con el código real (nombres de campos, líneas, relaciones Prisma), verifica en el archivo indicado y adapta el detalle, pero NO cambies el diseño ni el alcance. Registra toda desviación en el reporte final (Fase 6).

**Objetivo:** cerrar los defectos de integridad P0 del módulo de clases progresivas y agregar dos features: (1) especialidades (honores) relacionadas a clases activando la tabla existente `class_honors`, y (2) prerrequisitos explícitos entre clases con tabla nueva `class_prerequisites`.

**Arquitectura:** monorepo con `sacdia-backend` (NestJS + Prisma + PostgreSQL/Neon), `sacdia-app` (Flutter, Clean Architecture) y `sacdia-admin` (Next.js 16 + shadcn/ui). El backend es contract-first: primero endpoints/DTOs/errores, después clientes.

**Contexto obligatorio antes de empezar:** leer `AGENTS.md` raíz, `docs/features/clases-progresivas-analisis-integral.md` (diagnóstico que origina este plan), `docs/features/honores.md`, `sacdia-backend/CLAUDE.md`.

**Reglas duras (de AGENTS.md):**
- Conventional commits. Nunca `Co-Authored-By` ni atribución de IA.
- No ejecutar builds; sí ejecutar tests del módulo afectado.
- No tocar `.env` reales ni secretos.
- Actualizar documentación canónica en el mismo trabajo (Fase 5).

**Decisiones ya tomadas (no re-discutir):**
1. Invariante anual: **una sola inscripción activa por usuario/año**, alineando el servicio al índice DB `uniq_enrollments_active_user_year` que ya lo impone en producción.
2. Completitud de sección: un requisito con `status = REJECTED` **nunca** computa como completo; se conserva `score >= 70` para estados no rechazados (fix mínimo, sin rediseñar el modelo de puntaje).
3. `class_honors`: se activa tal como existe en schema (`relation_type: REQUIRED | RECOMMENDED | ELECTIVE`). En esta fase las relaciones son **informativas** (no bloquean investidura), incluso `REQUIRED`. Documentarlo así.
4. `class_prerequisites`: tabla nueva, **aditiva**. `requires_invested_gm` sigue funcionando; no se migra en este trabajo. Prerrequisito cumplido = enrollment del usuario con `investiture_status = 'INVESTIDO'` en la clase prerequisito.

---

## Fase 0 — Preparación

### Task 0.1: Branch y baseline

**Step 1:** desde la raíz del workspace, crear branch en los tres repos:

```bash
cd sacdia-backend && git checkout -b feat/classes-integrity-prereqs-honors && cd ..
cd sacdia-admin && git checkout -b feat/classes-integrity-prereqs-honors && cd ..
cd sacdia-app && git checkout -b feat/classes-integrity-prereqs-honors && cd ..
```

**Step 2:** verificar runners de test:
- Backend: revisar `sacdia-backend/package.json` scripts (esperado: jest, `npm test -- <ruta>`).
- Admin: revisar `sacdia-admin/package.json` scripts (identificar si es jest o vitest y anotar el comando en el reporte).
- App: `flutter test` desde `sacdia-app/`.

**Step 3:** correr baseline del módulo afectado y guardar resultado para el reporte:

```bash
cd sacdia-backend && npm test -- src/classes src/evidence-review src/investiture
```

Expected: suite verde (si hay fallos preexistentes, anotarlos en el reporte y NO intentar arreglarlos).

---

## Fase 1 — Integridad P0 (solo backend)

### Task 1.1: Bloquear mutaciones de progreso por estado (`locked_for_validation` + estados terminales)

**Files:**
- Modify: `sacdia-backend/src/classes/classes.service.ts` (métodos `resolveProgressEnrollment` ~L80, `updateSectionProgress` ~L859, `uploadSectionFile` ~L980, y el método de borrado de archivo de sección)
- Modify: `sacdia-backend/src/common/errors/error-codes.ts` (~L383, bloque `CLASS_*`)
- Test: `sacdia-backend/src/classes/classes.service.spec.ts`

**Step 1:** agregar error code en `error-codes.ts`, junto al resto de `CLASS_*`:

```typescript
CLASS_PROGRESS_LOCKED = 'CLASS_PROGRESS_LOCKED',
```

Si el proyecto mapea códigos a mensajes/status HTTP en otro archivo (buscar usos de `CLASS_ALREADY_ENROLLED` para descubrirlo), registrar ahí también: HTTP 409, mensaje "La inscripción está bloqueada para validación o en estado terminal; el progreso no puede modificarse".

**Step 2:** escribir tests que fallen en `classes.service.spec.ts` (seguir el patrón de mocks existente en ese archivo):
- `updateSectionProgress` lanza `CLASS_PROGRESS_LOCKED` cuando el enrollment tiene `locked_for_validation = true`.
- `updateSectionProgress` lanza `CLASS_PROGRESS_LOCKED` cuando `investiture_status` es cada uno de: `SUBMITTED`, `CLUB_APPROVED`, `COORDINATOR_APPROVED`, `FIELD_APPROVED`, `INVESTIDO`, `EXPIRED`.
- `updateSectionProgress` NO lanza cuando el estado es `IN_PROGRESS` o `REJECTED`.
- Mismos tres casos para `uploadSectionFile` y para el delete de archivo de sección.

**Step 3:** correr y verificar que fallan:

```bash
npm test -- src/classes/classes.service.spec.ts
```

**Step 4:** implementar. En `resolveProgressEnrollment`, ampliar ambos `select` para incluir `locked_for_validation: true` y devolverlo en el retorno tipado:

```typescript
}): Promise<{
  enrollmentId: number;
  ecclesiasticalYearId: number;
  investitureStatus: string;
  lockedForValidation: boolean;
}> {
```

Agregar constante privada en la clase:

```typescript
private static readonly PROGRESS_MUTATION_BLOCKED_STATUSES = new Set([
  'SUBMITTED',
  'CLUB_APPROVED',
  'COORDINATOR_APPROVED',
  'FIELD_APPROVED',
  'INVESTIDO',
  'EXPIRED',
]);

private assertProgressMutable(enrollment: {
  investitureStatus: string;
  lockedForValidation: boolean;
}) {
  if (
    enrollment.lockedForValidation ||
    ClassesService.PROGRESS_MUTATION_BLOCKED_STATUSES.has(
      enrollment.investitureStatus,
    )
  ) {
    throw new AppConflictException(ErrorCode.CLASS_PROGRESS_LOCKED);
  }
}
```

Llamar `this.assertProgressMutable(resolvedEnrollment)` inmediatamente después de `resolveProgressEnrollment` + check de acceso en: `updateSectionProgress`, `uploadSectionFile` y el método de delete de archivo. (Verificar cómo resuelve enrollment cada uno; si upload/delete no usan `resolveProgressEnrollment`, cargar `locked_for_validation` e `investiture_status` del enrollment que ya consultan.)

**Step 5:** correr tests, verificar verde:

```bash
npm test -- src/classes/classes.service.spec.ts
```

**Step 6:** commit:

```bash
git add -A && git commit -m "fix(classes): block progress mutations when enrollment is locked or terminal"
```

### Task 1.2: Validar jerarquía curricular en PATCH de progreso

**Files:**
- Modify: `sacdia-backend/src/classes/classes.service.ts` (`updateSectionProgress`, ~L859–976)
- Test: `sacdia-backend/src/classes/classes.service.spec.ts`

**Step 1:** tests que fallen:
- `updateSectionProgress` lanza `CLASS_SECTION_NOT_FOUND` si `sectionId` no pertenece a `moduleId`.
- Lanza `CLASS_SECTION_NOT_FOUND` si `moduleId` no pertenece a `classId` de la ruta.
- Lanza `CLASS_SECTION_NOT_FOUND` si la sección o el módulo están `active = false`.
- Caso feliz: sección válida del módulo/clase → escribe progreso.

**Step 2:** correr, verificar que fallan.

**Step 3:** implementar. En `updateSectionProgress`, después de `assertProgressMutable` y antes de la transacción:

```typescript
const validSection = await this.prisma.class_sections.findFirst({
  where: {
    section_id: sectionId,
    module_id: moduleId,
    active: true,
    // Verificar en schema.prisma el nombre real de la relación
    // class_sections -> class_modules y usarlo aquí:
    class_modules: {
      module_id: moduleId,
      class_id: classId,
      active: true,
    },
  },
  select: { section_id: true },
});

if (!validSection) {
  throw new AppNotFoundException(ErrorCode.CLASS_SECTION_NOT_FOUND);
}
```

Tomar como referencia la validación que ya hace `uploadSectionFile` (~L980+), que sí verifica sección ∈ clase; replicar su estilo de query.

**Step 4:** correr tests del archivo, verde.

**Step 5:** commit:

```bash
git add -A && git commit -m "fix(classes): validate module/section hierarchy before writing progress"
```

### Task 1.3: Un requisito `REJECTED` nunca computa como completo

**Files:**
- Modify: `sacdia-backend/src/classes/classes.service.ts` (`isCompletedProgress`, ~L738–745)
- Modify: `sacdia-backend/src/classes/class-requirement-eligibility.service.ts` (~L130–136)
- Test: `sacdia-backend/src/classes/classes.service.spec.ts`, `sacdia-backend/src/classes/class-requirement-eligibility.service.spec.ts`

**Step 1:** tests que fallen en ambos spec:
- Sección con `status = REJECTED` y `score = 100` → NO completa / NO elegible.
- Sección con `status = VALIDATED` y `score = 0` → completa (comportamiento actual, no romper).
- Sección con `status = PENDING` y `score = 80` → completa (comportamiento actual conservado).

**Step 2:** correr, verificar fallo del primer caso.

**Step 3:** implementar en `classes.service.ts`:

```typescript
const isCompletedProgress = (
  progress: (typeof sectionProgress)[number] | undefined,
) =>
  Boolean(
    progress &&
      progress.status !== evidence_validation_enum.REJECTED &&
      (progress.status === evidence_validation_enum.VALIDATED ||
        progress.score >= 70),
  );
```

Aplicar la misma condición (`status !== REJECTED`) en el cálculo equivalente de `class-requirement-eligibility.service.ts` ~L130–136.

**Step 4:** correr ambos spec, verde.

**Step 5:** commit:

```bash
git add -A && git commit -m "fix(classes): rejected sections never count as completed for progress or eligibility"
```

### Task 1.4: Alinear invariante anual GM con la base de datos

**Files:**
- Modify: `sacdia-backend/src/classes/classes.service.ts` (`enrollUser`, bloque GM ~L477–489)
- Test: `sacdia-backend/src/classes/classes.service.spec.ts`

**Step 1:** localizar tests existentes de `CLASS_MAX_GM_ACTIVE` en el spec y ajustarlos: ahora el límite es **1** inscripción activa GM por usuario/año (la DB ya impone 1 activa total vía índice `uniq_enrollments_active_user_year`). Agregar test: con 1 GM activa, segunda inscripción GM del mismo año lanza `CLASS_MAX_GM_ACTIVE`.

**Step 2:** implementar: en el bloque `else if (isGm)`, cambiar `if (activeCount >= 2)` por `if (activeCount >= 1)`. Agregar comentario:

```typescript
// DB enforces a single active enrollment per user/year via the partial
// unique index uniq_enrollments_active_user_year; keep the service rule
// aligned so violations surface as CLASS_MAX_GM_ACTIVE instead of a raw
// unique-constraint error.
```

**Step 3:** correr spec, verde.

**Step 4:** commit:

```bash
git add -A && git commit -m "fix(classes): align GM active-enrollment limit with DB unique index (1 per year)"
```

### Task 1.5: Rechazo individual de evidencia exige `SUBMITTED`

**Files:**
- Modify: `sacdia-backend/src/evidence-review/evidence-review.service.ts` (`rejectClass`, ~L1154–1175)
- Test: `sacdia-backend/src/evidence-review/evidence-review.service.spec.ts`

**Step 1:** test que falle: rechazar un registro de clase con `status = PENDING` lanza `EVIDENCE_REVIEW_RECORD_NOT_PENDING` (usar el mismo error que ya usa `approveClass` cuando el estado no es `SUBMITTED`; verificar el nombre exacto en `approveClass` ~L1089 y replicarlo).

**Step 2:** implementar en `rejectClass`: además de los bloqueos existentes (`REJECTED`, `VALIDATED`), exigir `status === SUBMITTED` con el mismo patrón de `approveClass`.

**Step 3:** correr spec, verde. Verificar que los tests de bulk-reject sigan pasando (si el bulk filtra por `SUBMITTED` ya, no cambia nada).

**Step 4:** commit:

```bash
git add -A && git commit -m "fix(evidence-review): individual class rejection requires SUBMITTED status"
```

### Task 1.6: Regresión completa de Fase 1

**Step 1:**

```bash
npm test -- src/classes src/evidence-review src/investiture src/post-registration
```

Expected: verde (salvo fallos preexistentes anotados en Task 0.1). Si algo nuevo falla, arreglar antes de continuar.

---

## Fase 2 — Especialidades por clase (activar `class_honors`)

Modelo ya existente en `sacdia-backend/prisma/schema.prisma` ~L1341–1355: `class_honors(class_honor_id, class_id, honor_id, relation_type RECOMMENDED|REQUIRED|ELECTIVE, active)` con unique `[class_id, honor_id, relation_type]`. **No modificar schema en esta fase.**

### Task 2.1: Backend — `GET /classes/:classId/honors` (catálogo público con estado opcional del usuario)

**Files:**
- Modify: `sacdia-backend/src/classes/classes.service.ts`
- Modify: `sacdia-backend/src/classes/classes.controller.ts` (junto a `GET /classes/:classId/modules`, que usa `OptionalJwtAuthGuard`)
- Test: `sacdia-backend/src/classes/classes.service.spec.ts`, `classes.controller.spec.ts`

**Step 1:** tests que fallen:
- Servicio devuelve relaciones activas con honor activo, agrupables por `relation_type`.
- Clase inexistente → `CLASS_NOT_FOUND`.
- Con `userId`: incluye `user_status` por honor desde `users_honors` (campo de estado: verificar nombre en schema, esperado `validation_status`); sin `userId`: `user_status: null`.

**Step 2:** implementar en el servicio:

```typescript
async getClassHonors(classId: number, userId?: string) {
  const classExists = await this.prisma.classes.findFirst({
    where: { class_id: classId, active: true },
    select: { class_id: true },
  });
  if (!classExists) {
    throw new AppNotFoundException(ErrorCode.CLASS_NOT_FOUND);
  }

  const relations = await this.prisma.class_honors.findMany({
    where: { class_id: classId, active: true, honor: { active: true } },
    include: {
      honor: {
        select: {
          honor_id: true,
          name: true,
          honor_image: true,
          honors_category_id: true,
          skill_level: true,
        },
      },
    },
    orderBy: [{ relation_type: 'asc' }, { honor: { name: 'asc' } }],
  });

  let userHonorsByHonorId = new Map<number, string>();
  if (userId && relations.length > 0) {
    const userHonors = await this.prisma.users_honors.findMany({
      where: {
        user_id: userId,
        honor_id: { in: relations.map((r) => r.honor_id) },
      },
      // Verificar en schema.prisma los nombres reales de columnas de
      // users_honors (estado de validación) y ajustar el select.
      select: { honor_id: true, validation_status: true },
    });
    userHonorsByHonorId = new Map(
      userHonors.map((uh) => [uh.honor_id, uh.validation_status]),
    );
  }

  return relations.map((relation) => ({
    class_honor_id: relation.class_honor_id,
    relation_type: relation.relation_type,
    honor: relation.honor,
    user_status: userHonorsByHonorId.get(relation.honor_id) ?? null,
  }));
}
```

**Step 3:** controller — replicar exactamente el patrón de `GET /classes/:classId/modules` (mismo guard `OptionalJwtAuthGuard`, misma forma de extraer user opcional):

```typescript
@Get(':classId/honors')
@UseGuards(OptionalJwtAuthGuard)
async getClassHonors(
  @Param('classId', ParseIntPipe) classId: number,
  @Req() req: RequestWithOptionalUser,
) {
  return this.classesService.getClassHonors(classId, req.user?.userId);
}
```

(Adaptar decoradores/typing al patrón real del controller; verificar cómo obtienen el user opcional los endpoints vecinos.)

**Step 4:** correr specs de classes, verde.

**Step 5:** commit:

```bash
git add -A && git commit -m "feat(classes): expose class honors catalog with optional user status"
```

### Task 2.2: Backend — CRUD admin de relaciones clase-honor

**Files:**
- Modify: `sacdia-backend/src/admin/admin-phase-e-catalogs.controller.ts` y su servicio (seguir el patrón exacto del CRUD de `class-sections` que vive ahí: guards, permisos `catalogs:read|create|update|delete`, DTOs con class-validator)
- Modify: `sacdia-backend/src/common/errors/error-codes.ts`
- Test: spec del servicio Phase E (localizar el existente junto al controller)

**Step 1:** error codes nuevos:

```typescript
ADMIN_CLASS_HONOR_NOT_FOUND = 'ADMIN_CLASS_HONOR_NOT_FOUND',
ADMIN_CLASS_HONOR_DUPLICATE = 'ADMIN_CLASS_HONOR_DUPLICATE',
```

**Step 2:** endpoints (mismos guards/permisos que el CRUD de secciones):
- `GET /admin/classes/:classId/honors` → lista relaciones (incluye inactivas, filtro `active?`).
- `POST /admin/classes/:classId/honors` → body `{ honor_id: number, relation_type: 'REQUIRED' | 'RECOMMENDED' | 'ELECTIVE' }`. Valida clase y honor existentes; duplicado activo `[class_id, honor_id, relation_type]` → `ADMIN_CLASS_HONOR_DUPLICATE` (409).
- `DELETE /admin/classes/:classId/honors/:classHonorId` → soft delete (`active = false`), inexistente → `ADMIN_CLASS_HONOR_NOT_FOUND` (404).

**Step 3:** tests: crear, duplicado, delete, not found. Correr, verde.

**Step 4:** commit:

```bash
git add -A && git commit -m "feat(admin): manage class-honor relations in Phase E catalogs"
```

### Task 2.3: Admin — UI de especialidades en catálogo de clases

**Files:**
- Create: `sacdia-admin/src/lib/api/class-honors.ts`
- Modify: componentes del catálogo de clases Phase E (localizar con `Grep` de `phase-e` y `classes` en `sacdia-admin/src/components/catalogs/`; el CRUD de clases vive en la página `dashboard/catalogs`)
- Test: seguir convención de tests existente en `sacdia-admin` (ver Task 0.1)

**Step 1:** cliente API `class-honors.ts` siguiendo el patrón de `sacdia-admin/src/lib/api/phase-e-catalogs.ts` (mismo fetch wrapper, manejo de errores y tipos):

```typescript
export type ClassHonorRelationType = "REQUIRED" | "RECOMMENDED" | "ELECTIVE";

export interface ClassHonorRelation {
  class_honor_id: number;
  relation_type: ClassHonorRelationType;
  active: boolean;
  honor: {
    honor_id: number;
    name: string;
    honor_image: string | null;
    honors_category_id: number | null;
    skill_level: number | null;
  };
}
```

Funciones: `getClassHonors(classId)`, `createClassHonor(classId, { honor_id, relation_type })`, `deleteClassHonor(classId, classHonorId)`.

**Step 2:** UI: en la fila/detalle de clase del catálogo, agregar acción "Especialidades" que abre un diálogo (shadcn `Dialog`) con:
- lista de relaciones actuales agrupadas por tipo, con badge de `relation_type` y botón eliminar (con confirmación);
- formulario para agregar: combobox de honores (reusar el cliente de catálogo de honores existente, `sacdia-admin/src/lib/api/admin-honors-catalog.ts`) + select de tipo de relación (default `RECOMMENDED`).
Seguir el estilo de los diálogos CRUD ya existentes en catálogos Phase E.

**Step 3:** test de componente básico (render de lista + submit) según convención del repo. Correr suite admin del área tocada.

**Step 4:** commit:

```bash
git add -A && git commit -m "feat(catalogs): class honors management dialog in classes catalog"
```

### Task 2.4: App móvil — especialidades recomendadas en detalle de clase

**Files:**
- Modify: `sacdia-app/lib/features/classes/data/datasources/classes_remote_data_source.dart`
- Create: entidad + model `class_honor` en `sacdia-app/lib/features/classes/domain/entities/` y `data/models/` (seguir estructura de entidades existentes del feature)
- Modify: vista de detalle/roadmap de clase (localizar en `sacdia-app/lib/features/classes/presentation/views/` la vista que muestra módulos de la clase)
- Test: `sacdia-app/test/features/classes/` (seguir convención de tests de models/datasource existentes)

**Step 1:** model/entidad `ClassHonor`: `classHonorId`, `relationType` (enum `required|recommended|elective`), `honorId`, `honorName`, `honorImage`, `userStatus` (nullable). Test de parseo JSON primero, correr, fallo, implementar, verde.

**Step 2:** datasource: método `getClassHonors(int classId)` → `GET /classes/:classId/honors` (usar el mismo cliente HTTP/base URL del datasource; ver métodos vecinos). Test de datasource con mock siguiendo patrón existente.

**Step 3:** UI: en la vista de detalle de clase, agregar sección "Especialidades recomendadas" debajo de los módulos:
- chips/cards horizontales con imagen y nombre del honor, badge por `relationType` y check si `userStatus` indica completado/validado;
- tap navega a la ruta existente de detalle de honor (`/honor/:honorId`; verificar nombre exacto en `sacdia-app/lib/core/router/route_names.dart`);
- si la lista es vacía, no renderizar la sección.
Gestionar estado con el mismo patrón del feature (bloc/cubit/provider que use la vista; replicarlo).

**Step 4:** correr `flutter test test/features/classes/` y `flutter analyze lib/features/classes` — verde/sin issues nuevos.

**Step 5:** commit:

```bash
git add -A && git commit -m "feat(classes): show recommended honors in class detail"
```

---

## Fase 3 — Prerrequisitos entre clases

### Task 3.1: Schema + migración `class_prerequisites`

**Files:**
- Modify: `sacdia-backend/prisma/schema.prisma`
- Create: `sacdia-backend/prisma/migrations/<timestamp>_class_prerequisites/migration.sql`

**Step 1:** agregar modelo (colocar cerca de `classes`; agregar las dos relaciones inversas en el modelo `classes`):

```prisma
model class_prerequisites {
  class_prerequisite_id Int      @id @default(autoincrement())
  class_id              Int
  prerequisite_class_id Int
  active                Boolean  @default(true)
  created_at            DateTime @default(now()) @db.Timestamptz(6)
  modified_at           DateTime @default(now()) @db.Timestamptz(6)

  class        classes @relation("class_prerequisites_class", fields: [class_id], references: [class_id], onDelete: Cascade, onUpdate: NoAction)
  prerequisite classes @relation("class_prerequisites_prerequisite", fields: [prerequisite_class_id], references: [class_id], onDelete: Cascade, onUpdate: NoAction)

  @@unique([class_id, prerequisite_class_id])
  @@index([prerequisite_class_id])
}
```

En `classes`:

```prisma
  prerequisites          class_prerequisites[] @relation("class_prerequisites_class")
  prerequisite_of        class_prerequisites[] @relation("class_prerequisites_prerequisite")
```

**Step 2:** generar migración SQL. Seguir el formato de las migraciones existentes (ver `prisma/migrations/20260512000000_unique_active_enrollment_per_user_year/migration.sql` como referencia de estilo). SQL:

```sql
CREATE TABLE "class_prerequisites" (
    "class_prerequisite_id" SERIAL PRIMARY KEY,
    "class_id" INTEGER NOT NULL,
    "prerequisite_class_id" INTEGER NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "modified_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "class_prerequisites_class_id_fkey"
        FOREIGN KEY ("class_id") REFERENCES "classes"("class_id")
        ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT "class_prerequisites_prerequisite_class_id_fkey"
        FOREIGN KEY ("prerequisite_class_id") REFERENCES "classes"("class_id")
        ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT "class_prerequisites_no_self_reference"
        CHECK ("class_id" <> "prerequisite_class_id")
);

CREATE UNIQUE INDEX "class_prerequisites_class_id_prerequisite_class_id_key"
    ON "class_prerequisites"("class_id", "prerequisite_class_id");

CREATE INDEX "class_prerequisites_prerequisite_class_id_idx"
    ON "class_prerequisites"("prerequisite_class_id");
```

**Step 3:** `npx prisma generate` (necesario para el cliente; no es build de app). NO ejecutar `prisma migrate deploy` contra la DB real: dejar la migración versionada y anotar en el reporte que está pendiente de aplicar.

**Step 4:** commit:

```bash
git add -A && git commit -m "feat(db): add class_prerequisites table for explicit class prerequisites"
```

### Task 3.2: Backend — validar prerrequisitos en inscripción

**Files:**
- Modify: `sacdia-backend/src/classes/classes.service.ts` (`enrollUser`, insertar después del bloque `requires_invested_gm` ~L443 y antes de `validateDisplayOrderProgression`)
- Modify: `sacdia-backend/src/common/errors/error-codes.ts`
- Test: `sacdia-backend/src/classes/classes.service.spec.ts`

**Step 1:** error code:

```typescript
CLASS_PREREQUISITE_NOT_MET = 'CLASS_PREREQUISITE_NOT_MET',
```

(HTTP 403, mismo registro de mensajes que Task 1.1 si aplica.)

**Step 2:** tests que fallen:
- Clase con prerrequisito no investido → `CLASS_PREREQUISITE_NOT_MET`.
- Clase con prerrequisito investido (enrollment `investiture_status = 'INVESTIDO'`) → inscripción procede.
- Clase sin prerrequisitos → sin cambios de comportamiento.
- Prerrequisito `active = false` se ignora.

**Step 3:** implementar dentro de la transacción de `enrollUser`:

```typescript
// 2b. Explicit class prerequisites: every active prerequisite must be
// INVESTIDO for this user, regardless of year.
const prerequisites = await tx.class_prerequisites.findMany({
  where: { class_id: classId, active: true },
  include: {
    prerequisite: { select: { class_id: true, name: true } },
  },
});

if (prerequisites.length > 0) {
  const investedClassIds = new Set(
    (
      await tx.enrollments.findMany({
        where: {
          user_id: userId,
          investiture_status: 'INVESTIDO',
          class_id: {
            in: prerequisites.map((p) => p.prerequisite_class_id),
          },
        },
        select: { class_id: true },
      })
    ).map((enrollment) => enrollment.class_id),
  );

  const missing = prerequisites.filter(
    (p) => !investedClassIds.has(p.prerequisite_class_id),
  );

  if (missing.length > 0) {
    throw new AppForbiddenException(ErrorCode.CLASS_PREREQUISITE_NOT_MET, {
      missing_prerequisites: missing.map((p) => ({
        class_id: p.prerequisite.class_id,
        name: p.prerequisite.name,
      })),
    });
  }
}
```

(Verificar la firma real de `AppForbiddenException`: si no acepta payload de detalles, buscar cómo otros errores adjuntan `details` en este proyecto y usar ese mecanismo; si no existe, lanzar sin detalles y listar los nombres en el mensaje.)

**Step 4:** correr spec, verde.

**Step 5:** commit:

```bash
git add -A && git commit -m "feat(classes): enforce explicit class prerequisites on enrollment"
```

### Task 3.3: Backend — CRUD admin de prerrequisitos + anti-ciclos

**Files:**
- Modify: `sacdia-backend/src/admin/admin-phase-e-catalogs.controller.ts` y servicio (mismo patrón que Task 2.2)
- Modify: `sacdia-backend/src/common/errors/error-codes.ts`
- Test: spec del servicio Phase E

**Step 1:** error codes:

```typescript
ADMIN_CLASS_PREREQUISITE_NOT_FOUND = 'ADMIN_CLASS_PREREQUISITE_NOT_FOUND',
ADMIN_CLASS_PREREQUISITE_DUPLICATE = 'ADMIN_CLASS_PREREQUISITE_DUPLICATE',
ADMIN_CLASS_PREREQUISITE_CYCLE = 'ADMIN_CLASS_PREREQUISITE_CYCLE',
```

**Step 2:** endpoints:
- `GET /admin/classes/:classId/prerequisites`
- `POST /admin/classes/:classId/prerequisites` → body `{ prerequisite_class_id: number }`
- `DELETE /admin/classes/:classId/prerequisites/:prerequisiteId` → soft delete

**Step 3:** validación anti-ciclos en el POST (antes de crear): BFS desde `prerequisite_class_id` siguiendo relaciones activas; si se alcanza `class_id`, rechazar:

```typescript
private async assertNoPrerequisiteCycle(
  tx: Prisma.TransactionClient,
  classId: number,
  prerequisiteClassId: number,
) {
  if (classId === prerequisiteClassId) {
    throw new AppBadRequestException(
      ErrorCode.ADMIN_CLASS_PREREQUISITE_CYCLE,
    );
  }
  const visited = new Set<number>([prerequisiteClassId]);
  let frontier = [prerequisiteClassId];
  while (frontier.length > 0) {
    const rows = await tx.class_prerequisites.findMany({
      where: { class_id: { in: frontier }, active: true },
      select: { prerequisite_class_id: true },
    });
    frontier = [];
    for (const row of rows) {
      if (row.prerequisite_class_id === classId) {
        throw new AppBadRequestException(
          ErrorCode.ADMIN_CLASS_PREREQUISITE_CYCLE,
        );
      }
      if (!visited.has(row.prerequisite_class_id)) {
        visited.add(row.prerequisite_class_id);
        frontier.push(row.prerequisite_class_id);
      }
    }
  }
}
```

**Step 4:** tests: crear, duplicado, auto-referencia, ciclo indirecto (A→B, intentar B→A), delete, not found. Correr, verde.

**Step 5:** commit:

```bash
git add -A && git commit -m "feat(admin): manage class prerequisites with cycle validation"
```

### Task 3.4: Backend — exponer prerrequisitos en detalle de clase

**Files:**
- Modify: `sacdia-backend/src/classes/classes.service.ts` (método del detalle `GET /classes/:classId`)
- Test: `classes.service.spec.ts`

**Step 1:** en la respuesta del detalle de clase, incluir:

```typescript
prerequisites: [
  { class_id, name }, // desde class_prerequisites activos con include de prerequisite
]
```

Test primero (detalle incluye prerrequisitos activos; excluye inactivos), luego implementación, verde.

**Step 2:** commit:

```bash
git add -A && git commit -m "feat(classes): include prerequisites in class detail response"
```

### Task 3.5: Admin — UI de prerrequisitos en catálogo de clases

**Files:**
- Create: `sacdia-admin/src/lib/api/class-prerequisites.ts` (mismo patrón que Task 2.3)
- Modify: mismos componentes de catálogo de clases de Task 2.3

**Step 1:** cliente API: `getClassPrerequisites(classId)`, `createClassPrerequisite(classId, { prerequisite_class_id })`, `deleteClassPrerequisite(classId, prerequisiteId)`.

**Step 2:** UI: en el mismo diálogo/zona de gestión de la clase, sección "Prerrequisitos": lista actual con eliminar + combobox de clases (excluir la propia clase). Mostrar error legible cuando el backend responda `ADMIN_CLASS_PREREQUISITE_CYCLE` ("Crearía un ciclo de prerrequisitos") y `..._DUPLICATE`.

**Step 3:** test de componente según convención; correr área tocada.

**Step 4:** commit:

```bash
git add -A && git commit -m "feat(catalogs): class prerequisites management in classes catalog"
```

### Task 3.6: App móvil — mostrar prerrequisitos y error de inscripción

**Files:**
- Modify: model/entidad de clase en `sacdia-app/lib/features/classes/` (agregar `prerequisites: List<ClassPrerequisite>` al modelo del detalle; entidad simple `classId` + `name`)
- Modify: vista de detalle de clase (misma de Task 2.4) y flujo de inscripción
- Test: `sacdia-app/test/features/classes/`

**Step 1:** parseo del campo `prerequisites` en el model del detalle (test primero).

**Step 2:** UI: si la clase tiene prerrequisitos, mostrar bloque "Requiere: <nombres>" en el detalle.

**Step 3:** manejo de error: donde el feature mapea códigos de error del backend (buscar `CLASS_ALREADY_ENROLLED` o `CLASS_LEVEL_TOO_HIGH` en `sacdia-app/lib` para localizar el mapeo), agregar `CLASS_PREREQUISITE_NOT_MET` con mensaje: "Debes estar investido en las clases previas requeridas para inscribirte."

**Step 4:** `flutter test test/features/classes/` + `flutter analyze lib/features/classes` — verde.

**Step 5:** commit:

```bash
git add -A && git commit -m "feat(classes): surface class prerequisites and enrollment error in app"
```

---

## Fase 4 — Regresión global

### Task 4.1: Suites completas por repo

```bash
cd sacdia-backend && npm test -- src/classes src/evidence-review src/investiture src/admin src/post-registration
cd sacdia-app && flutter test test/features/classes/ && flutter analyze lib/features/classes
cd sacdia-admin && <comando de test identificado en Task 0.1, área de catálogos>
```

Expected: todo verde. Guardar salidas (resumen: N passed / N failed) para el reporte. NO ejecutar builds.

---

## Fase 5 — Sincronización de documentación

### Task 5.1: Actualizar docs canónicas

**Files (todos en el repo raíz `sacdia`):**
- `docs/api/ENDPOINTS-LIVE-REFERENCE.md`: agregar `GET /classes/:classId/honors`, `GET/POST/DELETE /admin/classes/:classId/honors`, `GET/POST/DELETE /admin/classes/:classId/prerequisites`; anotar nuevos códigos de error y el cambio de regla GM.
- `docs/database/SCHEMA-REFERENCE.md` y `docs/database/schema.prisma`: reflejar `class_prerequisites` (copiar el modelo desde el schema del backend).
- `docs/features/clases-progresivas.md`: sección nueva "Prerrequisitos entre clases" y "Especialidades relacionadas"; regla anual GM actualizada (1 activa).
- `docs/features/honores.md`: marcar `class_honors` como activo en runtime con sus endpoints.
- `docs/features/clases-progresivas-analisis-integral.md`: actualizar sección 14 (marcar hallazgos resueltos: PATCH curricular, lock, REJECTED-score, GM, reject SUBMITTED) y sección 15 (P0 1–4 y P1-9 implementados). Respetar la regla de la sección 18 del propio documento.

**Commit (en repo raíz):**

```bash
git add docs && git commit -m "docs: sync API, schema and feature docs with class prerequisites and honors"
```

---

## Fase 6 — Reporte final (obligatorio)

### Task 6.1: Generar reporte

**Create:** `docs/reports/2026-08-11-implementacion-clases-prerequisitos-honores.md`

Estructura exacta:

```markdown
# Reporte de implementación — integridad clases + prerrequisitos + especialidades

**Fecha:** <fecha>
**Branches:** <branch por repo>
**Plan seguido:** docs/plans/2026-08-11-clases-progresivas-integridad-prerequisitos-honores.md

## 1. Resumen ejecutivo
<3-5 líneas: qué se implementó, qué quedó pendiente>

## 2. Tareas del plan
| Tarea | Estado (completa/parcial/omitida) | Commit(s) | Notas |
|---|---|---|---|
<una fila por Task 0.1 … 6.1>

## 3. Desviaciones del plan
<toda diferencia entre lo que el plan decía y lo que se hizo, con motivo.
Incluir supuestos del plan que resultaron incorrectos (nombres de campos,
relaciones, firmas de excepciones, ubicación de componentes)>

## 4. Tests
| Repo | Comando | Resultado (passed/failed) |
|---|---|---|
<baseline de Task 0.1 y regresión de Task 4.1; pegar resumen de salida>

## 5. Archivos modificados/creados
<lista por repo, con una línea de propósito por archivo>

## 6. Decisiones tomadas durante la ejecución
<decisiones no cubiertas por el plan, con justificación>

## 7. Pendientes y riesgos
<mínimo esperado:
- migración class_prerequisites versionada pero NO aplicada a la DB
- semántica de class_honors REQUIRED sigue siendo informativa
- requires_invested_gm no migrado a class_prerequisites
- cualquier fallo preexistente detectado en baseline>

## 8. Verificación manual sugerida
<pasos concretos para que un humano valide cada feature en dev>
```

**Commit (repo raíz):**

```bash
git add docs/reports && git commit -m "docs: implementation report for classes integrity, prerequisites and honors"
```

---

## Fuera de alcance (NO hacer)

- Fix del selector de archivos en corrección mobile (`_triggerFilePicker`) — trabajo separado.
- URL de historial en admin (`investiture.ts`) — trabajo separado.
- Exponer `advanced_enabled`/tracks/owners en admin — trabajo separado.
- Auditoría de índices legacy de progreso — trabajo separado.
- Reutilizar `ClassAssignmentResolverService` en inscripción directa (edad/tipo de club) — requiere decisión de producto.
- Aplicar migraciones contra la base de datos real.
- Ejecutar builds de cualquiera de los tres proyectos.
