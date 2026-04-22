# Runtime — Solicitudes (transferencias y asignaciones de rol)

**Estado**: ACTIVE
**Autoridad rectora**: `docs/canon/source-of-truth.md`
**Tipo de documento**: runtime canonizado, documented-as-built
**Ámbito**: workflow de solicitudes institucionales de transferencia de miembros entre clubes y solicitudes de asignación de rol. Scope acotado al módulo `requests`; NO incluye solicitudes de membresía (que viven en `membership-requests` con dominio propio)

<!-- VERIFICADO contra código 2026-04-22: requests.controller.ts con 8 handlers, migración a permisos propios requests:read/review, distribución por roles alineada con patrón MoM y scoring-categories. -->

---

## 1. Propósito

Canoniza el subsistema de **solicitudes de transferencia y asignación de rol** como workflow institucional propio, con permisos dedicados distintos de los dominios `clubs:*` o `club_roles:*` que antes se reutilizaban.

Dos flujos distintos:
- **Transferencias**: un miembro pide moverse entre clubes; el club receptor (o liderazgo de campo) aprueba/rechaza.
- **Asignaciones de rol**: un asistente de campo solicita asignar un rol institucional a un miembro; la solicitud pasa revisión.

Ambos flujos comparten shape de workflow (create → review) y permisos.

---

## 2. Alcance canonizado

Dentro del canon:
- contrato create + review (transfer + assignment);
- permisos propios del dominio (`requests:read` + `requests:review`);
- scope de autoridad por rol;
- separación explícita de `membership-requests` (dominio distinto).

Fuera del canon:
- UI específica admin (tablas, dialogs);
- flujos de membership (ver `docs/features/membership-requests.md`);
- cascadas derivadas de aprobación (ej. creación efectiva de `club_role_assignments`) — las rige el módulo destino.

---

## 3. Permisos canonizados

Permisos vigentes (dominio propio, migrados desde `clubs:*`/`club_roles:*` en 2026-04-22):

- `requests:read` — consulta de solicitudes de transferencia y asignación (filtrado por scope del rol).
- `requests:review` — crear solicitud de asignación + aprobar/rechazar ambos tipos.

Distribución tras migración:
- `requests:read` → todos los roles con contexto institucional (user, member, counselor, secretary, treasurer, secretary-treasurer, deputy-director, director, coordinator, zone-coordinator, general-coordinator, pastor, assistant-lf + JOIN copies) + admin/super_admin.
- `requests:review` → director (CLUB), assistant-lf (GLOBAL) + JOIN copies (director-lf, assistant-union, director-union, assistant-dia, director-dia) + admin/super_admin.

---

## 4. Semántica review vs create

`requests:review` gatea **tanto** la revisión (approve/reject) **como** la creación de solicitudes de asignación. Motivo: `createAssignmentRequest` no es self-service — es acción privilegiada de asistente de campo local para solicitar la asignación de un rol a un miembro. Quien puede crear la solicitud es parte de la misma autoridad que puede revisar.

`createTransferRequest` usa `requests:read` (no review) — una transferencia puede iniciarse por un rol con visibilidad básica; la aprobación queda en `reviewTransferRequest` con `requests:review`.

Un futuro split `requests:create` podría separar estos concerns si emergen casos self-service. Mientras, la semántica vigente mantiene create + review bajo el mismo permiso para asignaciones.

---

## 5. Superficie API canonizada

| Path | Método | Handler | Permiso |
|------|--------|---------|---------|
| `/requests/transfers` | POST | `createTransferRequest` | `requests:read` |
| `/requests/transfers` | GET | `getTransferRequests` | `requests:read` |
| `/requests/transfers/:id` | GET | `getTransferRequest` | `requests:read` |
| `/requests/transfers/:id/review` | PATCH/POST | `reviewTransferRequest` | `requests:review` |
| `/requests/assignments` | POST | `createAssignmentRequest` | `requests:review` |
| `/requests/assignments` | GET | `getAssignmentRequests` | `requests:read` |
| `/requests/assignments/:id` | GET | `getAssignmentRequest` | `requests:read` |
| `/requests/assignments/:id/review` | PATCH/POST | `reviewAssignmentRequest` | `requests:review` |

---

## 6. Admin UI

Las rutas admin `/dashboard/requests/transfers` y `/dashboard/requests/assignments` usan `requests:read` como permiso de visibilidad del nav. Las acciones destructivas (aprobar/rechazar) en el UI dependen del backend para rechazar con 403 si el rol no tiene `requests:review`.

La ruta `/dashboard/requests/membership` **NO pertenece a este canon** — vive en el dominio `membership-requests` con permiso `club_members:approve` (ver `docs/features/membership-requests.md`). Está agrupada bajo la misma carpeta UI por afinidad visual, no por dominio compartido.

---

## 7. Relación con otros canones

- `docs/canon/dominio-sacdia.md` — pertenencia via `Vinculación institucional` (decisión §4) es el contexto que las solicitudes mutan.
- `docs/canon/runtime-communications.md` — aprobación/rechazo puede emitir notificaciones con `source = 'requests:*'`.
- `docs/canon/decisiones-clave.md` §18 — canonización del dominio requests.

---

## 8. Invariantes

- `requests:*` es el único permiso canónico para endpoints del módulo `requests`; reutilizar `clubs:*` o `club_roles:*` en nuevos endpoints de este módulo rompe la frontera de concerns;
- `membership-requests` es dominio distinto; no forzar unificación de permisos aunque compartan nav admin;
- la aprobación de una solicitud nunca crea datos en otro módulo sin respetar la autoridad de ese módulo (ej. crear `club_role_assignments` debe honrar sus propias reglas);
- notificaciones emitidas deben seguir `docs/canon/runtime-communications.md` con `source` trazable.
