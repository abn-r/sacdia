# Documentación SACDIA

**Sistema de Administración de Clubes del Ministerio Juvenil Adventista**

> [!IMPORTANT]
> Este directorio es la fuente de verdad documental del proyecto.
> La documentación histórica se encuentra en `docs/history/`.

---

## Punto de Entrada Único

1. Reglas globales: `docs/00-STEERING/`
2. Funcional por módulo: `docs/01-FEATURES/`
3. Contratos API: `docs/02-API/`
4. Datos y schema: `docs/03-DATABASE/`
5. Historial y bitácoras: `docs/history/`

---

## Rutas Canónicas por Rol

### Backend

1. `docs/00-STEERING/tech.md`
2. `docs/02-API/ENDPOINTS-LIVE-REFERENCE.md`
3. `docs/02-API/API-SPECIFICATION.md`
4. `docs/03-DATABASE/schema.prisma`

### Mobile

1. `docs/00-STEERING/tech.md`
2. `docs/PHASE-2-MOBILE-PROGRAM.md`
3. `docs/02-API/ENDPOINTS-LIVE-REFERENCE.md`
4. `docs/01-FEATURES/`

### Admin Web

1. `docs/00-STEERING/tech.md`
2. `docs/PHASE-3-ADMIN-PROGRAM.md`
3. `docs/02-API/ENDPOINTS-LIVE-REFERENCE.md`
4. `docs/01-FEATURES/`

---

## Capa Canónica

### 00-STEERING

- `product.md`
- `tech.md`
- `structure.md`
- `coding-standards.md`
- `data-guidelines.md`
- `agents.md`

### 01-FEATURES

Módulos de negocio activos (sin contenido de ejemplo).

### 02-API

- **Runtime**: `ENDPOINTS-LIVE-REFERENCE.md`
- **Especificación técnica**: `API-SPECIFICATION.md`
- **Mapeo funcional**: `ENDPOINTS-REFERENCE.md`
- **Seguridad**: `SECURITY-GUIDE.md`
- **Integración frontend**: `FRONTEND-INTEGRATION-GUIDE.md`
- **Testing**: `TESTING-GUIDE.md`

### 03-DATABASE

- `schema.prisma`
- `SCHEMA-REFERENCE.md`
- `migrations/README.md`

---

## Capa Histórica

Todo contenido de auditorías, planes cerrados, sesiones y fuentes intermedias vive en:

- `docs/history/`
- `docs/CHANGELOG-IMPLEMENTATION.md`

---

## Estado de Documento

- `ACTIVE`: canónico y operativo.
- `HISTORICAL`: contexto histórico, no contrato vigente.
- `DEPRECATED`: reemplazado por documento canónico.

---

## Ver También

- `docs/CLAUDE.md`
- `docs/history/README.md`

**Última actualización**: 2026-03-04

