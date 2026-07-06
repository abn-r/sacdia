# Camporee Agenda Blocks Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Convert camporee events into a full agenda system with typed events, release timing, and optional schedule blocks assigned to club sections.

**Architecture:** Keep `camporee_events` as the canonical event/requisite/scoring record. Add camporee-level `agenda_visible_from` to gate agenda details in the app, and add child schedule block tables so a single event can run in multiple time windows with different club sections. Keep scoring based on `scoring_enabled + rubrics`; event type is classification, not the source of scoring truth.

**Tech Stack:** NestJS + Prisma/PostgreSQL backend, Next.js admin, Flutter app, markdown docs.

---

## Business Rules

1. Event type catalog must support at least: `scoring`, `recreational`, `rest`, `spiritual`, `devotional`, `general`.
2. A puntuable event still requires `scoring_enabled=true` and valid rubrics to count points.
3. Before `agenda_visible_from`, club app users can see event previews: title, type, requirements, max points/rubrics summary, but not full agenda schedule or blocks.
4. When `agenda_visible_from` is reached, app users can see complete agenda fields: day/time/venue/responsible/status and schedule blocks.
5. `agenda_visible_from = null` means agenda opens at camporee `start_date`.
6. Schedule blocks are optional. An event can have no blocks, one block, or many blocks.
7. Schedule blocks may assign zero or many `camporee_clubs`/`club_sections`; empty assignment means general block for all eligible sections.
8. Block assignment must not be required during event creation; it can be added later in edit.

## Tasks

### Task 1 — Backend schema and seed

**Files:**
- Modify: `sacdia-backend/prisma/schema.prisma`
- Create: `sacdia-backend/prisma/migrations/20260706120000_camporee_agenda_blocks/migration.sql`
- Modify docs mirror: `docs/database/schema.prisma`

**Changes:**
- Add `agenda_visible_from TIMESTAMPTZ NULL` to `local_camporees` and `union_camporees`.
- Add `camporee_event_schedule_blocks`.
- Add `camporee_event_schedule_block_assignments`.
- Seed/align event type codes: `scoring`, `recreational`, `rest`, `spiritual`, `devotional`, `general`.

### Task 2 — Backend contracts and service

**Files:**
- Modify: `sacdia-backend/src/camporees/dto/create-camporee.dto.ts`
- Modify: `sacdia-backend/src/camporees/dto/create-union-camporee.dto.ts`
- Modify: `sacdia-backend/src/camporees/camporees.service.ts`
- Modify: `sacdia-backend/src/camporee-events/dto/camporee-events.dto.ts`
- Modify: `sacdia-backend/src/camporee-events/camporee-events.service.ts`
- Modify: `sacdia-backend/src/camporee-events/camporee-events.controller.ts`
- Test: relevant camporee/camporee-events specs

**Changes:**
- Persist/update `agenda_visible_from`.
- Include schedule blocks in event list/detail responses.
- Add `PUT /camporee-events/:eventId/schedule-blocks` to replace blocks atomically.
- Add `GET /local-camporees/:id/events/preview` and union equivalent, with agenda gating.

### Task 3 — Admin integration

**Files:**
- Modify camporee local/union forms and API types.
- Modify event form/action/API types.
- Add schedule blocks editor component.

**Changes:**
- Add agenda release datetime in camporee creation/edit.
- Add event type selector in event create/edit.
- Add optional schedule block editor in event edit/create.

### Task 4 — App integration

**Files:**
- Modify camporee event entity/model/datasource/repository/providers/detail view.

**Changes:**
- Consume preview endpoint.
- Show preview before agenda release.
- Show schedule blocks when agenda is visible.

### Task 5 — Docs and verification

**Files:**
- Update `docs/features/camporees.md`
- Update `docs/features/camporee-events.md`
- Update `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- Update `docs/database/SCHEMA-REFERENCE.md`

**Verification:**
- `git diff --check`
- Backend Jest focused camporee/camporee-events tests
- Admin Vitest focused camporee event/form tests
- Flutter focused camporee datasource/repository tests
- Do not run builds.
