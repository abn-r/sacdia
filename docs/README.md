# Documentación SACDIA

**Sistema de Administración de Clubes del Ministerio Juvenil Adventista**

**Estado**: ACTIVE

> [!IMPORTANT]
> Este directorio es la fuente de verdad documental del proyecto.
> La documentación histórica se encuentra en `docs/history/`.
> La precedencia global es: `docs/canon/*` -> `docs/README.md` -> documentación operativa subordinada -> material histórico.

---

## Punto de Entrada Recomendado

1. Canon del sistema: `docs/canon/`
2. Reglas globales y baseline técnica: `docs/00-STEERING/`
3. Funcional por módulo: `docs/01-FEATURES/`
4. Contratos API y operación: `docs/02-API/`
5. Guías subordinadas: `docs/guides/`
6. Datos y schema: `docs/03-DATABASE/`
7. Historial y bitácoras: `docs/history/`

`README.md` en la raíz cumple solo función de onboarding corto. Documentos como `docs/03-IMPLEMENTATION-ROADMAP.md` y `docs/02-API/FRONTEND-INTEGRATION-GUIDE.md` deben leerse como apoyo subordinado al canon y a esta baseline.

---

## Rutas Canónicas por Rol

### Canon base

1. `docs/canon/dominio-sacdia.md`
2. `docs/canon/identidad-sacdia.md`
3. `docs/canon/gobernanza-canon.md`
4. `docs/canon/arquitectura-sacdia.md`
5. `docs/canon/runtime-sacdia.md`
6. `docs/canon/decisiones-clave.md`

### Backend

1. `docs/canon/dominio-sacdia.md`
2. `docs/canon/runtime-sacdia.md`
3. `docs/00-STEERING/tech.md`
4. `docs/02-API/ENDPOINTS-LIVE-REFERENCE.md`
5. `docs/02-API/API-SPECIFICATION.md`
6. `docs/03-DATABASE/schema.prisma`

### Mobile

1. `docs/canon/dominio-sacdia.md`
2. `docs/canon/runtime-sacdia.md`
3. `docs/00-STEERING/tech.md`
4. `docs/02-API/ENDPOINTS-LIVE-REFERENCE.md`
5. `docs/01-FEATURES/`

### Admin Web

1. `docs/canon/dominio-sacdia.md`
2. `docs/canon/runtime-sacdia.md`
3. `docs/00-STEERING/tech.md`
4. `docs/02-API/ENDPOINTS-LIVE-REFERENCE.md`
5. `docs/01-FEATURES/`

---

## Capa Canónica

### canon/

- `dominio-sacdia.md`
- `identidad-sacdia.md`
- `gobernanza-canon.md`
- `arquitectura-sacdia.md`
- `runtime-sacdia.md`
- `decisiones-clave.md`

`docs/canon/` es la capa de mayor autoridad documental del proyecto.

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

## Capa Operativa Subordinada

La documentación fuera de `docs/canon/` puede seguir siendo activa para operación, integración o referencia técnica, pero no redefine el canon.

- `docs/00-STEERING/`
- `docs/01-FEATURES/`
- `docs/02-API/`
- `docs/guides/`
- `docs/03-DATABASE/`

## Capa Histórica

Todo contenido de auditorías, planes cerrados, sesiones y fuentes intermedias vive en:

- `docs/history/`
- `docs/CHANGELOG-IMPLEMENTATION.md`

---

## Estado de Documento

- `ACTIVE`: documento vigente.
- `DRAFT`: documento en construcción.
- `HISTORICAL`: contexto histórico, no contrato vigente.
- `DEPRECATED`: reemplazado por documento canónico.

## Convención Editorial para Pendientes y Aspiracional

- No crear estados nuevos para "pending", "future" o "planned".
- Si un documento sigue siendo canónico, mantener `ACTIVE` y etiquetar el texto puntual como `Pendiente`, `Planificado`, `Recomendado` o `Por verificar`.
- Si el valor principal del documento es una foto de una etapa previa, marcarlo `HISTORICAL` y enlazar el reemplazo activo.
- Si un documento fue sustituido, marcarlo `DEPRECATED` y apuntar al documento vigente.

---

## Ver También

- `docs/CLAUDE.md`
- `docs/canon/README.md`
- `docs/history/README.md`

**Última actualización**: 2026-03-12
