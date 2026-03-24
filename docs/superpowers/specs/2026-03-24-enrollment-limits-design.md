# Enrollment Limits — Design Spec

**Date**: 2026-03-24
**Status**: Approved
**Scope**: sacdia-backend — `ClassesService.enrollUser()`

## Business Rules

| Club Type | Max Active Enrollments per Year | Pre-condition |
|-----------|-------------------------------|---------------|
| Aventureros (name-resolved) + Conquistadores (name-resolved) | **1 total** between both | None |
| Guías Mayores (name-resolved) | **2 active** | At least 1 enrollment with `investiture_status = INVESTIDO` in any GM class (any year) |

## Design

### Approach: Validation in `enrollUser()` (Approach A)

Single point of validation in `ClassesService.enrollUser()`, before creating or reactivating an enrollment. The entire operation runs inside a `prisma.$transaction()` to prevent race conditions on concurrent requests.

### Flow

```
enrollUser(userId, classId, ecclesiasticalYearId):
  prisma.$transaction(async (tx) => {
    1. Resolve club_type IDs by name from club_types table:
       - findMany where name IN ('Aventureros', 'Conquistadores', 'Guías Mayores')
       - Guard: if results.length !== 3 → InternalServerErrorException
         (fail closed — never skip validation because of missing reference data)

    2. Get the target class (includes club_type_id and requires_invested_gm)

    3. If requires_invested_gm === true:
       → Check exists enrollment with investiture_status = 'INVESTIDO' (enum)
         in any class with club_type_id = gm_id (any year)
       → If not exists → ForbiddenException

    4. Enrollment limit by club type:
       a. If club_type_id IN (aventureros_id, conquistadores_id):
          → Count enrollments where active = true AND year = current
            AND class.club_type_id IN (aventureros_id, conquistadores_id)
          → If count >= 1 → ConflictException

       b. If club_type_id = gm_id:
          → Count enrollments where active = true AND year = current
            AND class.club_type_id = gm_id
          → If count >= 2 → ConflictException

    5. Duplicate check (existing logic, now inside tx):
       → findUnique on composite key (user_id, class_id, ecclesiastical_year_id)
       → Active → ConflictException
       → Inactive → reactivate (update active: true)
       → Not found → create
  })
```

### Key Implementation Notes

- **Transaction**: The entire validation + create/reactivate block MUST be inside `prisma.$transaction()`. Without it, two concurrent requests could both pass the count check before either creates the enrollment, bypassing the limit.

- **`requires_invested_gm` field**: The `classes` table already has a `requires_invested_gm: Boolean` field. Use it directly instead of hardcoding the GM investiture check by club_type. If the target class has `requires_invested_gm = true`, check for a prior `INVESTIDO` enrollment.

- **`active: true` explicit in all queries**: Every count or existence check on enrollments MUST explicitly filter by `active: true`. Never rely on implicit assumptions about the default state.

- **`investiture_status` enum**: `investiture_status` is an enum (`investiture_status_enum`) in the database. Prisma accepts the string name `'INVESTIDO'` directly in queries.

- **Guard on name resolution**: If the `findMany` for club_types returns fewer than 3 results, throw `InternalServerErrorException`. This ensures the system fails closed — it never skips validation because a club type name was misspelled or missing from the DB.

### Why Post-Registration Doesn't Need This Validation

Post-registration is the **onboarding flow** — a user's first enrollment when they join a club. It does not need enrollment limit validation for the following reasons:

1. **It's always the first enrollment.** A new user enrolling for the first time has zero active enrollments, so the limit check would always pass.
2. **It already deactivates other-class enrollments.** The post-registration flow calls `updateMany` to set `active: false` on all enrollments from other classes before creating the new one, so it implicitly respects the 1-at-a-time rule.
3. **The investiture check is irrelevant on first enrollment.** The GM investiture pre-condition only applies when enrolling in _additional_ classes (2nd enrollment onward). A first-time user enrolling in a GM class is starting their journey — they don't need prior investiture.
4. **Different code path, different intent.** Post-registration is a controlled onboarding step, not an arbitrary enrollment addition. The limits protect against accumulating conflicting enrollments over time.

### Files to Modify

- `src/classes/classes.service.ts` — `enrollUser()` method only

### Error Responses

| Scenario | Exception | Message |
|----------|-----------|---------|
| Aventureros/Conquistadores limit reached | `ConflictException` | "Ya tenés una inscripción activa en Aventureros/Conquistadores" |
| GM without prior investiture | `ForbiddenException` | "Necesitás haber sido investido en al menos una clase de Guías Mayores" |
| GM limit reached | `ConflictException` | "Ya tenés 2 inscripciones activas en Guías Mayores" |
| Duplicate active enrollment | `ConflictException` | (existing message) |
| Club type name resolution failed | `InternalServerErrorException` | "No se pudieron resolver los tipos de club requeridos" |

### Design Decisions

1. **`prisma.$transaction()` wraps all logic** — Prevents race conditions where concurrent requests both pass validation before either writes. The serializable isolation of the transaction ensures correctness.
2. **`requires_invested_gm` drives the check** — Instead of hardcoding "if club_type is GM, check investiture", the `classes.requires_invested_gm` boolean field controls this. If the schema evolves (e.g., a new club type needs investiture), no code change is needed — just set the field.
3. **club_type IDs resolved by name** — No hardcoded IDs. Query `club_types` table by name to get IDs dynamically. A guard ensures all 3 expected types are found.
4. **GM investiture check spans all years** — Investiture is permanent. Once invested in any year, the user qualifies.
5. **Aventureros + Conquistadores share a single limit** — A user can only have 1 active enrollment across both types combined.
6. **Post-registration not modified** — It already deactivates other-class enrollments before creating, and it's always a first enrollment, so limits and investiture checks don't apply.
7. **Validation before duplicate check** — Limits are checked first, then the existing findUnique duplicate logic runs. Both inside the same transaction.
8. **Fail closed on missing data** — If name resolution returns unexpected results, the system throws rather than silently skipping validation.

### Test Cases

The following scenarios should be covered by unit and/or integration tests:

| # | Scenario | Expected Result |
|---|----------|-----------------|
| 1 | Aventureros enrollment when 1 active Conquistadores enrollment exists | `ConflictException` — block |
| 2 | Conquistadores enrollment when 1 active Aventureros enrollment exists | `ConflictException` — block |
| 3 | GM class with `requires_invested_gm = true`, no prior investiture | `ForbiddenException` — block |
| 4 | GM enrollment when 2 active GM enrollments exist | `ConflictException` — block |
| 5 | GM class with `requires_invested_gm = true`, prior `INVESTIDO` exists, under limit | Allow enrollment |
| 6 | Reactivation of inactive enrollment when limit already reached | `ConflictException` — block (reactivation respects limits) |
| 7 | Reactivation of inactive enrollment when under limit | Allow reactivation |
| 8 | Two concurrent enrollment requests for the same user | Only one succeeds — transaction serialization prevents both passing |
| 9 | Club type name resolution returns < 3 results | `InternalServerErrorException` — fail closed |
| 10 | First enrollment (no existing enrollments) in Aventureros | Allow — no limit hit |
| 11 | First enrollment in GM class with `requires_invested_gm = false` | Allow — no investiture needed |

### Not in Scope

- No changes to post-registration flow
- No database constraints (application-level only)
- No changes to admin endpoints
- No UI changes
