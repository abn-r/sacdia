# Honors Sub-proyecto A: Calidad de datos + modelo de sub-items + evidencia por requisito

**Fecha**: 2026-04-06
**Estado**: Aprobado (brainstorming)
**Alcance**: Backend (NestJS), App móvil (Flutter), Panel admin (Next.js)
**Pre-requisito**: No hay datos de usuario en progreso (pre-producción)

---

## Contexto

SACDIA tiene 5,410 requisitos de especialidades/honors cargados en la DB (601 honors). Los datos provienen de OCR de 605 PDFs y tienen problemas de calidad significativos:

| Problema | Cantidad | % |
|----------|----------|---|
| Solo un número (basura) | 305 | 5.6% |
| Sub-items no detectados (has_sub_items=false con a.b.c.) | 437 | 8.1% |
| Sub-items como texto plano (has_sub_items=true) | 875 | 16.2% |
| Textos con tablas embebidas (>2000 chars) | ~50 | ~1% |
| Limpios | 3,793 | 70.1% |

Además, el modelo actual es plano: no soporta sub-items jerárquicos, choice groups ("elegí N de M"), evidencia por requisito, ni clasificación teórico/práctico.

---

## Decisiones de diseño (validadas en brainstorming)

1. **Tracking individual de sub-items**: Cada sub-item es checkeable independientemente. El padre se marca automáticamente cuando se completan los hijos necesarios.
2. **Choice groups**: "Elegí N de M" muestra todos los sub-items, acepta N completados. El padre se marca cumplido al alcanzar `choice_min`.
3. **Evidencia por requisito**: Hasta 3 por tipo (imagen, archivo, enlace) = hasta 9 evidencias por requisito.
4. **Texto de respuesta**: Campo de 800 caracteres para respuestas textuales.
5. **Clasificación teórico/práctico**: `requires_evidence` se determina por análisis automatizado de verbos en el texto del requisito. Pre-producción: definitivo (sin revisión). Post-producción: con revisión admin.
6. **Evidencia obligatoria vs opcional**: Si `requires_evidence=true`, el usuario no puede marcar como completado sin al menos 1 evidencia. Si `requires_evidence=false`, la evidencia es opcional.
7. **Limpieza de datos**: Re-escaneo de los 605 PDFs con parser mejorado. Se ACTUALIZAN registros existentes (no se borran) para preservar `requirement_id`.
8. **Evidencias persistentes**: Si un admin cambia `requires_evidence` de true a false, las evidencias ya subidas se conservan.
9. **Admin panel**: CRUD completo de requisitos + workflow de revisión con PDF original al lado.
10. **Skills de diseño**: Usar `mobile-design` para Flutter y `frontend-design`/`ui-designer` para admin panel durante implementación.

---

## Cambios de schema

### 1. `honor_requirements` — campos nuevos

```prisma
model honor_requirements {
  requirement_id      Int       @id @default(autoincrement())
  honor_id            Int
  parent_id           Int?      // NUEVO: FK self-ref, null = top-level
  requirement_number  Int       // ordenamiento dentro de su nivel
  display_label       String?   @db.VarChar(10)  // NUEVO: "1", "a", "ii", "3.b"
  requirement_text    String    // solo texto instruccional (sin sub-items embebidos)
  reference_text      String?   // NUEVO: tablas/material de referencia separado
  has_sub_items       Boolean   @default(false)
  is_choice_group     Boolean   @default(false)  // NUEVO: "elegí N de los siguientes"
  choice_min          Int?      // NUEVO: mínimo a completar
  requires_evidence   Boolean   @default(false)  // NUEVO: práctico=true, teórico=false
  needs_review        Boolean   @default(true)
  active              Boolean   @default(true)
  created_at          DateTime  @default(now())
  modified_at         DateTime  @updatedAt

  // Relations
  honor               honors                @relation(fields: [honor_id], references: [honor_id])
  parent              honor_requirements?   @relation("SubItems", fields: [parent_id], references: [requirement_id])
  children            honor_requirements[]  @relation("SubItems")

  // Para top-level: unique en (honor_id, requirement_number) donde parent_id IS NULL
  // Para sub-items: unique en (parent_id, requirement_number)
  // Implementar con partial unique indexes en migración SQL directa
  @@index([honor_id])
  @@index([parent_id])
}
```

**Cambios respecto al actual**:
- `parent_id Int?` — self-referential FK para jerarquía
- `display_label String?` — etiqueta visual ("1", "a", "ii")
- `reference_text String?` — material de referencia separado del texto instruccional
- `is_choice_group Boolean` — flag para choice groups
- `choice_min Int?` — N en "elegí N de M"
- `requires_evidence Boolean` — clasificación teórico/práctico
- Unique constraint: partial indexes — `(honor_id, requirement_number) WHERE parent_id IS NULL` para top-level, `(parent_id, requirement_number)` para sub-items

### 2. `requirement_evidence` — tabla nueva

```prisma
model requirement_evidence {
  evidence_id   Int       @id @default(autoincrement())
  progress_id   Int       // FK → user_honor_requirement_progress
  evidence_type evidence_type_enum  // IMAGE | FILE | LINK
  url           String    // URL del archivo (R2) o enlace externo
  filename      String?   @db.VarChar(255)  // nombre original
  mime_type     String?   @db.VarChar(100)
  file_size     Int?      // bytes
  active        Boolean   @default(true)
  created_at    DateTime  @default(now())
  modified_at   DateTime  @updatedAt

  progress      user_honor_requirement_progress @relation(fields: [progress_id], references: [progress_id])

  @@index([progress_id])
}

enum evidence_type_enum {
  IMAGE
  FILE
  LINK
}
```

**Límites (enforced en app layer, no en DB)**:
- Máximo 3 evidencias tipo IMAGE por progress_id
- Máximo 3 evidencias tipo FILE por progress_id
- Máximo 3 evidencias tipo LINK por progress_id

### 3. `user_honor_requirement_progress` — campo nuevo

```prisma
model user_honor_requirement_progress {
  progress_id     Int       @id @default(autoincrement())
  user_honor_id   Int
  requirement_id  Int
  completed       Boolean   @default(false)
  text_response   String?   @db.VarChar(800)  // NUEVO: respuesta de texto
  notes           String?   @db.VarChar(2000) // ya existe
  completed_at    DateTime?
  active          Boolean   @default(true)
  created_at      DateTime  @default(now())
  modified_at     DateTime  @updatedAt

  // Relations
  evidences       requirement_evidence[]  // NUEVO: relación a evidencias

  @@unique([user_honor_id, requirement_id])
}
```

**Cambios**:
- `text_response String? @db.VarChar(800)` — respuesta del usuario separada de notes
- `evidences` — relación a `requirement_evidence[]`

---

## Re-escaneo de PDFs

### Estrategia

Re-OCR completo de los 605 PDFs con parser mejorado, ejecutado con sub-agentes Sonnet en paralelo.

### Parser mejorado

El parser debe:

1. **Detectar numeración real vs sub-items**: Distinguir entre "1. Requisito principal" y "a. Sub-item" / "i. Sub-sub-item"
2. **Extraer choice groups**: Detectar patrones como "elegí N de los siguientes", "realizar al menos N de", "completar N de las siguientes"
3. **Separar tablas embebidas**: Si un requisito tiene >800 chars de texto que es material de referencia (tablas, listas de definiciones), moverlo a `reference_text`
4. **Clasificar requires_evidence**: Análisis de verbos:
   - Práctico (requires_evidence=true): "construir", "demostrar", "hacer", "crear", "elaborar", "montar", "preparar", "realizar" (cuando implica acción física), "cocinar", "sembrar", "plantar"
   - Teórico (requires_evidence=false): "definir", "explicar", "describir", "¿qué es?", "¿cuál es?", "mencionar", "enumerar", "listar", "citar"
   - Ambiguo: "presentar", "investigar" — depende del contexto, marcar como `needs_review=true`

### Proceso por fases

**Fase 1**: Re-OCR de los 605 PDFs → markdown con estructura mejorada
**Fase 2**: Comparar re-extracción contra datos actuales en DB, generar diff por honor
**Fase 3**: Aplicar updates (nunca delete) con `needs_review=true`
**Fase 4**: Clasificar `requires_evidence` por análisis de verbos

### Ejecución

- Dividir los 605 PDFs en lotes de ~60-80
- Cada lote procesado por un sub-agente Sonnet
- Resultado: JSON/CSV con estructura jerárquica por honor
- Script de migración aplica los cambios a la DB

---

## Backend (NestJS)

### Endpoints nuevos/modificados

#### Requisitos (público)

| Método | Path | Cambio |
|--------|------|--------|
| GET | `/honors/:honorId/requirements` | **Modificar**: retornar árbol jerárquico (padre + hijos), incluir `display_label`, `is_choice_group`, `choice_min`, `requires_evidence`, `reference_text` |

#### Progreso de requisitos (autenticado)

| Método | Path | Cambio |
|--------|------|--------|
| GET | `/users/:userId/honors/:honorId/requirements/progress` | **Modificar**: incluir `text_response`, evidencias por requisito, y estructura jerárquica |
| PATCH | `/users/:userId/honors/:honorId/requirements/:requirementId/progress` | **Modificar**: aceptar `text_response`, validar `requires_evidence` antes de permitir `completed=true` |
| PATCH | `/users/:userId/honors/:honorId/requirements/progress/batch` | **Modificar**: misma validación de evidencia en batch |

#### Evidencia por requisito (autenticado, nuevo)

| Método | Path | Descripción |
|--------|------|-------------|
| POST | `/users/:userId/honors/:honorId/requirements/:requirementId/evidence` | Upload de evidencia (multipart para IMAGE/FILE, JSON para LINK). Valida límite de 3 por tipo. |
| GET | `/users/:userId/honors/:honorId/requirements/:requirementId/evidence` | Listar evidencias del requisito con URLs firmadas (R2, 5-min TTL) |
| DELETE | `/users/:userId/honors/:honorId/requirements/:requirementId/evidence/:evidenceId` | Soft-delete de evidencia |

#### Admin (autenticado, nuevo)

| Método | Path | Descripción |
|--------|------|-------------|
| GET | `/admin/honors/:honorId/requirements` | Listar requisitos con árbol + flags editables |
| POST | `/admin/honors/:honorId/requirements` | Crear requisito (top-level o sub-item) |
| PATCH | `/admin/honors/:honorId/requirements/:requirementId` | Editar texto, flags, reordenar |
| DELETE | `/admin/honors/:honorId/requirements/:requirementId` | Soft-delete requisito |
| PATCH | `/admin/honors/:honorId/requirements/reorder` | Reordenar requisitos (batch) |
| GET | `/admin/requirements/pending-review` | Paginado de requisitos con `needs_review=true` |
| PATCH | `/admin/requirements/batch-review` | Aprobar/rechazar por lotes |

### Lógica de completado

```
Para un requisito TOP-LEVEL sin hijos:
  - Si requires_evidence=true: completed = (al menos 1 evidencia) AND (text_response o evidencia)
  - Si requires_evidence=false: completed = marcado por el usuario (text_response opcional)

Para un requisito TOP-LEVEL con hijos (has_sub_items=true):
  - Si is_choice_group=true: completed = (hijos completados >= choice_min)
  - Si is_choice_group=false: completed = (todos los hijos completados)

Para un SUB-ITEM (parent_id != null):
  - Misma lógica que top-level sin hijos (requires_evidence aplica individualmente)
```

### Storage (R2)

- Path: `requirement_evidence/{user_id}/{honor_id}/{requirement_id}/{evidence_id}.{ext}`
- URLs firmadas: 5 minutos TTL (misma política que `users_honors`)
- Tipos aceptados:
  - IMAGE: jpg, jpeg, png, webp, heic (max 10MB)
  - FILE: pdf, doc, docx, xls, xlsx, ppt, pptx (max 25MB)
  - LINK: validación de URL (no upload)

---

## Flutter (App móvil)

**Usar skill `mobile-design` durante implementación.**

### Vista de requisitos refactoreada

- Árbol jerárquico: requisitos top-level expandibles, sub-items indentados
- Choice groups: badge "Completá N de M" en el padre, contador de progreso
- Por cada requisito/sub-item:
  - Checkbox de completado
  - Campo de texto expandible (hasta 800 chars) para `text_response`
  - Botón de evidencia (si `requires_evidence=true`: obligatorio, color de acento; si false: gris, opcional)
  - Badge de estado: pendiente / completado / requiere evidencia
  - Material de referencia (`reference_text`): desplegable/acordeón

### Upload de evidencia

- Bottom sheet con 3 secciones: Fotos (3 max), Archivos (3 max), Enlaces (3 max)
- Fotos: cámara o galería (image_picker)
- Archivos: file_picker con filtro de tipos
- Enlaces: text input con validación de URL
- Preview de evidencias ya subidas con opción de eliminar
- Indicador de progreso de upload

### Providers nuevos/modificados

- `honorRequirementsProvider` → retornar árbol jerárquico
- `requirementEvidenceProvider(requirementId)` → evidencias del requisito
- `RequirementEvidenceNotifier` → upload/delete de evidencia
- Modificar `RequirementProgressNotifier` → validar `requires_evidence` antes de marcar completado
- Modificar `userHonorProgressProvider` → incluir `text_response` y evidencias

---

## Admin Panel (Next.js)

**Usar skills `frontend-design` y `ui-designer` durante implementación.**

### Vista de requisitos por honor

- Tabla/árbol jerárquico con drag & drop para reordenar
- Columnas: #, display_label, texto (truncado), has_sub_items, is_choice_group, choice_min, requires_evidence, needs_review, acciones
- Expandir/colapsar sub-items
- Inline editing de texto y flags
- Botón "Agregar requisito" (top-level) y "Agregar sub-item" (hijo)

### Workflow de revisión

- Vista dedicada `/dashboard/honors/requirements/review`
- Lista paginada de requisitos con `needs_review=true`
- Split view: PDF original (embed o iframe) a la izquierda, requisito editable a la derecha
- Acciones: Aprobar (sets needs_review=false), Editar + Aprobar, Rechazar (soft-delete)
- Filtros: por honor, por categoría, por tipo de problema
- Acciones por lotes: seleccionar múltiples → aprobar/rechazar

---

## Fuera de alcance (sub-proyectos B, C, D)

- UX avanzada de progreso (barras, gamification) → Sub-proyecto B
- Flujo de validación instructor → Sub-proyecto C
- Master honors, filtro skill level en catálogo → Sub-proyecto D
