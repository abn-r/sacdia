# Honors Sub-proyecto A: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add hierarchical sub-items, per-requirement evidence, choice groups, and data quality cleanup to the honors/specialties feature across backend, mobile app, and admin panel.

**Architecture:** Extend the flat `honor_requirements` table with self-referential `parent_id` for sub-item hierarchy, add `requirement_evidence` table for per-requirement uploads (images, files, links — 3 per type max), and add `text_response` field to progress tracking. Re-scan 605 PDFs with improved parser to fix data quality issues. Use `mobile-design` skill for Flutter UI and `frontend-design`/`ui-designer` skills for admin panel.

**Tech Stack:** NestJS 11 + Prisma 7 + PostgreSQL (Neon), Flutter + Riverpod, Next.js 16 + shadcn/ui, Cloudflare R2

**Spec:** `docs/superpowers/specs/2026-04-06-honors-data-quality-subitems-design.md`

---

## File Structure

### Backend (sacdia-backend)

| Action | Path | Responsibility |
|--------|------|---------------|
| Modify | `prisma/schema.prisma:707-741` | Add new fields to `honor_requirements`, `user_honor_requirement_progress`, new `requirement_evidence` model + enum |
| Create | `prisma/migrations/YYYYMMDD_honor_requirements_hierarchy/migration.sql` | Schema migration with partial unique indexes |
| Modify | `src/honors/dto/honor-requirements.dto.ts` | Add `textResponse` to progress DTOs, new evidence DTOs, new admin DTOs |
| Modify | `src/honors/honor-requirements.service.ts` | Hierarchical queries, evidence validation, completion logic |
| Modify | `src/honors/honor-requirements.controller.ts` | Evidence endpoints on authenticated controller |
| Create | `src/admin/admin-honors.controller.ts` | Admin CRUD for requirements + review workflow |
| Create | `src/admin/admin-honors.service.ts` | Admin business logic |
| Modify | `src/honors/honors.module.ts` | Register new service + controller |
| Create | `prisma/seeds/honor-requirements-rescan.seed.ts` | Improved re-scan seed script |

### Flutter (sacdia-app)

| Action | Path | Responsibility |
|--------|------|---------------|
| Modify | `lib/features/honors/domain/entities/honor_requirement.dart` | Add `parentId`, `displayLabel`, `referenceText`, `isChoiceGroup`, `choiceMin`, `requiresEvidence`, `children` |
| Create | `lib/features/honors/domain/entities/requirement_evidence.dart` | New evidence entity |
| Modify | `lib/features/honors/domain/entities/user_honor_requirement_progress.dart` | Add `textResponse`, `evidences` |
| Modify | `lib/features/honors/data/models/honor_requirement_model.dart` | Update `fromJson`/`toJson` for new fields + children |
| Create | `lib/features/honors/data/models/requirement_evidence_model.dart` | New evidence model |
| Modify | `lib/features/honors/data/models/user_honor_requirement_progress_model.dart` | Add `textResponse`, `evidences` |
| Modify | `lib/features/honors/data/datasources/honors_remote_data_source.dart` | Evidence upload/delete endpoints |
| Modify | `lib/features/honors/data/repositories/honors_repository_impl.dart` | Evidence repository methods |
| Modify | `lib/features/honors/domain/repositories/honors_repository.dart` | Evidence interface methods |
| Create | `lib/features/honors/domain/usecases/upload_requirement_evidence.dart` | Upload evidence use case |
| Create | `lib/features/honors/domain/usecases/delete_requirement_evidence.dart` | Delete evidence use case |
| Modify | `lib/features/honors/presentation/providers/honors_providers.dart` | Evidence providers + notifiers |
| Modify | `lib/features/honors/presentation/views/honor_requirements_view.dart` | Hierarchical view + evidence UI |
| Create | `lib/features/honors/presentation/widgets/requirement_tree_item.dart` | Single requirement row with expand/collapse |
| Create | `lib/features/honors/presentation/widgets/evidence_upload_sheet.dart` | Bottom sheet for evidence upload |
| Create | `lib/features/honors/presentation/widgets/choice_group_header.dart` | "Completá N de M" badge + progress |

### Admin (sacdia-admin)

| Action | Path | Responsibility |
|--------|------|---------------|
| Modify | `src/lib/api/honors.ts` | Add requirements CRUD + evidence + review API calls |
| Create | `src/app/(dashboard)/dashboard/honors/[honorId]/requirements/page.tsx` | Requirements management page |
| Create | `src/components/honors/requirements-tree.tsx` | Hierarchical requirements tree with drag & drop |
| Create | `src/components/honors/requirement-edit-dialog.tsx` | Edit requirement dialog |
| Create | `src/app/(dashboard)/dashboard/honors/requirements/review/page.tsx` | Review workflow page |
| Create | `src/components/honors/review-split-view.tsx` | Split view: PDF + editable requirement |

---

## Task 1: Prisma Schema Migration

**Files:**
- Modify: `sacdia-backend/prisma/schema.prisma:707-741`
- Create: `sacdia-backend/prisma/migrations/20260406000000_honor_requirements_hierarchy/migration.sql`

- [ ] **Step 1: Add new fields to `honor_requirements` model**

In `sacdia-backend/prisma/schema.prisma`, replace the `honor_requirements` model (lines 707-723) with:

```prisma
model honor_requirements {
  requirement_id                  Int                               @id @default(autoincrement())
  honor_id                        Int
  parent_id                       Int?
  requirement_number              Int
  display_label                   String?                           @db.VarChar(10)
  requirement_text                String
  reference_text                  String?
  has_sub_items                   Boolean                           @default(false)
  is_choice_group                 Boolean                           @default(false)
  choice_min                      Int?
  requires_evidence               Boolean                           @default(false)
  needs_review                    Boolean                           @default(true)
  active                          Boolean                           @default(true)
  created_at                      DateTime                          @default(now()) @db.Timestamptz(6)
  modified_at                     DateTime                          @default(now()) @db.Timestamptz(6)
  honors                          honors                            @relation(fields: [honor_id], references: [honor_id], onDelete: NoAction, onUpdate: NoAction)
  parent                          honor_requirements?               @relation("RequirementSubItems", fields: [parent_id], references: [requirement_id], onDelete: NoAction, onUpdate: NoAction)
  children                        honor_requirements[]              @relation("RequirementSubItems")
  user_honor_requirement_progress user_honor_requirement_progress[]

  @@unique([honor_id, requirement_number], map: "honor_requirements_honor_id_requirement_number_key")
  @@index([honor_id])
  @@index([parent_id])
  @@map("honor_requirements")
}
```

Note: Keep the existing unique constraint for now — the migration SQL will add the partial indexes separately.

- [ ] **Step 2: Add `text_response` and evidence relation to `user_honor_requirement_progress`**

Replace the `user_honor_requirement_progress` model (lines 725-741) with:

```prisma
model user_honor_requirement_progress {
  progress_id          Int                    @id @default(autoincrement())
  user_honor_id        Int
  requirement_id       Int
  completed            Boolean                @default(false)
  text_response        String?                @db.VarChar(800)
  notes                String?
  completed_at         DateTime?              @db.Timestamptz(6)
  active               Boolean                @default(true)
  created_at           DateTime               @default(now()) @db.Timestamptz(6)
  modified_at          DateTime               @default(now()) @db.Timestamptz(6)
  users_honors         users_honors           @relation(fields: [user_honor_id], references: [user_honor_id], onDelete: Cascade, onUpdate: NoAction)
  honor_requirements   honor_requirements     @relation(fields: [requirement_id], references: [requirement_id], onDelete: NoAction, onUpdate: NoAction)
  requirement_evidence requirement_evidence[]

  @@unique([user_honor_id, requirement_id])
  @@index([user_honor_id])
  @@map("user_honor_requirement_progress")
}
```

- [ ] **Step 3: Add `evidence_type_enum` and `requirement_evidence` model**

Add after the `user_honor_requirement_progress` model:

```prisma
enum evidence_type_enum {
  IMAGE
  FILE
  LINK
}

model requirement_evidence {
  evidence_id   Int                             @id @default(autoincrement())
  progress_id   Int
  evidence_type evidence_type_enum
  url           String
  filename      String?                         @db.VarChar(255)
  mime_type     String?                         @db.VarChar(100)
  file_size     Int?
  active        Boolean                         @default(true)
  created_at    DateTime                        @default(now()) @db.Timestamptz(6)
  modified_at   DateTime                        @default(now()) @db.Timestamptz(6)
  progress      user_honor_requirement_progress @relation(fields: [progress_id], references: [progress_id], onDelete: Cascade, onUpdate: NoAction)

  @@index([progress_id])
  @@map("requirement_evidence")
}
```

- [ ] **Step 4: Create the migration SQL**

Run: `cd sacdia-backend && npx prisma migrate dev --name honor_requirements_hierarchy --create-only`

This creates the migration file without applying it. Verify the generated SQL includes:
- `ALTER TABLE honor_requirements ADD COLUMN parent_id INTEGER`
- `ALTER TABLE honor_requirements ADD COLUMN display_label VARCHAR(10)`
- `ALTER TABLE honor_requirements ADD COLUMN reference_text TEXT`
- `ALTER TABLE honor_requirements ADD COLUMN is_choice_group BOOLEAN DEFAULT false`
- `ALTER TABLE honor_requirements ADD COLUMN choice_min INTEGER`
- `ALTER TABLE honor_requirements ADD COLUMN requires_evidence BOOLEAN DEFAULT false`
- `ALTER TABLE user_honor_requirement_progress ADD COLUMN text_response VARCHAR(800)`
- `CREATE TABLE requirement_evidence`
- FK constraint from `honor_requirements.parent_id` to `honor_requirements.requirement_id`

- [ ] **Step 5: Apply migration**

Run: `cd sacdia-backend && npx prisma migrate dev`

Verify: `npx prisma generate` completes without errors.

- [ ] **Step 6: Commit**

```bash
cd sacdia-backend
git add prisma/schema.prisma prisma/migrations/
git commit -m "feat(honors): add hierarchical requirements, evidence table, and text_response field"
```

---

## Task 2: Backend DTOs

**Files:**
- Modify: `sacdia-backend/src/honors/dto/honor-requirements.dto.ts`

- [ ] **Step 1: Add `textResponse` to `UpdateRequirementProgressDto`**

In `sacdia-backend/src/honors/dto/honor-requirements.dto.ts`, add the `textResponse` field to `UpdateRequirementProgressDto`:

```typescript
export class UpdateRequirementProgressDto {
  @ApiProperty({ description: 'ID del requisito del honor' })
  @IsInt()
  requirementId: number;

  @ApiProperty({ description: 'Indica si el requisito fue completado' })
  @IsBoolean()
  completed: boolean;

  @ApiPropertyOptional({
    description: 'Respuesta de texto del usuario al requisito',
    maxLength: 800,
  })
  @IsOptional()
  @IsString()
  @MaxLength(800)
  textResponse?: string | null;

  @ApiPropertyOptional({
    description: 'Notas opcionales del miembro sobre el requisito',
    maxLength: 2000,
  })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  notes?: string | null;
}
```

- [ ] **Step 2: Add evidence DTOs**

Add to the same file:

```typescript
import { IsEnum, IsUrl } from 'class-validator';

export enum EvidenceType {
  IMAGE = 'IMAGE',
  FILE = 'FILE',
  LINK = 'LINK',
}

export class CreateEvidenceLinkDto {
  @ApiProperty({ description: 'URL del enlace externo' })
  @IsUrl()
  url: string;
}

export class DeleteEvidenceDto {
  @ApiProperty({ description: 'ID de la evidencia a eliminar' })
  @IsInt()
  evidenceId: number;
}
```

- [ ] **Step 3: Add admin requirement DTOs**

Add to the same file:

```typescript
export class CreateRequirementDto {
  @ApiProperty({ description: 'ID del honor' })
  @IsInt()
  honorId: number;

  @ApiPropertyOptional({ description: 'ID del requisito padre (null = top-level)' })
  @IsOptional()
  @IsInt()
  parentId?: number | null;

  @ApiProperty({ description: 'Número de orden del requisito' })
  @IsInt()
  requirementNumber: number;

  @ApiPropertyOptional({ description: 'Etiqueta visual (e.g., "1", "a", "ii")' })
  @IsOptional()
  @IsString()
  @MaxLength(10)
  displayLabel?: string | null;

  @ApiProperty({ description: 'Texto del requisito' })
  @IsString()
  requirementText: string;

  @ApiPropertyOptional({ description: 'Texto de referencia (tablas, material adicional)' })
  @IsOptional()
  @IsString()
  referenceText?: string | null;

  @ApiPropertyOptional({ description: 'Es un grupo de selección (elegí N de M)' })
  @IsOptional()
  @IsBoolean()
  isChoiceGroup?: boolean;

  @ApiPropertyOptional({ description: 'Mínimo de opciones a completar' })
  @IsOptional()
  @IsInt()
  choiceMin?: number | null;

  @ApiPropertyOptional({ description: 'Requiere evidencia obligatoria' })
  @IsOptional()
  @IsBoolean()
  requiresEvidence?: boolean;
}

export class UpdateRequirementDto {
  @ApiPropertyOptional({ description: 'Número de orden' })
  @IsOptional()
  @IsInt()
  requirementNumber?: number;

  @ApiPropertyOptional({ description: 'Etiqueta visual' })
  @IsOptional()
  @IsString()
  @MaxLength(10)
  displayLabel?: string | null;

  @ApiPropertyOptional({ description: 'Texto del requisito' })
  @IsOptional()
  @IsString()
  requirementText?: string;

  @ApiPropertyOptional({ description: 'Texto de referencia' })
  @IsOptional()
  @IsString()
  referenceText?: string | null;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  hasSubItems?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isChoiceGroup?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  choiceMin?: number | null;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  requiresEvidence?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  needsReview?: boolean;
}

export class ReorderRequirementsDto {
  @ApiProperty({ description: 'Lista de IDs en el nuevo orden', type: [Number] })
  @IsArray()
  @IsInt({ each: true })
  requirementIds: number[];
}

export class BatchReviewDto {
  @ApiProperty({ description: 'IDs de requisitos a aprobar', type: [Number] })
  @IsArray()
  @IsInt({ each: true })
  requirementIds: number[];

  @ApiProperty({ description: 'true = aprobar, false = rechazar' })
  @IsBoolean()
  approved: boolean;
}
```

- [ ] **Step 4: Update barrel export**

In `sacdia-backend/src/honors/dto/index.ts`, ensure all new DTOs are exported:

```typescript
export * from './honors.dto';
export * from './honor-requirements.dto';
```

- [ ] **Step 5: Commit**

```bash
cd sacdia-backend
git add src/honors/dto/
git commit -m "feat(honors): add DTOs for evidence, text_response, admin requirements CRUD, and review"
```

---

## Task 3: Backend Service — Hierarchical Queries + Evidence Validation

**Files:**
- Modify: `sacdia-backend/src/honors/honor-requirements.service.ts`

- [ ] **Step 1: Update `getRequirements` to return hierarchical tree**

Replace the `getRequirements` method:

```typescript
async getRequirements(honorId: number) {
  const honor = await this.prisma.honors.findUnique({
    where: { honor_id: honorId },
    select: { honor_id: true },
  });

  if (!honor) {
    throw new NotFoundException(`Honor with ID ${honorId} not found`);
  }

  const allRequirements = await this.prisma.honor_requirements.findMany({
    where: { honor_id: honorId, active: true },
    orderBy: { requirement_number: 'asc' },
  });

  // Build tree: top-level items with nested children
  const topLevel = allRequirements.filter((r) => r.parent_id === null);
  const childrenByParent = new Map<number, typeof allRequirements>();

  for (const req of allRequirements) {
    if (req.parent_id !== null) {
      const siblings = childrenByParent.get(req.parent_id) ?? [];
      siblings.push(req);
      childrenByParent.set(req.parent_id, siblings);
    }
  }

  return topLevel.map((req) => ({
    ...req,
    children: childrenByParent.get(req.requirement_id) ?? [],
  }));
}
```

- [ ] **Step 2: Update `getUserProgress` to include `text_response`, evidences, and hierarchy**

Replace the `getUserProgress` method:

```typescript
async getUserProgress(userId: string, honorId: number) {
  const userHonor = await this.prisma.users_honors.findFirst({
    where: {
      user_id: userId,
      honor_id: honorId,
      active: true,
    },
    select: { user_honor_id: true },
  });

  if (!userHonor) {
    throw new NotFoundException(
      `User ${userId} is not enrolled in honor ${honorId}`,
    );
  }

  const requirements = await this.prisma.honor_requirements.findMany({
    where: { honor_id: honorId, active: true },
    orderBy: { requirement_number: 'asc' },
  });

  const progressRows =
    await this.prisma.user_honor_requirement_progress.findMany({
      where: {
        user_honor_id: userHonor.user_honor_id,
        active: true,
      },
      include: {
        requirement_evidence: {
          where: { active: true },
          orderBy: { created_at: 'asc' },
        },
      },
    });

  const progressByRequirement = new Map(
    progressRows.map((p) => [p.requirement_id, p]),
  );

  const mergeRequirement = (req: (typeof requirements)[0]) => {
    const progress = progressByRequirement.get(req.requirement_id);
    return {
      requirement_id: req.requirement_id,
      requirement_number: req.requirement_number,
      display_label: req.display_label,
      requirement_text: req.requirement_text,
      reference_text: req.reference_text,
      has_sub_items: req.has_sub_items,
      is_choice_group: req.is_choice_group,
      choice_min: req.choice_min,
      requires_evidence: req.requires_evidence,
      needs_review: req.needs_review,
      completed: progress?.completed ?? false,
      text_response: progress?.text_response ?? null,
      notes: progress?.notes ?? null,
      completed_at: progress?.completed_at ?? null,
      evidences: (progress?.requirement_evidence ?? []).map((e) => ({
        evidence_id: e.evidence_id,
        evidence_type: e.evidence_type,
        url: e.url,
        filename: e.filename,
        mime_type: e.mime_type,
        file_size: e.file_size,
      })),
    };
  };

  // Build tree
  const topLevel = requirements.filter((r) => r.parent_id === null);
  const childrenByParent = new Map<number, typeof requirements>();
  for (const req of requirements) {
    if (req.parent_id !== null) {
      const siblings = childrenByParent.get(req.parent_id) ?? [];
      siblings.push(req);
      childrenByParent.set(req.parent_id, siblings);
    }
  }

  const mergedTree = topLevel.map((req) => ({
    ...mergeRequirement(req),
    children: (childrenByParent.get(req.requirement_id) ?? []).map(mergeRequirement),
  }));

  // Count only leaf requirements for progress
  const leafRequirements = requirements.filter(
    (r) => !childrenByParent.has(r.requirement_id),
  );
  const totalRequirements = leafRequirements.length;
  const completedCount = leafRequirements.filter(
    (r) => progressByRequirement.get(r.requirement_id)?.completed,
  ).length;
  const progressPercentage =
    totalRequirements === 0
      ? 0
      : Math.round((completedCount / totalRequirements) * 10000) / 100;

  return {
    user_honor_id: userHonor.user_honor_id,
    honor_id: honorId,
    total_requirements: totalRequirements,
    completed_count: completedCount,
    progress_percentage: progressPercentage,
    requirements: mergedTree,
  };
}
```

- [ ] **Step 3: Update `updateProgress` to validate evidence and accept `textResponse`**

Replace the `updateProgress` method:

```typescript
async updateProgress(
  userId: string,
  honorId: number,
  dto: UpdateRequirementProgressDto,
) {
  const requirement = await this.prisma.honor_requirements.findUnique({
    where: { requirement_id: dto.requirementId },
    select: {
      requirement_id: true,
      honor_id: true,
      requires_evidence: true,
      has_sub_items: true,
    },
  });

  if (!requirement || requirement.honor_id !== honorId) {
    throw new BadRequestException(
      `Requirement ${dto.requirementId} does not belong to honor ${honorId}`,
    );
  }

  const userHonor = await this.prisma.users_honors.findFirst({
    where: {
      user_id: userId,
      honor_id: honorId,
      active: true,
    },
    select: { user_honor_id: true },
  });

  if (!userHonor) {
    throw new NotFoundException(
      `User ${userId} is not enrolled in honor ${honorId}`,
    );
  }

  // Validate evidence requirement before marking complete
  if (dto.completed && requirement.requires_evidence) {
    const existingProgress =
      await this.prisma.user_honor_requirement_progress.findUnique({
        where: {
          user_honor_id_requirement_id: {
            user_honor_id: userHonor.user_honor_id,
            requirement_id: dto.requirementId,
          },
        },
        include: {
          requirement_evidence: { where: { active: true } },
        },
      });

    const hasEvidence =
      (existingProgress?.requirement_evidence?.length ?? 0) > 0;

    if (!hasEvidence) {
      throw new BadRequestException(
        'Este requisito requiere al menos una evidencia para marcarse como completado',
      );
    }
  }

  return this.prisma.user_honor_requirement_progress.upsert({
    where: {
      user_honor_id_requirement_id: {
        user_honor_id: userHonor.user_honor_id,
        requirement_id: dto.requirementId,
      },
    },
    update: {
      completed: dto.completed,
      ...(dto.textResponse !== undefined && {
        text_response: dto.textResponse,
      }),
      ...(dto.notes !== undefined && { notes: dto.notes }),
      completed_at: dto.completed ? new Date() : null,
      modified_at: new Date(),
    },
    create: {
      user_honor_id: userHonor.user_honor_id,
      requirement_id: dto.requirementId,
      completed: dto.completed,
      text_response: dto.textResponse ?? null,
      notes: dto.notes ?? null,
      completed_at: dto.completed ? new Date() : null,
    },
  });
}
```

- [ ] **Step 4: Add evidence CRUD methods**

Add these methods to `HonorRequirementsService`:

```typescript
private static readonly MAX_EVIDENCE_PER_TYPE = 3;

async uploadEvidence(
  userId: string,
  honorId: number,
  requirementId: number,
  file: Express.Multer.File,
  evidenceType: 'IMAGE' | 'FILE',
) {
  const { progressId } = await this.getOrCreateProgress(
    userId,
    honorId,
    requirementId,
  );

  // Check limit per type
  const existingCount = await this.prisma.requirement_evidence.count({
    where: {
      progress_id: progressId,
      evidence_type: evidenceType,
      active: true,
    },
  });

  if (existingCount >= HonorRequirementsService.MAX_EVIDENCE_PER_TYPE) {
    throw new BadRequestException(
      `Máximo ${HonorRequirementsService.MAX_EVIDENCE_PER_TYPE} evidencias de tipo ${evidenceType} por requisito`,
    );
  }

  // Upload to R2 — delegate to R2FileStorageService
  const r2Key = `requirement_evidence/${userId}/${honorId}/${requirementId}/${Date.now()}-${file.originalname}`;
  const url = await this.r2FileStorageService.uploadFile(r2Key, file.buffer, file.mimetype);

  return this.prisma.requirement_evidence.create({
    data: {
      progress_id: progressId,
      evidence_type: evidenceType,
      url,
      filename: file.originalname,
      mime_type: file.mimetype,
      file_size: file.size,
    },
  });
}

async addEvidenceLink(
  userId: string,
  honorId: number,
  requirementId: number,
  url: string,
) {
  const { progressId } = await this.getOrCreateProgress(
    userId,
    honorId,
    requirementId,
  );

  const existingCount = await this.prisma.requirement_evidence.count({
    where: {
      progress_id: progressId,
      evidence_type: 'LINK',
      active: true,
    },
  });

  if (existingCount >= HonorRequirementsService.MAX_EVIDENCE_PER_TYPE) {
    throw new BadRequestException(
      `Máximo ${HonorRequirementsService.MAX_EVIDENCE_PER_TYPE} enlaces por requisito`,
    );
  }

  return this.prisma.requirement_evidence.create({
    data: {
      progress_id: progressId,
      evidence_type: 'LINK',
      url,
    },
  });
}

async getEvidences(userId: string, honorId: number, requirementId: number) {
  const { progressId } = await this.getOrCreateProgress(
    userId,
    honorId,
    requirementId,
  );

  const evidences = await this.prisma.requirement_evidence.findMany({
    where: { progress_id: progressId, active: true },
    orderBy: { created_at: 'asc' },
  });

  // Sign R2 URLs for IMAGE and FILE types
  return Promise.all(
    evidences.map(async (e) => ({
      ...e,
      url:
        e.evidence_type === 'LINK'
          ? e.url
          : await this.r2FileStorageService.getSignedUrl(e.url, 300),
    })),
  );
}

async deleteEvidence(
  userId: string,
  honorId: number,
  requirementId: number,
  evidenceId: number,
) {
  const { progressId } = await this.getOrCreateProgress(
    userId,
    honorId,
    requirementId,
  );

  const evidence = await this.prisma.requirement_evidence.findFirst({
    where: {
      evidence_id: evidenceId,
      progress_id: progressId,
      active: true,
    },
  });

  if (!evidence) {
    throw new NotFoundException(`Evidence ${evidenceId} not found`);
  }

  return this.prisma.requirement_evidence.update({
    where: { evidence_id: evidenceId },
    data: { active: false, modified_at: new Date() },
  });
}

private async getOrCreateProgress(
  userId: string,
  honorId: number,
  requirementId: number,
) {
  const requirement = await this.prisma.honor_requirements.findUnique({
    where: { requirement_id: requirementId },
    select: { requirement_id: true, honor_id: true },
  });

  if (!requirement || requirement.honor_id !== honorId) {
    throw new BadRequestException(
      `Requirement ${requirementId} does not belong to honor ${honorId}`,
    );
  }

  const userHonor = await this.prisma.users_honors.findFirst({
    where: { user_id: userId, honor_id: honorId, active: true },
    select: { user_honor_id: true },
  });

  if (!userHonor) {
    throw new NotFoundException(
      `User ${userId} is not enrolled in honor ${honorId}`,
    );
  }

  const progress =
    await this.prisma.user_honor_requirement_progress.upsert({
      where: {
        user_honor_id_requirement_id: {
          user_honor_id: userHonor.user_honor_id,
          requirement_id: requirementId,
        },
      },
      update: {},
      create: {
        user_honor_id: userHonor.user_honor_id,
        requirement_id: requirementId,
      },
    });

  return { progressId: progress.progress_id };
}
```

- [ ] **Step 5: Inject R2FileStorageService in constructor**

Update the constructor:

```typescript
import { R2FileStorageService } from '../common/services/r2-file-storage.service';

@Injectable()
export class HonorRequirementsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly r2FileStorageService: R2FileStorageService,
  ) {}
  // ...
}
```

- [ ] **Step 6: Commit**

```bash
cd sacdia-backend
git add src/honors/honor-requirements.service.ts
git commit -m "feat(honors): add hierarchical queries, evidence CRUD, and text_response support"
```

---

## Task 4: Backend Controller — Evidence Endpoints

**Files:**
- Modify: `sacdia-backend/src/honors/honor-requirements.controller.ts`

- [ ] **Step 1: Add evidence endpoints to `UserHonorRequirementsController`**

Add these endpoints after the existing `updateProgress` method in the authenticated controller:

```typescript
import {
  Post,
  Delete,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { CreateEvidenceLinkDto } from './dto';

// Inside UserHonorRequirementsController:

@Post(':honorId/requirements/:requirementId/evidence/upload')
@AuthorizationResource({ type: 'user', ownerParam: 'userId' })
@RequirePermissions('user_honors:create')
@UseInterceptors(FileInterceptor('file'))
@ApiOperation({ summary: 'Subir evidencia (imagen o archivo) para un requisito' })
@ApiParam({ name: 'userId', type: String })
@ApiParam({ name: 'honorId', type: Number })
@ApiParam({ name: 'requirementId', type: Number })
async uploadEvidence(
  @Param('userId', ParseUUIDPipe) userId: string,
  @Param('honorId', ParseIntPipe) honorId: number,
  @Param('requirementId', ParseIntPipe) requirementId: number,
  @UploadedFile() file: Express.Multer.File,
) {
  const imageTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/heic'];
  const evidenceType = imageTypes.includes(file.mimetype) ? 'IMAGE' : 'FILE';

  const maxSize = evidenceType === 'IMAGE' ? 10 * 1024 * 1024 : 25 * 1024 * 1024;
  if (file.size > maxSize) {
    throw new BadRequestException(
      `Archivo demasiado grande. Máximo: ${maxSize / (1024 * 1024)}MB`,
    );
  }

  const data = await this.honorRequirementsService.uploadEvidence(
    userId, honorId, requirementId, file, evidenceType,
  );
  return { status: 'success', data };
}

@Post(':honorId/requirements/:requirementId/evidence/link')
@AuthorizationResource({ type: 'user', ownerParam: 'userId' })
@RequirePermissions('user_honors:create')
@ApiOperation({ summary: 'Agregar enlace como evidencia para un requisito' })
@ApiParam({ name: 'userId', type: String })
@ApiParam({ name: 'honorId', type: Number })
@ApiParam({ name: 'requirementId', type: Number })
async addEvidenceLink(
  @Param('userId', ParseUUIDPipe) userId: string,
  @Param('honorId', ParseIntPipe) honorId: number,
  @Param('requirementId', ParseIntPipe) requirementId: number,
  @Body() dto: CreateEvidenceLinkDto,
) {
  const data = await this.honorRequirementsService.addEvidenceLink(
    userId, honorId, requirementId, dto.url,
  );
  return { status: 'success', data };
}

@Get(':honorId/requirements/:requirementId/evidence')
@AuthorizationResource({ type: 'user', ownerParam: 'userId' })
@RequirePermissions('user_honors:read')
@ApiOperation({ summary: 'Listar evidencias de un requisito' })
async getEvidences(
  @Param('userId', ParseUUIDPipe) userId: string,
  @Param('honorId', ParseIntPipe) honorId: number,
  @Param('requirementId', ParseIntPipe) requirementId: number,
) {
  const data = await this.honorRequirementsService.getEvidences(
    userId, honorId, requirementId,
  );
  return { status: 'success', data };
}

@Delete(':honorId/requirements/:requirementId/evidence/:evidenceId')
@AuthorizationResource({ type: 'user', ownerParam: 'userId' })
@RequirePermissions('user_honors:delete')
@ApiOperation({ summary: 'Eliminar una evidencia de un requisito' })
async deleteEvidence(
  @Param('userId', ParseUUIDPipe) userId: string,
  @Param('honorId', ParseIntPipe) honorId: number,
  @Param('requirementId', ParseIntPipe) requirementId: number,
  @Param('evidenceId', ParseIntPipe) evidenceId: number,
) {
  const data = await this.honorRequirementsService.deleteEvidence(
    userId, honorId, requirementId, evidenceId,
  );
  return { status: 'success', data };
}
```

- [ ] **Step 2: Commit**

```bash
cd sacdia-backend
git add src/honors/honor-requirements.controller.ts
git commit -m "feat(honors): add evidence upload, link, list, and delete endpoints"
```

---

## Task 5: Backend — Admin Requirements Controller + Service

**Files:**
- Create: `sacdia-backend/src/admin/admin-honors.controller.ts`
- Create: `sacdia-backend/src/admin/admin-honors.service.ts`
- Modify: `sacdia-backend/src/honors/honors.module.ts`

- [ ] **Step 1: Create `admin-honors.service.ts`**

Create `sacdia-backend/src/admin/admin-honors.service.ts` with methods for:
- `getRequirements(honorId)` — returns full tree with all flags
- `createRequirement(dto: CreateRequirementDto)` — creates top-level or sub-item
- `updateRequirement(requirementId, dto: UpdateRequirementDto)` — updates any field
- `deleteRequirement(requirementId)` — soft-delete (sets active=false)
- `reorderRequirements(honorId, dto: ReorderRequirementsDto)` — batch reorder
- `getPendingReview(page, limit, filters)` — paginated pending review list
- `batchReview(dto: BatchReviewDto)` — batch approve/reject

Follow the pattern from existing admin services (e.g., `admin-users.service.ts`). Use `PrismaService` injection. Each method should validate the honor exists and check constraints (e.g., `choice_min` requires `is_choice_group=true`).

- [ ] **Step 2: Create `admin-honors.controller.ts`**

Create `sacdia-backend/src/admin/admin-honors.controller.ts` with routes:
- `GET /api/v1/admin/honors/:honorId/requirements` — list requirements tree
- `POST /api/v1/admin/honors/:honorId/requirements` — create requirement
- `PATCH /api/v1/admin/honors/requirements/:requirementId` — update requirement
- `DELETE /api/v1/admin/honors/requirements/:requirementId` — soft-delete
- `PATCH /api/v1/admin/honors/:honorId/requirements/reorder` — reorder
- `GET /api/v1/admin/honors/requirements/pending-review` — pending review list
- `PATCH /api/v1/admin/honors/requirements/batch-review` — batch review

Use `@UseGuards(JwtAuthGuard, GlobalRolesGuard)` with `@Roles('admin', 'super_admin')` following the existing admin controller pattern.

- [ ] **Step 3: Register in module**

Add `AdminHonorsService` and `AdminHonorsController` to `sacdia-backend/src/honors/honors.module.ts` (or the admin module if honors references are properly imported).

- [ ] **Step 4: Commit**

```bash
cd sacdia-backend
git add src/admin/admin-honors.controller.ts src/admin/admin-honors.service.ts src/honors/honors.module.ts
git commit -m "feat(admin): add requirements CRUD and review workflow endpoints"
```

---

## Task 6: PDF Re-scan Script

**Files:**
- Create: `sacdia-backend/prisma/seeds/honor-requirements-rescan.seed.ts`

- [ ] **Step 1: Create the improved re-scan seed script**

This script:
1. Reads all 605 PDFs from `/Users/abner/Downloads/S3/honors_pdf/`
2. Uses improved parsing to detect: real numbering vs sub-items, choice groups, reference tables
3. Classifies `requires_evidence` based on verb analysis
4. Compares against current DB data
5. Generates update SQL (never deletes)
6. Supports `--dry-run` mode

The script should:
- Use `pdf-parse` or `pdfjs-dist` for PDF text extraction
- Parse requirement structure with regex patterns for numbered lists, lettered sub-items, Roman numeral sub-sub-items
- Detect choice patterns: "de los siguientes", "al menos N de", "completar N de"
- Classify verbs: practical (construir, demostrar, hacer) vs theoretical (definir, explicar, describir)
- Output: JSON per honor with hierarchical requirements

**Note:** This task will be executed with Sonnet sub-agents in parallel batches of ~60-80 PDFs each. The plan provides the script structure; actual execution is parallelized at runtime.

- [ ] **Step 2: Run dry-run and review output**

```bash
cd sacdia-backend && npx tsx prisma/seeds/honor-requirements-rescan.seed.ts --dry-run
```

Review the diff output. Check match rates and flagged issues.

- [ ] **Step 3: Apply updates to DB**

```bash
cd sacdia-backend && npx tsx prisma/seeds/honor-requirements-rescan.seed.ts
```

- [ ] **Step 4: Commit**

```bash
cd sacdia-backend
git add prisma/seeds/honor-requirements-rescan.seed.ts
git commit -m "feat(honors): add improved PDF re-scan seed script with hierarchy and evidence classification"
```

---

## Task 7: Flutter — Entity + Model Updates

**SKILL:** Use `mobile-design` skill before designing any UI components.

**Files:**
- Modify: `sacdia-app/lib/features/honors/domain/entities/honor_requirement.dart`
- Create: `sacdia-app/lib/features/honors/domain/entities/requirement_evidence.dart`
- Modify: `sacdia-app/lib/features/honors/domain/entities/user_honor_requirement_progress.dart`
- Modify: `sacdia-app/lib/features/honors/data/models/honor_requirement_model.dart`
- Create: `sacdia-app/lib/features/honors/data/models/requirement_evidence_model.dart`
- Modify: `sacdia-app/lib/features/honors/data/models/user_honor_requirement_progress_model.dart`

- [ ] **Step 1: Update `HonorRequirement` entity**

Add fields: `parentId`, `displayLabel`, `referenceText`, `isChoiceGroup`, `choiceMin`, `requiresEvidence`, `children`. Update `copyWith` and `props`.

- [ ] **Step 2: Create `RequirementEvidence` entity**

New file with fields: `id`, `evidenceType` (enum: image, file, link), `url`, `filename`, `mimeType`, `fileSize`.

- [ ] **Step 3: Update `UserHonorRequirementProgress` entity**

Add fields: `textResponse`, `evidences` (List<RequirementEvidence>).

- [ ] **Step 4: Update models (`fromJson`/`toJson`) to match new API contract**

Update `HonorRequirementModel.fromJson` to parse `parent_id`, `display_label`, `reference_text`, `is_choice_group`, `choice_min`, `requires_evidence`, and nested `children` array.

Create `RequirementEvidenceModel` with `fromJson`/`toJson`.

Update `UserHonorRequirementProgressModel` to include `text_response` and `evidences`.

- [ ] **Step 5: Commit**

```bash
cd sacdia-app
git add lib/features/honors/domain/entities/ lib/features/honors/data/models/
git commit -m "feat(honors): update entities and models for hierarchical requirements and evidence"
```

---

## Task 8: Flutter — Repository + Data Source + Use Cases

**Files:**
- Modify: `sacdia-app/lib/features/honors/data/datasources/honors_remote_data_source.dart`
- Modify: `sacdia-app/lib/features/honors/data/repositories/honors_repository_impl.dart`
- Modify: `sacdia-app/lib/features/honors/domain/repositories/honors_repository.dart`
- Create: `sacdia-app/lib/features/honors/domain/usecases/upload_requirement_evidence.dart`
- Create: `sacdia-app/lib/features/honors/domain/usecases/delete_requirement_evidence.dart`

- [ ] **Step 1: Add evidence methods to remote data source**

Add to `HonorsRemoteDataSource`:
- `uploadRequirementEvidence(userId, honorId, requirementId, File file)` — multipart POST
- `addRequirementEvidenceLink(userId, honorId, requirementId, String url)` — JSON POST
- `getRequirementEvidences(userId, honorId, requirementId)` — GET
- `deleteRequirementEvidence(userId, honorId, requirementId, evidenceId)` — DELETE

- [ ] **Step 2: Add evidence methods to repository interface + implementation**

Mirror the data source methods in both the interface and implementation.

- [ ] **Step 3: Create use cases**

Create `UploadRequirementEvidence` and `DeleteRequirementEvidence` use cases following the existing pattern (e.g., `start_honor.dart`).

- [ ] **Step 4: Commit**

```bash
cd sacdia-app
git add lib/features/honors/
git commit -m "feat(honors): add evidence data layer - datasource, repository, and use cases"
```

---

## Task 9: Flutter — Providers + Notifiers

**Files:**
- Modify: `sacdia-app/lib/features/honors/presentation/providers/honors_providers.dart`

- [ ] **Step 1: Add evidence providers**

Add to `honors_providers.dart`:

```dart
// Evidence for a specific requirement
final requirementEvidenceProvider = FutureProvider.autoDispose
    .family<List<RequirementEvidence>, ({String userId, int honorId, int requirementId})>(
  (ref, params) async {
    final repo = ref.watch(honorsRepositoryProvider);
    return repo.getRequirementEvidences(params.userId, params.honorId, params.requirementId);
  },
);
```

- [ ] **Step 2: Add `RequirementEvidenceNotifier`**

```dart
class RequirementEvidenceNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> uploadEvidence({
    required String userId,
    required int honorId,
    required int requirementId,
    required File file,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(honorsRepositoryProvider);
      await repo.uploadRequirementEvidence(userId, honorId, requirementId, file);
      // Invalidate progress and evidence providers
      ref.invalidate(userHonorProgressProvider((userId: userId, honorId: honorId)));
      ref.invalidate(requirementEvidenceProvider(
        (userId: userId, honorId: honorId, requirementId: requirementId),
      ));
    });
  }

  Future<void> addLink({
    required String userId,
    required int honorId,
    required int requirementId,
    required String url,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(honorsRepositoryProvider);
      await repo.addRequirementEvidenceLink(userId, honorId, requirementId, url);
      ref.invalidate(userHonorProgressProvider((userId: userId, honorId: honorId)));
      ref.invalidate(requirementEvidenceProvider(
        (userId: userId, honorId: honorId, requirementId: requirementId),
      ));
    });
  }

  Future<void> deleteEvidence({
    required String userId,
    required int honorId,
    required int requirementId,
    required int evidenceId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(honorsRepositoryProvider);
      await repo.deleteRequirementEvidence(userId, honorId, requirementId, evidenceId);
      ref.invalidate(userHonorProgressProvider((userId: userId, honorId: honorId)));
      ref.invalidate(requirementEvidenceProvider(
        (userId: userId, honorId: honorId, requirementId: requirementId),
      ));
    });
  }
}

final requirementEvidenceNotifierProvider =
    AutoDisposeAsyncNotifierProvider<RequirementEvidenceNotifier, void>(
  RequirementEvidenceNotifier.new,
);
```

- [ ] **Step 3: Update `RequirementProgressNotifier` to include `textResponse`**

Modify the existing notifier to pass `textResponse` in the update DTO.

- [ ] **Step 4: Commit**

```bash
cd sacdia-app
git add lib/features/honors/presentation/providers/
git commit -m "feat(honors): add evidence providers and notifiers, update progress for text_response"
```

---

## Task 10: Flutter — Requirements View Refactor

**SKILL:** Use `mobile-design` skill before implementing UI.

**Files:**
- Modify: `sacdia-app/lib/features/honors/presentation/views/honor_requirements_view.dart`
- Create: `sacdia-app/lib/features/honors/presentation/widgets/requirement_tree_item.dart`
- Create: `sacdia-app/lib/features/honors/presentation/widgets/evidence_upload_sheet.dart`
- Create: `sacdia-app/lib/features/honors/presentation/widgets/choice_group_header.dart`

- [ ] **Step 1: Create `RequirementTreeItem` widget**

Widget that renders a single requirement with:
- Indentation based on depth (top-level vs sub-item)
- Checkbox for completion
- Expandable text response field (800 chars)
- Evidence button (colored if `requiresEvidence`, grey if optional)
- Expand/collapse for sub-items
- Reference text accordion

- [ ] **Step 2: Create `ChoiceGroupHeader` widget**

Widget showing "Completá N de M" with progress count.

- [ ] **Step 3: Create `EvidenceUploadSheet` widget**

Bottom sheet with 3 sections:
- Fotos (camera/gallery via image_picker, max 3)
- Archivos (file_picker, max 3)
- Enlaces (text input with URL validation, max 3)
- Preview of existing evidences with delete button

- [ ] **Step 4: Refactor `honor_requirements_view.dart`**

Replace the flat list with a hierarchical tree using `RequirementTreeItem`. Handle:
- Top-level requirements as expandable items
- Sub-items indented under parent
- Choice groups with `ChoiceGroupHeader`
- Auto-complete parent when children meet criteria

- [ ] **Step 5: Commit**

```bash
cd sacdia-app
git add lib/features/honors/presentation/
git commit -m "feat(honors): refactor requirements view with hierarchy, evidence upload, and choice groups"
```

---

## Task 11: Admin — API Client Updates

**Files:**
- Modify: `sacdia-admin/src/lib/api/honors.ts`

- [ ] **Step 1: Add admin requirements API methods**

Add to the honors API client:

```typescript
// Admin Requirements CRUD
export async function listRequirements(honorId: number) {
  return fetchApi<RequirementTree[]>(`/admin/honors/${honorId}/requirements`);
}

export async function createRequirement(honorId: number, payload: CreateRequirementPayload) {
  return fetchApi<Requirement>(`/admin/honors/${honorId}/requirements`, {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

export async function updateRequirement(requirementId: number, payload: UpdateRequirementPayload) {
  return fetchApi<Requirement>(`/admin/honors/requirements/${requirementId}`, {
    method: 'PATCH',
    body: JSON.stringify(payload),
  });
}

export async function deleteRequirement(requirementId: number) {
  return fetchApi(`/admin/honors/requirements/${requirementId}`, {
    method: 'DELETE',
  });
}

export async function reorderRequirements(honorId: number, requirementIds: number[]) {
  return fetchApi(`/admin/honors/${honorId}/requirements/reorder`, {
    method: 'PATCH',
    body: JSON.stringify({ requirementIds }),
  });
}

// Review workflow
export async function getPendingReview(page = 1, limit = 20, filters?: ReviewFilters) {
  const params = new URLSearchParams({ page: String(page), limit: String(limit) });
  if (filters?.honorId) params.set('honorId', String(filters.honorId));
  if (filters?.categoryId) params.set('categoryId', String(filters.categoryId));
  return fetchApi<PaginatedResponse<ReviewRequirement>>(
    `/admin/honors/requirements/pending-review?${params}`,
  );
}

export async function batchReview(requirementIds: number[], approved: boolean) {
  return fetchApi(`/admin/honors/requirements/batch-review`, {
    method: 'PATCH',
    body: JSON.stringify({ requirementIds, approved }),
  });
}
```

- [ ] **Step 2: Add TypeScript types**

Add types for `RequirementTree`, `CreateRequirementPayload`, `UpdateRequirementPayload`, `ReviewRequirement`, `ReviewFilters`, `PaginatedResponse`.

- [ ] **Step 3: Commit**

```bash
cd sacdia-admin
git add src/lib/api/honors.ts
git commit -m "feat(admin): add requirements CRUD and review workflow API client"
```

---

## Task 12: Admin — Requirements Management Page

**SKILL:** Use `frontend-design` and `ui-designer` skills before implementing UI.

**Files:**
- Create: `sacdia-admin/src/app/(dashboard)/dashboard/honors/[honorId]/requirements/page.tsx`
- Create: `sacdia-admin/src/components/honors/requirements-tree.tsx`
- Create: `sacdia-admin/src/components/honors/requirement-edit-dialog.tsx`

- [ ] **Step 1: Create `requirements-tree.tsx` component**

Hierarchical tree table with:
- Columns: display_label, text (truncated), has_sub_items, is_choice_group, choice_min, requires_evidence, needs_review, actions
- Expand/collapse sub-items with indentation
- Drag & drop reorder (using `@dnd-kit/core` or similar library already in the project)
- Inline toggle for boolean flags
- Action dropdown: Edit, Add Sub-item, Delete

- [ ] **Step 2: Create `requirement-edit-dialog.tsx` component**

Dialog (shadcn/ui) with form fields:
- `displayLabel` (input, max 10 chars)
- `requirementText` (textarea)
- `referenceText` (textarea, optional)
- `isChoiceGroup` (switch)
- `choiceMin` (number input, visible if isChoiceGroup)
- `requiresEvidence` (switch)
- `needsReview` (switch)

- [ ] **Step 3: Create the page at `[honorId]/requirements/page.tsx`**

Server component that:
- Fetches honor details and requirements tree
- Renders `RequirementsTree` with action handlers
- "Agregar requisito" button opens `RequirementEditDialog` in create mode
- Link back to honor detail page

- [ ] **Step 4: Add navigation link from honor detail page**

Add a "Gestionar Requisitos" button/link on the existing honor detail page that navigates to `/dashboard/honors/[honorId]/requirements`.

- [ ] **Step 5: Commit**

```bash
cd sacdia-admin
git add src/app/(dashboard)/dashboard/honors/ src/components/honors/
git commit -m "feat(admin): add requirements management page with tree view and CRUD dialogs"
```

---

## Task 13: Admin — Review Workflow Page

**SKILL:** Use `frontend-design` and `ui-designer` skills before implementing UI.

**Files:**
- Create: `sacdia-admin/src/app/(dashboard)/dashboard/honors/requirements/review/page.tsx`
- Create: `sacdia-admin/src/components/honors/review-split-view.tsx`

- [ ] **Step 1: Create `review-split-view.tsx` component**

Split view component:
- Left panel: PDF embed (iframe pointing to `material_url` of the honor)
- Right panel: Editable requirement form (same fields as edit dialog)
- Navigation: Previous/Next buttons to move through pending requirements
- Actions: "Aprobar" (sets needs_review=false), "Editar + Aprobar", "Rechazar" (soft-delete)

- [ ] **Step 2: Create the review page**

Page at `/dashboard/honors/requirements/review` with:
- Paginated list of requirements with `needs_review=true`
- Filters: by honor, by category
- Checkbox selection for batch actions
- "Aprobar seleccionados" and "Rechazar seleccionados" buttons
- Click on a requirement opens `ReviewSplitView`

- [ ] **Step 3: Add navigation link to the review page**

Add a "Revisar Requisitos Pendientes" link in the honors dashboard or sidebar navigation.

- [ ] **Step 4: Commit**

```bash
cd sacdia-admin
git add src/app/(dashboard)/dashboard/honors/requirements/ src/components/honors/
git commit -m "feat(admin): add requirements review workflow with split view and batch actions"
```

---

## Task 14: Integration Testing + Final Verification

- [ ] **Step 1: Verify backend starts cleanly**

```bash
cd sacdia-backend && pnpm run start:dev
```

Check: No TypeScript errors, all routes registered in Swagger at `/api`.

- [ ] **Step 2: Verify Flutter app compiles**

```bash
cd sacdia-app && flutter analyze && flutter build apk --debug
```

Check: No analysis errors, build succeeds.

- [ ] **Step 3: Verify admin panel builds**

```bash
cd sacdia-admin && pnpm run build
```

Check: No TypeScript errors, build succeeds.

- [ ] **Step 4: Manual smoke test**

1. Backend: Hit `GET /honors/1/requirements` — verify hierarchical response
2. Flutter: Open honors catalog → select honor → verify requirements tree renders
3. Admin: Navigate to honors → select honor → "Gestionar Requisitos" → verify tree

- [ ] **Step 5: Final commit with any fixes**

```bash
# In each repo that has fixes
git add -A && git commit -m "fix(honors): integration fixes from smoke testing"
```
