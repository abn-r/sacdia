# Ground Truth First — Rediseño Documental SACDIA

**Fecha**: 2026-03-14
**Estado**: Aprobado
**Enfoque**: A — Ground Truth First

## Contexto y Problema

SACDIA tiene documentación construida top-down desde la idea del proyecto (canon) mientras el código creció bottom-up resolviendo necesidades puntuales. No hay certeza de cuánto del canon refleja la realidad del código. La documentación acumuló ruido: docs redundantes, estados inconsistentes, walkthroughs obsoletos, y una carpeta `docs/` con 100+ archivos donde no se distingue lo vigente de lo histórico.

### Situación actual

- **Canon**: 10 archivos en `docs/canon/` (8 raíz + 2 en `auth/`) con jerarquía de autoridad, construidos desde la idea del negocio
- **Código**: 3 sub-proyectos (backend NestJS, admin Next.js, app Flutter) en desarrollo local, sin deploy a producción
- **Documentación**: 6.1/10 en salud general — base sólida pero ejecución incompleta
- **Equipo**: 1 desarrollador + agentes IA
- **Negocio**: No completamente definido, canon fue el inicio de esa definición

### Problema raíz

No se sabe qué es real. Mientras no se sepa, cualquier documento puede estar describiendo algo que no existe. Esto genera un bucle: no se puede avanzar en desarrollo porque la documentación no es confiable, y no se puede mejorar la documentación porque no se sabe qué refleja la realidad.

## Objetivo

Reconstruir la documentación de SACDIA desde la verdad ejecutable (código) hacia arriba, verificando el canon contra la realidad y eliminando el ruido documental. Prioridades en orden:

1. **Planificación** — visibilidad clara de qué está hecho, qué falta, priorización
2. **Contrato operacional** — qué hace el sistema HOY, verificado contra código
3. **Onboarding** — que agentes IA puedan entender el sistema y contribuir

## Restricciones

- No se borra nada — se reorganiza. Documentos obsoletos se mueven a `history/`
- No se despliega a producción — todo es desarrollo local
- Los 4 repos son accesibles desde el mismo workspace

---

## Fase 1: Auditoría de Código (Ground Truth Extraction)

### Objetivo
Extraer hechos puros de cada sub-proyecto. Sin opiniones, sin comparaciones, sin juicios.

### Entregables

#### 1.1 Backend Audit (`docs/audit/backend-audit.md`)
- Cada endpoint real: método HTTP, ruta, controller, servicio, qué hace
- Cada modelo/tabla en schema.prisma con campos y relaciones
- Cada módulo NestJS con sus dependencias e imports
- Guards, decoradores custom, middleware implementados
- Servicios externos configurados y usados (Supabase, Firebase, Redis, etc.)
- Configuración de auth: estrategias, tokens, sesiones

#### 1.2 Admin Audit (`docs/audit/admin-audit.md`)
- Cada página/ruta implementada en Next.js
- Componentes principales y su función
- Qué endpoints del backend consume cada página
- Estado de integración con auth (qué está protegido, qué no)
- Librerías y dependencias principales

#### 1.3 App Audit (`docs/audit/app-audit.md`)
- Cada screen implementada en Flutter
- Providers/controllers/cubits y qué consumen
- Qué endpoints del backend consume cada screen
- Estado de integración con auth
- Navegación implementada (rutas, deep links)

### Formato
Datos crudos en tablas markdown. Sin narrativa. Una tabla por tipo de artefacto.

#### Esquemas de tablas obligatorios

**Endpoints** (backend):
| Method | Route | Controller | Service | Auth Guard | Description |

**Modelos** (backend):
| Model | Table Name | Fields Count | Relations | Enums Used |

**Módulos** (backend):
| Module | Controllers | Services | Imports | Exports |

**Páginas** (admin):
| Route | Page Component | API Endpoints Used | Auth Protected | Description |

**Screens** (app):
| Screen | Route | Provider/Cubit | API Endpoints Used | Auth Protected | Description |

**Integraciones**:
| Service | Package/SDK | Config Location | Used In Modules | Active |

### Verificación de completitud
- Backend endpoints: contar decoradores `@Get|@Post|@Put|@Delete|@Patch` en controllers y comparar con tabla
- Modelos: contar declaraciones `model` en schema.prisma y comparar con tabla
- Admin páginas: contar archivos `page.tsx` o equivalentes y comparar con tabla
- App screens: contar widgets de screen registrados en rutas y comparar con tabla

### Ejecución
- 3 sub-agentes en paralelo (uno por sub-proyecto)
- Cada agente escanea el código fuente directamente

---

## Fase 2: Reality Matrix

### Objetivo
Cruzar la auditoría de código contra el canon y la documentación existente para saber qué es real, qué es fantasma, y qué tiene drift.

### Entregable: `docs/audit/REALITY-MATRIX.md`

#### Tabla 1: Endpoints
| Endpoint | Implementado | Doc API (ENDPOINTS-LIVE-REFERENCE) | Canon menciona | Estado |
|----------|:---:|:---:|:---:|---|

Estados posibles:
- **ALINEADO** — existe en código, documentado, canon lo contempla
- **SIN CANON** — existe y funciona pero canon no lo define
- **SIN DOCS** — existe en código pero no está documentado
- **FANTASMA** — documentado pero no implementado
- **DRIFT** — existe pero se comporta distinto a lo documentado

#### Tabla 2: Modelos de Datos
| Tabla/Modelo | En schema.prisma | En SCHEMA-REFERENCE | Canon menciona | Estado |
|-------------|:---:|:---:|:---:|---|

#### Tabla 3: Módulos/Features
| Dominio canon | Módulo backend | Páginas admin | Screens app | Estado |
|--------------|:---:|:---:|:---:|---|

#### Tabla 4: Integraciones Externas
| Servicio | Configurado | Usado activamente | Documentado | Estado |
|---------|:---:|:---:|:---:|---|

### Ejecución
- 1 agente que toma las 3 auditorías + canon + docs actuales y produce la matrix
- Depende de: Fase 1 completa

---

## Fase 3a: Canon Update

### Objetivo
Verificar cada documento canónico contra la Reality Matrix y marcar su estado real.

### Proceso
Para cada documento canónico:
1. Cruzar sus afirmaciones contra la Reality Matrix
2. Marcar lo que es **verificado** (coincide con código)
3. Marcar lo que es **aspiracional** (existe en canon pero no en código)
4. Marcar lo que es **incompleto** (falta en canon pero existe en código)
5. `runtime-sacdia.md` pasa de DRAFT a ACTIVE con datos verificados

### Entregable
- Documentos canónicos actualizados con marcas de verificación
- Lista de decisiones pendientes para el desarrollador (qué del canon aspiracional se mantiene como objetivo vs qué se descarta)

### Ejecución
- 1 agente con acceso a Reality Matrix + canon actual
- Depende de: Fase 2 completa

---

## Fase 3b: Docs Simplificación

### Objetivo
Reorganizar `docs/` eliminando ruido. No se borra nada, se mueve a `history/`.

### Estructura final

```
docs/
├── canon/                  # Verdad del negocio (verificada contra código)
├── audit/                  # Auditorías + Reality Matrix (foto del código)
│   ├── backend-audit.md
│   ├── admin-audit.md
│   ├── app-audit.md
│   └── REALITY-MATRIX.md
├── api/                    # Solo ENDPOINTS-LIVE-REFERENCE (verificado, solo endpoints reales)
├── database/               # schema.prisma + SCHEMA-REFERENCE (sincronizado)
├── steering/               # Solo docs activos: tech, coding-standards, data-guidelines, agents
├── guides/                 # Guías operativas vigentes
├── features/               # Un archivo por feature con estado real (Fase 3c)
├── plans/                  # Planes activos (se mantiene)
├── templates/              # Templates (se mantiene)
├── history/                # TODO lo que no sea activo
│   ├── 00-STEERING/        # product.md (DEPRECATED), structure.md (HISTORICAL)
│   ├── 01-FEATURES/        # walkthroughs viejos, docs de auth legacy
│   ├── 02-API/             # docs redundantes (API-REFERENCE.md, etc.)
│   ├── 02-PROCESSES.md
│   ├── 03-DATABASE/        # docs desincronizados si aplica
│   ├── phases/             # PHASE-2, PHASE-3, roadmap, implementation plan
│   ├── context/            # dominio-auth.md y otros
│   └── [contenido existente de history/]
└── README.md               # Índice actualizado con nueva estructura
```

### Cambios clave
- Se eliminan prefijos numéricos (`00-`, `01-`, `02-`, `03-`)
- ENDPOINTS-LIVE-REFERENCE se verifica: solo endpoints que existen en código
- SCHEMA-REFERENCE se sincroniza contra schema.prisma
- Todo documento sin estado explícito recibe uno (ACTIVE/DRAFT/HISTORICAL/DEPRECATED)
- CLAUDE.md de navegación por carpeta se consolidan en README principal
- Documentos redundantes (API-REFERENCE.md como alias) se mueven a history

### Regla de archivos no mapeados
Cualquier archivo o directorio en `docs/` que no esté explícitamente mapeado a la nueva estructura se mueve a `history/` con una nota sobre su ubicación original. Casos específicos:
- `docs/CLAUDE.md` → se mueve a `history/navigation/` y se reemplaza con versión actualizada o se consolida en `docs/README.md`
- `docs/superpowers/` → se mantiene como `superpowers/` (contiene specs y artefactos SDD activos)
- `docs/BACKEND-PANORAMA-*.md`, `docs/CHANGELOG-IMPLEMENTATION.md` → `history/`
- `docs/DEPLOYMENT-GUIDE.md` → se evalúa: si es vigente va a `guides/`, si no a `history/`
- `docs/03-IMPLEMENTATION-ROADMAP.md` → `history/phases/`

### Ejecución
- 1 agente de reorganización
- Depende de: Fase 3a Y Fase 3c completas (necesita feature registry creado antes de reorganizar)

---

## Fase 3c: Feature Registry

### Objetivo
Un archivo por dominio que muestre el estado real de cada feature.

### Ubicación: `docs/features/{dominio}.md`

### Formato estándar

```markdown
# {Nombre del Dominio}
Estado: IMPLEMENTADO | PARCIAL | PLANIFICADO | NO INICIADO

## Qué existe (verificado contra código)
- [endpoints, tablas, screens que existen realmente]

## Qué define el canon
- [lo que dice dominio-sacdia.md, decisiones-clave.md sobre este dominio]

## Gap
- [diferencia entre lo que existe y lo que el canon espera]

## Prioridad
- [a definir por el desarrollador después de ver la matrix]
```

### Features a documentar
Lista inicial derivada de `docs/01-FEATURES/` (13 dominios): actividades, auth, catalogos, certificaciones-guias-mayores, clases-progresivas, communications, finanzas, gestion-clubs, gestion-seguros, honores, infrastructure, inventario, validacion-investiduras.

**Regla**: Esta lista se valida contra los módulos reales del backend durante Fase 2. Dominios con cero artefactos de código reciben estado `NO INICIADO`. Si el código tiene módulos no listados aquí, se agregan como dominios nuevos.

### Ejecución
- 1 agente con acceso a Reality Matrix + canon
- Depende de: Fase 2 completa (puede correr en paralelo con 3a)

---

## Orden de Ejecución

```
Fase 1 (paralelo):
  ├── 1.1 Backend Audit ──┐
  ├── 1.2 Admin Audit ────┼── Fase 2: Reality Matrix
  └── 1.3 App Audit ──────┘         │
                                     ├── Fase 3a: Canon Update ────────┐
                                     └── Fase 3c: Feature Registry ────┼── Fase 3b: Docs Simplificación
```

## Resultado Final

Al completar las 3 fases:
- **Sabés qué es real** — la Reality Matrix es tu fuente de verdad operacional
- **Canon verificado** — cada afirmación canónica está marcada como verificada o aspiracional
- **Docs sin ruido** — estructura limpia donde todo tiene estado explícito
- **Feature registry** — visibilidad clara por dominio para planificar con el líder
- **Base para avanzar** — tanto vos como los agentes IA saben qué hay, qué falta, y dónde ir

---

## Qué NO incluye este diseño

- No se redefine el negocio (eso viene después, informado por la Reality Matrix)
- No se escribe código nuevo
- No se implementan features faltantes
- No se crea CI/CD para validación documental
- No se despliega nada
