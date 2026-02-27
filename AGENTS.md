# AGENTS.md

Guia operativa para agentes de IA en `sacdia`.
Objetivo: asegurar que cualquier implementacion use el contexto correcto antes de tocar codigo.

## 1) Lectura minima obligatoria (siempre)

1. `CLAUDE.md`
2. `README.md`
3. `docs/README.md`
4. `docs/00-STEERING/product.md`
5. `docs/00-STEERING/tech.md`
6. `docs/00-STEERING/structure.md`
7. `docs/00-STEERING/coding-standards.md`
8. `docs/00-STEERING/data-guidelines.md`
9. `docs/00-STEERING/agents.md` (reglas extendidas y checklist detallado)

## 2) Router de documentacion por tipo de cambio

### Backend y API (NestJS)

- Codigo: `sacdia-backend/`
- Contexto local: `sacdia-backend/CLAUDE.md`
- Referencia API runtime (canónica): `docs/02-API/ENDPOINTS-LIVE-REFERENCE.md`
- Endpoints por proceso: `docs/02-API/ENDPOINTS-REFERENCE.md`
- Seguridad: `docs/02-API/SECURITY-GUIDE.md`
- Testing: `docs/02-API/TESTING-GUIDE.md`

### Admin Web (Next.js)

- Codigo: `sacdia-admin/`
- Contexto local: `sacdia-admin/CLAUDE.md`
- Integracion con API: `docs/02-API/FRONTEND-INTEGRATION-GUIDE.md`
- Feature docs: `docs/01-FEATURES/<feature>/`

### App Movil (Flutter)

- Codigo: `sacdia-app/`
- Contexto local: `sacdia-app/CLAUDE.md`
- Integracion con API: `docs/02-API/FRONTEND-INTEGRATION-GUIDE.md`
- Feature docs: `docs/01-FEATURES/<feature>/`

### Base de datos (Supabase/PostgreSQL/Prisma)

- Contexto DB: `docs/03-DATABASE/README.md`
- Schema referencia: `docs/03-DATABASE/SCHEMA-REFERENCE.md`
- Prisma schema: `docs/03-DATABASE/schema.prisma`
- Migraciones SQL: `docs/03-DATABASE/migrations/`

### Roadmap, estado y arquitectura global

- Estado general: `docs/03-IMPLEMENTATION-ROADMAP.md`
- Arquitectura/API decisiones: `docs/02-API/ARCHITECTURE-DECISIONS.md`
- Servicios externos: `docs/EXTERNAL-SERVICES-AUDIT.md`
- Resumenes de fase: `docs/PHASE-1-COMPLETION-SUMMARY.md`

## 3) Router de features

Para cambios de negocio, ubicar primero el dominio en `docs/01-FEATURES/`:

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

- Cambio de endpoint/DTO/errores: actualizar `docs/02-API/`.
- Cambio de schema o relaciones: actualizar `docs/03-DATABASE/`.
- Cambio de flujo funcional: actualizar `docs/01-FEATURES/<feature>/`.
- Cambio transversal de arquitectura: actualizar `docs/00-STEERING/` o roadmap.

## 6) Checklist rapido antes de cerrar

- Se leyo la documentacion base y la del dominio afectado.
- La implementacion sigue los estandares del proyecto.
- Tests/lint/analyze relevantes ejecutados en el modulo afectado.
- Docs actualizadas para reflejar el estado final.

## 7) Nota sobre archivos CLAUDE con memoria

Algunos `CLAUDE.md` incluyen bloques `<claude-mem-context>` autogenerados.
No usar esos bloques como unica fuente de verdad para requisitos tecnicos.
La fuente de verdad funcional y tecnica debe ser `docs/00-STEERING/`, `docs/01-FEATURES/`, `docs/02-API/` y `docs/03-DATABASE/`.
