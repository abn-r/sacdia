# Communications (Notificaciones)

**Estado**: IMPLEMENTADO

## Descripcion de dominio

El modulo de comunicaciones gestiona las notificaciones push a los dispositivos moviles de los miembros de SACDIA. En el contexto de clubes de Conquistadores, Aventureros y Guias Mayores, las notificaciones son esenciales para coordinar actividades, avisar cambios de horario, convocar a campamentos, comunicar decisiones de la directiva y mantener informados a los padres/representantes legales.

El sistema utiliza Firebase Cloud Messaging (FCM) como proveedor de push notifications. Cada dispositivo registra su token FCM al autenticarse, y el backend puede enviar notificaciones a tres niveles: directa a un usuario especifico, broadcast a todos los usuarios registrados, o segmentada a los miembros de una seccion de club especifica.

Los tokens FCM se gestionan por usuario y dispositivo, permitiendo que un usuario reciba notificaciones en multiples dispositivos simultaneamente. El ciclo de vida del token incluye registro al login, desregistro al logout, y consulta de tokens activos.

## Que existe (verificado contra codigo)

### Backend (NotificationsModule)
- **Controller**: `src/notifications/notifications.controller.ts` (maneja tanto notificaciones como FCM tokens)
- **Services**: `src/notifications/notifications.service.ts`, `src/notifications/fcm-tokens.service.ts`
- **Module**: `src/notifications/notifications.module.ts`
- **Integracion**: FirebaseAdminModule (FCM)
- **7 endpoints totales**:
  - Notificaciones:
    - `POST /api/v1/notifications/send` — Enviar notificacion a usuario especifico (JWT)
    - `POST /api/v1/notifications/broadcast` — Enviar notificacion a todos los usuarios (roles: super_admin, admin)
    - `POST /api/v1/notifications/club/:sectionId` — Enviar notificacion a miembros de seccion (roles: super_admin, admin)
  - FCM Tokens:
    - `POST /api/v1/fcm-tokens` — Registrar token FCM (JWT)
    - `DELETE /api/v1/fcm-tokens/:token` — Desregistrar token FCM (JWT)
    - `GET /api/v1/fcm-tokens` — Obtener tokens propios (JWT)
    - `GET /api/v1/fcm-tokens/user/:userId` — Obtener tokens por userId (owner/admin only)

### Admin
- **1 pagina funcional**: Formularios de envio de notificaciones
  - Notificacion directa a un usuario especifico
  - Broadcast a todos los usuarios
  - Notificacion a seccion de club
- Consume `POST /notifications/send`, `POST /notifications/broadcast`, `POST /notifications/club/:sectionId`

### App Movil
- **No tiene screens de notificaciones** — No hay UI de bandeja o historial
- Firebase Messaging integrado para recepcion de push notifications
- Registro/desregistro automatico de tokens FCM via providers

### Base de datos
- `user_fcm_tokens` — Tokens FCM por usuario/dispositivo

## Requisitos funcionales

1. Solo super_admin y admin deben poder enviar broadcast y notificaciones a secciones de club
2. Cualquier usuario autenticado debe poder enviar notificacion directa a otro usuario
3. Los tokens FCM deben registrarse automaticamente al autenticarse en la app
4. Los tokens deben desregistrarse al cerrar sesion
5. Un usuario puede tener multiples tokens (multiples dispositivos)
6. Las notificaciones deben incluir titulo, cuerpo y datos opcionales (deep link, tipo de evento)
7. El envio a seccion debe resolver los tokens de todos los miembros activos de esa seccion
8. El admin debe ofrecer formularios simples para los tres tipos de envio

## Decisiones de diseno

- **Firebase FCM como unico proveedor**: Se usa exclusivamente FCM para push notifications; no hay fallback por SMS o email
- **Tokens gestionados por el backend**: El registro/desregistro de tokens se hace via API, no directamente desde Firebase
- **Envio fire-and-forget**: Las notificaciones se envian pero no se persisten en base de datos; no hay tabla de historial de notificaciones enviadas
- **Sin colas**: El envio es sincrono; para broadcast masivos esto podria ser un bottleneck
- **Segmentacion por seccion**: La granularidad de envio por grupo es la seccion de club, no unidades o roles especificos

## Gaps y pendientes

- **Sin historial de notificaciones**: No hay tabla ni endpoint para consultar notificaciones enviadas; el envio es fire-and-forget
- **Sin bandeja en app**: La app no tiene UI para ver notificaciones recibidas; solo muestra push del sistema operativo
- **Sin preferencias**: Los usuarios no pueden configurar que tipo de notificaciones quieren recibir
- **Sin programacion**: No hay capacidad para programar notificaciones futuras (ej: recordatorio de actividad 1 hora antes)
- **Envio sincrono**: El broadcast a todos los usuarios es sincrono; para bases de usuarios grandes puede causar timeouts
- **Sin notificaciones a roles**: No se puede enviar a un rol especifico (ej: todos los directores)

## Prioridad y siguiente accion

- **Prioridad**: Baja — feature funcional; las mejoras son incrementales
- **Siguiente accion**: Agregar tabla de historial de notificaciones enviadas para auditoria. Considerar implementar bandeja de notificaciones en la app. Evaluar colas (Redis/BullMQ) para broadcast masivo asincrono.
