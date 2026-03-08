# Session: RBAC Hardening Stage 1

**Status**: HISTORICAL  
**Date**: 2026-03-07  
**Backend Commit**: `ca935dd`  
**Scope**: Backend permission enforcement and sensitive-route hardening

## Summary

This stage moved `sacdia-backend` from a mixed "JWT + role names + partial permissions" model toward real backend permission enforcement.

The key change is that the backend now has:

- a reusable `PermissionsGuard`
- explicit permission metadata decorators
- resource-aware authorization checks for global, club, instance, assignment, and owner-scoped routes
- broader hardening of sensitive endpoints that previously depended only on JWT

The canonical `authorization` contract introduced previously remains the source of truth, and this stage starts enforcing against it instead of just exposing it.

## Implemented

- Added `@RequirePermissions(...)` and `@AuthorizationResource(...)`.
- Added `PermissionsGuard` with support for:
  - global permission checks
  - club-scoped checks
  - exact instance checks
  - club-assignment checks
  - owner fallback for self-service user routes
- Registered the new guard in `CommonModule` and exported it for reuse.
- Hardened administrative controllers to require explicit permissions instead of relying only on global role guards:
  - admin users
  - admin geography
  - admin reference
  - RBAC admin routes
- Hardened business controllers with permission metadata and resource-aware checks:
  - clubs and club role assignments
  - activities
  - finances
  - inventory
  - notifications
  - user profile routes
  - legal representatives
  - user classes progress/enrollment routes
- Added focused tests for:
  - `PermissionsGuard`
  - permission/resource metadata on representative controllers
  - updated admin controller spec wiring

## Verification

Commands executed:

```bash
pnpm exec jest common/guards/permissions.guard.spec.ts common/guards/permissions-metadata.spec.ts common/services/authorization-context.service.spec.ts common/guards/club-roles.guard.spec.ts admin/admin-users.controller.spec.ts auth/auth.controller.spec.ts --runInBand
pnpm build
```

Result:

- Targeted authorization and controller tests passed.
- Backend build passed.

## Notes

- Club aggregate routes that still operate at main-club level remain a compatibility compromise; the new guard already enforces exact instance matching where the route or entity shape makes that possible.
- Existing legacy auth fields are still present for client compatibility, but backend authorization is no longer limited to those fields.
- Stage 1 does not imply full enforcement coverage for every permission in the business catalog; some modules remain staged.

## Documentation Added

This stage requires three canonical documents before client migration continues:

- `docs/01-FEATURES/auth/AUTHORIZATION-CANONICAL-CONTRACT.md`
- `docs/01-FEATURES/auth/RBAC-ENFORCEMENT-MATRIX.md`
- `docs/01-FEATURES/auth/CLUB-ROLE-ASSIGNMENT-FIRST-CONTRACT.md`

These documents define:

- the official `authorization` payload contract;
- how permissions are enforced in backend;
- the assignment-first write/read model for club roles.

## Consistency Update (2026-03-08)

A documentation consistency pass aligned the canonical RBAC trilogy plus permission catalog:

- `PERMISSIONS-SYSTEM.md` now acts as canonical catalog and no longer positions flat `permissions` as the client source of truth.
- `RBAC-ENFORCEMENT-MATRIX.md` now reflects current notification permissions (`send`, `broadcast`, `club`) and separates `club_roles:assign` create vs update semantics.
- `CLUB-ROLE-ASSIGNMENT-FIRST-CONTRACT.md` now mirrors the same create/update/revoke authorization resource model.

## Next Stage

- Migrate `sacdia-admin` to consume `authorization.effective.permissions` and `authorization.grants`.
- Migrate `sacdia-app` away from `metadata.roles` / `metadata.club`.
- Align admin role-assignment writes to the assignment-first backend contract.
