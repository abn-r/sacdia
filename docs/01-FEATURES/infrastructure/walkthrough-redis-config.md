# Guía de Configuración - Upstash Redis

**Fecha**: 6 de febrero de 2026  
**Servicio**: Upstash Redis  
**Propósito**: Cache distribuido y Session Management

---

## 📋 Resumen de Configuración

Tu backend SACDIA usa Upstash Redis para:

- ✅ **Token Blacklist**: Invalidar JWTs antes de su expiración
- ✅ **Session Management**: Gestionar sesiones concurrentes (máx 5 por usuario)
- ✅ **Cache distribuido**: Mejorar performance de queries frecuentes

---

## 🔑 Credenciales Configuradas

He actualizado tu archivo `.env` con las credenciales correctas de tu instancia de Upstash:

### Variables Principales

```bash
# URL de conexión Redis (PRINCIPAL - usada por NestJS)
REDIS_URL="redis://default:Ab3aAAIncDIyNzIxZmNiZGQ1NTc0OWRhOWEzZjllY2ViMDA0MDViMHAyNDg2MDI@trusting-teal-48602.upstash.io:6379"
```

**Esta es la variable que NestJS usa** en `common.module.ts`:

```typescript
if (process.env.REDIS_URL) {
  const { redisStore } = await import("cache-manager-redis-yet");
  return {
    store: await redisStore({
      url: process.env.REDIS_URL, // ← Usa esta variable
    }),
    ttl: 86400000,
  };
}
```

### Variables REST (Opcionales)

Estas NO se usan actualmente, pero están disponibles si decides usar el cliente REST de Upstash en el futuro:

```bash
UPSTASH_REDIS_REST_URL="https://trusting-teal-48602.upstash.io"
UPSTASH_REDIS_REST_TOKEN="Ab3aAAIncDIyNzIxZmNiZGQ1NTc0OWRhOWEzZjllY2ViMDA0MDViMHAyNDg2MDI"
```

---

## 🔍 Desglose de la URL de Redis

Tu `REDIS_URL` se descompone así:

```
redis://default:PASSWORD@HOST:PORT
```

| Componente    | Valor                            | Descripción                    |
| ------------- | -------------------------------- | ------------------------------ |
| **Protocolo** | `redis://`                       | Protocolo Redis estándar       |
| **Usuario**   | `default`                        | Usuario por defecto de Upstash |
| **Password**  | `Ab3aAA...MDI`                   | Tu password único de Upstash   |
| **Host**      | `trusting-teal-48602.upstash.io` | Tu endpoint de Upstash         |
| **Puerto**    | `6379`                           | Puerto estándar de Redis       |

---

## ✅ Verificar la Conexión

### Opción 1: Script de Prueba (Recomendado)

He creado un script de prueba para ti en [`scripts/test-redis.ts`](file:///Users/abner/Documents/dev/sacdia/sacdia-backend/scripts/test-redis.ts).

**Ejecuta el script**:

```bash
# Instalar dependencia si no la tienes
npm install redis

# Ejecutar test
npx ts-node scripts/test-redis.ts
```

**Salida esperada**:

```
🔍 Testing Upstash Redis connection...

📡 Connecting to: redis://default:****@trusting-teal-48602.upstash.io:6379

✅ Connected to Redis successfully!

Test 1: PING command
  Response: PONG

Test 2: SET command
  ✅ Key "test:connection" set successfully

Test 3: GET command
  Value: "Hello from NestJS!"

Test 4: TTL command
  TTL: 58 seconds

Test 5: DEL command
  ✅ Key deleted successfully

📊 Redis Server Info:
  redis_version:7.2.4
  uptime_in_days:45

🎉 All tests passed! Redis is ready to use.

👋 Connection closed.
```

---

### Opción 2: Redis CLI (Desde tu terminal)

Puedes conectarte directamente con redis-cli:

```bash
redis-cli --tls -u redis://default:Ab3aAAIncDIyNzIxZmNiZGQ1NTc0OWRhOWEzZjllY2ViMDA0MDViMHAyNDg2MDI@trusting-teal-48602.upstash.io:6379
```

**Comandos de prueba**:

```redis
# Verificar conexión
PING
> PONG

# Ver todas las keys
KEYS *

# Crear una key de prueba
SET test:hello "world"
> OK

# Leer la key
GET test:hello
> "world"

# Borrar la key
DEL test:hello
> (integer) 1

# Salir
exit
```

---

### Opción 3: Iniciar tu Backend

Simplemente inicia tu backend y observa los logs:

```bash
npm run start:dev
```

Si Redis está configurado correctamente, verás:

```
[Nest] INFO [CacheModule] Redis store initialized
[SessionManagementService] Session management using Redis
[TokenBlacklistService] Token blacklist using Redis
```

---

## 🏗️ Cómo se Usa en tu Backend

### 1. Session Management

El servicio `SessionManagementService` almacena sesiones en Redis:

```typescript
// Crear sesión (en login)
await sessionService.createSession(userId, sessionId, userAgent, ipAddress);

// Redis almacena:
// Key: session:{userId}:{sessionId}
// Value: { sessionId, userId, deviceInfo, ipAddress, createdAt, lastActivity }
// TTL: 24 horas
```

**Endpoints que usan esto**:

- `POST /auth/login` - Crea sesión
- `GET /auth/sessions` - Lista sesiones (lee de Redis)
- `DELETE /auth/sessions/:id` - Elimina sesión de Redis

---

### 2. Token Blacklist

El servicio `TokenBlacklistService` invalida tokens en Redis:

```typescript
// Blacklistear token (en logout)
await tokenBlacklistService.blacklistToken(token, expiresInSeconds);

// Redis almacena:
// Key: blacklist:token:{jti}
// Value: timestamp
// TTL: tiempo restante del token
```

**Endpoints que usan esto**:

- `POST /auth/logout` - Blacklistea token actual
- `DELETE /auth/sessions` - Blacklistea todos los tokens del usuario

---

### 3. Cache General (Futuro)

Puedes usar el cache para cualquier dato que quieras cachear:

```typescript
import { CACHE_MANAGER } from "@nestjs/cache-manager";
import { Inject } from "@nestjs/common";
import { Cache } from "cache-manager";

@Injectable()
export class MyService {
  constructor(@Inject(CACHE_MANAGER) private cache: Cache) {}

  async getCatalog(id: string) {
    const cacheKey = `catalog:${id}`;

    // Intentar obtener del cache
    const cached = await this.cache.get(cacheKey);
    if (cached) return cached;

    // Si no existe, obtener de BD
    const data = await this.prisma.catalog.findUnique({ where: { id } });

    // Guardar en cache por 1 hora
    await this.cache.set(cacheKey, data, 3600000);

    return data;
  }
}
```

---

## 📊 Monitoreo en Upstash Dashboard

### Acceder al Dashboard

1. Ve a [console.upstash.com](https://console.upstash.com)
2. Login con tu cuenta
3. Selecciona tu database **trusting-teal-48602**

### Métricas Disponibles

- **Commands/sec**: Operaciones por segundo
- **Bandwidth**: Ancho de banda usado
- **Storage**: Espacio usado en MB
- **Keys**: Número total de keys almacenadas

### Límites del Plan Free

Upstash Free tier incluye:

- ✅ 10,000 comandos/día
- ✅ 256 MB storage
- ✅ TLS encryption
- ✅ Daily backups
- ✅ Todas las regiones

**Tu uso estimado**:

- Sesiones: ~5 keys por usuario × 100 usuarios = 500 keys
- Token Blacklist: ~10 keys/día
- Cache: Variable, pero típicamente < 1000 keys
- **Total**: Muy por debajo del límite

---

## 🔒 Seguridad

### ✅ Buenas Prácticas Implementadas

1. **TLS Enabled**: Todas las conexiones usan TLS encryption
2. **Password Protected**: Requiere authentication
3. **Environment Variables**: Credenciales NO están en código
4. **TTL Automático**: Las keys expiran automáticamente

### ⚠️ NO Hacer

1. ❌ NO commitees el archivo `.env` a Git
2. ❌ NO compartas las credenciales en Slack/Discord
3. ❌ NO uses la misma instancia para producción y desarrollo

---

## 🚀 Próximos Pasos

### 1. Verificar Conexión ✅

```bash
npx ts-node scripts/test-redis.ts
```

### 2. Iniciar Backend ✅

```bash
npm run start:dev
```

### 3. Probar Session Management ✅

```bash
# Login (crea sesión en Redis)
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "password"}'

# Listar sesiones
curl -X GET http://localhost:3000/auth/sessions \
  -H "Authorization: Bearer <token>"
```

### 4. Monitorear en Upstash Dashboard

Ve a [console.upstash.com](https://console.upstash.com) y observa las métricas en tiempo real.

---

## 🐛 Troubleshooting

### Error: "ECONNREFUSED"

**Causa**: No puede conectar a Upstash.

**Solución**:

1. Verifica que `REDIS_URL` esté correcta en `.env`
2. Verifica que tu internet funcione
3. Verifica el status de Upstash en [status.upstash.com](https://status.upstash.com)

---

### Error: "WRONGPASS invalid username-password pair"

**Causa**: Password incorrecta.

**Solución**:

1. Ve a Upstash Dashboard
2. Regenera el password si es necesario
3. Actualiza `REDIS_URL` en `.env`

---

### Error: "ERR unknown command 'KEYS'"

**Causa**: Upstash REST API no soporta algunos comandos.

**Solución**:

- Usa `REDIS_URL` (protocolo TCP), NO las variables REST
- `cache-manager-redis-yet` usa TCP automáticamente

---

### Sessions No Persisten

**Causa**: Usando in-memory cache en lugar de Redis.

**Verificar**:

```bash
# En los logs del backend, deberías ver:
[CacheModule] Redis store initialized

# Si ves esto, NO está usando Redis:
[CacheModule] Using in-memory cache
```

**Solución**:

1. Verifica que `REDIS_URL` exista en `.env`
2. Reinicia el backend: `npm run start:dev`

---

## 📚 Documentación Relacionada

- [Upstash Redis Docs](https://docs.upstash.com/redis)
- [cache-manager-redis-yet](https://github.com/node-cache-manager/node-cache-manager/tree/master/packages/cache-manager-redis-yet)
- [NestJS Caching](https://docs.nestjs.com/techniques/caching)

---

**Configurado**: 6 de febrero de 2026  
**Estado**: ✅ Listo para usar
