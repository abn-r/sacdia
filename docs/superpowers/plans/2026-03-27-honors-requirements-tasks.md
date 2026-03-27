# Honor Requirements Per-Requirement Tracking — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add per-requirement progress tracking to honors. Members view individual requirements, check them off, optionally add notes, and see progress bars on honor cards and detail views. Progress is informational only — it does NOT gate validation submission.

**Architecture:** Two new DB tables (`honor_requirements` catalog + `user_honor_requirement_progress` per-user). New `HonorRequirementsService` in the existing `HonorsModule`. Seed script parses 605 markdown files via `index.csv` to populate requirements. Flutter follows Clean Architecture with new entities, models, repository methods, use cases, providers, and a `HonorRequirementsView` checklist screen. Progress bar visible on both honor cards (catalog) and honor detail view.

**Tech Stack:** NestJS 11, Prisma 7, PostgreSQL (Neon), Flutter 3.x, Riverpod, Dio

**Spec:** `docs/superpowers/specs/2026-03-27-honors-requirements-spec.md`
**Design:** `docs/superpowers/specs/2026-03-27-honors-requirements-design.md`

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Modify | `sacdia-backend/prisma/schema.prisma` | Add `honor_requirements` + `user_honor_requirement_progress` models, relations on `honors` and `users_honors` |
| Create | `sacdia-backend/prisma/migrations/YYYYMMDD_honor_requirements/migration.sql` | Migration for 2 new tables with indexes + unique constraints |
| Create | `sacdia-backend/prisma/seeds/honor-requirements.seed.ts` | Seed script: parse markdown, match honors, insert requirements |
| Create | `sacdia-backend/src/honors/dto/honor-requirements.dto.ts` | `UpdateRequirementProgressDto`, `BulkUpdateRequirementProgressDto` |
| Modify | `sacdia-backend/src/honors/dto/index.ts` | Re-export new DTOs |
| Create | `sacdia-backend/src/honors/honor-requirements.service.ts` | Service: getRequirements, getUserProgress, updateProgress, bulkUpdateProgress |
| Create | `sacdia-backend/src/honors/honor-requirements.controller.ts` | `HonorRequirementsController` (public) + `UserHonorRequirementsController` (auth'd) |
| Modify | `sacdia-backend/src/honors/honors.module.ts` | Register new service + controllers |
| Create | `sacdia-app/lib/features/honors/domain/entities/honor_requirement.dart` | `HonorRequirement` entity (Equatable) |
| Create | `sacdia-app/lib/features/honors/domain/entities/user_honor_requirement_progress.dart` | `UserHonorRequirementProgress` entity (Equatable) |
| Create | `sacdia-app/lib/features/honors/data/models/honor_requirement_model.dart` | Model with `fromJson` factory |
| Create | `sacdia-app/lib/features/honors/data/models/user_honor_requirement_progress_model.dart` | Model with `fromJson` factory |
| Modify | `sacdia-app/lib/features/honors/data/datasources/honors_remote_data_source.dart` | Add 3 methods: getHonorRequirements, getUserHonorProgress, bulkUpdateRequirementProgress |
| Modify | `sacdia-app/lib/features/honors/domain/repositories/honors_repository.dart` | Add 3 abstract method signatures |
| Modify | `sacdia-app/lib/features/honors/data/repositories/honors_repository_impl.dart` | Implement 3 new methods |
| Create | `sacdia-app/lib/features/honors/domain/usecases/get_honor_requirements.dart` | UseCase: fetch catalog requirements for a honor |
| Create | `sacdia-app/lib/features/honors/domain/usecases/get_user_honor_progress.dart` | UseCase: fetch user progress per requirement |
| Create | `sacdia-app/lib/features/honors/domain/usecases/update_requirement_progress.dart` | UseCase: bulk update requirement completion |
| Modify | `sacdia-app/lib/features/honors/presentation/providers/honors_providers.dart` | Add `honorRequirementsProvider`, `userHonorProgressProvider`, `RequirementProgressNotifier` |
| Create | `sacdia-app/lib/features/honors/presentation/views/honor_requirements_view.dart` | Checklist UI: header, progress bar, checkboxes, notes, save button |
| Modify | `sacdia-app/lib/features/honors/presentation/views/honor_detail_view.dart` | Add "Requisitos" CTA with X/Y count for enrolled users |
| Modify | `sacdia-app/lib/features/honors/presentation/widgets/honor_card.dart` | Add progress bar for enrolled honors |
| Modify | `sacdia-app/lib/core/config/route_names.dart` | Add `honorRequirements` route name + path helper |

---

## Phase A: Data Model + Seed (Backend)

> Sequential. Must complete before Phase B.

### Task A1: Prisma Schema — New Models + Migration

**Files:**
- Modify: `sacdia-backend/prisma/schema.prisma`
- Create: `sacdia-backend/prisma/migrations/YYYYMMDD_honor_requirements/migration.sql`

**Steps:**
- [ ] Add `honor_requirements` model to schema.prisma with fields: `requirement_id` (PK autoincrement), `honor_id` (FK), `requirement_number` (INT), `text` (String), `has_sub_items` (Boolean default false), `needs_review` (Boolean default true), `active` (Boolean default true), `created_at`, `modified_at`. Add `@@unique([honor_id, requirement_number])` and `@@index([honor_id])`
- [ ] Add `user_honor_requirement_progress` model with fields: `progress_id` (PK autoincrement), `user_honor_id` (FK → users_honors, onDelete: Cascade), `requirement_id` (FK → honor_requirements), `completed` (Boolean default false), `notes` (String?), `completed_at` (DateTime?), `active` (Boolean default true), `created_at`, `modified_at`. Add `@@unique([user_honor_id, requirement_id])` and `@@index([user_honor_id])`
- [ ] Add `honor_requirements honor_requirements[]` relation to the `honors` model
- [ ] Add `user_honor_requirement_progress user_honor_requirement_progress[]` relation to the `users_honors` model
- [ ] Run `npx prisma migrate dev --name honor_requirements` to generate migration
- [ ] Verify migration SQL creates both tables with correct indexes and constraints

**Commit:** `feat(backend): add honor_requirements and user_honor_requirement_progress tables`

---

### Task A2: Seed Script — Parse Markdown + Insert Requirements

**Files:**
- Create: `sacdia-backend/prisma/seeds/honor-requirements.seed.ts`

**Steps:**
- [ ] Create seed script at `prisma/seeds/honor-requirements.seed.ts` with PrismaClient import
- [ ] Implement `normalize(s: string): string` — lowercase, `NFD` + strip accents, remove non-alphanumeric except spaces, trim
- [ ] Parse `docs/working/honors-especialidades/index.csv` into `Map<slug, {title, requirementsDetected, mdPath}>`
- [ ] Query `honors` table, build `Map<normalizedName, honor_id>`
- [ ] For each CSV entry: normalize title, lookup honor_id, read `.md` file, extract requirements via regex `/^(\d+)\.\s+(.+)$/gm`
- [ ] Detect `has_sub_items` when text matches `/[a-z]\.\s|[ivx]+\.\s/i`
- [ ] Set `needs_review = true` for ALL rows
- [ ] Cross-validate parsed count vs CSV `requirements_detected`, log mismatches
- [ ] **Dry-run mode:** First run with `--dry-run` flag that only reports: total honors matched, unmatched list (saved to `unmatched.json`), count mismatches — no DB inserts
- [ ] Batch insert via `prisma.honor_requirements.createMany({ skipDuplicates: true })`
- [ ] Log summary: total honors processed, total requirements inserted, mismatches, unmatched

**Commit:** `feat(backend): add honor requirements seed script with markdown parsing`

---

## Phase B: Backend API

> Sequential after Phase A. Tasks B1-B3 are sequential (DTOs → Service → Controller → Module).

### Task B1: DTOs for Honor Requirements

**Files:**
- Create: `sacdia-backend/src/honors/dto/honor-requirements.dto.ts`
- Modify: `sacdia-backend/src/honors/dto/index.ts`

**Steps:**
- [ ] Create `UpdateRequirementProgressDto` with `@IsInt() requirementId`, `@IsBoolean() completed`, `@IsOptional() @IsString() @MaxLength(2000) notes?: string | null`
- [ ] Create `BulkUpdateRequirementProgressDto` with `@IsArray() @ArrayNotEmpty() @ValidateNested({ each: true }) @Type(() => UpdateRequirementProgressDto) requirements: UpdateRequirementProgressDto[]`
- [ ] Re-export both DTOs from `dto/index.ts`

**Commit:** `feat(backend): add honor requirements DTOs`

---

### Task B2: HonorRequirementsService

**Files:**
- Create: `sacdia-backend/src/honors/honor-requirements.service.ts`

**Steps:**
- [ ] Create `HonorRequirementsService` injectable with `PrismaService` dependency
- [ ] `getRequirements(honorId: number)` — query `honor_requirements` where `honor_id` and `active: true`, order by `requirement_number` ASC. Throw `NotFoundException` if honor does not exist
- [ ] `getUserProgress(userId: string, honorId: number)` — find `users_honors` for user+honor, LEFT JOIN requirements with progress. Return merged array with `completed` defaulting to `false`, `notes` to `null`. Include `total_requirements`, `completed_count`, `progress_percentage` (rounded 2 decimals, 0 if total is 0). Throw `NotFoundException` if enrollment not found
- [ ] `updateProgress(userId: string, honorId: number, dto: UpdateRequirementProgressDto)` — validate requirement belongs to the honor, upsert progress row. Set `completed_at = now()` when `completed: true`, `null` when `false`
- [ ] `bulkUpdateProgress(userId: string, honorId: number, dto: BulkUpdateRequirementProgressDto)` — validate ALL requirement IDs belong to the honor BEFORE any writes. Use `$transaction` for atomicity. Return updated progress summary

**Commit:** `feat(backend): add HonorRequirementsService with CRUD methods`

---

### Task B3: Controllers + Module Registration

**Files:**
- Create: `sacdia-backend/src/honors/honor-requirements.controller.ts`
- Modify: `sacdia-backend/src/honors/honors.module.ts`

**Steps:**
- [ ] Create `HonorRequirementsController` at `@Controller('api/v1/honors')` with `GET /:honorId/requirements` — public, uses `OptionalJwtAuthGuard`. Returns `{ status: 'success', data: { honor_id, total_requirements, requirements } }`
- [ ] Create `UserHonorRequirementsController` at `@Controller('api/v1/users')` with 3 endpoints:
  - `GET /:userId/honors/:userHonorId/requirements/progress` — `JwtAuth + OwnerOrAdmin + Permissions('user_honors:read')`
  - `PATCH /:userId/honors/:userHonorId/requirements/:requirementId/progress` — `Permissions('user_honors:update')`
  - `PATCH /:userId/honors/:userHonorId/requirements/progress/batch` — `Permissions('user_honors:update')`
- [ ] Register `HonorRequirementsService`, `HonorRequirementsController`, `UserHonorRequirementsController` in `HonorsModule`

**Commit:** `feat(backend): add honor requirements controllers and wire module`

---

## Phase C: Flutter Data + Domain Layers

> Sequential after Phase B endpoints are defined. Tasks C1-C4 are sequential. Can start C1-C2 in parallel with Phase B if endpoint contracts are agreed.

### Task C1: Entities

**Files:**
- Create: `sacdia-app/lib/features/honors/domain/entities/honor_requirement.dart`
- Create: `sacdia-app/lib/features/honors/domain/entities/user_honor_requirement_progress.dart`

**Steps:**
- [ ] Create `HonorRequirement` extending `Equatable` with fields: `int id`, `int honorId`, `int requirementNumber`, `String text`, `bool hasSubItems`, `bool needsReview`. Props: all fields
- [ ] Create `UserHonorRequirementProgress` extending `Equatable` with fields: `int requirementId`, `int requirementNumber`, `String text`, `bool completed`, `String? notes`, `DateTime? completedAt`. Props: all fields

**Commit:** `feat(app): add honor requirement entities`

---

### Task C2: Models (JSON Parsing)

**Files:**
- Create: `sacdia-app/lib/features/honors/data/models/honor_requirement_model.dart`
- Create: `sacdia-app/lib/features/honors/data/models/user_honor_requirement_progress_model.dart`

**Steps:**
- [ ] Create `HonorRequirementModel` extending `HonorRequirement` with `fromJson(Map<String, dynamic>)` factory. Map: `requirement_id → id`, `honor_id → honorId`, `requirement_number → requirementNumber`, `requirement_text → text`, `has_sub_items → hasSubItems`, `needs_review → needsReview`
- [ ] Create `UserHonorRequirementProgressModel` extending `UserHonorRequirementProgress` with `fromJson` factory. Map: `requirement_id → requirementId`, `requirement_number → requirementNumber`, `requirement_text → text`, `completed → completed`, `notes → notes`, `completed_at → completedAt` (parse ISO string)

**Commit:** `feat(app): add honor requirement JSON models`

---

### Task C3: DataSource + Repository

**Files:**
- Modify: `sacdia-app/lib/features/honors/data/datasources/honors_remote_data_source.dart`
- Modify: `sacdia-app/lib/features/honors/domain/repositories/honors_repository.dart`
- Modify: `sacdia-app/lib/features/honors/data/repositories/honors_repository_impl.dart`

**Steps:**
- [ ] Add to `HonorsRemoteDataSource`: `getHonorRequirements(int honorId)` — GET `/honors/$honorId/requirements`, parse `data.requirements` list
- [ ] Add to `HonorsRemoteDataSource`: `getUserHonorProgress(String userId, int userHonorId)` — GET `/users/$userId/honors/$userHonorId/requirements/progress`, return full response data
- [ ] Add to `HonorsRemoteDataSource`: `bulkUpdateRequirementProgress(String userId, int userHonorId, List<Map<String, dynamic>> updates)` — PATCH `/users/$userId/honors/$userHonorId/requirements/progress/batch`
- [ ] Add 3 abstract method signatures to `HonorsRepository`
- [ ] Implement 3 methods in `HonorsRepositoryImpl` with error handling (try/catch → Left/Right pattern matching existing code)

**Commit:** `feat(app): add honor requirements datasource and repository methods`

---

### Task C4: Use Cases + Providers

**Files:**
- Create: `sacdia-app/lib/features/honors/domain/usecases/get_honor_requirements.dart`
- Create: `sacdia-app/lib/features/honors/domain/usecases/get_user_honor_progress.dart`
- Create: `sacdia-app/lib/features/honors/domain/usecases/update_requirement_progress.dart`
- Modify: `sacdia-app/lib/features/honors/presentation/providers/honors_providers.dart`

**Steps:**
- [ ] Create `GetHonorRequirements` use case — takes `int honorId`, returns `List<HonorRequirement>`
- [ ] Create `GetUserHonorProgress` use case — takes `({String userId, int userHonorId})`, returns progress response with `totalRequirements`, `completedCount`, `progressPercentage`, `requirements` list
- [ ] Create `UpdateRequirementProgress` use case — takes `({String userId, int userHonorId, List<UpdateItem> updates})`, returns updated progress
- [ ] Add `honorRequirementsProvider` — `FutureProvider.autoDispose.family<List<HonorRequirement>, int>`
- [ ] Add `userHonorProgressProvider` — `FutureProvider.autoDispose.family` keyed by `({String userId, int userHonorId})`
- [ ] Add `RequirementProgressNotifier` — `AutoDisposeAsyncNotifier` with `toggle()` and `bulkUpdate()` methods that invalidate progress provider on success

**Commit:** `feat(app): add honor requirements use cases and providers`

---

## Phase D: Flutter Presentation

> Sequential after Phase C. Tasks D1-D4 are sequential except D3 and D4 which can run in parallel.

### Task D1: Route Registration

**Files:**
- Modify: `sacdia-app/lib/core/config/route_names.dart`

**Steps:**
- [ ] Add `static const honorRequirements = 'honor-requirements'` to `RouteNames`
- [ ] Add path helper: `/honor/:honorId/requirements/:userHonorId`
- [ ] Register route in the app router pointing to `HonorRequirementsView`

**Commit:** `feat(app): add honor requirements route`

---

### Task D2: HonorRequirementsView (Checklist UI)

**Files:**
- Create: `sacdia-app/lib/features/honors/presentation/views/honor_requirements_view.dart`

**Steps:**
- [ ] Create `HonorRequirementsView` as `ConsumerStatefulWidget` receiving `honorId` and `userHonorId` from route params
- [ ] Dark header section with honor name and icon (match `HonorDetailView` style)
- [ ] Progress bar showing `completedCount/totalRequirements` with percentage — updates in real-time as checkboxes change
- [ ] Scrollable list of requirements: each row has a `Checkbox` + requirement number + text
- [ ] Long text truncated to 3 lines with "Ver mas" expand toggle
- [ ] Optional notes `TextField` appears below each requirement on tap
- [ ] Local state tracks checkbox changes; "Guardar cambios" button triggers `bulkUpdate` via `RequirementProgressNotifier`
- [ ] Handle loading/error states with existing app patterns (shimmer, error widget)

**Commit:** `feat(app): add HonorRequirementsView checklist UI`

---

### Task D3: Integration into HonorDetailView

> Can run in parallel with Task D4.

**Files:**
- Modify: `sacdia-app/lib/features/honors/presentation/views/honor_detail_view.dart`

**Steps:**
- [ ] For enrolled users: add a "Requisitos" card/button showing "X/Y completados" using `userHonorProgressProvider`
- [ ] On tap, navigate to `HonorRequirementsView` with `honorId` and `userHonorId`
- [ ] Add progress bar below the "Requisitos" CTA matching the detail view style
- [ ] For non-enrolled users: hide the requisitos section entirely

**Commit:** `feat(app): add requirements CTA and progress bar to honor detail view`

---

### Task D4: Progress Bar on HonorCard (Catalog List)

> Can run in parallel with Task D3.

**Files:**
- Modify: `sacdia-app/lib/features/honors/presentation/widgets/honor_card.dart`

**Steps:**
- [ ] Accept optional `progressPercentage` and `completedCount`/`totalRequirements` props
- [ ] When user is enrolled and progress data is available, render a thin `LinearProgressIndicator` at the bottom of the card
- [ ] Show "X/Y" text label next to or below the progress bar
- [ ] For non-enrolled honors or when no progress data exists, hide the progress indicator entirely
- [ ] Ensure progress data is fetched efficiently (batch or cached, NOT per-card API call)

**Commit:** `feat(app): add progress bar to honor cards for enrolled honors`

---

## Parallelism Summary

```
Phase A: A1 → A2                           (sequential)
Phase B: B1 → B2 → B3                      (sequential, after A)
Phase C: C1 → C2 → C3 → C4                 (sequential, after B contracts defined)
Phase D: D1 → D2 → D3 ┐                    (D3 and D4 parallel, after C)
                       D4 ┘

Total: 13 tasks
Estimated sessions: 4-6 (one per phase, D may take 2)
```
