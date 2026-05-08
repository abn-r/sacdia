# Runtime — Camporees (gestión de la entidad)

**Estado**: ACTIVE
**Autoridad rectora**: `docs/canon/source-of-truth.md`
**Tipo de documento**: runtime canonizado, documented-as-built
**Ámbito**: operaciones CRUD sobre la entidad `camporee` (crear, actualizar, desactivar, listar, leer). NO cubre attendance/registration/payments — esos comparten permisos cross-cutting `attendance:*` con actividades regulares

<!-- VERIFICADO contra código 2026-04-22: camporees.controller.ts con 10 handlers CRUD migrados a camporees:*, 24 handlers restantes preservados en attendance:* cross-cutting. -->

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
- estado de `camporees:register` como permiso existente sin uso (reservado para eventual distinción de inscripción).

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

Permiso existente sin uso actual (no migrado en esta ola):

- `camporees:register` — reservado para eventual separación "inscripción de club a camporee" del generic `attendance:manage`. Si el producto futuro decide diferenciar, se canonizará en decisión posterior. Hoy todos los endpoints de enrollment y payments usan `attendance:manage`.

Permisos cross-cutting preservados:

- `attendance:read` — listar participantes, clubs inscritos, pagos.
- `attendance:manage` — registrar/cancelar inscripciones, pagos.
- `attendance:approve_late` — aprobar/rechazar inscripciones y pagos tardíos.

### Distribución de grants tras migración

- `camporees:read` — todos los roles con contexto institucional (secretary + arriba) + JOIN copies + admin/super_admin.
- `camporees:create` + `camporees:update` — secretary, treasurer, secretary-treasurer, deputy-director, director (CLUB) + assistant-lf (GLOBAL) + JOIN copies + admin/super_admin.
- `camporees:delete` — solo director (CLUB) + assistant-lf (GLOBAL) + JOIN + super_admin (admin lo recibe vía wildcard que excluye `:delete` — confirmar si `camporees:delete` queda fuera; ver §6 invariantes).

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

### 4.2 Cross-cutting `attendance:*` (fuera del canon de este documento)

24 handlers adicionales para registration, attendance, payments, late approval siguen el patrón `attendance:*`. Documentados en `docs/features/camporees.md` y el canon sigue `attendance:*` como transversal.

---

## 5. Relación con otros canones

- `docs/canon/runtime-sacdia.md` — camporee como actividad institucional de alcance regional.
- `docs/canon/runtime-communications.md` — notificaciones por aprobación tardía usan `source = 'camporees:*'`.
- `docs/canon/decisiones-clave.md` §20 — canonización del dominio camporees + preservación explícita de `attendance:*` cross-cutting.
- `docs/features/camporees.md` — detalle funcional runtime de los 34 handlers completos.

---

## 6. Invariantes

- `camporees:*` es el permiso canónico para CRUD de la entidad camporee; reutilizar `activities:*` en nuevos endpoints de camporees rompe la frontera de concerns;
- `attendance:*` es cross-cutting deliberado entre activities y camporees; fragmentarlo en `camporees:attendance:*` rompe el patrón canonizado;
- `camporees:register` permanece reservado; reactivar su uso requiere decisión explícita en `decisiones-clave.md`;
- el wildcard de `admin` (`NOT LIKE '%:delete'`) excluye `camporees:delete` — si la operación de delete debe ser accesible a admin, requiere grant explícito en el bloque de `admin` o escalación vía `super_admin`;
- handlers futuros en camporees deben clasificarse: si son CRUD de la entidad → `camporees:*`; si son operaciones de asistencia/inscripción → `attendance:*`. No mezclar.
