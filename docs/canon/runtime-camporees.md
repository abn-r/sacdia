# Runtime — Camporees (gestión de la entidad)

**Estado**: ACTIVE
**Autoridad rectora**: `docs/canon/source-of-truth.md`
**Tipo de documento**: runtime canonizado, documented-as-built
**Ámbito**: operaciones CRUD sobre la entidad `camporee` (crear, actualizar, desactivar, listar, leer). NO cubre attendance/registration/payments — esos comparten permisos cross-cutting `attendance:*` con actividades regulares

<!-- VERIFICADO contra código 2026-10-04: camporees.controller.ts tiene 46 handlers: 13 con permisos camporees:* (10 CRUD/lectura + section-registration GET + register_active_section + register) y 33 con attendance:* cross-cutting. Los módulos camporee-events/-scoring/-orders/-supplies/-venues/-staff/-event-templates tienen permisos y documentación propios. -->

---

## 1. Propósito

Canoniza las operaciones **CRUD** sobre la entidad camporee (crear, actualizar, eliminar, leer) como dominio propio con permisos `camporees:*`. Separa explícitamente:

- **Operation** (camporees:\*): CRUD de la entidad — alcance canonizado en este documento.
- **Attendance + Registration + Payments + Late approval** (attendance:\*): operaciones cross-cutting compartidas con actividades regulares — no se canonizan aquí; mantienen el patrón establecido de `attendance:manage`/`attendance:read`/`attendance:approve_late`.

La separación intencional evita fragmentación innecesaria (no crear `camporees:attendance:*`) mientras garantiza granularidad de autoridad para el CRUD — crear un camporee es acción más privilegiada que gestionar asistencia de uno existente.

---

## 2. Alcance canonizado

Dentro del canon:
- permisos `camporees:read/create/update/delete` para CRUD;
- grants por rol mirrored desde `activities:*` tras migración;
- separación explícita de `attendance:*` cross-cutting;
- permisos de inscripción de club/sección: `camporees:register` (organizadores territoriales) y `camporees:register_active_section` (director de club).

Fuera del canon:
- attendance, registration, payments, late approval de camporees (usan `attendance:*`, documentado en features);
- UI específica admin;
- flujos operativos pos-creación (inscripción, pago, cierre).

---

## 3. Permisos canonizados

Permisos vigentes (migrados 2026-04-22 desde `activities:*`):

- `camporees:read` — listar y leer camporees.
- `camporees:create` — crear nuevo camporee (local o union).
- `camporees:update` — actualizar información de camporee.
- `camporees:delete` — desactivar/eliminar camporee.

Permisos de inscripción (reactivados en julio de 2026, migración `20260713220000_camporee_section_registration_context`):

- `camporees:register` — inscribe un club en un camporee (`POST /camporees/:camporeeId/clubs`). El seed lo reserva a organizadores territoriales: solo `assistant-lf`, `director-lf`, `assistant-union` y `director-union` (GLOBAL). El cleanup final de `role-permissions.seed.sql` lo retira de cualquier otro rol, incluidos `admin` y `super-admin`.
- `camporees:register_active_section` — el director inscribe su sección activa (`POST /camporees/:camporeeId/section-registration`). El seed lo deja solo en `director` (CLUB).

Permisos cross-cutting preservados:

- `attendance:read` — listar participantes, clubs inscritos, pagos.
- `attendance:manage` — registrar/cancelar inscripciones, pagos.
- `attendance:approve_late` — aprobar/rechazar inscripciones y pagos tardíos.

### Distribución de grants tras migración

- `camporees:read` — todos los roles con contexto institucional (secretary + arriba) + JOIN copies + `admin`/`super-admin`.
- `camporees:create` + `camporees:update` — secretary, treasurer, secretary-treasurer, deputy-director, director (CLUB) + assistant-lf (GLOBAL) + JOIN copies + `admin`/`super-admin`.
- `camporees:delete` — solo director (CLUB) + assistant-lf (GLOBAL) + JOIN + `super-admin` (el wildcard de `admin` excluye `:delete`; ver §6).

---

## 4. Superficie API canonizada

### 4.1 CRUD (alcance de este canon)

| Path | Método | Handler | Permiso |
|------|--------|---------|---------|
| `/camporees` | GET | `findAll` | `camporees:read` |
| `/camporees/:id` | GET | `findOne` | `camporees:read` |
| `/camporees` | POST | `create` | `camporees:create` |
| `/camporees/:id` | PATCH | `update` | `camporees:update` |
| `/camporees/:id` | DELETE | `remove` | `camporees:delete` |
| `/camporees/union` | GET | `findAllUnion` | `camporees:read` |
| `/camporees/union/:id` | GET | `findOneUnion` | `camporees:read` |
| `/camporees/union` | POST | `createUnion` | `camporees:create` |
| `/camporees/union/:id` | PATCH | `updateUnion` | `camporees:update` |
| `/camporees/union/:id` | DELETE | `removeUnion` | `camporees:delete` |
| `/camporees/:camporeeId/section-registration` | GET | `getActiveSectionRegistration` | `camporees:read` |

### 4.2 Inscripción

| Path | Método | Permiso |
|------|--------|---------|
| `/camporees/:camporeeId/section-registration` | POST | `camporees:register_active_section` |
| `/camporees/:camporeeId/clubs` | POST | `camporees:register` |

El cierre y la reapertura de la inscripción de clubes (`POST camporees/:camporeeId/club-registration/close|reopen` y sus equivalentes `union-camporees/...`) viven en `camporee-club-registration.controller.ts` y usan `camporee_events:update`.

### 4.3 Cross-cutting `attendance:*` (fuera del canon de este documento)

33 handlers adicionales del mismo controller (registro de miembros, asistencia, pagos y aprobación tardía) usan `attendance:read` (8), `attendance:manage` (13) y `attendance:approve_late` (12). Detalle funcional en `docs/features/camporees.md`.

---

## 5. Relación con otros canones

- `docs/canon/runtime-sacdia.md` — camporee como actividad institucional de alcance regional.
- `docs/canon/runtime-communications.md` — notificaciones por aprobación tardía usan `source = 'camporees:*'`.
- `docs/canon/decisiones-clave.md` §20 — canonización del dominio camporees + preservación explícita de `attendance:*` cross-cutting.
- `docs/features/camporees.md` — detalle funcional runtime del controller completo (46 handlers).
- Módulos hermanos con canon funcional en `docs/features/`: `camporee-events`, `camporee-orders`, `camporee-supplies` (además de `camporee-scoring`, `camporee-venues`, `camporee-staff` y `camporee-event-templates` en el backend).

---

## 6. Invariantes

- `camporees:*` es el permiso canónico para CRUD de la entidad camporee; reutilizar `activities:*` en nuevos endpoints de camporees rompe la frontera de concerns;
- `attendance:*` es cross-cutting deliberado entre activities y camporees; fragmentarlo en `camporees:attendance:*` rompe el patrón canonizado;
- `camporees:register` queda restringido a organizadores territoriales (LF y unión) y `camporees:register_active_section` al director de club; ampliar cualquiera de los dos requiere cambiar el cleanup de `role-permissions.seed.sql` y registrarlo en `decisiones-clave.md`;
- el wildcard de `admin` (`NOT LIKE '%:delete'`) excluye `camporees:delete` — si la operación de delete debe ser accesible a admin, requiere grant explícito en el bloque de `admin` o escalación vía `super-admin`;
- handlers futuros en camporees deben clasificarse: si son CRUD de la entidad → `camporees:*`; si son operaciones de asistencia/inscripción → `attendance:*`. No mezclar.
