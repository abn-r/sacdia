# AGENTS.md

Guia operativa para agentes de IA en `sacdia`.
Objetivo: asegurar que cualquier implementacion use el contexto correcto antes de tocar codigo.

## 1) Lectura minima obligatoria (siempre)

1. `CLAUDE.md`
2. `README.md`
3. `docs/README.md`
4. `docs/steering/tech.md`
5. `docs/steering/coding-standards.md`
6. `docs/steering/data-guidelines.md`
7. `docs/steering/agents.md` (reglas extendidas y checklist detallado)

## 2) Router de documentacion por tipo de cambio

### Backend y API (NestJS)

- Codigo: `sacdia-backend/`
- Contexto local: `sacdia-backend/CLAUDE.md`
- Referencia API runtime (canónica): `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- Seguridad: `docs/api/SECURITY-GUIDE.md`
- Testing: `docs/api/TESTING-GUIDE.md`

### Admin Web (Next.js)

- Codigo: `sacdia-admin/`
- Contexto local: `sacdia-admin/CLAUDE.md`
- Integracion con API: `docs/api/FRONTEND-INTEGRATION-GUIDE.md`
- Feature docs: `docs/features/`

### App Movil (Flutter)

- Codigo: `sacdia-app/`
- Contexto local: `sacdia-app/CLAUDE.md`
- Integracion con API: `docs/api/FRONTEND-INTEGRATION-GUIDE.md`
- Feature docs: `docs/features/`

### Base de datos (Supabase/PostgreSQL/Prisma)

- Contexto DB: `docs/database/README.md`
- Schema referencia: `docs/database/SCHEMA-REFERENCE.md`
- Prisma schema: `docs/database/schema.prisma`
- Migraciones SQL: `docs/database/migrations/`

### Roadmap, estado y arquitectura global

- Arquitectura/API decisiones: `docs/api/ARCHITECTURE-DECISIONS.md`
- Servicios externos: `docs/EXTERNAL-SERVICES-AUDIT.md`
- Resumenes de fase: `docs/PHASE-1-COMPLETION-SUMMARY.md`

## 3) Router de features

Para cambios de negocio, ubicar primero el dominio en `docs/features/`:

- `actividades`
- `auth`
- `catalogos`
- `certificaciones-guias-mayores`
- `clases-progresivas`
- `communications`
- `finanzas`
- `gestion-clubs`
- `gestion-seguros`
- `honores`
- `infrastructure`
- `inventario`
- `recursos`
- `validacion-investiduras`

Orden recomendado dentro de cada feature:

1. `CLAUDE.md` (si existe contexto operativo)
2. `requirements.md` (si existe)
3. `design.md` (si existe)
4. `walkthrough-*.md` (si existe)
5. `tasks.md` (si existe)

## 4) Reglas de implementacion

- No asumir contratos: validar en documentacion del dominio.
- Priorizar consistencia con patrones ya existentes.
- Implementar con pruebas y validaciones, no solo happy path.
- Si falta un requisito, detener implementacion y pedir definicion.

## 5) Regla de sincronizacion codigo-documentacion

Si se modifica codigo que cambie comportamiento, actualizar documentacion en el mismo trabajo:

- Cambio de endpoint/DTO/errores: actualizar `docs/api/`.
- Cambio de schema o relaciones: actualizar `docs/database/`.
- Cambio de flujo funcional: actualizar `docs/features/`.
- Cambio transversal de arquitectura: actualizar `docs/steering/`.

## 6) Checklist rapido antes de cerrar

- Se leyo la documentacion base y la del dominio afectado.
- La implementacion sigue los estandares del proyecto.
- Tests/lint/analyze relevantes ejecutados en el modulo afectado.
- Docs actualizadas para reflejar el estado final.

## 7) Nota sobre archivos CLAUDE con memoria

Algunos `CLAUDE.md` incluyen bloques `<claude-mem-context>` autogenerados.
No usar esos bloques como unica fuente de verdad para requisitos tecnicos.
La fuente de verdad funcional y tecnica debe ser `docs/steering/`, `docs/features/`, `docs/api/` y `docs/database/`.
