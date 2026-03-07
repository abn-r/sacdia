# Session: Canonical Authorization Contract

**Status**: HISTORICAL  
**Date**: 2026-03-06  
**Commit**: `62179f5`  
**Scope**: Backend authorization contract and auth response normalization

## Summary

This session introduced a canonical authorization resolver in `sacdia-backend` so `/auth/me` and the active-context endpoint stop depending on ad hoc field flattening.

The backend now resolves:

- global role grants with structured territorial scope
- club assignment grants by exact assignment
- active assignment
- effective permissions for the current session

Legacy fields remain present in the auth response for continuity, but the new `authorization` block is now the canonical backend output.

## Implemented

- Added `AuthorizationContextService` as the single backend resolver for authorization payload assembly.
- Updated `GET /auth/me` to include `authorization` alongside legacy `roles`, `permissions`, `club`, and `club_context`.
- Updated `PATCH /auth/me/context` to return both legacy active-context fields and the canonical `authorization` snapshot.
- Reused the resolver in `GlobalRolesGuard` and `OwnerOrAdminGuard` to remove duplicated global-role lookups.
- Added unit tests for the resolver and updated auth service tests to validate the new contract.

## Verification

Commands executed:

```bash
pnpm exec jest common/services/authorization-context.service.spec.ts auth/auth.service.spec.ts auth/auth.controller.spec.ts --runInBand
pnpm build
```

Result:

- Targeted auth/resolver tests passed.
- Backend build passed.

## Files Touched

- `src/common/services/authorization-context.service.ts`
- `src/common/services/authorization-context.service.spec.ts`
- `src/auth/auth.service.ts`
- `src/auth/auth.controller.ts`
- `src/common/guards/global-roles.guard.ts`
- `src/common/guards/owner-or-admin.guard.ts`

## Deferred Follow-Ups

- Migrate remaining authorization guards and club-scoped enforcement to the canonical resolver semantics.
- Align `sacdia-admin` to consume `authorization.effective` and `authorization.grants`.
- Align `sacdia-app` to stop inferring club RBAC from `metadata.roles`.
- Review JWT-only endpoints that still need authorization hardening.
