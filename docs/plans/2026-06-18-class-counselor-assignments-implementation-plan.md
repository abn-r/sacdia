# Asignación de Consejeros a Clases Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Permitir que el director/asignador configure qué consejero o staff operativo acompaña una clase progresiva específica y que ese actor pueda ver/gestionar el avance de miembros inscritos en esa clase.

**Architecture:** La asignación de rol de club (`club_role_assignments`) sigue representando cargo/sección/año. La nueva asignación pedagógica vive en una tabla separada vinculada a usuario, sección, clase y año eclesiástico. La autorización de progreso distingue actor (`currentUser.sub`) de miembro objetivo (`:userId`).

**Tech Stack:** NestJS + Prisma/PostgreSQL, Next.js Admin, Flutter/Riverpod App, REST API v1, Jest/Vitest/Flutter tests. No ejecutar builds salvo pedido explícito.

---

## Reglas de dominio confirmadas

- Un consejero puede tener una unidad y también una clase progresiva a cargo.
- Normalmente un consejero tiene 1 clase asignada; 2 clases es caso extraordinario y debe quedar marcado con justificación.
- Cada clase de una sección debe tener 1 responsable principal y puede tener hasta 2 apoyos/suplentes activos.
- Una clase no debe tener más de 3 responsables pedagógicos activos en el mismo año eclesiástico.
- Consejero asignado a una clase puede ver avances/evidencias de miembros inscritos en esa clase y puede subir evidencias para el miembro. La evidencia queda en el progreso del miembro, pero `uploaded_by_id` debe ser el consejero.
- Director, subdirector, secretario y secretario-tesorero tienen alcance de toda la sección para ver avances.
- Secretario también puede recibir clase asignada como consejero.
- `instructor` queda fuera de la asignación formal de clase: puede impartir una parte de la clase o dirigir una especialidad, pero no lleva la trayectoria completa del miembro durante el año eclesiástico.

## Decisión arquitectónica

Crear `class_counselor_assignments` y NO agregar `class_id` a `club_role_assignments`.

**Por qué:** cargo operativo y alcance pedagógico son conceptos distintos. Mezclarlos en la misma tabla rompería histórico, permisos y consultas futuras.

## Task 1: Documentar contrato canónico antes de código

**Files:**
- Modify: `docs/features/clases-progresivas.md`
- Modify: `docs/features/gestion-clubs.md`
- Modify: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`

**Steps:**
1. Agregar sección “Asignación pedagógica de clases”.
2. Documentar actor vs miembro objetivo.
3. Documentar que `uploaded_by_id` es quien sube la evidencia, no necesariamente el dueño del enrollment.
4. Documentar alcance:
   - class-scoped: consejero/secretario asignado.
   - section-scoped: director, subdirector, secretario, secretario-tesorero.

## Task 2: Agregar modelo DB

**Files:**
- Modify: `sacdia-backend/prisma/schema.prisma`
- Create: `sacdia-backend/prisma/migrations/<timestamp>_class_counselor_assignments/migration.sql`

**Table proposed:**

```sql
CREATE TABLE class_counselor_assignments (
  assignment_id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  club_section_id INTEGER NOT NULL REFERENCES club_sections(club_section_id) ON DELETE CASCADE,
  class_id INTEGER NOT NULL REFERENCES classes(class_id) ON DELETE CASCADE,
  ecclesiastical_year_id INTEGER NOT NULL REFERENCES ecclesiastical_years(year_id) ON DELETE CASCADE,
  club_role_assignment_id UUID REFERENCES club_role_assignments(assignment_id) ON DELETE SET NULL,
  active BOOLEAN NOT NULL DEFAULT true,
  exceptional BOOLEAN NOT NULL DEFAULT false,
  exception_reason VARCHAR(500),
  assigned_by_id UUID REFERENCES users(user_id),
  responsibility_type VARCHAR(20) NOT NULL DEFAULT 'primary',
  start_date DATE NOT NULL DEFAULT CURRENT_DATE,
  end_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  modified_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

Add indexes:
- `(user_id, active, ecclesiastical_year_id)`
- `(club_section_id, class_id, active, ecclesiastical_year_id)`
- partial unique active assignment per `(user_id, club_section_id, class_id, ecclesiastical_year_id)`
- partial unique active primary per `(club_section_id, class_id, ecclesiastical_year_id)` where `responsibility_type = 'primary'`
- CHECK `responsibility_type IN ('primary', 'assistant', 'substitute')`

## Task 3: Backend service + validation

**Files:**
- Create: `sacdia-backend/src/classes/class-counselor-assignments.service.ts`
- Create: `sacdia-backend/src/classes/dto/class-counselor-assignment.dto.ts`
- Modify: `sacdia-backend/src/classes/classes.module.ts`

**Rules:**
- `class_id` must belong to the same `club_type_id` as `club_section_id`.
- Assignee must have active `club_role_assignments` in that section/year.
- Assignable roles: `counselor`, `secretary`.
- `instructor` must not be assignable as formal class owner in this workflow.
- Each `(club_section_id, class_id, ecclesiastical_year_id)` must have max 1 active `primary`.
- Each `(club_section_id, class_id, ecclesiastical_year_id)` can have max 3 active assignments total.
- If user already has 1 active class in same section/year, second assignment requires `exceptional=true` and `exception_reason`.
- More than 2 active class assignments should be rejected.

## Task 4: Backend API endpoints

**Files:**
- Create: `sacdia-backend/src/classes/class-counselor-assignments.controller.ts`
- Modify: `sacdia-backend/src/classes/classes.module.ts`
- Modify: `sacdia-backend/src/common/guards/permissions.guard.ts`
- Modify: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`

**Endpoints proposed:**

- `GET /api/v1/clubs/:clubId/sections/:sectionId/class-counselor-assignments`
- `POST /api/v1/clubs/:clubId/sections/:sectionId/class-counselor-assignments`
- `PATCH /api/v1/class-counselor-assignments/:assignmentId`
- `DELETE /api/v1/class-counselor-assignments/:assignmentId`
- `GET /api/v1/clubs/:clubId/sections/:sectionId/classes/progress-scope`
- `GET /api/v1/clubs/:clubId/sections/:sectionId/classes/:classId/members-progress`

**Implementation note:** `PATCH`/`DELETE` by assignment id use a dedicated `class_counselor_assignment` authorization resource so the guard resolves the assignment's `club_section_id` before allowing mutations. Do not protect these routes with broad `active_assignment` scope.

**Implementation note:** `progress-scope` and `members-progress` are implemented through `ClassProgressScopeController` + `ClassProgressScopeService`. `members-progress` must first validate the actor scope and then filter returned enrollments by active `club_role_assignments` membership in the requested section/year; validating only `class_id + ecclesiastical_year_id` is not enough because the same class exists across multiple sections.

## Task 5: Corregir actor vs target user en progreso/evidencias

**Files:**
- Modify: `sacdia-backend/src/classes/classes.controller.ts`
- Modify: `sacdia-backend/src/classes/classes.service.ts`

**Critical fix:**
Current `submitSection`, `uploadSectionFile`, and `deleteSectionFile` parse `:userId` but call service with `currentUser.sub`. Change signatures to:

```ts
targetUserId: string,
actorUserId: string,
classId: number,
sectionId: number,
...
```

Then:
- Resolve enrollment using `targetUserId`.
- Store evidence/progress under target member enrollment.
- Store uploaded/submitted actor as `actorUserId`.
- Authorize actor via class assignment or section-wide role.

**Implementation note:** Controller now forwards both `:userId` and `currentUser.sub` for progress/evidence routes. Service methods resolve enrollment by target and record `uploaded_by_id`/`submitted_by_id` with actor.

## Task 6: Authorization helper

**Files:**
- Create: `sacdia-backend/src/classes/class-progress-access.service.ts`
- Test: `sacdia-backend/src/classes/class-progress-access.service.spec.ts`

**Allowed access:**
- Self access remains allowed.
- Assigned class counselor/staff can access target member if target enrollment class/year/section matches assignment.
- Director/subdirector/secretary/secretary-treasurer can access all class progress in their active section.
- Global admin/coordinator behavior must remain compatible with existing guards.

**Implementation note:** `ClassProgressAccessService` must resolve target member section memberships by `club_role_assignments` and class club type before accepting a counselor assignment; matching only `class_id + year` is not sufficient because the same class exists across multiple sections/clubs.

## Task 7: Admin UI

**Files:**
- Modify: `sacdia-admin/src/components/clubs/club-sections-panel.tsx`
- Create: `sacdia-admin/src/components/classes/class-counselor-assignments-card.tsx`
- Modify: `sacdia-admin/src/lib/api/clubs.ts`
- Modify: `sacdia-admin/src/lib/clubs/actions.ts`

**UI:**
- Add “Clases asignadas” card per section in club detail.
- Select class filtered by section `club_type_id`.
- Select assignee from active section staff.
- Show badge for exceptional second assignment.
- Add revoke/edit actions.

**Implementation note:** Admin web now mounts `ClassCounselorAssignmentsCard` inside `ClubSectionsPanel` for each existing section. It fetches section members through `listNormalizedClubSectionMembers`, filters assignable candidates to `counselor`/`secretary`, fetches classes by section `club_type_id`, and uses server actions for create/update/revoke assignment mutations.

## Task 8: App mobile UX

**Files:**
- Modify: `sacdia-app/lib/core/config/router.dart`
- Modify: `sacdia-app/lib/features/dashboard/presentation/widgets/quick_access_grid.dart`
- Create: `sacdia-app/lib/features/classes/presentation/views/teaching_scope_view.dart`
- Create: `sacdia-app/lib/features/classes/presentation/views/class_members_progress_view.dart`
- Create: `sacdia-app/lib/features/classes/presentation/views/class_counselor_assignments_view.dart`
- Modify: `sacdia-app/lib/features/classes/presentation/providers/classes_providers.dart`
- Modify: `sacdia-app/lib/features/classes/data/datasources/classes_remote_data_source.dart`

**Flow:**
1. Quick access “Clase agrupada” opens teaching scope.
2. If actor has section-wide role, show all section classes.
3. If actor has assigned classes, show only assigned classes.
4. Opening a class shows members enrolled in that class.
5. Tapping a member opens `ClassDetailWithProgressView` with `targetUserId` + `enrollmentId`.
6. Upload/submit evidence uses target member route but actor auth.
7. Directors/section operators with `club_roles:assign`/`club_roles:revoke` can open assignment management from `TeachingScopeView` and create/edit/revoke class counselor assignments in the mobile app.

**Implementation note:** `sacdia-app` now wires `/home/grouped-class` to `TeachingScopeView`, backed by `classProgressScopeProvider` and `classMembersProgressProvider`. `ClassProgressQuery` accepts `targetUserId` so delegated evidence/progress calls target the member enrollment while the backend still derives the actor from the JWT.

**Implementation note:** `ClassCounselorAssignmentsView` is mounted from the `TeachingScopeView` app bar for users with club-role assignment permissions. It reuses `membersNotifierProvider` to filter assignable candidates to `counselor`/`secretary`, `classesByClubTypeProvider` for the section class catalog, and `classCounselorAssignmentsProvider`/notifier for list/create/update/revoke.

## Task 9: Tests

**Backend:**
- Service validates same club type.
- Rejects second assignment without exception data.
- Rejects third active assignment.
- Counselor can view/upload for assigned class only.
- Counselor cannot access another class.
- Director/subdirector/secretary/secretary-treasurer can access section scope.
- Evidence upload persists under target enrollment and actor uploader.

**Admin:**
- Assignment payload includes `class_id`, `user_id`, `ecclesiastical_year_id`.
- Exceptional assignment requires reason.

**App:**
- Teaching scope renders assigned classes.
- Section-wide staff sees all section classes.
- Member progress request uses target member id, not actor id.

## Task 10: Rollout

1. Merge DB + backend first.
2. Deploy admin assignment UI.
3. Deploy app teaching scope flow.
4. Backfill is not required initially because no existing class-level assignments exist.
5. Monitor for permission regressions around class evidence endpoints.

## Product decision

`instructor` is intentionally excluded from formal class ownership. The instructor can teach a class segment or direct an honor/specialty, but the counselor owns the full progress trajectory from the beginning to the end of the ecclesiastical year.
