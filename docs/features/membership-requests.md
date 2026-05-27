# Membership Requests (solicitudes de membresia)

**Estado**: IMPLEMENTADO

## Descripcion de dominio

Este dominio cubre la revision de solicitudes pendientes para ingresar o asumir un rol dentro de una seccion de club. En runtime, la solicitud inicial se crea desde el paso 3 de post-registro (`POST /api/v1/users/:userId/post-registration/step-3/complete`) sobre `club_role_assignments`; no hay una tabla paralela ni un endpoint separado de creacion.

La solicitud vive sobre una asignacion anual de rol y reutiliza los mismos actores de gestion de miembros del club. Cuando una solicitud se aprueba, la asignacion pasa a estado activo; cuando se rechaza, conserva trazabilidad via `rejection_reason`; cuando vence por tiempo, pasa a `expired`.

La membresia activa es el gate operativo para funcionalidades de club/seccion. Un usuario puede existir, autenticarse y gestionar su perfil sin membresia activa, pero mientras su solicitud este `pending` debe ver el club/seccion como `Pendiente de aprobacion` y no debe acceder a operaciones internas del club.

## Que existe (verificado contra codigo)

### Backend (MembershipRequestsModule + PostRegistrationModule)
- **Controller**: `src/membership-requests/membership-requests.controller.ts`
- **Service**: `src/membership-requests/membership-requests.service.ts`
- **Cron**: `src/membership-requests/membership-requests-cron.service.ts`
- **Endpoints de revision**:
  - `GET /api/v1/club-sections/:clubSectionId/membership-requests` - listar solicitudes pendientes activas de una seccion
  - `POST /api/v1/club-sections/:clubSectionId/membership-requests/:assignmentId/approve` - aprobar solicitud pendiente
  - `POST /api/v1/club-sections/:clubSectionId/membership-requests/:assignmentId/reject` - rechazar solicitud pendiente con motivo opcional
- **Endpoint self-service de cancelacion**:
  - `POST /api/v1/users/:userId/post-registration/membership-request/cancel` - cancelar la solicitud pendiente del usuario y reabrir seleccion de club/seccion
- **Permisos**:
  - toda la superficie usa `JwtAuthGuard` + `PermissionsGuard`
  - los tres endpoints requieren `club_members:approve`
  - la autorizacion contextual usa `@AuthorizationResource({ type: 'club', clubIdParam: 'clubSectionId' })`
- **Comportamiento operativo**:
  - el listado devuelve solo filas `active=true` y `status='pending'`
  - completar el paso 3 crea/reactiva una solicitud `pending`, impide una segunda solicitud pendiente activa del mismo usuario y notifica a `director`, `deputy-director`, `secretary` y `secretary-treasurer`
  - aprobar cambia `status` a `active`, limpia `expires_at` e invalida cache de autorizacion del usuario afectado
  - rechazar cambia `status` a `rejected`, limpia `expires_at`, persiste `rejection_reason` si llega e invalida cache de autorizacion
  - cancelar por usuario cambia la solicitud a `cancelled`, la desactiva, limpia `expires_at` y reabre `users_pr.club_selection_complete=false` sin borrar perfil ni datos personales
  - un cron horario expira solicitudes viejas usando lock distribuido; toma `membership.pending_timeout_days` desde `system_config` y usa `8` dias por defecto

### Admin
- **1 pagina funcional**: `/dashboard/requests/membership`
- Permite seleccionar seccion activa, listar pendientes, ver rol/fecha/expiracion y ejecutar aprobar o rechazar
- La pagina obtiene secciones desde `GET /api/v1/clubs` y luego consume la superficie especifica de membership requests

### App Movil
- **Feature verificada dentro de Members**: `MembersView` incluye tab de solicitudes de ingreso
- Carga solicitudes usando el contexto activo de club/seccion y muestra perfil basico del solicitante, filtros y badge de pendientes
- Directores pueden aprobar o rechazar desde la app; al hacerlo se invalida y recarga el estado del feature
- El usuario con solicitud pendiente debe conservar acceso a perfil, gestion de informacion personal y carga masiva/staging de especialidades y clases
- El usuario con solicitud pendiente no debe ver funcionalidades operativas de club hasta que su asignacion pase a `active`; la app oculta accesos rapidos y tabs operativos cuando detecta membresia `pending`, `rejected` o `expired`
- El club/seccion solicitado debe mostrarse como `Pendiente de aprobacion`; si no hay `active_assignment`, la app usa la solicitud no activa para mostrar el banner de estado
- La app permite cancelar la solicitud pendiente propia desde el banner y volver a seleccion de club/seccion en post-registro
- La app conserva un acceso visible a carga masiva de certificados desde el estado pendiente

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
7. Cada usuario debe tener una sola solicitud pendiente a la vez
8. El usuario pendiente puede cancelar su solicitud; al hacerlo vuelve a seleccion de club/seccion en post-registro
9. Una nueva solicitud debe notificar a director, subdirector, secretario y secretario tesorero del club/seccion destino
10. El usuario pendiente puede acceder a perfil, gestion de informacion personal y carga masiva/staging de especialidades y clases
11. La carga masiva/staging de especialidades y clases no desbloquea permisos operativos de club antes de la membresia activa
12. El usuario pendiente debe ver la membresia solicitada como `Pendiente de aprobacion`

## Decisiones de diseno

- **Sin tabla separada**: la solicitud reutiliza `club_role_assignments` en lugar de duplicar un modelo paralelo
- **Revision contextual por seccion**: la ruta es section-scoped para que permisos y alcance se resuelvan sobre la seccion destino
- **Una solicitud pendiente por usuario**: evita estados ambiguos de club/seccion y simplifica el post-registro
- **Cancelacion como reinicio de seleccion**: cancelar una solicitud pendiente no borra perfil; devuelve al usuario al paso de seleccion de club/seccion
- **Pendiente como estado limitado**: `pending` permite autogestion personal, pero bloquea operaciones internas de club
- **Expiracion configurable**: el timeout no esta hardcodeado al negocio; se lee desde `system_config`
- **Lock distribuido en cron**: evita expirar la misma ventana mas de una vez cuando hay multiples instancias del backend

## Gaps y pendientes

- **Surface verificada acotada a revision**: en este batch no se verifico una ruta canonica dedicada para crear la solicitud inicial
- **Visibilidad de staging pendiente de arbitrar**: queda por definir si la carga masiva/staging de especialidades y clases del usuario pendiente sera visible para directores antes de aprobar membresia
- **Sin historial administrativo expuesto**: el endpoint listado devuelve solo pendientes, no una bandeja de aprobadas/rechazadas/expiradas
- **Sin UI admin para timeout**: el valor de expiracion existe en `system_config`, pero no se verifico una pantalla administrativa para editarlo

## Prioridad y siguiente accion

- **Prioridad**: Media - feature operativa y consumida por admin/app, con alcance acotado a revision de pendientes
- **Siguiente accion**: verificar end-to-end con backend real que cancelar reabra post-registro y que aprobar active permisos operativos en el siguiente refresh de autorizacion
