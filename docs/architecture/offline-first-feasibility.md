# Offline-First Feasibility Analysis — SACDIA App

> **Status**: ANALYSIS ONLY — No implementation decision taken yet.
> **Date**: 2026-04-06
> **Pending**: Define which operations MUST work offline vs nice-to-have before proceeding.

---

## Context

Many SACDIA users may not have reliable internet access. The app needs to allow offline data consultation and, eventually, offline write operations that sync when connectivity is restored.

## Current State

- **Flutter app**: 100% remote-dependent, zero offline capabilities
- **28 feature modules**, most are WRITE-heavy
- **No local database** (no Hive, SQLite, Isar, Drift)
- **Persistence**: Only SecureStorage (auth tokens + PII cache) and SharedPreferences (settings)
- **52 repositories**, all remote-only via Dio
- **74 models** with `fromJson()`/`toJson()` — serializable
- **Clean architecture** (repositories, data sources separated) — good foundation for adding local layer

## Backend State (96 Prisma models, 47 controllers)

- All entities have `created_at` + `modified_at` with microsecond precision (`@db.Timestamptz(6)`)
- Mix of auto-increment (Int) + UUID (String) primary keys (~40 models use UUID)
- Soft-delete via boolean `active` flag (no hard deletes)
- 7 bulk/batch endpoints already exist
- No optimistic locking (no `version` column)
- File storage via Cloudflare R2 with signed URLs (300s expiry)
- 11 enums for state machines (investiture has 8 states with strict transitions)

---

## What Favors Offline-First

| Factor | Detail |
|--------|--------|
| Clean architecture | Repositories separated from data sources — adding `LocalDataSource` is natural |
| Timestamps everywhere | 96 entities with `created_at` + `modified_at` — enables Last-Write-Wins sync |
| Serializable models | 74 models with `fromJson()`/`toJson()` — direct local DB storage |
| Soft-delete pattern | Boolean `active` flag, no hard deletes — offline-friendly |
| Bulk endpoints | 7 batch APIs — sync can send payloads in bulk |
| UUIDs (~40 models) | Client can generate IDs offline without server collision |

## What Complicates Offline-First

| Factor | Risk | Detail |
|--------|------|--------|
| Complex unique constraints | HIGH | Up to 5-field unique constraints (e.g., `club_role_assignments`). Sync must detect violations pre-send |
| No version column | HIGH | No optimistic locking — concurrent offline edits on same record undetectable without adding it |
| 20+ cascading deletes | MEDIUM | Server-side cascades. Offline CANNOT delete — must queue and confirm on reconnect |
| State machines | MEDIUM | `investiture_status` has 8 states with strict transitions. Client must validate offline |
| Server-side transactions | MEDIUM | Multi-step atomicity (enrollment + history + audit) lost offline |
| Signed URLs expire | LOW | R2 signed URLs (300s). Must cache files locally or re-sign on sync |

---

## Proposed Phased Strategy

### Phase 1 — Read-Only Offline (Cache for Consultation)

**Impact: HIGH | Risk: LOW | Backend changes: NONE**

- Add local database (Drift/SQLite recommended) to cache entities the user queries most
- Every successful `GET` saves to local DB. Without network, UI shows cached data
- Visual indicator: "Offline mode — data from last sync"
- **Cache**: club members, activities, classes, honors, profile, dashboard
- **Don't cache**: large global catalogs (download once, refresh periodically)
- **Estimated effort**: 2-3 weeks

### Phase 2 — Offline Writes with Sync Queue

**Impact: HIGH | Risk: MEDIUM | Backend changes: Add `version` column**

- Operation queue: user performs action → saved locally → uploaded when network returns
- **Candidate operations** (high value, low conflict risk):
  - Record activity attendance
  - Mark honor/requirement progress
  - Update class progress
  - Draft monthly reports
- **NOT offline** (high conflict risk):
  - Assign/remove club roles
  - Approve/reject investiture enrollments
  - Evaluate annual folders
  - Club transfers
- **Backend change**: Add `version` (Int, auto-increment on update) to syncable entities
- **Estimated effort**: 3-5 weeks

### Phase 3 — Bidirectional Sync with Conflict Resolution

**Impact: MEDIUM | Risk: HIGH**

- Conflict detection: if local `version` ≠ server `version`, flag conflict
- Resolution UI: "This record was modified while you were offline — keep yours or server's?"
- Background sync service with exponential retry
- File upload queue with hash deduplication
- Offline audit trail: log operations locally, send with sync
- **Estimated effort**: 4-6 weeks

---

## Local Database Recommendation

| Option | Pro | Contra | Verdict |
|--------|-----|--------|---------|
| **Drift (SQLite)** | Real SQL, migrations, complex queries, relations, type-safe | More verbose, more setup | **Recommended** |
| **Isar** | Fast, clean API | Discontinued by author, uncertain future | Not recommended |
| **Hive** | Simple, key-value | Doesn't scale for complex queries/relations | Not suitable |
| **ObjectBox** | Fast, built-in sync | Commercial license for sync features | Evaluate cost |

**Recommendation: Drift (SQLite)** — 96 entities with complex relationships and unique constraints need real SQL for conflict queries, joins, and migrations. Drift provides Dart type-safety with code generation.

---

## Conflict-Prone Entities (8 High Risk)

1. **Enrollments** — 5-field unique, state machine, concurrent approval workflows
2. **Users Honors** — reactivation + concurrent validation
3. **Annual Folder Evaluations** — two evaluators scoring same section
4. **Club Role Assignments** — 5-field unique, overlapping date ranges
5. **Camporee Registrations** — status updates race (approved/rejected)
6. **Monthly Reports** — director draft vs treasurer online edit
7. **Activity Instances** — joint activities across sections, bulk updates
8. **Class Section Progress** — evidence submission vs validator approval race

---

## Complete Action Inventory (230+ actions)

Use this checklist with the client to decide which actions need offline support.
Mark each action: **OFFLINE** (must work without internet), **CACHE** (read-only from cache), **ONLINE-ONLY** (requires internet).

### Auth (Autenticación)

| # | Action | Type | Description | Offline Decision |
|---|--------|------|-------------|-----------------|
| 1 | Iniciar sesión | CREATE | Login con email/contraseña | ONLINE-ONLY (needs server auth) |
| 2 | Registrarse | CREATE | Registro con email/contraseña | ONLINE-ONLY |
| 3 | Cerrar sesión | DELETE | Logout e invalidar sesión | ONLINE-ONLY |
| 4 | Recuperar contraseña | CREATE | Solicitar email de reset | ONLINE-ONLY |
| 5 | Actualizar contraseña | UPDATE | Cambiar contraseña actual | ONLINE-ONLY |
| 6 | Obtener perfil actual | READ | Perfil del usuario autenticado | `[ ]` |
| 7 | Verificar estado post-registro | READ | Verificar si completó post-registro | `[ ]` |
| 8 | Cambiar contexto activo | UPDATE | Cambiar rol/asignación activa | `[ ]` |
| 9 | Login con Google | CREATE | OAuth con Google | ONLINE-ONLY |
| 10 | Login con Apple | CREATE | OAuth con Apple | ONLINE-ONLY |

### Profile (Perfil)

| # | Action | Type | Description | Offline Decision |
|---|--------|------|-------------|-----------------|
| 1 | Ver perfil de usuario | READ | Ver datos del perfil | `[ ]` |
| 2 | Actualizar perfil | UPDATE | Modificar información personal | `[ ]` |
| 3 | Cambiar foto de perfil | UPLOAD | Subir nueva foto | `[ ]` |

### Post Registration (Información Personal)

| # | Action | Type | Description | Offline Decision |
|---|--------|------|-------------|-----------------|
| 1 | Actualizar info personal | UPDATE | Género, fecha nacimiento, bautismo | `[ ]` |
| 2 | Ver contactos de emergencia | READ | Listar contactos de emergencia | `[ ]` |
| 3 | Agregar contacto emergencia | CREATE | Nuevo contacto de emergencia | `[ ]` |
| 4 | Actualizar contacto emergencia | UPDATE | Modificar contacto existente | `[ ]` |
| 5 | Eliminar contacto emergencia | DELETE | Borrar contacto | `[ ]` |
| 6 | Obtener tipos de relación | READ | Catálogo de tipos de relación | `[ ]` |
| 7 | Verificar si requiere repr. legal | READ | Revisar si necesita representante | `[ ]` |
| 8 | Crear representante legal | CREATE | Registrar representante legal | `[ ]` |
| 9 | Ver representante legal | READ | Ver datos del representante | `[ ]` |
| 10 | Actualizar representante legal | UPDATE | Modificar representante | `[ ]` |
| 11 | Ver catálogo de alergias | READ | Catálogo general | `[ ]` |
| 12 | Ver alergias del usuario | READ | Alergias seleccionadas | `[ ]` |
| 13 | Guardar alergias | CREATE | Guardar selección de alergias | `[ ]` |
| 14 | Eliminar alergia | DELETE | Quitar alergia | `[ ]` |
| 15 | Ver catálogo de enfermedades | READ | Catálogo general | `[ ]` |
| 16 | Ver enfermedades del usuario | READ | Condiciones médicas del usuario | `[ ]` |
| 17 | Guardar enfermedades | CREATE | Guardar condiciones médicas | `[ ]` |
| 18 | Eliminar enfermedad | DELETE | Quitar condición | `[ ]` |
| 19 | Ver catálogo de medicamentos | READ | Catálogo general | `[ ]` |
| 20 | Ver medicamentos del usuario | READ | Medicamentos del usuario | `[ ]` |
| 21 | Guardar medicamentos | CREATE | Guardar medicamentos | `[ ]` |
| 22 | Eliminar medicamento | DELETE | Quitar medicamento | `[ ]` |

### Club

| # | Action | Type | Description | Offline Decision |
|---|--------|------|-------------|-----------------|
| 1 | Ver información del club | READ | Datos del club | `[ ]` |
| 2 | Ver sección del club | READ | Detalle de sección | `[ ]` |
| 3 | Actualizar sección | UPDATE | Modificar información de sección | `[ ]` |

### Members (Miembros)

| # | Action | Type | Description | Offline Decision |
|---|--------|------|-------------|-----------------|
| 1 | Ver miembros del club | READ | Lista de miembros de sección | `[ ]` |
| 2 | Ver detalle del miembro | READ | Perfil de un miembro específico | `[ ]` |
| 3 | Ver solicitudes de ingreso | READ | Solicitudes pendientes | `[ ]` |
| 4 | Aprobar solicitud de ingreso | CREATE | Aceptar solicitud | `[ ]` |
| 5 | Rechazar solicitud de ingreso | CREATE | Rechazar solicitud | `[ ]` |
| 6 | Asignar rol a miembro | CREATE | Asignar rol de club | `[ ]` |
| 7 | Remover rol de miembro | DELETE | Quitar rol de club | `[ ]` |

### Activities (Actividades)

| # | Action | Type | Description | Offline Decision |
|---|--------|------|-------------|-----------------|
| 1 | Ver actividades del club | READ | Lista de actividades activas | `[ ]` |
| 2 | Ver detalle de actividad | READ | Detalles de una actividad | `[ ]` |
| 3 | Crear actividad | CREATE | Nueva actividad | `[ ]` |
| 4 | Actualizar actividad | UPDATE | Modificar actividad | `[ ]` |
| 5 | Eliminar actividad | DELETE | Borrar actividad | `[ ]` |
| 6 | Ver asistencia de actividad | READ | Registros de asistencia | `[ ]` |
| 7 | Registrar asistencia | CREATE | Marcar asistencia de miembros | `[ ]` |
| 8 | Subir imagen de actividad | UPLOAD | Foto de la actividad | `[ ]` |

### Classes (Clases Progresivas)

| # | Action | Type | Description | Offline Decision |
|---|--------|------|-------------|-----------------|
| 1 | Ver catálogo de clases | READ | Todas las clases progresivas | `[ ]` |
| 2 | Ver detalle de clase | READ | Detalles con módulos | `[ ]` |
| 3 | Ver módulos de clase | READ | Módulos y requisitos | `[ ]` |
| 4 | Ver clases del usuario | READ | Clases inscritas | `[ ]` |
| 5 | Ver progreso de clase | READ | Progreso actual | `[ ]` |
| 6 | Actualizar progreso | UPDATE | Marcar requisito completado | `[ ]` |
| 7 | Inscribirse en clase | CREATE | Inscripción en año eclesiástico | `[ ]` |
| 8 | Ver progreso detallado | READ | Módulos y secciones con estado | `[ ]` |
| 9 | Enviar requisito a validación | CREATE | Enviar para revisión | `[ ]` |
| 10 | Subir evidencia de clase | UPLOAD | Archivo de evidencia | `[ ]` |
| 11 | Eliminar evidencia de clase | DELETE | Borrar archivo | `[ ]` |

### Honors (Especialidades)

| # | Action | Type | Description | Offline Decision |
|---|--------|------|-------------|-----------------|
| 1 | Ver categorías | READ | Categorías de especialidades | `[ ]` |
| 2 | Ver especialidades | READ | Lista paginada | `[ ]` |
| 3 | Ver detalle de especialidad | READ | Info de una especialidad | `[ ]` |
| 4 | Ver especialidades del usuario | READ | Especialidades inscritas | `[ ]` |
| 5 | Ver estadísticas | READ | Stats de especialidades | `[ ]` |
| 6 | Inscribirse en especialidad | CREATE | Iniciar especialidad | `[ ]` |
| 7 | Actualizar especialidad | UPDATE | Modificar inscripción | `[ ]` |
| 8 | Eliminar inscripción | DELETE | Desinscribirse | `[ ]` |
| 9 | Registrar especialidad | CREATE | Registrar con detalles | `[ ]` |
| 10 | Ver agrupadas por categoría | READ | Vista agrupada | `[ ]` |
| 11 | Ver requisitos | READ | Lista de requisitos | `[ ]` |
| 12 | Ver progreso de requisitos | READ | Estado de cada requisito | `[ ]` |
| 13 | Marcar requisito completado | UPDATE | Actualizar progreso individual | `[ ]` |
| 14 | Actualizar progreso en lote | UPDATE | Batch update de requisitos | `[ ]` |
| 15 | Subir archivo de especialidad | UPLOAD | Imagen de evidencia | `[ ]` |
| 16 | Subir evidencia de requisito | UPLOAD | Archivo para requisito | `[ ]` |
| 17 | Agregar enlace de evidencia | CREATE | Link como evidencia | `[ ]` |
| 18 | Ver evidencias de requisito | READ | Archivos de un requisito | `[ ]` |
| 19 | Eliminar evidencia | DELETE | Borrar archivo | `[ ]` |

### Enrollment (Inscripción de Sección)

| # | Action | Type | Description | Offline Decision |
|---|--------|------|-------------|-----------------|
| 1 | Crear inscripción | CREATE | Inscribir sección para el año | `[ ]` |
| 2 | Ver inscripción activa | READ | Inscripción actual | `[ ]` |
| 3 | Actualizar inscripción | UPDATE | Modificar datos | `[ ]` |

### Investiture (Investidura)

| # | Action | Type | Description | Offline Decision |
|---|--------|------|-------------|-----------------|
| 1 | Enviar para validación | CREATE | Enviar inscripción a validar | `[ ]` |
| 2 | Validar inscripción | CREATE | Aprobar o rechazar | `[ ]` |
| 3 | Marcar como investido | CREATE | Completar investidura | `[ ]` |
| 4 | Ver investiduras pendientes | READ | Lista de pendientes | `[ ]` |
| 5 | Ver historial de investidura | READ | Historial de acciones | `[ ]` |

### Annual Folders (Carpetas Anuales)

| # | Action | Type | Description | Offline Decision |
|---|--------|------|-------------|-----------------|
| 1 | Ver carpeta anual | READ | Carpeta por inscripción | `[ ]` |
| 2 | Subir evidencia | UPLOAD | Archivo a sección de carpeta | `[ ]` |
| 3 | Eliminar evidencia | DELETE | Borrar archivo de carpeta | `[ ]` |
| 4 | Enviar carpeta | CREATE | Enviar a validación | `[ ]` |

### Evidence Folder (Carpeta de Evidencias del Club)

| # | Action | Type | Description | Offline Decision |
|---|--------|------|-------------|-----------------|
| 1 | Ver carpeta de evidencias | READ | Carpeta de la sección | `[ ]` |
| 2 | Enviar carpeta completa | CREATE | Enviar toda la carpeta | `[ ]` |
| 3 | Enviar sección | CREATE | Enviar una sección | `[ ]` |
| 4 | Subir archivo | UPLOAD | Subir evidencia | `[ ]` |
| 5 | Eliminar archivo | DELETE | Borrar evidencia | `[ ]` |

### Finances (Finanzas)

| # | Action | Type | Description | Offline Decision |
|---|--------|------|-------------|-----------------|
| 1 | Ver movimientos | READ | Lista de transacciones | `[ ]` |
| 2 | Ver resumen financiero | READ | Resumen consolidado | `[ ]` |
| 3 | Ver detalle de movimiento | READ | Detalle de transacción | `[ ]` |
| 4 | Crear movimiento | CREATE | Nueva transacción | `[ ]` |
| 5 | Actualizar movimiento | UPDATE | Modificar transacción | `[ ]` |
| 6 | Eliminar movimiento | DELETE | Borrar transacción | `[ ]` |
| 7 | Ver categorías | READ | Catálogo de categorías | `[ ]` |

### Inventory (Inventario)

| # | Action | Type | Description | Offline Decision |
|---|--------|------|-------------|-----------------|
| 1 | Ver categorías | READ | Categorías de inventario | `[ ]` |
| 2 | Ver ítems | READ | Lista de ítems del club | `[ ]` |
| 3 | Ver detalle de ítem | READ | Detalle de un ítem | `[ ]` |
| 4 | Crear ítem | CREATE | Agregar al inventario | `[ ]` |
| 5 | Actualizar ítem | UPDATE | Modificar ítem | `[ ]` |
| 6 | Eliminar ítem | DELETE | Borrar ítem | `[ ]` |

### Insurance (Seguros)

| # | Action | Type | Description | Offline Decision |
|---|--------|------|-------------|-----------------|
| 1 | Ver seguros de miembros | READ | Estado de seguros | `[ ]` |
| 2 | Ver detalle de seguro | READ | Detalle de un seguro | `[ ]` |
| 3 | Crear seguro | CREATE | Registrar seguro | `[ ]` |
| 4 | Actualizar seguro | UPDATE | Modificar seguro | `[ ]` |
| 5 | Ver seguros por vencer | READ | Pólizas próximas a vencer | `[ ]` |

### Camporees

| # | Action | Type | Description | Offline Decision |
|---|--------|------|-------------|-----------------|
| 1 | Ver camporees | READ | Lista de camporees | `[ ]` |
| 2 | Ver detalle | READ | Info del camporee | `[ ]` |
| 3 | Registrar miembro | CREATE | Inscribir miembro | `[ ]` |
| 4 | Ver miembros inscritos | READ | Lista de inscritos | `[ ]` |
| 5 | Remover miembro | DELETE | Desinscribir miembro | `[ ]` |
| 6 | Inscribir club | CREATE | Inscribir sección | `[ ]` |
| 7 | Ver clubes inscritos | READ | Lista de clubes | `[ ]` |
| 8 | Crear pago | CREATE | Registrar pago | `[ ]` |
| 9 | Ver pagos del miembro | READ | Pagos individuales | `[ ]` |
| 10 | Ver pagos del camporee | READ | Todos los pagos | `[ ]` |

### Units (Unidades)

| # | Action | Type | Description | Offline Decision |
|---|--------|------|-------------|-----------------|
| 1 | Ver unidades del club | READ | Lista de unidades | `[ ]` |
| 2 | Ver detalle de unidad | READ | Info de una unidad | `[ ]` |
| 3 | Crear unidad | CREATE | Nueva unidad | `[ ]` |
| 4 | Actualizar unidad | UPDATE | Modificar unidad | `[ ]` |
| 5 | Eliminar unidad | DELETE | Desactivar unidad | `[ ]` |
| 6 | Agregar miembro a unidad | CREATE | Asignar miembro | `[ ]` |
| 7 | Remover miembro de unidad | DELETE | Quitar miembro | `[ ]` |
| 8 | Ver registros semanales | READ | Registros de unidad | `[ ]` |
| 9 | Crear registro semanal | CREATE | Nuevo registro | `[ ]` |
| 10 | Actualizar registro semanal | UPDATE | Modificar registro | `[ ]` |

### Monthly Reports (Informes Mensuales)

| # | Action | Type | Description | Offline Decision |
|---|--------|------|-------------|-----------------|
| 1 | Ver preview de informe | READ | Preview del informe | `[ ]` |
| 2 | Ver informes de inscripción | READ | Informes de la sección | `[ ]` |
| 3 | Ver detalle de informe | READ | Info completa | `[ ]` |
| 4 | Descargar PDF | READ | Obtener URL del PDF | `[ ]` |

### Coordinator (Aprobaciones)

| # | Action | Type | Description | Offline Decision |
|---|--------|------|-------------|-----------------|
| 1 | Ver dashboard SLA | READ | Métricas de SLA | `[ ]` |
| 2 | Ver evidencias pendientes | READ | Evidencias por revisar | `[ ]` |
| 3 | Ver detalle de evidencia | READ | Info de evidencia | `[ ]` |
| 4 | Aprobar evidencia | CREATE | Aprobar envío | `[ ]` |
| 5 | Rechazar evidencia | CREATE | Rechazar envío | `[ ]` |
| 6 | Aprobar evidencias en lote | CREATE | Bulk approve | `[ ]` |
| 7 | Rechazar evidencias en lote | CREATE | Bulk reject | `[ ]` |
| 8 | Ver camporees locales | READ | Lista de camporees | `[ ]` |
| 9 | Ver camporees de unión | READ | Camporees de unión | `[ ]` |
| 10 | Ver aprobaciones pendientes | READ | Pendientes locales | `[ ]` |
| 11 | Ver aprobaciones unión | READ | Pendientes de unión | `[ ]` |
| 12 | Aprobar inscripción de club | CREATE | Aceptar club | `[ ]` |
| 13 | Rechazar inscripción de club | CREATE | Rechazar club | `[ ]` |
| 14 | Aprobar inscripción de miembro | CREATE | Aceptar miembro | `[ ]` |
| 15 | Rechazar inscripción de miembro | CREATE | Rechazar miembro | `[ ]` |
| 16 | Aprobar pago | CREATE | Aceptar pago | `[ ]` |
| 17 | Rechazar pago | CREATE | Rechazar pago | `[ ]` |

### Dashboard

| # | Action | Type | Description | Offline Decision |
|---|--------|------|-------------|-----------------|
| 1 | Ver resumen del dashboard | READ | KPIs y estadísticas | `[ ]` |

### Transfers (Traslados)

| # | Action | Type | Description | Offline Decision |
|---|--------|------|-------------|-----------------|
| 1 | Crear solicitud de traslado | CREATE | Solicitar traslado | `[ ]` |
| 2 | Ver solicitudes | READ | Mis solicitudes | `[ ]` |
| 3 | Ver detalle de traslado | READ | Info de solicitud | `[ ]` |

### Validation (Validación)

| # | Action | Type | Description | Offline Decision |
|---|--------|------|-------------|-----------------|
| 1 | Enviar a revisión | CREATE | Enviar entidad a validar | `[ ]` |
| 2 | Ver historial de validación | READ | Historial de una entidad | `[ ]` |
| 3 | Verificar elegibilidad | READ | Verificar elegibilidad | `[ ]` |

### Certifications (Certificaciones)

| # | Action | Type | Description | Offline Decision |
|---|--------|------|-------------|-----------------|
| 1 | Ver catálogo | READ | Todas las certificaciones | `[ ]` |
| 2 | Ver detalle | READ | Info de certificación | `[ ]` |
| 3 | Ver certificaciones del usuario | READ | Mis certificaciones | `[ ]` |
| 4 | Ver progreso | READ | Progreso de certificación | `[ ]` |
| 5 | Inscribirse | CREATE | Inscribirse en certificación | `[ ]` |
| 6 | Actualizar progreso | UPDATE | Marcar sección completada | `[ ]` |
| 7 | Desinscribirse | DELETE | Desinscribirse | `[ ]` |

### Notifications (Notificaciones)

| # | Action | Type | Description | Offline Decision |
|---|--------|------|-------------|-----------------|
| 1 | Ver historial | READ | Historial de notificaciones | `[ ]` |

---

### Action Summary by Type

| Type | Count | Notes |
|------|-------|-------|
| READ (Consultar) | ~107 | Candidates for Phase 1 cache |
| CREATE (Crear) | ~81 | Need sync queue evaluation per action |
| UPDATE (Modificar) | ~32 | Need conflict risk evaluation |
| DELETE (Eliminar) | ~18 | Must queue, never execute offline |
| UPLOAD (Subir archivo) | ~8 | Need local file queue + upload on reconnect |
| **Total** | **~230+** | |

### Actions by Role

| Role | Count | Notes |
|------|-------|-------|
| Any user | ~87 | Personal progress, profile, classes, honors |
| Director | ~72 | Club management, activities, members, finances |
| Coordinator | ~29 | Approvals, evidence review, camporee mgmt |
| Admin | ~5 | System-level operations |
| Treasurer | ~7 | Financial operations |

---

## Open Questions (Must Answer Before Implementation)

- [ ] Which specific operations MUST work offline? (prioritized list from users/client)
- [ ] What's the typical offline duration? (minutes, hours, days?)
- [ ] How many concurrent offline users per club? (affects conflict probability)
- [ ] Is "last write wins" acceptable for most data, or do users need manual conflict resolution?
- [ ] What's the tolerance for stale data in read-only mode? (hours? days?)
- [ ] Should file evidence (images, PDFs) be available offline or just metadata?
- [ ] Budget/timeline constraints for implementation?

---

## Key Insight

> Phase 1 (read-only offline) resolves 60-70% of the use case with zero backend changes and low risk. Phase 2 is where the real offline value is, but requires the open questions answered first.
