# PR Draft — Auditoría estructurada de documentación y gobernanza

**Fecha**: 2026-03-14  
**Estado**: DRAFT  
**Objetivo**: concentrar en un solo documento la evaluación documental del workspace `sacdia/` para revisión con el líder del proyecto.  
**Regla rectora**: `docs/canon/` manda sobre cualquier otra capa documental. Si una fuente subordinada contradice `docs/canon/`, gana `docs/canon/`.

---

## 1. Resumen ejecutivo

La base documental del proyecto es fuerte en **gobernanza y precedencia**, pero todavía es irregular en **completitud, consistencia y mantenimiento operativo**.

Lo mejor resuelto hoy es:

- la jerarquía documental del canon;
- la separación entre contenido activo e histórico;
- la existencia de una referencia runtime para API y una fuente estructural para datos.

Los problemas principales hoy son:

- cobertura incompleta en `docs/01-FEATURES/` (ningún dominio tiene `requirements + design + tasks`);
- documentación subordinada con drift o lenguaje heredado;
- README/documentación de carpetas runtime que no reflejan el estado real del workspace;
- ruido estructural en carpetas auxiliares o históricas no suficientemente explicadas.

---

## 2. Regla de autoridad que debe usar el proyecto

### 2.1 Precedencia global aprobada

1. `docs/canon/*`
2. `docs/README.md`
3. documentación operativa subordinada:
   - `docs/00-STEERING/`
   - `docs/01-FEATURES/`
   - `docs/02-API/`
   - `docs/03-DATABASE/`
   - `docs/guides/`
4. material histórico:
   - `docs/history/`
   - roadmaps, changelogs, bitácoras o snapshots históricos

### 2.2 Regla práctica

- **No usar** `README.md` raíz, `CLAUDE.md`, `docs/history/*` o documentos históricos como fuente de verdad final.
- **No usar** `SCHEMA-REFERENCE.md` por encima de `docs/03-DATABASE/schema.prisma`.
- **No usar** `ENDPOINTS-REFERENCE.md` o walkthroughs viejos por encima de `docs/02-API/ENDPOINTS-LIVE-REFERENCE.md`.
- Si falta una pieza en `docs/canon/`, la capa subordinada puede complementar, pero **no redefinir**.

---

## 3. Mapa actual del workspace revisado

```text
sacdia/
|- docs/                 # sistema documental principal
|- sacdia-backend/       # backend NestJS + Prisma
|- sacdia-admin/         # panel admin Next.js
|- sacdia-app/           # app móvil Flutter
|- desing-admin-portal/  # mockups/prototipo de diseño (nombre con typo)
|- postman/              # colecciones Postman/Insomnia
|- scripts/              # validaciones y utilidades del workspace
|- .github/workflows/    # CI documental/paridad
|- AGENTS.md             # router operativo para agentes
|- CLAUDE.md             # onboarding corto del workspace
```

### 3.1 Lectura del mapa

- La estructura macro del repo es clara.
- `docs/` ya funciona como centro documental.
- Hay carpetas auxiliares con valor real (`postman/`, `scripts/`, `.github/workflows/`) que deberían estar mejor conectadas al sistema documental.
- `desing-admin-portal/` requiere decisión explícita: documentar, renombrar o archivar.

---

## 4. Estado por capa documental

### 4.1 Canon — fuerte

La capa `docs/canon/` está bien posicionada como autoridad.

Archivos clave presentes:

- `source-of-truth.md`
- `gobernanza-canon.md`
- `dominio-sacdia.md`
- `identidad-sacdia.md`
- `arquitectura-sacdia.md`
- `runtime-sacdia.md`
- `decisiones-clave.md`
- `auth/modelo-autorizacion.md`
- `auth/runtime-auth.md`

**Valor**:

- la precedencia está explícita;
- el canon define cómo resolver contradicciones;
- el proyecto ya separa verdad vigente vs. histórico;
- auth ya tiene subcanon específico.

### 4.2 Steering / baseline — útil, pero desigual

`docs/00-STEERING/` conserva piezas útiles, pero no todas están al mismo nivel de vigencia.

- `tech.md`: útil y activo.
- `coding-standards.md`, `data-guidelines.md`, `agents.md`: útiles como baseline subordinada.
- `product.md`: ya está `DEPRECATED`.
- `structure.md`: está `HISTORICAL` y además conserva estructura genérica/plantilla, no una guía viva del repo actual.

### 4.3 Features — cobertura incompleta

Resultado actual por dominios revisados:

| Dominio | requirements | design | tasks | walkthroughs | Lectura |
|---|---:|---:|---:|---:|---|
| actividades | ✗ | ✓ | ✗ | 2 | parcial |
| auth | ✗ | ✗ | ✗ | 6 | fragmentado |
| catalogos | ✗ | ✓ | ✗ | 1 | parcial |
| certificaciones-guias-mayores | ✓ | ✗ | ✗ | 1 | parcial |
| clases-progresivas | ✗ | ✓ | ✗ | 0 | parcial |
| communications | ✗ | ✗ | ✗ | 1 | mínimo |
| finanzas | ✗ | ✓ | ✗ | 1 | parcial |
| gestion-clubs | ✗ | ✓ | ✗ | 1 | parcial |
| gestion-seguros | ✓ | ✗ | ✗ | 0 | mínimo |
| honores | ✗ | ✓ | ✗ | 1 | parcial |
| infrastructure | ✗ | ✗ | ✗ | 4 | narrativo |
| inventario | ✗ | ✗ | ✗ | 1 | mínimo |
| validacion-investiduras | ✓ | ✗ | ✗ | 0 | mínimo |

**Hallazgo crítico**: no existe ni un solo dominio con set completo `requirements.md + design.md + tasks.md`.

### 4.4 API / Database — autoridad clara, pero con deuda de alineación

Piezas fuertes:

- `docs/02-API/ENDPOINTS-LIVE-REFERENCE.md` como contrato runtime.
- `docs/02-API/API-SPECIFICATION.md` como especificación técnica complementaria.
- `docs/03-DATABASE/schema.prisma` como fuente estructural de verdad.

Piezas con deuda:

- `docs/03-DATABASE/SCHEMA-REFERENCE.md` sigue siendo referencia humana, pero el propio canon la subordina a `schema.prisma`;
- `docs/03-DATABASE/README.md` no expone de forma suficientemente visible esa subordinación;
- parte de la documentación API y de procesos aún carga lenguaje o referencias heredadas.

---

## 5. Qué está bien

1. **Gobernanza documental clara**.  
   El proyecto ya definió quién manda y cómo arbitrar conflictos.

2. **Canon con intención correcta**.  
   El canon no intenta documentar todo, sino fijar verdad estructural.

3. **Separación histórica razonable**.  
   `docs/history/` ya absorbe gran parte del material viejo.

4. **Runtime API bien centralizado**.  
   `ENDPOINTS-LIVE-REFERENCE.md` da una base fuerte para backend/admin/app.

5. **Base de datos con fuente estructural inequívoca**.  
   `schema.prisma` es una decisión correcta como autoridad.

6. **El repo sí expresa el sistema real**.  
   El workspace muestra con claridad backend, admin, app, documentación y herramientas auxiliares.

---

## 6. Qué está mal o débil

### 6.1 Drift o desalineación documental

- `CLAUDE.md` raíz todavía menciona `/.specs`, pero esa carpeta no existe.
- `sacdia-app/README.md` sigue siendo prácticamente el README default de Flutter.
- `desing-admin-portal/README.md` describe un app de AI Studio/Gemini y no el propósito real de la carpeta.
- `sacdia-admin/README.md` tiene señales de desactualización:
  - menciona Supabase como backend directo;
  - enlaza repositorios con naming incorrecto (`sandia-app`);
  - no refleja la primacía de la documentación del repo padre.

### 6.2 Incompletitud sistemática por feature

- No hay `tasks.md` activos en dominios reales.
- Hay varios dominios con walkthroughs, pero sin requirements ni design.
- Auth tiene mucha documentación, pero dispersa entre canon, context y walkthroughs.

### 6.3 Taxonomía editorial inconsistente

Aunque la taxonomía oficial es `ACTIVE | DRAFT | HISTORICAL | DEPRECATED`, todavía aparecen estados como:

- `Producción`
- `✅ Completado`
- `Producción Ready`
- estados mixtos dentro del cuerpo del documento

Eso dificulta auditoría automática y lectura uniforme.

### 6.4 Estructura/folder docs no totalmente explicada

- `postman/` existe y tiene valor, pero su rol no aparece con suficiente peso en la documentación central.
- `scripts/` y `.github/workflows/` son importantes para salud documental, pero siguen siendo piezas técnicas poco visibles para un líder no técnico.
- `desing-admin-portal/` ni está bien nombrado ni está gobernado documentalmente.

---

## 7. Contradicciones o tensiones a vigilar

1. **Canon vs. walkthroughs legacy de auth**  
   `docs/canon/auth/*` debería ser la fuente rectora; los walkthroughs deberían quedar claramente subordinados o deprecados.

2. **`schema.prisma` vs. `SCHEMA-REFERENCE.md`**  
   Si no están sincronizados, el archivo humano genera riesgo operativo.

3. **`tech.md` / README de módulos vs. runtime real**  
   Algunos README por módulo no reflejan la arquitectura descrita en el canon y en el docs root.

4. **`structure.md` histórico vs. estructura real del repo**  
   Existe una guía de estructura, pero no sirve como fuente viva del monorepo actual.

---

## 8. Decisiones que el líder debería tomar

### Alta prioridad

1. **Ratificar formalmente que `docs/canon/` manda**  
   y exigir que cualquier documento subordinado enlace al canon si trata el mismo tema.

2. **Definir qué hacer con `desing-admin-portal/`**  
   opciones:
   - renombrar a `design-admin-portal/` y documentarlo;
   - moverlo a historia/archivo;
   - eliminarlo si ya no aporta.

3. **Elegir 3–5 dominios prioritarios para cierre documental completo**  
   con `requirements`, `design` y `tasks`.

4. **Ordenar limpieza de README por módulo**  
   al menos:
   - `/CLAUDE.md` raíz
   - `sacdia-admin/README.md`
   - `sacdia-app/README.md`
   - `desing-admin-portal/README.md`

### Media prioridad

5. **Unificar taxonomía de estado editorial**  
   para que solo existan `ACTIVE`, `DRAFT`, `HISTORICAL`, `DEPRECATED` como estado de documento.

6. **Alinear explícitamente la documentación de auth**  
   dejando `docs/canon/auth/` como fuente central y el resto como apoyo o histórico.

7. **Definir una política de “folder ownership documental”**  
   cada carpeta principal debería tener dueño, propósito y documento rector.

---

## 9. Mejoras recomendadas

### Ola 1 — limpieza estructural rápida

- quitar referencia a `/.specs` del `CLAUDE.md` raíz;
- corregir o reemplazar `sacdia-app/README.md`;
- corregir `sacdia-admin/README.md`;
- decidir destino de `desing-admin-portal/`;
- reforzar en `docs/README.md` el rol de `postman/`, `scripts/` y workflows;
- mantener `docs/02-PROCESSES.md` como histórico subordinado sin ambigüedad.

### Ola 2 — cierre de deuda documental operativa

- crear `tasks.md` para dominios prioritarios;
- completar features incompletas empezando por `auth`, `gestion-clubs`, `actividades`, `certificaciones-guias-mayores`;
- revisar `SCHEMA-REFERENCE.md` contra `schema.prisma`;
- revisar consistencia entre `API-SPECIFICATION.md` y `ENDPOINTS-LIVE-REFERENCE.md`.

### Ola 3 — institucionalización

- check automatizado de headers de estado;
- check automatizado de referencias a documentos `DEPRECATED` o `HISTORICAL`;
- matriz de ownership por carpeta/documento;
- revisión trimestral usando `docs/canon/completion-matrix.md`.

---

## 10. Propuesta de PR para revisión con el líder

### Título sugerido

`docs: audit documentation governance, folder structure, and canon precedence`

### Descripción sugerida

```md
## Summary

This PR delivers a structured audit of SACDIA documentation governance, repository folders, and source-of-truth rules.

## Canon rule

`docs/canon/` is the highest authority for the project. If subordinate docs conflict with canon, canon wins.

## Included in this review

- documentation authority model
- current workspace folder map
- strengths and gaps by documentation layer
- feature coverage review
- repo/documentation mismatches
- decisions required from project leadership
- prioritized improvement waves

## Key findings

- canon governance is strong
- feature documentation is incomplete across all domains
- several module READMEs are outdated or misleading
- there is structural/documentary noise around auxiliary folders
- state taxonomy is not consistently applied

## Expected outcome

Use this PR as an evaluation packet with project leadership to decide:

1. what stays as canonical,
2. what must be deprecated or archived,
3. which domains must be completed first,
4. what cleanup should be executed in the next documentation wave.
```

---

## 11. Criterios de aceptación de esta auditoría

- [ ] El líder valida la precedencia de `docs/canon/`.
- [ ] Se aprueba el tratamiento de carpetas auxiliares y ambiguas.
- [ ] Se priorizan dominios para completar `requirements/design/tasks`.
- [ ] Se aprueba una ola de limpieza de README/documentos desalineados.
- [ ] Se define una siguiente wave documental con responsables.

---

## 12. Conclusión

SACDIA ya tiene una **arquitectura documental mejor pensada que la mayoría de los proyectos**, pero todavía no tiene una **operación documental homogénea**.  
La oportunidad no está en crear más papeles, sino en:

- consolidar autoridad;
- cerrar huecos de cobertura;
- eliminar documentos engañosos o desalineados;
- y hacer que la estructura del repo cuente la misma historia que el canon.
