# Walkthrough: Push Notifications (Firebase Cloud Messaging)

**Módulo**: Push Notifications
**Tecnología**: Firebase Cloud Messaging (FCM)
**Versión API**: 2.2
**Fecha**: 3 de febrero de 2026

---

## 📋 Descripción General

El módulo de **Push Notifications** proporciona un sistema completo de notificaciones push usando Firebase Cloud Messaging (FCM), permitiendo:

- Registro de tokens FCM por dispositivo (iOS, Android, Web)
- Envío de notificaciones a usuarios individuales
- Envío masivo a clubs completos
- Auto-cleanup de tokens expirados
- Soporte para múltiples dispositivos por usuario

**Características**:
- ✅ Multi-device support (máximo recomendado: 5 tokens por usuario)
- ✅ Envío de notificaciones con título, body y data custom
- ✅ Gestión de tokens activos/inactivos
- ✅ Integración con Firebase Admin SDK

---

## 🔧 Configuración Previa

### 1. Crear Proyecto de Firebase

1. Ir a https://console.firebase.google.com/
2. Click en "Add project" o "Agregar proyecto"
3. Nombre: `sacdia-production`
4. Habilitar Google Analytics (opcional)
5. Click "Create project"

### 2. Habilitar Cloud Messaging

1. En el proyecto, ir a "Build" → "Cloud Messaging"
2. Click en el ícono de engranaje → "Project settings"
3. Ir a "Cloud Messaging" tab
4. **Habilitar Cloud Messaging API** en Google Cloud Console
5. Anotar el **Server Key** (legacy, para referencia)

### 3. Generar Service Account Key

1. En Project Settings, ir a "Service accounts"
2. Click "Generate new private key"
3. Se descarga archivo JSON con credenciales
4. **Guardar de forma segura** (no commitear a Git)

Ejemplo del archivo JSON:

```json
{
  "type": "service_account",
  "project_id": "sacdia-production",
  "private_key_id": "abc123...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xyz@sacdia-production.iam.gserviceaccount.com",
  "client_id": "123456789",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/..."
}
```

### 4. Configurar Variables de Entorno

Agregar al `.env` del backend:

```bash
FIREBASE_PROJECT_ID=sacdia-production
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xyz@sacdia-production.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

**IMPORTANTE**: El `FIREBASE_PRIVATE_KEY` debe tener `\n` como saltos de línea literales (no interpretados).

---

## 🎯 Flujo Completo

### Flujo General

```mermaid
sequenceDiagram
    participant App (iOS/Android)
    participant Backend
    participant FCM
    participant Device

    App->>FCM: Solicitar token FCM
    FCM-->>App: Token generado
    App->>Backend: POST /users/:userId/fcm-tokens { fcm_token, device_type }
    Backend->>Backend: Guardar en BD
    Backend-->>App: Token registrado

    Backend->>Backend: Evento (ej: nueva actividad)
    Backend->>FCM: sendMulticast({ tokens, notification, data })
    FCM->>Device: Push notification
    Device->>App: Mostrar notificación
```

---

## 📱 Implementación Cliente

### iOS (Swift)

```swift
import FirebaseMessaging

// 1. Solicitar permiso de notificaciones
UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
    if granted {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}

// 2. Obtener token FCM
Messaging.messaging().token { token, error in
    if let error = error {
        print("Error fetching FCM token: \(error)")
    } else if let token = token {
        print("FCM token: \(token)")

        // 3. Registrar token en backend
        registerFcmToken(userId: currentUserId, token: token, deviceType: "ios")
    }
}

// 4. Función para registrar en backend
func registerFcmToken(userId: String, token: String, deviceType: String) {
    let url = URL(string: "https://api.sacdia.app/api/v1/users/\(userId)/fcm-tokens")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = [
        "fcm_token": token,
        "device_type": deviceType,
        "device_name": UIDevice.current.name
    ]

    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    URLSession.shared.dataTask(with: request) { data, response, error in
        // Handle response
    }.resume()
}
```

### Android (Kotlin)

```kotlin
import com.google.firebase.messaging.FirebaseMessaging

// 1. Obtener token FCM
FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
    if (!task.isSuccessful) {
        Log.w(TAG, "Fetching FCM token failed", task.exception)
        return@addOnCompleteListener
    }

    val token = task.result
    Log.d(TAG, "FCM token: $token")

    // 2. Registrar token en backend
    registerFcmToken(userId, token, "android")
}

// 3. Función para registrar en backend
fun registerFcmToken(userId: String, token: String, deviceType: String) {
    val url = "https://api.sacdia.app/api/v1/users/$userId/fcm-tokens"

    val json = JSONObject().apply {
        put("fcm_token", token)
        put("device_type", deviceType)
        put("device_name", Build.MODEL)
    }

    val request = Request.Builder()
        .url(url)
        .post(json.toString().toRequestBody("application/json".toMediaType()))
        .addHeader("Authorization", "Bearer $authToken")
        .build()

    client.newCall(request).enqueue(object : Callback {
        override fun onResponse(call: Call, response: Response) {
            // Handle response
        }
    })
}

// 4. Crear servicio para recibir notificaciones
class MyFirebaseMessagingService : FirebaseMessagingService() {
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        remoteMessage.notification?.let {
            showNotification(it.title, it.body)
        }
    }

    override fun onNewToken(token: String) {
        // Token actualizado, registrar nuevamente
        registerFcmToken(currentUserId, token, "android")
    }
}
```

### Flutter

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationsService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize(String userId) async {
    // 1. Solicitar permiso
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Obtener token
      String? token = await _fcm.getToken();
      if (token != null) {
        // 3. Registrar en backend
        await registerFcmToken(userId, token);
      }

      // 4. Escuchar actualizaciones de token
      _fcm.onTokenRefresh.listen((newToken) {
        registerFcmToken(userId, newToken);
      });

      // 5. Manejar notificaciones foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        showLocalNotification(message);
      });
    }
  }

  Future<void> registerFcmToken(String userId, String token) async {
    final response = await dio.post(
      '/api/v1/users/$userId/fcm-tokens',
      data: {
        'fcm_token': token,
        'device_type': Platform.isIOS ? 'ios' : 'android',
        'device_name': await getDeviceName(),
      },
    );
  }
}
```

---

## 🚀 API Endpoints

### 1. Registrar Token FCM

**Endpoint**: `POST /api/v1/users/:userId/fcm-tokens`
**Autenticación**: Requerida

**Request Body**:

```json
{
  "fcm_token": "fUbHlTxsQz2...",
  "device_type": "ios",
  "device_name": "iPhone 14 de Juan"
}
```

**Request**:

```bash
curl -X POST http://localhost:3000/api/v1/users/uuid-123/fcm-tokens \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "fcm_token": "fUbHlTxsQz2e3rF5g6h7j8k9l0m1n2o3p4q5r6s7t8u9v0w1x2y3z4",
    "device_type": "ios",
    "device_name": "iPhone 14 de Juan"
  }'
```

**Response** (201 Created):

```json
{
  "status": "success",
  "data": {
    "token_id": "uuid-token-1",
    "user_id": "uuid-123",
    "fcm_token": "fUbHlTxsQz2e3rF5g6h7j8k9l0m1n2o3p4q5r6s7t8u9v0w1x2y3z4",
    "device_type": "ios",
    "device_name": "iPhone 14 de Juan",
    "is_active": true,
    "created_at": "2026-02-03T10:00:00.000Z"
  }
}
```

**Validaciones**:
- ✅ Si el token ya existe, lo retorna (no crea duplicado)
- ✅ `device_type` debe ser "ios", "android" o "web"
- ✅ `fcm_token` es único en la tabla

---

### 2. Listar Tokens de un Usuario

**Endpoint**: `GET /api/v1/users/:userId/fcm-tokens`
**Autenticación**: Requerida

**Request**:

```bash
curl -X GET http://localhost:3000/api/v1/users/uuid-123/fcm-tokens \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": [
    {
      "token_id": "uuid-token-1",
      "fcm_token": "fUbHlTxsQz2...",
      "device_type": "ios",
      "device_name": "iPhone 14 de Juan",
      "is_active": true,
      "created_at": "2026-02-03T10:00:00.000Z"
    },
    {
      "token_id": "uuid-token-2",
      "fcm_token": "gVcImUytRa3...",
      "device_type": "android",
      "device_name": "Samsung Galaxy S23",
      "is_active": true,
      "created_at": "2026-01-15T14:30:00.000Z"
    }
  ]
}
```

---

### 3. Eliminar Token (Desactivar)

**Endpoint**: `DELETE /api/v1/fcm-tokens/:tokenId`
**Autenticación**: Requerida

**Request**:

```bash
curl -X DELETE http://localhost:3000/api/v1/fcm-tokens/uuid-token-1 \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "message": "FCM token deleted successfully"
}
```

**Nota**: Marca `is_active = false` (soft delete).

---

## 📤 Enviar Notificaciones (Backend)

### Enviar a Usuario Individual

```typescript
// notifications.service.ts
async sendToUser(
  userId: string,
  title: string,
  body: string,
  data?: Record<string, string>
) {
  // 1. Obtener tokens activos del usuario
  const tokens = await this.prisma.user_fcm_tokens.findMany({
    where: {
      user_id: userId,
      is_active: true
    },
    select: { fcm_token: true }
  });

  if (tokens.length === 0) {
    return {
      success: false,
      message: 'No active tokens'
    };
  }

  // 2. Preparar mensaje
  const message: admin.messaging.MulticastMessage = {
    notification: {
      title: title,
      body: body
    },
    data: data || {},
    tokens: tokens.map(t => t.fcm_token)
  };

  // 3. Enviar con FCM
  const response = await this.firebase.messaging.sendMulticast(message);

  // 4. Desactivar tokens que fallaron
  if (response.failureCount > 0) {
    const failedTokens = response.responses
      .map((resp, idx) => resp.success ? null : tokens[idx].fcm_token)
      .filter(token => token !== null);

    await this.prisma.user_fcm_tokens.updateMany({
      where: { fcm_token: { in: failedTokens } },
      data: { is_active: false }
    });
  }

  return {
    success: response.successCount > 0,
    successCount: response.successCount,
    failureCount: response.failureCount
  };
}
```

**Uso desde otro módulo**:

```typescript
// activities.service.ts
async createActivity(clubId: number, dto: CreateActivityDto) {
  const activity = await this.prisma.activities.create({ data: dto });

  // Enviar notificación a miembros del club
  const members = await this.getClubMembers(clubId);

  for (const member of members) {
    await this.notificationsService.sendToUser(
      member.user_id,
      'Nueva Actividad',
      `Se ha creado la actividad: ${activity.name}`,
      {
        type: 'activity_created',
        activity_id: activity.id.toString()
      }
    );
  }

  return activity;
}
```

---

### Enviar a Club Completo

```typescript
async sendToClub(clubId: number, title: string, body: string, data?: Record<string, string>) {
  // 1. Obtener miembros del club
  const members = await this.prisma.club_role_assignments.findMany({
    where: {
      club_pathf_id: clubId,  // o club_adv_id, club_mg_id según tipo
      active: true
    },
    select: { user_id: true }
  });

  const userIds = members.map(m => m.user_id);

  // 2. Enviar a cada usuario
  const results = await Promise.all(
    userIds.map(userId => this.sendToUser(userId, title, body, data))
  );

  // 3. Agregar resultados
  const totalSuccess = results.reduce((sum, r) => sum + (r.successCount || 0), 0);
  const totalFailure = results.reduce((sum, r) => sum + (r.failureCount || 0), 0);

  return {
    success: true,
    sent: totalSuccess,
    failed: totalFailure,
    members: userIds.length
  };
}
```

**Uso**:

```typescript
// En activities.controller.ts o service
await this.notificationsService.sendToClub(
  clubId,
  'Reunión Mañana',
  'No olvides asistir a la reunión de club mañana a las 5pm',
  {
    type: 'reminder',
    activity_id: '123'
  }
);
```

---

## 💡 Casos de Uso

### Caso 1: Usuario Registra Nuevo Dispositivo

**Escenario**: Usuario instala la app en un nuevo teléfono.

**Flujo**:

1. **App solicita token a FCM**
   ```swift
   Messaging.messaging().token { token, error in ... }
   ```

2. **App registra token en backend**
   ```bash
   POST /api/v1/users/:userId/fcm-tokens
   Body: { fcm_token: "nuevo-token", device_type: "ios", device_name: "iPhone 15" }
   ```

3. **Backend guarda token**
   ```typescript
   const existing = await prisma.user_fcm_tokens.findUnique({
     where: { fcm_token: dto.fcm_token }
   });

   if (existing) return existing;  // Ya existe, no duplicar

   return await prisma.user_fcm_tokens.create({ data: dto });
   ```

4. **Usuario ahora recibe notificaciones en ambos dispositivos**

---

### Caso 2: Nueva Actividad Creada

**Escenario**: Director crea una nueva actividad y todos los miembros deben recibir notificación.

**Flujo**:

1. **Director crea actividad**
   ```bash
   POST /api/v1/clubs/1/activities
   Body: { name: "Reunión Semanal", date: "2026-02-10T17:00:00Z" }
   ```

2. **Backend crea actividad**
   ```typescript
   const activity = await prisma.activities.create({ data: dto });
   ```

3. **Backend envía notificaciones**
   ```typescript
   await notificationsService.sendToClub(
     clubId,
     'Nueva Actividad',
     `${director.name} ha creado: ${activity.name}`,
     {
       type: 'activity_created',
       activity_id: activity.id.toString(),
       club_id: clubId.toString()
     }
   );
   ```

4. **FCM envía a todos los dispositivos activos**

5. **Usuarios reciben notificación en sus teléfonos**

---

### Caso 3: Token Expirado o Inválido

**Escenario**: Usuario desinstala la app o el token expira.

**Flujo**:

1. **Backend intenta enviar notificación**
   ```typescript
   const response = await firebase.messaging.sendMulticast(message);
   ```

2. **FCM responde con error**
   ```typescript
   response.failureCount = 1
   response.responses[0].error.code = 'messaging/invalid-registration-token'
   ```

3. **Backend desactiva token automáticamente**
   ```typescript
   await prisma.user_fcm_tokens.updateMany({
     where: { fcm_token: { in: failedTokens } },
     data: { is_active: false }
   });
   ```

4. **Token ya no será usado en futuros envíos**

---

### Caso 4: Usuario con 3 Dispositivos

**Escenario**: Usuario tiene iPhone, iPad y Android.

**Flujo**:

1. **Usuario registra cada dispositivo**
   - iPhone: Token A
   - iPad: Token B
   - Android: Token C

2. **Backend guarda 3 tokens activos**
   ```sql
   SELECT * FROM user_fcm_tokens WHERE user_id = 'uuid-123' AND is_active = true;
   -- Retorna 3 filas
   ```

3. **Backend envía notificación**
   ```typescript
   await sendToUser('uuid-123', 'Hola', 'Nueva actividad');
   ```

4. **FCM envía a los 3 dispositivos simultáneamente**

5. **Usuario ve la notificación en sus 3 dispositivos**

---

## 🔒 Validaciones y Errores

### Error 1: Token Duplicado

**Causa**: Intentar registrar un token que ya existe.

**Comportamiento**: Backend retorna el token existente sin error (idempotente).

**Response** (201 Created):

```json
{
  "status": "success",
  "data": {
    "token_id": "existing-uuid",
    "fcm_token": "token-ya-existente"
  }
}
```

---

### Error 2: Tipo de Dispositivo Inválido

**Causa**: `device_type` no es "ios", "android" o "web".

**Response** (400 Bad Request):

```json
{
  "statusCode": 400,
  "message": ["device_type must be one of: ios, android, web"],
  "error": "Bad Request"
}
```

---

### Error 3: Firebase No Configurado

**Causa**: Variables de entorno de Firebase no están configuradas.

**Response** (500 Internal Server Error):

```json
{
  "statusCode": 500,
  "message": "Firebase Admin SDK not configured",
  "error": "Internal Server Error"
}
```

**Solución**: Configurar `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`.

---

### Error 4: Token Expirado/Inválido al Enviar

**Comportamiento**:
- FCM retorna error `messaging/invalid-registration-token`
- Backend desactiva automáticamente el token
- No se muestra error al usuario (envío continúa a otros dispositivos)

---

## 📊 Modelo de Base de Datos

### Tabla: `user_fcm_tokens`

```prisma
model user_fcm_tokens {
  token_id       String   @id @default(uuid()) @db.Uuid
  user_id        String   @db.Uuid
  fcm_token      String   @unique
  device_type    String   // 'ios' | 'android' | 'web'
  device_name    String?
  is_active      Boolean  @default(true)
  created_at     DateTime @default(now())
  updated_at     DateTime @updatedAt

  users          users    @relation(fields: [user_id], references: [id], onDelete: Cascade)

  @@index([user_id])
  @@index([is_active])
  @@map("user_fcm_tokens")
}
```

---

## 🧪 Testing

### Test E2E: `notifications.e2e-spec.ts`

```typescript
describe('Push Notifications API (e2e)', () => {
  let mockToken: string;

  beforeAll(() => {
    mockToken = 'mock-fcm-token-' + Math.random();
  });

  it('POST /users/:userId/fcm-tokens - should register token', async () => {
    const response = await request(app.getHttpServer())
      .post(`/api/v1/users/${userId}/fcm-tokens`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        fcm_token: mockToken,
        device_type: 'ios',
        device_name: 'Test iPhone'
      })
      .expect(201);

    expect(response.body.data.fcm_token).toBe(mockToken);
  });

  it('POST /users/:userId/fcm-tokens - should be idempotent', async () => {
    // Primer registro
    await request(app.getHttpServer())
      .post(`/api/v1/users/${userId}/fcm-tokens`)
      .set('Authorization', `Bearer ${token}`)
      .send({ fcm_token: mockToken, device_type: 'ios' })
      .expect(201);

    // Segundo registro (mismo token)
    const response = await request(app.getHttpServer())
      .post(`/api/v1/users/${userId}/fcm-tokens`)
      .set('Authorization', `Bearer ${token}`)
      .send({ fcm_token: mockToken, device_type: 'ios' })
      .expect(201);

    // Debe retornar el mismo registro
    expect(response.body.data.fcm_token).toBe(mockToken);
  });

  it('GET /users/:userId/fcm-tokens - should list tokens', async () => {
    const response = await request(app.getHttpServer())
      .get(`/api/v1/users/${userId}/fcm-tokens`)
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    expect(Array.isArray(response.body.data)).toBe(true);
  });

  it('DELETE /fcm-tokens/:tokenId - should delete token', async () => {
    await request(app.getHttpServer())
      .delete(`/api/v1/fcm-tokens/${tokenId}`)
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    const dbToken = await prisma.user_fcm_tokens.findUnique({
      where: { token_id: tokenId }
    });

    expect(dbToken.is_active).toBe(false);
  });
});
```

---

## 📝 Notas Importantes

1. **Multi-Device**: Un usuario puede tener múltiples tokens activos (máximo recomendado: 5).

2. **Auto-Cleanup**: Los tokens inválidos se desactivan automáticamente al fallar el envío.

3. **Soft Delete**: Los tokens usan `is_active = false` en lugar de eliminación física.

4. **Batch Sending**: Para envíos masivos, FCM recomienda usar `sendMulticast` (hasta 500 tokens por request).

5. **Rate Limits**: FCM tiene rate limits. Ver documentación de Firebase para límites actuales.

6. **Data Payload**: El campo `data` es opcional y puede contener información custom para la app.

7. **Permisos**: Solo el dueño del token puede eliminarlo.

8. **Token Refresh**: Los tokens FCM pueden cambiar. La app debe actualizar el token cuando recibe `onTokenRefresh`.

---

## 🔗 Referencias

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Firebase Admin SDK (Node.js)](https://firebase.google.com/docs/admin/setup)
- [FCM HTTP v1 API](https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages)

---

**Documento creado**: 2026-02-03
**Versión**: 1.0
**Autor**: Sistema SACDIA
