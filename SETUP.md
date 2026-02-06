# SACDIA - Sistema de Administración de Clubes JA

## Resumen

Sistema integral de gestión para clubes de Conquistadores, Aventureros y Guías Mayores desarrollado con arquitectura multi-repositorio.

## Contenido de CLAUDE.md

He creado una estructura de documentación CLAUDE.md siguiendo las mejores prácticas:

### 📁 `/CLAUDE.md` (Root - 70 líneas)

**Contenido universal** que aplica a todo el monorepo:

- Estructura general del proyecto (3 apps)
- Stack tecnológico compartido (TypeScript, Supabase, PostgreSQL)
- Comandos para clonar repositorios
- Estándares globales de código
- Información de autenticación compartida
- Referencias a documentación clave

### 📁 `/sacdia-backend/CLAUDE.md` (45 líneas)

**Detalles específicos del backend**:

- Comandos de desarrollo y testing
- Estructura de carpetas (17 módulos)
- Stack técnico (NestJS, Prisma, Supabase)
- Particularidades (RBAC, versioning, audit log)
- Variables de entorno necesarias
- Performance monitoring

### 📁 `/sacdia-admin/CLAUDE.md` (40 líneas)

**Detalles específicos del panel admin**:

- Comandos Next.js
- Estructura App Router
- Stack (Next.js 16, shadcn/ui, Tailwind v4)
- Particularidades (Server Components, SSR Supabase)
- Autenticación con ejemplos de código
- Deployment en Vercel

### 📁 `/sacdia-app/CLAUDE.md` (40 líneas)

**Detalles específicos de la app móvil**:

- Comandos Flutter
- Estructura Clean Architecture
- Stack (Flutter, Riverpod, Dio, Hive)
- Particularidades (offline-first, DI)
- Variables de entorno
- Deployment iOS/Android

## Principios Aplicados

✅ **Extrema concisión**: Total ~195 líneas (objetivo <300)
✅ **Sin duplicación**: Info en root solo si es universal
✅ **Lenguaje directo**: Sin fluff, solo lo esencial
✅ **Formato simple**: Markdown básico con ejemplos de código
✅ **Enfoque práctico**: Comandos, rutas, particularidades técnicas

## Qué Incluí vs Qué Omití

### ✅ Incluido en Root

- Mapa de estructura del monorepo
- Stack compartido (TypeScript, Supabase, Git)
- Comandos de clonación
- Estándares globales de código
- Info de autenticación compartida

### ❌ NO incluido en Root (va en subdirectorios)

- Comandos específicos de cada app
- Estructura interna de carpetas
- Detalles de implementación técnica
- Variables de entorno específicas

## Próximos Pasos

1. **Revisar** cada CLAUDE.md y ajustar según tu preferencia
2. **Eliminar SETUP.md** (ya no es necesario)
3. **Opcional**: Crear `.claude/rules/` para reglas adicionales:
   - `security.md` - Estándares de seguridad
   - `api-conventions.md` - Convenciones de API
4. **Opcional**: Crear `.claude/skills/` para workflows:
   - `deploy/SKILL.md` - Proceso de deployment

## Notas

- Total de líneas: ~195 (bien dentro del límite de 300)
- Cada CLAUDE.md es autocontenido pero referencia al root
- Formato conciso siguiendo disclosure progresivo
- Puedes agregar más detalles específicos según necesites
