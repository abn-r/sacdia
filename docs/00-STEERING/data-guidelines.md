# Data Guidelines

> Guías para manejo de datos, APIs externas, y fuentes de datos

---

## Principios Generales

1. **Validar en Capas**: Cliente (UX) → API (Seguridad) → DB (Integridad)
2. **Nunca Confiar en el Cliente**: Toda validación debe existir en backend
3. **Fail Fast**: Validar temprano y fallar rápido
4. **Log Everything Important**: Pero no datos sensibles
5. **Encrypt Sensitive Data**: En tránsito y en reposo

---

## Validación de Datos

### Input Validation

**Validar TODO input del usuario**:

```typescript
import { z } from 'zod';

// ✅ Bien - Schema de validación
const CreateUserSchema = z.object({
  email: z.string().email().max(255),
  name: z.string().min(1).max(100),
  age: z.number().int().min(18).max(120),
  role: z.enum(['admin', 'user', 'guest']).default('user'),
});

// En controller
async function createUser(req, res) {
  try {
    // Valida y parsea
    const validData = CreateUserSchema.parse(req.body);
    
    const user = await userService.create(validData);
    return res.status(201).json({ success: true, data: user });
    
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          details: error.errors
        }
      });
    }
    throw error;
  }
}
```

### Sanitización

**Sanitizar inputs para prevenir inyecciones**:

```typescript
import validator from 'validator';
import xss from 'xss';

function sanitizeHtmlInput(input: string): string {
  // Remove XSS
  const cleaned = xss(input, {
    whiteList: {}, // No HTML tags allowed
    stripIgnoreTag: true,
  });
  
  return validator.trim(cleaned);
}

function sanitizeSearchQuery(query: string): string {
  // Escape special characters para búsqueda segura
  return query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}
```

---

## Bases de Datos

### Queries Seguras

**SIEMPRE usa prepared statements o ORM**:

```typescript
// ✅ Bien - ORM (Prisma)
const users = await prisma.user.findMany({
  where: {
    email: {
      contains: searchQuery
    }
  }
});

// ✅ Bien - Prepared statement
const users = await db.query(
  'SELECT * FROM users WHERE email LIKE $1',
  [`%${searchQuery}%`]
);

// ❌ NUNCA - SQL Injection vulnerable
const users = await db.query(
  `SELECT * FROM users WHERE email LIKE '%${searchQuery}%'`
);
```

### Transacciones

**Usa transacciones para operaciones relacionadas**:

```typescript
async function transferMoney(fromId: string, toId: string, amount: number) {
  return await prisma.$transaction(async (tx) => {
    // Retirar de cuenta origen
    await tx.account.update({
      where: { id: fromId },
      data: { balance: { decrement: amount } }
    });
    
    // Depositar en cuenta destino
    await tx.account.update({
      where: { id: toId },
      data: { balance: { increment: amount } }
    });
    
    // Crear transacción
    await tx.transaction.create({
      data: { fromId, toId, amount, type: 'transfer' }
    });
  });
  
  // Si algo falla, TODO se revierte
}
```

### Índices

**Agrega índices para queries frecuentes**:

```sql
-- Búsquedas por email (frecuente)
CREATE INDEX idx_users_email ON users(email);

-- Búsquedas por fecha de creación
CREATE INDEX idx_users_created_at ON users(created_at);

-- Índice compuesto para queries complejas
CREATE INDEX idx_orders_user_status ON orders(user_id, status);

-- Índice parcial para casos específicos
CREATE INDEX idx_active_users ON users(email) WHERE deleted_at IS NULL;
```

### Paginación

**SIEMPRE pagina resultados grandes**:

```typescript
interface PaginationParams {
  page: number;
  limit: number;
}

async function getUsers({ page = 1, limit = 20 }: PaginationParams) {
  const skip = (page - 1) * limit;
  
  const [users, total] = await Promise.all([
    prisma.user.findMany({
      skip,
      take: limit,
      orderBy: { createdAt: 'desc' }
    }),
    prisma.user.count()
  ]);
  
  return {
    data: users,
    meta: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
      hasNext: page * limit < total,
      hasPrev: page > 1
    }
  };
}
```

---

## APIs Externas

### Manejo de Errores

**Implementa estrategia de retry**:

```typescript
import axios from 'axios';
import axiosRetry from 'axios-retry';

const apiClient = axios.create({
  baseURL: process.env.EXTERNAL_API_URL,
  timeout: 5000,
});

// Configurar retry
axiosRetry(apiClient, {
  retries: 3,
  retryDelay: axiosRetry.exponentialDelay, // 1s, 2s, 4s
  retryCondition: (error) => {
    // Retry en errores de red o 5xx
    return axiosRetry.isNetworkOrIdempotentRequestError(error) ||
           (error.response?.status || 0) >= 500;
  },
});

// Uso
async function fetchExternalData(id: string) {
  try {
    const response = await apiClient.get(`/data/${id}`);
    return response.data;
  } catch (error) {
    if (axios.isAxiosError(error)) {
      if (error.response?.status === 404) {
        throw new NotFoundError('External resource', id);
      }
      if (error.response?.status === 429) {
        throw new RateLimitError('External API rate limit exceeded');
      }
    }
    
    logger.error('Error fetching external data', { id, error });
    throw new Error('Failed to fetch external data');
  }
}
```

### Caching de APIs Externas

**Cachea para reducir llamadas**:

```typescript
import { createClient } from 'redis';

const redis = createClient({ url: process.env.REDIS_URL });

async function getExternalUser(userId: string) {
  const cacheKey = `external:user:${userId}`;
  
  // 1. Intentar obtener del cache
  const cached = await redis.get(cacheKey);
  if (cached) {
    logger.info(`Cache hit for user ${userId}`);
    return JSON.parse(cached);
  }
  
  // 2. Si no está en cache, fetch de API
  logger.info(`Cache miss for user ${userId}, fetching from API`);
  const user = await fetchFromExternalAPI(userId);
  
  // 3. Guardar en cache (5 minutos)
  await redis.setEx(cacheKey, 300, JSON.stringify(user));
  
  return user;
}
```

### Rate Limiting

**Respeta rate limits de APIs**:

```typescript
import Bottleneck from 'bottleneck';

// Configurar limiter: máximo 100 requests por minuto
const limiter = new Bottleneck({
  minTime: 600, // Mínimo 600ms entre requests
  maxConcurrent: 5, // Máximo 5 requests concurrentes
});

// Wrap API calls
const rateLimitedFetch = limiter.wrap(async (url: string) => {
  return await fetch(url);
});

// Uso
const data = await rateLimitedFetch('https://api.example.com/data');
```

---

## Datos Sensibles

### Encryption

**Encripta en tránsito**:
- HTTPS/TLS obligatorio
- TLS 1.3 preferido
- Certificados válidos

**Encripta en reposo**:

```typescript
import crypto from 'crypto';

const ALGORITHM = 'aes-256-gcm';
const KEY = Buffer.from(process.env.ENCRYPTION_KEY!, 'hex'); // 32 bytes

function encrypt(text: string): string {
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv(ALGORITHM, KEY, iv);
  
  let encrypted = cipher.update(text, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  
  const authTag = cipher.getAuthTag();
  
  // Return iv:authTag:encrypted
  return `${iv.toString('hex')}:${authTag.toString('hex')}:${encrypted}`;
}

function decrypt(encryptedData: string): string {
  const [ivHex, authTagHex, encrypted] = encryptedData.split(':');
  
  const iv = Buffer.from(ivHex, 'hex');
  const authTag = Buffer.from(authTagHex, 'hex');
  const decipher = crypto.createDecipheriv(ALGORITHM, KEY, iv);
  
  decipher.setAuthTag(authTag);
  
  let decrypted = decipher.update(encrypted, 'hex', 'utf8');
  decrypted += decipher.final('utf8');
  
  return decrypted;
}
```

### Password Hashing

**NUNCA guardes passwords en texto plano**:

```typescript
import bcrypt from 'bcrypt';

const SALT_ROUNDS = 10;

async function hashPassword(password: string): Promise<string> {
  return await bcrypt.hash(password, SALT_ROUNDS);
}

async function verifyPassword(password: string, hash: string): Promise<boolean> {
  return await bcrypt.compare(password, hash);
}
```

### Secrets Management

**NUNCA en código**:

```typescript
// ❌ NUNCA
const API_KEY = 'sk_live_abc123...';
const DB_PASSWORD = 'mypassword123';

// ✅ SIEMPRE desde environment
const API_KEY = process.env.API_KEY!;
const DB_PASSWORD = process.env.DB_PASSWORD!;

// Validar que existen
if (!API_KEY || !DB_PASSWORD) {
  throw new Error('Missing required environment variables');
}
```

---

## Logging

### Qué Loggear

**✅ Loggea**:
- Requests a API (sin datos sensibles)
- Errores y excepciones
- Eventos de negocio importantes
- Cambios de estado críticos
- Intentos de autenticación
- Rate limit hits

**❌ NO Loggees**:
- Passwords
- Tokens completos (solo últimos 4 caracteres)
- PII sin necesidad (emails, nombres, etc.)
- Números de tarjeta de crédito
- Secrets/API Keys

### Structured Logging

```typescript
import winston from 'winston';

const logger = winston.createLogger({
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
});

// ✅ Bien - Structured
logger.info('User created', {
  userId: user.id,
  email: user.email, // OK si no es PII crítica
  timestamp: new Date().toISOString(),
  action: 'user.created'
});

// ❌ Mal - String sin estructura
logger.info(`User ${user.email} was created with password ${password}`);
// NUNCA loggees passwords!
```

### Log Levels

- **ERROR**: Errores que requieren atención
- **WARN**: Situaciones inusuales pero manejables
- **INFO**: Eventos normales importantes
- **DEBUG**: Información detallada para debugging
- **TRACE**: Información muy granular

```typescript
logger.error('Failed to process payment', { orderId, error: error.message });
logger.warn('Rate limit approaching threshold', { ip, requestCount });
logger.info('User logged in', { userId });
logger.debug('Cache miss', { key: cacheKey });
```

---

## Data Privacy & Compliance

### GDPR

**Right to be Forgotten**:

```typescript
async function deleteUserData(userId: string) {
  await prisma.$transaction([
    // Soft delete user
    prisma.user.update({
      where: { id: userId },
      data: {
        email: `deleted_${userId}@deleted.com`,
        name: '[DELETED]',
        deletedAt: new Date()
      }
    }),
    
    // Delete o anonymize related data
    prisma.order.updateMany({
      where: { userId },
      data: { userId: null } // Anonymize
    }),
    
    // Delete PII
    prisma.address.deleteMany({
      where: { userId }
    })
  ]);
  
  logger.info('User data deleted', { userId });
}
```

**Data Portability**:

```typescript
async function exportUserData(userId: string) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    include: {
      orders: true,
      addresses: true,
      preferences: true
    }
  });
  
  return {
    exportedAt: new Date().toISOString(),
    data: user
  };
}
```

### Consentimiento

**Trackear consentimiento**:

```typescript
interface UserConsent {
  userId: string;
  marketingEmails: boolean;
  analytics: boolean;
  thirdPartySharing: boolean;
  consentedAt: Date;
  ipAddress: string;
}
```

---

## Backups

### Database Backups

```bash
# Script de backup automatizado
#!/bin/bash

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="backup_${DATE}.sql"

# Backup
pg_dump $DATABASE_URL > $BACKUP_FILE

# Comprimir
gzip $BACKUP_FILE

# Upload a S3
aws s3 cp ${BACKUP_FILE}.gz s3://my-backups/database/

# Limpiar backups antiguos (mantener últimos 30 días)
find /backups -name "backup_*.sql.gz" -mtime +30 -delete
```

### Restore Testing

**Testear restores regularmente**:

```bash
# Mensualmente, verificar que backups funcionan
pg_restore -d test_db latest_backup.dump

# Ejecutar queries de validación
psql test_db -c "SELECT COUNT(*) FROM users;"
```

---

## Monitoreo de Datos

### Data Quality Metrics

```typescript
// Job que corre diariamente
async function checkDataQuality() {
  const checks = [
    {
      name: 'Orphaned records',
      query: 'SELECT COUNT(*) FROM orders WHERE user_id NOT IN (SELECT id FROM users)',
      threshold: 0
    },
    {
      name: 'Invalid emails',
      query: "SELECT COUNT(*) FROM users WHERE email NOT LIKE '%@%.%'",
      threshold: 0
    },
    {
      name: 'Future dates',
      query: 'SELECT COUNT(*) FROM orders WHERE created_at > NOW()',
      threshold: 0
    }
  ];
  
  for (const check of checks) {
    const result = await db.query(check.query);
    const count = result.rows[0].count;
    
    if (count > check.threshold) {
      logger.error('Data quality check failed', { 
        check: check.name,
        count,
        threshold: check.threshold
      });
      
      // Alerta al equipo
      await sendAlert(`Data quality check failed: ${check.name}`);
    }
  }
}
```

---

## Notas para IA

**Cuando trabajes con datos**:

1. **Validación es obligatoria**
   - Nunca assumes que datos son válidos
   - Valida en múltiples capas

2. **Seguridad primero**
   - Nunca hardcodees secrets
   - Siempre usa prepared statements
   - Encripta datos sensibles

3. **Performance**
   - Implementa paginación para listas grandes
   - Cachea datos que cambian poco
   - Usa índices para queries frecuentes

4. **Logging inteligente**
   - Loggea eventos importantes
   - NO loggees datos sensibles
   - Usa structured logging

5. **APIs externas**
   - Implementa retries
   - Cachea cuando posible
   - Respeta rate limits
   - Maneja errores gracefully

---

**Última actualización**: [YYYY-MM-DD]
