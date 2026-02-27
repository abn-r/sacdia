# SACDIA - Sistema de Administración de Clubes JA

Monorepo con panel admin web, app móvil y backend API para gestionar clubes de Conquistadores, Aventureros y Guías Mayores.

## Estructura del Proyecto

```
/sacdia-backend     - API REST (NestJS + Prisma)
/sacdia-admin       - Panel Web (Next.js 16 + shadcn/ui)
/sacdia-app         - App Móvil (Flutter + Clean Architecture)
/docs               - Documentación técnica
/.specs             - Especificaciones del sistema
```

## Stack Tecnológico Compartido

- **Autenticación**: Supabase Auth (JWT + OAuth con Google y Apple)
- **Base de Datos**: PostgreSQL vía Supabase
- **Storage**: Supabase Storage para archivos
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

- **Provider**: Supabase Auth
- **Tokens**: JWT con refresh automático
- **OAuth**: Google y Apple configurados
- **Roles**: Sistema RBAC con roles globales + roles de club

## URLs de Desarrollo

- Backend: `http://localhost:3000`
- Admin: `http://localhost:3001`
- API Docs: `http://localhost:3000/api`
- Supabase: Configurar en `.env` de cada proyecto

## Documentación

- **Router para agentes IA**: `AGENTS.md`
- **Steering global**: `docs/00-STEERING/`
- **API (runtime canónica)**: `docs/02-API/ENDPOINTS-LIVE-REFERENCE.md`
- **Database**: `docs/03-DATABASE/SCHEMA-REFERENCE.md`
- **Roadmap**: `docs/03-IMPLEMENTATION-ROADMAP.md`

## CLAUDE.md Específicos

Cada aplicación tiene su propio CLAUDE.md con detalles específicos:

- `/sacdia-backend/CLAUDE.md` - API, endpoints, tests
- `/sacdia-admin/CLAUDE.md` - Next.js, components, routes
- `/sacdia-app/CLAUDE.md` - Flutter, screens, providers
