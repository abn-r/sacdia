# Auditoria Documental SACDIA -- 2026-03-14

## Resumen Ejecutivo

La documentacion de SACDIA tiene una base solida: el canon esta bien pensado, la jerarquia de autoridad esta definida con claridad en `source-of-truth.md`, y la separacion entre contenido historico y operacional es ejemplar. Sin embargo, la ejecucion tiene brechas importantes. El score global es **6.1/10** -- un proyecto que sabe _como_ deberia documentarse pero que todavia no llego a completar el ciclo para ninguna feature.

Los puntos fuertes son la capa canon (80% completa), la navegacion entre documentos (AGENTS.md + docs/README), y el archivo historico bien organizado. Los puntos debiles son la falta total de documentos de tareas (`tasks.md`) para cualquier feature, la duplicacion de contratos de autenticacion en 4+ ubicaciones sin cadena de deprecacion clara, y el drift entre fuentes que el propio canon declara como autoritativas (schema.prisma vs SCHEMA-REFERENCE.md).

El riesgo principal no es la cantidad de documentacion -- hay bastante -- sino la **confianza**: un agente o desarrollador que consulta la documentacion no puede saber con certeza si lo que lee refleja el estado actual del sistema sin verificar contra codigo. Este informe detalla los hallazgos y propone un plan de accion priorizado.

---

## 1. Estructura del Proyecto

```
sacdia/                              # Monorepo raiz
|-- sacdia-backend/                  # API REST (NestJS + Prisma) [REPO SEPARADO]
|-- sacdia-admin/                    # Panel Web (Next.js 16 + shadcn/ui) [REPO SEPARADO]
|-- sacdia-app/                      # App Movil (Flutter) [REPO SEPARADO]
|-- desing-admin-portal/             # Mockups de diseno (Vite+React+TS) [NO DOCUMENTADO, TYPO]
|-- postman/                         # Colecciones Postman [NO DOCUMENTADO]
|-- scripts/                         # Utilidades CI (SDD parity, API consistency) [ACTIVE]
|-- .atl/                            # Skill registry para agentes [ACTIVE]
|-- .github/workflows/               # CI: docs-api-consistency, sdd-command-parity [ACTIVE]
|-- AGENTS.md                        # Router para agentes IA [ACTIVE]
|-- CLAUDE.md                        # Instrucciones proyecto [ACTIVE]
|-- docs/
|   |-- README.md                    # Indice y navegacion [ACTIVE]
|   |-- canon/                       # Capa canonica [ACTIVE]
|   |   |-- README.md                # Principios y reglas de creacion
|   |   |-- source-of-truth.md       # Jerarquia de autoridad
|   |   |-- completion-matrix.md     # Tracking de cobertura
|   |   |-- gobernanza-canon.md      # Gobernanza, resolucion de conflictos
|   |   |-- dominio-sacdia.md        # Lenguaje canonico, invariantes
|   |   |-- identidad-sacdia.md      # Proposito, alcance del sistema
|   |   |-- arquitectura-sacdia.md   # Organizacion tecnica
|   |   |-- runtime-sacdia.md        # Estado runtime documentado [DRAFT]
|   |   |-- decisiones-clave.md      # Decisiones clave (9 vigentes)
|   |   |-- auth/
|   |   |   |-- modelo-autorizacion.md   # Modelo RBAC contextual
|   |   |   |-- runtime-auth.md          # Endpoints, tokens, sesiones
|   |-- context/                     # Contexto de dominio
|   |-- guides/                      # Guias operacionales
|   |-- plans/                       # Planes de implementacion
|   |-- 00-STEERING/                 # Directrices del proyecto
|   |-- 01-FEATURES/                 # Features por dominio (parcial)
|   |-- 02-API/                      # Especificacion API [ACTIVE]
|   |-- 02-PROCESSES.md              # Procesos [DEPRECATED - mover a history]
|   |-- 03-DATABASE/                 # Schema y migraciones [ACTIVE]
|   |-- PHASE-2-MOBILE-PROGRAM.md    # Programa movil [HISTORICAL]
|   |-- PHASE-3-ADMIN-PROGRAM.md     # Programa admin [HISTORICAL]
```

> **Nota:** Los sub-proyectos (`sacdia-backend`, `sacdia-admin`, `sacdia-app`) son repositorios Git independientes, NO submodulos. Cada uno tiene su propio `CLAUDE.md` con instrucciones especificas.

---

## 2. Jerarquia de Autoridad (Canon)

`source-of-truth.md` define un sistema de precedencia claro con tres niveles de consulta segun el tipo de pregunta.

### Orden de consulta por tipo de pregunta

| Tipo de pregunta | Cadena de consulta |
|---|---|
| Producto / Alcance | source-of-truth -> docs/README -> dominio -> identidad -> 01-FEATURES |
| Arquitectura | source-of-truth -> docs/README -> arquitectura -> decisiones-clave -> 00-STEERING |
| API / Runtime | source-of-truth -> ENDPOINTS-LIVE-REFERENCE -> ARCHITECTURE-DECISIONS -> 01-FEATURES |
| Datos / Schema | source-of-truth -> schema.prisma -> 03-DATABASE/README -> SCHEMA-REFERENCE |
| Precedencia | source-of-truth -> docs/README -> gobernanza-canon |

### Precedencia interna del canon

| Prioridad | Archivo | Funcion |
|:-:|---|---|
| 1 | gobernanza-canon.md | Meta-reglas, resolucion de conflictos |
| 2 | dominio-sacdia.md | Lenguaje y semantica canonica |
| 3 | identidad-sacdia.md | Proposito y alcance del sistema |
| 4 | arquitectura-sacdia.md | Organizacion tecnica, tensiones de diseno |
| 5 | runtime-sacdia.md | Verdad operacional documentada |
| 6 | decisiones-clave.md | Memoria y justificacion de decisiones |

### 2.1 Archivos Canonicos

| Archivo | Proposito | Estado | Nivel de autoridad |
|---|---|---|---|
| canon/README.md | Principios canon, reglas de creacion | ACTIVE | Meta |
| canon/source-of-truth.md | Jerarquia por dominio | ACTIVE | Meta |
| canon/completion-matrix.md | Tracking de cobertura | ACTIVE | Operacional |
| canon/gobernanza-canon.md | Gobernanza, conflictos | ACTIVE | Prioridad 1 |
| canon/dominio-sacdia.md | Lenguaje canonico, invariantes | ACTIVE | Prioridad 2 |
| canon/identidad-sacdia.md | Proposito, alcance | ACTIVE | Prioridad 3 |
| canon/arquitectura-sacdia.md | Org tecnica, tensiones de diseno | ACTIVE | Prioridad 4 |
| canon/runtime-sacdia.md | Estado runtime documentado | **DRAFT** | Prioridad 5 |
| canon/decisiones-clave.md | Decisiones clave (9 vigentes) | ACTIVE | Prioridad 6 |
| canon/auth/modelo-autorizacion.md | Modelo RBAC contextual | ACTIVE | Dominio auth |
| canon/auth/runtime-auth.md | Endpoints, tokens, sesiones auth | ACTIVE | Dominio auth |

### 2.2 Fuentes Externas Autorizadas por Canon

**Tier 1 -- Misma autoridad que canon:**

| Fuente | Rol |
|---|---|
| docs/README.md | Indice maestro y navegacion |
| docs/02-API/ENDPOINTS-LIVE-REFERENCE.md | Referencia API canonica |
| docs/03-DATABASE/schema.prisma | Fuente de verdad del schema |

**Tier 2 -- Subordinada pero normativa:**

| Fuente | Rol |
|---|---|
| docs/00-STEERING/tech.md | Directrices tecnicas |
| docs/00-STEERING/coding-standards.md | Estandares de codigo |
| docs/00-STEERING/data-guidelines.md | Lineamientos de datos |
| docs/00-STEERING/agents.md | Directrices para agentes IA |
| docs/02-API/ARCHITECTURE-DECISIONS.md | Decisiones arquitectonicas API |

**Explicitamente NO autoritativas:**

- `docs/03-IMPLEMENTATION-ROADMAP.md` -- roadmap aspiracional
- `docs/history/*` -- archivo historico
- `docs/00-STEERING/product.md` -- DEPRECATED
- `docs/00-STEERING/structure.md` -- HISTORICAL

---

## 3. Cobertura por Capa

### 3.1 Capa Canon (80% completa)

**Cubierto:**
- Jerarquia de autoridad completa y bien definida
- Modelo de dominio con lenguaje canonico e invariantes
- Identidad del sistema (proposito, alcance, no-alcance)
- Arquitectura tecnica con tensiones documentadas
- 9 decisiones clave vigentes con justificacion
- Modelo de autorizacion RBAC contextual completo
- Runtime de autenticacion (endpoints, tokens, sesiones)
- Gobernanza y reglas de resolucion de conflictos

**Faltante:**
- `runtime-sacdia.md` todavia en DRAFT -- es la 5ta autoridad canonica pero no esta validado contra codigo
- No hay glosario canonico centralizado (los terminos estan dispersos en dominio-sacdia.md)
- Sin proceso canonico documentado para flujos criticos (login -> GET /auth/me -> cambio de contexto)

### 3.2 Capa Operacional (60% completa)

**Cubierto:**
- API: ENDPOINTS-LIVE-REFERENCE.md completo y canonico
- API: ARCHITECTURE-DECISIONS.md con decisiones tecnicas
- Database: schema.prisma como fuente de verdad
- Steering: tech.md, coding-standards.md, data-guidelines.md

**Parcial:**
- Features: 13 features identificados pero NINGUNO tiene documentacion completa
- SCHEMA-REFERENCE.md existe pero tiene drift respecto a schema.prisma
- Procesos: 02-PROCESSES.md existe pero esta desactualizado

**Faltante:**
- Ningun feature tiene `tasks.md` (0 de 13)
- No hay runbook operacional
- No hay guia de troubleshooting
- No hay documentacion de deployment

### 3.3 Capa Historica (95% completa)

La separacion historica esta muy bien lograda. Los documentos deprecated y historicos estan correctamente categorizados con la excepcion de:
- `PHASE-2-MOBILE-PROGRAM.md` y `PHASE-3-ADMIN-PROGRAM.md` estan en la raiz de `docs/` en vez de `docs/history/`
- `02-PROCESSES.md` deberia migrar a history

---

## 4. Hallazgos Criticos

### 4.1 Problemas de Autoridad

| ID | Problema | Impacto |
|:-:|---|---|
| A1 | `runtime-sacdia.md` marcado como DRAFT pero es la 5ta autoridad canonica | Un agente que consulte la cadena de autoridad va a leer un documento no validado como si fuera verdad |
| A2 | Documentacion de auth distribuida en 4+ ubicaciones: canon/auth/, 01-FEATURES/auth/, context/dominio-auth.md, y walkthroughs dispersos | No hay cadena de deprecacion clara; riesgo de contradiccion |
| A3 | Documentos deprecated todavia referenciados en navegacion sin warnings explicitos | Consultas pueden terminar en fuentes desactualizadas |

### 4.2 Gaps de Cobertura

| ID | Gap | Severidad |
|:-:|---|---|
| G1 | NINGUN feature tiene documentacion completa (requirements + design + tasks) | Alta |
| G2 | SCHEMA-REFERENCE.md tiene drift respecto a schema.prisma (fuente de verdad) | Alta |
| G3 | No existe runbook operacional ni guia de deployment | Media |
| G4 | No existe glosario maestro canonico | Media |
| G5 | Cero archivos `tasks.md` en todo el proyecto | Alta |

### 4.3 Redundancia y Duplicacion

| ID | Redundancia | Ubicaciones |
|:-:|---|---|
| R1 | Contratos de autenticacion | canon/auth/runtime-auth.md, canon/auth/modelo-autorizacion.md, 01-FEATURES/auth/walkthroughs, context/dominio-auth.md |
| R2 | API-REFERENCE.md vs ENDPOINTS-LIVE-REFERENCE.md | Posible alias/redundancia; la segunda es canonica |
| R3 | Multiples archivos CLAUDE.md de navegacion | 6+ archivos sin consolidacion clara de instrucciones |

### 4.4 Inconsistencias de Estado

| ID | Inconsistencia | Detalle |
|:-:|---|---|
| E1 | Documentos sin label de estado explicito | Varios archivos en 01-FEATURES y 02-API no tienen header con estado |
| E2 | Contenido aspiracional mezclado con estado actual | Algunos docs canonicos describen funcionalidad futura como si existiera |
| E3 | Campos legacy marcados como "transicionales" | Sin fecha de expiracion definida en runtime-auth.md |

---

## 5. Contradicciones Detectadas

| ID | Documentos involucrados | Naturaleza | Severidad | Resolucion sugerida |
|:-:|---|---|:-:|---|
| C1 | canon/auth/* vs 01-FEATURES/auth/walkthroughs | Canon incluye MFA; walkthroughs antiguos no lo contemplan | Media | Deprecar walkthroughs con referencia a canon/auth |
| C2 | 02-PROCESSES.md vs canon/identidad-sacdia.md | Ownership post-registro difiere entre ambos | Alta | Resolver en canon/identidad; mover 02-PROCESSES a history |
| C3 | schema.prisma vs SCHEMA-REFERENCE.md | Schema drift: referencia no refleja estado actual de prisma | Alta | Sincronizar o marcar drift explicito en SCHEMA-REFERENCE |
| C4 | ENDPOINTS-LIVE-REFERENCE.md vs API-SPECIFICATION.md | Ambos describen contratos tecnicos de la API; autoridad ambigua | Media | Aclarar que ENDPOINTS-LIVE-REFERENCE es canonico; API-SPECIFICATION es complementario |
| C5 | runtime-sacdia.md (DRAFT) vs su posicion canonica (#5) | Documento no validado en cadena de autoridad | Alta | Validar contra codigo y promover a ACTIVE, o degradar a HISTORICAL |
| C6 | Auth docs en 4+ ubicaciones | Sin cadena de deprecacion, posibles contradicciones silenciosas | Alta | Establecer canon/auth como unica fuente; deprecar el resto |

---

## 6. Feature Coverage Matrix

| Feature | Req | Design | Tasks | Walkthroughs | Estado |
|---|:-:|:-:|:-:|:-:|---|
| actividades | -- | SI | -- | SI | Parcial |
| auth | -- | -- | -- | SI (6) | Solo walkthroughs |
| catalogos | -- | SI | -- | SI | Parcial |
| certificaciones-guias-mayores | SI | -- | -- | SI | Parcial |
| clases-progresivas | -- | SI | -- | -- | Minimo |
| communications | -- | -- | -- | SI | Solo walkthroughs |
| finanzas | -- | SI | -- | SI | Parcial |
| gestion-clubs | -- | SI | -- | SI | Parcial |
| gestion-seguros | SI | -- | -- | -- | Minimo |
| honores | -- | SI | -- | SI | Parcial |
| infrastructure | -- | -- | -- | SI | Solo walkthroughs |
| inventario | -- | -- | -- | SI | Solo walkthroughs |
| validacion-investiduras | SI | -- | -- | -- | Minimo |

> **Observacion critica:** Ningun feature alcanza cobertura completa. La columna "Tasks" esta vacia para todos -- no hay descomposicion de trabajo documentada para ninguna funcionalidad.

---

## 7. Scorecard

| Dimension | Score | Notas |
|---|:-:|---|
| Jerarquia de autoridad | 7/10 | Bien definida en source-of-truth.md; ejecucion incompleta (runtime DRAFT) |
| Completitud canon | 7/10 | Canon solido pero falta glosario y runtime validado |
| Cobertura operacional | 5/10 | API bien; features parciales; cero tasks |
| Sincronizacion | 6/10 | Drift en schema y auth; falta mecanismo de deteccion automatica |
| Calidad de navegacion | 8/10 | AGENTS.md y docs/README excelentes; CLAUDE.md multiples |
| Separacion historica | 9/10 | Bien organizado; faltan 2-3 archivos por mover |
| Integridad de links | 6/10 | Sin verificacion sistematica; referencias a archivos inexistentes |
| Manejo de deprecacion | 5/10 | Labels inconsistentes; falta cadena de deprecacion en auth |
| Documentacion faltante | 4/10 | Tasks, runbooks, glosario, deployment -- todo ausente |
| Cumplimiento de reglas | 6/10 | Canon define reglas claras pero no se aplican uniformemente |
| **GLOBAL** | **6.1/10** | Fundacion solida, ejecucion con brechas significativas |

---

## 8. Plan de Accion Recomendado

### Inmediato (Sprint actual)

| # | Accion | Responsable sugerido |
|:-:|---|---|
| 1 | Verificar `runtime-sacdia.md` contra codigo real. Si coincide, promover a ACTIVE. Si no, degradar a HISTORICAL y documentar discrepancias. | Lead tecnico |
| 2 | Marcar walkthroughs de auth en `01-FEATURES/` como DEPRECATED con referencia explicita a `canon/auth/` | Cualquier contributor |
| 3 | Sincronizar `SCHEMA-REFERENCE.md` con `schema.prisma` actual, o agregar header con warning de drift y fecha de ultima sincronizacion | Backend dev |
| 4 | Mover `02-PROCESSES.md` a `docs/history/` con label HISTORICAL | Cualquier contributor |

### Corto plazo (Este trimestre)

| # | Accion | Responsable sugerido |
|:-:|---|---|
| 5 | Crear `tasks.md` para los 3-4 features prioritarios del roadmap actual | Feature owners |
| 6 | Documentar procesos canonicos de auth (login -> GET /auth/me -> cambio de contexto) como flujo validado en canon/auth | Backend dev + lead |
| 7 | Evaluar si `structure.md` (HISTORICAL) necesita reemplazo activo o si `arquitectura-sacdia.md` cubre su funcion | Lead tecnico |
| 8 | Definir fecha de expiracion para campos legacy en `runtime-auth.md` (campos "transicionales") | Lead tecnico |
| 9 | Crear glosario canonico en `docs/canon/glosario.md` consolidando terminos de dominio-sacdia.md | Cualquier contributor |

### Largo plazo (Governance)

| # | Accion | Responsable sugerido |
|:-:|---|---|
| 10 | Instaurar auditoria trimestral usando `completion-matrix.md` como base | Lead del proyecto |
| 11 | Agregar lifecycle tracking a `decisiones-clave.md` (fecha de revision, estado de vigencia) | Lead tecnico |
| 12 | Expandir templates para scaffolding de features (requirements.md, design.md, tasks.md) | Equipo |

---

## 9. Mismatches Estructura vs Documentacion

| Item | Situacion | Accion sugerida |
|---|---|---|
| `.specs/` | Referenciado en `CLAUDE.md` de la raiz pero no existe | Remover referencia de CLAUDE.md -- fue superseded por `docs/canon/` |
| `postman/` | Carpeta existe con colecciones pero no esta mencionada en ningun README | Agregar referencia en docs/README o CLAUDE.md |
| `desing-admin-portal/` | Existe con contenido (Vite+React+TS mockups) pero tiene typo en el nombre y no esta documentado | Decidir: renombrar a `design-admin-portal/` y documentar, o archivar si ya no se usa |
| `PHASE-2-MOBILE-PROGRAM.md` | En raiz de `docs/` | Mover a `docs/history/` |
| `PHASE-3-ADMIN-PROGRAM.md` | En raiz de `docs/` | Mover a `docs/history/` |

---

## 10. Notas para el Lider del Proyecto

### Decisiones que requieren intervencion humana

1. **runtime-sacdia.md**: Validar contra codigo o degradar. Esto no se puede automatizar porque requiere conocimiento del estado real del sistema en produccion.
2. **desing-admin-portal/**: Decidir si se renombra y documenta o se archiva. Depende de si el equipo de diseno todavia lo usa.
3. **Prioridad de features para documentar tasks.md**: Solo el lead sabe cuales features van al proximo sprint.
4. **Campos legacy en runtime-auth.md**: Definir fechas de expiracion requiere decision de producto.

### Lo que se puede automatizar

- Sincronizacion schema.prisma -> SCHEMA-REFERENCE.md (CI check o script)
- Verificacion de links rotos en documentacion (lint en CI)
- Deteccion de documentos sin header de estado (script + workflow)
- Mover archivos a `history/` y actualizar referencias (PR mecanico)
- Generar templates vacios de `tasks.md` para features existentes

### Mensaje final

La documentacion de SACDIA esta en un punto de inflexion. El canon es una base excelente -- pocos proyectos tienen una jerarquia de autoridad tan bien pensada. El riesgo ahora es que esa estructura se vuelva aspiracional en vez de operacional. Las acciones inmediatas (items 1-4) se pueden resolver en un sprint y van a subir el score de 6.1 a ~7.0. Los items de corto plazo (5-9) son los que van a hacer la diferencia entre documentacion decorativa y documentacion util.
