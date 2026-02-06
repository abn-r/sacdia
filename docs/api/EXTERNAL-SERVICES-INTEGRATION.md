# Integración de Servicios Externos

**Versión**: 1.0  
**Fecha**: 2026-02-04  
**Status**: ⚠️ Pendiente de Configuración

---

## 📋 Resumen

Este documento detalla la integración de tres servicios externos críticos en el backend de SACDIA:

1. **Upstash Redis** - Cache distribuido
2. **Firebase Cloud Messaging (FCM)** - Notificaciones push
3. **Sentry** - Monitoreo de errores

---

## 🎯 Objetivo

Implementar servicios externos escalables para:

- Mejorar el rendimiento mediante caching distribuido
- Habilitar comunicación en tiempo real vía push notifications
- Monitorear y detectar errores proactivamente en producción

---

## 1️⃣ Upstash Redis

### Descripción

Redis en la nube (serverless) para cache distribuido, reemplazando el cache en memoria por una solución compartida entre instancias.

### Casos de Uso

- **Token blacklist**: Tokens JWT invalidados
- **Sesiones**: Datos de sesión de usuarios
- **MFA codes**: Códigos de autenticación temporal
- **Rate limiting**: Control de tasa de requests

### Configuración

#### Variables de Entorno

```bash
# .env
REDIS_URL=redis://default:password@region.upstash.io:port
```

#### Implementación

**Archivo**: `src/common/common.module.ts`

```typescript
CacheModule.registerAsync({
  isGlobal: true,
  useFactory: async (configService: ConfigService) => {
    const redisUrl = configService.get<string>('REDIS_URL');

    if (redisUrl) {
      const redisStore = await import('cache-manager-redis-yet').then(
        (m) => m.redisStore,
      );
      return {
        store: redisStore,
        url: redisUrl,
        ttl: 86400000, // 24 hours
      };
    }

    // Fallback a in-memory
    return {
      ttl: 86400000,
      max: 10000,
    };
  },
  inject: [ConfigService],
}),
```

### Beneficios

✅ **Escalabilidad**: Cache compartido entre múltiples instancias  
✅ **Persistencia**: Datos sobreviven reinicio de servidor  
✅ **Performance**: Latencia ultra-baja (<1ms en misma región)  
✅ **Costo**: Tier gratuito hasta 10K requests/día

### Verificación

```bash
# 1. Login de usuario (genera token)
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"pass123"}'

# 2. Revisar Upstash Console
# Ver que se guardaron datos en Redis
```

---

## 2️⃣ Firebase Cloud Messaging (FCM)

### Descripción

Servicio de Google para enviar notificaciones push a dispositivos móviles (iOS, Android, Web).

### Arquitectura

```mermaid
sequenceDiagram
    participant App as Mobile App
    participant Backend as SACDIA Backend
    participant FCM as Firebase FCM
    participant Device as User Device

    App->>Backend: POST /fcm-tokens (register token)
    Backend->>Backend: Save to user_fcm_tokens table

    Note over Backend: Event occurs (e.g., new activity)
    Backend->>Backend: Get user tokens
    Backend->>FCM: sendMulticast(tokens, message)
    FCM->>Device: Deliver notification
    Device->>App: Display notification
```

### Módulos Implementados

#### NotificationsModule

**Servicios**:

- `NotificationsService` - Lógica de envío
- `FcmTokensService` - Gestión de tokens

**Controladores**:

- `NotificationsController` - Endpoints de envío
- `FcmTokensController` - Endpoints de tokens

### Endpoints

#### 1. Registrar Token FCM

```http
POST /api/v1/fcm-tokens
Content-Type: application/json

{
  "userId": "uuid-123",
  "token": "fcm-device-token-abc...",
  "device_type": "ios",
  "device_name": "iPhone 14 Pro"
}
```

**Response** (201):

```json
{
  "fcm_token_id": "uuid-token-1",
  "user_id": "uuid-123",
  "token": "fcm-device-token-abc...",
  "device_type": "ios",
  "device_name": "iPhone 14 Pro",
  "active": true,
  "created_at": "2026-02-04T10:00:00.000Z"
}
```

#### 2. Enviar Notificación a Usuario

```http
POST /api/v1/notifications/send
Content-Type: application/json

{
  "userId": "uuid-123",
  "title": "Nueva Actividad",
  "body": "Se ha creado una nueva actividad en tu club",
  "data": {
    "type": "activity_created",
    "activity_id": "456"
  }
}
```

**Response** (200):

```json
{
  "success": true,
  "successCount": 2,
  "failureCount": 0
}
```

#### 3. Broadcast a Todos los Usuarios

```http
POST /api/v1/notifications/broadcast
Content-Type: application/json

{
  "title": "Mantenimiento Programado",
  "body": "El sistema estará en mantenimiento mañana de 2-4am",
  "data": {
    "type": "system_announcement"
  }
}
```

#### 4. Notificar a Miembros de Club

```http
POST /api/v1/notifications/club/:instanceType/:instanceId
Content-Type: application/json

{
  "title": "Reunión Mañana",
  "body": "No olvides asistir a la reunión del club",
  "data": {
    "type": "club_reminder"
  }
}
```

Donde `instanceType` puede ser: `adventurers`, `pathfinders`, `master_guilds`

#### 5. Listar Tokens de Usuario

```http
GET /api/v1/fcm-tokens/user/:userId
```

**Response** (200):

```json
[
  {
    "fcm_token_id": "uuid-1",
    "token": "token-ios...",
    "device_type": "ios",
    "device_name": "iPhone 14",
    "active": true
  },
  {
    "fcm_token_id": "uuid-2",
    "token": "token-android...",
    "device_type": "android",
    "device_name": "Samsung S23",
    "active": true
  }
]
```

#### 6. Eliminar Token

```http
DELETE /api/v1/fcm-tokens/:token
```

### Modelo de Base de Datos

```prisma
model user_fcm_tokens {
  fcm_token_id String   @id @default(dbgenerated("extensions.uuid_generate_v4()")) @db.Uuid
  user_id      String   @db.Uuid
  token        String   @unique @db.VarChar(255)
  device_type  String?  @db.VarChar(50)
  device_name  String?  @db.VarChar(100)
  active       Boolean  @default(true)
  last_used    DateTime @default(now()) @db.Timestamptz(6)
  created_at   DateTime @default(now()) @db.Timestamptz(6)
  modified_at  DateTime @default(now()) @updatedAt @db.Timestamptz(6)

  users users @relation(fields: [user_id], references: [user_id], onDelete: Cascade)

  @@index([user_id])
  @@index([active])
  @@map("user_fcm_tokens")
}
```

### Configuración

#### 1. Crear Proyecto en Firebase Console

1. Ir a [Firebase Console](https://console.firebase.google.com/)
2. Crear nuevo proyecto o seleccionar existente
3. Habilitar "Cloud Messaging" en Project Settings

#### 2. Generar Service Account Key

1. En Project Settings → Service Accounts
2. Click "Generate new private key"
3. Descargar JSON (⚠️ NO commitear a Git)

#### 3. Configurar Variables de Entorno

```bash
# .env
FIREBASE_PROJECT_ID=sacdia-production
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xyz@sacdia-production.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

> **IMPORTANTE**: El `FIREBASE_PRIVATE_KEY` debe tener `\n` como string literal (no interpretado).

### Auto-Cleanup de Tokens Inválidos

El sistema desactiva automáticamente tokens que:

- Devuelven error `invalid-registration-token`
- Fallan al enviar notificación

```typescript
// notifications.service.ts - Snippet
if (response.failureCount > 0) {
  const failedTokens = response.responses
    .map((resp, idx) => (resp.success ? null : tokenStrings[idx]))
    .filter((token): token is string => token !== null);

  if (failedTokens.length > 0) {
    await this.prisma.user_fcm_tokens.updateMany({
      where: { token: { in: failedTokens } },
      data: { active: false },
    });
  }
}
```

### Casos de Uso

#### Ejemplo 1: Nueva Actividad Creada

```typescript
// activities.service.ts
async createActivity(clubId: number, dto: CreateActivityDto) {
  const activity = await this.prisma.activities.create({ data: dto });

  // Notificar a miembros del club
  await this.notificationsService.sendToClubMembers(
    clubId,
    'pathfinders',
    {
      title: 'Nueva Actividad',
      body: `Se creó: ${activity.name}`,
      data: {
        type: 'activity_created',
        activity_id: activity.activity_id.toString(),
      },
    },
  );

  return activity;
}
```

#### Ejemplo 2: Recordatorio de Reunión

```typescript
// Cron job o scheduled task
async sendWeeklyReminder() {
  const clubs = await this.getActiveClubs();

  for (const club of clubs) {
    await this.notificationsService.sendToClubMembers(
      club.id,
      club.type,
      {
        title: 'Reunión Mañana',
        body: 'No olvides asistir a la reunión del club',
        data: { type: 'weekly_reminder' },
      },
    );
  }
}
```

---

## 3️⃣ Sentry Monitoring

### Descripción

Plataforma de monitoreo de errores y performance tracking para detectar y resolver bugs en producción.

### Implementación

#### 1. Inicialización en `main.ts`

```typescript
import * as Sentry from "@sentry/node";
import { nodeProfilingIntegration } from "@sentry/profiling-node";

async function bootstrap() {
  // Inicializar Sentry
  if (process.env.SENTRY_DSN) {
    Sentry.init({
      dsn: process.env.SENTRY_DSN,
      environment: process.env.NODE_ENV || "development",
      tracesSampleRate: process.env.NODE_ENV === "production" ? 0.1 : 1.0,
      profilesSampleRate: process.env.NODE_ENV === "production" ? 0.1 : 1.0,
      integrations: [nodeProfilingIntegration()],
    });
  }

  const app = await NestFactory.create(AppModule);

  // Registrar interceptor global
  app.useGlobalInterceptors(new AuditInterceptor(), new SentryInterceptor());

  await app.listen(3000);
}
```

#### 2. Interceptor Global

**Archivo**: `src/common/interceptors/sentry.interceptor.ts`

```typescript
import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from "@nestjs/common";
import { Observable, throwError } from "rxjs";
import { catchError } from "rxjs/operators";
import * as Sentry from "@sentry/node";

@Injectable()
export class SentryInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    return next.handle().pipe(
      catchError((error) => {
        const request = context.switchToHttp().getRequest();

        Sentry.withScope((scope) => {
          scope.setExtra("requestBody", request.body);
          scope.setExtra("requestQuery", request.query);
          scope.setUser({ id: request.user?.user_id });
          Sentry.captureException(error);
        });

        return throwError(() => error);
      }),
    );
  }
}
```

### Configuración

#### Variables de Entorno

```bash
# .env
SENTRY_DSN=https://abc123@o123456.ingest.sentry.io/7654321
```

#### Obtener DSN

1. Crear cuenta en [Sentry.io](https://sentry.io)
2. Crear nuevo proyecto (Node.js)
3. Copiar DSN desde Project Settings

### Características

✅ **Auto-capture**: Captura automática de excepciones no manejadas  
✅ **Context**: Incluye datos de request, user, query params  
✅ **Performance**: Tracking de transacciones lentas  
✅ **Alertas**: Notificaciones por email/Slack cuando hay errores  
✅ **Release tracking**: Asociar errores con versiones de despliegue

### Dashboard

El dashboard de Sentry muestra:

- Stack traces completos
- Contexto de request (body, headers, user)
- Frecuencia de errores
- Tendencias temporales
- Impacto en usuarios

---

## ⚠️ Limitaciones Conocidas

### Autenticación Temporal

> **IMPORTANTE**: Actualmente los endpoints de notificaciones **NO** tienen autenticación porque los guards no existen aún.

**Antes de producción**:

- [ ] Agregar `@UseGuards(SupabaseGuard)` a controladores
- [ ] Extraer `userId` del JWT token (no del body)
- [ ] Implementar permisos por roles (ej: solo admins pueden broadcast)

---

## 🚀 Pasos Pendientes

### Requeridos Antes de Producción

- [ ] **Migración de BD**: Ejecutar `npx prisma migrate dev --name add_user_fcm_tokens`
- [ ] **Credenciales**: Configurar `.env` production con valores reales
- [ ] **Auth Guards**: Restaurar autenticación en endpoints
- [ ] **Pruebas**: Ejecutar tests end-to-end de notificaciones
- [ ] **Monitoreo**: Configurar alertas en Sentry

### Configuración en Vercel

```bash
# Variables de entorno en Vercel Dashboard
REDIS_URL=redis://...
FIREBASE_PROJECT_ID=sacdia-prod
FIREBASE_CLIENT_EMAIL=...
FIREBASE_PRIVATE_KEY="-----BEGIN..."
SENTRY_DSN=https://...
```

### Verificación Manual

```bash
# 1. Aplicar migración
npx prisma migrate dev

# 2. Iniciar servidor
pnpm run start:dev

# 3. Registrar token
curl -X POST http://localhost:3000/api/v1/fcm-tokens \
  -H "Content-Type: application/json" \
  -d '{"userId":"test-uuid","token":"test-token","device_type":"ios"}'

# 4. Enviar notificación
curl -X POST http://localhost:3000/api/v1/notifications/send \
  -H "Content-Type: application/json" \
  -d '{"userId":"test-uuid","title":"Test","body":"Hello"}'

# 5. Verificar en:
# - Upstash Console (cache keys)
# - Firebase Console (FCM logs)
# - Sentry Dashboard (no errors)
```

---

## 📊 Métricas y Monitoreo

### KPIs a Monitorear

| Métrica                    | Objetivo | Herramienta        |
| -------------------------- | -------- | ------------------ |
| Cache hit rate             | >80%     | Upstash Dashboard  |
| Notification delivery rate | >95%     | Firebase Console   |
| Error rate                 | <0.1%    | Sentry             |
| P95 latency                | <200ms   | Sentry Performance |

### Alertas Recomendadas

**Sentry**:

- Error rate > 10 errores/min
- Memory usage > 80%
- P95 latency > 500ms

**Firebase**:

- Delivery rate < 90%
- Invalid token rate > 5%

---

## 🔗 Referencias

### Documentación Oficial

- [Upstash Redis](https://docs.upstash.com/redis)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Sentry Node.js](https://docs.sentry.io/platforms/node/)

### Archivos del Proyecto

- [common.module.ts](file:///Users/abner/Documents/dev/sacdia/sacdia-backend/src/common/common.module.ts) - Redis config
- [notifications.module.ts](file:///Users/abner/Documents/dev/sacdia/sacdia-backend/src/notifications/notifications.module.ts) - FCM module
- [main.ts](file:///Users/abner/Documents/dev/sacdia/sacdia-backend/src/main.ts) - Sentry init
- [schema.prisma](file:///Users/abner/Documents/dev/sacdia/sacdia-backend/prisma/schema.prisma) - user_fcm_tokens model

### Migraciones

- [20260204_add_user_fcm_tokens](file:///Users/abner/Documents/dev/sacdia/sacdia-backend/prisma/migrations/20260204_add_user_fcm_tokens/migration.sql)

---

**Última actualización**: 2026-02-04  
**Autor**: Sistema SACDIA  
**Versión**: 1.0
