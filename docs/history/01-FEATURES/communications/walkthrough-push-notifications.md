# Walkthrough: Push Notifications (Firebase Cloud Messaging)

**Módulo**: Push Notifications  
**Tecnología**: Firebase Cloud Messaging (FCM)  
**Versión API**: 2.3  
**Fecha**: 2026-02-13

---

## Descripción General

Este módulo cubre:

- Registro de tokens FCM por dispositivo.
- Envío de notificaciones a usuario individual.
- Envío de notificaciones masivas y por club.
- Gestión de ownership de tokens.
- Limpieza de tokens inválidos.

> [!IMPORTANT]
> Contrato vigente desde 2026-02-13:
> - `POST /api/v1/fcm-tokens` **no** recibe `userId` en body.
> - El backend toma `userId` desde el JWT autenticado.
> - `broadcast` y `club` están restringidos a roles `admin|super_admin`.

---

## Endpoints Vigentes

### Gestión de Tokens

- `POST /api/v1/fcm-tokens` (JWT)
- `GET /api/v1/fcm-tokens` (JWT)
- `DELETE /api/v1/fcm-tokens/:token` (JWT)
- `GET /api/v1/fcm-tokens/user/:userId` (JWT, owner/admin; compatibilidad)

### Envío

- `POST /api/v1/notifications/send` (JWT)
- `POST /api/v1/notifications/broadcast` (JWT + `admin|super_admin`)
- `POST /api/v1/notifications/club/:instanceType/:instanceId` (JWT + `admin|super_admin`)

---

## Request/Response de Referencia

### 1) Registrar token

```http
POST /api/v1/fcm-tokens
Authorization: Bearer <JWT>
Content-Type: application/json

{
  "token": "fcm-device-token-abc...",
  "device_type": "ios",
  "device_name": "iPhone 14 Pro"
}
```

```json
{
  "fcm_token_id": "uuid-token-1",
  "user_id": "uuid-from-jwt",
  "token": "fcm-device-token-abc...",
  "device_type": "ios",
  "device_name": "iPhone 14 Pro",
  "active": true
}
```

### 2) Listar tokens propios

```http
GET /api/v1/fcm-tokens
Authorization: Bearer <JWT>
```

### 3) Desactivar token propio

```http
DELETE /api/v1/fcm-tokens/fcm-device-token-abc...
Authorization: Bearer <JWT>
```

### 4) Enviar notificación a usuario

```http
POST /api/v1/notifications/send
Authorization: Bearer <JWT>
Content-Type: application/json

{
  "userId": "uuid-target",
  "title": "Nueva actividad",
  "body": "Se creó una actividad en tu club",
  "data": {
    "type": "activity_created",
    "activity_id": "456"
  }
}
```

### 5) Broadcast (solo admin/super_admin)

```http
POST /api/v1/notifications/broadcast
Authorization: Bearer <JWT_ADMIN>
Content-Type: application/json

{
  "title": "Anuncio general",
  "body": "Mantenimiento programado",
  "data": { "type": "announcement" }
}
```

---

## Configuración Firebase

Variables de entorno requeridas:

```bash
FIREBASE_PROJECT_ID=...
FIREBASE_CLIENT_EMAIL=...
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

Notas:

- `FIREBASE_PRIVATE_KEY` debe conservar saltos de línea como `\n`.
- Si la clave PEM es inválida, FCM queda deshabilitado y health reporta `initialized: false`.

---

## Ejemplo de Cliente (Flutter)

```dart
Future<void> registerFcmToken(Dio dio, String token, String deviceName) async {
  await dio.post(
    '/api/v1/fcm-tokens',
    data: {
      'token': token,
      'device_type': 'android',
      'device_name': deviceName,
    },
  );
}
```

```dart
Future<void> removeFcmToken(Dio dio, String token) async {
  await dio.delete('/api/v1/fcm-tokens/$token');
}
```

---

## Seguridad y Autorización

- Sin JWT: `401`.
- JWT válido sin rol admin en `broadcast/club`: `403`.
- Usuario autenticado solo opera sus tokens.
- Endpoint de compatibilidad por `userId` queda limitado a owner/admin.

---

## Verificación Recomendada

```bash
pnpm run build
pnpm run test -- src/notifications/fcm-tokens.service.spec.ts
pnpm run test:e2e -- test/notifications-security.e2e-spec.ts
pnpm prisma migrate deploy
pnpm run verify:fcm-migration
```

---

## Referencias

- `docs/02-API/EXTERNAL-SERVICES-INTEGRATION.md`
- `docs/02-API/ENDPOINTS-REFERENCE.md`
- `sacdia-backend/src/notifications/notifications.controller.ts`
- `sacdia-backend/src/notifications/fcm-tokens.service.ts`
