# Technology Stack

> Define el stack tecnológico del proyecto  
> La IA usará esta info para suggest implementaciones compatibles

---

## Stack Overview

**Tipo de Proyecto**: Full-stack (Backend API + Admin Web + Mobile App)

**Arquitectura**: Backend REST API + Múltiples Clients (Web Admin + Flutter App)

**Metodología**: Clean Architecture

---

## Frontend

### Framework Principal (Admin Panel)

**Framework**: Next.js  
**Versión**: 14+ (App Router)  
**Por qué lo elegimos**: SSR/SSG capabilities, mejor SEO, routing integrado, ideal para panel admin

### Lenguaje

**Lenguaje**: TypeScript  
**Versión**: 5.x  
**Configuración**: strict mode enabled

### Librerías y Herramientas

#### UI Components & Styling (Admin Panel)

- **UI Library**: shadcn/ui (Radix UI + Tailwind CSS)
- **Styling**: Tailwind CSS
- **Icons**: Lucide React (viene con shadcn/ui)
- **Forms**: React Hook Form + Zod validation

#### State Management (Admin Panel)

- **Global State**: Context API / Zustand (si se necesita)
- **Server State**: TanStack Query (React Query) - para cache y sincronización con backend
- **Form State**: React Hook Form

#### Routing (Admin Panel)

- **Router**: Next.js App Router (built-in)
- **Versión**: Next.js 14+

#### Data Fetching (Admin Panel)

- **HTTP Client**: Axios (con interceptors para auth)
- **GraphQL Client**: No usamos GraphQL - REST API

#### Testing (Admin Panel)

- **Unit/Integration**: Jest
- **Component Testing**: React Testing Library
- **E2E**: Playwright
- **Coverage objetivo**: >70%

#### Build Tools

- **Bundler**: Next.js (built-in Turbopack/Webpack)
- **Package Manager**: **pnpm** (rápido, eficiente en espacio)

---

## Backend

### Framework Principal

**Framework**: NestJS  
**Versión**: 10.x  
**Por qué lo elegimos**: Arquitectura modular, TypeScript nativo, decorators, excelente para APIs enterprise, integración con Prisma

### Lenguaje

**Lenguaje**: Node.js con TypeScript  
**Versión**: Node 20.x LTS / TypeScript 5.x

**Librerías NestJS**:
- `@nestjs/config` - Configuración
- `@nestjs/jwt` - JWT tokens
- `@nestjs/passport` - Autenticación
- `class-validator` + `class-transformer` - Validación de DTOs
- `@nestjs/swagger` - Documentación API

### Base de Datos

#### Database Principal

**Tipo**: Relacional  
**Motor**: PostgreSQL (hosted en Supabase)  
**Versión**: 15.x  
**ORM/ODM**: Prisma (v5.x)

**Prisma Features Usados**:
- Prisma Client - Type-safe queries
- Prisma Migrate - Migraciones de DB
- Prisma Studio - GUI para DB (dev)

#### Bases de Datos Adicionales

- **Cache**: Redis (para sessions, rate limiting)
- **Search**: Ninguno (usar PostgreSQL full-text search inicialmente)
- **Queue**: Redis + Bull (para jobs asíncronos)
- **Storage**: Supabase Storage (archivos/imágenes)

### APIs

**Estilo de API**: REST

**REST API Details**:
- Versionado: URL-based (`/api/v1/`)
- Autenticación: JWT (tokens de Supabase Auth)
- Response format: JSON
- Status codes: Estándar HTTP
- Rate limiting: Implementado con `@nestjs/throttler`

**Si GraphQL**:
- Server: [Apollo Server | GraphQL Yoga | Otro]
- Schema approach: [Code-first | Schema-first]

### Testing Backend

- **Unit**: Jest (built-in NestJS)
- **Integration**: Supertest + Test DB PostgreSQL
- **DB Testing**: Docker PostgreSQL container para tests

---

## Mobile App (Flutter)

### Framework Principal

**Framework**: Flutter  
**Versión**: 3.19+ (Stable channel)  
**Lenguaje**: Dart 3.3+  
**Por qué**: Cross-platform (iOS + Android con mismo código), performance casi nativo, widgets ricos, comunidad activa

### Arquitectura

**Patrón**: **Clean Architecture**

**Capas**:
```
lib/
├── core/                  # Utilidades, constantes, extensions, errores
│   ├── constants/
│   ├── extensions/
│   ├── utils/
│   └── errors/
│
├── features/              # Features por dominio (bounded contexts)
│   └── [feature_name]/
│       ├── data/          # Capa de Datos
│       │   ├── datasources/    # Remote y Local data sources
│       │   ├── models/         # DTOs (de/hacia JSON)
│       │   └── repositories/   # Implementación de repositories
│       │
│       ├── domain/        # Capa de Dominio (lógica de negocio)
│       │   ├── entities/       # Entidades del negocio (plain Dart objects)
│       │   ├── repositories/   # Interfaces de repositories
│       │   └── usecases/       # Casos de uso (1 acción por clase)
│       │
│       └── presentation/  # Capa de Presentación (UI)
│           ├── pages/          # Pantallas completas
│           ├── widgets/        # Widgets reutilizables del feature
│           ├── providers/      # Riverpod providers
│           └── state/          # State notifiers, estados
│
└── shared/                # Compartido entre features
    ├── widgets/           # Widgets globales reutilizables
    ├── theme/             # Temas, colores, text styles
    └── providers/         # Providers globales (auth, config)
```

**Principios Clean Architecture aplicados**:
- **Dependency Rule**: Dependencias apuntan hacia adentro (Presentation → Domain ← Data)
- **Domain no depende de nada**: Solo Dart puro
- **Use Cases**: Una clase por acción de negocio
- **Repository Pattern**: Abstracción para acceso a datos

### State Management

**Solución**: **Riverpod 2.x** (https://riverpod.dev/)

**Por qué Riverpod**:
- Type-safe con compile-time errors
- No necesita BuildContext
- Testeable fácilmente (providers son top-level)
- Mejor que Provider (su sucesor mejorado)
- Auto-dispose cuando no se usa
- Code generation support

**Tipos de Providers usados**:
```dart
// Estado simple inmutable
final counterProvider = StateProvider<int>((ref) => 0);

// Estado complejo con lógica
final userNotifierProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier(ref.read(userRepositoryProvider));
});

// Async data loading
final usersProvider = FutureProvider<List<User>>((ref) async {
  return await ref.read(userRepositoryProvider).getUsers();
});

// Stream para real-time
final notificationsProvider = StreamProvider<Notification>((ref) {
  return ref.read(notificationServiceProvider).notificationsStream();
});
```

### HTTP & Networking

**HTTP Client**: **Dio 5.x** (https://pub.dev/packages/dio)

**Configuración**:
```dart
// DioClient con interceptors
- BaseURL configurada
- Timeout (connect: 30s, receive: 30s)
- Auth Interceptor (inyecta JWT token)
- Logging Interceptor (solo en dev mode)
- Error Interceptor (manejo centralizado de errores)
- Retry Interceptor (3 reintentos en errores de red)
```

**Librerías complementarias**:
- `dio_cache_interceptor` - Cache de HTTP responses
- `pretty_dio_logger` - Logs legibles (dev only)

### Serialización de Datos

**json_serializable 6.x** + **freezed 2.x**

**Por qué**:
- Code generation = menos boilerplate
- Type-safe serialization
- freezed: Immutable models + union types + copyWith

**Ejemplo**:
```dart
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    required String name,
    DateTime? lastLogin,
  }) = _User;
  
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

### Local Storage & Persistence

**Secure Storage (Tokens, Secrets)**:
- `flutter_secure_storage` - Keychain (iOS) / KeyStore (Android)
- Para: JWT tokens, refresh tokens, API keys

**Preferences (Settings simples)**:
- `shared_preferences` - Key-value storage
- Para: Theme mode, idioma, flags de features

**SQLite Local (Cache opcional)**:
- `drift` (antes Moor) - SQL type-safe
- Solo si necesitas cache offline complejo

### Autenticación Flow

**Provider**: **Supabase Auth**

**Librerías**:
- `supabase_flutter` 2.x - Cliente oficial de Supabase

**Flow de Autenticación**:
```
1. User Login/Register → Supabase Auth API
2. Supabase Auth retorna JWT access token + refresh token
3. Guardar tokens en flutter_secure_storage
4. Dio Interceptor inyecta token en headers para llamadas a Backend NestJS:
   Authorization: Bearer {jwt_token}
5. Backend NestJS valida JWT (verifica signature con Supabase public key)
6. Refresh automático cuando token expira (Dio interceptor detecta 401)
```

**Providers Riverpod de Auth**:
```dart
// Auth state provider
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>(...);

// User profile provider
final currentUserProvider = FutureProvider<User?>(...);

// Auth repository
final authRepositoryProvider = Provider<AuthRepository>(...);
```

### Navegación

**Router**: **go_router 13.x**

**Por qué**:
- Routing declarativo type-safe
- Deep linking support
- Redirecciones (guards para auth)
- Rutas anidadas
- Manejo de back button

**Estructura**:
```dart
final router = GoRouter(
  redirect: (context, state) {
    // Auth guards aquí
  },
  routes: [
    GoRoute(path: '/login', builder: ...),
    GoRoute(path: '/home', builder: ...),
    GoRoute(
      path: '/feature/:id',
      builder: ...,
      routes: [  // Nested routes
        GoRoute(path: 'detail', builder: ...),
      ],
    ),
  ],
);
```

### UI/UX

**Design System**: **Material 3** (Material You)

**Temas**:
- Light theme
- Dark theme
- Dynamic color (Material You) opcional

**Responsive**:
- `responsive_framework` o custom MediaQuery breakpoints
- Adaptive para iOS/Android (CupertinoApp si necesario)

**Librerías UI Esenciales**:
```yaml
dependencies:
  # Icons & Images
  flutter_svg: ^2.0.0              # SVG support
  cached_network_image: ^3.3.0     # Cache de imágenes de red
  
  # Loading & Feedback
  flutter_spinkit: ^5.2.0          # Loading indicators
  fluttertoast: ^8.2.0             # Toast messages
  
  # Forms
  flutter_hooks: ^0.20.0            # Hooks para forms (opcional)
  
  # Animations
  lottie: ^3.0.0                   # Animaciones Lottie (opcional)
  
  # Pull to refresh
  pull_to_refresh: ^2.0.0          # Refresh lists
```

### Internacionalización (i18n)

**Si necesitas múltiples idiomas**:
- `flutter_localizations` (built-in)
- `intl` package
- ARB files para traducciones

### Testing

**Unit Tests**:
- Testear Use Cases, Repositories (con mocks)
- `mockito` + `build_runner` para generate mocks

**Widget Tests**:
- Testear widgets individuales
- `flutter_test` (built-in)

**Integration Tests**:
- E2E testing (opcional para MVP)
- `integration_test` package

**Coverage objetivo**: >70% para production

### DevTools & Debug

- Flutter DevTools (inspector, profiler, network)
- `logger` package para logs estructurados
- Firebase Crashlytics (para crash reporting en producción)

### Features Específicas Móviles

**Modo Offline**:
- `drift` (SQLite) para cache local persistente
- Sincronización automática cuando hay conexión
- Queue de operaciones pendientes

**Real-time**:
- Supabase Realtime para subscripciones
- WebSocket fallback si es necesario

**Geolocalización**:
- `geolocator` package
- Permisos iOS/Android configurados
- Background location (si necesario)

**Cámara/Galería**:
- `image_picker` - Seleccionar de galería
- `camera` - Tomar foto directo
- `image_cropper` - Recortar imágenes
- Compression antes de upload

**Biometría**:
- `local_auth` package
- FaceID (iOS) + Fingerprint (Android)
- Autenticación local para features sensibles

**Notificaciones Locales**:
- `flutter_local_notifications`
- Recordatorios programados
- Background tasks con `workmanager`

**Librerías Adicionales Flutter**:
```yaml
dependencies:
  # Offline & Database
  drift: ^2.14.0
  
  # Real-time
  supabase_flutter: ^2.0.0  # Incluye Realtime
  
  # Location
  geolocator: ^11.0.0
  geocoding: ^2.1.0
  
  # Camera & Images
  image_picker: ^1.0.0
  camera: ^0.10.0
  image_cropper: ^5.0.0
  flutter_image_compress: ^2.0.0
  
  # Biometrics
  local_auth: ^2.1.0
  
  # Notifications
  flutter_local_notifications: ^16.0.0
  firebase_messaging: ^14.0.0
  
  # Background tasks
  workmanager: ^0.5.0
  
  # Crashlytics
  firebase_crashlytics: ^3.4.0
```

---

## Infraestructura

### Hosting

**Backend NestJS**: **Vercel Serverless Functions** (budget-friendly <$20/mes)
**Admin Panel (Next.js)**: Vercel (mismo proyecto que backend)
**Database**: Supabase (PostgreSQL hosted) - Free tier para hobby
**Storage**: Supabase Storage - Free tier
**Redis**: Upstash (Serverless Redis) - Free tier
**Mobile App**: App Store + Google Play Store

**CDN**: Cloudflare (para assets estáticos)

### Containers & Orchestration

**Containerización**: Docker (para backend)  
**Orchestration**: Docker Compose (dev) / Railway o Render (producción simple)

### CI/CD

**Platform**: GitHub Actions

**Pipelines**:

**Backend NestJS**:
```yaml
on: push
jobs:
  test:
    - Install dependencies
    - Run linter (ESLint)
    - Run tests (Jest)
    - Run Prisma generate
  deploy:
    - Build Docker image
    - Push to registry
    - Deploy to hosting (Railway/Render)
```

**Admin Panel (Next.js)**:
```yaml
on: push to main
jobs:
  - Build Next.js app
  - Run tests
  - Deploy to Vercel (automatic)
```

**Flutter App**:
```yaml
on: tag creation
jobs:
  - Run tests
  - Build APK (Android)
  - Build IPA (iOS)
  - Upload to Play Console / App Store Connect
```


---

## Servicios de Terceros

### Esenciales

| Servicio | Propósito | Provider | Alternativa |
|----------|-----------|----------|-------------|
| Authentication | Auth de usuarios | **Supabase Auth** | Auth0, Firebase |
| Email | Emails transaccionales | **Resend** | SendGrid, AWS SES |
| Payments | Procesamiento | **Stripe + PayPal + MercadoPago** | Otro |
| Storage | Archivos/imágenes | **Supabase Storage** | AWS S3, Cloudinary |
| Push Notifications | Notif. móviles | **Firebase Cloud Messaging (FCM)** | OneSignal |

### Opcionales / Nice-to-Have

| Servicio | Propósito | Provider |
|----------|-----------|----------|
| Analytics | User analytics | **Google Analytics 4** |
| Monitoring | Error tracking | **Sentry** (NestJS + Next.js + Flutter) |
| Logs | Log aggregation | Vercel Logs + Better Stack (opcional) |
| Crash Reports | Flutter crashes | **Firebase Crashlytics** |

---

## Desarrollo Local

### Requisitos del Sistema

**Node.js**: Versión 20.x LTS  
**Flutter**: Versión 3.19+ (Stable)  
**Docker**: Requerido para PostgreSQL y Redis locales  
**Supabase CLI**: Para desarrollo local (opcional)

### Setup

bash
# Clone repository
git clone [repo-url]

# Install dependencies
npm install

# Setup environment
cp .env.example .env
# Editar .env con tus valores

# Run database (con Docker)
docker-compose up -d postgres redis

# Run migrations
npm run migrate

# Start dev server
npm run dev


### Puertos Usados

| Servicio | Puerto  |
|----------|--------|
| Next.js Admin Panel | 3000 |
| NestJS Backend API | 3001 |
| PostgreSQL (Docker) | 5432 |
| Redis (Docker) | 6379 |
| Prisma Studio | 5555 |
| Flutter App | Emulator/Device |

---

## Librerías Comunes

### Utilities

**Dates**: date-fns (frontend) / dayjs (backend)  
**Validation**: Zod (Next.js) / class-validator (NestJS)  
**HTTP**: Axios (Next.js) / Dio (Flutter)  
**Logging**: Pino (NestJS) / logger (Flutter)  
**Environment**: dotenv + @nestjs/config

### Frontend Specific

**Charts** (Admin): Recharts  
**Tables** (Admin): TanStack Table (React Table v8)  
**File Upload** (Admin): react-dropzone  
**Rich Text**: TipTap o Lexical (si necesario)

---

## Coding Standards & Tools

### Linting

**JavaScript/TypeScript**: ESLint + Prettier  
**Config**: Airbnb base + custom rules para NestJS y Next.js

**Flutter/Dart**: Built-in Dart analyzer + flutter_lints

**Python** (si aplica): [pylint | flake8 | ruff]

### Formatting

**Formatter**: Prettier  
**Config**:
json
{
  "semi": true,
  "singleQuote": true,
  "trailingComma": "es5",
  "printWidth": 80
}


### Type Checking

**TypeScript**: strict mode habilitado

typescript
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true
  }
}


### Git Hooks

**Tool**: Husky + lint-staged

**Pre-commit**:
- Lint código modificado
- Formatear con Prettier
- Run type check

**Pre-push**:
- Run tests

---

## Versiones y Compatibilidad

### Browser Support

- Chrome: Últimas 2 versiones
- Firefox: Últimas 2 versiones
- Safari: Últimas 2 versiones
- Edge: Últimas 2 versiones
- IE11: ❌ No soportado

### Mobile Support

- **iOS**: 13.0+ (Flutter requirement)
- **Android**: API 21+ (Android 5.0 Lollipop)

### Versiones Mínimas

**Node.js**: 20.x LTS  
**Flutter**: 3.19+  
**Dart**: 3.3+

---

## Decisiones Técnicas

### Estructura de Repositorios - Recomendación

**Opción Recomendada**: **Backend + Admin juntos, Flutter separado** 

**Por qué**:

✅ **Ventajas**:
1. **Backend + Admin comparten**:
   - Types/Interfaces (DTOs compartidos)
   - Validaciones (Zod schemas reutilizables)
   - Constants y enums
   - Mismo deploy (Vercel monorepo support nativo)
   - CI/CD simplificado (un solo workflow para ambos)
   - Refactoring más fácil (cambios en API se reflejan inmediatamente en Admin)

2. **Flutter separado**:
   - Ciclo de release independiente (app stores tienen su timing propio)
   - Equipo mobile puede trabajar sin afectar backend/admin
   - Build process completamente diferente (no mixing concerns)
   - Versionado independiente (v1.2.0 app != v2.1.0 backend)
   - Menos ruido en el repositorio (Flutter tiene muchos archivos generados)

3. **Práctico para tu caso**:
   - Menos overhead que 3 repos separados
   - Más flexible que monorepo completo
   - Perfect para equipo pequeño/solo
   - Budget-friendly (Vercel monorepo en free tier)

**Estructura Propuesta**:

```
📦 sacdia-backend-admin/          (Repositorio 1)
├── apps/
│   ├── backend/                  # NestJS API
│   │   ├── src/
│   │   ├── prisma/
│   │   └── package.json
│   │
│   └── admin/                    # Next.js Admin Panel
│       ├── app/                  # App Router
│       ├── components/
│       └── package.json
│
├── packages/
│   ├── shared/                   # Types, DTOs, constants
│   │   ├── types/
│   │   ├── dtos/
│   │   └── constants/
│   │
│   └── ui/                       # Shared UI (si reutilizas)
│       └── components/
│
├── .github/
│   └── workflows/
│       └── deploy.yml            # CI/CD para ambos
│
├── package.json                  # pnpm workspace root
├── pnpm-workspace.yaml
├── turbo.json                    # Turborepo (opcional)
└── vercel.json                   # Monorepo deploy config

📦 sacdia-app/                    (Repositorio 2 - Flutter)
├── lib/
│   ├── core/
│   ├── features/
│   └── shared/
├── android/
├── ios/
├── test/
└── pubspec.yaml
```

**pnpm-workspace.yaml**:
```yaml
packages:
  - 'apps/*'
  - 'packages/*'
```

**Alternativa** (3 repos separados):
Solo si tienes equipos completamente separados o necesitas control de acceso muy granular por repo. Para tu caso, no es necesario.

---

### Por qué TypeScript

- **Type safety** reduce bugs en runtime (catch errors en compilación)
- **Mejor DX** con autocomplete e IntelliSense
- **Refactoring más seguro** (rename, move files con confianza)
- **Obligatorio para NestJS**, natural para Next.js
- **Clean Architecture en Flutter** beneficia de tipos Dart (misma filosofía)
- **Shared types** entre backend y frontend (menos duplicación)

---

### Por qué  Clean Architecture (Flutter)

- **Separación de responsabilidades** clara (data/domain/presentation)
- **Testeable**: domain layer es Dart puro (no depende de Flutter)
- **Escalable**: nuevas features no rompen existentes
- **Mantenible**: cambiar API o DB no afecta UI
- **Estándar de industria** para apps complejas con longevidad
- **Modo offline** más fácil (repository abstraction)

---

### Por qué Supabase

✅ **Pros**:
- **PostgreSQL real** (no NoSQL limitado como Firebase)
- **Auth built-in** (menos código custom, mantiene estándares)
- **Storage incluido** (S3-compatible)
- **Real-time subscriptions** (WebSocket management handled)
- **Free tier generosa** para hobby (~500MB DB, 1GB storage, 2GB bandwidth)
- **BaaS pero con SQL completo** (queries complejas, joins, triggers)
- **Supabase CLI** para development local

⚠️ **Trade-offs**:
- Vendor lock-in moderado (pero PostgreSQL standard)
- Menos control que DB self-hosted

---

### Por qué Vercel Serverless para Backend

✅ **Pros para tu caso (< $20/mes)**:
- **Hobby tier gratis** (100GB bandwidth, funciones ilimitadas)
- **Auto-scaling** sin configuración
- **Deploy automático** con GitHub (push to deploy)
- **Edge functions** para mejor performance global
- **Mismo provider** que Admin (simplifica billing y config)
- **Monorepo support** nativo (backend + admin en un proyecto)

⚠️ **Limitaciones**:
- **Max 10s execution time** (suficiente para APIs REST, pero no para jobs largos)
- **Cold starts** (~500ms primera request, luego

 rápido)
- **No WebSockets persistentes** (usar Supabase Realtime en su lugar)
- Si creces mucho, evaluar Railway/Render (pay-as-you-go)

**Para tu MVP**: Perfecto. Si creces, migrar es sencillo (NestJS es portable).

---

### Por qué Riverpod sobre Bloc/Provider

- **Type-safe** con compile-time safety (Provider legacy no tiene)
- **No BuildContext** necesario (más limpio)
- **Auto-dispose** (mejor memory management)
- **Testeable** fácilmente (providers son top-level)
- **Code generation** support (elimina boilerplate)
- **Mejor DX** que Bloc (menos ceremony, más directo)

---

### Por qué pnpm sobre npm/yarn

- **30-50% más rápido** que npm
- **Ahorra espacio en disco** (hardlinks entre proyectos)
- **Monorepo support nativo** (workspaces)
- **Strict** por default (evita phantom dependencies)
- **Compatible** con npm packages (drop-in replacement)

---

### Por qué Resend para Emails

- **$0/mes para 3,000 emails** (vs SendGrid $15/mes)
- **Developer-friendly** API (más simple que SendGrid)
- **React Email** integration (templates en React)
- **Delivery reputation** excelente
- **Logs y analytics** incluidos

Si creces → SendGrid o AWS SES.

---

### Por qué múltiples payment gateways

**Stripe**: Internacional, mejor DX, webhooks robustos  
**PayPal**: Usuarios sin tarjeta, confianza del brand  
**MercadoPago**: Latinoamérica (si es tu market)

**Implementación**: Abstract payment en backend (strategy pattern), frontend elige gateway.

---

---

## Restricciones Técnicas

### Performance

- Bundle size máximo: [X] MB
- Time to Interactive: < [Y] segundos
- Core Web Vitals: Cumplir umbrales "Good"

### Seguridad

- TLS 1.3+ obligatorio
- Todas las dependencias sin vulnerabilidades críticas/altas
- Secrets nunca en código (usar secrets manager)

### Compliance

- [GDPR | HIPAA | SOC 2 | Ninguno específico]

---

## Migration Path

Si estamos migrando de stack anterior:

**Stack Anterior**: [Descripción]  
**Stack Nuevo**: [Descripción]  
**Razones del Cambio**: [Lista]  
**Timeline**: [Fecha estimada de completion]

**Pasos**:
1. [Paso 1]
2. [Paso 2]
3. [Paso 3]

---

## Notas para IA

**Al sugerir implementaciones**:

### 1. SIEMPRE usa las tecnologías especificadas

**Backend**:
- ✅ NestJS con TypeScript
- ✅ Prisma para queries (no raw SQL directo)
- ✅ class-validator + class-transformer para DTOs
- ✅ @nestjs/swagger para documentación
- ❌ NO Express directo, NO TypeORM, NO Sequelize

**Admin Panel**:
- ✅ Next.js 14+ App Router (no Pages Router)
- ✅ shadcn/ui components (no Material-UI, no Chakra)
- ✅ TailwindCSS (no CSS-in-JS)
- ✅ React Hook Form + Zod (no Formik, no Yup)
- ✅ TanStack Query para data fetching
- ❌ NO create-react-app, NO Vite standalone

**Flutter**:
- ✅ Clean Architecture (data/domain/presentation)
- ✅ Riverpod 2.x (no Bloc, no Provider legacy)
- ✅ Dio para HTTP (no http package)
- ✅ freezed + json_serializable para models
- ✅ go_router para navegación
- ❌ NO GetX, NO Bloc pattern

### 2. Autenticación Flow

**SIEMPRE sigue este flujo**:
```
1. User login → Supabase Auth API
2. Get JWT token from Supabase
3. Flutter: Store en flutter_secure_storage
4. Flutter: Dio interceptor inyecta token en headers
5. Backend NestJS: Valida JWT (Supabase public key)
6. Backend: No crear custom auth, usar Supabase tokens
```

❌ **NO implementes**:
- Custom JWT generation en backend
- Session-based auth
- Cookies para auth (usar headers)

### 3. Database Queries

**✅ Bien (Prisma)**:
```typescript
const users = await this.prisma.user.findMany({
  where: { email: { contains: query } },
  include: { orders: true }
});
```

**❌ Mal (raw SQL)**:
```typescript
const users = await this.prisma.$queryRaw`
  SELECT * FROM users WHERE email LIKE '%${query}%'
`;
```

### 4. Flutter Clean Architecture

**SIEMPRE estructura features así**:
```
lib/features/[feature_name]/
├── data/
│   ├── datasources/
│   │   ├── [feature]_remote_datasource.dart
│   │   └── [feature]_local_datasource.dart
│   ├── models/
│   │   └── [model]_model.dart          # freezed + json_serializable
│   └── repositories/
│       └── [feature]_repository_impl.dart
│
├── domain/
│   ├── entities/
│   │   └── [entity].dart               # Plain Dart class
│   ├── repositories/
│   │   └── [feature]_repository.dart   # Abstract interface
│   └── usecases/
│       └── [action]_usecase.dart       # One action per class
│
└── presentation/
    ├── pages/
    ├── widgets/
    ├── providers/                      # Riverpod providers
    └── state/                          # StateNotifiers
```

### 5. API Responses

**✅ Formato estándar**:
```typescript
// Success
{
  "success": true,
  "data": { ... },
  "meta": { page: 1, total: 100 }  // Si aplica
}

// Error
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid email format",
    "details": [...]  // Opcional
  }
}
```

### 6. Monorepo (Backend + Admin)

**Shared types** entre backend y admin:
```
packages/shared/src/
├── types/
│   ├── user.ts
│   └── order.ts
├── dtos/
│   └── create-user.dto.ts          # Zod schema compartido
└── constants/
    └── api-endpoints.ts
```

**Importar así**:
```typescript
// En backend o admin
import { UserDTO } from '@repo/shared/dtos';
import { API_ENDPOINTS } from '@repo/shared/constants';
```

### 7. Testing

**Backend (NestJS)**:
```typescript
describe('UserService', () => {
  let service: UserService;
  let prisma: PrismaService;
  
  beforeEach(async () => {
    const module = await Test.createTestingModule({
      providers: [UserService, PrismaService],
    }).compile();
    
    service = module.get<UserService>(UserService);
  });
  
  it('should create user', async () => {
    // Use Jest + mock Prisma
  });
});
```

**Flutter**:
```dart
// Test use case
test('should get user from repository', () async {
  // Arrange
  when(mockRepo.getUser(any))
    .thenAnswer((_) async => Right(tUser));
  
  // Act
  final result = await usecase(Params(id: '1'));
  
  // Assert
  expect(result, Right(tUser));
  verify(mockRepo.getUser('1'));
});
```

### 8. Versiones específicas

Al sugerir instalación de packages:

**pnpm (Backend/Admin)**:
```bash
pnpm add @nestjs/core@^10.0.0
pnpm add -D @types/node@^20.0.0
```

**Flutter**:
```yaml
dependencies:
  riverpod: ^2.4.0
  freezed_annotation: ^2.4.0
  
dev_dependencies:
  build_runner: ^2.4.0
  freezed: ^2.4.0
```

### 9. Errores Comunes a Evitar

❌ **NO hagas**:
1. No mezclar App Router y Pages Router en Next.js
2. No usar `any` en TypeScript (usar `unknown` si es necesario)
3. No poner lógica de negocio en presentation layer (Flutter)
4. No hardcodear URLs de API (usar env variables)
5. No commits de `.env` files
6. No raw SQL en Prisma (usar type-safe queries)  
7. No setState en Flutter (usar Riverpod)

### 10. Si necesitas agregar nueva tecnología

**ANTES de sugerirla**:
1. Verifica si hay algo similar ya en uso
2. Justifica por qué es necesaria
3. Verifica compatibilidad con stack actual
4. Menciona bundle size impact (si aplica)
5. **Pregunta al usuario antes de agregar**

**Ejemplo**:
```
Veo que necesitas [X]. Podríamos usar [librería Y] que:
- Es compatible con nuestro stack
- Bundle size: 15KB gzipped
- Alternativas consideradas: [A, B]
  
¿Procedo con [Y] o prefieres otra opción?
```

---

**Última actualización**: 2026-01-11  
**Revisado por**: Usuario - Stack completo definido
