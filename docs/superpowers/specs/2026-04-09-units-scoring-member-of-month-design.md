# Units Scoring & Member of the Month — Design Spec

**Date:** 2026-04-09
**Status:** Draft
**Author:** SACDIA Team
**Affects:** sacdia-backend, sacdia-admin, sacdia-app

---

## Overview

Extend the existing units system with configurable scoring categories (hierarchical inheritance from Division → Union → Local Field), dynamic weekly point registration, and automated monthly "Member of the Month" selection per club section with notifications.

The current units module supports CRUD for units, unit members, and weekly records with fixed fields (attendance, punctuality, points). This design replaces the fixed scoring model with a flexible, hierarchically-configured category system while preserving backward compatibility with existing data.

---

## Current State

- Full units CRUD exists (backend, admin, Flutter)
- Weekly records with fixed fields: `attendance`, `punctuality`, `points`
- Unit members management (add/remove)
- Permissions: `units:read`, `units:create`, `units:update`, `units:delete`
- Counselors: `advisor_id` + `substitute_advisor_id` (stays as-is)
- No scoring category configuration exists
- No "Member of the Month" feature exists
- No hierarchical inheritance pattern for organizational configuration exists in the codebase yet

---

## Section 1: Schema Changes (Prisma)

### 1.1 New Models

#### `scoring_categories` — Configurable point categories

Represents a single scoring dimension (e.g., "Puntualidad", "Uniforme", "Biblia") created at a specific organizational level.

```prisma
model scoring_categories {
  scoring_category_id Int      @id @default(autoincrement())
  name                String   @db.VarChar(100)
  max_points          Int      // max points per session for this category
  origin_level        origin_level_enum
  origin_id           Int      // ID of the division, union, or local field that created it
  active              Boolean  @default(true)
  created_at          DateTime @default(now())
  modified_at         DateTime @updatedAt

  // Relations
  weekly_record_scores weekly_record_scores[]

  // Indexes
  @@index([origin_level, origin_id])
  @@map("scoring_categories")
}

enum origin_level_enum {
  DIVISION
  UNION
  LOCAL_FIELD
}
```

**Design decisions:**
- `origin_level` + `origin_id` together identify who created the category. This polymorphic FK pattern avoids three nullable FK columns.
- `max_points` enforces a ceiling per category per session — validated both backend and frontend.
- Soft-delete via `active = false` rather than physical deletion, since historical weekly_record_scores reference these categories.

#### `weekly_record_scores` — Points per category within a weekly record

```prisma
model weekly_record_scores {
  score_id    Int @id @default(autoincrement())
  record_id   Int
  category_id Int
  points      Int @default(0)

  // Relations
  weekly_record    weekly_records     @relation(fields: [record_id], references: [record_id], onDelete: Cascade)
  scoring_category scoring_categories @relation(fields: [category_id], references: [scoring_category_id])

  // Constraints
  @@unique([record_id, category_id])
  @@map("weekly_record_scores")
}
```

**Design decisions:**
- Composite unique on `[record_id, category_id]` prevents duplicate scores for the same category in a single weekly record.
- `onDelete: Cascade` on `record_id` — if a weekly record is deleted, its scores are removed too.
- No cascade on `category_id` — categories are soft-deleted, not physically removed.

#### `member_of_month` — Monthly recognition history

```prisma
model member_of_month {
  member_of_month_id Int      @id @default(autoincrement())
  club_section_id    Int
  user_id            String   @db.Uuid
  month              Int      // 1-12
  year               Int
  total_points       Int
  notified           Boolean  @default(false)
  created_at         DateTime @default(now())

  // Relations
  club_section club_sections @relation(fields: [club_section_id], references: [club_section_id])
  user         users         @relation(fields: [user_id], references: [user_id])

  // Constraints
  @@unique([club_section_id, user_id, month, year])
  @@map("member_of_month")
}
```

**Design decisions:**
- Unique on `[club_section_id, user_id, month, year]` allows multiple winners (ties) for the same section/month/year — each tied user gets their own row.
- `notified` flag tracks push notification delivery status for retry logic.
- `total_points` is stored denormalized at selection time — serves as a historical record even if underlying scores change.

### 1.2 Modifications to Existing Models

#### `weekly_records`

```prisma
model weekly_records {
  // ... existing fields remain ...
  attendance  Int      @default(0)
  punctuality Int      @default(0)
  points      Int      @default(0) // becomes denormalized cache

  // New relation
  weekly_record_scores weekly_record_scores[]
}
```

**Changes:**
- Keep `attendance` (Int), `punctuality` (Int), `points` (Int) for backward compatibility.
- `points` field becomes a **denormalized cache** — updated automatically when scores are saved: `points = SUM(weekly_record_scores.points)`.
- Update logic: every time `weekly_record_scores` are created/updated for a record, recalculate and persist the `points` sum in the parent `weekly_records` row within the same transaction.
- Note: `user_id` is `String @db.Uuid`, `week` is `Int` (1-52), unique constraint on `[user_id, week]`.

#### `unit_members` — Constraint change

**Current behavior:** A global UNIQUE constraint on `user_id` prevents a user from being in multiple units system-wide.

**New behavior:**
- Remove the global UNIQUE constraint on `user_id` in the schema.
- Add **service-layer validation**: a user can only be in ONE active unit per `club_section`. This allows a user to be in units across different club sections (e.g., Conquistadores in one club and Aventureros in another) while preventing duplicate membership within a section.
- Resolution path: the unit's `club_section_id` is used to determine which section the unit belongs to. When adding a member, query: `SELECT * FROM unit_members um JOIN units u ON um.unit_id = u.unit_id WHERE um.user_id = ? AND u.club_section_id = ? AND um.active = true`.

### 1.3 Data Migration

Migration script must:

1. **Create two legacy categories at the division level** for each existing division:
   - "Asistencia" (`max_points: 1`, `origin_level: DIVISION`)
   - "Puntualidad" (`max_points: 1`, `origin_level: DIVISION`)

2. **Migrate existing weekly records:**
   - For each `weekly_records` row with `attendance > 0`, create a `weekly_record_scores` entry with `category_id` = "Asistencia" category, `points = attendance`.
   - For each `weekly_records` row with `punctuality > 0`, create a `weekly_record_scores` entry with `category_id` = "Puntualidad" category, `points = punctuality`.

3. **Recalculate `points`:** Verify that existing `points` values are consistent with the new scores. If they include manual adjustments beyond attendance/punctuality, create a third legacy category "Puntos Extra" to capture the difference.

4. **Migration is additive** — no columns are removed from `weekly_records`. The old `attendance` and `punctuality` fields remain but are no longer written to by new code.

---

## Section 2: Backend API — New Endpoints

### 2.1 Scoring Categories (Hierarchical Configuration)

The hierarchical inheritance model follows the organizational structure: Division → Union → Local Field. Each level inherits categories from above and can add its own.

#### Division Level (admin/super_admin only)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/divisions/scoring-categories` | List all division-level categories |
| `POST` | `/divisions/scoring-categories` | Create a mandatory category |
| `PATCH` | `/divisions/scoring-categories/:id` | Update a category |
| `DELETE` | `/divisions/scoring-categories/:id` | Soft-delete (set `active = false`) |

**Authorization:** `admin` or `super_admin` role only.

**POST/PATCH request body:**
```json
{
  "name": "Uniforme",
  "max_points": 5
}
```

**GET response:**
```json
[
  {
    "scoring_category_id": 1,
    "name": "Puntualidad",
    "max_points": 5,
    "origin_level": "DIVISION",
    "origin_id": 1,
    "active": true,
    "readonly": false
  }
]
```

#### Union Level (admin/super_admin + union directors)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/unions/:unionId/scoring-categories` | List union categories + inherited division categories (readonly) |
| `POST` | `/unions/:unionId/scoring-categories` | Create a category for this union |
| `PATCH` | `/unions/:unionId/scoring-categories/:id` | Update own category only |
| `DELETE` | `/unions/:unionId/scoring-categories/:id` | Soft-delete own category only |

**Authorization:** `admin`, `super_admin`, or user with director role in the specified union.

**GET response merge logic:**
```
division_categories (readonly: true) + union_own_categories (readonly: false)
```

**PATCH/DELETE guard:** Service layer verifies that the category's `origin_level = UNION` and `origin_id = unionId` before allowing mutation. Returns `403 Forbidden` if attempting to modify an inherited category.

#### Local Field Level (admin/super_admin + local field directors)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/local-fields/:fieldId/scoring-categories` | List all categories (division readonly + union readonly + own editable) |
| `POST` | `/local-fields/:fieldId/scoring-categories` | Create a category for this local field |
| `PATCH` | `/local-fields/:fieldId/scoring-categories/:id` | Update own category only |
| `DELETE` | `/local-fields/:fieldId/scoring-categories/:id` | Soft-delete own category only |

**Authorization:** `admin`, `super_admin`, or user with director role in the specified local field.

**GET response merge logic:**
```
division_categories (readonly: true, origin_badge: "Division")
+ union_categories (readonly: true, origin_badge: "Union")
+ own_categories (readonly: false, origin_badge: "Campo Local")
```

**Resolution chain for GET:**
1. Determine the local field's parent union and the union's parent division from the organizational hierarchy.
2. Query `scoring_categories` WHERE (`origin_level = DIVISION` AND `origin_id = divisionId`) OR (`origin_level = UNION` AND `origin_id = unionId`) OR (`origin_level = LOCAL_FIELD` AND `origin_id = fieldId`).
3. Mark each category with `readonly: boolean` based on whether it belongs to the requesting level.

**Response shape for each category:**
```json
{
  "scoring_category_id": 5,
  "name": "Biblia",
  "max_points": 10,
  "origin_level": "LOCAL_FIELD",
  "origin_id": 3,
  "origin_badge": "Campo Local",
  "active": true,
  "readonly": false
}
```

### 2.2 Weekly Records — Adaptation

The existing weekly records endpoints are adapted to accept dynamic scoring categories.

#### Create Weekly Record

**`POST /clubs/:clubId/units/:unitId/weekly-records`**

**Request body (new format):**
```json
{
  "user_id": "uuid-string",
  "week": 14,
  "attendance": 1,
  "scores": [
    { "category_id": 1, "points": 5 },
    { "category_id": 2, "points": 3 },
    { "category_id": 7, "points": 10 }
  ]
}
```

**Validation rules:**
1. Every `category_id` in `scores` must correspond to an **active** category available to the club's local field (resolved via the merge chain).
2. Each `points` value must be `>= 0` and `<= category.max_points`.
3. The `points` field on `weekly_records` is auto-calculated: `SUM(scores[].points)`.
4. `attendance` and `punctuality` fields are still accepted as `Int` and stored directly on `weekly_records`.

**Transaction:**
1. Create `weekly_records` row with calculated `points`.
2. Bulk-create `weekly_record_scores` rows for each score entry.
3. Both operations in a single Prisma transaction.

#### Update Weekly Record

**`PATCH /clubs/:clubId/units/:unitId/weekly-records/:recordId`**

Same `scores` array format. Uses upsert logic on `weekly_record_scores` (unique on `[record_id, category_id]`):
- If score exists for category → update points.
- If score doesn't exist → create.
- Categories not included in the payload are left unchanged (partial update).
- Recalculate `points` on parent `weekly_records` after update.

#### Get Weekly Records

**`GET /clubs/:clubId/units/:unitId/weekly-records`**

**Response (enriched):**
```json
{
  "records": [
    {
      "record_id": 100,
      "week": 14,
      "member": { "user_id": "uuid-string", "name": "Juan Perez" },
      "attendance": 1,
      "points": 18,
      "scores": [
        { "category_id": 1, "category_name": "Puntualidad", "points": 5, "max_points": 5 },
        { "category_id": 2, "category_name": "Uniforme", "points": 3, "max_points": 5 },
        { "category_id": 7, "category_name": "Biblia", "points": 10, "max_points": 10 }
      ]
    }
  ]
}
```

**Write permission:** Club directors + unit counselors (advisor/substitute) + unit captain. Resolved via `units:update` permission + role check in service layer.

### 2.3 Member of the Month

#### Get Current Member of the Month

**`GET /clubs/:clubId/sections/:sectionId/member-of-month`**

Returns the member(s) of the month for the current month/year. If no evaluation has run yet for the current month, returns `null`.

**Response:**
```json
{
  "month": 4,
  "year": 2026,
  "members": [
    {
      "user_id": "uuid-string",
      "name": "Juan Perez",
      "photo_url": "https://...",
      "total_points": 87
    }
  ]
}
```

Multiple entries in `members` array indicate a tie.

#### Get History

**`GET /clubs/:clubId/sections/:sectionId/member-of-month/history`**

**Query params:** `page` (default 1), `limit` (default 12)

**Response:**
```json
{
  "data": [
    {
      "month": 3,
      "year": 2026,
      "members": [
        { "user_id": "uuid-string", "name": "Juan Perez", "photo_url": "...", "total_points": 92 }
      ]
    },
    {
      "month": 2,
      "year": 2026,
      "members": [
        { "user_id": "uuid-string-2", "name": "Maria Lopez", "photo_url": "...", "total_points": 85 }
      ]
    }
  ],
  "pagination": { "page": 1, "limit": 12, "total": 5 }
}
```

#### Manual Evaluation Trigger

**`POST /clubs/:clubId/sections/:sectionId/member-of-month/evaluate`**

**Request body:**
```json
{
  "month": 3,
  "year": 2026
}
```

**Authorization:** Club directors only.

**Logic:** Same as the cron job (see below) but for a specific month/year/section. Useful for corrections or late evaluations.

#### Cron Job — Automated Monthly Evaluation

**Schedule:** Runs on the 1st of each month at 00:00 UTC.

**Algorithm:**
1. For each active `club_section`:
   a. Determine the week numbers that fall within the previous month (e.g., month 3 of 2026 → weeks 9-13 approximately). Use the year and month to calculate which ISO weeks correspond.
   b. Query: `SUM(wrs.points)` from `weekly_record_scores wrs` joined through `weekly_records wr` → `unit_members um` → `units u`, filtered by `u.club_section_id = sectionId` and `wr.week` within the calculated week range, grouped by `um.user_id`.
   c. Find the maximum total. Select all users with that maximum (handles ties).
   d. Insert into `member_of_month` — one row per winning user.
   e. If rows already exist for this section/month/year (idempotency), delete existing rows and re-insert (replace strategy within a transaction).

2. For each newly inserted `member_of_month` row:
   a. Send **in-app notification** to the elected member.
   b. Send **native push notification** (FCM) to the elected member.
   c. Send **in-app notification** to all club directors of the section's club.
   d. Mark `notified = true` after successful delivery.

**Idempotency:** Re-running the cron or manual trigger for the same month/year/section replaces previous results. This is done via a transaction: DELETE existing rows for that section/month/year, then INSERT new ones.

**Edge cases:**
- If no weekly records exist for the month → no member of the month is selected (no row inserted).
- If all members have 0 points → no member of the month is selected.
- If only one unit exists with one member → that member wins by default (if points > 0).

---

## Section 3: Admin Panel (sacdia-admin)

### 3.1 Scoring Categories Configuration

#### Division Page — New Route

**Route:** `/dashboard/settings/scoring-categories`

**Visibility:** Only for `admin` / `super_admin` users.

**UI components:**
- Page header: "Categorias de Puntuacion"
- Data table with columns: Name, Max Points, Status (active/inactive badge), Actions
- "Nueva Categoria" button → opens Dialog modal (per design system: CRUD create/edit = Dialog)
- Edit action → same Dialog modal pre-filled
- Delete action → AlertDialog confirmation (per design system)
- Status toggle in table row for quick active/inactive switch

**Dialog fields:**
- Name (text input, required, max 100 chars)
- Max Points (number input, required, min 1)

#### Union Page — New Tab

**Location:** Existing route `/dashboard/unions/[id]`, new tab "Categorias de Puntuacion"

**UI components:**
- Same data table structure as division page
- Inherited division categories shown with a `Badge` variant "secondary" labeled "Division" and rows are non-editable (no action buttons)
- Union's own categories are fully editable
- Visual separator or grouping between inherited and own categories (optional: group headers)

#### Local Field Page — New Tab

**Location:** Existing route `/dashboard/local-fields/[id]`, new tab "Categorias de Puntuacion"

**UI components:**
- Data table with three visual layers:
  - Division categories → `Badge` "Division" (readonly, secondary variant)
  - Union categories → `Badge` "Union" (readonly, secondary variant)
  - Local field's own categories → `Badge` "Campo Local" (editable, default variant)
- Only local field's own categories have edit/delete actions
- "Nueva Categoria" button creates categories at the local field level

### 3.2 Weekly Records Panel — Adaptation

**File:** `weekly-records-panel.tsx` (existing component)

**Current state:** Fixed columns for attendance, punctuality, points.

**New behavior:**
- On mount, fetch active scoring categories for the club's local field via `GET /local-fields/:fieldId/scoring-categories`.
- Render **dynamic columns** — one column per active category, with the category name as the column header.
- Each cell is an editable number input, constrained to `0..max_points` for that category.
- "Total" column at the end, calculated as `SUM` of all category scores, non-editable.
- "Attendance" and "Punctuality" columns remain as integer inputs (backward compatible).
- When saving a row, construct the `scores` array from the dynamic column values and send to the API.

**Column rendering logic:**
```
[Int: Attendance] + [Int: Punctuality] + [For each category: Number input (0..max_points)] + [Calculated: Total]
```

### 3.3 Member of the Month — Club View

**Location:** Within the club page (`/dashboard/clubs/[id]`), inside the section tab.

**Components:**

1. **Highlighted card** at the top of the section view:
   - Member photo (avatar), full name, total score
   - Gold/yellow accent styling to denote recognition
   - If tie: show all winners side by side (avatar group)
   - If no member of the month for current month: card is hidden (not an empty state)

2. **"Evaluar Mes" button:**
   - Visible only to club directors
   - Opens a Dialog with month/year selector (defaults to previous month)
   - On confirm, calls `POST .../member-of-month/evaluate`
   - Shows success toast with the winner's name

3. **"Ver Historial" link:**
   - Navigates to a sub-view or opens a sheet/dialog
   - Paginated table: Month/Year, Member Name, Photo, Score
   - Sorted by most recent first

---

## Section 4: Flutter App (sacdia-app)

### 4.1 Units List View Modification

**File:** `units_list_view.dart`

**Changes:**

Add a **"Miembro del Mes" card** above the units list:
- Positioned before the `ListView` of units, inside the same scrollable area (not a separate fixed header).
- Shows: member photo (circular avatar), full name, total score, and a small trophy/star icon.
- If there is a tie, display all winners in a horizontal carousel (swipeable) or an avatar stack with "+N" indicator.
- If no data exists for the current month (API returns `null`), the card is **not rendered at all** — no empty state, no placeholder.
- Tapping the card navigates to the Member of the Month history screen.

**Data fetching:**
- When the units list loads for a section, also fetch `GET /clubs/:clubId/sections/:sectionId/member-of-month` in parallel.
- Cache the result in the provider to avoid re-fetching on tab switches.

### 4.2 Unit Detail View — Points Adaptation

**File:** `unit_detail_view.dart`

**Current state:** Fixed +5/+1/-1/-5 buttons for point adjustment.

**New behavior:**

When registering or editing points for a member:
1. Fetch active categories for the club's local field (cached after first fetch).
2. Display one **row per category**:
   - Category name (label)
   - Points input: number stepper or slider, range `0` to `max_points`
   - Visual indicator of current value vs max (e.g., "3/5")
3. Total displayed at the bottom as a read-only calculated sum.
4. Submit sends the full `scores` array to the API.

**Atomic rule maintained:**
- When registering weekly points for a given week, either ALL members of the unit must have at least one score > 0, or ALL must have 0. This prevents partial data entry.
- UI enforcement: "Guardar" button validates this rule before submission. If violated, show an error snackbar: "Todos los miembros deben tener puntaje o ninguno."

**Permission enforcement:**
- Points registration UI is only shown to: club directors, unit counselors (advisor/substitute), and unit captain.
- Other members see the points in read-only mode.

### 4.3 Member of the Month History — New Screen

**New file:** `member_of_month_history_view.dart`

**Accessible from:** Tapping the "Miembro del Mes" card in the units list view.

**UI:**
- App bar title: "Miembro del Mes — Historial"
- Chronological list, most recent first
- Each item: month/year header, member photo (circular avatar), full name, total score
- Ties: multiple members listed under the same month/year header
- Infinite scroll pagination (fetch next page when scrolling near bottom)
- Empty state (if no history at all): "No hay datos de miembro del mes aun."

### 4.4 Push Notifications

**Integration:** Uses existing notification system + Firebase Cloud Messaging (FCM) for native push.

**Notification triggers (from cron or manual evaluation):**

1. **To elected member:**
   - Title: "Felicidades!"
   - Body: "Fuiste elegido Miembro del Mes de [section_name] en [club_name]"
   - Data payload: `{ type: "member_of_month", club_id, section_id, month, year }`
   - Tap action: navigate to member of month history screen

2. **To club directors:**
   - Title: "Miembro del Mes"
   - Body: "[member_name] fue elegido Miembro del Mes de [section_name] con [X] puntos"
   - Data payload: `{ type: "member_of_month_director", club_id, section_id, month, year }`
   - Tap action: navigate to the section's units list

**Delivery flow:**
1. Backend evaluation completes and inserts `member_of_month` rows.
2. For each row, backend creates an in-app notification record (existing notifications table).
3. Backend sends FCM push via existing push notification service.
4. On successful FCM delivery, set `member_of_month.notified = true`.
5. If FCM fails, leave `notified = false` for retry (retry mechanism can be a separate cron or manual re-trigger).

### 4.5 Providers — Changes

#### `UnitsNotifier` Adaptation

- Remove hardcoded attendance/punctuality/points field handling.
- Add `List<ScoringCategory> categories` to state, fetched once when loading unit data.
- Weekly record creation/update methods accept `List<Score>` instead of individual fields.
- `loadUnit()` fetches categories in parallel with unit data.

#### New State: `memberOfMonth`

- Add `MemberOfMonth? memberOfMonth` to the units list state (or a separate notifier if the state grows too large).
- Fetch on units list load: `GET /clubs/:clubId/sections/:sectionId/member-of-month`.
- Expose `fetchMemberOfMonthHistory(page)` for the history screen with pagination support.

---

## Section 5: Permissions & Business Rules

### 5.1 Permission Matrix

| Action | Who Can Perform |
|--------|-----------------|
| Create unit | Director, sub-director, secretario, secretario-tesorero |
| Update unit | Director, sub-director, secretario, secretario-tesorero |
| Delete unit (soft-delete) | Director only |
| Register weekly points | Club directors + unit counselors (advisor/substitute) + unit captain |
| Trigger member of month evaluation | Club directors only |
| Configure scoring categories (division) | admin / super_admin |
| Configure scoring categories (union) | admin / super_admin + union directors |
| Configure scoring categories (local field) | admin / super_admin + local field directors |
| View units and points | Any club member with `units:read` |
| View member of the month | Any club member with `units:read` |

### 5.2 Permission Implementation Strategy

Existing permissions (`units:create`, `units:update`, `units:delete`, `units:read`) are **kept as-is**. No new permission entries are created.

Additional granularity is resolved in the **service layer** by checking the user's role within the club or organization:

- **Unit deletion:** Requires `units:delete` permission AND `user.clubRole === 'director'`. Service rejects with `403` if user has the permission but is not a director.
- **Points registration:** Requires `units:update` permission AND user is one of: club director, unit counselor (advisor_id or substitute_advisor_id), or unit captain (capitan_id on the unit).
- **Member of month evaluation:** Requires `units:update` permission AND `user.clubRole === 'director'`.
- **Scoring category management:** Resolved by checking admin/super_admin role (division level) or director role at the appropriate organizational level (union/local field).

### 5.3 Business Rules

1. **One unit per section** — A member can only be in ONE active unit per club section. Validated in the service layer when adding a unit member. If the user is already in an active unit within the same section, the request is rejected with a `409 Conflict` and message: "El miembro ya pertenece a una unidad activa en esta seccion."

2. **Captain and secretary must be unit members** — When creating or updating a unit, the `capitan_id` and `secretario_id` (if set) must reference users who are already members of the unit (or being added in the same operation). Validated in service layer.

3. **Inherited categories are immutable** — A local field cannot edit or delete categories created at the union or division level. A union cannot edit or delete categories created at the division level. Enforced by checking `origin_level` and `origin_id` before any mutation.

4. **Monthly evaluation is idempotent** — Re-running the evaluation for the same month/year/section replaces previous results. Implemented as a DELETE + INSERT within a single transaction. This allows corrections without creating duplicate entries.

5. **Atomic points rule** — When registering weekly points for a session date, either ALL members of the unit must have points > 0 or ALL must have 0. This prevents counselors from partially entering data and ensures data consistency. Validated both in the Flutter UI (before submission) and in the backend service (before persisting).

6. **Category deactivation cascading** — When a category is deactivated (`active = false`), it no longer appears in the dynamic column list for new weekly records. However, existing weekly_record_scores referencing that category are preserved for historical accuracy. The category name still appears in historical record views.

7. **Points ceiling enforcement** — The `points` value in `weekly_record_scores` must be `>= 0` and `<= scoring_categories.max_points`. Validated in the backend service. Frontend enforces this with input constraints (min/max on number inputs).

---

## Appendix A: Entity Relationship Summary

```
divisions ──1:N──> scoring_categories (origin_level = DIVISION)
unions ──1:N──> scoring_categories (origin_level = UNION)
local_fields ──1:N──> scoring_categories (origin_level = LOCAL_FIELD)

scoring_categories ──1:N──> weekly_record_scores
weekly_records ──1:N──> weekly_record_scores

club_sections ──1:N──> member_of_month
users ──1:N──> member_of_month
```

## Appendix B: API Summary Table

| Method | Endpoint | Auth |
|--------|----------|------|
| `GET` | `/divisions/scoring-categories` | admin/super_admin |
| `POST` | `/divisions/scoring-categories` | admin/super_admin |
| `PATCH` | `/divisions/scoring-categories/:id` | admin/super_admin |
| `DELETE` | `/divisions/scoring-categories/:id` | admin/super_admin |
| `GET` | `/unions/:unionId/scoring-categories` | admin/super_admin, union directors |
| `POST` | `/unions/:unionId/scoring-categories` | admin/super_admin, union directors |
| `PATCH` | `/unions/:unionId/scoring-categories/:id` | admin/super_admin, union directors |
| `DELETE` | `/unions/:unionId/scoring-categories/:id` | admin/super_admin, union directors |
| `GET` | `/local-fields/:fieldId/scoring-categories` | admin/super_admin, local field directors |
| `POST` | `/local-fields/:fieldId/scoring-categories` | admin/super_admin, local field directors |
| `PATCH` | `/local-fields/:fieldId/scoring-categories/:id` | admin/super_admin, local field directors |
| `DELETE` | `/local-fields/:fieldId/scoring-categories/:id` | admin/super_admin, local field directors |
| `POST` | `/clubs/:clubId/units/:unitId/weekly-records` | directors, counselors, captain |
| `PATCH` | `/clubs/:clubId/units/:unitId/weekly-records/:recordId` | directors, counselors, captain |
| `GET` | `/clubs/:clubId/units/:unitId/weekly-records` | any club member |
| `GET` | `/clubs/:clubId/sections/:sectionId/member-of-month` | any club member |
| `GET` | `/clubs/:clubId/sections/:sectionId/member-of-month/history` | any club member |
| `POST` | `/clubs/:clubId/sections/:sectionId/member-of-month/evaluate` | directors only |

## Appendix C: Migration Checklist

- [ ] Create `origin_level_enum` enum in Prisma schema
- [ ] Create `scoring_categories` model
- [ ] Create `weekly_record_scores` model
- [ ] Create `member_of_month` model
- [ ] Add `weekly_record_scores` relation to `weekly_records`
- [ ] Add `member_of_month` relation to `club_sections` and `users`
- [ ] Modify `unit_members` unique constraint
- [ ] Write data migration for legacy attendance/punctuality categories
- [ ] Write data migration for existing weekly records → weekly_record_scores
- [ ] Verify points recalculation after migration
- [ ] Run migration on staging environment before production
