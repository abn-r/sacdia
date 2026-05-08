# Runtime Audit + Docs Reset Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Auditar el runtime real de SACDIA, compararlo contra canon/docs vigentes y producir una base operacional verificable para onboarding de agentes y reorganización documental.

**Architecture:** El trabajo se divide en cuatro entregables secuenciales: inventario factual del backend, reality matrix, contrato operacional mínimo y reorganización documental guiada por evidencia. El canon de negocio no se reescribe al inicio; primero se separa explícitamente la verdad operativa verificada del contenido aspiracional o histórico.

**Tech Stack:** Markdown, NestJS backend source inspection, Prisma schema, documentación existente en `docs/`, scripts utilitarios del workspace.

---

### Task 1: Congelar alcance y fuentes autorizadas

**Files:**
- Read: `/Users/abner/Documents/development/sacdia/AGENTS.md`
- Read: `/Users/abner/Documents/development/sacdia/docs/canon/source-of-truth.md`
- Read: `/Users/abner/Documents/development/sacdia/docs/canon/gobernanza-canon.md`
- Create: `/Users/abner/Documents/development/sacdia/docs/plans/2026-03-14-runtime-audit-docs-reset-plan.md`

**Step 1: Confirmar objetivo operativo**
- Alinear que el objetivo inmediato es: `planificación -> contrato operacional -> onboarding`, no cleanup masivo.

**Step 2: Congelar criterio de verdad**
- Definir tres etiquetas de evidencia: `verified-runtime`, `documented-only`, `historical-or-aspirational`.

**Step 3: Confirmar política editorial**
- Registrar que nada se borra; lo no vigente se mueve o clasifica bajo `docs/history/`.

**Step 4: Verificar salida esperada**
- Entregables mínimos: inventario backend, reality matrix, onboarding IA, mapa de migración documental.

### Task 2: Levantar inventario factual del backend

**Files:**
- Read: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/**/*.controller.ts`
- Read: `/Users/abner/Documents/development/sacdia/sacdia-backend/prisma/schema.prisma`
- Create: `/Users/abner/Documents/development/sacdia/docs/plans/runtime-audit-inventory.md`

**Step 1: Extraer controllers y rutas HTTP**
- Listar cada controller, prefijo `@Controller`, método HTTP, path y archivo fuente.

**Step 2: Extraer superficie de datos**
- Listar modelos Prisma, enums y relaciones/familias clave.

**Step 3: Agrupar por módulo operativo**
- Consolidar inventario por dominios: auth, users, clubs, classes, admin, etc.

**Step 4: Marcar incertidumbres**
- Señalar rutas o módulos que existan en código pero requieran validación adicional de vigencia.

### Task 3: Construir reality matrix

**Files:**
- Read: `/Users/abner/Documents/development/sacdia/docs/canon/runtime-sacdia.md`
- Read: `/Users/abner/Documents/development/sacdia/docs/canon/completion-matrix.md`
- Read: `/Users/abner/Documents/development/sacdia/docs/02-API/ENDPOINTS-LIVE-REFERENCE.md`
- Create: `/Users/abner/Documents/development/sacdia/docs/plans/reality-matrix.md`

**Step 1: Definir columnas**
- `runtime real`, `canon`, `api docs`, `estado`, `nota/acción`.

**Step 2: Cruzar endpoints**
- Marcar `aligned`, `doc-drift`, `code-only`, `canon-only`, `unknown`.

**Step 3: Cruzar modelo de datos**
- Marcar drift entre `schema.prisma`, `SCHEMA-REFERENCE.md` y canon/runtime.

**Step 4: Resumir contradicciones prioritarias**
- Preparar top 10 discrepancias que bloquean onboarding o planificación.

### Task 4: Redactar contrato operacional mínimo

**Files:**
- Create: `/Users/abner/Documents/development/sacdia/docs/canon/operational-contract.md`
- Read: `/Users/abner/Documents/development/sacdia/docs/canon/source-of-truth.md`
- Read: `/Users/abner/Documents/development/sacdia/docs/plans/reality-matrix.md`

**Step 1: Declarar propósito**
- Explicar qué puede asumir un agente hoy sin inventar.

**Step 2: Separar capas**
- Secciones mínimas: `qué está verificado`, `qué es canon de negocio`, `qué está en transición`, `qué no debe asumirse`.

**Step 3: Definir precedencia operacional temporal**
- Mientras dure la reconciliación: inventario verificado > contrato operacional > canon de negocio > docs subordinadas > history.

**Step 4: Añadir reglas anti-hallucination**
- Si algo no está en `verified-runtime` o contrato operacional, el agente debe marcarlo como no verificado.

### Task 5: Crear onboarding para agentes IA

**Files:**
- Create: `/Users/abner/Documents/development/sacdia/docs/agent-onboarding.md`
- Modify: `/Users/abner/Documents/development/sacdia/AGENTS.md`
- Modify: `/Users/abner/Documents/development/sacdia/README.md`

**Step 1: Definir ruta corta de lectura**
- Máximo 5-7 documentos para arrancar sin ruido.

**Step 2: Escribir reglas de operación**
- Qué consultar primero, qué no asumir, cómo escalar contradicciones.

**Step 3: Enlazar desde README/AGENTS**
- Hacer visible el onboarding como puerta de entrada para vos y para agentes.

**Step 4: Verificar consistencia**
- Confirmar que onboarding no contradiga `source-of-truth` ni el contrato operacional.

### Task 6: Reorganizar documentación sin borrar contenido

**Files:**
- Modify: `/Users/abner/Documents/development/sacdia/docs/README.md`
- Modify: `/Users/abner/Documents/development/sacdia/docs/history/README.md`
- Move/Annotate: documentos legacy o duplicados detectados por la matrix

**Step 1: Definir buckets finales**
- `canon/`, `operational/` o equivalente mínimo, `history/`, `plans/`.

**Step 2: Reetiquetar documentos conflictivos**
- Marcar `ACTIVE`, `DRAFT`, `HISTORICAL`, `DEPRECATED` donde corresponda.

**Step 3: Mover solo después de mapear reemplazo**
- Ningún documento va a `history/` sin referencia explícita a su reemplazo activo.

**Step 4: Actualizar índices**
- Ajustar `docs/README.md` y mapas de navegación.

### Task 7: Cerrar con priorización ejecutiva

**Files:**
- Create: `/Users/abner/Documents/development/sacdia/docs/plans/runtime-audit-executive-summary.md`

**Step 1: Resumir hallazgos**
- Contar módulos, endpoints, tablas y drift principal.

**Step 2: Priorizar roadmap corto**
- Orden: `contrato operacional`, `onboarding`, `alineación API`, `alineación data`, `canon v2 por dominio`.

**Step 3: Identificar decisiones tuyas**
- Listar lo que requiere definición de negocio humana y no debe decidir un agente.

**Step 4: Proponer siguiente slice**
- Recomendar primer dominio operativo a reconciliar por completo.
