# Design: Honor Requirements Per-Requirement Tracking

**Date**: 2026-03-27
**Status**: Draft
**Scope**: sacdia-backend (Prisma + NestJS), sacdia-app (Flutter), seed script

## Technical Approach

Add per-requirement progress tracking to honors following the `class_sections` / `class_section_progress` pattern. Two new DB tables (catalog + user progress), 4 new backend endpoints, seed script parsing 605 markdown files, and a new Flutter `HonorRequirementsView` with checkbox + notes per requirement. Existing honor enrollment, evidence upload, and validation flows remain unchanged.

## Architecture Decisions

### Decision: Extend HonorsService vs New Service

| Option | Tradeoff | Decision |
|--------|----------|----------|
| Extend `HonorsService` | Simpler DI, but file already 1029 lines | **No** |
| New `HonorRequirementsService` | Clean separation, follows SRP | **Yes** |

**Rationale**: `HonorsService` is already large (file upload, stats, CRUD). A separate service keeps each file focused. Registered in same `HonorsModule`, shares `PrismaService`.

### Decision: Seed Script Technology

| Option | Tradeoff | Decision |
|--------|----------|----------|
| Prisma seed (TypeScript) | Runs via `prisma db seed`, consistent with Prisma workflow | **Yes** |
| Standalone SQL file | Simpler but no markdown parsing | No |
| Node.js standalone script | Works but outside Prisma lifecycle | No |

**Rationale**: TypeScript seed script at `prisma/seeds/honor-requirements.seed.ts` can parse markdown, query DB for honor_id matching, and use Prisma client for inserts. Executable via `npx ts-node prisma/seeds/honor-requirements.seed.ts`.

### Decision: Honor Name Matching Strategy

| Option | Tradeoff | Decision |
|--------|----------|----------|
| Exact match on slug → `honors.name` | Fast, but may miss due to accents/casing | No |
| Normalized match (lowercase, strip accents, trim) | Handles 90%+ of cases | **Yes, primary** |
| Fuzzy match fallback (Levenshtein) | Catches edge cases | **Yes, fallback** |

**Rationale**: CSV `title` column (e.g., "anfibios") maps to DB `honors.name`. Normalize both sides: lowercase, strip accents (`á→a`), trim whitespace. For unmatched, log to `unmatched.json` for manual review. No fuzzy lib needed — simple normalization covers the majority.

### Decision: Bulk Progress Update Strategy

| Option | Tradeoff | Decision |
|--------|----------|----------|
| Individual PATCH per requirement | Simple, many round trips | No |
| Batch PATCH with array body | Single request, matches `BulkCreateUserHonorsDto` pattern | **Yes** |
| WebSocket real-time sync | Over-engineered for this use case | No |

**Rationale**: User checks multiple boxes then navigates away. A single PATCH with `[{requirementId, completed, notes?}]` array mirrors the existing `BulkCreateUserHonorsDto` pattern in the honors module.

## Data Flow

```
[Catalog — read-only]
honors ──1:N──→ honor_requirements (seeded from markdown)

[User progress — read/write]
users_honors ──1:N──→ user_honor_requirement_progress ──N:1──→ honor_requirements

[API flow]
Flutter ──GET /honors/:id/requirements──→ Backend ──→ Prisma ──→ honor_requirements
Flutter ──GET /users/:uid/honors/:hid/requirements──→ Backend ──→ join requirements + progress
Flutter ──PATCH /users/:uid/honors/:hid/requirements/bulk──→ Backend ──→ upsert progress rows
```

## Interfaces / Contracts

### Prisma Models (2 new)

```prisma
model honor_requirements {
  requirement_id     Int       @id @default(autoincrement())
  honor_id           Int
  requirement_number Int
  text               String
  has_sub_items      Boolean   @default(false)
  needs_review       Boolean   @default(true)
  active             Boolean   @default(true)
  created_at         DateTime  @default(now()) @db.Timestamptz(6)
  modified_at        DateTime  @default(now()) @db.Timestamptz(6)

  honors                          honors                            @relation(fields: [honor_id], references: [honor_id], onDelete: NoAction, onUpdate: NoAction)
  user_honor_requirement_progress user_honor_requirement_progress[]

  @@unique([honor_id, requirement_number])
  @@index([honor_id])
}

model user_honor_requirement_progress {
  progress_id    Int       @id @default(autoincrement())
  user_honor_id  Int
  requirement_id Int
  completed      Boolean   @default(false)
  notes          String?
  completed_at   DateTime? @db.Timestamptz(6)
  active         Boolean   @default(true)
  created_at     DateTime  @default(now()) @db.Timestamptz(6)
  modified_at    DateTime  @default(now()) @db.Timestamptz(6)

  users_honors       users_honors       @relation(fields: [user_honor_id], references: [user_honor_id], onDelete: Cascade, onUpdate: NoAction)
  honor_requirements honor_requirements @relation(fields: [requirement_id], references: [requirement_id], onDelete: NoAction, onUpdate: NoAction)

  @@unique([user_honor_id, requirement_id])
  @@index([user_honor_id])
}
```

Relation additions to existing models:
- `honors`: add `honor_requirements honor_requirements[]`
- `users_honors`: add `user_honor_requirement_progress user_honor_requirement_progress[]`

### Backend DTOs

```typescript
// honor-requirements.dto.ts

export class UpdateRequirementProgressDto {
  @IsInt()
  requirementId: number;

  @IsBoolean()
  completed: boolean;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  notes?: string | null;
}

export class BulkUpdateRequirementProgressDto {
  @IsArray()
  @ArrayNotEmpty()
  @ValidateNested({ each: true })
  @Type(() => UpdateRequirementProgressDto)
  requirements: UpdateRequirementProgressDto[];
}
```

### Backend Endpoints (4 new)

| Method | Path | Guard | Permission | Description |
|--------|------|-------|------------|-------------|
| `GET` | `/honors/:honorId/requirements` | `OptionalJwtAuthGuard` | Public | List honor requirements (catalog) |
| `GET` | `/users/:userId/honors/:honorId/requirements` | `JwtAuth + OwnerOrAdmin + Permissions` | `user_honors:read` | Get user progress per requirement |
| `PATCH` | `/users/:userId/honors/:honorId/requirements/:requirementId` | `JwtAuth + OwnerOrAdmin + Permissions` | `user_honors:update` | Toggle single requirement |
| `PATCH` | `/users/:userId/honors/:honorId/requirements/bulk` | `JwtAuth + OwnerOrAdmin + Permissions` | `user_honors:update` | Bulk update requirements |

### Backend Service Methods

```typescript
// honor-requirements.service.ts — key methods

class HonorRequirementsService {
  // Catalog
  getRequirements(honorId: number): Promise<honor_requirements[]>

  // User progress — joins requirements with progress rows, returns all requirements
  // with completed/notes filled where progress exists, defaults for the rest
  getUserProgress(userId: string, honorId: number): Promise<RequirementWithProgress[]>

  // Single toggle — upserts one progress row
  updateProgress(userId: string, honorId: number, dto: UpdateRequirementProgressDto): Promise<void>

  // Bulk toggle — upserts N progress rows inside $transaction
  bulkUpdateProgress(userId: string, honorId: number, dto: BulkUpdateRequirementProgressDto): Promise<void>
}
```

The `getUserProgress` method loads all `honor_requirements` for the honor, LEFT JOINs with `user_honor_requirement_progress` for the user's `user_honor_id`, and returns a merged array with `completed` defaulting to `false` and `notes` to `null` where no progress row exists.

### Flutter Entities

```dart
// honor_requirement.dart
class HonorRequirement extends Equatable {
  final int id;
  final int honorId;
  final int requirementNumber;
  final String text;
  final bool hasSubItems;
  final bool needsReview;
}

// user_honor_requirement_progress.dart
class UserHonorRequirementProgress extends Equatable {
  final int requirementId;
  final int requirementNumber;
  final String text;
  final bool completed;
  final String? notes;
  final DateTime? completedAt;
}
```

### Flutter Providers

```dart
// New providers in honors_providers.dart or new file

// Catalog requirements for a honor
final honorRequirementsProvider = FutureProvider.autoDispose
    .family<List<HonorRequirement>, int>((ref, honorId) async { ... });

// User progress for a specific honor enrollment
final userHonorProgressProvider = FutureProvider.autoDispose
    .family<List<UserHonorRequirementProgress>, ({String userId, int honorId})>(
        (ref, params) async { ... });

// Mutation notifier for toggling requirements
class RequirementProgressNotifier extends AutoDisposeAsyncNotifier<void> {
  Future<void> toggle(String userId, int honorId, int requirementId, bool completed, String? notes);
  Future<void> bulkUpdate(String userId, int honorId, List<UpdateRequirementProgressDto> items);
}
```

### Flutter View: `HonorRequirementsView`

Accessible from `HonorDetailView` ("Ver requisitos" button) and `HonorEvidenceView` (progress summary card).

```
Route: /honor/:honorId/requirements/:userHonorId
```

Layout:
```
┌────────────────────────────────┐
│  Dark Header (honor name/icon) │
├────────────────────────────────┤
│  Progress Bar  [7/11 - 63%]   │
├────────────────────────────────┤
│  ☑ 1. Requirement text...      │
│  ☑ 2. Requirement text...      │
│  ☐ 3. Long requirement text    │
│     that wraps multiple lines  │
│     [expandable] + notes field │
│  ☑ 4. Requirement text...      │
│  ...                           │
├────────────────────────────────┤
│  [Guardar cambios]             │
└────────────────────────────────┘
```

UX behavior:
- Checkboxes toggle locally, debounced bulk PATCH on save or navigate-away
- Long requirement text truncated to 3 lines with "Ver más" expand
- Optional notes field appears below each requirement on tap
- Progress bar updates in real-time as checkboxes change
- No gating: user can navigate to evidence/submit regardless of progress

## Seed Script Design

**Location**: `sacdia-backend/prisma/seeds/honor-requirements.seed.ts`

**Algorithm**:
1. Read `index.csv` → build `Map<slug, {title, requirementsDetected}>`
2. Query `honors` table → build `Map<normalizedName, honor_id>`
3. For each CSV entry:
   a. Normalize `title` → lookup `honor_id`
   b. Read corresponding `.md` file
   c. Extract requirements with regex: `/^(\d+)\.\s+(.+)$/gm` (multiline, captures number + text)
   d. Detect `has_sub_items`: `/[a-z]\.\s|[ivx]+\.\s/i` in text
   e. Validate extracted count against CSV `requirements_detected`
4. Batch insert via `prisma.honor_requirements.createMany({ skipDuplicates: true })`
5. Log: matched count, unmatched honors (to `unmatched.json`), count mismatches

**Normalization function**:
```typescript
function normalize(s: string): string {
  return s.toLowerCase()
    .normalize('NFD').replace(/[\u0300-\u036f]/g, '') // strip accents
    .replace(/[^a-z0-9\s]/g, '')  // remove special chars
    .trim();
}
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `sacdia-backend/prisma/schema.prisma` | Modify | Add 2 new models + relations on `honors` and `users_honors` |
| `sacdia-backend/prisma/migrations/YYYYMMDD_honor_requirements/` | Create | Migration for 2 new tables with indexes |
| `sacdia-backend/prisma/seeds/honor-requirements.seed.ts` | Create | Seed script: parse markdown → insert requirements |
| `sacdia-backend/src/honors/honors.module.ts` | Modify | Register `HonorRequirementsService` + new controllers |
| `sacdia-backend/src/honors/honor-requirements.service.ts` | Create | Service with 4 methods: getRequirements, getUserProgress, updateProgress, bulkUpdateProgress |
| `sacdia-backend/src/honors/honor-requirements.controller.ts` | Create | 2 controllers: `HonorRequirementsController` (public catalog) + `UserHonorRequirementsController` (auth'd progress) |
| `sacdia-backend/src/honors/dto/honor-requirements.dto.ts` | Create | DTOs: UpdateRequirementProgressDto, BulkUpdateRequirementProgressDto |
| `sacdia-backend/src/honors/dto/index.ts` | Modify | Re-export new DTOs |
| `sacdia-app/lib/features/honors/domain/entities/honor_requirement.dart` | Create | `HonorRequirement` entity |
| `sacdia-app/lib/features/honors/domain/entities/user_honor_requirement_progress.dart` | Create | `UserHonorRequirementProgress` entity |
| `sacdia-app/lib/features/honors/data/models/honor_requirement_model.dart` | Create | Model with `fromJson` |
| `sacdia-app/lib/features/honors/data/models/user_honor_requirement_progress_model.dart` | Create | Model with `fromJson` |
| `sacdia-app/lib/features/honors/data/datasources/honors_remote_data_source.dart` | Modify | Add 3 methods: getHonorRequirements, getUserHonorProgress, updateHonorRequirementProgress |
| `sacdia-app/lib/features/honors/domain/repositories/honors_repository.dart` | Modify | Add 3 method signatures |
| `sacdia-app/lib/features/honors/data/repositories/honors_repository_impl.dart` | Modify | Implement 3 new methods |
| `sacdia-app/lib/features/honors/domain/usecases/get_honor_requirements.dart` | Create | UseCase for fetching catalog requirements |
| `sacdia-app/lib/features/honors/domain/usecases/get_user_honor_progress.dart` | Create | UseCase for fetching user progress |
| `sacdia-app/lib/features/honors/domain/usecases/update_requirement_progress.dart` | Create | UseCase for bulk update |
| `sacdia-app/lib/features/honors/presentation/providers/honors_providers.dart` | Modify | Add requirement + progress providers |
| `sacdia-app/lib/features/honors/presentation/views/honor_requirements_view.dart` | Create | Checklist UI with checkboxes, notes, progress bar |
| `sacdia-app/lib/features/honors/presentation/views/honor_detail_view.dart` | Modify | Add "Ver requisitos" CTA for enrolled users |
| `sacdia-app/lib/features/honors/presentation/views/honor_evidence_view.dart` | Modify | Add progress summary card |
| `sacdia-app/lib/core/config/route_names.dart` | Modify | Add `honorRequirements` route + path helper |

## Testing Strategy

| Layer | What to Test | Approach |
|-------|-------------|----------|
| Unit | Seed script markdown parser + normalizer | Jest: parse sample .md files, validate extracted requirements count and text |
| Unit | `HonorRequirementsService` methods | Jest: mock PrismaService, test getRequirements, getUserProgress, updateProgress, bulkUpdateProgress |
| Unit | DTOs validation | Jest: test class-validator decorators on UpdateRequirementProgressDto |
| Integration | Endpoint auth + response shapes | Supertest: test all 4 endpoints with valid/invalid tokens |
| Widget | `HonorRequirementsView` checkbox behavior | Flutter widget test: verify toggle state, progress bar update |

## Migration / Rollout

No migration of existing data needed. Changes are purely additive:
1. Run Prisma migration to create 2 new tables
2. Run seed script to populate `honor_requirements` (~5680 rows)
3. Deploy backend with new endpoints
4. Deploy app update with requirements UI

Rollback: Drop 2 new tables. Remove new endpoints/views. No existing data affected.

## Open Questions

- [ ] How many of the 605 CSV titles will match DB `honors.name` after normalization? Need to run a dry-run match report before committing the seed.
- [ ] Should the progress bar be visible on the honor card in the catalog list, or only on detail/evidence views? (UX decision — does not block implementation)
