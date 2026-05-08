# Source of Truth - Canon Factory Wave 0

**Estado**: ACTIVE  
**Ámbito**: autoridad documental operativa para `Runtime` y `Matrix`  
**Vigencia**: Wave 0  
**Ruta mandataria de arranque**: este archivo es la primera lectura obligatoria cuando exista duda sobre precedencia documental.

> [!IMPORTANT]
> Este documento congela qué fuentes mandan, cuáles solo apoyan y cuáles **no** pueden usarse como estado actual.
> Si una fuente subordinada contradice una fuente superior, **no se sintetiza por intuición**: se escala el conflicto.
> Para `Runtime`, este archivo manda sobre cualquier duda de precedencia dentro de la documentación del proyecto.

---

## 1. Propósito operativo

Este archivo define la jerarquía documental vigente del proyecto SACDIA para Canon Factory Wave 0.

Su función es:

1. fijar el orden de consulta;
2. separar fuentes canónicas de fuentes auxiliares;
3. bloquear el uso de roadmaps, bitácoras o notas históricas como estado actual;
4. reducir ambigüedad operativa para `Matrix` y `Runtime`.

---

## 2. Regla general de precedencia

La precedencia documental congelada es:

1. `docs/canon/source-of-truth.md`
2. `docs/README.md`
3. `docs/canon/*` aplicable al tema consultado
4. documentación operativa subordinada explícitamente autorizada por este archivo
5. material auxiliar permitido
6. material histórico o explícitamente no autorizado

Si una fuente de nivel inferior contradice una de nivel superior, prevalece la superior y el punto conflictivo debe registrarse para arbitraje.

---

## 3. Autoridad congelada por dominio

### 3.1 Producto y alcance funcional

Fuentes canónicas:

1. `docs/canon/dominio-sacdia.md`
2. `docs/canon/identidad-sacdia.md`
3. `docs/canon/gobernanza-canon.md`

Fuentes subordinadas permitidas:

4. `docs/features/<dominio>.md`

Reglas:

- `docs/history/00-STEERING/product.md` **no manda** para estado actual: está marcado `DEPRECATED` y reemplazado por canon.
- Las rutas de lectura heredadas que todavía nombren `product.md` no elevan su autoridad por encima del canon.
- Los documentos de `docs/features/` pueden precisar reglas de dominio activas, pero no redefinen el canon base del sistema.

### 3.2 Baseline técnica global

Fuentes canónicas técnicas:

1. `docs/canon/arquitectura-sacdia.md`
2. `docs/canon/decisiones-clave.md`
3. `docs/steering/tech.md`
4. `docs/history/00-STEERING/structure.md`
5. `docs/steering/coding-standards.md`
6. `docs/steering/data-guidelines.md`
7. `docs/steering/agents.md`

Reglas:

- `tech.md` define la baseline tecnológica global activa.
- Para taxonomía documental manda `docs/README.md`; `structure.md` solo puede usarse para estructura técnica no documental.
- `coding-standards.md`, `data-guidelines.md` y `agents.md` son normativos para implementación, validación y operación de agentes.

### 3.3 API y runtime operativo

Fuentes canónicas de API/runtime:

1. `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
2. `docs/api/ARCHITECTURE-DECISIONS.md`

Fuentes subordinadas permitidas:

3. `docs/features/<dominio>.md` para reglas funcionales del dominio
4. `docs/history/02-API/ENDPOINTS-REFERENCE.md` **solo** como mapeo de procesos y apoyo narrativo

Reglas:

- `ENDPOINTS-LIVE-REFERENCE.md` es el contrato runtime vigente para App y Admin.
- `ARCHITECTURE-DECISIONS.md` manda para decisiones aprobadas y racionales estructurales, pero no reemplaza el contrato runtime si `ENDPOINTS-LIVE-REFERENCE.md` ya fija una superficie activa.
- `ENDPOINTS-REFERENCE.md` no puede usarse para afirmar estado runtime actual si difiere del Live Reference.
- `Runtime` no debe inspeccionar código fuente como autoridad primaria de API; debe usar el documento runtime generado, salvo arbitraje explícito posterior.

### 3.4 Datos, schema y modelo operativo

Fuentes canónicas de datos:

1. `sacdia-backend/prisma/schema.prisma`
2. `docs/database/README.md`
3. `docs/database/schema.prisma`
4. `docs/database/SCHEMA-REFERENCE.md`

Reglas:

- Mientras exista drift entre ambos schemas, `sacdia-backend/prisma/schema.prisma` es la fuente de verdad estructural efectiva del runtime.
- `docs/database/schema.prisma` queda tratado como espejo documental pendiente de resincronización, no como autoridad primaria mientras siga desalineado.
- `docs/database/README.md` debe declarar explícitamente este arbitraje para evitar síntesis por intuición.
- `docs/database/SCHEMA-REFERENCE.md` es referencia humana subordinada y no puede contradecir al schema efectivo del backend.
- Cuando un documento de datos difiera en naming, tipos, claves o relaciones, gana `sacdia-backend/prisma/schema.prisma` hasta que la capa documental sea resincronizada.

### 3.5 Gobernanza documental

Fuentes canónicas de gobernanza:

1. `docs/canon/source-of-truth.md`
2. `docs/README.md`
3. `docs/canon/gobernanza-canon.md`

Reglas:

- `README.md` raíz es onboarding corto, no baseline normativa completa.
- `CLAUDE.md` raíz orienta navegación del workspace, pero no redefine contratos ni estado actual.

---

## 4. Orden de consulta obligatorio

### 4.1 Si la pregunta es de producto o alcance

1. `docs/canon/source-of-truth.md`
2. `docs/README.md`
3. `docs/canon/dominio-sacdia.md`
4. `docs/canon/identidad-sacdia.md`
5. `docs/features/<dominio>.md`

### 4.2 Si la pregunta es de arquitectura o baseline técnica

1. `docs/canon/source-of-truth.md`
2. `docs/README.md`
3. `docs/canon/arquitectura-sacdia.md`
4. `docs/canon/decisiones-clave.md`
5. `docs/steering/tech.md`
6. `docs/history/00-STEERING/structure.md`
7. `docs/steering/coding-standards.md`
8. `docs/steering/data-guidelines.md`

### 4.3 Si la pregunta es de API o comportamiento runtime

1. `docs/canon/source-of-truth.md`
2. `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
3. `docs/api/ARCHITECTURE-DECISIONS.md`
4. `docs/features/<dominio>.md`
5. `docs/history/02-API/ENDPOINTS-REFERENCE.md` solo si no contradice al Live Reference

### 4.4 Si la pregunta es de datos o schema

1. `docs/canon/source-of-truth.md`
2. `sacdia-backend/prisma/schema.prisma`
3. `docs/database/README.md`
4. `docs/database/schema.prisma`
5. `docs/database/SCHEMA-REFERENCE.md`

### 4.5 Si la pregunta es de precedencia documental

1. `docs/canon/source-of-truth.md`
2. `docs/README.md`
3. `docs/canon/gobernanza-canon.md`

---

## 5. Fuentes auxiliares permitidas

Estas fuentes pueden usarse como contexto subordinado, orientación o navegación, pero no como autoridad final de estado actual:

- `AGENTS.md`
- `CLAUDE.md`
- `README.md`
- `docs/history/02-API/ENDPOINTS-REFERENCE.md`
- `docs/features/**` cuando precisan un dominio sin contradecir canon ni runtime
- `docs/EXTERNAL-SERVICES-AUDIT.md` **si existe**

Uso permitido:

- onboarding;
- ruteo hacia documentos correctos;
- contexto operativo;
- trazabilidad o explicación narrativa.

Uso no permitido:

- cerrar estado actual por sí solas;
- invalidar canon;
- reemplazar contratos runtime o schema.

---

## 6. Fuentes explícitamente no autorizadas para estado actual

Quedan explícitamente fuera como fuente de estado actual:

- `docs/history/phases/03-IMPLEMENTATION-ROADMAP.md`
- cualquier documento `HISTORICAL`
- `docs/history/`
- changelogs, bitácoras de sesión y resúmenes de fase cuando pretendan describir contrato vigente
- `docs/history/00-STEERING/product.md` para estado actual de producto
- bloques `<claude-mem-context>` en archivos `CLAUDE.md`
- código fuente como autoridad primaria ad hoc, salvo cuando su salida ya fue promovida a documento canónico explícito (por ejemplo `ENDPOINTS-LIVE-REFERENCE.md`)

Regla explícita:

> `docs/history/phases/03-IMPLEMENTATION-ROADMAP.md` **NO representa estado actual**.  
> Solo puede leerse como roadmap, bitácora de fases o snapshot histórico.

---

## 7. Regla de contradicciones

Si dos fuentes autorizadas chocan:

1. no sintetizar por intuición;
2. no “promediar” documentos;
3. mantener la jerarquía ya congelada;
4. registrar el conflicto para arbitraje;
5. aislar el punto conflictivo sin bloquear el resto de la autoridad general, salvo que el choque impida operar.

Si el conflicto bloquea el uso seguro de la documentación, debe marcarse `BLOCKER` y escalarse a arbitraje documental.

---

## 8. Mandato operativo para Runtime y Matrix

`Runtime` y `Matrix` deben operar con estas reglas:

1. iniciar cualquier decisión de precedencia en este archivo;
2. usar `ENDPOINTS-LIVE-REFERENCE.md` para afirmar comportamiento API vigente;
3. usar `sacdia-backend/prisma/schema.prisma` para afirmar estructura de datos vigente mientras persista el drift documental;
4. tratar `ENDPOINTS-REFERENCE.md` y roadmap como apoyo narrativo, no como contrato actual;
5. escalar contradicciones reales en vez de resolverlas por intuición.

---

## 9. Freeze de Wave 0

La congelación de Wave 0 queda así:

- canon y gobernanza documental: `docs/canon/*` + `docs/README.md`
- runtime API: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- decisiones aprobadas: `docs/api/ARCHITECTURE-DECISIONS.md`
- baseline técnica global: `docs/steering/*` activos
- datos: `sacdia-backend/prisma/schema.prisma` como autoridad efectiva; `docs/database/schema.prisma` como espejo a resincronizar
- histórico y roadmap: prohibidos como estado actual

Mientras este archivo no sea reemplazado explícitamente por otro documento canónico, esta jerarquía permanece vigente.
