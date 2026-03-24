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

Single point of validation in `ClassesService.enrollUser()`, before creating or reactivating an enrollment.

### Flow

```
enrollUser(userId, classId, ecclesiasticalYearId):
  1. Resolve club_type IDs by name from club_types table:
     - findMany where name IN ('Aventureros', 'Conquistadores', 'Guías Mayores')
     - Extract IDs dynamically (no hardcoded values)

  2. Get the club_type_id of the target class (from classes table)

  3. Validate by type:
     a. If Aventureros or Conquistadores:
        → Count active enrollments in current year where class.club_type_id IN (aventureros_id, conquistadores_id)
        → If count >= 1 → ConflictException("Ya tenés una inscripción activa en Aventureros/Conquistadores")

     b. If Guías Mayores:
        → Check exists enrollment with investiture_status = 'INVESTIDO' in any GM class (any year)
        → If not exists → ForbiddenException("Necesitás haber completado la clase base de Guías Mayores")
        → Count active enrollments in current year where class.club_type_id = gm_id
        → If count >= 2 → ConflictException("Ya tenés 2 inscripciones activas en Guías Mayores")

  4. Existing duplicate check (already implemented):
     → findUnique on composite key (user_id, class_id, ecclesiastical_year_id)
     → Active duplicate → ConflictException
     → Inactive → reactivate
     → Not found → create
```

### Files to Modify

- `src/classes/classes.service.ts` — `enrollUser()` method only

### Error Responses

| Scenario | Exception | Message |
|----------|-----------|---------|
| Aventureros/Conquistadores limit reached | `ConflictException` | "Ya tenés una inscripción activa en Aventureros/Conquistadores" |
| GM without prior investiture | `ForbiddenException` | "Necesitás haber completado la clase base de Guías Mayores" |
| GM limit reached | `ConflictException` | "Ya tenés 2 inscripciones activas en Guías Mayores" |
| Duplicate active enrollment | `ConflictException` | (existing message) |

### Design Decisions

1. **club_type IDs resolved by name** — No hardcoded IDs. Query `club_types` table by name to get IDs dynamically.
2. **GM investiture check spans all years** — Investiture is permanent. Once invested in any year, the user qualifies.
3. **Aventureros + Conquistadores share a single limit** — A user can only have 1 active enrollment across both types combined.
4. **Post-registration not modified** — It already deactivates other-class enrollments before creating, so it implicitly respects the 1-at-a-time rule.
5. **Validation before duplicate check** — Limits are checked first, then the existing findUnique duplicate logic runs.

### Not in Scope

- No changes to post-registration flow
- No database constraints (application-level only)
- No changes to admin endpoints
- No UI changes
