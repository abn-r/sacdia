# Communications (Notificaciones)

**Estado**: IMPLEMENTADO

## Descripcion de dominio

El modulo de comunicaciones gestiona notificaciones push, bandeja/historial y preferencias de recepcion para los miembros de SACDIA. En el contexto de clubes de Conquistadores, Aventureros y Guias Mayores, cubre tanto el envio administrativo de mensajes como la bandeja personal que cada usuario consulta desde la app.

El sistema usa Firebase Cloud Messaging (FCM) como transporte push, pero ya no es solo fire-and-forget: el backend persiste `notification_logs` para auditoria y `notification_deliveries` para la bandeja por usuario. Cada dispositivo registra su token FCM al autenticarse, puede desregistrarlo al cerrar sesion y mantiene multiples tokens activos por usuario/dispositivo.

El envio soporta tres niveles: directo a un usuario, broadcast global y envio a miembros de una instancia de club. Ademas, cada usuario puede consultar historial, conteo de no leidas, marcar entregas como leidas y configurar preferencias por categoria.

## Que existe (verificado contra codigo)

### Backend (NotificationsModule)
- **Controllers**: `src/notifications/notifications.controller.ts` (notificaciones + bandeja) y `FcmTokensController` en el mismo archivo
- **Services**: `src/notifications/notifications.service.ts`, `src/notifications/fcm-tokens.service.ts`, `src/notifications/notification-preferences.service.ts`
- **Module**: `src/notifications/notifications.module.ts`
- **Integracion**: FirebaseAdminModule (FCM) + persistencia en `notification_logs`, `notification_deliveries` y `notification_preferences`
- **17 endpoints totales**:
  - Notificaciones y bandeja:
    - `POST /api/v1/notifications/send` — Enviar notificacion directa (`notifications:send`, body `{ userId, title, body, data? }`)
    - `POST /api/v1/notifications/broadcast` — Enviar broadcast global (`notifications:broadcast`)
    - `POST /api/v1/notifications/club/:instanceType/:instanceId` — Enviar a miembros de club con enforcement por `active_assignment` y validación de tipo de sección (`notifications:club`; mismatch responde `NOTIF_TARGET_TYPE_MISMATCH`)
    - `GET /api/v1/notifications/targets/club` — Listar targets autorizados del actor para envio a club (`notifications:club`, scope por `active_assignment`)
    - `GET /api/v1/notifications/history` — Historial paginado; admin ve auditoria, usuario regular ve su bandeja autenticada
    - `GET /api/v1/notifications/unread-count` — Conteo de no leidas del usuario autenticado
    - `PATCH /api/v1/notifications/read-all` — Marcar todas como leidas
    - `PATCH /api/v1/notifications/:deliveryId/read` — Marcar una entrega como leida
    - `GET /api/v1/notifications/preferences` — Obtener preferencias por categoria
    - `PUT /api/v1/notifications/preferences/:category` — Actualizar preferencia por categoria
  - FCM tokens:
    - `POST /api/v1/fcm-tokens` — Registrar token FCM legacy
    - `POST /api/v1/users/me/fcm-tokens` — Registrar token FCM propio desde la app
    - `DELETE /api/v1/fcm-tokens/by-token` — Desregistrar token por valor (body)
    - `DELETE /api/v1/fcm-tokens/:id` — Desregistrar token por ID de registro
    - `DELETE /api/v1/users/me/fcm-tokens/:tokenId` — Desregistrar token propio por ID desde la app
    - `GET /api/v1/fcm-tokens` — Obtener tokens propios activos
    - `GET /api/v1/fcm-tokens/user/:userId` — Obtener tokens por `userId` (owner/admin)

### Admin
- **2 paginas presentes**: envio y auditoria
  - `/dashboard/notifications` — formularios para envio directo, broadcast y envio por club
  - `/dashboard/notifications/history` — tabla paginada de historial/auditoria
- **Cobertura verificada**:
  - envio directo y broadcast consumen rutas vigentes
  - historial administrativo consume `GET /api/v1/notifications/history`
  - el formulario de envio por club del admin ya consume la ruta canonica `POST /api/v1/notifications/club/:instanceType/:instanceId` (alineado 2026-04-22; la ruta legacy `POST /notifications/section/:sectionId` nunca existio en backend y producia 404 silencioso hasta el fix)

### App Movil
- **Tiene bandeja funcional**: `NotificationsInboxView` con paginacion, pull-to-refresh y carga incremental
- Firebase Messaging integrado para recepcion de push notifications
- Registro automatico de token con `POST /api/v1/users/me/fcm-tokens` y desregistro con `DELETE /api/v1/users/me/fcm-tokens/:tokenId`; fallback legacy por valor en `DELETE /api/v1/fcm-tokens/by-token`
- Navegacion desde taps de notificaciones y snackbar en foreground via `PushNotificationService`

### Base de datos
- `user_fcm_tokens` — Tokens FCM por usuario/dispositivo
- `notification_logs` — auditoria de envios
- `notification_deliveries` — bandeja por destinatario + estado de lectura
- `notification_preferences` — opt-out por categoria

## Requisitos funcionales

1. El envio directo requiere `notifications:send`
2. El broadcast global requiere `notifications:broadcast`
3. El envio a club requiere `notifications:club`, enforcement por `active_assignment` y coherencia entre `instanceType` y el tipo real de la sección
4. Los tokens FCM deben registrarse automaticamente al autenticarse en la app
5. Los tokens deben poder desregistrarse al cerrar sesion
6. Un usuario puede tener multiples tokens activos (multiples dispositivos)
7. Las notificaciones deben incluir titulo, cuerpo y datos opcionales
8. Cada usuario debe poder consultar historial, contar no leidas y marcar entregas como leidas
9. Cada usuario debe poder configurar preferencias por categoria
10. El admin debe ofrecer UI para envio y auditoria basica

## Decisiones de diseno

- **Firebase FCM como transporte push**: No hay fallback por SMS o email
- **Tokens gestionados por backend**: El registro/desregistro se hace via API, no directo contra Firebase desde el cliente
- **Persistencia dual**: `notification_logs` guarda auditoria de envios y `notification_deliveries` alimenta la bandeja por usuario
- **Preferencias opt-out por categoria**: Si falta fila en `notification_preferences`, el backend asume `enabled=true`
- **Modo mixto de envio**: con Redis/BullMQ usa cola; sin Redis cae a envio sincrono
- **Inbox-first**: si FCM no esta configurado o el usuario no tiene tokens, igual se crean `notification_logs` y `notification_deliveries`; solo se omite el push.
- **Segmentacion por club**: la superficie publica de envio por club hoy se resuelve sobre la instancia activa autorizada del actor (`active_assignment`)
- **Descubrimiento de targets seguro**: `GET /api/v1/notifications/targets/club` expone solo la instancia activa autorizada y evita listar clubes/secciones fuera de scope.
- **RBAC efectivo**: `notifications:send` y `notifications:broadcast` quedan en roles globales admin/super-admin por wildcard del seed; `notifications:club` se otorga a liderazgo de sección (`secretary`, `secretary-treasurer`, `deputy-director`, `director`) y se vuelve exacto por `active_assignment`.
- **Historial sin permiso de envío**: `GET /notifications/history` solo requiere JWT; usuario regular ve su bandeja y admin ve auditoría según scope.

## Matriz envio -> destinatarios

| Escenario | Destinatarios | Gate |
|-----------|---------------|------|
| Directo admin | `userId` explícito | `notifications:send` global |
| Broadcast admin | usuarios activos | `notifications:broadcast` global |
| Club admin | miembros activos de la sección seleccionada | `notifications:club` + `active_assignment` exacto + tipo de sección consistente |
| Actividades | miembros de la sección de la actividad | emisor interno `activities:*` |
| Requests/validación/camporees/investiduras | roles/ámbitos calculados por servicio | helpers internos por sección o rol global |
| Achievements/member of month/alertas cron | usuario específico | `notifySafe` |

## Gaps y pendientes

- **Scope admin resuelto en historial**: `GET /notifications/history` filtra auditoria administrativa por territorio/scope del caller; `super_admin` conserva la vista completa
- **Sin programacion**: No hay scheduling de notificaciones futuras
- **Sin UI expuesta para preferencias/unread en admin**: esas superficies hoy se consumen principalmente desde la app/self-service
- **Sin targeting administrable por rol desde la UI**: el runtime tiene helpers internos por rol, pero no una superficie de producto dedicada

## Prioridad y siguiente accion

- **Prioridad**: Media — dominio funcional y con bandeja operativa; quedan mejoras de UX para targeting por club/rol.
- **Siguiente accion**: Smoke real con FCM/dispositivo cuando haya entorno disponible; luego evaluar targeting por rol si producto lo necesita.
