# ESTRUCTURA SACDIA — Guía Operativa

**Estado**: ACTIVE
**Actualizado**: 2026-10-04 (verificado contra `development` de los tres repos runtime)

> Dónde vive cada cosa en el workspace. El stack y las versiones están en `docs/steering/tech.md`; la topología y las cifras, en `docs/canon/runtime-sacdia.md`.

---

## 1. Layout del workspace

```text
sacdia/                     # repo de documentación (este)
|- docs/                    # documentación global
|- scripts/                 # verificaciones documentales (CI en .github/workflows/)
|- assets/                  # recursos compartidos
|- sacdia-docs/             # portal de manuales (gitlink; pendiente de rediseño)
|- sacdia-backend/          # repo propio — API NestJS
|- sacdia-admin/            # repo propio — panel Next.js
`- sacdia-app/              # repo propio — app Flutter
```

Los tres repos runtime están en el `.gitignore` de `sacdia`: cada uno tiene su historial, su CI y su flujo `development` → `preproduction` → `main`.

---

## 2. Backend — `sacdia-backend`

```text
src/
|- main.ts                  # bootstrap: helmet, CORS, pipes, prefijo /api + versión v1, Swagger opt-in
|- app.module.ts            # módulos + guards globales (throttler, JWT, permisos)
|- <módulo>/                # un módulo Nest por dominio (≈60), por ejemplo:
|   |- <módulo>.module.ts
|   |- <módulo>.controller.ts
|   |- <módulo>.service.ts
|   |- *.spec.ts            # tests unitarios junto al código
|   `- dto/                 # DTOs con class-validator
|- rankings/                # agrupa submódulos (member-rankings, section-rankings, annual-ranking-progress, member-ranking-weights)
|- common/                  # guards, decorators, filters, interceptors, pipes, errors (AppException + ErrorCode), email, services compartidos
|- config/                  # validación de entorno (Joi), cache, BullMQ, throttler, trust proxy
|- prisma/                  # PrismaService
`- i18n/{es,en,fr,pt-BR}/   # mensajes de nestjs-i18n
prisma/
|- schema.prisma            # autoridad estructural de datos
|- migrations/              # Prisma Migrate
`- seeds/                   # seeds SQL (permisos, grants) y TS (usuarios de prueba, logros...)
test/                       # e2e (*.e2e-spec.ts)
scripts/                    # utilidades: auditorías, backfills, importadores, benchmarks
render.yaml                 # blueprint de Render
.env.example                # catálogo de variables de entorno
```

Lista de módulos por área: `docs/canon/runtime-sacdia.md` §5.2.

---

## 3. Admin — `sacdia-admin`

```text
src/
|- app/
|   |- (auth)/login/                    # login
|   |- (dashboard)/dashboard/<sección>/ # páginas del panel (clubs, users, catalogs, campamentos, investiture, ...)
|   `- api/auth/{token,refresh,me,logout}/  # rutas que gestionan cookies httpOnly
|- components/<dominio>/                # componentes por dominio; components/ui/ = shadcn
|- lib/
|   |- api/                             # cliente HTTP (client.ts) y un archivo por recurso
|   |- auth/                            # sesión, cookies, roles, permisos
|   |   `- screen-catalog/              # gates de pantallas y capacidades (admin y app)
|   `- <dominio>/                       # lógica y server actions por dominio
|- navigation/sidebar/                  # ítems del sidebar (ids = ids del screen catalog)
|- server/                              # utilidades de servidor y server actions compartidas
|- stores/preferences/                  # Zustand: tema, layout, sidebar
|- i18n/                                # configuración de next-intl
`- proxy.ts                             # protege /dashboard/*
messages/{es,en,fr,pt-BR}.json          # traducciones
```

---

## 4. App móvil — `sacdia-app`

Organización **feature-first**; cada feature aplica Clean Architecture internamente.

```text
lib/
|- main.dart
|- core/                    # transversal: auth, authorization (screen catalog Dart), config (router, route_names),
|                           # constants (api_endpoints, app_constants), network (Dio + interceptores), notifications,
|                           # realtime (invalidación FCM), storage, theme, l10n, widgets, utils, analytics
|- features/<feature>/      # ~40 features (activities, classes, honors, camporees, coordinator, virtual_card, ...)
|   |- data/               # datasources (remote/local), models, repositories (impl)
|   |- domain/             # entities, repositories (contratos con Either<Failure, T>), usecases
|   `- presentation/       # providers (Riverpod), views, widgets
|- shared/                  # modelos, datos y widgets compartidos entre features
`- providers/               # providers globales (Dio, storage, catálogos)
assets/translations/{es,en,fr,pt-BR}.json
test/                       # tests unitarios y de widgets; test/fixtures/screen-catalog.snapshot.json
integration_test/
```

---

## 5. Documentación — `sacdia/docs`

La tabla de carpetas y su nivel de autoridad está en `docs/README.md`. La precedencia, en `docs/canon/source-of-truth.md`.

---

## 6. Nombrado

### TypeScript (backend y admin)

- Variables y funciones: `camelCase`; clases, interfaces y tipos: `PascalCase`.
- Archivos: `kebab-case` con sufijo de rol en el backend (`*.controller.ts`, `*.service.ts`, `*.module.ts`, `*.dto.ts`, `*.spec.ts`).
- Códigos de error: `UPPER_SNAKE_CASE` en `common/errors/error-codes.ts`.

### SQL / Prisma

- Tablas y columnas: `snake_case`. Los modelos Prisma usan el mismo nombre que la tabla.
- PKs con nombre propio por tabla (`user_id`, `club_section_id`, `enrollment_id`, `user_pr_id`...). Las tablas de Better Auth (`account`, `session`, `verification`) usan `id`.
- FKs: `<entidad>_id`.
- Timestamps: `created_at` y, según la tabla, `modified_at` o `updated_at`.
- Baja lógica: columna `active`.
- Traducciones de catálogos: tabla `<catálogo>_translations`.

### Permisos

- `recurso:acción` en `snake_case` (`annual_folders:evaluate`, `camporees:register_active_section`).

### Roles

- `kebab-case` (`super-admin`, `director-lf`, `deputy-director`, `secretary-treasurer`).

### Flutter / Dart

- Clases: `PascalCase`; variables y funciones: `camelCase`; archivos y carpetas: `snake_case`.
- Vistas: `*_view.dart`; providers: `*_providers.dart`; datasources: `*_remote_data_source.dart` / `*_local_data_source.dart`.

### Git

- Commits: Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`, `perf:`).
- Ramas de trabajo con prefijo de tipo (`feat/`, `fix/`, `perf/`...) creadas desde `development`.
- Ramas permanentes: `development`, `preproduction`, `main`.

---

## 7. Encontrar cosas rápidamente

| Busco | Dónde |
|---|---|
| Un endpoint | `docs/api/ENDPOINTS-LIVE-REFERENCE.md`; en código, `sacdia-backend/src/**/*.controller.ts` |
| Un modelo de datos | `sacdia-backend/prisma/schema.prisma` (autoridad); `docs/database/SCHEMA-REFERENCE.md` (lectura) |
| Un permiso o su reparto | `sacdia-backend/prisma/seeds/permissions.seed.sql` y `role-permissions.seed.sql` |
| La spec de un dominio | `docs/features/README.md` → `docs/features/<dominio>.md` |
| Una pantalla del admin | `sacdia-admin/src/app/(dashboard)/dashboard/<sección>/` y su gate en `src/lib/auth/screen-catalog/screens/` |
| Una pantalla de la app | `sacdia-app/lib/features/<feature>/presentation/views/`; rutas en `lib/core/config/route_names.dart` |
| Un estándar de código | `docs/steering/coding-standards.md` |
| Una decisión de arquitectura | `docs/canon/decisiones-clave.md`, `docs/api/ARCHITECTURE-DECISIONS.md` |

---

## 8. Comandos esenciales

```bash
# Backend
cd sacdia-backend
pnpm install
pnpm run start:dev          # http://localhost:3000/api/v1
pnpm prisma migrate dev     # crear/aplicar migración en local
pnpm test                   # unit tests (Jest)
pnpm run test:e2e

# Admin
cd sacdia-admin
pnpm install
pnpm dev                    # http://localhost:3001
pnpm test && pnpm typecheck && pnpm lint

# App
cd sacdia-app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1
flutter analyze && flutter test
```
