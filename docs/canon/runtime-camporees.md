# Runtime — Camporees (gestión de la entidad)

**Estado**: ACTIVE
**Autoridad rectora**: `docs/canon/source-of-truth.md`
**Tipo de documento**: runtime canonizado, documented-as-built
**Ámbito**: operaciones CRUD sobre la entidad `camporee` y los permisos específicos para inscribir secciones locales. La asistencia, participantes, pagos y aprobaciones tardías siguen usando `attendance:*` cuando el endpoint lo indica.

<!-- VERIFICADO contra código 2026-04-22: camporees.controller.ts con 10 handlers CRUD migrados a camporees:*, 24 handlers restantes preservados en attendance:* cross-cutting. -->

---

## 1. Propósito

Canoniza las operaciones **CRUD** sobre la entidad camporee y la inscripción de secciones locales. Separa explícitamente:

- **Operation** (camporees:\*): CRUD de la entidad — alcance canonizado en este documento.
- **Inscripción de sección local** (`camporees:register` y `camporees:register_active_section`): operaciones propias de camporee para el flujo heredado de organizador y el flujo contextual del director, respectivamente.
- **Attendance + participantes + pagos + aprobación tardía** (`attendance:*`): operaciones cross-cutting compartidas con actividades regulares que mantienen el patrón `attendance:manage`/`attendance:read`/`attendance:approve_late`.

La separación intencional evita fragmentación innecesaria (no crear `camporees:attendance:*`) mientras garantiza granularidad de autoridad para el CRUD — crear un camporee es acción más privilegiada que gestionar asistencia de uno existente.

---

## 2. Alcance canonizado

Dentro del canon:
- permisos `camporees:read/create/update/delete` para CRUD;
- grants por rol mirrored desde `activities:*` tras migración;
- separación explícita de `attendance:*` cross-cutting;
- permisos propios para inscribir secciones locales sin que el cliente pueda seleccionar arbitrariamente la sección en el flujo contextual.

Fuera del canon:
- participantes, pagos y aprobaciones tardías de camporees (usan `attendance:*`, documentado en features);
- UI específica admin;
- flujos operativos pos-creación (inscripción, pago, cierre).

---

## 3. Permisos canonizados

Permisos vigentes (migrados 2026-04-22 desde `activities:*`):

- `camporees:read` — listar y leer camporees.
- `camporees:create` — crear nuevo camporee (local o union).
- `camporees:update` — actualizar información de camporee.
- `camporees:delete` — desactivar/eliminar camporee.

Permisos específicos de inscripción local:

- `camporees:register` — inscripción heredada de una sección elegida por un organizador: `POST /camporees/:camporeeId/clubs`.
- `camporees:register_active_section` — inscripción contextual de la sección activa dirigida por el actor: `POST /camporees/:camporeeId/section-registration`; no recibe `club_section_id` del cliente.

Permisos cross-cutting preservados:

- `attendance:read` — listar participantes, clubs inscritos, pagos.
- `attendance:manage` — registrar/cancelar participantes, inscripciones de clubes de unión y pagos.
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

### 4.2 Inscripción de secciones y operaciones cross-cutting

| Path | Método | Permiso | Flujo |
|------|--------|---------|-------|
| `/camporees/:camporeeId/clubs` | POST | `camporees:register` | Inscripción heredada gestionada por organizador local. |
| `/camporees/:camporeeId/section-registration` | GET | `camporees:read` | Consulta contextual de la sección activa. |
| `/camporees/:camporeeId/section-registration` | POST | `camporees:register_active_section` | Inscripción segura de la sección activa del director. |

Los demás handlers de participantes, clubes de unión, pagos y aprobación tardía siguen `attendance:*`. Están documentados en `docs/features/camporees.md`.

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
- `camporees:register` sólo protege el endpoint heredado de inscripción local; los clientes de director deben usar `camporees:register_active_section` y el endpoint contextual, sin enviar una sección arbitraria;
- el wildcard de `admin` (`NOT LIKE '%:delete'`) excluye `camporees:delete` — si la operación de delete debe ser accesible a admin, requiere grant explícito en el bloque de `admin` o escalación vía `super_admin`;
- handlers futuros en camporees deben clasificarse: si son CRUD de la entidad → `camporees:*`; si son operaciones de asistencia/inscripción → `attendance:*`. No mezclar.
