# SACDIA — Deployment Guide

Tutorial paso a paso para deployar SACDIA en produccion.

**Stack de infraestructura:**
- Backend (NestJS): Render
- Admin Panel (Next.js): Vercel
- Base de Datos: Neon (PostgreSQL serverless)
- App Movil: Flutter (App Store + Play Store)
- Auth: Better Auth (self-hosted en el backend, HS256 JWT)
- Storage: Cloudflare R2
- Cache: Upstash Redis
- Push Notifications: Firebase FCM
- Monitoring: Sentry

---

## Tabla de Contenidos

1. [Requisitos previos](#1-requisitos-previos)
2. [Neon (PostgreSQL)](#2-neon-postgresql)
3. [Render (Backend NestJS)](#3-render-backend-nestjs)
4. [Vercel (Admin Panel Next.js)](#4-vercel-admin-panel-nextjs)
5. [Google OAuth](#5-google-oauth)
6. [Apple Sign In](#6-apple-sign-in)
7. [Flutter (App Store + Play Store)](#7-flutter-app-store--play-store)
8. [Cutover: Apagar Supabase](#8-cutover-apagar-supabase)
9. [Verificacion E2E](#9-verificacion-e2e)
10. [Upgrade a Produccion (planes pagos)](#10-upgrade-a-produccion-planes-pagos)
11. [Troubleshooting](#11-troubleshooting)

---

## 1. Requisitos previos

Antes de empezar, necesitas cuentas en:

| Servicio | URL | Costo (testing) | Costo (produccion) |
|----------|-----|-----------------|---------------------|
| Neon | https://neon.com | $0 (Free) | $19/mo (Launch) |
| Render | https://render.com | $0 (Free) | $7-25/mo (Starter/Standard) |
| Vercel | https://vercel.com | $0 (Hobby) | $20/mo (Pro) |
| Google Cloud Console | https://console.cloud.google.com | $0 | $0 |
| Apple Developer | https://developer.apple.com | $99/year | $99/year |
| Firebase | https://console.firebase.google.com | $0 | $0 (Blaze pay-as-you-go) |
| Upstash | https://upstash.com | $0 (Free) | Pay-as-you-go |
| Cloudflare R2 | https://dash.cloudflare.com | $0 (10GB free) | $0.015/GB |
| Sentry | https://sentry.io | $0 (Developer) | $26/mo (Team) |

**Herramientas locales necesarias:**
```bash
node --version   # v20+ requerido
pnpm --version   # v9+ requerido (NO usar npm para better-auth)
flutter --version # 3.x
git --version
```

---

## 2. Neon (PostgreSQL)

### 2.1 Crear proyectos

1. Ir a [neon.com/console](https://neon.com/console)
2. Crear 3 proyectos:

| Proyecto | Auto-suspend | Region |
|----------|-------------|--------|
| `sacdia-dev` | ON (5 min) | US East 1 |
| `sacdia-staging` | ON (5 min) | US East 1 |
| `sacdia-prod` | **OFF** (siempre encendido) | US East 1 |

3. Para cada proyecto, anotar las dos connection strings:
   - **Pooled** (tiene `-pooler` en el hostname): para runtime
   - **Direct** (sin `-pooler`): para migraciones

### 2.2 Aplicar migraciones

Desde `sacdia-backend/`, correr para cada ambiente:

```bash
# Dev
DATABASE_URL="postgresql://...pooler..." \
DATABASE_DIRECT_URL="postgresql://...direct..." \
npx prisma migrate deploy

# Staging (misma logica, distinto connection string)
# Prod (misma logica, distinto connection string)
```

### 2.3 Seedear roles base

Cada base de datos nueva necesita los roles base para que el register funcione:

```bash
DATABASE_URL="<pooled_url>" \
DATABASE_DIRECT_URL="<direct_url>" \
npx prisma db execute --stdin <<'SQL'
INSERT INTO roles (role_id, role_name, role_category, active, created_at, modified_at)
VALUES
  (gen_random_uuid(), 'user', 'GLOBAL', true, NOW(), NOW()),
  (gen_random_uuid(), 'admin', 'GLOBAL', true, NOW(), NOW()),
  (gen_random_uuid(), 'super_admin', 'GLOBAL', true, NOW(), NOW())
ON CONFLICT (role_name) DO NOTHING;
SQL
```

Repetir para dev, staging y prod.

### 2.4 Nota sobre connection strings

```
Pooled (runtime):  postgresql://user:pass@ep-xxx-pooler.region.aws.neon.tech/neondb?sslmode=require
Direct (migrate):  postgresql://user:pass@ep-xxx.region.aws.neon.tech/neondb?sslmode=require
                                              ^ sin -pooler
```

El `prisma.config.ts` ya esta configurado para usar ambas:
```typescript
datasource: {
  url: process.env["DATABASE_URL"],        // pooled
  directUrl: process.env["DATABASE_DIRECT_URL"],  // direct
}
```

---

## 3. Render (Backend NestJS)

### 3.1 Crear servicio

1. Ir a [render.com](https://render.com) -> login con GitHub
2. **"New" -> "Web Service"**
3. Conectar repo: `abn-r/sacdia-backend`

### 3.2 Configurar

| Campo | Valor |
|-------|-------|
| Name | `sacdia-backend` |
| Region | Oregon (US West) o el mas cercano |
| Branch | `development` (o `main` cuando mergees) |
| Runtime | Node |
| Build Command | `pnpm install && pnpm run build` |
| Start Command | `pnpm run start:prod` |
| Instance Type | Free (testing) o Starter $7/mo (produccion) |

**IMPORTANTE**: El `package.json` tiene un script `prebuild` que corre `prisma generate` automaticamente antes del build. Si por alguna razon no funciona, cambia el Build Command a:
```
pnpm install && pnpm prisma generate && pnpm run build
```

### 3.3 Variables de entorno

Agregar TODAS estas en Render Dashboard -> tu servicio -> Environment:

```env
# Core
NODE_ENV=production
PORT=3000

# Database (Neon) - usar las del ambiente correspondiente
DATABASE_URL=postgresql://...pooler...
DATABASE_DIRECT_URL=postgresql://...direct...

# Better Auth
BETTER_AUTH_SECRET=<genera un string random de 32+ caracteres>
BETTER_AUTH_BASE_URL=https://sacdia-backend.onrender.com

# Frontend URL (admin panel en Vercel)
FRONTEND_URL=https://sacdia-admin.vercel.app

# Google OAuth
GOOGLE_CLIENT_ID=<tu client ID del paso 5>
GOOGLE_CLIENT_SECRET=<tu client secret del paso 5>

# Apple OAuth (cuando tengas Apple Developer Account)
# APPLE_CLIENT_ID=
# APPLE_TEAM_ID=
# APPLE_KEY_ID=
# APPLE_PRIVATE_KEY=

# Upstash Redis
REDIS_URL=rediss://default:...@....upstash.io:6379

# Firebase FCM
FIREBASE_SERVICE_ACCOUNT_JSON_BASE64=<tu base64 de service account>

# Cloudflare R2
R2_ACCOUNT_ID=<tu account id>
R2_ACCESS_KEY_ID=<tu access key>
R2_SECRET_ACCESS_KEY=<tu secret key>
R2_REGION=auto

# Sentry
SENTRY_DSN=https://...@....ingest.sentry.io/...
```

**Para generar BETTER_AUTH_SECRET:**
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

### 3.4 Deploy

Click "Deploy Web Service". Render clona, instala, builda y deploya automaticamente.

La URL sera algo como: `https://sacdia-backend.onrender.com`

### 3.5 Verificar

```bash
curl https://sacdia-backend.onrender.com/api/v1/health
```

Debe devolver:
```json
{
  "status": "ok",
  "dependencies": {
    "database": { "ok": true },
    "cache": { "ok": true }
  }
}
```

---

## 4. Vercel (Admin Panel Next.js)

### 4.1 Crear proyecto

1. Ir a [vercel.com](https://vercel.com) -> login con GitHub
2. **"Add New" -> "Project"**
3. Importar repo: `abn-r/sacdia-admin`

### 4.2 Configurar

| Campo | Valor |
|-------|-------|
| Framework Preset | Next.js (auto-detectado) |
| Root Directory | `.` |
| Build Command | auto |
| Output Directory | auto |

**IMPORTANTE**: En Settings -> Git -> Production Branch, cambiar a `development` (o `main` cuando mergees). Si no, Vercel deploya la branch `main` que no tiene los cambios de Wave 3.

### 4.3 Variables de entorno

```env
NEXT_PUBLIC_API_URL=https://sacdia-backend.onrender.com/api/v1
```

Solo esa variable es requerida. Opcional:
```env
NEXT_PUBLIC_RBAC_LEGACY_FALLBACK=true
```

### 4.4 Deploy

Click "Deploy". Vercel builda y deploya automaticamente.

La URL sera algo como: `https://sacdia-admin.vercel.app`

### 4.5 Verificar

Abrir la URL en el browser. Deberias ver la pagina de login del admin panel.

---

## 5. Google OAuth

### 5.1 Crear credenciales (si no las tenes)

1. Ir a [Google Cloud Console](https://console.cloud.google.com)
2. Seleccionar tu proyecto (o crear uno nuevo)
3. **APIs & Services -> Credentials -> "+ Create Credentials" -> "OAuth client ID"**
4. Application type: **"Web application"**
5. Name: `Sacdia Backend`

### 5.2 Configurar redirect URIs

En **"Authorized redirect URIs"** agregar:

```
http://localhost:3000/api/auth/callback/google
https://sacdia-backend.onrender.com/api/auth/callback/google
https://tu-dominio-produccion.com/api/auth/callback/google
```

### 5.3 Guardar credenciales

Te da:
- **Client ID**: `xxxx.apps.googleusercontent.com`
- **Client Secret**: `GOCSPX-xxxx`

Agregar ambos como env vars en Render (ya documentado en paso 3.3).

### 5.4 Configurar pantalla de consentimiento

Si no lo hiciste:
1. **APIs & Services -> OAuth consent screen**
2. User type: External
3. Completar nombre de la app, email de contacto, logo
4. Scopes: `email`, `profile`, `openid`
5. Test users: agregar tu email para testing

---

## 6. Apple Sign In

**Requiere Apple Developer Account ($99/year)**

### 6.1 Crear App ID

1. Ir a [developer.apple.com](https://developer.apple.com) -> Certificates, Identifiers & Profiles
2. **Identifiers -> "+" -> App IDs**
3. Bundle ID: `io.sacdia.app`
4. Habilitar "Sign in with Apple"

### 6.2 Crear Service ID

1. **Identifiers -> "+" -> Services IDs**
2. Identifier: `io.sacdia.app.auth`
3. Habilitar "Sign in with Apple"
4. Configurar:
   - **Domains**: `sacdia-backend.onrender.com` (o tu dominio)
   - **Return URLs**: `https://sacdia-backend.onrender.com/api/auth/callback/apple`

### 6.3 Crear Key

1. **Keys -> "+" -> "Sign in with Apple"**
2. Descargar el archivo `.p8` (private key)
3. Anotar el Key ID

### 6.4 Agregar env vars

En Render, agregar:
```env
APPLE_CLIENT_ID=io.sacdia.app.auth
APPLE_TEAM_ID=<tu Team ID>
APPLE_KEY_ID=<el Key ID del paso 6.3>
APPLE_PRIVATE_KEY=<contenido del .p8, en una sola linea>
```

---

## 7. Flutter (App Store + Play Store)

### 7.1 Configurar URL del backend

En `lib/core/constants/app_constants.dart` (o donde este configurado), cambiar la base URL:

```dart
static const String baseUrl = 'https://sacdia-backend.onrender.com/api/v1';
```

O usar flavor/environment config para dev/staging/prod.

### 7.2 Build Android

```bash
cd sacdia-app

# Limpiar
flutter clean && flutter pub get

# Build APK (testing)
flutter build apk --release

# Build App Bundle (Play Store)
flutter build appbundle --release
```

El `.aab` esta en `build/app/outputs/bundle/release/app-release.aab`

### 7.3 Subir a Play Store

1. Ir a [Google Play Console](https://play.google.com/console)
2. Seleccionar tu app (o crear una nueva)
3. **Testing -> Internal testing -> "Create new release"**
4. Subir el `.aab`
5. Agregar notas: "Updated authentication system"
6. Publicar en internal track

### 7.4 Build iOS

```bash
# Build
flutter build ipa --release
```

El `.ipa` esta en `build/ios/ipa/`

### 7.5 Subir a App Store

1. Abrir Xcode -> **Product -> Archive** (o usar el `.ipa` generado)
2. **Distribute App -> App Store Connect**
3. En [App Store Connect](https://appstoreconnect.apple.com):
   - **TestFlight -> "+" -> Add build**
   - Subir el build
   - Agregar testers al grupo de TestFlight

### 7.6 Nota sobre deep links

Los deep links para OAuth ya estan configurados:
- iOS: `Info.plist` tiene `CFBundleURLSchemes` con `io.sacdia.app`
- Android: `AndroidManifest.xml` tiene el intent-filter
- Router: `/auth/callback` GoRoute maneja el callback

---

## 8. Cutover: Apagar Supabase

**Solo hacer esto cuando TODO lo anterior este funcionando y verificado.**

### 8.1 Verificar que todo funciona

- [ ] Backend en Render responde `/api/v1/health` con DB y Cache OK
- [ ] Register funciona (crear usuario de prueba)
- [ ] Login funciona (recibir JWT)
- [ ] Auth/me funciona (validar JWT)
- [ ] Refresh funciona (nuevo JWT desde session token)
- [ ] Logout funciona (401 despues de logout)
- [ ] Admin panel carga y permite login
- [ ] Flutter app conecta al backend correctamente

### 8.2 Pausar Supabase (NO borrar)

1. Ir a [supabase.com](https://supabase.com/dashboard)
2. Para cada proyecto (dev, staging, prod):
   - Settings -> General -> **"Pause Project"**
3. **NO borrar** los proyectos todavia

### 8.3 Remover env vars de Supabase

En Render, verificar que estas variables NO existan:
```
SUPABASE_URL          <- borrar si existe
SUPABASE_ANON_KEY     <- borrar si existe
SUPABASE_SERVICE_ROLE_KEY <- borrar si existe
SUPABASE_JWT_SECRET   <- borrar si existe
```

### 8.4 Monitorear 24h

Despues del cutover, monitorear:
- Error rate en `/auth/login` (debe ser < 5%)
- Error rate en `/auth/me` (debe ser < 2%)
- Logs en Render Dashboard -> tu servicio -> Logs
- Sentry para errores no capturados

### 8.5 Borrar Supabase (30 dias despues)

**Esperar 30 dias** despues de pausar. Si no hubo problemas:
1. Ir a cada proyecto en Supabase
2. Settings -> General -> **"Delete Project"**
3. Confirmar borrado

---

## 9. Verificacion E2E

Script para verificar todo el flujo de auth contra el backend deployado:

```bash
# Cambiar por tu URL
API_URL="https://sacdia-backend.onrender.com/api/v1"

# 1. Health
echo "=== HEALTH ==="
curl -s "$API_URL/health" | python3 -c "import sys,json; d=json.load(sys.stdin); print('DB:', d['dependencies']['database']['ok'], '| Cache:', d['dependencies']['cache']['ok'])"

# 2. Register
echo "=== REGISTER ==="
curl -s -X POST "$API_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@sacdia.com","password":"TestPass123!","name":"Test","paternal_last_name":"User","maternal_last_name":"E2E"}'
echo ""

# 3. Login
echo "=== LOGIN ==="
LOGIN=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@sacdia.com","password":"TestPass123!"}')
AT=$(echo "$LOGIN" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['accessToken'])")
RT=$(echo "$LOGIN" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['refreshToken'])")
echo "JWT received: $([ ${#AT} -gt 20 ] && echo YES || echo NO)"

# 4. Auth/me
echo "=== AUTH/ME ==="
curl -s "$API_URL/auth/me" -H "Authorization: Bearer $AT" | \
  python3 -c "import sys,json; d=json.load(sys.stdin); print('Email:', d['data']['email'], '| Roles:', d['data']['roles'])"

# 5. Refresh
echo "=== REFRESH ==="
curl -s -X POST "$API_URL/auth/refresh" \
  -H "Content-Type: application/json" \
  -d "{\"refreshToken\":\"$RT\"}" | \
  python3 -c "import sys,json; d=json.load(sys.stdin); print('Status:', d['status'])"

# 6. Logout
echo "=== LOGOUT ==="
curl -s -X POST "$API_URL/auth/logout" \
  -H "Authorization: Bearer $AT" \
  -H "Content-Type: application/json" \
  -d "{\"refreshToken\":\"$RT\"}" | \
  python3 -c "import sys,json; d=json.load(sys.stdin); print('Status:', d.get('status','done'))"

# 7. Verify blocked
echo "=== VERIFY BLOCKED ==="
HTTP=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/auth/me" -H "Authorization: Bearer $AT")
echo "Post-logout: HTTP $HTTP (expect 401)"
```

---

## 10. Upgrade a Produccion (planes pagos)

Cuando estes listo para produccion real:

### Backend: Render Free -> Starter/Standard

| Plan | Costo | RAM | CPU | Auto-suspend |
|------|-------|-----|-----|-------------|
| Free | $0 | 512MB | Shared | SI (15 min) |
| **Starter** | **$7/mo** | 512MB | 0.5 | NO |
| **Standard** | **$25/mo** | 2GB | 1 | NO |

Recomendado: **Starter ($7/mo)** para arrancar. Si ves problemas de memoria, subir a Standard.

Para cambiar: Render Dashboard -> tu servicio -> Settings -> Instance Type.

### Alternativa: Migrar a Railway

Si preferis mejor DX y pricing por uso:

1. Crear cuenta en [railway.com](https://railway.com)
2. **"New Project" -> "Deploy from GitHub"** -> `abn-r/sacdia-backend`
3. Agregar las mismas env vars
4. Railway auto-detecta NestJS y deploya

Costo estimado: ~$7-15/mo (usage-based).

### DB: Neon Free -> Launch

Para produccion, el proyecto `sacdia-prod` en Neon debe ser **Launch ($19/mo)**:
- Auto-suspend deshabilitado
- Mayor pool de conexiones
- Backups automaticos

Cambiar en Neon Console -> tu proyecto -> Settings -> Plan.

### Costo total estimado (produccion)

| Servicio | Costo |
|----------|-------|
| Render Starter (backend) | $7/mo |
| Vercel Free (admin) | $0 |
| Neon Launch (prod DB) | $19/mo |
| Neon Free (dev + staging) | $0 |
| **Total** | **~$26/mo** |

---

## 11. Troubleshooting

### Build falla con "Property X does not exist on type PrismaService"

**Causa**: `prisma generate` no se corrio antes del build.
**Fix**: Verificar que `package.json` tiene:
```json
"prebuild": "prisma generate"
```

### Register devuelve 500 "User role not found"

**Causa**: La tabla `roles` esta vacia en esa base de datos.
**Fix**: Correr el seed SQL del paso 2.3.

### Cold start de 30s-2min en Render Free

**Causa**: Render Free apaga el servicio despues de 15 min sin trafico.
**Fix**: Upgrade a Render Starter ($7/mo) que es always-on. O aceptarlo para testing.

### "Cannot find module dist/main"

**Causa**: El build no genero la carpeta `dist/`.
**Fix**: Verificar que el Build Command es `pnpm install && pnpm run build`.

### Login funciona pero el admin no puede hacer requests

**Causa**: Falta el interceptor de Authorization header en client-side.
**Fix**: Verificar que existe `src/app/api/auth/token/route.ts` y el interceptor en `src/lib/api/client.ts`.

### OAuth redirect falla con "redirect_uri_mismatch"

**Causa**: La URL del backend no esta en las Authorized redirect URIs de Google Console.
**Fix**: Agregar `https://tu-backend.onrender.com/api/auth/callback/google` en Google Cloud Console -> Credentials -> tu OAuth client.

### Vercel deploya sin los cambios de Wave 3

**Causa**: Vercel esta deployando desde la branch `main` que no tiene los cambios.
**Fix**: Settings -> Git -> Production Branch -> cambiar a `development`.

### Flutter: "No se recibio ID de usuario" al registrar

**Causa**: El parsing de la respuesta de register no matchea el formato del backend.
**Fix**: El backend devuelve `{ success: true, userId: "uuid" }`. Verificar que el datasource parsea `response.data['userId']`.

---

## Arquitectura final

```
                    Usuarios
                       |
          +------------+------------+
          |                         |
     Flutter App              Admin Panel
     (App Store /             (Vercel)
      Play Store)                |
          |                      |
          +----------+-----------+
                     |
              sacdia-backend
              (Render / Railway)
                     |
          +----------+----------+
          |          |          |
       Neon DB   Upstash    Cloudflare
      (PostgreSQL) (Redis)    R2 (Storage)
          |
    +-----+-----+
    |     |     |
   dev  staging prod
```

## Variables de entorno - Referencia completa

```env
# === CORE ===
NODE_ENV=production
PORT=3000

# === DATABASE (Neon) ===
DATABASE_URL=postgresql://...pooler.../neondb?sslmode=require
DATABASE_DIRECT_URL=postgresql://.../neondb?sslmode=require

# === AUTH (Better Auth) ===
BETTER_AUTH_SECRET=<32+ chars random hex>
BETTER_AUTH_BASE_URL=https://tu-backend.com

# === FRONTEND ===
FRONTEND_URL=https://tu-admin.vercel.app

# === GOOGLE OAUTH ===
GOOGLE_CLIENT_ID=xxx.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX-xxx

# === APPLE OAUTH (requiere Apple Developer Account) ===
APPLE_CLIENT_ID=io.sacdia.app.auth
APPLE_TEAM_ID=<Team ID>
APPLE_KEY_ID=<Key ID>
APPLE_PRIVATE_KEY=<contenido .p8>

# === REDIS (Upstash) ===
REDIS_URL=rediss://default:xxx@xxx.upstash.io:6379

# === FIREBASE ===
FIREBASE_SERVICE_ACCOUNT_JSON_BASE64=<base64 del service account JSON>

# === CLOUDFLARE R2 ===
R2_ACCOUNT_ID=xxx
R2_ACCESS_KEY_ID=xxx
R2_SECRET_ACCESS_KEY=xxx
R2_REGION=auto

# === MONITORING ===
SENTRY_DSN=https://xxx@xxx.ingest.sentry.io/xxx
```
