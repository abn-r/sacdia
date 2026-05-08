# Runtime — Comunicaciones (notificaciones push + bandeja)

**Estado**: ACTIVE
**Autoridad rectora**: `docs/canon/source-of-truth.md`
**Tipo de documento**: runtime canonizado, documented-as-built
**Ámbito**: notificaciones visibles (push + bandeja) dirigidas a usuarios SACDIA, preferencias por categoría, tokens FCM y emisión desde features del runtime

<!-- VERIFICADO contra código 2026-04-22: notifications.controller.ts, notifications.service.ts, notifications.processor.ts, schema Prisma, push_notification_service.dart y admin UI cruzados con implementación real. -->

---

## 1. Propósito

Canoniza el subsistema de **comunicaciones visibles al usuario**: notificaciones push (FCM), bandeja personal, preferencias opt-out por categoría y gestión de tokens FCM por dispositivo.

El subsistema de invalidación por FCM silent messages (cache invalidation) vive en `docs/canon/runtime-resiliencia-red.md` y usa la misma cola pero un path distinto (sin `notification`, sin persistencia en log/delivery). Este canon describe solo el camino visible.

---

## 2. Alcance canonizado

Dentro del canon:
- contrato de envío (directo, broadcast, por sección, por rol);
- contrato de persistencia (logs + deliveries);
- contrato de preferencias y opt-out;
- ciclo de vida de tokens FCM;
- política de cola BullMQ y fallback sincrónico;
- frontera con silent messages (resiliencia de red).

Fuera del canon:
- UI específica de admin (formularios, tablas);
- textos de notificación o plantillas;
- política comercial de frecuencia o campañas.

---

## 3. Transporte y cola

- transporte push: **Firebase Cloud Messaging (FCM)**. No existe fallback por SMS ni email.
- cola: **BullMQ `notifications`** (constante `NOTIFICATIONS_QUEUE = 'notifications'`, `notifications.service.ts:34`).
- opciones de job (`notifications.service.ts:64-72`):
  - `attempts: 3`;
  - `backoff: { type: 'exponential', delay: 2000 }` (2s → 4s → 8s);
  - `removeOnComplete: { count: 100 }`;
  - `removeOnFail: { count: 50 }`.
- modo degradado: sin Redis/BullMQ, el servicio cae a envío síncrono en el request. La degradación no debe propagarse al caller como error.
- failed set: jobs que agotan 3 intentos quedan en el failed set del queue, loggeados, sin throw hacia el emisor original.

---

## 4. Superficie pública de envío

Servicio: `NotificationsService` (`sacdia-backend/src/notifications/notifications.service.ts`).

| Método | Alcance | Pattern | Línea |
|--------|---------|---------|-------|
| `sendToUser(dto, sentBy, source?)` | 1 usuario | request/response | 128 |
| `broadcast(dto, sentBy, source?)` | todos los usuarios activos | request/response | 160 |
| `sendToClubMembers(clubSectionId, dto, sentBy, source?)` | miembros de una sección de club | request/response | 195 |
| `sendToSectionRole(clubSectionId, roleNames[], title, body, data?, source?)` | roles dentro de una sección | fire-and-forget | 237 |
| `sendToGlobalRole(roleNames[], title, body, data?, localFieldId?, source?, unionId?)` | roles globales con scope | fire-and-forget | 287 |
| `notifySafe(userId, title, body, data?, source?)` | 1 usuario, sin throw | fire-and-forget | 341 |
| `sendSilentToSection(payload)` | silent (cache invalidation) | fire-and-forget | 372 |

Contrato fire-and-forget: los emisores desde otros features llaman vía `void this.notificationsService.method()` o envuelven en `setImmediate()` para no bloquear la respuesta HTTP del request original.

---

## 5. Endpoints HTTP canonizados

Controller: `notifications.controller.ts`.

### 5.1 Emisión (admin)
- `POST /api/v1/notifications/send` (permiso `notifications:send`);
- `POST /api/v1/notifications/broadcast` (permiso `notifications:broadcast`);
- `POST /api/v1/notifications/club/:instanceType/:instanceId` (permiso `notifications:club`, enforcement por `active_assignment`).

### 5.2 Bandeja del usuario
- `GET /api/v1/notifications/history` — historial paginado. Admins ven auditoría; usuario regular ve su bandeja.
- `GET /api/v1/notifications/unread-count` — conteo de `notification_deliveries` con `read_at IS NULL`;
- `PATCH /api/v1/notifications/read-all`;
- `PATCH /api/v1/notifications/:deliveryId/read`.

### 5.3 Preferencias por categoría
- `GET /api/v1/notifications/preferences`;
- `PUT /api/v1/notifications/preferences/:category` (body: `{ enabled: boolean }`).

### 5.4 Tokens FCM
Controller: `FcmTokensController` (en el mismo archivo).
- `POST /api/v1/fcm-tokens` — registrar token al autenticarse;
- `DELETE /api/v1/fcm-tokens/by-token` — desregistrar por valor de token;
- `DELETE /api/v1/fcm-tokens/:id` — desregistrar por id del registro;
- `GET /api/v1/fcm-tokens` — tokens activos del usuario;
- `GET /api/v1/fcm-tokens/user/:userId` — solo owner o admin.

---

## 6. Persistencia canonizada

### 6.1 `notification_logs` (`schema.prisma:1108-1128`)
Auditoría por envío (no por recipient). Campos clave:
- `log_id` (int, autoincrement);
- `type` ∈ `{ USER, CLUB, BROADCAST, SECTION_ROLE, GLOBAL_ROLE }`;
- `target_type` ∈ `{ user, club_section, all, section_role, global_role }`;
- `target_id` (nullable);
- `sent_by` (uuid, admin emisor o `null` si automático);
- `source` (varchar 100) — **tag obligatorio** para trazabilidad (ej. `admin:manual_send`, `camporees:late_registration`, `achievements:unlocked`);
- `tokens_sent`, `tokens_failed` — métricas FCM.

### 6.2 `notification_deliveries` (`schema.prisma:1130-1144`)
Una fila por recipient:
- `delivery_id` (uuid, PK);
- `log_id` (FK a `notification_logs`);
- `user_id`;
- `read_at` (nullable) — `null` ⇒ unread.
- uniqueness: `(log_id, user_id)`.
- índices: `(user_id, read_at)`, `(user_id, created_at DESC)` para bandeja.

### 6.3 `notification_preferences` (`schema.prisma:1093-1106`)
Opt-out por categoría:
- `(user_id, category)` único;
- `enabled` default `true`;
- si no hay fila, asumir `enabled = true` (opt-out, no opt-in).

### 6.4 `user_fcm_tokens` (`schema.prisma:1146-1161`)
- `token` (varchar 255, unique);
- `device_type`, `device_name` (nullables);
- `active` (boolean) — se desactiva en errores FCM permanentes (ver §8);
- `last_used` (timestamptz) — actualizado en cada push exitoso.

---

## 7. Política de persistencia vs opt-out

Flujo canónico para envío visible (`handleSendToUser` y hermanos):

1. resolver usuarios destinatarios (por user id, por sección, por rol, o todos los activos);
2. filtrar por preferencias: si `notification_preferences(user_id, category).enabled = false`, **excluir al usuario por completo** — no se crea `notification_delivery` ni se envía FCM;
3. crear `notification_log` con `source` y `target_*`;
4. crear `notification_delivery` para cada usuario **no excluido por opt-out**, aun si no tiene tokens activos (la bandeja se puebla igual);
5. enviar FCM `sendMulticast` solo a tokens activos del subconjunto;
6. actualizar `tokens_sent` / `tokens_failed` en el log.

Invariante: un usuario opted-out **no recibe push y tampoco aparece en bandeja** para esa categoría. La bandeja respeta el opt-out.

---

## 8. Ciclo de vida de tokens FCM

- registro: la app llama `POST /fcm-tokens` al iniciar sesión y obtener token. Un usuario puede tener múltiples tokens activos (múltiples dispositivos).
- uso: cada push exitoso actualiza `last_used`.
- desactivación automática: si FCM responde con uno de los códigos permanentes, el token se marca `active = false` (`notifications.processor.ts:102, 822-843`). Códigos permanentes canonizados:
  - `messaging/invalid-registration-token`;
  - `messaging/registration-token-not-registered`;
  - `messaging/invalid-argument`.
- cleanup programado: `CleanupService` (`sacdia-backend/src/common/services/cleanup.service.ts:29`, `@Cron(EVERY_6_HOURS)`) purga tokens inactivos antiguos.
- desregistro explícito: logout en la app dispara `DELETE /fcm-tokens/by-token` con el valor actual.

---

## 9. Silent messages (frontera con resiliencia de red)

El processor `handleRealtimeInvalidate` (`notifications.processor.ts:678`) comparte la cola pero **no pertenece al path visible**:

- no crea `notification_log`;
- no crea `notification_deliveries`;
- el payload FCM es **data-only**, sin `notification` object;
- APNS `content-available: 1`, Android `priority: high`;
- `actorId` se usa para excluir al emisor del fanout.

Autoridad: `docs/canon/runtime-resiliencia-red.md` §2.3 y §5. No duplicar política allí.

---

## 10. Emisores canónicos del runtime

Features del backend que emiten notificaciones visibles (verificado 2026-04-22):

| Feature | Archivo | Método(s) | Tag `source` típico |
|---------|---------|-----------|---------------------|
| Camporees | `sacdia-backend/src/camporees/camporees.service.ts` | `sendToGlobalRole` | `camporees:late_*` |
| Activities reminder | `sacdia-backend/src/activities/activities-reminder.service.ts` | `sendToClubMembers` | `activities:reminder` |
| Investiture | `sacdia-backend/src/investiture/investiture.service.ts` | `sendToGlobalRole` | `investiture:*` |
| Requests | `sacdia-backend/src/requests/requests.service.ts` | `sendToSectionRole`, `sendToGlobalRole` | `requests:*` |
| Validation | `sacdia-backend/src/validation/validation.service.ts` | `sendToSectionRole` | `validation:*` |
| Achievements | `sacdia-backend/src/achievements/achievements.processor.ts` | `notifySafe` | `achievements:*` |

Cualquier feature nuevo que emita notificaciones debe:
1. declarar un `source` único y trazable;
2. usar el método de `NotificationsService` que mejor describa su alcance;
3. no propagar excepciones del envío al flujo principal (fire-and-forget).

---

## 11. Clientes

### 11.1 App móvil (Flutter)
Servicio: `sacdia-app/lib/core/notifications/push_notification_service.dart`.
- registro de token al `initialize()`;
- distinción foreground/background;
- routing de taps contra whitelist de `RouteNames`;
- handling tipado para `member_of_month` y `achievement_unlocked`;
- inbox con paginación vía `notificationsInboxProvider` (Riverpod).

### 11.2 Admin web (Next.js)
Página: `sacdia-admin/src/app/(dashboard)/dashboard/notifications/page.tsx`.
- `DirectNotificationForm` (1 usuario);
- `BroadcastNotificationForm` (todos);
- `ClubNotificationForm` (por sección).
- requiere `requireAdminUser()`.

---

## 12. Relación con otros canones

- `docs/canon/runtime-sacdia.md` — topología general del runtime.
- `docs/canon/runtime-resiliencia-red.md` — silent messages y política de invalidación (usa la misma cola, path distinto).
- `docs/canon/dominio-sacdia.md` — trayectoria y operación institucional del miembro.
- `docs/canon/decisiones-clave.md` — decisión 14 (comunicaciones visibles son canon operativo).

---

## 13. Invariantes

- todo envío visible crea `notification_log` + al menos una `notification_delivery` por recipient **no excluido por opt-out**, incluso si no hay tokens activos;
- un usuario con `enabled = false` en la categoría no recibe push ni entrada en bandeja;
- los silent messages (cache invalidation) **jamás** crean log ni delivery;
- un token FCM que responde con un código permanente debe marcarse `active = false` antes del siguiente envío;
- el fallo del transporte FCM o de la cola no puede propagarse como error al endpoint o feature que originó el envío;
- cada envío debe llevar un `source` trazable no vacío.
