# SACDIA - Sistema de Administración de Clubes JA

Workspace multi-repo con panel admin web, app móvil y backend API para gestionar clubes de Conquistadores, Aventureros y Guías Mayores.

## Estructura del Proyecto

Cada carpeta runtime es un repositorio Git independiente (ignorado en el `.gitignore` de este repo).

```
/sacdia-backend     - API REST (NestJS + Prisma)
/sacdia-admin       - Panel Web (Next.js 16 + shadcn/ui)
/sacdia-app         - App Móvil (Flutter, feature-first + Riverpod)
/sacdia-docs        - Portal de manuales (gitlink; pendiente de rediseño)
/docs               - Documentación técnica
/scripts            - Verificaciones documentales (CI)
```

## Stack Tecnológico Compartido

- **Autenticación**: Better Auth (self-hosted en NestJS, HS256 JWT + OAuth con Google y Apple)
- **Base de Datos**: PostgreSQL vía Neon
- **Cache y colas**: Redis + BullMQ (Redis obligatorio en producción)
- **Storage**: Cloudflare R2 para archivos
- **Hosting**: backend en Render (`sacdia-backend/render.yaml`), admin en Vercel
- **TypeScript**: Backend y panel admin
- **Dart**: App móvil (Flutter)
- **Toolchain**: Node 24 (`engines` del backend: `>=24 <25`; el CI del admin usa Node 22), pnpm 10, Flutter estable (el CI de la app usa 3.41.6)
- **Git**: Conventional Commits para todos los repos

## Flujo de ramas

Repos runtime: `development` → `preproduction` (QA) → `main`.

- Se trabaja en ramas creadas desde `development` y se integra con PR a `development`.
- `preproduction` es el entorno de QA; `main` es release. El producto todavía no está en producción.
- La documentación describe el código de `development`. El trabajo en ramas sin integrar se marca "Pendiente de merge (PR #N)".

## Comandos desde Raíz

```bash
# Clonar repositorios
git clone https://github.com/abn-r/sacdia-backend.git
git clone https://github.com/abn-r/sacdia-admin.git sacdia-admin
git clone https://github.com/abn-r/sacdia-app.git sacdia-app

# Ver CLAUDE.md en cada proyecto para comandos específicos
```

## Estándares de Código

- **Commits**: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`
- **Naming**: camelCase (TS/Dart), snake_case (SQL)
- **Async**: Usar async/await
- **Validación**: Validar todas las entradas de usuario
- **Error Handling**: Try-catch en operaciones asíncronas
- Detalle en `docs/steering/coding-standards.md` y `docs/steering/data-guidelines.md`

## Autenticación

- **Provider**: Better Auth (self-hosted, `src/better-auth/` en sacdia-backend)
- **Tokens**: HS256 JWT firmado con BETTER_AUTH_SECRET (Option C: BA autentica, SACDIA firma JWT)
- **OAuth**: Google y Apple configurados vía Better Auth
- **Roles**: Sistema RBAC con roles globales + roles de club
- **Clientes**: el admin guarda los tokens en cookies httpOnly; la app, en `flutter_secure_storage`

## URLs de Desarrollo

- Backend: `http://localhost:3000` (API en `/api/v1`)
- Admin: `http://localhost:3001`
- API Docs: `http://localhost:3000/api` (solo con `SWAGGER_ENABLED=true`)
- DB (Neon): Configurar DATABASE_URL en `.env` de sacdia-backend

## Documentación

- **Router para agentes IA**: `AGENTS.md`
- **Precedencia documental**: `docs/canon/source-of-truth.md`
- **Steering global**: `docs/steering/`
- **Runtime base**: `docs/canon/runtime-sacdia.md`
- **API (runtime canónica)**: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- **Database**: `sacdia-backend/prisma/schema.prisma` (autoridad) y `docs/database/SCHEMA-REFERENCE.md`
- **Feature Registry y estado por dominio**: `docs/features/README.md`
- **Decisiones pendientes**: `docs/audit/DECISIONS-PENDING.md`
- **Despliegue**: `docs/deployment/DEPLOYMENT-GUIDE.md`

## CLAUDE.md Específicos

Cada aplicación tiene su propio CLAUDE.md con detalles específicos:

- `/sacdia-backend/CLAUDE.md` - API, endpoints, tests
- `/sacdia-admin/CLAUDE.md` - Next.js, components, routes
- `/sacdia-app/CLAUDE.md` - Flutter, screens, providers
