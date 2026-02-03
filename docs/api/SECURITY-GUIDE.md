# SACDIA Security Implementation Guide

**Versión**: 1.0  
**Fecha**: 31 de enero de 2026  
**Status**: ✅ Implementado

---

## 📋 Resumen de Características de Seguridad

### Fase 1-3: Seguridad Básica

| Característica   | Archivo                    | Descripción                                     |
| ---------------- | -------------------------- | ----------------------------------------------- |
| Helmet           | `main.ts`                  | Security headers (CSP, HSTS, X-Frame-Options)   |
| Rate Limiting    | `app.module.ts`            | 3 tiers: 3/seg, 20/10seg, 100/min               |
| Compression      | `main.ts`                  | gzip para responses                             |
| CORS             | `main.ts`                  | Whitelist configurable                          |
| XSS Sanitization | `sanitize.pipe.ts`         | Remueve HTML de inputs                          |
| Audit Logging    | `audit.interceptor.ts`     | Log de todas las requests                       |
| Error Handling   | `http-exception.filter.ts` | Oculta detalles en producción                   |
| Password Policy  | `register.dto.ts`          | Requiere mayúscula, minúscula, número, especial |

### Fase 4: Seguridad Avanzada

| Característica  | Archivo                         | Descripción                                |
| --------------- | ------------------------------- | ------------------------------------------ |
| 2FA (TOTP)      | `mfa.service.ts`                | Autenticación de dos factores con Supabase |
| Token Blacklist | `token-blacklist.service.ts`    | Revocación de tokens JWT                   |
| Session Limits  | `session-management.service.ts` | Máximo 5 sesiones por usuario              |
| IP Whitelist    | `ip-whitelist.guard.ts`         | Restricción de acceso admin por IP         |

---

## 🔐 Endpoints de Seguridad

### 2FA (MFA) Endpoints

```typescript
// Iniciar enrolamiento - genera QR code
POST / v1 / auth / mfa / enroll;
// Response: { factorId, qrCode, secret, uri }

// Verificar código y activar 2FA
POST / v1 / auth / mfa / verify;
// Body: { factorId: string, code: string }

// Listar factores configurados
GET / v1 / auth / mfa / factors;
// Response: [{ id, friendlyName, factorType, status, createdAt }]

// Verificar estado de 2FA
GET / v1 / auth / mfa / status;
// Response: { mfaEnabled, currentLevel, nextLevel, factors }

// Deshabilitar 2FA
DELETE / v1 / auth / mfa / unenroll;
// Body: { factorId: string }
```

### Sessions Endpoints

```typescript
// Listar sesiones activas
GET /v1/auth/sessions
// Response: { activeSessions, maxSessions, sessions }

// Cerrar sesión específica
DELETE /v1/auth/sessions/:sessionId

// Cerrar todas las sesiones (logout de todos los dispositivos)
DELETE /v1/auth/sessions
```

---

## 📝 Ejemplos de Uso

### Token Blacklist Service

```typescript
import { TokenBlacklistService } from "./common/services/token-blacklist.service";

// Revocar token individual
await tokenBlacklistService.blacklistToken(token, expiresInSeconds);

// Revocar todos los tokens de un usuario
await tokenBlacklistService.blacklistAllUserTokens(userId);

// Verificar si token está revocado
const isRevoked = await tokenBlacklistService.isBlacklisted(token);

// Verificar si usuario tiene tokens bloqueados
const isUserBlocked = await tokenBlacklistService.isUserBlacklisted(
  userId,
  tokenIssuedAt,
);
```

### Session Management Service

```typescript
import { SessionManagementService } from "./common/services/session-management.service";

// Crear nueva sesión (elimina la más antigua si excede límite)
const result = await sessionService.createSession(
  userId,
  sessionId,
  deviceInfo,
  ipAddress,
);
// Si removedSession está presente, se eliminó una sesión antigua

// Obtener todas las sesiones activas
const sessions = await sessionService.getUserSessions(userId);

// Actualizar última actividad
await sessionService.updateSessionActivity(userId, sessionId);

// Verificar si sesión es válida
const isValid = await sessionService.isValidSession(userId, sessionId);

// Cerrar sesión específica
await sessionService.removeSession(userId, sessionId);

// Cerrar todas las sesiones (logout de todos los dispositivos)
const count = await sessionService.removeAllSessions(userId);

// Obtener estadísticas de sesiones
const stats = await sessionService.getSessionStats(userId);
// { activeSessions: 3, maxSessions: 5, sessions: [...] }
```

### MFA Service

```typescript
import { MfaService } from "./common/services/mfa.service";

// Iniciar enrolamiento de 2FA
const enrollment = await mfaService.enrollMfa(accessToken);
// { factorId, qrCode, secret, uri }

// Verificar código y activar 2FA
const verified = await mfaService.verifyAndActivateMfa(
  accessToken,
  factorId,
  code,
);

// Verificar código durante login
const isValid = await mfaService.verifyMfaCode(accessToken, factorId, code);

// Listar factores configurados
const factors = await mfaService.listFactors(accessToken);

// Verificar si usuario tiene MFA habilitado
const hasMfa = await mfaService.hasMfaEnabled(accessToken);

// Obtener nivel de autenticación actual
const level = await mfaService.getAuthenticatorAssuranceLevel(accessToken);
// { currentLevel: 'aal1' | 'aal2', nextLevel }

// Deshabilitar 2FA
await mfaService.unenrollFactor(accessToken, factorId);
```

### IP Whitelist Guard

```typescript
import { AdminOnly } from "./common/guards/ip-whitelist.guard";

// En controlador
@Controller("admin")
export class AdminController {
  @AdminOnly() // Solo IPs en whitelist
  @Get("sensitive-data")
  async getSensitiveData() {
    // Solo accesible desde IPs permitidas
  }
}
```

---

## 🔧 Configuración de Variables de Entorno

```env
# ===========================================
# SEGURIDAD - Fase 1-3
# ===========================================
NODE_ENV=production
ALLOWED_ORIGINS=https://sacdia.app,https://admin.sacdia.app

# ===========================================
# SEGURIDAD - Fase 4
# ===========================================
# IP Whitelist para endpoints admin (soporta CIDR)
ADMIN_ALLOWED_IPS=192.168.1.100,10.0.0.0/24,203.0.113.50

# Redis (para cache distribuido - opcional)
REDIS_URL=redis://localhost:6379
```

---

## 📦 Dependencias de Seguridad

```json
{
  "dependencies": {
    "@nestjs/throttler": "^6.5.0",
    "@nestjs/cache-manager": "^3.1.0",
    "helmet": "^8.1.0",
    "compression": "^1.8.1",
    "sanitize-html": "^2.17.0",
    "cache-manager": "^7.2.8",
    "redis": "^5.10.0"
  },
  "devDependencies": {
    "@types/sanitize-html": "^2.16.0"
  }
}
```

---

## 📂 Estructura de Archivos de Seguridad

```
src/
├── common/
│   ├── guards/
│   │   └── ip-whitelist.guard.ts       # IP whitelist para admin
│   ├── interceptors/
│   │   └── audit.interceptor.ts        # Logging de requests
│   ├── filters/
│   │   ├── http-exception.filter.ts    # Errores HTTP seguros
│   │   └── all-exceptions.filter.ts    # Catch-all
│   ├── pipes/
│   │   └── sanitize.pipe.ts            # XSS sanitization
│   └── services/
│       ├── token-blacklist.service.ts  # Revocación de tokens
│       ├── session-management.service.ts # Límites de sesiones
│       └── mfa.service.ts              # 2FA con Supabase
├── auth/
│   ├── mfa.controller.ts               # Endpoints de 2FA
│   ├── sessions.controller.ts          # Endpoints de sesiones
│   └── dto/
│       └── mfa.dto.ts                  # DTOs de MFA
└── main.ts                             # Helmet, Compression, CORS
```

---

**Generado**: 31 de enero de 2026
