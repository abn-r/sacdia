# Honors Flow Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the honors (especialidades) flow in sacdia-app with a minimalist evidence-based UI, adding status tracking and backend validation field population.

**Architecture:** Three phases — (1) Backend: Prisma migration + update validation service, (2) Flutter data layer: update entities/models/providers for new status flow, (3) Flutter presentation: redesign all views and widgets per approved mockup v3.

**Tech Stack:** NestJS + Prisma (backend), Flutter + Riverpod (app), Cloudflare R2 (file storage)

**Spec:** `docs/superpowers/specs/2026-03-25-honors-flow-redesign-design.md`
**Mockup:** `.superpowers/brainstorm/honors-redesign-mockup-v3.html`

---

## Status Mapping (CRITICAL)

The backend `validation_status` column on `users_honors` maps to display labels and colors as follows. The **key insight** is that `in_progress` has TWO display states depending on whether evidence files exist.

| Backend `validation_status` | Has evidence? | Display label (ES) | `AppColors` constant | Hex |
|----|-----|-----|-----|-----|
| `in_progress` | No | Inscripta — sin evidencia | `AppColors.sacBlue` | `#2EA0DA` |
| `in_progress` | Yes | En progreso | `AppColors.sacRed` | `#F06151` |
| `pending_review` | — | Enviada — en revision | `AppColors.sacYellow` | `#FBBD5E` |
| `approved` | — | Validada | `AppColors.sacGreen` | `#4FBF9F` |
| `rejected` | — | Rechazada | `AppColors.sacRed` | `#F06151` |

### Display status derivation logic (Flutter)

This goes in the `UserHonor` entity as a computed getter:

```dart
/// Display status combines backend validation_status with evidence presence.
String get displayStatus {
  if (validationStatus == 'approved') return 'validado';
  if (validationStatus == 'rejected') return 'rechazado';
  if (validationStatus == 'pending_review') return 'enviado';
  // in_progress: split by evidence
  if (images.isNotEmpty || document != null) return 'en_progreso';
  return 'inscripto';
}

Color get statusColor {
  switch (displayStatus) {
    case 'validado': return AppColors.sacGreen;
    case 'enviado': return AppColors.sacYellow;
    case 'en_progreso':
    case 'rechazado': return AppColors.sacRed;
    case 'inscripto': return AppColors.sacBlue;
    default: return AppColors.sacGrey;
  }
}

String get statusLabel {
  switch (displayStatus) {
    case 'validado': return 'Validada';
    case 'enviado': return 'Enviada — en revision';
    case 'en_progreso': return 'En progreso';
    case 'rechazado': return 'Rechazada';
    case 'inscripto': return 'Inscripta — sin evidencia';
    default: return 'Disponible';
  }
}
```

---

## Existing Code Inventory (Read Before Implementing)

### Backend — `sacdia-backend/`

| File | Current state | Action |
|------|--------------|--------|
| `prisma/schema.prisma` (line ~1211) | `users_honors` has `validation_status String @default("in_progress")` but MISSING: `submitted_at`, `validated_by_id`, `validated_at`, `rejection_reason` | **Migrate** |
| `src/validation/validation.service.ts` (line ~123) | `submitHonorForReview()` sets `validation_status: 'pending_review'` but does NOT set `submitted_at` | **Update** |
| `src/validation/validation.service.ts` (line ~319) | `reviewHonor()` sets `validation_status: 'in_progress'` on reject (loses rejected state) and does NOT populate `validated_by_id`, `validated_at`, `rejection_reason` | **Update** |
| `src/honors/honors.service.ts` (line ~278) | `startHonor()` creates with `validate: false, certificate: '', images: []` but does NOT set `validation_status` explicitly (relies on DB default) | **Update** |
| `src/honors/honors.service.ts` (line ~752) | `getUserHonorStats()` counts `validate: true/false` only — no status breakdown | **Update** |
| `src/honors/dto/honors.dto.ts` | `UpdateUserHonorDto` lacks `validation_status` field | **Update** (optional, for admin) |
| `src/validation/dto/review-validation.dto.ts` | Already has `action: 'approved' | 'rejected'` + optional `comment` | **Keep** |
| `src/validation/validation.controller.ts` | Already has `POST /validation/submit` and `POST /validation/:entityType/:entityId/review` | **Keep** |

### Flutter — `sacdia-app/lib/features/honors/`

| File | Current state | Action |
|------|--------------|--------|
| `domain/entities/user_honor.dart` | 12 fields, `status` is computed `validate ? 'completed' : 'in_progress'` | **Rewrite** |
| `data/models/user_honor_model.dart` | `fromJson` parses 12 fields, no `validation_status` | **Rewrite** |
| `presentation/providers/honors_providers.dart` | Has `userHonorsProvider`, `honorCategoriesProvider`, `honorsProvider`, `HonorEnrollmentNotifier` | **Extend** |
| `presentation/widgets/honor_card.dart` | Takes `Honor` only, no status awareness | **Rewrite** |
| `presentation/widgets/honor_category_card.dart` | Simple SacCard grid tile | **Delete** |
| `presentation/widgets/honor_progress_card.dart` | Takes `UserHonor`, binary status display | **Delete** |
| `presentation/views/honors_catalog_view.dart` | Two-level: categories grid -> honors list | **Rewrite** |
| `presentation/views/honor_detail_view.dart` | Full detail + registration section + validation section | **Rewrite** |
| `presentation/views/my_honors_view.dart` | Tabs: "En progreso" / "Completados" with stats | **Rewrite** |
| `presentation/views/add_honor_view.dart` | Grid with search + chips (will be absorbed into catalog) | **Delete** |

### Flutter — `sacdia-app/lib/features/validation/`

| File | Current state | Action |
|------|--------------|--------|
| `domain/entities/validation.dart` | `ValidationEntityType.honor` with slug `'honor'` | **Keep** (reuse for evidence submission) |
| `presentation/providers/validation_providers.dart` | `SubmitValidationNotifier` with `submit(entityType, entityId)` | **Reuse** in evidence view |
| `data/datasources/validation_remote_data_source.dart` | `POST /validation/submit` with `entity_type` + `entity_id` | **Keep** |

---

## Phase 1: Backend (5 tasks)

### Task 1 — Prisma migration: add validation tracking fields to `users_honors`

- [ ] Create migration file

**File:** `sacdia-backend/prisma/schema.prisma`

Add the following fields to the `users_honors` model (at line ~1217, after `validation_status`):

```prisma
model users_honors {
  user_honor_id     Int       @id(map: "user_honors_pkey") @default(autoincrement())
  user_id           String    @db.Uuid
  honor_id          Int
  active            Boolean   @default(true)
  validate          Boolean   @default(false)
  validation_status String    @default("in_progress") @db.VarChar(20)
  submitted_at      DateTime? @db.Timestamptz(6)
  validated_by_id   String?   @db.Uuid
  validated_at      DateTime? @db.Timestamptz(6)
  rejection_reason  String?
  certificate       String    @db.VarChar
  images            Json      @default("[]")
  document          String?   @db.VarChar
  date              DateTime  @db.Date
  created_at        DateTime? @default(now()) @db.Timestamptz(6)
  modified_at       DateTime? @default(now()) @db.Timestamptz(6)
  honors            honors    @relation(fields: [honor_id], references: [honor_id], onDelete: NoAction, onUpdate: NoAction, map: "user_honors_honor_id_fkey")
  users             users     @relation(fields: [user_id], references: [user_id], onDelete: NoAction, onUpdate: NoAction, map: "user_honors_user_id_fkey")
  validator         users?    @relation("honor_validator", fields: [validated_by_id], references: [user_id], onDelete: NoAction, onUpdate: NoAction)

  @@unique([user_id, honor_id])
  @@index([user_id], map: "idx_users_honors_user_id")
  @@index([validation_status], map: "idx_users_honors_validation_status")
}
```

**Important:** The `validator` relation requires a corresponding reverse relation on the `users` model. Add this line to the `users` model (near line ~879, alongside other reverse relations):

```prisma
  honors_validated           users_honors[]   @relation("honor_validator")
```

Then run the migration:

```bash
cd sacdia-backend && pnpm prisma migrate dev --name add_honor_validation_fields
```

**Pattern reference:** This mirrors `class_section_progress` (lines 170-190 in schema.prisma) which already has `submitted_by_id`, `submitted_at`, `validated_by_id`, `validated_at`, `rejection_reason`.

---

### Task 2 — Update `ValidationService.submitHonorForReview()` to populate `submitted_at`

- [ ] Update the submit transaction

**File:** `sacdia-backend/src/validation/validation.service.ts`

In `submitHonorForReview()` (line ~152), update the `data` object in the `tx.users_honors.update()` call:

**Current code (line 153-158):**

```typescript
const updated = await tx.users_honors.update({
  where: { user_honor_id: userHonorId },
  data: {
    validation_status: 'pending_review',
    modified_at: new Date(),
  },
});
```

**New code:**

```typescript
const updated = await tx.users_honors.update({
  where: { user_honor_id: userHonorId },
  data: {
    validation_status: 'pending_review',
    submitted_at: new Date(),
    rejection_reason: null, // Clear any previous rejection
    modified_at: new Date(),
  },
});
```

**Why clear `rejection_reason`:** When a user resubmits after rejection, the old rejection reason should be cleared since it no longer applies.

---

### Task 3 — Update `ValidationService.reviewHonor()` to store `rejected` status and populate audit fields

- [ ] Update the review transaction

**File:** `sacdia-backend/src/validation/validation.service.ts`

In `reviewHonor()` (line ~335), update the transaction:

**Current code (lines 339-349):**

```typescript
const newValidationStatus =
  action === 'approved' ? 'approved' : 'in_progress';

const updated = await tx.users_honors.update({
  where: { user_honor_id: userHonorId },
  data: {
    validate: action === 'approved',
    validation_status: newValidationStatus,
    modified_at: new Date(),
  },
});
```

**New code:**

```typescript
const newValidationStatus =
  action === 'approved' ? 'approved' : 'rejected';

const updated = await tx.users_honors.update({
  where: { user_honor_id: userHonorId },
  data: {
    validate: action === 'approved',
    validation_status: newValidationStatus,
    validated_by_id: performedBy,
    validated_at: new Date(),
    rejection_reason: action === 'rejected' ? comment : null,
    modified_at: new Date(),
  },
});
```

**Key changes:**
1. Rejection now sets `'rejected'` instead of `'in_progress'` — the user explicitly sees their honor was rejected with a reason
2. `validated_by_id` and `validated_at` are populated for both approve and reject (audit trail)
3. `rejection_reason` is set on rejection, cleared on approval

**Downstream impact:** The `submitHonorForReview()` method (Task 2) also needs to accept submissions from `rejected` status. Update the status guard (line ~140-150):

**Current code:**

```typescript
if (userHonor.validate === true || userHonor.validation_status === 'approved') {
  throw new BadRequestException('El honor ya se encuentra validado');
}

if (userHonor.validation_status === 'pending_review') {
  throw new BadRequestException('El honor ya se encuentra pendiente de revision');
}
```

**New code (add explicit allowed-status check):**

```typescript
if (userHonor.validate === true || userHonor.validation_status === 'approved') {
  throw new BadRequestException('El honor ya se encuentra validado');
}

if (userHonor.validation_status === 'pending_review') {
  throw new BadRequestException('El honor ya se encuentra pendiente de revision');
}

// Allow submission from: in_progress, rejected
const allowedStatuses = ['in_progress', 'rejected'];
if (!allowedStatuses.includes(userHonor.validation_status)) {
  throw new BadRequestException(
    `El honor debe estar en estado in_progress o rejected para enviar a revision. Estado actual: ${userHonor.validation_status}`,
  );
}
```

---

### Task 4 — Update `HonorsService.startHonor()` to explicitly set `validation_status`

- [ ] Set `validation_status` on new enrollments and reactivations

**File:** `sacdia-backend/src/honors/honors.service.ts`

In `startHonor()`, update both the "reactivate" path (line ~254) and the "create new" path (line ~278).

**Reactivation path (line 252-261)** — add `validation_status`:

```typescript
const updated = await this.prisma.users_honors.update({
  where: { user_honor_id: existing.user_honor_id },
  data: {
    active: true,
    date: dto?.date ? new Date(dto.date) : new Date(),
    validate: false,
    validation_status: 'in_progress',
    certificate: '',
    images: [],
    document: null,
    submitted_at: null,
    validated_by_id: null,
    validated_at: null,
    rejection_reason: null,
    modified_at: new Date(),
  },
  // ... include stays the same
});
```

**Create path (line 278-287)** — add `validation_status`:

```typescript
const created = await this.prisma.users_honors.create({
  data: {
    user_id: userId,
    honor_id: honorId,
    date: dto?.date ? new Date(dto.date) : new Date(),
    validate: false,
    validation_status: 'in_progress',
    certificate: '',
    images: [],
    active: true,
  },
  // ... include stays the same
});
```

**Why:** Although the DB default is `'in_progress'`, being explicit prevents bugs if the default changes and makes the code self-documenting.

---

### Task 5 — Update `HonorsService.getUserHonorStats()` to return status breakdown

- [ ] Add per-status counts

**File:** `sacdia-backend/src/honors/honors.service.ts`

Replace `getUserHonorStats()` (lines 752-770):

```typescript
async getUserHonorStats(userId: string) {
  const where = { user_id: userId, active: true };

  const [total, approved, pendingReview, rejected, inProgress] =
    await Promise.all([
      this.prisma.users_honors.count({ where }),
      this.prisma.users_honors.count({
        where: { ...where, validation_status: 'approved' },
      }),
      this.prisma.users_honors.count({
        where: { ...where, validation_status: 'pending_review' },
      }),
      this.prisma.users_honors.count({
        where: { ...where, validation_status: 'rejected' },
      }),
      this.prisma.users_honors.count({
        where: { ...where, validation_status: 'in_progress' },
      }),
    ]);

  return {
    total,
    validated: approved, // backward compat
    in_progress: inProgress,
    pending_review: pendingReview,
    rejected,
    approved,
  };
}
```

Also update `getUserHonors()` (line ~207) to include the new fields in the response. The Prisma `findMany` already returns all columns, so no code change needed — but verify the `select` in `include.honors` doesn't accidentally exclude any fields.

---

### Phase 1 commit

```bash
git add sacdia-backend/prisma/schema.prisma sacdia-backend/prisma/migrations/ sacdia-backend/src/validation/validation.service.ts sacdia-backend/src/honors/honors.service.ts
git commit -m "feat: add honor validation tracking fields and update submit/review logic"
```

---

## Phase 2: Flutter Data Layer (3 tasks)

### Task 6 — Update `UserHonor` entity with new fields + computed helpers

- [ ] Rewrite entity with new fields

**File:** `sacdia-app/lib/features/honors/domain/entities/user_honor.dart`

```dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:sacdia_app/core/theme/app_colors.dart';

/// Entidad de especialidad de usuario del dominio.
///
/// Combina los datos del backend `users_honors` con helpers de display
/// para la UI de la app.
class UserHonor extends Equatable {
  final int id;
  final int honorId;
  final String userId;
  final bool active;
  final bool validate;
  final String validationStatus;
  final String certificate;
  final List<String> images;
  final String? document;
  final DateTime date;

  // Validation audit fields
  final DateTime? submittedAt;
  final String? validatedById;
  final DateTime? validatedAt;
  final String? rejectionReason;

  // Embedded honor details returned by GET /users/:userId/honors
  final String? honorName;
  final String? honorImageUrl;
  final String? honorCategoryName;
  final int? honorSkillLevel;

  const UserHonor({
    required this.id,
    required this.honorId,
    required this.userId,
    this.active = true,
    this.validate = false,
    this.validationStatus = 'in_progress',
    this.certificate = '',
    this.images = const [],
    this.document,
    required this.date,
    this.submittedAt,
    this.validatedById,
    this.validatedAt,
    this.rejectionReason,
    this.honorName,
    this.honorImageUrl,
    this.honorCategoryName,
    this.honorSkillLevel,
  });

  // ── Computed display helpers ─────────────────────────────────────────

  /// Display status combines backend validation_status with evidence presence.
  /// Backend stores: in_progress | pending_review | approved | rejected
  /// Display adds: inscripto (in_progress + no evidence) vs en_progreso (in_progress + evidence)
  String get displayStatus {
    if (validationStatus == 'approved') return 'validado';
    if (validationStatus == 'rejected') return 'rechazado';
    if (validationStatus == 'pending_review') return 'enviado';
    // in_progress: split by evidence presence
    if (images.isNotEmpty || (document != null && document!.isNotEmpty)) {
      return 'en_progreso';
    }
    return 'inscripto';
  }

  /// Color for the current display status (use for border-left, badges, headers).
  Color get statusColor {
    switch (displayStatus) {
      case 'validado':
        return AppColors.sacGreen;
      case 'enviado':
        return AppColors.sacYellow;
      case 'en_progreso':
      case 'rechazado':
        return AppColors.sacRed;
      case 'inscripto':
        return AppColors.sacBlue;
      default:
        return AppColors.sacGrey;
    }
  }

  /// Human-readable label for the current display status.
  String get statusLabel {
    switch (displayStatus) {
      case 'validado':
        return 'Validada';
      case 'enviado':
        return 'Enviada — en revision';
      case 'en_progreso':
        return 'En progreso';
      case 'rechazado':
        return 'Rechazada';
      case 'inscripto':
        return 'Inscripta — sin evidencia';
      default:
        return 'Disponible';
    }
  }

  /// Whether the honor has been fully validated/completed.
  bool get isCompleted => validationStatus == 'approved';

  /// Whether the user can submit (or resubmit) for review.
  bool get canSubmit =>
      validationStatus == 'in_progress' || validationStatus == 'rejected';

  /// Whether the honor is currently under review (read-only for member).
  bool get isUnderReview => validationStatus == 'pending_review';

  /// Whether there is evidence uploaded.
  bool get hasEvidence =>
      images.isNotEmpty || (document != null && document!.isNotEmpty);

  /// Total evidence file count.
  int get evidenceCount {
    int count = images.length;
    if (document != null && document!.isNotEmpty) count++;
    return count;
  }

  @override
  List<Object?> get props => [
        id,
        honorId,
        userId,
        active,
        validate,
        validationStatus,
        certificate,
        images,
        document,
        date,
        submittedAt,
        validatedById,
        validatedAt,
        rejectionReason,
        honorName,
        honorImageUrl,
        honorCategoryName,
        honorSkillLevel,
      ];
}
```

---

### Task 7 — Update `UserHonorModel` to parse new JSON fields

- [ ] Rewrite model with new field parsing

**File:** `sacdia-app/lib/features/honors/data/models/user_honor_model.dart`

```dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/user_honor.dart';

const String _honorImagesBase =
    'https://sacdia-files.s3.us-east-1.amazonaws.com/Especialidades/';

String? _buildImageUrl(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  if (raw.startsWith('http')) return raw;
  return '$_honorImagesBase$raw';
}

/// Modelo de especialidad de usuario para la capa de datos
class UserHonorModel extends Equatable {
  final int id;
  final int honorId;
  final String userId;
  final bool active;
  final bool validate;
  final String validationStatus;
  final String certificate;
  final List<String> images;
  final String? document;
  final DateTime date;

  // Validation audit fields
  final DateTime? submittedAt;
  final String? validatedById;
  final DateTime? validatedAt;
  final String? rejectionReason;

  // Embedded honor details
  final String? honorName;
  final String? honorImageUrl;
  final String? honorCategoryName;
  final int? honorSkillLevel;

  const UserHonorModel({
    required this.id,
    required this.honorId,
    required this.userId,
    this.active = true,
    this.validate = false,
    this.validationStatus = 'in_progress',
    this.certificate = '',
    this.images = const [],
    this.document,
    required this.date,
    this.submittedAt,
    this.validatedById,
    this.validatedAt,
    this.rejectionReason,
    this.honorName,
    this.honorImageUrl,
    this.honorCategoryName,
    this.honorSkillLevel,
  });

  /// Crea una instancia desde JSON
  factory UserHonorModel.fromJson(Map<String, dynamic> json) {
    // PK is 'user_honor_id'; 'id' as fallback
    final id = (json['user_honor_id'] ?? json['id']) as int;

    // Parse images — stored as JSON array of strings
    List<String> images = const [];
    final rawImages = json['images'];
    if (rawImages is List) {
      images = rawImages.map((e) => e.toString()).toList();
    }

    // Date field: 'date' is the honor date, 'created_at' as fallback
    final dateRaw = json['date'] as String? ?? json['created_at'] as String?;
    final date = dateRaw != null
        ? DateTime.tryParse(dateRaw) ?? DateTime.now()
        : DateTime.now();

    // Parse nullable timestamps
    DateTime? submittedAt;
    final rawSubmittedAt = json['submitted_at'] as String?;
    if (rawSubmittedAt != null) {
      submittedAt = DateTime.tryParse(rawSubmittedAt);
    }

    DateTime? validatedAt;
    final rawValidatedAt = json['validated_at'] as String?;
    if (rawValidatedAt != null) {
      validatedAt = DateTime.tryParse(rawValidatedAt);
    }

    // Parse nested honor details returned by GET /users/:userId/honors.
    String? honorName;
    String? honorImageUrl;
    String? honorCategoryName;
    int? honorSkillLevel;
    final nestedHonor = json['honors'] as Map<String, dynamic>?;
    if (nestedHonor != null) {
      honorName = nestedHonor['name'] as String?;
      honorImageUrl = _buildImageUrl(nestedHonor['honor_image'] as String?);
      honorSkillLevel = nestedHonor['skill_level'] as int?;
      final nestedCategory =
          nestedHonor['honors_categories'] as Map<String, dynamic>?;
      honorCategoryName = nestedCategory?['name'] as String?;
    }

    return UserHonorModel(
      id: id,
      honorId: json['honor_id'] as int,
      userId: json['user_id'] as String,
      active: (json['active'] as bool?) ?? true,
      validate: (json['validate'] as bool?) ?? false,
      validationStatus:
          (json['validation_status'] as String?) ?? 'in_progress',
      certificate: (json['certificate'] as String?) ?? '',
      images: images,
      document: json['document'] as String?,
      date: date,
      submittedAt: submittedAt,
      validatedById: json['validated_by_id'] as String?,
      validatedAt: validatedAt,
      rejectionReason: json['rejection_reason'] as String?,
      honorName: honorName,
      honorImageUrl: honorImageUrl,
      honorCategoryName: honorCategoryName,
      honorSkillLevel: honorSkillLevel,
    );
  }

  /// Convierte la instancia a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'honor_id': honorId,
      'user_id': userId,
      'active': active,
      'validate': validate,
      'validation_status': validationStatus,
      'certificate': certificate,
      'images': images,
      'document': document,
      'date': date.toIso8601String(),
      'submitted_at': submittedAt?.toIso8601String(),
      'validated_by_id': validatedById,
      'validated_at': validatedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
    };
  }

  /// Convierte el modelo a entidad de dominio
  UserHonor toEntity() {
    return UserHonor(
      id: id,
      honorId: honorId,
      userId: userId,
      active: active,
      validate: validate,
      validationStatus: validationStatus,
      certificate: certificate,
      images: images,
      document: document,
      date: date,
      submittedAt: submittedAt,
      validatedById: validatedById,
      validatedAt: validatedAt,
      rejectionReason: rejectionReason,
      honorName: honorName,
      honorImageUrl: honorImageUrl,
      honorCategoryName: honorCategoryName,
      honorSkillLevel: honorSkillLevel,
    );
  }

  /// Crea una copia con campos actualizados
  UserHonorModel copyWith({
    int? id,
    int? honorId,
    String? userId,
    bool? active,
    bool? validate,
    String? validationStatus,
    String? certificate,
    List<String>? images,
    String? document,
    DateTime? date,
    DateTime? submittedAt,
    String? validatedById,
    DateTime? validatedAt,
    String? rejectionReason,
    String? honorName,
    String? honorImageUrl,
    String? honorCategoryName,
    int? honorSkillLevel,
  }) {
    return UserHonorModel(
      id: id ?? this.id,
      honorId: honorId ?? this.honorId,
      userId: userId ?? this.userId,
      active: active ?? this.active,
      validate: validate ?? this.validate,
      validationStatus: validationStatus ?? this.validationStatus,
      certificate: certificate ?? this.certificate,
      images: images ?? this.images,
      document: document ?? this.document,
      date: date ?? this.date,
      submittedAt: submittedAt ?? this.submittedAt,
      validatedById: validatedById ?? this.validatedById,
      validatedAt: validatedAt ?? this.validatedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      honorName: honorName ?? this.honorName,
      honorImageUrl: honorImageUrl ?? this.honorImageUrl,
      honorCategoryName: honorCategoryName ?? this.honorCategoryName,
      honorSkillLevel: honorSkillLevel ?? this.honorSkillLevel,
    );
  }

  @override
  List<Object?> get props => [
        id,
        honorId,
        userId,
        active,
        validate,
        validationStatus,
        certificate,
        images,
        document,
        date,
        submittedAt,
        validatedById,
        validatedAt,
        rejectionReason,
        honorName,
        honorImageUrl,
        honorCategoryName,
        honorSkillLevel,
      ];
}
```

---

### Task 8 — Add new providers for search, category filtering, and status-aware honors

- [ ] Add providers to `honors_providers.dart`

**File:** `sacdia-app/lib/features/honors/presentation/providers/honors_providers.dart`

Add the following providers AFTER the existing `userHonorForHonorProvider` (line ~258):

```dart
// ── Search & filter providers ─────────────────────────────────────────────

/// Search query for the catalog view. Debounce is handled in the UI.
final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Currently selected category ID for catalog filtering. null = "Todas".
final selectedCategoryProvider = StateProvider.autoDispose<int?>((ref) => null);

/// All honors filtered by search query and selected category.
/// Used by the redesigned honors_catalog_view.
final filteredHonorsProvider =
    FutureProvider.autoDispose<List<Honor>>((ref) async {
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final categoryId = ref.watch(selectedCategoryProvider);

  // Fetch all honors (no filter params = get all)
  final getHonors = ref.read(getHonorsProvider);
  final result = await getHonors(GetHonorsParams(categoryId: categoryId));

  return result.fold(
    (failure) => throw Exception(failure.message),
    (honors) {
      if (query.length < 2) return honors;
      return honors
          .where((h) => h.name.toLowerCase().contains(query))
          .toList();
    },
  );
});

/// Combines catalog honors with user honors to determine display status.
/// Returns a list of tuples: (Honor, UserHonor?) for rendering cards.
final honorsWithStatusProvider =
    FutureProvider.autoDispose<List<({Honor honor, UserHonor? userHonor})>>(
        (ref) async {
  final honorsAsync = await ref.watch(filteredHonorsProvider.future);
  final userHonorsAsync = ref.watch(userHonorsProvider);

  final userHonors = userHonorsAsync.maybeWhen(
    data: (list) => list,
    orElse: () => <UserHonor>[],
  );

  return honorsAsync.map((honor) {
    final uh = userHonors.cast<UserHonor?>().firstWhere(
          (u) => u!.honorId == honor.id,
          orElse: () => null,
        );
    return (honor: honor, userHonor: uh);
  }).toList();
});
```

**Also update** `getUserHonors` include in `HonorsService` to also select `skill_level` so `honorSkillLevel` is available. Check the existing `select` in `getUserHonors()` (line ~216):

```typescript
honors: {
  select: {
    honor_id: true,
    name: true,
    honor_image: true,
    skill_level: true, // Already present - good
    honors_categories: { select: { name: true, icon: true } },
  },
},
```

This already selects `skill_level` — no backend change needed for this.

---

### Phase 2 commit

```bash
git add sacdia-app/lib/features/honors/domain/entities/user_honor.dart sacdia-app/lib/features/honors/data/models/user_honor_model.dart sacdia-app/lib/features/honors/presentation/providers/honors_providers.dart
git commit -m "feat: update honors data layer with validation status fields and catalog providers"
```

---

## Phase 3: Flutter Presentation (9 tasks)

> **Visual reference:** Open `.superpowers/brainstorm/honors-redesign-mockup-v3.html` in a browser for the exact layout, colors, and spacing.

### Task 9 — Create `honor_category_chip.dart` widget

- [ ] Create new chip widget file

**File:** `sacdia-app/lib/features/honors/presentation/widgets/honor_category_chip.dart`

```dart
import 'package:flutter/material.dart';
import 'package:sacdia_app/core/theme/app_colors.dart';

/// Horizontal category filter chip for the honors catalog.
///
/// Active state: solid sacBlue background with white text.
/// Inactive state: #F4F6F7 background with #64748B text.
/// No icons, no emojis — text only per design spec.
class HonorCategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const HonorCategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.sacBlue
              : const Color(0xFFF4F6F7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
```

---

### Task 10 — Redesign `honor_card.dart` — unified card with border-left states

- [ ] Rewrite honor card widget

**File:** `sacdia-app/lib/features/honors/presentation/widgets/honor_card.dart`

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sacdia_app/core/theme/app_colors.dart';

import '../../domain/entities/honor.dart';
import '../../domain/entities/user_honor.dart';

/// Unified honor card for both catalog and my-honors views.
///
/// Renders all 6 states:
/// - Available (not enrolled): no border-left, chevron-right
/// - Inscripto: blue border-left, "Inscripta — sin evidencia"
/// - En progreso: red border-left, "En progreso"
/// - Enviado: yellow border-left, "Enviada — en revision"
/// - Validado: green border-left, gold star badge
/// - Rechazado: red border-left, "Rechazada"
class HonorCard extends StatelessWidget {
  final Honor honor;
  final UserHonor? userHonor;
  final VoidCallback onTap;

  const HonorCard({
    super.key,
    required this.honor,
    this.userHonor,
    required this.onTap,
  });

  bool get _isEnrolled => userHonor != null;
  bool get _isCompleted => userHonor?.isCompleted ?? false;
  String? get _displayStatus => userHonor?.displayStatus;
  Color? get _statusColor => userHonor?.statusColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: const Color(0xFFFAFBFB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // Border-left indicator
                  if (_isEnrolled)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 3,
                        color: _statusColor,
                      ),
                    ),

                  // Card content
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      _isEnrolled ? 15 : 12, // Extra left padding for border
                      12,
                      12,
                      12,
                    ),
                    child: Row(
                      children: [
                        // Icon area: 44x44
                        _buildIconArea(),
                        const SizedBox(width: 12),

                        // Text area
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                honor.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.sacBlack,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_isEnrolled && _displayStatus != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  userHonor!.statusLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _statusColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Trailing: gold star badge (validado) or chevron (available)
                        _buildTrailing(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconArea() {
    if (_isCompleted) {
      // Validado: solid green with white checkmark
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.sacGreen,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 24,
        ),
      );
    }

    // Enrolled states: light tinted background with honor image
    // Available: #F0F4F5 background with honor image
    final bgColor = _isEnrolled
        ? _statusColor!.withAlpha(25)
        : const Color(0xFFF0F4F5);

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: honor.imageUrl != null && honor.imageUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: honor.imageUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Icon(
                  Icons.emoji_events_outlined,
                  color: _statusColor ?? AppColors.sacGrey,
                  size: 22,
                ),
              ),
            )
          : Icon(
              Icons.emoji_events_outlined,
              color: _statusColor ?? AppColors.sacGrey,
              size: 22,
            ),
    );
  }

  Widget _buildTrailing() {
    if (_isCompleted) {
      // Gold star badge
      return Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: AppColors.sacYellow,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.star_rounded,
          color: Colors.white,
          size: 16,
        ),
      );
    }

    if (_isEnrolled) {
      // Status label is already shown — just show a subtle text
      return const SizedBox.shrink();
    }

    // Available: chevron
    return const Icon(
      Icons.chevron_right_rounded,
      color: AppColors.sacGrey,
      size: 24,
    );
  }
}
```

---

### Task 11 — Redesign `honors_catalog_view.dart` — dark header, search, chips, card list

- [ ] Rewrite catalog view

**File:** `sacdia-app/lib/features/honors/presentation/views/honors_catalog_view.dart`

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sacdia_app/core/config/route_names.dart';
import 'package:sacdia_app/core/theme/app_colors.dart';
import 'package:sacdia_app/core/widgets/sac_loading.dart';

import '../../domain/entities/honor.dart';
import '../../domain/entities/user_honor.dart';
import '../providers/honors_providers.dart';
import '../widgets/honor_card.dart';
import '../widgets/honor_category_chip.dart';

/// Redesigned honors catalog view.
///
/// Layout:
/// - Dark header (#183651) with title + completed/total badge + search bar
/// - Horizontal category chips row ("Todas" default)
/// - Vertical list of HonorCard (border-left state indicators)
class HonorsCatalogView extends ConsumerStatefulWidget {
  const HonorsCatalogView({super.key});

  @override
  ConsumerState<HonorsCatalogView> createState() => _HonorsCatalogViewState();
}

class _HonorsCatalogViewState extends ConsumerState<HonorsCatalogView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchQueryProvider.notifier).state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(honorCategoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final honorsWithStatus = ref.watch(honorsWithStatusProvider);
    final statsAsync = ref.watch(userHonorStatsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Dark header ──────────────────────────────────────────
          _buildHeader(context, statsAsync),

          // ── Category chips ───────────────────────────────────────
          categoriesAsync.when(
            data: (categories) => _buildCategoryChips(
              categories,
              selectedCategory,
            ),
            loading: () => const SizedBox(height: 52),
            error: (_, __) => const SizedBox(height: 52),
          ),

          // ── Honor cards list ─────────────────────────────────────
          Expanded(
            child: honorsWithStatus.when(
              data: (items) => _buildHonorsList(items),
              loading: () => const Center(child: SacLoading()),
              error: (error, _) => _buildErrorState(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AsyncValue<Map<String, dynamic>> statsAsync,
  ) {
    final completed = statsAsync.maybeWhen(
      data: (s) => s['validated'] as int? ?? 0,
      orElse: () => 0,
    );
    final total = statsAsync.maybeWhen(
      data: (s) => s['total'] as int? ?? 0,
      orElse: () => 0,
    );

    return Container(
      color: AppColors.sacBlack,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Especialidades',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  // Completed/total badge pill
                  if (total > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$completed',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.sacGreen,
                              ),
                            ),
                            TextSpan(
                              text: '/$total',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withAlpha(180),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Search bar
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Buscar especialidad...',
                  hintStyle: TextStyle(
                    color: Colors.white.withAlpha(120),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.white.withAlpha(120),
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: Colors.white.withAlpha(120),
                            size: 18,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(searchQueryProvider.notifier).state = '';
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white.withAlpha(20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(
    List<dynamic> categories,
    int? selectedCategory,
  ) {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categories.length + 1, // +1 for "Todas"
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: HonorCategoryChip(
                label: 'Todas',
                isSelected: selectedCategory == null,
                onTap: () {
                  ref.read(selectedCategoryProvider.notifier).state = null;
                },
              ),
            );
          }

          final category = categories[index - 1];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: HonorCategoryChip(
              label: category.name,
              isSelected: selectedCategory == category.id,
              onTap: () {
                final current = ref.read(selectedCategoryProvider);
                ref.read(selectedCategoryProvider.notifier).state =
                    current == category.id ? null : category.id;
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHonorsList(
    List<({Honor honor, UserHonor? userHonor})> items,
  ) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedAward01,
              size: 56,
              color: AppColors.sacGrey,
            ),
            const SizedBox(height: 12),
            const Text(
              'No hay especialidades en esta categoria',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.sacBlue,
      onRefresh: () async {
        ref.invalidate(filteredHonorsProvider);
        ref.invalidate(userHonorsProvider);
        ref.invalidate(userHonorStatsProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return HonorCard(
            honor: item.honor,
            userHonor: item.userHonor,
            onTap: () {
              context.push(
                RouteNames.honorDetailPath(item.honor.id.toString()),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedAlert02,
            size: 56,
            color: AppColors.sacRed,
          ),
          const SizedBox(height: 16),
          const Text(
            'Error al cargar especialidades',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              ref.invalidate(filteredHonorsProvider);
              ref.invalidate(userHonorsProvider);
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Reintentar'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.sacBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### Task 12 — Redesign `honor_detail_view.dart` — compact header, material card, CTA

- [ ] Rewrite detail view

**File:** `sacdia-app/lib/features/honors/presentation/views/honor_detail_view.dart`

This view handles two scenarios:
1. **Not enrolled:** Show description + material PDF + "Inscribirme" CTA
2. **Enrolled (any status):** Navigate directly to evidence view

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sacdia_app/core/config/route_names.dart';
import 'package:sacdia_app/core/theme/app_colors.dart';
import 'package:sacdia_app/core/widgets/sac_loading.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/honor.dart';
import '../../domain/entities/user_honor.dart';
import '../../domain/usecases/get_honors.dart';
import '../providers/honors_providers.dart';

// ── Label helpers ─────────────────────────────────────────────────────────────

String _skillLevelLabel(int level) {
  switch (level) {
    case 1:
      return 'Basico';
    case 2:
      return 'Intermedio';
    case 3:
      return 'Avanzado';
    default:
      return 'Nivel $level';
  }
}

// ── Main View ─────────────────────────────────────────────────────────────────

/// Honor detail view.
///
/// If the user is already enrolled, redirects to the evidence view.
/// Otherwise shows honor info + "Inscribirme" CTA.
class HonorDetailView extends ConsumerWidget {
  final int honorId;
  final Honor? initialHonor;

  const HonorDetailView({
    super.key,
    required this.honorId,
    this.initialHonor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (initialHonor != null) {
      return _HonorDetailBody(honor: initialHonor!, honorId: honorId);
    }

    final honorAsync = ref.watch(honorsProvider(const GetHonorsParams()));
    return honorAsync.when(
      data: (honors) {
        try {
          final honor = honors.firstWhere((h) => h.id == honorId);
          return _HonorDetailBody(honor: honor, honorId: honorId);
        } catch (_) {
          return Scaffold(
            appBar: AppBar(backgroundColor: AppColors.sacBlack),
            body: const Center(child: Text('Especialidad no encontrada')),
          );
        }
      },
      loading: () => const Scaffold(body: Center(child: SacLoading())),
      error: (_, __) => Scaffold(
        appBar: AppBar(backgroundColor: AppColors.sacBlack),
        body: const Center(child: Text('Error al cargar')),
      ),
    );
  }
}

class _HonorDetailBody extends ConsumerWidget {
  final Honor honor;
  final int honorId;

  const _HonorDetailBody({required this.honor, required this.honorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userHonorAsync = ref.watch(userHonorForHonorProvider(honorId));

    return userHonorAsync.when(
      data: (userHonor) {
        // If enrolled, navigate to evidence view
        if (userHonor != null) {
          // Use addPostFrameCallback to avoid navigating during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.pushReplacement(
                RouteNames.honorEvidencePath(
                  honorId.toString(),
                  userHonor.id.toString(),
                ),
              );
            }
          });
          return const Scaffold(body: Center(child: SacLoading()));
        }
        return _NotEnrolledView(honor: honor);
      },
      loading: () => const Scaffold(body: Center(child: SacLoading())),
      error: (_, __) => _NotEnrolledView(honor: honor),
    );
  }
}

class _NotEnrolledView extends ConsumerWidget {
  final Honor honor;

  const _NotEnrolledView({required this.honor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollmentState = ref.watch(honorEnrollmentNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.sacBlack,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.sacBlack,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Honor icon
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(20),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: honor.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: CachedNetworkImage(
                                    imageUrl: honor.imageUrl!,
                                    fit: BoxFit.contain,
                                    errorWidget: (_, __, ___) =>
                                        const Icon(
                                      Icons.emoji_events_outlined,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.emoji_events_outlined,
                                  color: Colors.white,
                                  size: 32,
                                ),
                        ),
                        const SizedBox(height: 10),
                        // Honor name
                        Text(
                          honor.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Badge pills
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (honor.skillLevel != null)
                              _Pill(
                                label: _skillLevelLabel(honor.skillLevel!),
                                color: AppColors.sacGreen,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Body ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  if (honor.description != null &&
                      honor.description!.isNotEmpty) ...[
                    Text(
                      honor.description!,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.7,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Material PDF card
                  if (honor.materialUrl != null &&
                      honor.materialUrl!.isNotEmpty) ...[
                    _MaterialDownloadCard(materialUrl: honor.materialUrl!),
                    const SizedBox(height: 28),
                  ],

                  // "How it works" section
                  _HowItWorksSection(),
                  const SizedBox(height: 28),

                  // CTA: Inscribirme
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: enrollmentState.isLoading
                          ? null
                          : () => _enroll(context, ref),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.sacGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: enrollmentState.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Inscribirme'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _enroll(BuildContext context, WidgetRef ref) async {
    final authState = ref.read(authNotifierProvider);
    final userId = authState.value?.id;
    if (userId == null) return;

    await ref
        .read(honorEnrollmentNotifierProvider.notifier)
        .enrollInHonor(userId, honor.id);

    if (context.mounted) {
      // Refresh user honors and navigate
      ref.invalidate(userHonorsProvider);
      ref.invalidate(userHonorStatsProvider);
      ref.invalidate(userHonorForHonorProvider(honor.id));
    }
  }
}

// ── Subwidgets ───────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _MaterialDownloadCard extends StatelessWidget {
  final String materialUrl;

  const _MaterialDownloadCard({required this.materialUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.tryParse(materialUrl);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F8FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.sacBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Material de estudio',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.sacBlack,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Descargar PDF',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.download_rounded,
              color: AppColors.sacBlue,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const steps = [
      ('1', 'Descarga el material de estudio'),
      ('2', 'Completa las actividades con tu instructor'),
      ('3', 'Subi la evidencia firmada (fotos o PDF)'),
      ('4', 'Envia a revision y espera la validacion'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Como funciona',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.sacBlack,
          ),
        ),
        const SizedBox(height: 12),
        ...steps.map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.sacBlue.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        step.$1,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.sacBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      step.$2,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
```

**Important note for implementer:** The `_HonorDetailBody` redirects enrolled users to the evidence view. This requires the route `RouteNames.honorEvidencePath` to exist (see Task 16). If implementing in order, create a placeholder route first or implement Task 16 before this redirect logic.

---

### Task 13 — Create `honor_evidence_view.dart` — evidence upload, status messages, submit (LARGEST new file)

- [ ] Create new evidence view

**File:** `sacdia-app/lib/features/honors/presentation/views/honor_evidence_view.dart`

This is the main working screen after enrollment. It integrates with the existing `features/validation/` submit infrastructure.

```dart
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sacdia_app/core/config/route_names.dart';
import 'package:sacdia_app/core/theme/app_colors.dart';
import 'package:sacdia_app/core/widgets/sac_loading.dart';

import '../../../validation/domain/entities/validation.dart';
import '../../../validation/presentation/providers/validation_providers.dart';
import '../../domain/entities/honor.dart';
import '../../domain/entities/user_honor.dart';
import '../../domain/usecases/get_honors.dart';
import '../providers/honors_providers.dart';

/// Evidence & progress screen for an enrolled honor.
///
/// Header color adapts to validation status.
/// Shows: status card, material download, evidence grid, action buttons.
///
/// Integration with validation feature:
/// - Uses `SubmitValidationNotifier` from `features/validation/` for submit
/// - Uses `ValidationEntityType.honor` as entity type
/// - entity_id is the `user_honor_id` (NOT honor_id)
class HonorEvidenceView extends ConsumerStatefulWidget {
  final int honorId;
  final int userHonorId;

  const HonorEvidenceView({
    super.key,
    required this.honorId,
    required this.userHonorId,
  });

  @override
  ConsumerState<HonorEvidenceView> createState() => _HonorEvidenceViewState();
}

class _HonorEvidenceViewState extends ConsumerState<HonorEvidenceView> {
  static const int _maxFiles = 10;
  static const int _maxFileSizeBytes = 10 * 1024 * 1024; // 10MB

  @override
  Widget build(BuildContext context) {
    // Watch the user honor for this specific honor
    final userHonorAsync =
        ref.watch(userHonorForHonorProvider(widget.honorId));
    final honorsAsync = ref.watch(honorsProvider(const GetHonorsParams()));

    return userHonorAsync.when(
      data: (userHonor) {
        if (userHonor == null) {
          return const Scaffold(
            body: Center(child: Text('Honor no encontrado')),
          );
        }

        // Find the honor catalog entry for metadata
        final honor = honorsAsync.maybeWhen(
          data: (honors) {
            try {
              return honors.firstWhere((h) => h.id == widget.honorId);
            } catch (_) {
              return null;
            }
          },
          orElse: () => null,
        );

        return _EvidenceBody(
          userHonor: userHonor,
          honor: honor,
          onSubmit: () => _submitForReview(userHonor),
          onAddEvidence: _showFilePickerOptions,
        );
      },
      loading: () => const Scaffold(body: Center(child: SacLoading())),
      error: (_, __) => Scaffold(
        appBar: AppBar(backgroundColor: AppColors.sacRed),
        body: const Center(child: Text('Error al cargar')),
      ),
    );
  }

  Future<void> _submitForReview(UserHonor userHonor) async {
    final success = await ref.read(submitValidationProvider.notifier).submit(
          entityType: ValidationEntityType.honor,
          entityId: userHonor.id, // user_honor_id
        );

    if (success && mounted) {
      // Refresh user honors to reflect new status
      ref.invalidate(userHonorsProvider);
      ref.invalidate(userHonorForHonorProvider(widget.honorId));
      ref.invalidate(userHonorStatsProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enviada a revision'),
          backgroundColor: AppColors.sacGreen,
        ),
      );
    }
  }

  void _showFilePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.sacGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: AppColors.sacBlue),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: AppColors.sacGreen),
              title: const Text('Elegir de galeria'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_rounded,
                  color: AppColors.sacRed),
              title: const Text('Seleccionar PDF'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPdf();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (image != null) {
      await _uploadFile(File(image.path), image.name);
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    for (final image in images) {
      await _uploadFile(File(image.path), image.name);
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );
    if (result != null) {
      for (final file in result.files) {
        if (file.path != null) {
          await _uploadFile(File(file.path!), file.name);
        }
      }
    }
  }

  Future<void> _uploadFile(File file, String fileName) async {
    final fileSize = await file.length();
    if (fileSize > _maxFileSizeBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$fileName excede el limite de 10MB'),
            backgroundColor: AppColors.sacRed,
          ),
        );
      }
      return;
    }

    // TODO: Upload file via HonorsService.updateUserHonor()
    // This will be connected to the existing file upload infrastructure
    // using StorageBucketAlias.EVIDENCE_FILES and the backend
    // PATCH /users/:userId/honors/:honorId endpoint.
    // After upload, invalidate providers to refresh evidence list.
  }
}

// ── Evidence Body ────────────────────────────────────────────────────────────

class _EvidenceBody extends StatelessWidget {
  final UserHonor userHonor;
  final Honor? honor;
  final VoidCallback onSubmit;
  final VoidCallback onAddEvidence;

  const _EvidenceBody({
    required this.userHonor,
    this.honor,
    required this.onSubmit,
    required this.onAddEvidence,
  });

  Color get _headerColor => userHonor.statusColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: _headerColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: _headerColor,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                    child: Row(
                      children: [
                        // Honor icon
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: honor?.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: honor!.imageUrl!,
                                    fit: BoxFit.contain,
                                    errorWidget: (_, __, ___) =>
                                        const Icon(
                                      Icons.emoji_events_outlined,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.emoji_events_outlined,
                                  color: Colors.white,
                                  size: 28,
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                honor?.name ??
                                    userHonor.honorName ??
                                    'Especialidad',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              // Status badge pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(40),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  userHonor.statusLabel,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status card
                  _StatusMessageCard(userHonor: userHonor),
                  const SizedBox(height: 20),

                  // Material download (always visible)
                  if (honor?.materialUrl != null &&
                      honor!.materialUrl!.isNotEmpty) ...[
                    _MaterialCard(materialUrl: honor!.materialUrl!),
                    const SizedBox(height: 20),
                  ],

                  // Evidence section
                  _EvidenceSection(
                    userHonor: userHonor,
                    onAddEvidence: onAddEvidence,
                  ),
                  const SizedBox(height: 24),

                  // Action buttons
                  _ActionButtons(
                    userHonor: userHonor,
                    onSubmit: onSubmit,
                    onAddEvidence: onAddEvidence,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status Message Card ──────────────────────────────────────────────────────

class _StatusMessageCard extends StatelessWidget {
  final UserHonor userHonor;

  const _StatusMessageCard({required this.userHonor});

  (IconData, String) get _statusContent {
    switch (userHonor.displayStatus) {
      case 'inscripto':
        return (
          Icons.info_outline_rounded,
          'Descarga el material, completa las actividades con tu instructor y subi la evidencia',
        );
      case 'en_progreso':
        return (
          Icons.upload_file_rounded,
          'Tenes evidencia cargada. Cuando estes listo, enviala a revision',
        );
      case 'enviado':
        return (
          Icons.hourglass_top_rounded,
          'Tu evidencia fue enviada. Un coordinador la revisara pronto',
        );
      case 'validado':
        return (
          Icons.check_circle_outline_rounded,
          'Especialidad completada!',
        );
      case 'rechazado':
        return (
          Icons.error_outline_rounded,
          'Tu evidencia fue rechazada: ${userHonor.rejectionReason ?? "Sin motivo especificado"}. Podes corregir y reenviar',
        );
      default:
        return (Icons.info_outline_rounded, '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, message) = _statusContent;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: userHonor.statusColor.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: userHonor.statusColor.withAlpha(40),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: userHonor.statusColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: userHonor.statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Material Card ────────────────────────────────────────────────────────────

class _MaterialCard extends StatelessWidget {
  final String materialUrl;

  const _MaterialCard({required this.materialUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.tryParse(materialUrl);
        if (uri != null) {
          // Use url_launcher
          // await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F8FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.sacBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Material de estudio',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.sacBlack,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Descargar PDF',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            Icon(Icons.download_rounded, color: AppColors.sacBlue, size: 22),
          ],
        ),
      ),
    );
  }
}

// ── Evidence Section ─────────────────────────────────────────────────────────

class _EvidenceSection extends StatelessWidget {
  final UserHonor userHonor;
  final VoidCallback onAddEvidence;

  const _EvidenceSection({
    required this.userHonor,
    required this.onAddEvidence,
  });

  @override
  Widget build(BuildContext context) {
    final canEdit = userHonor.canSubmit; // in_progress or rejected

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Evidencia',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.sacBlack,
              ),
            ),
            Text(
              '${userHonor.evidenceCount}/10',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Evidence grid: 3 columns
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: userHonor.images.length +
              (canEdit && userHonor.evidenceCount < 10 ? 1 : 0),
          itemBuilder: (context, index) {
            // Last cell: add button
            if (index == userHonor.images.length && canEdit) {
              return _AddEvidenceCell(onTap: onAddEvidence);
            }

            // Evidence file thumbnail
            final imageUrl = userHonor.images[index];
            return _EvidenceThumbnail(
              imageUrl: imageUrl,
              canDelete: canEdit,
              onDelete: () {
                // TODO: Implement delete with confirmation dialog
              },
              onTap: () {
                // TODO: Open fullscreen viewer (SacImageViewer for images)
              },
            );
          },
        ),
      ],
    );
  }
}

class _AddEvidenceCell extends StatelessWidget {
  final VoidCallback onTap;

  const _AddEvidenceCell({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.sacGrey,
            width: 1.5,
            // Dashed effect via dash pattern is complex in Flutter.
            // Using a solid subtle border as an approximation.
          ),
        ),
        child: Center(
          child: Icon(
            Icons.add_rounded,
            color: AppColors.sacGrey,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _EvidenceThumbnail extends StatelessWidget {
  final String imageUrl;
  final bool canDelete;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _EvidenceThumbnail({
    required this.imageUrl,
    required this.canDelete,
    required this.onDelete,
    required this.onTap,
  });

  bool get _isPdf =>
      imageUrl.toLowerCase().endsWith('.pdf') ||
      imageUrl.toLowerCase().contains('pdf');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: canDelete
          ? () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Eliminar evidencia'),
                  content: const Text(
                    'Estas seguro de que queres eliminar esta evidencia?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onDelete();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.sacRed,
                      ),
                      child: const Text('Eliminar'),
                    ),
                  ],
                ),
              );
            }
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: _isPdf
            ? Container(
                color: const Color(0xFFFFF0F0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: AppColors.sacRed,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PDF',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.sacRed,
                      ),
                    ),
                  ],
                ),
              )
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: const Color(0xFFF0F4F5),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: const Color(0xFFF0F4F5),
                  child: const Icon(
                    Icons.broken_image_rounded,
                    color: AppColors.sacGrey,
                    size: 24,
                  ),
                ),
              ),
      ),
    );
  }
}

// ── Action Buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends ConsumerWidget {
  final UserHonor userHonor;
  final VoidCallback onSubmit;
  final VoidCallback onAddEvidence;

  const _ActionButtons({
    required this.userHonor,
    required this.onSubmit,
    required this.onAddEvidence,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submitState = ref.watch(submitValidationProvider);

    switch (userHonor.displayStatus) {
      case 'inscripto':
        // No evidence yet: "Subir evidencia"
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onAddEvidence,
            icon: const Icon(Icons.upload_rounded, size: 18),
            label: const Text('Subir evidencia'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.sacBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );

      case 'en_progreso':
        // Has evidence: "Enviar a revision" + "Subir mas"
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: submitState.isLoading ? null : onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.sacGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: submitState.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Enviar a revision'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAddEvidence,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Subir mas'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.sacBlue,
                  side: const BorderSide(color: AppColors.sacBlue),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );

      case 'enviado':
        // Waiting for review: no action buttons
        return const SizedBox.shrink();

      case 'validado':
        // Completed: "Ver insignia"
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              context.push(
                RouteNames.honorCompletionPath(
                  userHonor.honorId.toString(),
                  userHonor.id.toString(),
                ),
              );
            },
            icon: const Icon(Icons.emoji_events_rounded, size: 18),
            label: const Text('Ver insignia'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.sacGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );

      case 'rechazado':
        // Rejected: "Corregir y reenviar"
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onAddEvidence,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.sacGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Corregir y reenviar'),
              ),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
```

**Integration with existing `features/validation/`:**

The evidence view uses `SubmitValidationNotifier` from `sacdia-app/lib/features/validation/presentation/providers/validation_providers.dart` to submit for review. The key integration points are:

1. Import `ValidationEntityType.honor` from `features/validation/domain/entities/validation.dart`
2. Import `submitValidationProvider` from `features/validation/presentation/providers/validation_providers.dart`
3. Call `ref.read(submitValidationProvider.notifier).submit(entityType: ValidationEntityType.honor, entityId: userHonor.id)` — where `userHonor.id` is the `user_honor_id` (NOT the `honor_id`)
4. The data source at `features/validation/data/datasources/validation_remote_data_source.dart` already calls `POST /validation/submit` with `{ entity_type: 'honor', entity_id: <user_honor_id> }`

---

### Task 14 — Create `honor_completion_view.dart` — celebration screen

- [ ] Create celebration view

**File:** `sacdia-app/lib/features/honors/presentation/views/honor_completion_view.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:sacdia_app/core/theme/app_colors.dart';
import 'package:sacdia_app/core/widgets/sac_loading.dart';

import '../../domain/entities/honor.dart';
import '../../domain/entities/user_honor.dart';
import '../../domain/usecases/get_honors.dart';
import '../providers/honors_providers.dart';

/// Celebration screen shown when an honor is completed (validated).
///
/// Green header with checkmark, large badge, stats row.
class HonorCompletionView extends ConsumerWidget {
  final int honorId;
  final int userHonorId;

  const HonorCompletionView({
    super.key,
    required this.honorId,
    required this.userHonorId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userHonorAsync = ref.watch(userHonorForHonorProvider(honorId));
    final honorsAsync = ref.watch(honorsProvider(const GetHonorsParams()));

    return userHonorAsync.when(
      data: (userHonor) {
        if (userHonor == null) {
          return const Scaffold(
            body: Center(child: Text('Honor no encontrado')),
          );
        }

        final honor = honorsAsync.maybeWhen(
          data: (honors) {
            try {
              return honors.firstWhere((h) => h.id == honorId);
            } catch (_) {
              return null;
            }
          },
          orElse: () => null,
        );

        return _CompletionBody(userHonor: userHonor, honor: honor);
      },
      loading: () => const Scaffold(body: Center(child: SacLoading())),
      error: (_, __) => const Scaffold(
        body: Center(child: Text('Error al cargar')),
      ),
    );
  }
}

class _CompletionBody extends StatelessWidget {
  final UserHonor userHonor;
  final Honor? honor;

  const _CompletionBody({required this.userHonor, this.honor});

  @override
  Widget build(BuildContext context) {
    final honorName = honor?.name ?? userHonor.honorName ?? 'Especialidad';
    final completionDate = userHonor.validatedAt ?? userHonor.date;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // ── Green header ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.sacGreen,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.sacGreen,
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Checkmark circle
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Especialidad Completa',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yyyy').format(completionDate),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withAlpha(200),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
              child: Column(
                children: [
                  // Large badge circle
                  Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      color: AppColors.sacYellow,
                      shape: BoxShape.circle,
                    ),
                    child: honor?.imageUrl != null
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: honor!.imageUrl!,
                              fit: BoxFit.contain,
                              errorWidget: (_, __, ___) => const Icon(
                                Icons.emoji_events_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.emoji_events_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Honor name
                  Text(
                    honorName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.sacBlack,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Status pills
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (honor?.skillLevel != null)
                        _StatusPill(
                          label: 'Nivel ${honor!.skillLevel}',
                          color: AppColors.sacGreen,
                        ),
                      const SizedBox(width: 8),
                      const _StatusPill(
                        label: 'Insignia obtenida',
                        color: AppColors.sacYellow,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Stats row
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFBFB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _StatItem(
                          value: '${userHonor.evidenceCount}',
                          label: 'Evidencias',
                          color: AppColors.sacBlue,
                        ),
                        _StatItem(
                          value: DateFormat('dd/MM')
                              .format(userHonor.date),
                          label: 'Inscripcion',
                          color: AppColors.sacRed,
                        ),
                        _StatItem(
                          value: _duration(
                              userHonor.date, completionDate),
                          label: 'Duracion',
                          color: AppColors.sacGreen,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Primary CTA
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => context.pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.sacBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Ver mas especialidades'),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Secondary
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.sacBlack,
                        side: BorderSide(
                            color: AppColors.sacBlack.withAlpha(40)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Volver'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _duration(DateTime start, DateTime end) {
    final diff = end.difference(start);
    if (diff.inDays > 30) {
      final months = (diff.inDays / 30).round();
      return '${months}m';
    }
    return '${diff.inDays}d';
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
```

---

### Task 15 — Update `my_honors_view.dart` — reuse new HonorCard

- [ ] Rewrite my honors view using new HonorCard

**File:** `sacdia-app/lib/features/honors/presentation/views/my_honors_view.dart`

The key change: replace `HonorProgressCard` with the new `HonorCard` widget, and update status filtering to use `displayStatus` instead of the old binary `status`.

The existing structure (tabs + stats + list) is fine. Changes needed:

1. Replace import of `honor_progress_card.dart` with `honor_card.dart`
2. In the tab split logic, use `userHonor.isCompleted` instead of `uh.status.toLowerCase() == 'completed'`
3. Replace `HonorProgressCard(...)` with `HonorCard(honor: matchingHonor, userHonor: userHonor, onTap: ...)`
4. Update stats to show the new breakdown (validated/in_progress/pending_review/rejected)
5. Navigate to evidence view instead of detail view on card tap

The full rewrite follows the same layout as the existing view but with the new card widget and status-aware filtering. The implementer should preserve the existing `StaggeredListItem` animations and `DefaultTabController` structure.

**Key code change in the list builder (replace HonorProgressCard):**

```dart
HonorCard(
  honor: honor,
  userHonor: userHonor,
  onTap: () {
    context.push(
      RouteNames.honorEvidencePath(
        userHonor.honorId.toString(),
        userHonor.id.toString(),
      ),
    );
  },
);
```

---

### Task 16 — Update routing — add evidence and completion routes

- [ ] Add new route constants and paths
- [ ] Add GoRoute entries

**File:** `sacdia-app/lib/core/config/route_names.dart`

Add the following routes after `honorDetail` (line ~18):

```dart
  // Honors evidence & completion
  static const String honorEvidence = '/honor/:honorId/evidence/:userHonorId';
  static const String honorCompletion = '/honor/:honorId/completion/:userHonorId';

  // Helpers
  static String honorEvidencePath(String honorId, String userHonorId) =>
      '/honor/$honorId/evidence/$userHonorId';
  static String honorCompletionPath(String honorId, String userHonorId) =>
      '/honor/$honorId/completion/$userHonorId';
```

**File:** `sacdia-app/lib/core/config/router.dart`

Add two new GoRoute entries after the existing `honorDetail` route (around line 341-349):

```dart
      // Detalle de honor
      GoRoute(
        path: RouteNames.honorDetail,
        pageBuilder: (context, state) {
          final honorIdStr = state.pathParameters['honorId']!;
          final honorId = int.tryParse(honorIdStr) ?? 0;
          return _sharedAxisBuild(
              context, state, HonorDetailView(honorId: honorId));
        },
      ),

      // Evidence/progress view for an enrolled honor
      GoRoute(
        path: RouteNames.honorEvidence,
        pageBuilder: (context, state) {
          final honorId = int.tryParse(state.pathParameters['honorId']!) ?? 0;
          final userHonorId =
              int.tryParse(state.pathParameters['userHonorId']!) ?? 0;
          return _sharedAxisBuild(
            context,
            state,
            HonorEvidenceView(
              honorId: honorId,
              userHonorId: userHonorId,
            ),
          );
        },
      ),

      // Completion/celebration view
      GoRoute(
        path: RouteNames.honorCompletion,
        pageBuilder: (context, state) {
          final honorId = int.tryParse(state.pathParameters['honorId']!) ?? 0;
          final userHonorId =
              int.tryParse(state.pathParameters['userHonorId']!) ?? 0;
          return _sharedAxisBuild(
            context,
            state,
            HonorCompletionView(
              honorId: honorId,
              userHonorId: userHonorId,
            ),
          );
        },
      ),
```

Add the necessary imports at the top of `router.dart`:

```dart
import 'package:sacdia_app/features/honors/presentation/views/honor_evidence_view.dart';
import 'package:sacdia_app/features/honors/presentation/views/honor_completion_view.dart';
```

---

### Task 17 — Clean up — delete deprecated files

- [ ] Delete deprecated files and their backup counterparts

**Files to delete:**

```
sacdia-app/lib/features/honors/presentation/views/add_honor_view.dart
sacdia-app/lib/features/honors/presentation/views/add_honor_view.backup.dart
sacdia-app/lib/features/honors/presentation/widgets/honor_progress_card.dart
sacdia-app/lib/features/honors/presentation/widgets/honor_progress_card.backup.dart
sacdia-app/lib/features/honors/presentation/widgets/honor_category_card.dart
sacdia-app/lib/features/honors/presentation/widgets/honor_category_card.backup.dart
```

**Also delete the backup files for modified views:**

```
sacdia-app/lib/features/honors/presentation/views/honors_catalog_view.backup.dart
sacdia-app/lib/features/honors/presentation/views/honor_detail_view.backup.dart
sacdia-app/lib/features/honors/presentation/views/my_honors_view.backup.dart
sacdia-app/lib/features/honors/presentation/widgets/honor_card.backup.dart
```

**Search for dead imports:** After deletion, run `flutter analyze` and fix any import references to deleted files. Known files that import the deleted widgets:

- `honors_catalog_view.dart` imports `honor_category_card.dart` — already replaced in Task 11
- `my_honors_view.dart` imports `honor_progress_card.dart` — already replaced in Task 15
- Any file importing `add_honor_view.dart` — search and remove

---

### Phase 3 commits

```bash
# After Tasks 9-12 (views + widgets core)
git add sacdia-app/lib/features/honors/presentation/
git commit -m "feat: redesign honors catalog, detail, and card widgets with status-aware UI"

# After Task 13 (evidence view - largest)
git add sacdia-app/lib/features/honors/presentation/views/honor_evidence_view.dart
git commit -m "feat: add honor evidence view with upload, status messages, and submit"

# After Task 14 (completion view)
git add sacdia-app/lib/features/honors/presentation/views/honor_completion_view.dart
git commit -m "feat: add honor completion celebration view"

# After Tasks 15-16 (my_honors + routing)
git add sacdia-app/lib/features/honors/presentation/views/my_honors_view.dart sacdia-app/lib/core/config/route_names.dart sacdia-app/lib/core/config/router.dart
git commit -m "feat: update my-honors view and add evidence/completion routes"

# After Task 17 (cleanup)
git add -u
git commit -m "refactor: remove deprecated honor views and widgets"
```

---

## Implementation Notes

### Offline behavior (deferred)

The spec mentions offline evidence queueing with Hive and `ConnectivityNotifier`. This is complex and should be implemented as a **follow-up task** after the core flow is working. For now, the evidence upload requires network connectivity. The TODO comments in Task 13's `_uploadFile` method mark where this integration will happen.

### Dark mode (out of scope)

Per the spec, dark mode is explicitly out of scope. All colors use hardcoded light palette values from `AppColors` (sacBlack, sacBlue, etc.) rather than semantic theme tokens.

### Backward compatibility

- The `validate: bool` field is kept on `users_honors` for backward compatibility. It becomes derived: `true` when `validation_status = 'approved'`
- The `getUserHonorStats()` response maintains the `validated` and `in_progress` keys for any existing consumers, while adding the new breakdown

### File upload infrastructure

The evidence upload in Task 13 uses `TODO` markers for the actual file upload. The backend already has `PATCH /users/:userId/honors/:honorId` with file upload support (via `FileFieldsInterceptor` and `StorageBucketAlias.EVIDENCE_FILES`). The implementer needs to connect the Flutter file picker results to the existing `HonorsRemoteDataSource.updateUserHonor()` method.

### Testing

After implementation, verify:
1. New enrollment creates `validation_status = 'in_progress'`
2. Submit changes status to `pending_review` and sets `submitted_at`
3. Approve changes status to `approved` and sets `validated_by_id`, `validated_at`
4. Reject changes status to `rejected` and sets `rejection_reason`
5. Resubmit from rejected clears `rejection_reason`
6. Flutter `displayStatus` correctly splits `in_progress` into `inscripto` vs `en_progreso`
7. All 5 card states render correctly with proper colors
8. Navigation: catalog -> detail -> evidence -> completion flows correctly
