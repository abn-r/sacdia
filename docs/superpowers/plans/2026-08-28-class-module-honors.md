# Class Module Honors Implementation Plan

> **For agentic workers:** Execute inline in this session. Spec: `docs/superpowers/specs/2026-08-28-class-module-honors-design.md`.

**Goal:** Anclar `class_honors` a un módulo opcional; admin asigna; app muestra PDF e inscribe por el flujo existente de especialidades. Sin gate de progreso ni investidura.

**Architecture:** Columna nullable `module_id` en `class_honors`. POST/PATCH admin. GET público añade `module_id`, `module_name`, `material_url`. Módulos embeben `honors[]`. App agrupa por módulo y reusa `honor_detail_view`.

**Tech Stack:** NestJS + Prisma, Next.js admin, Flutter app.

---

### Task 1: Schema + migración

**Files:**
- Modify: `sacdia-backend/prisma/schema.prisma` (`class_honors`, `class_modules`)
- Create: `sacdia-backend/prisma/migrations/20260828140000_class_honors_module/migration.sql`
- Modify: `docs/database/schema.prisma` (espejo)
- Modify: `docs/database/SCHEMA-REFERENCE.md`

Prisma `class_honors`:

```prisma
module_id Int?

class   classes       @relation(...)
honor   honors        @relation(...)
module  class_modules? @relation(fields: [module_id], references: [module_id], onDelete: SetNull, onUpdate: NoAction)

@@index([module_id], map: "idx_class_honors_module")
```

`class_modules`: `class_honors class_honors[]`

SQL:

```sql
ALTER TABLE "class_honors"
  ADD COLUMN IF NOT EXISTS "module_id" INTEGER;

ALTER TABLE "class_honors"
  ADD CONSTRAINT "class_honors_module_id_fkey"
  FOREIGN KEY ("module_id") REFERENCES "class_modules"("module_id")
  ON DELETE SET NULL ON UPDATE NO ACTION;

CREATE INDEX IF NOT EXISTS "idx_class_honors_module"
  ON "class_honors"("module_id");
```

Run: `cd sacdia-backend && npx prisma generate`

No aplicar a Neon en esta task.

---

### Task 2: DTO + PATCH admin

**Files:**
- Modify: `sacdia-backend/src/admin/dto/phase-e-catalogs.dto.ts`
- Modify: `sacdia-backend/src/admin/admin-phase-e-catalogs.controller.ts`

En `CreateClassHonorDto` añadir:

```ts
@ApiPropertyOptional({ example: 12, nullable: true })
@IsOptional()
@IsInt()
@Min(1)
@Type(() => Number)
module_id?: number | null;
```

Nuevo `UpdateClassHonorDto`:

```ts
export class UpdateClassHonorDto {
  @ApiPropertyOptional({ nullable: true, description: 'null quita el módulo' })
  @IsOptional()
  @ValidateIf((_, v) => v !== null)
  @IsInt()
  @Min(1)
  @Type(() => Number)
  module_id?: number | null;
}
```

Controller: `PATCH classes/:classId/honors/:classHonorId` con `@RequirePermissions('catalogs:update')`.

---

### Task 3: Admin service + tests

**Files:**
- Modify: `sacdia-backend/src/admin/admin-phase-e-catalogs.service.ts`
- Modify: `sacdia-backend/src/admin/admin-phase-e-catalogs.service.spec.ts`

Helper `assertModuleForClass(classId, moduleId)`: `findFirst` `class_modules` `{ module_id, class_id, active: true }`. Si falta → `AppNotFoundException(ADMIN_CLASS_MODULE_NOT_FOUND)`.

`createClassHonor`: si `dto.module_id` truthy, assert; persistir `module_id`. Include `module: { select: { module_id, name } }` y `honor.material_url`.

`updateClassHonor(classId, classHonorId, dto, actorId)`: fila activa de esa clase; si `module_id === null` set null; si number, assert; `modified_at`.

`findClassHonors`: mismo include de módulo + `material_url`.

Tests Jest (ampliar suite existente de `createClassHonor`):
- create con módulo de la clase
- create con módulo de otra clase → `ADMIN_CLASS_MODULE_NOT_FOUND`
- PATCH `module_id: null` limpia
- PATCH módulo válido

Run: `cd sacdia-backend && ./node_modules/.bin/jest src/admin/admin-phase-e-catalogs.service.spec.ts --no-coverage`

---

### Task 4: GET público + embed en módulos

**Files:**
- Modify: `sacdia-backend/src/classes/classes.service.ts` (`getClassHonors`, `findOne` / `getModules`)
- Modify: `sacdia-backend/src/classes/classes.service.spec.ts` (`describe('getClassHonors')`)

`getClassHonors` include:

```ts
honor: { select: { honor_id, name, honor_image, material_url, honors_category_id, skill_level } }
module: { select: { module_id, name } }
```

Map:

```ts
{
  class_honor_id,
  relation_type,
  module_id: relation.module_id ?? null,
  module_name: relation.module?.name ?? null,
  honor: relation.honor,
  user_status: ...,
}
```

En `findOne`, incluir `class_honors` activos bajo `class_modules` (honor activo + `material_url`) **o** cargar `class_honors` y adjuntar por `module_id` tras traducir módulos. JWT user_status solo si hay `userId` (getModules/findOne hoy no reciben user; embed sin `user_status` en módulos está bien; el progreso usa `GET .../honors` con JWT).

Tests: GET incluye `material_url` y `module_id`; sin módulo → nulls. Actualizar expect actuales de `getClassHonors` que no contemplan los campos nuevos.

Run: `cd sacdia-backend && ./node_modules/.bin/jest src/classes/classes.service.spec.ts --no-coverage`

---

### Task 5: Docs canónicas

**Files:**
- Modify: `docs/features/clases-progresivas.md` (sección Especialidades relacionadas)
- Modify: `docs/features/honores.md` (`class_honors` + módulo + PDF + enroll)
- Modify: `docs/api/ENDPOINTS-LIVE-REFERENCE.md` (POST body `module_id`; fila PATCH nueva; nota GET público)

Dejar explícito: informativo, sin gate.

---

### Task 6: Admin UI

**Files:**
- Modify: `sacdia-admin/src/lib/api/class-honors.ts` (`module_id`, `module?`, `updateClassHonor`)
- Modify: `sacdia-admin/src/lib/api/class-honors.test.ts` si existe; si no, ampliar `class-honors-dialog.test.tsx`
- Modify: `sacdia-admin/src/components/classes/class-honors-dialog.tsx`
- Modify: `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/classes/[classId]/page.tsx` (pasar módulos al diálogo)
- Modify: `sacdia-admin/src/components/classes/class-module-tree.tsx` (chips por `module_id`)
- Modify: `sacdia-admin/src/lib/api/classes.ts` (`honors?` en `ClassModule` si el árbol los usa)

Diálogo: Select módulo (opciones = módulos de la página) valor sentinela `none`. Create envía `module_id`. Lista: nombre de módulo. Mover existente: `updateClassHonor`.

Run: `cd sacdia-admin && pnpm exec vitest run src/components/classes/class-honors-dialog.test.tsx`

---

### Task 7: App parseo + UI + i18n

**Files:**
- Modify: `sacdia-app/lib/features/classes/domain/entities/class_honor.dart` (`moduleId`, `moduleName`, `materialUrl`, `hasMaterial`)
- Modify: `sacdia-app/lib/features/classes/data/models/class_honor_model.dart`
- Modify: `sacdia-app/lib/features/classes/domain/entities/class_module.dart` (`honors`)
- Modify: `sacdia-app/lib/features/classes/data/models/class_module_model.dart`
- Modify: `sacdia-app/lib/features/classes/presentation/views/class_detail_with_progress_view.dart`
- Modify: `sacdia-app/lib/features/classes/presentation/views/class_modules_view.dart` / `module_expansion_tile.dart` si el catálogo lista módulos
- Modify: `sacdia-app/assets/translations/{es,en,pt-BR,fr}.json`
- Create: `sacdia-app/test/features/classes/data/models/class_honor_model_test.dart`

Carrusel `_RecommendedHonorsSection`: `honors.where((h) => h.moduleId == null)`.

En `_RequirementTrackSections` / módulos BASIC: para cada `ClassModuleDetail`, honors con `moduleId == module.id` (mismo `classHonorsProvider`).

Tarjeta: `SacPdfViewer.show` + `context.push(RouteNames.honorDetailPath(...))`.

Keys sugeridas bajo `classes.honors`: `open_pdf`, `enroll`, `continue_honor`, `no_pdf`.

Run: `cd sacdia-app && flutter test test/features/classes/data/models/class_honor_model_test.dart`

---

### Task 8: Verificación

- Jest admin + classes.
- Vitest diálogo.
- Flutter parse test + `dart analyze` de archivos tocados.
- Browser: detalle de clase admin → asignar especialidad a un módulo (si el panel corre).
- No aplicar Neon hasta pedido explícito.

---

### Fuera de este plan

Gate de módulo/investidura. Unique nuevo. Backfill de `module_id`. Importador Aventureros.
