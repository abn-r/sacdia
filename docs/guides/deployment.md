# Guía de Deployment - SACDIA

**Estado**: ACTIVE

**Versión**: 2.2.0
**Fecha**: 4 de febrero de 2026
**Stack**: NestJS Backend + Next.js Admin + Flutter App

---

## 📋 Tabla de Contenidos

1. [Arquitectura de Deployment](#arquitectura-de-deployment)
2. [Backend (NestJS)](#backend-nestjs)
3. [Admin Panel (Next.js)](#admin-panel-nextjs)
4. [Mobile App (Flutter)](#mobile-app-flutter)
5. [Base de Datos](#base-de-datos)
6. [CI/CD](#cicd)
7. [Monitoring](#monitoring)
8. [Troubleshooting](#troubleshooting)

---

## Arquitectura de Deployment

### Stack de Infraestructura

```
┌─────────────────────────────────────────────────────────┐
│                    PRODUCCIÓN                            │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │   Vercel     │  │   Vercel     │  │ App Store /  │ │
│  │   (API)      │  │   (Admin)    │  │ Google Play  │ │
│  │ NestJS       │  │ Next.js 16   │  │ Flutter      │ │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘ │
│         │                  │                  │          │
│         └──────────────────┴──────────────────┘          │
│                            │                             │
│                  ┌─────────▼─────────┐                  │
│                  │  Supabase Cloud   │                  │
│                  │  - PostgreSQL 15  │                  │
│                  │  - Auth           │                  │
│                  │  - Storage        │                  │
│                  └───────────────────┘                  │
│                                                          │
│         ┌────────────────┬────────────────┐            │
│         │                │                 │            │
│  ┌──────▼──────┐  ┌─────▼──────┐  ┌──────▼──────┐    │
│  │   Upstash   │  │  Firebase  │  │   Sentry    │    │
│  │   Redis     │  │    FCM     │  │  Monitoring │    │
│  └─────────────┘  └────────────┘  └─────────────┘    │
└─────────────────────────────────────────────────────────┘
```

### Ambientes

| Ambiente | Propósito | URL Base |
|----------|-----------|----------|
| **Development** | Desarrollo local | `http://localhost:3000` |
| **Staging** | Testing pre-producción | `https://api-staging.sacdia.app` |
| **Production** | Producción | `https://api.sacdia.app` |

---

## Backend (NestJS)

### Deployment en Vercel

#### 1. Preparación del Proyecto

**Archivo**: `vercel.json`

```json
{
  "version": 2,
  "builds": [
    {
      "src": "src/main.ts",
      "use": "@vercel/node"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "src/main.ts",
      "methods": ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
    }
  ],
  "env": {
    "NODE_ENV": "production"
  }
}
```

**Archivo**: `package.json` (scripts)

```json
{
  "scripts": {
    "build": "nest build",
    "start": "nest start",
    "start:prod": "node dist/main",
    "vercel-build": "npm run build"
  }
}
```

---

#### 2. Variables de Entorno en Vercel

**Dashboard → Settings → Environment Variables**:

```bash
# Database
DATABASE_URL="postgresql://..."

# Supabase
SUPABASE_URL="https://xxx.supabase.co"
SUPABASE_ANON_KEY="eyJ..."
SUPABASE_SERVICE_ROLE_KEY="eyJ..."

# Firebase (FCM)
FIREBASE_PROJECT_ID="sacdia-app"
FIREBASE_CLIENT_EMAIL="firebase-adminsdk@..."
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"

# Redis (Upstash)
REDIS_URL="redis://..."

# JWT
JWT_SECRET="your-super-secret-key-change-in-production"
JWT_EXPIRES_IN="15m"

# CORS
CORS_ORIGIN="https://admin.sacdia.app,https://sacdia.app"

# Rate Limiting
RATE_LIMIT_TTL="60"
RATE_LIMIT_LIMIT="100"

# Sentry (opcional)
SENTRY_DSN="https://..."
```

**IMPORTANTE**: Crear variables separadas para cada ambiente (Production, Preview, Development).

---

#### 3. Deployment desde CLI

```bash
# Instalar Vercel CLI
npm i -g vercel

# Login
vercel login

# Deploy a Preview (staging)
vercel

# Deploy a Production
vercel --prod

# Ver logs
vercel logs [deployment-url]
```

---

#### 4. Deployment desde GitHub

**Configurar en Vercel Dashboard**:

1. Conectar repositorio: `github.com/abn-r/sacdia-backend`
2. Configurar:
   - **Framework Preset**: Other
   - **Build Command**: `npm run build`
   - **Output Directory**: `dist`
   - **Install Command**: `npm install`

3. **Git Integration**:
   - `main` branch → Production
   - `development` branch → Preview (Staging)
   - Pull Requests → Preview URLs automáticos

---

#### 5. Post-Deployment

**Ejecutar migraciones** (una vez):

```bash
# Desde local conectado a producción
DATABASE_URL="postgresql://..." npx prisma migrate deploy

# O configurar en Vercel
# Build Command: npm run build && npx prisma migrate deploy
```

**Verificar deployment**:

```bash
curl https://api.sacdia.app/api/v1/health
# Response: { "status": "ok" }

curl https://api.sacdia.app/api
# Debe redirigir a Swagger UI
```

---

### Deployment Alternativo: Railway

Si prefieres Railway en lugar de Vercel:

**railway.json**:

```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "NIXPACKS"
  },
  "deploy": {
    "startCommand": "npm run start:prod",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

**Variables de entorno**: Mismas que Vercel

**Comandos**:

```bash
# Instalar CLI
npm i -g @railway/cli

# Login
railway login

# Vincular proyecto
railway link

# Deploy
railway up
```

---

## Admin Panel (Next.js)

### Deployment en Vercel

#### 1. Configuración

**Archivo**: `vercel.json` (opcional si usas defaults)

```json
{
  "buildCommand": "pnpm build",
  "devCommand": "pnpm dev",
  "installCommand": "pnpm install",
  "framework": "nextjs",
  "outputDirectory": ".next"
}
```

---

#### 2. Variables de Entorno

```bash
# API
NEXT_PUBLIC_API_URL="https://api.sacdia.app/api/v1"

# Supabase
NEXT_PUBLIC_SUPABASE_URL="https://xxx.supabase.co"
NEXT_PUBLIC_SUPABASE_ANON_KEY="eyJ..."

# Opcional: Analytics
NEXT_PUBLIC_VERCEL_ANALYTICS_ID="xxx"
```

---

#### 3. Deployment

**Desde Dashboard**:
1. Conectar repo: `github.com/abn-r/sacdia-admin`
2. Framework: Next.js (detectado automáticamente)
3. Root Directory: `./` o `sacdia-admin/` si es monorepo
4. Build Command: `pnpm build`

**Desde CLI**:

```bash
cd sacdia-admin
vercel --prod
```

---

#### 4. Optimizaciones

**next.config.js**:

```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  // Output standalone para menor tamaño
  output: 'standalone',

  // Optimización de imágenes
  images: {
    domains: ['storage.supabase.co'],
    formats: ['image/avif', 'image/webp'],
  },

  // Comprimir respuestas
  compress: true,

  // Headers de seguridad
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          {
            key: 'X-DNS-Prefetch-Control',
            value: 'on'
          },
          {
            key: 'Strict-Transport-Security',
            value: 'max-age=63072000; includeSubDomains; preload'
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff'
          },
          {
            key: 'X-Frame-Options',
            value: 'DENY'
          },
        ],
      },
    ];
  },
};

module.exports = nextConfig;
```

---

## Mobile App (Flutter)

### Deployment iOS (App Store)

#### 1. Preparación

**Actualizar versión** en `pubspec.yaml`:

```yaml
version: 1.0.0+1
# format: version+build
# 1.0.0 = semantic version
# +1 = build number
```

**Configurar firma**:

```bash
# En Xcode
1. Abrir ios/Runner.xcworkspace
2. Runner → Signing & Capabilities
3. Team: Seleccionar Apple Developer Account
4. Bundle Identifier: com.sacdia.app
```

---

#### 2. Build para App Store

```bash
# Limpiar
flutter clean
flutter pub get

# Build Release
flutter build ios --release

# Abrir en Xcode
open ios/Runner.xcworkspace
```

**En Xcode**:
1. Product → Archive
2. Esperar a que compile
3. Window → Organizer
4. Seleccionar archive → Distribute App
5. App Store Connect → Upload

---

#### 3. App Store Connect

1. Crear app en [App Store Connect](https://appstoreconnect.apple.com)
2. Completar metadata:
   - Nombre: "SACDIA - Clubes JA"
   - Categoría: Educación
   - Screenshots (required)
   - Descripción
   - Keywords
   - Privacy Policy URL

3. Versión:
   - Subir build
   - Agregar "What's New"
   - Submit for Review

---

### Deployment Android (Google Play)

#### 1. Configurar Firma

**Crear keystore**:

```bash
keytool -genkey -v -keystore ~/sacdia-upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias sacdia-key
```

**Archivo**: `android/key.properties`

```properties
storePassword=<password>
keyPassword=<password>
keyAlias=sacdia-key
storeFile=/Users/abner/sacdia-upload-keystore.jks
```

**Actualizar** `android/app/build.gradle`:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

---

#### 2. Build App Bundle

```bash
# Limpiar
flutter clean
flutter pub get

# Build App Bundle (recomendado)
flutter build appbundle --release

# O APK (no recomendado para Play Store)
flutter build apk --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

---

#### 3. Google Play Console

1. Crear app en [Google Play Console](https://play.google.com/console)
2. Completar Store Listing:
   - Título: "SACDIA - Clubes JA"
   - Descripción corta
   - Descripción completa
   - Screenshots (min 2)
   - Ícono (512x512)

3. Versión:
   - Upload `app-release.aab`
   - Agregar Release Notes
   - Submit for Review

---

#### 4. CI/CD con GitHub Actions

**Archivo**: `.github/workflows/deploy-android.yml`

```yaml
name: Deploy Android

on:
  push:
    branches: [main]
    tags:
      - 'v*.*.*'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - uses: actions/setup-java@v3
        with:
          distribution: 'zulu'
          java-version: '11'

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
          channel: 'stable'

      - run: flutter pub get
      - run: flutter test
      - run: flutter build appbundle --release

      - name: Upload to Play Store
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT }}
          packageName: com.sacdia.app
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: production
          status: completed
```

---

## Base de Datos

### Supabase

**Ya está en la nube**, no requiere deployment adicional.

**Migraciones**:

```bash
# Desde local a producción
DATABASE_URL="postgresql://..." npx prisma migrate deploy

# O usar Supabase CLI
supabase db push
```

**Backups automáticos**:
- Supabase Free: Backups diarios (7 días de retención)
- Supabase Pro: Backups diarios (30 días de retención) + Point-in-Time Recovery

**Backup manual**:

```bash
# Exportar schema + data
pg_dump $DATABASE_URL > backup_$(date +%Y%m%d).sql

# Restaurar
psql $DATABASE_URL < backup_20260204.sql
```

---

## CI/CD

### GitHub Actions - Backend

**Archivo**: `.github/workflows/deploy-backend.yml`

```yaml
name: Deploy Backend

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'

      - name: Install dependencies
        run: npm install

      - name: Run linter
        run: npm run lint

      - name: Run tests
        run: npm run test

      - name: Run E2E tests
        run: npm run test:e2e
        env:
          DATABASE_URL: ${{ secrets.TEST_DATABASE_URL }}

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3

      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          vercel-args: '--prod'

      - name: Run Migrations
        run: |
          npx prisma migrate deploy
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
```

---

### GitHub Actions - Admin Panel

**Archivo**: `.github/workflows/deploy-admin.yml`

```yaml
name: Deploy Admin Panel

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'

      - name: Install pnpm
        run: npm install -g pnpm

      - name: Install dependencies
        run: pnpm install

      - name: Build
        run: pnpm build
        env:
          NEXT_PUBLIC_API_URL: ${{ secrets.NEXT_PUBLIC_API_URL }}
          NEXT_PUBLIC_SUPABASE_URL: ${{ secrets.NEXT_PUBLIC_SUPABASE_URL }}
          NEXT_PUBLIC_SUPABASE_ANON_KEY: ${{ secrets.NEXT_PUBLIC_SUPABASE_ANON_KEY }}

      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_ADMIN_PROJECT_ID }}
          vercel-args: '--prod'
```

---

## Monitoring

### Sentry (Error Tracking)

**Backend (NestJS)**:

```bash
npm install @sentry/node @sentry/tracing
```

**main.ts**:

```typescript
import * as Sentry from '@sentry/node';

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampleRate: 1.0,
});

app.use(Sentry.Handlers.requestHandler());
app.use(Sentry.Handlers.tracingHandler());

// Al final
app.use(Sentry.Handlers.errorHandler());
```

---

**Frontend (Next.js)**:

```bash
npx @sentry/wizard@latest -i nextjs
```

**Configuración automática** en `sentry.client.config.ts` y `sentry.server.config.ts`.

---

**Mobile (Flutter)**:

```yaml
dependencies:
  sentry_flutter: ^7.14.0
```

```dart
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://...@sentry.io/...';
      options.tracesSampleRate = 1.0;
    },
    appRunner: () => runApp(MyApp()),
  );
}
```

---

### Vercel Analytics

**Automático** para proyectos en Vercel.

**Dashboard**: Vercel → Proyecto → Analytics

Métricas:
- Requests por segundo
- Latencia p50, p75, p99
- Errores 4xx, 5xx
- Bandwidth

---

### Uptime Monitoring (Uptime Robot)

1. Crear cuenta en [Uptime Robot](https://uptimerobot.com)
2. Agregar monitors:
   - `https://api.sacdia.app/api/v1/health` (cada 5 min)
   - `https://admin.sacdia.app` (cada 5 min)

3. Configurar alertas:
   - Email
   - Slack
   - SMS (opcional)

---

## Troubleshooting

### Backend no levanta en Vercel

**Problema**: `Error: Cannot find module 'dist/main'`

**Solución**:
1. Verificar `vercel.json` apunta a `src/main.ts`
2. Verificar `package.json` tiene script `vercel-build`
3. Revisar logs: `vercel logs [deployment-url]`

---

### Migraciones de Prisma fallan

**Problema**: `Error: Migration failed`

**Solución**:
1. Resetear DB (solo en staging):
   ```bash
   npx prisma migrate reset
   ```

2. En producción, crear migración manual:
   ```bash
   npx prisma migrate deploy --skip-generate
   ```

---

### CORS Errors en Frontend

**Problema**: `Access-Control-Allow-Origin error`

**Solución**: Verificar `CORS_ORIGIN` en backend incluye URL del frontend:

```typescript
app.enableCors({
  origin: process.env.CORS_ORIGIN?.split(','),
  credentials: true,
});
```

---

### Mobile App crashes al abrir

**Problema**: App cierra inmediatamente después de abrir

**Solución**:
1. Revisar logs:
   ```bash
   # iOS
   flutter logs

   # Android
   adb logcat
   ```

2. Verificar configuración de Supabase en `main.dart`
3. Verificar permisos en `AndroidManifest.xml` / `Info.plist`

---

## Checklist de Deployment

### Pre-Deployment

- [ ] Tests passing (unit + E2E)
- [ ] Linter sin errores
- [ ] Migraciones creadas
- [ ] Variables de entorno configuradas
- [ ] Secrets actualizados
- [ ] Documentación actualizada

### Deployment

- [ ] Deploy a staging primero
- [ ] Smoke tests en staging
- [ ] Ejecutar migraciones
- [ ] Deploy a producción
- [ ] Verificar health endpoint
- [ ] Verificar Swagger UI
- [ ] Tests E2E contra producción

### Post-Deployment

- [ ] Monitoring activo (Sentry, Vercel Analytics)
- [ ] Uptime checks configurados
- [ ] Backups verificados
- [ ] Team notificado
- [ ] Changelog actualizado

---

**Generado**: 4 de febrero de 2026
**Versión**: 2.2.0
**Estado**: Producción Ready
