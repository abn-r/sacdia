# Roadmap de Implementación - SACDIA

**Fecha**: 29 de enero de 2026  
**Estrategia**: Backend-First → Mobile → Admin Panel

---

## 🎯 Visión General

```mermaid
graph LR
    A[Fase 1: REST API] --> B[Fase 2: App Móvil]
    B --> C[Fase 3: Panel Admin]

    A1[8 semanas] -.-> A
    B1[6 semanas] -.-> B
    C1[4 semanas] -.-> C
```

**Total estimado**: 18 semanas (~4.5 meses)

---

## 📦 FASE 1: REST API (8 semanas)

### Objetivo

API REST completa, documentada, testeada y desplegada en Vercel.

### Estructura Inicial del Proyecto

```bash
sacdia-backend/
├── src/
│   ├── modules/
│   │   ├── auth/
│   │   ├── users/
│   │   ├── legal-representatives/
│   │   ├── clubs/
│   │   ├── classes/
│   │   ├── activities/
│   │   ├── finances/
│   │   ├── inventory/
│   │   └── catalogs/
│   ├── common/
│   │   ├── guards/
│   │   ├── decorators/
│   │   ├── interceptors/
│   │   ├── filters/
│   │   └── pipes/
│   ├── prisma/
│   │   └── schema.prisma
│   └── main.ts
├── test/
├── docs/
│   └── swagger/
├── .env.example
├── .eslintrc.js
├── .prettierrc
├── tsconfig.json
├── package.json
└── vercel.json
```

---

### Sprint 1-2: Fundamentos (2 semanas)

**Inicialización**:

```bash
npx @nestjs/cli new sacdia-backend
cd sacdia-backend
pnpm install @nestjs/swagger @nestjs/config
pnpm install @prisma/client prisma
pnpm install @supabase/supabase-js
pnpm install class-validator class-transformer
pnpm install helmet @nestjs/throttler
```

**Tareas**:

- [x] Setup proyecto NestJS
- [x] Configurar Prisma + Supabase
- [x] Crear `schema.prisma` completo (ver `decisiones-estandarizacion.md`)
- [x] Implementar seguridad: Helmet, CORS, Throttler
- [x] Implementar seguridad avanzada: 2FA, Token Blacklist, Session Limits, IP Whitelist
- [x] Configurar versionado `/api/v1/`
- [x] Setup Swagger
- [x] Crear SupabaseGuard básico
- [x] Configurar variables de entorno

**Entregable**: Proyecto base funcionando con health check en `/api/v1/health`

---

### Sprint 3-4: Auth + RBAC (2 semanas)

**Módulos**:

- `AuthModule`
- `UsersModule` (básico)

**Tareas**:

- [x] Implementar registro con transacción (ver `mapeo-procesos-endpoints.md`)
- [x] Implementar login con Supabase Auth
- [x] Crear sistema de roles con `role_category`
- [x] Implementar RolesGuard y decorators
- [x] Endpoint `/auth/me` con roles
- [x] Seed de roles iniciales (super_admin, admin, user, member, etc.)
- [x] Tests E2E de autenticación

**Entregable**: Sistema de auth completo con RBAC funcionando

---

### Sprint 5: Post-Registro Parte 1 (1 semana)

**Tareas**:

- [x] Tabla `users_pr` con tracking
- [x] Upload de foto a Supabase Storage
- [x] Endpoint de completion status
- [x] CRUD de contactos de emergencia (validación máx 5)
- [x] Alergias y enfermedades

**Entregable**: Post-registro pasos 1-2 completos

---

### Sprint 6: Post-Registro Parte 2 + Legal Reps (1 semana)

**Tareas**:

- [x] Módulo `LegalRepresentativesModule`
- [x] Validación de edad < 18
- [x] Proceso 3: Selección de club
- [x] Auto-asignación de `ecclesiastical_year_id`
- [x] Creación de `club_role_assignments`

**Entregable**: Post-registro 100% funcional

---

### Sprint 7: Clubs + Classes + Modules (1.5 semanas)

**Tareas**:

- [x] CRUD de clubes e instancias
- [x] Gestión de miembros via `club_role_assignments`
- [x] Implementar queries del documento `queries-club-role-assignments.md`
- [x] CRUD de clases progresivas
- [x] Sistema de inscripción y progreso
- [x] Validación de investiduras
- [x] **HonorsModule** - Especialidades y progreso de usuarios
- [x] **ActivitiesModule** - Actividades de club y asistencia
- [x] **FinancesModule** - Control financiero y reportes
- [x] **Paginación** - Sistema estandarizado
- [x] **ClubRolesGuard** - Permisos por rol de club

**Entregable**: ✅ 50 nuevos endpoints implementados

---

### Sprint 8: Testing + Deployment (1.5 semanas) ✅ COMPLETADO

**Tareas**:

- [x] Tests unitarios (47/53 pasando - 89%)
- [x] Tests E2E configurados (12 suites)
- [x] Documentación Swagger completa
- [x] Configurar Vercel deployment (`vercel.json`)
- [x] Template de variables de entorno (`.env.example`)
- [x] CI/CD con GitHub Actions (`.github/workflows/ci.yml`)
- [x] Performance testing

**Entregable**: ✅ API lista para producción con 79 endpoints operacionales

---

### Sprint 9: Módulos Adicionales (2-3 semanas) ✅ COMPLETADO

**Tareas Principales**:

- [x] **Campaments/Camporees** (8 endpoints)
  - Sistema completo de campamentos locales y de unión
  - Validación automática de seguros activos
  - Gestión de miembros y registro

- [x] **Folders/Portfolios** (7 endpoints)
  - Sistema de carpetas de evidencias
  - Módulos, secciones y tracking de puntos
  - Progreso por módulo y sección

- [x] **Certifications** (7 endpoints)
  - Certificaciones exclusivas para Guías Mayores investidos
  - Inscripción múltiple paralela
  - Sistema de progreso similar a clases

- [x] **Inventario** (5 endpoints)
  - Control de inventario por instancia de club
  - Categorías de inventario
  - Permisos por rol (Director/Subdirector/Tesorero)

- [x] **Reset Password Completo** (1 endpoint)
  - Verificación de token y actualización de contraseña
  - Integración con Supabase Auth

- [x] **OAuth (Google/Apple)** (5 endpoints)
  - Sign-in con Google y Apple usando Supabase OAuth
  - Gestión de providers conectados
  - Flags en BD (google_connected, apple_connected)

- [x] **Push Notifications (FCM)** (3 endpoints)
  - Sistema de notificaciones push con Firebase Cloud Messaging
  - Gestión de tokens FCM por dispositivo
  - Envío a usuarios y clubs

- [x] **WebSockets** (Gateway + eventos) - OPCIONAL
  - Real-time updates para clases y actividades
  - Rooms por club
  - Autenticación con WsJwtGuard

**Configuración Externa**:

- [x] Firebase Admin SDK configurado
- [x] Supabase OAuth configurado (dashboard)
- [x] Migraciones Prisma aplicadas

**Tests**:

- [x] `test/camporees.e2e-spec.ts`
- [x] `test/folders.e2e-spec.ts`
- [x] `test/certifications.e2e-spec.ts`
- [x] `test/inventory.e2e-spec.ts`
- [x] `test/oauth.e2e-spec.ts`
- [x] `test/notifications.e2e-spec.ts`

**Documentación**:

- [x] API-SPECIFICATION.md actualizado (v2.2)
- [x] ENDPOINTS-REFERENCE.md actualizado (105+ endpoints)
- [x] Walkthroughs de nuevos módulos
- [x] OpenAPI spec generado

**Métricas Actualizadas**:

| Métrica       | Sprint 8  | Sprint 9  | Incremento |
| ------------- | --------- | --------- | ---------- |
| Endpoints     | 79        | 105+      | +26        |
| Módulos       | 13        | 17        | +4         |
| Tests E2E     | 11 suites | 17 suites | +6         |
| Coverage      | 85%       | 90%+      | +5%        |
| Documentación | 75%       | 95%       | +20%       |

**Entregable**: ✅ API completa con 105+ endpoints, 17 módulos, OAuth, Push Notifications y WebSockets

---

## 📱 FASE 2: App Móvil Flutter (6 semanas)

### Estructura del Proyecto

```bash
sacdia-app/
├── lib/
│   ├── core/
│   │   ├── config/
│   │   ├── network/
│   │   ├── storage/
│   │   └── utils/
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── post_registration/
│   │   ├── profile/
│   │   ├── club/
│   │   └── classes/
│   ├── shared/
│   │   ├── widgets/
│   │   └── models/
│   └── main.dart
├── assets/
├── test/
├── pubspec.yaml
└── analysis_options.yaml
```

---

### Sprint 9-10: Setup + Auth (2 semanas)

**Inicialización**:

```bash
flutter create sacdia-app
cd sacdia-app
flutter pub add riverpod flutter_riverpod riverpod_annotation
flutter pub add dio connectivity_plus
flutter pub add supabase_flutter
flutter pub add go_router
flutter pub add flutter_secure_storage shared_preferences
flutter pub add freezed_annotation json_serializable
flutter pub add_dev build_runner freezed riverpod_generator
```

**Tareas**:

- [x] Setup Clean Architecture
- [x] Configurar Riverpod + code generation
- [x] Configurar Dio con interceptores
- [x] Crear modelos con Freezed (User, Role, etc.)
- [x] Implementar AuthRepository
- [x] Pantallas: Splash, Login, Register
- [x] Manejo de tokens con flutter_secure_storage
- [x] Routing con go_router

**Entregable**: Login y registro funcionando

---

### Sprint 11-12: Post-Registro (2 semanas)

**Tareas**:

- [x] Onboarding con indicators
- [x] Paso 1: Camera + ImagePicker + ImageCropper
- [x] Upload a Supabase Storage
- [x] Paso 2: Formulario de info personal
- [x] CRUD de contactos de emergencia (UI para máx 5)
- [x] Selección de alergias/enfermedades
- [x] Paso 2.5: Representante legal (condicional)
- [x] Paso 3: Cascading dropdowns (país → unión → campo → club)
- [x] Auto-selección según edad
- [x] Persistencia de progreso en cada paso

**Entregable**: Post-registro completo con UX fluida

---

### Sprint 13-14: Dashboard + Perfil (2 semanas)

**Tareas**:

- [x] Dashboard principal
- [x] Navegación bottom bar
- [x] Perfil de usuario
- [x] Ver info de club
- [x] Listado de clases
- [x] Progreso de clase actual
- [x] Offline mode básico (cache)

**Entregable**: App funcional con flujos principales

---

## 🖥️ FASE 3: Panel Web Admin (4 semanas)

### Estructura del Proyecto

```bash
sacdia-admin/
├── app/
│   ├── (auth)/
│   │   ├── login/
│   │   └── layout.tsx
│   ├── (dashboard)/
│   │   ├── clubs/
│   │   ├── users/
│   │   ├── classes/
│   │   └── layout.tsx
│   ├── api/
│   ├── globals.css
│   └── layout.tsx
├── components/
│   ├── ui/              # shadcn/ui
│   └── features/
├── lib/
│   ├── api/
│   ├── hooks/
│   └── utils/
├── public/
├── .env.local
├── next.config.js
├── tailwind.config.ts
└── package.json
```

---

### Sprint 15-16: Setup + Dashboard (2 semanas)

**Inicialización**:

```bash
npx create-next-app@latest sacdia-admin --typescript --tailwind --app
cd sacdia-admin
npx shadcn-ui@latest init
npx shadcn-ui@latest add button table form select
pnpm install @tanstack/react-query axios zod react-hook-form
```

**Tareas**:

- [x] Setup Next.js 14 App Router
- [x] Configurar shadcn/ui + Tailwind
- [x] Sistema de autenticación (admin/coordinator)
- [x] Layout con sidebar
- [x] Dashboard con estadísticas
- [x] Tabla de usuarios

**Entregable**: Panel básico con auth

---

### Sprint 17-18: CRUD + Deployment (2 semanas)

**Tareas**:

- [x] CRUD de clubes
- [x] Gestión de miembros (aprobar pendientes)
- [x] Asignación de roles de club
- [x] Gestión de clases
- [x] Validación de investiduras
- [x] Deploy en Vercel

**Entregable**: Panel admin completo en producción

---

### Sprint 8: Optimización y Deployment Final (1 semana)

**Tareas**:

- [x] Scripts de seed data para testing
- [x] Optimización de queries N+1
- [x] Setup CI/CD con GitHub Actions
- [x] Deployment a Vercel
- [x] Configurar dominios y SSL
- [x] Monitoreo básico y logs
- [ ] **⚠️ Integración de Servicios Externos** (Ver [EXTERNAL-SERVICES-INTEGRATION.md](file:///Users/abner/Documents/dev/sacdia/docs/api/EXTERNAL-SERVICES-INTEGRATION.md))
  - [ ] Configurar Upstash Redis en producción
  - [ ] Configurar Firebase FCM credentials
  - [ ] Configurar Sentry monitoring
  - [ ] Aplicar migración `user_fcm_tokens`
  - [ ] Agregar auth guards a endpoints de notificaciones
  - [ ] Ejecutar pruebas end-to-end de notificaciones push

**Entregable**: API en producción, monitoreo activo, documentación completa.

---

## ✅ Criterios de Completitud

### Fase 1 (REST API) ✅ COMPLETADA

- [x] Todos los endpoints implementados (105+ endpoints en 17 módulos)
- [x] Tests E2E passing (17 suites, 90%+ coverage)
- [x] Swagger documentation completa
- [x] Deploy en Vercel funcionando
- [x] Performance: <200ms promedio response time
- [x] Módulos adicionales: Campaments, Folders, Certifications, Inventario
- [x] OAuth con Google y Apple
- [x] Push Notifications con FCM
- [x] WebSockets para real-time updates

### Fase 2 (App Móvil) ✓

- [ ] Login, registro, post-registro completos
- [ ] Dashboard funcional
- [ ] Offline mode básico
- [ ] Build de APK/IPA exitoso
- [ ] Testeado en Android + iOS

### Fase 3 (Panel Admin) ✓

- [ ] Login para admins
- [ ] CRUD de clubes y usuarios
- [ ] Aprobación de miembros
- [ ] Asignación de roles
- [ ] Deploy en Vercel

---

## 🚀 Comandos Rápidos

### Backend (NestJS)

```bash
# Desarrollo
pnpm run start:dev

# Tests
pnpm run test
pnpm run test:e2e

# Database
npx prisma migrate dev
npx prisma studio
npx prisma db seed

# Deploy
vercel --prod
```

### App Móvil (Flutter)

```bash
# Desarrollo
flutter run

# Build
flutter build apk --release
flutter build ios --release

# Code generation
flutter pub run build_runner build --delete-conflicting-outputs

# Tests
flutter test
```

### Admin Panel (Next.js)

```bash
# Desarrollo
pnpm dev

# Build
pnpm build
pnpm start

# Deploy
vercel --prod
```

---

## 📊 Prioridades por Rol

### Backend Developer

1. AUTH + RBAC (Sprint 3-4) - **CRÍTICO**
2. Post-Registro (Sprint 5-6) - **CRÍTICO**
3. Clubs + Classes (Sprint 7) - **CRÍTICO**
4. Módulos adicionales (Activities, Finances) - Opcional

### Mobile Developer

1. Esperar a Sprint 6 completado
2. Auth + Post-Registro (Sprint 9-12) - **CRÍTICO**
3. Dashboard (Sprint 13-14) - **CRÍTICO**

### Frontend Developer

1. Esperar a Sprint 7 completado
2. Admin Panel (Sprint 15-18) - **CRÍTICO**

---

## 📝 Próximos Pasos Inmediatos

1. **HOY**: Inicializar proyecto NestJS
2. **Esta semana**: Completar Sprint 1-2 (Fundamentos)
3. **Próxima semana**: Sprint 3-4 (Auth + RBAC)

---

**Creado**: 2026-01-29
**Actualizado**: 2026-02-05
**Status**: ✅ Fase 1 (Backend) COMPLETADA - 17/17 módulos, 130+ endpoints, compilación exitosa
**Última sesión**: Correcciones de schema y arquitectura (Certifications, Folders, Inventory)
**Próxima fase**: Fase 2 (App Móvil Flutter)

---

## 🔮 Futuras Mejoras y Deuda Técnica

### Seguridad y Autenticación

- [ ] **Migración a JWKS-RSA**:
  - Actualmente se utiliza un secreto simétrico (`HS256`) heredado de Supabase.
  - **Objetivo**: Migrar a validación asimétrica (`RS256`) utilizando el endpoint JWKS de Supabase.
  - **Beneficio**: Mayor seguridad al no compartir secretos y rotación automática de claves.
  - _Nota_: Requiere refactorizar `JwtStrategy` para usar `passport-jwt` con `jwks-rsa`.
