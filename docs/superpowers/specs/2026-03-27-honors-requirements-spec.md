# Honors Requirements — Specification

**Change**: `honors-requirements`
**Date**: 2026-03-27
**Status**: Draft
**Depends on**: Proposal (`sdd/honors-requirements/proposal`)

---

## Purpose

Add per-requirement tracking for honor specialties. Members can view the individual requirements of any honor they are enrolled in, check them off as completed, and optionally add notes. Progress is informational only and does NOT gate the validation submission workflow.

---

## Domain: Data Model

### Requirement: Honor Requirements Catalog

The system MUST store individual requirements for each honor specialty as structured rows in an `honor_requirements` table.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `requirement_id` | SERIAL | PK | Auto-increment identifier |
| `honor_id` | INT | FK -> `honors.honor_id`, NOT NULL | Parent honor |
| `requirement_number` | INT | NOT NULL | Display order (1-based) |
| `requirement_text` | TEXT | NOT NULL | Full requirement text as extracted |
| `has_sub_items` | BOOLEAN | DEFAULT false | True if text contains a/b/c or i/ii/iii patterns |
| `needs_review` | BOOLEAN | DEFAULT true | OCR quality flag for future admin review |
| `active` | BOOLEAN | DEFAULT true | Soft delete |
| `created_at` | TIMESTAMPTZ | DEFAULT now() | Row creation |
| `modified_at` | TIMESTAMPTZ | DEFAULT now() | Last update |

- UNIQUE constraint: `(honor_id, requirement_number)`
- Index: `honor_id` (for catalog lookups)

#### Scenario: Honor has requirements seeded

- GIVEN an honor "anfibios" exists in the `honors` table
- WHEN the seed script processes `anfibios.md` (11 requirements detected)
- THEN 11 rows MUST exist in `honor_requirements` with `honor_id` matching "anfibios", numbered 1-11
- AND each row's `needs_review` MUST be `true`

#### Scenario: Duplicate seed is idempotent

- GIVEN requirements for "anfibios" already exist in `honor_requirements`
- WHEN the seed script runs again
- THEN no duplicate rows SHALL be created (upsert on unique constraint)

### Requirement: User Honor Requirement Progress

The system MUST track per-user completion of individual requirements via a `user_honor_requirement_progress` table.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `progress_id` | SERIAL | PK | Auto-increment identifier |
| `user_honor_id` | INT | FK -> `users_honors.user_honor_id`, NOT NULL | Parent enrollment |
| `requirement_id` | INT | FK -> `honor_requirements.requirement_id`, NOT NULL | Target requirement |
| `completed` | BOOLEAN | DEFAULT false | Completion checkbox state |
| `notes` | TEXT | NULLABLE | Optional user notes/answers |
| `completed_at` | TIMESTAMPTZ | NULLABLE | When user marked completed |
| `active` | BOOLEAN | DEFAULT true | Soft delete |
| `created_at` | TIMESTAMPTZ | DEFAULT now() | Row creation |
| `modified_at` | TIMESTAMPTZ | DEFAULT now() | Last update |

- UNIQUE constraint: `(user_honor_id, requirement_id)`
- Index: `user_honor_id` (for progress lookups)

#### Scenario: User completes a requirement

- GIVEN user has an active `users_honors` enrollment for "anfibios"
- WHEN user marks requirement #3 as completed with notes "Sapos vs Ranas: piel seca vs humeda"
- THEN a row MUST be upserted in `user_honor_requirement_progress` with `completed = true`, `notes` set, and `completed_at` set to current timestamp

#### Scenario: User unchecks a completed requirement

- GIVEN user previously completed requirement #3 for "anfibios"
- WHEN user unchecks requirement #3
- THEN `completed` MUST be set to `false` and `completed_at` MUST be set to `null`
- AND `notes` SHOULD be preserved (not cleared)

---

## Domain: Seed Strategy

### Requirement: Markdown Parsing and Seeding

The system MUST provide a seed script that parses markdown files from `docs/working/honors-especialidades/md/` and populates the `honor_requirements` table.

**Parsing rules:**
1. The script MUST extract numbered requirements using the pattern `^\d+\.\s+(.+)$` (multiline)
2. The script MUST match each markdown file's slug to an honor via `index.csv` title -> `honors.name`
3. The script MUST set `has_sub_items = true` when text contains `a.`, `b.`, `c.` or `i.`, `ii.`, `iii.` patterns
4. The script MUST set `needs_review = true` for ALL seeded rows
5. The script MUST preserve requirement ordering (1-based `requirement_number`)

**Validation rules:**
1. The script SHOULD log a warning for any markdown file that cannot be matched to a DB honor
2. The script MUST cross-validate: parsed requirement count per honor vs `requirements_detected` column in `index.csv`
3. The script MUST report total honors processed, total requirements inserted, and mismatches

#### Scenario: Successful seed of a well-formed honor

- GIVEN `acolchado.md` exists with 7 detected requirements and honor "acolchado" exists in DB
- WHEN the seed script runs
- THEN 7 rows MUST be inserted into `honor_requirements` with correct `honor_id`
- AND the parsed count (7) MUST match `index.csv` `requirements_detected` (7)

#### Scenario: Honor name mismatch

- GIVEN a markdown file `foo-bar.md` exists but no honor named "foo bar" exists in DB
- WHEN the seed script runs
- THEN the script MUST log a warning with the unmatched slug
- AND MUST NOT insert any rows for that file
- AND MUST continue processing remaining files

#### Scenario: Empty requirement text after parsing

- GIVEN `agricultura.md` has requirements 6-7 with empty text (OCR artifacts)
- WHEN the seed script encounters an empty requirement body
- THEN the script SHOULD skip that requirement and log a warning
- AND `requirement_number` for subsequent items MUST still match the source numbering

---

## Domain: Backend API

### Requirement: List Honor Requirements

The system MUST expose `GET /api/v1/honors/:honorId/requirements` to return the catalog of requirements for a given honor.

**Response shape:**
```json
{
  "status": "success",
  "data": {
    "honor_id": 42,
    "total_requirements": 11,
    "requirements": [
      {
        "requirement_id": 301,
        "requirement_number": 1,
        "requirement_text": "...",
        "has_sub_items": false
      }
    ]
  }
}
```

- The endpoint MUST return only active requirements, ordered by `requirement_number` ASC
- The endpoint MUST return 404 if `honorId` does not exist
- The endpoint MAY be public (no auth required) since requirement text is catalog data

#### Scenario: List requirements for a valid honor

- GIVEN honor 42 ("anfibios") has 11 active requirements
- WHEN `GET /api/v1/honors/42/requirements`
- THEN response MUST have status 200 with `total_requirements: 11` and 11 items ordered 1-11

#### Scenario: Honor has no requirements

- GIVEN honor 99 exists but has no seeded requirements
- WHEN `GET /api/v1/honors/99/requirements`
- THEN response MUST have status 200 with `total_requirements: 0` and empty `requirements` array

### Requirement: Get User Requirement Progress

The system MUST expose `GET /api/v1/users/:userId/honors/:userHonorId/requirements/progress` to return the user's completion state per requirement.

**Response shape:**
```json
{
  "status": "success",
  "data": {
    "user_honor_id": 10,
    "honor_id": 42,
    "total_requirements": 11,
    "completed_count": 4,
    "progress_percentage": 36.36,
    "requirements": [
      {
        "requirement_id": 301,
        "requirement_number": 1,
        "requirement_text": "...",
        "has_sub_items": false,
        "completed": true,
        "notes": "...",
        "completed_at": "2026-03-20T15:00:00Z"
      }
    ]
  }
}
```

- The endpoint MUST join `honor_requirements` with `user_honor_requirement_progress` (LEFT JOIN — requirements without progress rows show `completed: false`, `notes: null`)
- The endpoint MUST validate that the `users_honors` record belongs to `:userId` (OwnerOrAdminGuard)
- The endpoint MUST return 404 if `userHonorId` does not exist or does not belong to `:userId`
- `progress_percentage` MUST be `(completed_count / total_requirements) * 100`, rounded to 2 decimals

#### Scenario: User has partial progress

- GIVEN user has enrollment (user_honor_id=10) for honor 42 with 11 requirements, 4 completed
- WHEN `GET /api/v1/users/{userId}/honors/10/requirements/progress`
- THEN response MUST show `completed_count: 4`, `progress_percentage: 36.36`
- AND all 11 requirements MUST appear in the list, with 4 showing `completed: true`

#### Scenario: User has no progress yet

- GIVEN user has enrollment for honor 42 but no progress rows exist
- WHEN `GET /api/v1/users/{userId}/honors/10/requirements/progress`
- THEN response MUST show `completed_count: 0`, `progress_percentage: 0`
- AND all requirements MUST appear with `completed: false`

### Requirement: Update Single Requirement Progress

The system MUST expose `PATCH /api/v1/users/:userId/honors/:userHonorId/requirements/:requirementId/progress` to toggle a single requirement's completion state.

**Request body:**
```json
{
  "completed": true,
  "notes": "Optional text"
}
```

**Rules:**
- The endpoint MUST upsert the `user_honor_requirement_progress` row (create if not exists, update if exists)
- When `completed` changes to `true`, `completed_at` MUST be set to current timestamp
- When `completed` changes to `false`, `completed_at` MUST be set to `null`
- `notes` MAY be provided independently of `completed` (partial update)
- The endpoint MUST validate ownership via OwnerOrAdminGuard
- The endpoint MUST return 404 if `requirementId` does not belong to the honor associated with `userHonorId`
- The endpoint MUST return 403 if user does not own the enrollment

#### Scenario: Toggle requirement on

- GIVEN user owns enrollment 10, requirement 301 belongs to the same honor
- WHEN `PATCH .../requirements/301/progress` with `{ "completed": true }`
- THEN progress row MUST be upserted with `completed: true`, `completed_at: now()`

#### Scenario: Invalid requirement for enrollment

- GIVEN user owns enrollment 10 (honor 42), requirement 999 belongs to honor 50
- WHEN `PATCH .../requirements/999/progress` with `{ "completed": true }`
- THEN response MUST be 404 with error message indicating requirement does not belong to this honor

### Requirement: Batch Update Requirement Progress

The system MUST expose `PATCH /api/v1/users/:userId/honors/:userHonorId/requirements/progress/batch` to update multiple requirements at once.

**Request body:**
```json
{
  "updates": [
    { "requirement_id": 301, "completed": true, "notes": "..." },
    { "requirement_id": 302, "completed": false }
  ]
}
```

**Rules:**
- The endpoint MUST validate ALL `requirement_id` values belong to the honor associated with `userHonorId` BEFORE applying any updates
- If ANY requirement_id is invalid, the entire batch MUST be rejected (atomic)
- The endpoint MUST use a database transaction for atomicity
- Maximum batch size SHOULD be 50 items (covers the largest honors at ~20 requirements)
- The endpoint MUST return the updated progress summary (same shape as the GET progress endpoint)

#### Scenario: Batch update succeeds

- GIVEN user owns enrollment 10 with 11 requirements
- WHEN batch update with 3 valid requirement updates
- THEN all 3 MUST be upserted atomically
- AND response MUST include updated `completed_count` and `progress_percentage`

#### Scenario: Batch with invalid requirement rejected

- GIVEN user owns enrollment 10 (honor 42)
- WHEN batch includes requirement_id 999 (belongs to a different honor)
- THEN the entire batch MUST be rejected with 400
- AND no progress rows SHALL be modified

---

## Domain: Business Rules

### Requirement: Enrollment Prerequisite

The system MUST NOT allow progress tracking for a user who does not have an active `users_honors` enrollment for the target honor.

#### Scenario: Unenrolled user attempts progress update

- GIVEN user has no `users_honors` record for honor 42
- WHEN user attempts to update requirement progress for honor 42
- THEN response MUST be 404

### Requirement: Progress Does Not Gate Validation

Completing all requirements MUST NOT automatically trigger submission for validation. The user MUST explicitly submit via the existing validation workflow.

#### Scenario: All requirements completed

- GIVEN user has completed 11/11 requirements for honor 42
- WHEN all requirements are marked complete
- THEN `users_honors.validation_status` MUST remain unchanged (still "in_progress")
- AND the system MAY display a prompt suggesting the user submit for review

### Requirement: Coexistence with Evidence Upload

Per-requirement progress tracking and the existing PDF/image evidence upload flow MUST operate independently. Neither feature blocks or depends on the other.

#### Scenario: User uploads evidence without completing requirements

- GIVEN user has 0/11 requirements completed for honor 42
- WHEN user uploads a signed PDF via the existing evidence flow
- THEN the upload MUST succeed regardless of requirement progress

#### Scenario: User submits for review with partial requirements

- GIVEN user has 7/11 requirements completed and evidence uploaded
- WHEN user submits the honor for coordinator review
- THEN submission MUST succeed — requirement completion percentage is informational only

### Requirement: Progress Percentage Calculation

The system MUST calculate progress as `(completed_count / total_active_requirements) * 100`, rounded to 2 decimal places. If total is 0, percentage MUST be 0.

#### Scenario: Percentage with zero requirements

- GIVEN an honor has 0 active requirements (none seeded or all deactivated)
- WHEN progress percentage is calculated
- THEN result MUST be 0 (not NaN or error)

---

## Domain: Integration (Flutter)

### Requirement: Requirements Tab in Honor Detail

The `HonorDetailView` MUST include a "Requisitos" section or tab that navigates to a `HonorRequirementsView` showing the full checklist.

#### Scenario: Enrolled user views honor detail

- GIVEN user is enrolled in honor 42 with 4/11 requirements completed
- WHEN user opens the honor detail screen
- THEN a "Requisitos" CTA MUST be visible showing "4/11 completados"
- AND tapping it MUST navigate to the requirements list view

### Requirement: Progress Bar on Honor Card

Honor cards in the catalog/my-honors list MUST display a progress bar showing requirement completion percentage for enrolled honors.

#### Scenario: Honor card shows progress

- GIVEN user is enrolled in honor 42 with 36% progress
- WHEN the honor card renders in the catalog list
- THEN a progress indicator MUST show "4/11" or equivalent visual
- AND the progress bar MUST reflect 36%

#### Scenario: Non-enrolled honor card

- GIVEN user is NOT enrolled in honor 42
- WHEN the honor card renders
- THEN no progress indicator SHALL be shown

---

## Summary

| Domain | Type | Requirements | Scenarios |
|--------|------|-------------|-----------|
| Data Model | New | 2 (tables) | 4 |
| Seed Strategy | New | 1 (parsing + validation) | 3 |
| Backend API | New | 4 (endpoints) | 8 |
| Business Rules | New | 4 (enrollment, no-auto-submit, coexistence, percentage) | 5 |
| Integration | New | 2 (detail view, honor card) | 3 |
| **Total** | | **13** | **23** |

### Coverage

- **Happy paths**: Covered for all endpoints and UI flows
- **Edge cases**: Empty requirements, zero progress, honor name mismatches, empty OCR text, zero-division percentage
- **Error states**: Invalid requirement ID, unauthorized access, unenrolled user, batch validation failure

### Next Step

Ready for **design** (`sdd-design`) to define Flutter UI component hierarchy, wireframes, and backend module structure.
