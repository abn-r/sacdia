# SACDIA - Sistema de Administración de Clubes JA

Monorepo con panel admin web, app móvil y backend API para gestionar clubes de Conquistadores, Aventureros y Guías Mayores.

## Estructura del Proyecto

```
/sacdia-backend     - API REST (NestJS + Prisma)
/sacdia-admin       - Panel Web (Next.js 16 + shadcn/ui)
/sacdia-app         - App Móvil (Flutter + Clean Architecture)
/docs               - Documentación técnica
```

## Stack Tecnológico Compartido

- **Autenticación**: Better Auth (self-hosted en NestJS, HS256 JWT + OAuth con Google y Apple)
- **Base de Datos**: PostgreSQL vía Neon
- **Storage**: Cloudflare R2 para archivos
- **TypeScript**: Backend y panel admin
- **Dart**: App móvil (Flutter)
- **Git**: Conventional Commits para todos los repos

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

## Autenticación

- **Provider**: Better Auth (self-hosted, `src/better-auth/` en sacdia-backend)
- **Tokens**: HS256 JWT firmado con BETTER_AUTH_SECRET (Option C: BA autentica, SACDIA firma JWT)
- **OAuth**: Google y Apple configurados vía Better Auth
- **Roles**: Sistema RBAC con roles globales + roles de club

## URLs de Desarrollo

- Backend: `http://localhost:3000`
- Admin: `http://localhost:3001`
- API Docs: `http://localhost:3000/api`
- DB (Neon): Configurar DATABASE_URL en `.env` de sacdia-backend

## Documentación

- **Router para agentes IA**: `AGENTS.md`
- **Steering global**: `docs/steering/`
- **API (runtime canónica)**: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- **Database**: `docs/database/SCHEMA-REFERENCE.md`
- **Reality Matrix**: `docs/audit/REALITY-MATRIX.md`
- **Feature Registry**: `docs/features/README.md`
- **Decisiones pendientes**: `docs/audit/DECISIONS-PENDING.md`

## CLAUDE.md Específicos

Cada aplicación tiene su propio CLAUDE.md con detalles específicos:

- `/sacdia-backend/CLAUDE.md` - API, endpoints, tests
- `/sacdia-admin/CLAUDE.md` - Next.js, components, routes
- `/sacdia-app/CLAUDE.md` - Flutter, screens, providers
