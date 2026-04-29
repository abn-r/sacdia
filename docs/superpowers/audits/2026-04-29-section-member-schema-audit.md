# Audit 8.4-A — Schema validation Neon dev (2026-04-29)

**Connection**: `neonctl connection-string development --project-id wispy-hall-32797215`
**Date executed**: 2026-04-29
**Spec reference**: `docs/superpowers/specs/2026-04-29-clasificacion-seccion-miembro-design.md` §5

## Resumen ejecutivo

| ID  | Ítem                                  | Estado    | Tabla/columna real                                       | Acción                                                                 |
|-----|---------------------------------------|-----------|----------------------------------------------------------|------------------------------------------------------------------------|
| A1  | members.member_id INTEGER             | DEVIATION | No existe tabla `members`. Entidad miembro = `enrollments.enrollment_id` (INTEGER) + `users.user_id` (UUID) | FK en `member_rankings` usar `enrollment_id INTEGER REFERENCES enrollments(enrollment_id)` |
| A2  | members.member_status existe          | MISSING   | No existe `member_status`. `enrollments` tiene `active BOOLEAN` + `investiture_status` enum (IN_PROGRESS, INVESTIDO) | Fase 1 filtra por `active = true`; no se necesita migration de ADD COLUMN |
| A3  | club_sections.club_section_id INTEGER | CONFIRMED | `club_section_id` INTEGER                                | Sin cambio — usar `INTEGER REFERENCES club_sections(club_section_id)` |
| A4  | member_class_progress existe          | DEVIATION | No existe. Tabla real: `class_module_progress` (cols: `user_id` UUID, `enrollment_id` INTEGER, `module_id` INTEGER, `active` BOOLEAN, sin `year_id` directo) | `ClassScoreService` consulta `class_module_progress` unido a `enrollments` vía `enrollment_id` para filtrar por `ecclesiastical_year_id` |
| A5  | evidence_attendance per-member        | MISSING   | No existe tabla per-member de asistencia a evidencias. `evidence_files` es a nivel sección/módulo, no per-member | `EvidenceScoreService` bloqueado: retorna NULL en Fase 1. Requiere revisión de negocio antes de Fase 2 |
| A6  | investitures per-member               | DEVIATION | No existe `investitures` ni `member_investitures`. Datos de investidura viven en `enrollments.investiture_status` (enum: IN_PROGRESS / INVESTIDO) + `investiture_validation_history.enrollment_id` | `InvestitureScoreService` usa `enrollments WHERE investiture_status = 'INVESTIDO'` como señal binaria (investido/no investido) |
| A7  | camporee_attendees / participants     | DEVIATION | No existe `camporee_attendees`. Existe `camporee_members` con `user_id UUID` + `status VARCHAR` (tabla sin datos aún en dev). Camporees de referencia: `local_camporees` y `union_camporees` (campo `ecclesiastical_year` INTEGER, sin FK formal) | `CamporeeScoreService` usa `camporee_members WHERE user_id = $userId AND status = 'attended'` |
| A8  | rol `member` en roles                 | CONFIRMED | Rol `member` existe: `role_id UUID 9567fef6-...`, `role_name='member'`, `role_category=CLUB`. Sin columna `code`. Permisos usan `permission_name` (no `name`). `role_id` es UUID | Seed grants usan `role_id` UUID real del rol `member`. `permission_name` en lugar de `name` |
| A9  | system_config columns                 | CONFIRMED | Columnas: `config_key`, `config_value`, `description`, `config_type`, `updated_at`. Sin columna `id` explícita | INSERT usa `ON CONFLICT (config_key)` — correcto |
| A10 | years vs ecclesiastical_years         | CONFIRMED | `years` no existe. `ecclesiastical_years` existe con PK `year_id` INTEGER. Camporees usan campo `ecclesiastical_year` INTEGER (no FK formal, solo valor referencial) | FK en tablas nuevas: `year_id INTEGER REFERENCES ecclesiastical_years(year_id)` |
| A11 | investiture_requirements              | MISSING   | No existe. Solo existen `investiture_config` (fechas/config por LF+año) e `investiture_validation_history` (audit log). Sin tabla de elegibilidad de investiduras | `InvestitureScoreService` retorna score binario (INVESTIDO=100, IN_PROGRESS=0, sin enrollment=NULL). `eligible_count` no se puede calcular |

`<state>` ∈ { `CONFIRMED`, `DEVIATION`, `MISSING` }.

---

## Detalle por ítem

### A1 — `members.member_id` type

**Query**:
```sql
SELECT data_type FROM information_schema.columns
  WHERE table_name='members' AND column_name='member_id';
```

**Output**:
```
 data_type
-----------
(0 rows)
```

**Probe adicional** (tabla de miembros real):
```sql
SELECT column_name, data_type FROM information_schema.columns
  WHERE table_name='enrollments' ORDER BY ordinal_position;
SELECT column_name, data_type FROM information_schema.columns
  WHERE table_name='users' ORDER BY ordinal_position;
```

**Output probe**:
```
-- enrollments:
enrollment_id           | integer
user_id                 | uuid
class_id                | integer
ecclesiastical_year_id  | integer
investiture_status      | USER-DEFINED (investiture_status_enum)
active                  | boolean
...

-- users:
user_id                 | uuid
name                    | character varying
...
```

**Conclusión**: DEVIATION. La tabla `members` no existe en el schema de Neon dev. El concepto de "miembro" en SACDIA está representado por dos entidades relacionadas:
- `users` (`user_id UUID`) — identidad del usuario
- `enrollments` (`enrollment_id INTEGER`, FK `user_id UUID`, FK `class_id INTEGER`, FK `ecclesiastical_year_id INTEGER`) — inscripción del usuario a una clase de un año

El `enrollment_id` (INTEGER) es la entidad que mejor representa "un miembro en un año" — ya contiene el año, la clase (que define el tipo de club), y el estado de investidura.

**Acción**: Las FKs en `member_rankings` y `section_rankings` deben referenciar `enrollments(enrollment_id)` en lugar de `members(member_id)`. El campo se renombra de `member_id` a `enrollment_id` en las tablas nuevas. Todos los calculadores reciben `enrollmentId` como parámetro, y acceden a `user_id` / `ecclesiastical_year_id` / `class_id` (→ `club_type_id` vía `classes`) vía join a `enrollments`.

---

### A2 — `members.member_status` existe

**Query**:
```sql
SELECT column_name, data_type, udt_name FROM information_schema.columns
  WHERE table_name='members' AND column_name='member_status';
```

**Output**:
```
 column_name | data_type | udt_name
-------------+-----------+----------
(0 rows)
```

**Probe adicional** (columnas de estado en la entidad real `enrollments`):
```sql
SELECT column_name, data_type, udt_name FROM information_schema.columns
  WHERE table_name='enrollments'
    AND (column_name ILIKE '%status%' OR column_name ILIKE '%active%' OR column_name ILIKE '%state%');
```

**Output probe**:
```
    column_name     |  data_type   |        udt_name
--------------------+--------------+-------------------------
 investiture_status | USER-DEFINED | investiture_status_enum
 advanced_status    | boolean      | bool
 active             | boolean      | bool
```

**Valores reales de `investiture_status`**:
```
 investiture_status
--------------------
 IN_PROGRESS
 INVESTIDO
```

**Valores de `active`**: solo `true` presente en datos de desarrollo.

**Conclusión**: MISSING (en el sentido de que `member_status` tal como se especificó no existe). Sin embargo, el equivalente funcional existe: `enrollments.active BOOLEAN` indica si la inscripción está activa. No hay valor `'active'` como string enum — es booleano.

**Acción**: Fase 1 filtra miembros activos con `WHERE enrollments.active = true`. No se requiere ninguna migration de `ADD COLUMN member_status` — el campo booleano `active` cumple la misma función. Actualizar spec §5: el filtro de "miembro activo" es `enrollments.active = true`.

---

### A3 — `club_sections.club_section_id` type

**Query**:
```sql
SELECT data_type FROM information_schema.columns
  WHERE table_name='club_sections' AND column_name='club_section_id';
```

**Output**:
```
 data_type
-----------
 integer
(1 row)
```

**Conclusión**: CONFIRMED. `club_sections.club_section_id` es INTEGER como asumía el spec.

**Acción**: Sin cambio. Usar `INTEGER REFERENCES club_sections(club_section_id)` en las FKs de `member_rankings` y `section_rankings`.

**Columns adicionales relevantes de `club_sections`**: `club_type_id INTEGER`, `main_club_id INTEGER`, `active BOOLEAN`, `name TEXT`.

---

### A4 — `member_class_progress` existe

**Query**:
```sql
SELECT to_regclass('public.member_class_progress');
SELECT column_name, data_type FROM information_schema.columns
  WHERE table_name='member_class_progress' ORDER BY ordinal_position;
```

**Output**:
```
 to_regclass
-------------
 (null)
(1 row)

 column_name | data_type
-------------+-----------
(0 rows)
```

**Probe** (tablas relacionadas con progreso de clase):
```sql
-- class_module_progress:
module_progress_id | integer
user_id            | uuid
class_id           | integer
module_id          | integer
score              | double precision
active             | boolean
created_at         | timestamp with time zone
modified_at        | timestamp with time zone
enrollment_id      | integer

-- class_section_progress:
section_progress_id | integer
user_id             | uuid
class_id            | integer
module_id           | integer
section_id          | integer
score               | double precision
evidences           | jsonb
active              | boolean
status              | USER-DEFINED
enrollment_id       | integer
...
```

**FKs de `class_module_progress`**:
```
class_id      → classes(class_id)
user_id       → users(user_id)
enrollment_id → enrollments(enrollment_id)
```

El año se accede vía `enrollment_id → enrollments.ecclesiastical_year_id`.

**Conclusión**: DEVIATION. La tabla real se llama `class_module_progress` (no `member_class_progress`). Usa `user_id UUID` como identificador del usuario y `enrollment_id INTEGER` como link al enrollment del año. No tiene columna `year_id` directa — el año se obtiene vía JOIN a `enrollments.ecclesiastical_year_id`. No tiene columna `status` con valor `'completed'` — tiene `active BOOLEAN` y `score NUMERIC`.

**Acción**: `ClassScoreService` usa `class_module_progress` con JOIN a `enrollments` para filtrar por año. El "completed" es `active = true AND score IS NOT NULL` (o score > 0 — a definir en implementación). Nótese también `class_section_progress` con `status USER-DEFINED` y `active` — podría ser más apropiado para contar "secciones completadas". A resolver en Task 2 (implementación de servicios).

---

### A5 — `evidence_attendance` per-member

**Query**:
```sql
SELECT to_regclass('public.evidence_attendance');
SELECT column_name FROM information_schema.columns
  WHERE table_name='evidence_attendance' ORDER BY ordinal_position;
```

**Output**:
```
 to_regclass
-------------
 (null)
(1 row)

 column_name
-------------
(0 rows)
```

**Probe** (tablas de evidencia existentes):
```
-- evidence_files:
evidence_file_id, section_record_id, file_url, file_name, file_type,
uploaded_by_id (uuid), uploaded_at, active, section_progress_id, user_honor_id

-- annual_folder_evidences:
evidence_id (uuid), annual_folder_id (uuid), section_id (uuid),
file_url, file_name, uploaded_by (uuid), notes, ...

-- requirement_evidence:
evidence_id (integer), progress_id (integer), evidence_type USER-DEFINED,
url, filename, mime_type, file_size, active, ...
```

**Conclusión**: MISSING. No existe ninguna tabla `evidence_attendance` que registre asistencia de un miembro (usuario) a eventos de evidencia. Las tablas de evidencia existentes son a nivel de archivos adjuntos de progreso de módulo (`evidence_files`), carpetas anuales (`annual_folder_evidences`), o requisitos de honor (`requirement_evidence`). Ninguna representa "el miembro X asistió a la evidencia Y del año Z".

**Acción**: `EvidenceScoreService.calculate()` retorna NULL para todos los miembros en Fase 1. El peso de evidencia se redistribuye a las otras señales disponibles vía la política de redistribución de NULLs del composite. Bloqueo documentado: requiere decisión de negocio sobre qué constituye "asistencia a evidencia" en SACDIA antes de implementar en Fase 2. Candidato a nueva tabla en migration futura o alternativa vía `annual_folder_section_evaluations`.

---

### A6 — investitures per-member

**Query**:
```sql
SELECT to_regclass('public.investitures'), to_regclass('public.member_investitures');
SELECT table_name, column_name FROM information_schema.columns
  WHERE table_name IN ('investitures','member_investitures') ORDER BY table_name, ordinal_position;
```

**Output**:
```
 to_regclass | to_regclass
-------------+-------------
 (null)      | (null)
(1 row)

 table_name | column_name
------------+-------------
(0 rows)
```

**Probe** (tablas de investidura existentes):
```
-- investiture_config: config_id, local_field_id, ecclesiastical_year_id, submission_deadline,
--   investiture_date, active
-- investiture_validation_history: history_id, enrollment_id, action USER-DEFINED,
--   performed_by (uuid), comments, created_at
-- enrollments.investiture_status: investiture_status_enum (IN_PROGRESS | INVESTIDO)
-- enrollments.investiture_date, enrollments.validated_by, enrollments.validated_at
```

**Conclusión**: DEVIATION. No existen tablas `investitures` ni `member_investitures`. El estado de investidura per-member vive en `enrollments.investiture_status` (enum: `IN_PROGRESS`, `INVESTIDO`) con historial de validación en `investiture_validation_history`. El modelo es binario (investido o no) a nivel de enrollment anual — no hay "múltiples investiduras" por año.

**Acción**: `InvestitureScoreService` cambia de modelo (achieved_count / eligible_count) a señal binaria:
- `investiture_status = 'INVESTIDO'` → score = 100
- `investiture_status = 'IN_PROGRESS'` → score = 0
- Sin enrollment para el año → score = NULL (redistribuye peso)

El `eligible_count` del diseño original no aplica — A11 (abajo) confirma que no existe tabla de requisitos de investidura.

---

### A7 — camporee_attendees / camporee_participants

**Query**:
```sql
SELECT to_regclass('public.camporee_attendees'), to_regclass('public.camporee_participants');
```

**Output**:
```
 to_regclass | to_regclass
-------------+-------------
 (null)      | (null)
(1 row)
```

**Probe** (tablas camporee existentes):
```
-- camporee_members: camporee_member_id (integer), camporee_id (integer),
--   camporee_type (varchar), user_id (uuid), club_name, local_field_id (integer),
--   insurance_verified, insurance_id, active, status (varchar),
--   union_camporee_id (integer), approved_by, rejected_by, rejection_reason

-- camporee_clubs: camporee_club_id, camporee_id, camporee_type, club_id,
--   local_field_id, active, club_section_id, registered_by, status, ...

-- local_camporees: local_camporee_id, ..., ecclesiastical_year (integer), active
-- union_camporees: union_camporee_id, ..., ecclesiastical_year (integer), union_id, active
```

**Valores de `camporee_members.status`** (vacío en dev, no hay data aún):
```
 status
--------
(0 rows)
```

**Conclusión**: DEVIATION. No existen `camporee_attendees` ni `camporee_participants`. La tabla per-member es `camporee_members` con `user_id UUID`. El campo de año en camporees es `ecclesiastical_year` INTEGER (referencia informal, sin FK formal a `ecclesiastical_years`). `camporee_type` VARCHAR indica si es local o union (o podría ser el tipo de club). Sin datos en dev para validar valores de `status`.

**Acción**: `CamporeeScoreService` usa `camporee_members WHERE user_id = $userUuid AND status = 'approved'` (valor a confirmar en staging con datos reales). El `camporee_id` debe cruzarse con `local_camporees.ecclesiastical_year = yearId` y `union_camporees.ecclesiastical_year = yearId`. La FK del año no es formal — se filtra por valor entero del año activo. Asumir `status = 'approved'` como "asistió" hasta confirmar con datos.

---

### A8 — rol `member` en roles

**Query**:
```sql
SELECT role_id, code, name FROM roles WHERE code = 'member' OR name ILIKE '%member%';
```

**Output**:
```
-- roles table has no 'code' column. Correct query:
SELECT role_id, role_name, role_category FROM roles WHERE role_name = 'member';
```

**Output corregido**:
```
               role_id                | role_name | role_category
--------------------------------------+-----------+---------------
 9567fef6-8091-494a-ac1c-fb3716ed2091 | member    | CLUB
(1 row)
```

**Nota adicional** — `roles` no tiene columna `code`. Identificador es `role_name`. El `role_id` es UUID (no INTEGER). La tabla `permissions` usa `permission_name` (no `name`) como identificador de texto. `role_permissions` vincula `role_id UUID` con `permission_id UUID`.

**Conclusión**: CONFIRMED (rol existe). DEVIATION (estructura diferente a lo asumido): `role_id` es UUID, no hay columna `code`, y los permisos usan `permission_name` no `name`.

**Acción**: Seed grants en `role_permissions` usan el UUID literal `9567fef6-8091-494a-ac1c-fb3716ed2091` para el rol `member`. La columna de INSERT en `permissions` es `permission_name`, no `name`. Ajustar los INSERT del archivo 3 de migration.

---

### A9 — system_config column names

**Query**:
```sql
SELECT column_name FROM information_schema.columns
  WHERE table_name='system_config' ORDER BY ordinal_position;
```

**Output**:
```
 column_name
--------------
 config_key
 config_value
 description
 config_type
 updated_at
(5 rows)
```

**Sample rows**:
```
             config_key              | config_value | config_type
-------------------------------------+--------------+-------------
 investiture.min_approval_percentage | 80           | int
 investiture.min_monthly_reports     | 10           | int
 reports.auto_generate_day           | 5            | int
 reports.auto_generate_enabled       | true         | boolean
 membership.pending_timeout_days     | 8            | number
```

**Conclusión**: CONFIRMED. Las columnas son `config_key`, `config_value`, `config_type` — exactamente como detectó el audit de 8.4-C. La columna `description` también existe (no mencionada en spec). `updated_at` pero sin `created_at`.

**Acción**: Los INSERT de `system_config` del spec §4.5 son correctos: `(config_key, config_value, config_type)`. Agregar `description` si se quiere documentar el propósito de cada key.

---

### A10 — `years` vs `ecclesiastical_years`

**Query**:
```sql
SELECT to_regclass('public.years'), to_regclass('public.ecclesiastical_years');
SELECT column_name FROM information_schema.columns
  WHERE table_name='ecclesiastical_years' ORDER BY ordinal_position;
```

**Output**:
```
 to_regclass |   to_regclass
-------------+-----------------
 (null)      | ecclesiastical_years
(1 row)

 column_name
-------------
 year_id
 start_date
 end_date
 active
 modified_at
 created_at
(6 rows)
```

**Nota sobre camporees**: `local_camporees.ecclesiastical_year` e `union_camporees.ecclesiastical_year` son INTEGER (referencia informal al `year_id` de `ecclesiastical_years`, sin FK formal declarada).

**Conclusión**: CONFIRMED (`ecclesiastical_years` existe, `years` no existe). PK de la tabla es `year_id INTEGER`. El spec ya usaba `year_id` como nombre del campo FK — esto es correcto, pero la tabla referenciada debe ser `ecclesiastical_years(year_id)`.

**Acción**: Las 3 tablas nuevas (`member_rankings`, `section_rankings`, `member_ranking_weights`) deben usar `year_id INTEGER REFERENCES ecclesiastical_years(year_id)`. El campo de año en las tablas de camporees es `ecclesiastical_year` INTEGER sin FK formal — en los calculadores filtrar por valor entero del `year_id` activo.

---

### A11 — `investiture_requirements`

**Query**:
```sql
SELECT to_regclass('public.investiture_requirements');
SELECT column_name FROM information_schema.columns
  WHERE table_name='investiture_requirements' ORDER BY ordinal_position;
```

**Output**:
```
 to_regclass
-------------
 (null)
(1 row)

 column_name
-------------
(0 rows)
```

**Probe** (todas las tablas de investidura):
```
-- Solo existen:
investiture_config
investiture_validation_history
```

**Conclusión**: MISSING. No existe tabla `investiture_requirements`. La elegibilidad de investidura no está modelada como requisitos discretos — es un proceso de validación manual (ver `investiture_validation_history.action USER-DEFINED`) sobre el `enrollments.investiture_status`.

**Acción**: `InvestitureScoreService` adopta modelo binario (ver A6 arriba). El concepto de `eligible_count` del spec §7.3 no aplica en Fase 1. Score = 100 si `INVESTIDO`, 0 si `IN_PROGRESS`, NULL si sin enrollment del año. El peso de investidura se redistribuye proporcionalmente si NULL (mismo mecanismo que otros NULLs). Documentar para Fase 2: si la dirección define requisitos de investidura per-club-type, crear tabla `investiture_requirements` con migration dedicada.

---

## Tabla de correcciones requeridas en migrations

| Migration | Corrección requerida |
|-----------|---------------------|
| `member_rankings_schema.sql` | FK `enrollment_id INTEGER REFERENCES enrollments(enrollment_id)` en lugar de `member_id INTEGER REFERENCES members(member_id)` |
| `member_rankings_schema.sql` | FK `year_id INTEGER REFERENCES ecclesiastical_years(year_id)` (tabla correcta) |
| `member_rankings_seeds.sql` | `INSERT INTO permissions (permission_name, ...)` en lugar de `(name, ...)` |
| `member_rankings_seeds.sql` | `role_id` de `member` = UUID `9567fef6-8091-494a-ac1c-fb3716ed2091` |
| Calculadores | `ClassScoreService`: usa `class_module_progress` con JOIN a `enrollments` |
| Calculadores | `EvidenceScoreService`: retorna NULL (bloqueado en Fase 1) |
| Calculadores | `InvestitureScoreService`: modelo binario INVESTIDO/IN_PROGRESS |
| Calculadores | `CamporeeScoreService`: usa `camporee_members` con `user_id UUID` |

## Tabla de open questions post-audit

| # | Pregunta | Impacto |
|---|----------|---------|
| OQ-A4a | ¿`class_section_progress.status` con valor `'completed'` define una sección completada? ¿O `active = true` con `score > 0` en `class_module_progress`? | Denominador de `ClassScoreService` |
| OQ-A7a | ¿`camporee_members.status = 'approved'` significa "asistió"? ¿O existe otro valor? (sin datos en dev) | Numerador de `CamporeeScoreService` |
| OQ-A7b | ¿`camporee_members.camporee_id` referencia `local_camporees.local_camporee_id` o `union_camporees.union_camporee_id`? ¿El campo `camporee_type` distingue? | JOIN en `CamporeeScoreService` |
| OQ-A6a | ¿El score binario de investidura (INVESTIDO=100, IN_PROGRESS=0) es aceptable como señal? ¿O se prefiere retornar NULL si no hay datos suficientes? | Decisión de negocio en `InvestitureScoreService` |
