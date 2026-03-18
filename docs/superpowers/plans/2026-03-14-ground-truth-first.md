# Ground Truth First — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild SACDIA documentation from code truth upward, producing a Reality Matrix, verified canon, and clean doc structure.

**Architecture:** 3-phase approach — audit code → cross-reference against canon/docs → reorganize. Each phase produces markdown artifacts in `docs/audit/` or updates `docs/canon/`.

**Spec:** `docs/superpowers/specs/2026-03-14-ground-truth-first-design.md`

**Tech Stack:** Markdown, Git. No code changes. Sub-agents scan NestJS (backend), Next.js (admin), Flutter (app).

---

## Chunk 1: Phase 1 — Code Audits (Parallel)

Three independent audit tasks that run in parallel. Each produces one markdown file in `docs/audit/`.

### Task 1: Backend Audit

**Files:**
- Create: `docs/audit/backend-audit.md`
- Read: `sacdia-backend/src/**/*.controller.ts`, `sacdia-backend/src/**/*.module.ts`, `sacdia-backend/src/**/*.service.ts`, `sacdia-backend/prisma/schema.prisma`, `sacdia-backend/src/common/**/*`

**Context for agent:**
- Backend is NestJS + Prisma
- Controllers at `sacdia-backend/src/{domain}/{domain}.controller.ts`
- Auth split: `src/auth/auth.controller.ts`, `sessions.controller.ts`, `oauth.controller.ts`, `mfa.controller.ts`
- Shared infra at `src/common/` (guards, decorators, interceptors, services)
- Schema at `sacdia-backend/prisma/schema.prisma`
- Known domains: activities, auth, clubs, classes, finances, honors, inventory, users, emergency-contacts, legal-representatives, certifications, camporees, post-registration, notifications, rbac, admin, catalogs, folders, health

- [ ] **Step 1: Scan all controllers and extract endpoints**

For every `*.controller.ts`, extract each route handler. Produce table:

```markdown
## Endpoints

| Method | Route | Controller | Service | Auth Guard | Description |
|--------|-------|------------|---------|------------|-------------|
| GET | /api/v1/auth/me | AuthController | AuthService | JwtAuthGuard | Get current user |
```

Include the full route (with prefix from controller decorator + method decorator).

- [ ] **Step 2: Verify endpoint count**

Run: count all `@Get(`, `@Post(`, `@Put(`, `@Delete(`, `@Patch(` decorators across all controllers.
Compare count with table rows. They must match.

- [ ] **Step 3: Scan schema.prisma and extract models**

Read `sacdia-backend/prisma/schema.prisma`. Produce table:

```markdown
## Modelos de Datos

| Model | Table Name | Fields Count | Key Relations | Enums Used |
|-------|------------|-------------|---------------|------------|
| User | users | 15 | clubs, enrollments | Role |
```

- [ ] **Step 4: Verify model count**

Count `model ` declarations in schema.prisma. Compare with table rows.

- [ ] **Step 5: Scan modules and extract dependency map**

For every `*.module.ts`, extract imports and exports. Produce table:

```markdown
## Módulos NestJS

| Module | Controllers | Services | Imports | Exports |
|--------|-------------|----------|---------|---------|
| AuthModule | AuthController, SessionsController, OAuthController, MfaController | AuthService | PrismaModule, CommonModule | AuthService |
```

- [ ] **Step 6: Scan shared infrastructure**

Read `sacdia-backend/src/common/` — guards, decorators, interceptors, pipes, services. Produce table:

```markdown
## Infraestructura Compartida

| Type | Name | Location | Used By |
|------|------|----------|---------|
| Guard | JwtAuthGuard | src/common/guards/jwt-auth.guard.ts | All protected endpoints |
| Decorator | CurrentUser | src/common/decorators/current-user.decorator.ts | Controllers |
```

- [ ] **Step 7: Scan external service integrations**

Search for SDK/client imports (Supabase, Firebase, Redis, etc.). Produce table:

```markdown
## Integraciones Externas

| Service | Package/SDK | Config Location | Used In Modules | Active |
|---------|-------------|----------------|-----------------|--------|
| Supabase | @supabase/supabase-js | src/common/services/supabase.service.ts | Auth, Storage | Yes |
```

- [ ] **Step 8: Write docs/audit/backend-audit.md**

Combine all tables into single file. Header:

```markdown
# Backend Audit — SACDIA
Fecha: 2026-03-14
Fuente: sacdia-backend/ (NestJS + Prisma)
Método: Scan automático de código fuente

## Resumen
- Endpoints: {count}
- Modelos: {count}
- Módulos: {count}
- Integraciones externas: {count}
```

- [ ] **Step 9: Commit**

```bash
git add docs/audit/backend-audit.md
git commit -m "docs(audit): add backend ground truth audit"
```

---

### Task 2: Admin Audit

**Files:**
- Create: `docs/audit/admin-audit.md`
- Read: `sacdia-admin/src/app/**/*page.tsx`, `sacdia-admin/src/app/**/layout.tsx`, `sacdia-admin/src/components/**/*`, `sacdia-admin/src/lib/**/*`, `sacdia-admin/package.json`

**Context for agent:**
- Admin is Next.js 16 with App Router
- Pages at `sacdia-admin/src/app/(auth)/` and `sacdia-admin/src/app/(dashboard)/`
- Components at `sacdia-admin/src/components/{domain}/`
- API calls at `sacdia-admin/src/lib/{domain}/`
- Auth via Supabase SSR at `sacdia-admin/src/lib/auth/` and `sacdia-admin/src/lib/supabase/`

- [ ] **Step 1: Scan all pages/routes**

Find every `page.tsx` file. Produce table:

```markdown
## Páginas/Rutas

| Route | Page Component | Layout Group | Description |
|-------|---------------|-------------|-------------|
| /dashboard | src/app/(dashboard)/page.tsx | dashboard | Main dashboard |
| /login | src/app/(auth)/login/page.tsx | auth | Login page |
```

- [ ] **Step 2: Scan API consumption**

For each page/component, find `fetch`, API client calls, or `src/lib/{domain}/` imports. Produce table:

```markdown
## Consumo de API por Página

| Page/Component | API Endpoints Called | Lib Module |
|---------------|---------------------|------------|
| /dashboard/clubs | GET /api/v1/clubs | src/lib/clubs/ |
```

- [ ] **Step 3: Scan auth integration**

Check middleware, route protection, auth hooks. Produce:

```markdown
## Estado de Auth

| Route Group | Protected | Method | Notes |
|------------|-----------|--------|-------|
| (dashboard) | Yes | Middleware + Supabase SSR | All dashboard routes |
| (auth) | No | Public | Login, register |
```

- [ ] **Step 4: Scan dependencies**

Read `package.json`. List key dependencies:

```markdown
## Dependencias Principales

| Package | Version | Purpose |
|---------|---------|---------|
| next | 16.x | Framework |
| @supabase/ssr | x.x | Auth SSR |
```

- [ ] **Step 5: Verify page count**

Count `page.tsx` files. Compare with table rows.

- [ ] **Step 6: Write docs/audit/admin-audit.md and commit**

```bash
git add docs/audit/admin-audit.md
git commit -m "docs(audit): add admin ground truth audit"
```

---

### Task 3: App Audit

**Files:**
- Create: `docs/audit/app-audit.md`
- Read: `sacdia-app/lib/features/**/*`, `sacdia-app/lib/core/**/*`, `sacdia-app/lib/providers/**/*`, `sacdia-app/lib/main.dart`, `sacdia-app/pubspec.yaml`

**Context for agent:**
- App is Flutter with Clean Architecture
- Features at `sacdia-app/lib/features/{feature}/` with `data/`, `domain/`, `presentation/` subdirs
- Known features: auth, activities, classes, club, dashboard, evidence_folder, finances, home, honors, insurance, inventory, members, post_registration, profile, units
- Core at `sacdia-app/lib/core/`
- State management likely Riverpod at `sacdia-app/lib/providers/`

- [ ] **Step 1: Scan all screens**

Find screen/page widgets in `presentation/` folders. Produce table:

```markdown
## Screens

| Screen | Feature | Route/Navigation | Provider/Cubit | Description |
|--------|---------|-----------------|----------------|-------------|
| LoginScreen | auth | /login | AuthNotifier | Login page |
```

- [ ] **Step 2: Scan API consumption**

For each feature's `data/` layer, find HTTP calls or repository implementations. Produce table:

```markdown
## Consumo de API por Feature

| Feature | Repository | API Endpoints Called |
|---------|-----------|---------------------|
| auth | AuthRepositoryImpl | POST /api/v1/auth/login, GET /api/v1/auth/me |
```

- [ ] **Step 3: Scan auth integration**

Check auth state management, token storage, route guards. Produce:

```markdown
## Estado de Auth

| Feature | Auth Required | Guard/Check | Notes |
|---------|-------------|-------------|-------|
| home | Yes | AuthGuard | Redirects to login |
| auth | No | None | Public |
```

- [ ] **Step 4: Scan navigation**

Find route definitions, GoRouter config, or navigation patterns. Produce:

```markdown
## Navegación

| Route | Screen | Auth Required | Deep Link |
|-------|--------|-------------|-----------|
| /home | HomeScreen | Yes | No |
```

- [ ] **Step 5: Scan dependencies**

Read `pubspec.yaml`. List key dependencies:

```markdown
## Dependencias Principales

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_riverpod | x.x | State management |
| dio | x.x | HTTP client |
```

- [ ] **Step 6: Verify screen count**

Count screen widgets. Compare with table rows.

- [ ] **Step 7: Write docs/audit/app-audit.md and commit**

```bash
git add docs/audit/app-audit.md
git commit -m "docs(audit): add app ground truth audit"
```

---

## Chunk 2: Phase 2 — Reality Matrix

**Depends on:** Chunk 1 complete (all 3 audits committed).

### Task 4: Build Reality Matrix

**Files:**
- Create: `docs/audit/REALITY-MATRIX.md`
- Read: `docs/audit/backend-audit.md`, `docs/audit/admin-audit.md`, `docs/audit/app-audit.md`, `docs/canon/**/*.md`, `docs/02-API/ENDPOINTS-LIVE-REFERENCE.md`, `docs/03-DATABASE/SCHEMA-REFERENCE.md`

**Context for agent:**
- You are cross-referencing CODE REALITY (from audit files) against DOCUMENTATION (canon + API docs + schema docs)
- States: ALINEADO, SIN CANON, SIN DOCS, FANTASMA, DRIFT
- This is the most critical artifact — accuracy matters more than speed

- [ ] **Step 1: Build Endpoints Matrix**

Cross-reference backend-audit endpoints against `docs/02-API/ENDPOINTS-LIVE-REFERENCE.md` and canon mentions. Produce:

```markdown
## Tabla 1: Endpoints

| Endpoint | Implementado | Doc API | Canon | Estado |
|----------|:---:|:---:|:---:|---|
| POST /api/v1/auth/login | ✅ | ✅ | ✅ | ALINEADO |
| GET /api/v1/something | ✅ | ❌ | ❌ | SIN DOCS |
| POST /api/v1/ghost | ❌ | ✅ | ✅ | FANTASMA |
```

State rules:
- ALINEADO: ✅ in code AND (✅ in API docs OR ✅ in canon)
- SIN CANON: ✅ in code, ✅ in API docs, ❌ in canon
- SIN DOCS: ✅ in code, ❌ in API docs, ❌ in canon
- FANTASMA: ❌ in code, ✅ in API docs or canon
- DRIFT: ✅ in code but behavior differs from docs (note what differs)

- [ ] **Step 2: Build Data Models Matrix**

Cross-reference backend-audit models against `docs/03-DATABASE/SCHEMA-REFERENCE.md` and canon. Produce:

```markdown
## Tabla 2: Modelos de Datos

| Model | schema.prisma | SCHEMA-REFERENCE | Canon | Estado |
|-------|:---:|:---:|:---:|---|
```

- [ ] **Step 3: Build Modules/Features Matrix**

Cross-reference backend modules, admin pages, and app screens per domain. Produce:

```markdown
## Tabla 3: Módulos/Features

| Dominio | Backend Module | Admin Pages | App Screens | Canon Domain | Estado |
|---------|:---:|:---:|:---:|:---:|---|
| auth | ✅ (AuthModule) | ✅ (/login) | ✅ (auth/) | ✅ | ALINEADO |
| inventario | ✅ (InventoryModule) | ❌ | ✅ (inventory/) | ✅ | PARCIAL |
```

Note: validate the 13 canon domains against actual backend modules. Add any backend module NOT in the canon domain list as a new row.

- [ ] **Step 4: Build Integrations Matrix**

Cross-reference backend integrations against documentation. Produce:

```markdown
## Tabla 4: Integraciones Externas

| Service | Configurado | Usado Activamente | Documentado | Estado |
|---------|:---:|:---:|:---:|---|
```

- [ ] **Step 5: Write summary statistics**

At the top of REALITY-MATRIX.md:

```markdown
# Reality Matrix — SACDIA
Fecha: 2026-03-14

## Resumen

| Categoría | Total | ALINEADO | SIN CANON | SIN DOCS | FANTASMA | DRIFT |
|-----------|-------|----------|-----------|----------|----------|-------|
| Endpoints | X | X | X | X | X | X |
| Modelos | X | X | X | X | X | X |
| Features | X | X | X | X | X | X |
| Integraciones | X | X | X | X | X | X |
```

- [ ] **Step 6: Commit**

```bash
git add docs/audit/REALITY-MATRIX.md
git commit -m "docs(audit): add reality matrix cross-reference"
```

---

## Chunk 3: Phase 3 — Canon Update, Feature Registry, Docs Simplification

**Depends on:** Chunk 2 complete (Reality Matrix committed).

### Task 5: Canon Update (3a)

**Files:**
- Modify: `docs/canon/runtime-sacdia.md`, `docs/canon/completion-matrix.md`, and any canon file with unverified claims
- Read: `docs/audit/REALITY-MATRIX.md`, all `docs/canon/*.md`

**Context for agent:**
- Canon was built top-down from project idea, NOT from code
- Reality Matrix tells you what is actually implemented
- Your job: add verification marks to canon, NOT rewrite it
- Mark claims as `[VERIFICADO]`, `[ASPIRACIONAL]`, or `[INCOMPLETO]`
- `runtime-sacdia.md` is DRAFT — update to ACTIVE with verified data

- [ ] **Step 1: Read Reality Matrix summary**

Load `docs/audit/REALITY-MATRIX.md` and understand the gap distribution.

- [ ] **Step 2: Verify runtime-sacdia.md**

Cross-reference every claim in `docs/canon/runtime-sacdia.md` against Reality Matrix:
- API module count, endpoint count — verified?
- Integration claims (Supabase, Firebase, Redis) — verified?
- Auth model claims — verified?
- Data boundary claims (enrollments vs users_classes) — verified?

Update the document:
- Change estado from DRAFT to ACTIVE
- Add `<!-- VERIFICADO contra código 2026-03-14 -->` next to verified claims
- Add `<!-- ASPIRACIONAL: no implementado -->` next to unverified claims
- Update counts to match reality

- [ ] **Step 3: Verify completion-matrix.md**

Update feature coverage status based on Reality Matrix Tabla 3. Correct any status that contradicts code reality.

- [ ] **Step 4: Review other canon files for code-dependent claims**

Scan `arquitectura-sacdia.md`, `decisiones-clave.md`, `auth/runtime-auth.md` for claims that can be verified against code. Add verification marks where applicable.

- [ ] **Step 5: Prune ENDPOINTS-LIVE-REFERENCE.md**

Using Reality Matrix Tabla 1, remove FANTASMA endpoints from `docs/02-API/ENDPOINTS-LIVE-REFERENCE.md` (endpoints documented but not implemented). Add a note at the top: `<!-- Verificado contra código 2026-03-14. Endpoints FANTASMA removidos. -->`. Keep a list of removed endpoints in `docs/audit/DECISIONS-PENDING.md` under "Endpoints removidos de Live Reference".

- [ ] **Step 6: Sync SCHEMA-REFERENCE.md**

Using Reality Matrix Tabla 2, identify DRIFT between `docs/03-DATABASE/SCHEMA-REFERENCE.md` and `docs/03-DATABASE/schema.prisma`. For each model with DRIFT:
- Update SCHEMA-REFERENCE to match schema.prisma (schema.prisma is source of truth)
- Add `<!-- Sincronizado contra schema.prisma 2026-03-14 -->` at the top

- [ ] **Step 7: Generate decisions list for developer**

Create a section at the end of REALITY-MATRIX.md or a separate `docs/audit/DECISIONS-PENDING.md`:

```markdown
# Decisiones Pendientes para el Desarrollador

## Canon aspiracional — ¿mantener como objetivo?
1. [claim from canon that is not implemented] — ¿se mantiene como spec o se descarta?

## Código sin canon — ¿agregar al negocio?
1. [module/endpoint that exists but canon doesn't define] — ¿se formaliza en canon?
```

- [ ] **Step 8: Commit**

```bash
git add docs/canon/ docs/audit/DECISIONS-PENDING.md docs/02-API/ENDPOINTS-LIVE-REFERENCE.md docs/03-DATABASE/SCHEMA-REFERENCE.md
git commit -m "docs(canon): verify canon against code reality, prune ghost endpoints, sync schema"
```

---

### Task 6: Feature Registry (3c, parallel with 5)

**Files:**
- Create: `docs/features/{domain}.md` (one per domain)
- Read: `docs/audit/REALITY-MATRIX.md`, `docs/canon/dominio-sacdia.md`, `docs/canon/decisiones-clave.md`

**Context for agent:**
- Domain list comes from Reality Matrix Tabla 3 (validated against code, not just canon)
- Each file follows the standard format from the spec
- Domains with zero code artifacts get `NO INICIADO`

- [ ] **Step 1: Extract domain list from Reality Matrix**

Read Tabla 3 from `docs/audit/REALITY-MATRIX.md`. Build the definitive list of domains (may differ from the 13 canon domains if code has modules not in canon).

- [ ] **Step 2: Create feature file for each domain**

For each domain, create `docs/features/{domain}.md`:

```markdown
# {Nombre del Dominio}
Estado: IMPLEMENTADO | PARCIAL | PLANIFICADO | NO INICIADO

## Qué existe (verificado contra código)
- Backend: {modules, endpoints count}
- Admin: {pages, if any}
- App: {screens, if any}
- DB: {tables/models used}

## Qué define el canon
- {relevant quotes/references from dominio-sacdia.md, decisiones-clave.md}

## Gap
- {what canon expects that doesn't exist in code}
- {what exists in code that canon doesn't define}

## Prioridad
- A definir por el desarrollador
```

- [ ] **Step 3: Create features/README.md index**

```markdown
# Feature Registry — SACDIA
Generado: 2026-03-14

| Dominio | Estado | Backend | Admin | App |
|---------|--------|---------|-------|-----|
| auth | IMPLEMENTADO | ✅ | ✅ | ✅ |
| inventario | PARCIAL | ✅ | ❌ | ✅ |
```

- [ ] **Step 4: Commit**

```bash
git add docs/features/
git commit -m "docs(features): add verified feature registry"
```

---

### Task 7: Docs Simplification (3b)

**Depends on:** Tasks 5 AND 6 complete.

**Files:**
- Modify: `docs/README.md`
- Move: multiple files to `docs/history/`
- Read: full `docs/` directory listing

**Context for agent:**
- No files are deleted — everything goes to `docs/history/`
- Numeric prefixes (`00-`, `01-`, `02-`, `03-`) are removed from folder names
- CLAUDE.md navigation files are consolidated into docs/README.md
- The target structure is defined in the spec
- `docs/superpowers/` stays as-is
- `docs/plans/` stays as-is
- `docs/templates/` stays as-is

- [ ] **Step 1: Create target directories**

```bash
mkdir -p docs/api docs/database docs/steering docs/features
# history/ already exists, audit/ already exists from Phase 1
```

Note: `docs/guides/` already exists.

- [ ] **Step 2: Move steering docs**

```bash
# Active steering docs → docs/steering/
mv docs/00-STEERING/tech.md docs/steering/
mv docs/00-STEERING/coding-standards.md docs/steering/
mv docs/00-STEERING/data-guidelines.md docs/steering/
mv docs/00-STEERING/agents.md docs/steering/

# Deprecated/historical → history
mv docs/00-STEERING/product.md docs/history/00-STEERING/
mv docs/00-STEERING/structure.md docs/history/00-STEERING/
mv docs/00-STEERING/CLAUDE.md docs/history/navigation/
mv docs/00-STEERING/README.md docs/history/00-STEERING/ 2>/dev/null

# Clean up: move any remaining files before rmdir
find docs/00-STEERING/ -type f -exec mv {} docs/history/00-STEERING/ \; 2>/dev/null
rmdir docs/00-STEERING/ 2>/dev/null  # remove if empty
```

- [ ] **Step 3: Move API docs**

```bash
# Canonical API doc → docs/api/
mv docs/02-API/ENDPOINTS-LIVE-REFERENCE.md docs/api/
mv docs/02-API/API-SPECIFICATION.md docs/api/
mv docs/02-API/ARCHITECTURE-DECISIONS.md docs/api/
mv docs/02-API/SECURITY-GUIDE.md docs/api/
mv docs/02-API/FRONTEND-INTEGRATION-GUIDE.md docs/api/
mv docs/02-API/TESTING-GUIDE.md docs/api/
mv docs/02-API/API-VERSIONING.md docs/api/

# Redundant/subordinate → history
mv docs/02-API/ENDPOINTS-REFERENCE.md docs/history/02-API/
mv docs/02-API/API-REFERENCE.md docs/history/02-API/
mv docs/02-API/CLAUDE.md docs/history/navigation/02-API-CLAUDE.md
mv docs/02-API/README.md docs/history/02-API/
mv docs/02-API/_source_docs/ docs/history/02-API/ 2>/dev/null
mv docs/02-API/EXTERNAL-SERVICES-INTEGRATION.md docs/api/ 2>/dev/null

# Clean up: move any remaining files before rmdir
find docs/02-API/ -type f -exec mv {} docs/history/02-API/ \; 2>/dev/null
rmdir docs/02-API/ 2>/dev/null
```

- [ ] **Step 4: Move database docs**

```bash
# Canonical DB docs → docs/database/
mv docs/03-DATABASE/schema.prisma docs/database/
mv docs/03-DATABASE/SCHEMA-REFERENCE.md docs/database/
mv docs/03-DATABASE/migrations/ docs/database/
mv docs/03-DATABASE/README.md docs/database/

# Others → history
mv docs/03-DATABASE/migration-schema-v2.sql docs/history/03-DATABASE/
mv docs/03-DATABASE/CLAUDE.md docs/history/navigation/03-DATABASE-CLAUDE.md
mv docs/03-DATABASE/_source_docs/ docs/history/03-DATABASE/ 2>/dev/null
mv docs/03-DATABASE/schema_additions_phase1.prisma docs/history/03-DATABASE/ 2>/dev/null
mv docs/03-DATABASE/schema.prisma.backup_* docs/history/03-DATABASE/ 2>/dev/null
mv docs/03-DATABASE/examples/ docs/history/03-DATABASE/ 2>/dev/null

# Clean up: move any remaining files before rmdir
find docs/03-DATABASE/ -type f -exec mv {} docs/history/03-DATABASE/ \; 2>/dev/null
rmdir docs/03-DATABASE/ 2>/dev/null
```

- [ ] **Step 5: Move feature docs to history**

```bash
# Old feature docs → history (replaced by docs/features/ registry)
mv docs/01-FEATURES/ docs/history/01-FEATURES/
```

- [ ] **Step 6: Move loose root docs to history**

```bash
mv docs/02-PROCESSES.md docs/history/
mv docs/CHANGELOG-IMPLEMENTATION.md docs/history/
mv docs/BACKEND-PANORAMA-2026-03-04.md docs/history/
mv docs/03-IMPLEMENTATION-ROADMAP.md docs/history/phases/
mv docs/PHASE-2-MOBILE-PROGRAM.md docs/history/phases/
mv docs/PHASE-3-ADMIN-PROGRAM.md docs/history/phases/
mv docs/CLAUDE.md docs/history/navigation/docs-CLAUDE.md
mv docs/context/ docs/history/context/
```

Evaluate `docs/DEPLOYMENT-GUIDE.md`: if it has useful active content, move to `docs/guides/deployment.md`. Otherwise move to `docs/history/`.

- [ ] **Step 7: Move CLAUDE.md files from remaining folders to history**

Only move CLAUDE.md from folders that still exist at this point (01-FEATURES/ was already moved in Step 5, so skip it).

```bash
mv docs/guides/CLAUDE.md docs/history/navigation/guides-CLAUDE.md 2>/dev/null
mv docs/templates/CLAUDE.md docs/history/navigation/templates-CLAUDE.md 2>/dev/null
```

- [ ] **Step 8: Add explicit state labels to all documents**

Every document in the new structure that lacks an explicit state must receive one. Add a `Estado: ACTIVE | DRAFT | HISTORICAL | DEPRECATED` line in the document header or frontmatter. Applies to:
- All files in `docs/steering/`
- All files in `docs/api/`
- All files in `docs/database/`
- All files in `docs/guides/`
- `docs/features/` files already have state from Task 6
- `docs/canon/` files already have state from Task 5

- [ ] **Step 9: Update docs/README.md**

Rewrite to reflect new structure. Include:
- Project overview (1 paragraph)
- New directory structure with descriptions
- Authority hierarchy (from canon/source-of-truth.md)
- Quick navigation by role/question type
- Link to Reality Matrix for current state
- Link to Feature Registry for planning

- [ ] **Step 10: Update canon/source-of-truth.md paths**

Update any path references in `docs/canon/source-of-truth.md` that point to old locations (e.g., `docs/02-API/` → `docs/api/`, `docs/03-DATABASE/` → `docs/database/`, `docs/00-STEERING/` → `docs/steering/`). Also update `docs/canon/README.md` to reflect verification marks added in Task 5.

- [ ] **Step 11: Update docs/guides/README.md**

Update `docs/guides/README.md` to reflect new structure and remove references to old paths. If it only contained navigation that's now in `docs/README.md`, mark it as consolidated.

- [ ] **Step 12: Commit**

```bash
git add -A docs/
git commit -m "docs(restructure): reorganize docs around canon with verified structure"
```

---

## Execution Summary

| Task | Phase | Parallel? | Depends On | Estimated Steps |
|------|-------|-----------|------------|-----------------|
| Task 1: Backend Audit | 1 | Yes (with 2,3) | — | 9 |
| Task 2: Admin Audit | 1 | Yes (with 1,3) | — | 6 |
| Task 3: App Audit | 1 | Yes (with 1,2) | — | 7 |
| Task 4: Reality Matrix | 2 | No | Tasks 1,2,3 | 6 |
| Task 5: Canon Update | 3a | Yes (with 6) | Task 4 | 8 |
| Task 6: Feature Registry | 3c | Yes (with 5) | Task 4 | 4 |
| Task 7: Docs Simplification | 3b | No | Tasks 5,6 | 12 |
| **Total** | | | | **52 steps** |

## Post-Completion

After all tasks complete:
1. Developer reviews `docs/audit/DECISIONS-PENDING.md` and makes business decisions
2. Canon gets final updates based on those decisions
3. Development can resume with verified documentation as foundation
