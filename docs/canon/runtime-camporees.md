# Runtime — Camporees (entidad e inscripción de secciones)

**Estado**: ACTIVE
**Autoridad rectora**: `docs/canon/source-of-truth.md`
**Tipo de documento**: runtime canonizado, documented-as-built
**Ámbito**: CRUD de `camporee`, inscripción contextual de la sección activa y enrolamiento legacy territorial. Attendance de participantes, pagos y aprobaciones tardías conservan permisos cross-cutting `attendance:*`.

<!-- VERIFICADO contra código 2026-07-14: CRUD camporees:*, section-registration contextual, legacy territorial camporees:register y participant gates. -->

---

## 1. Propósito

Canoniza las operaciones **CRUD** sobre la entidad camporee (crear, actualizar, eliminar, leer) como dominio propio con permisos `camporees:*`. Separa explícitamente:

- **Operation** (camporees:\*): CRUD de la entidad.
- **Section enrollment** (`camporees:register_active_section`): el director CLUB inscribe su sección activa sin enviar IDs.
- **Territorial enrollment legacy** (`camporees:register`): cuatro organizadores GLOBAL pueden inscribir una sección explícita dentro de scope.
- **Participant attendance + Payments + Late approval** (attendance:\*): operaciones cross-cutting compartidas con actividades regulares.

La separación intencional evita fragmentación innecesaria (no crear `camporees:attendance:*`) mientras garantiza granularidad de autoridad para el CRUD — crear un camporee es acción más privilegiada que gestionar asistencia de uno existente.

---

## 2. Alcance canonizado

Dentro del canon:
- permisos `camporees:read/create/update/delete` para CRUD;
- grants por rol mirrored desde `activities:*` tras migración;
- separación explícita de `attendance:*` cross-cutting;
- contrato contextual `camporees:register_active_section` para director CLUB;
- contrato legacy `camporees:register` para organizadores territoriales exactos.

Fuera del canon:
- attendance de participantes, pagos y late approval de camporees (usan `attendance:*`, documentado en features);
- UI específica admin;
- flujos operativos pos-creación (inscripción, pago, cierre).

---

## 3. Permisos canonizados

Permisos CRUD vigentes (migrados 2026-04-22 desde `activities:*`):

- `camporees:read` — listar y leer camporees.
- `camporees:create` — crear nuevo camporee (local o union).
- `camporees:update` — actualizar información de camporee.
- `camporees:delete` — desactivar/eliminar camporee.

Permisos de inscripción vigentes:

- `camporees:register_active_section` — únicamente `director` de categoría `CLUB`; muta sólo su assignment activo y no acepta IDs de sección/club/actor.
- `camporees:register` — únicamente `assistant-lf`, `director-lf`, `assistant-union`, `director-union` de categoría `GLOBAL`, dentro del field/unión correspondiente. No se hereda a roles CLUB, división, `admin` ni `super-admin`.

Permisos cross-cutting preservados:

- `attendance:read` — listar participantes, clubs inscritos, pagos.
- `attendance:manage` — registrar/remover participantes, cancelar inscripciones existentes y gestionar pagos; no autoriza crear la inscripción legacy de club.
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

### 4.2 Inscripción de sección

| Path | Método | Autoridad |
|------|--------|-----------|
| `/camporees/:id/section-registration` | GET | `camporees:read` + assignment activo |
| `/camporees/:id/section-registration` | POST | `camporees:register_active_section` + director CLUB activo; sin body |
| `/camporees/:id/clubs` | POST | `camporees:register` + uno de los cuatro organizadores GLOBAL dentro de scope; body `club_section_id` |

El POST contextual deriva sección, club y actor. El legacy relee desde DB y sólo usa `club_section_id` como selector, nunca como autoridad de territorio o lineage.

### 4.3 Cross-cutting `attendance:*`

Participantes, lectura/remoción, pagos y aprobación tardía siguen el patrón `attendance:*`. Antes de crear un participante local, el backend exige una inscripción activa de la misma sección con estado `registered` o `approved`; los errores de elegibilidad son `CAMPOREE_SECTION_REGISTRATION_REQUIRED` y `CAMPOREE_MEMBER_OUTSIDE_ACTIVE_SECTION`.

---

## 5. Relación con otros canones

- `docs/canon/runtime-sacdia.md` — camporee como actividad institucional de alcance regional.
- `docs/canon/runtime-communications.md` — notificaciones por aprobación tardía usan `source = 'camporees:*'`.
- `docs/canon/decisiones-clave.md` §20 y §25 — CRUD/attendance cross-cutting e inscripción contextual/legacy territorial.
- `docs/features/camporees.md` — detalle funcional runtime de los 34 handlers completos.

---

## 6. Invariantes

- `camporees:*` es el permiso canónico para CRUD de la entidad camporee; reutilizar `activities:*` en nuevos endpoints de camporees rompe la frontera de concerns;
- `attendance:*` sigue cross-cutting para participantes/pagos/aprobaciones, pero no sustituye los permisos específicos de inscripción de sección;
- `camporees:register_active_section` nunca admite body ni grants distintos de director CLUB;
- `camporees:register` se restringe a los cuatro organizadores territoriales exactos; los wildcards administrativos no lo conceden;
- participantes locales creados por el flujo contextual conservan lineage mediante `camporee_members.camporee_club_id`; la columna continúa nullable por compatibilidad legacy y por otros flujos que todavía no persisten esa relación;
- el wildcard de `admin` (`NOT LIKE '%:delete'`) excluye `camporees:delete` — si la operación de delete debe ser accesible a admin, requiere grant explícito en el bloque de `admin` o escalación vía `super_admin`;
- handlers futuros deben distinguir CRUD, inscripción de sección y attendance de participantes; no reutilizar `attendance:manage` para enrolar una sección.
