# Camporees

**Estado**: IMPLEMENTADO

## Descripcion de dominio

Los camporees son eventos institucionales centrales en la vida de los clubes de Conquistadores y Aventureros. Son campamentos competitivos organizados a nivel de campo local (camporees locales) o de union (camporees de union) donde los clubes participan en actividades de evaluacion: orden cerrado, nudos, primeros auxilios, cocina al aire libre, orientacion, campismo, conocimiento biblico y otras disciplinas. Los camporees representan la culminacion del trabajo formativo del club durante un periodo.

El modelo de datos contempla dos niveles de camporees: locales (`local_camporees`) organizados por el campo local, y de union (`union_camporees`) que agrupan clubes de todo el territorio de la union. Los camporees de union pueden referenciar campos locales participantes (`union_camporee_local_fields`). Cada camporee admite inscripcion de clubes (`camporee_clubs`) y registro de miembros individuales (`camporee_members`).

La inscripcion de miembros en camporees tiene implicaciones directas con el modulo de seguros: para participar en un camporee, los miembros generalmente requieren un seguro activo de tipo CAMPOREE o GENERAL_ACTIVITIES. Esta relacion esta modelada en la tabla `camporee_members` que referencia `member_insurances`.

## Que existe (verificado contra codigo)

### Backend (CamporeesModule)
- **Controller**: `src/camporees/camporees.controller.ts`
- **Service**: `src/camporees/camporees.service.ts`
- **Late approvals service**: `src/camporees/camporee-late-approvals.service.ts`
- **Guards**: JwtAuthGuard, PermissionsGuard
- **41 endpoints**:

**Camporees locales — CRUD**
  - `GET /api/v1/camporees` — Listar camporees
  - `POST /api/v1/camporees` — Crear camporee
  - `GET /api/v1/camporees/:camporeeId` — Obtener camporee por ID
  - `PATCH /api/v1/camporees/:camporeeId` — Actualizar camporee
  - `DELETE /api/v1/camporees/:camporeeId` — Desactivar camporee (soft delete)

**Camporees locales — Inscripcion de clubs**
  - `POST /api/v1/camporees/:camporeeId/clubs` — Inscribir club
  - `GET /api/v1/camporees/:camporeeId/clubs` — Listar clubs inscritos
  - `DELETE /api/v1/camporees/:camporeeId/clubs/:camporeeClubId` — Cancelar inscripcion de club

**Camporees locales — Registro de miembros**
  - `POST /api/v1/camporees/:camporeeId/register` — Registrar miembro
  - `GET /api/v1/camporees/:camporeeId/members` — Listar miembros
  - `DELETE /api/v1/camporees/:camporeeId/members/:userId` — Remover miembro

**Camporees locales — Pagos**
  - `POST /api/v1/camporees/:camporeeId/members/:memberId/payments` — Registrar pago
  - `GET /api/v1/camporees/:camporeeId/members/:memberId/payments` — Listar pagos de un miembro
  - `GET /api/v1/camporees/:camporeeId/payments` — Listar todos los pagos del camporee

**Camporees locales — Aprobaciones tardias**
  - `GET /api/v1/camporees/:camporeeId/pending` — Listar inscripciones pendientes de aprobacion
  - `PATCH /api/v1/camporees/:camporeeId/clubs/:camporeeClubId/approve` — Aprobar inscripcion tardía de club
  - `PATCH /api/v1/camporees/:camporeeId/clubs/:camporeeClubId/reject` — Rechazar inscripcion tardía de club
  - `PATCH /api/v1/camporees/:camporeeId/members/:camporeeMemberId/approve` — Aprobar inscripcion tardía de miembro
  - `PATCH /api/v1/camporees/:camporeeId/members/:camporeeMemberId/reject` — Rechazar inscripcion tardía de miembro

**Pagos (compartido local/union)**
  - `PATCH /api/v1/camporees/payments/:paymentId` — Actualizar pago
  - `PATCH /api/v1/camporees/payments/:camporeePaymentId/approve` — Aprobar pago tardío
  - `PATCH /api/v1/camporees/payments/:camporeePaymentId/reject` — Rechazar pago tardío

**Camporees de union — CRUD**
  - `GET /api/v1/camporees/union` — Listar camporees de union
  - `POST /api/v1/camporees/union` — Crear camporee de union
  - `GET /api/v1/camporees/union/:camporeeId` — Obtener camporee de union por ID
  - `PATCH /api/v1/camporees/union/:camporeeId` — Actualizar camporee de union
  - `DELETE /api/v1/camporees/union/:camporeeId` — Desactivar camporee de union

**Camporees de union — Inscripcion de clubs**
  - `POST /api/v1/camporees/union/:camporeeId/clubs` — Inscribir club
  - `GET /api/v1/camporees/union/:camporeeId/clubs` — Listar clubs inscritos
  - `DELETE /api/v1/camporees/union/:camporeeId/clubs/:camporeeClubId` — Cancelar inscripcion de club

**Camporees de union — Registro de miembros**
  - `POST /api/v1/camporees/union/:camporeeId/register` — Registrar miembro
  - `GET /api/v1/camporees/union/:camporeeId/members` — Listar miembros
  - `DELETE /api/v1/camporees/union/:camporeeId/members/:userId` — Remover miembro

**Camporees de union — Pagos**
  - `POST /api/v1/camporees/union/:camporeeId/members/:memberId/payments` — Registrar pago
  - `GET /api/v1/camporees/union/:camporeeId/members/:memberId/payments` — Listar pagos de un miembro
  - `GET /api/v1/camporees/union/:camporeeId/payments` — Listar todos los pagos del camporee de union

**Camporees de union — Aprobaciones tardias**
  - `GET /api/v1/camporees/union/:camporeeId/pending` — Listar inscripciones pendientes de aprobacion
  - `PATCH /api/v1/camporees/union/:camporeeId/clubs/:camporeeClubId/approve` — Aprobar inscripcion tardía de club
  - `PATCH /api/v1/camporees/union/:camporeeId/clubs/:camporeeClubId/reject` — Rechazar inscripcion tardía de club
  - `PATCH /api/v1/camporees/union/:camporeeId/members/:camporeeMemberId/approve` — Aprobar inscripcion tardía de miembro
  - `PATCH /api/v1/camporees/union/:camporeeId/members/:camporeeMemberId/reject` — Rechazar inscripcion tardía de miembro

### Capacidades implementadas
- Inscripcion de clubs (local y union) con status tracking
- Registro de miembros (local y union) con validacion de seguro
- Seguimiento de pagos por miembro (local y union)
- Enforcement de plazos via 3 campos de deadline por camporee; si no estan configurados, no hay restriccion
- Flujo de aprobacion tardía: inscripciones post-deadline entran en `pending_approval`, pendientes de aprobacion por director/asistente
- Triggers de notificacion para inscripciones tardias
- Inscripcion de camporees de union con FK polimorfica a campos locales participantes (`union_camporee_local_fields`)
- Endpoints de aprobacion escopados por tipo (local y union)
- Listas con filtro `?status=` (por defecto excluyen `pending_approval`)

### Admin
- **CRUD completo**: Lista con creacion/eliminacion, pagina de detalle con tarjeta de info y tab de miembros, dialog de creacion/edicion, registro de miembros con validacion de seguro, remocion de miembros
- Reutiliza el cliente API existente (`lib/api/camporees.ts`) y las server actions (`lib/camporees/actions.ts`)

### App Movil
- **4 screens**: lista de camporees, detalle con preview de miembros, registro de miembro con validacion de seguro, lista de miembros con opcion de remocion
- Capa de datos completa: entidades, modelos, datasource, repositorio, providers
- Rutas configuradas en GoRouter

### Base de datos
- `local_camporees` — Camporees a nivel de campo local
- `union_camporees` — Camporees a nivel de union
- `union_camporee_local_fields` — Campos locales participantes en camporees de union
- `camporee_clubs` — Clubs inscritos en camporees
- `camporee_members` — Miembros inscritos en camporees (referencia `member_insurances`)

## Requisitos funcionales

1. Directores y subdirectores deben poder crear y gestionar camporees
2. Los camporees deben tener nombre, fechas, ubicacion, tipo (local/union) y descripcion
3. El sistema debe permitir inscribir miembros individualmente en un camporee
4. Debe ser posible listar los miembros inscritos en cada camporee
5. El registro de miembros debe validar requisitos (seguro activo, membresia vigente)
6. Los camporees deben poder desactivarse (soft delete) sin perder datos historicos
7. El panel admin debe permitir CRUD completo de camporees con gestion de miembros
8. La app movil permite ver camporees disponibles, inscribirse y gestionar miembros inscritos
9. Los campos de deadline son opcionales; si no estan configurados, no se aplica restriccion de fecha
10. Cuando se supera el deadline, la inscripcion se permite pero queda en estado `pending_approval`
11. Las aprobaciones tardias son realizadas por `director-lf`/`assistant-lf` (local) o `director-union`/`assistant-union` (union)
12. La inscripcion de club a camporee de union valida que el club pertenece a un campo local participante
13. Las consultas de listado excluyen registros en `pending_approval` por defecto; se usa `?status=` para filtrar explicitamente

## Permisos

| Permiso | Operacion |
|---------|-----------|
| `attendance:manage` | Inscribir clubs, registrar miembros, registrar pagos, cancelar inscripciones |
| `attendance:read` | Listar clubs inscritos, miembros, pagos |
| `attendance:approve_late` | Aprobar o rechazar inscripciones y pagos en `pending_approval` |
| `activities:read` | Listar y obtener camporees |
| `activities:create` | Crear camporees (local y union) |
| `activities:update` | Actualizar camporees |
| `activities:delete` | Desactivar camporees |

## Decisiones de diseno

- **Dos niveles de camporees**: El modelo distingue camporees locales y de union con tablas separadas, permitiendo diferente estructura organizativa
- **Inscripcion de clubs ademas de miembros**: Ademas del registro individual de miembros, los clubs participan como unidad a traves de `camporee_clubs`
- **Inscripcion individual de miembros**: Los miembros se registran individualmente, no como club completo, permitiendo control granular de participacion
- **Vinculacion con seguros**: `camporee_members` referencia `member_insurances` para validar que el participante tiene cobertura vigente
- **Plazos opcionales con flujo de aprobacion**: Si un camporee tiene deadline configurado y se supera, el registro entra en `pending_approval` en lugar de rechazarse; requiere aprobacion explicita
- **FK polimorfica en union**: `union_camporee_local_fields` vincula camporees de union con los campos locales que participan, requerido para validar inscripcion de clubs
- **Servicio de aprobaciones separado**: `CamporeeLateApprovalsService` encapsula toda la logica de aprobacion tardía, separada del servicio principal
- **Autorizacion escopada por tipo**: Los endpoints de aprobacion para union usan `AuthorizationResource({ type: 'union_camporee' })` vs `type: 'camporee'` para locales

## Gaps y pendientes

- **Sin evaluaciones**: No hay modelo para registrar evaluaciones o puntajes de los clubes/miembros durante el camporee
- **Sin logistica**: No hay modelo para gestionar logistica del camporee (comida, transporte, alojamiento)

## Estado de implementacion

Actualizado: 2026-03-25

- **Prioridad**: Completo — backend, admin y app implementados con CRUD completo y validacion de seguro en el registro de miembros
- **Deadlines**: 3 campos de deadline por camporee (`club_registration_deadline`, `member_registration_deadline`, `payment_deadline`) en local_camporees y union_camporees
- **Inscripcion union**: FK polimorfica en `camporee_clubs` y `camporee_members` con `union_camporee_id` + CHECK constraint en DB
- **Aprobacion tardía**: `CamporeeLateApprovalsService` separado, autorización escopada por tipo (`camporee` vs `union_camporee`), 10 endpoints de aprobacion/rechazo (5 local + 5 union)
- **Schema documentado**: Las 5 tablas del modulo estan documentadas en SCHEMA-REFERENCE.md con todos los campos
