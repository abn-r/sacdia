# Membership Requests (solicitudes de membresia)

**Estado**: IMPLEMENTADO

## Descripcion de dominio

Este dominio cubre la revision de solicitudes pendientes para ingresar o asumir un rol dentro de una seccion de club. En runtime, la superficie verificada se concentra en la aprobacion, rechazo y expiracion automatica de solicitudes ya creadas sobre `club_role_assignments`; no se documento en este batch un endpoint canonico separado para crear la solicitud.

La solicitud vive sobre una asignacion anual de rol y reutiliza los mismos actores de gestion de miembros del club. Cuando una solicitud se aprueba, la asignacion pasa a estado activo; cuando se rechaza, conserva trazabilidad via `rejection_reason`; cuando vence por tiempo, pasa a `expired`.

## Que existe (verificado contra codigo)

### Backend (MembershipRequestsModule)
- **Controller**: `src/membership-requests/membership-requests.controller.ts`
- **Service**: `src/membership-requests/membership-requests.service.ts`
- **Cron**: `src/membership-requests/membership-requests-cron.service.ts`
- **3 endpoints**:
  - `GET /api/v1/club-sections/:clubSectionId/membership-requests` - listar solicitudes pendientes activas de una seccion
  - `POST /api/v1/club-sections/:clubSectionId/membership-requests/:assignmentId/approve` - aprobar solicitud pendiente
  - `POST /api/v1/club-sections/:clubSectionId/membership-requests/:assignmentId/reject` - rechazar solicitud pendiente con motivo opcional
- **Permisos**:
  - toda la superficie usa `JwtAuthGuard` + `PermissionsGuard`
  - los tres endpoints requieren `club_members:approve`
  - la autorizacion contextual usa `@AuthorizationResource({ type: 'club', clubIdParam: 'clubSectionId' })`
- **Comportamiento operativo**:
  - el listado devuelve solo filas `active=true` y `status='pending'`
  - aprobar cambia `status` a `active`, limpia `expires_at` e invalida cache de autorizacion del usuario afectado
  - rechazar cambia `status` a `rejected`, limpia `expires_at`, persiste `rejection_reason` si llega e invalida cache de autorizacion
  - un cron horario expira solicitudes viejas usando lock distribuido; toma `membership.pending_timeout_days` desde `system_config` y usa `8` dias por defecto

### Admin
- **1 pagina funcional**: `/dashboard/requests/membership`
- Permite seleccionar seccion activa, listar pendientes, ver rol/fecha/expiracion y ejecutar aprobar o rechazar
- La pagina obtiene secciones desde `GET /api/v1/clubs` y luego consume la superficie especifica de membership requests

### App Movil
- **Feature verificada dentro de Members**: `MembersView` incluye tab de solicitudes de ingreso
- Carga solicitudes usando el contexto activo de club/seccion y muestra perfil basico del solicitante, filtros y badge de pendientes
- Directores pueden aprobar o rechazar desde la app; al hacerlo se invalida y recarga el estado del feature

### Base de datos
- `club_role_assignments` - almacena la solicitud y su transicion de `pending` a `active`, `rejected` o `expired`
- `system_config` - soporta el timeout configurable `membership.pending_timeout_days`
- Relaciones con `users`, `roles`, `club_sections` y `ecclesiastical_years`

## Requisitos funcionales

1. Debe ser posible listar solicitudes pendientes por seccion
2. Solo actores con `club_members:approve` pueden revisarlas
3. Aprobar una solicitud debe activar la asignacion anual correspondiente
4. Rechazar una solicitud debe permitir guardar un motivo opcional
5. Las solicitudes pendientes viejas deben expirar automaticamente por cron
6. Cambios de estado deben invalidar el cache de autorizacion del usuario afectado

## Decisiones de diseno

- **Sin tabla separada**: la solicitud reutiliza `club_role_assignments` en lugar de duplicar un modelo paralelo
- **Revision contextual por seccion**: la ruta es section-scoped para que permisos y alcance se resuelvan sobre la seccion destino
- **Expiracion configurable**: el timeout no esta hardcodeado al negocio; se lee desde `system_config`
- **Lock distribuido en cron**: evita expirar la misma ventana mas de una vez cuando hay multiples instancias del backend

## Gaps y pendientes

- **Surface verificada acotada a revision**: en este batch no se verifico una ruta canonica dedicada para crear la solicitud inicial
- **Sin historial administrativo expuesto**: el endpoint listado devuelve solo pendientes, no una bandeja de aprobadas/rechazadas/expiradas
- **Sin UI admin para timeout**: el valor de expiracion existe en `system_config`, pero no se verifico una pantalla administrativa para editarlo

## Prioridad y siguiente accion

- **Prioridad**: Media - feature operativa y consumida por admin/app, con alcance acotado a revision de pendientes
- **Siguiente accion**: documentar o arbitrar la superficie canonica de creacion de solicitud si se vuelve parte del contrato publico
