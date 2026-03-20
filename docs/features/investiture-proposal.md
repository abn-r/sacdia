# Propuesta: Validación de Investiduras

**Estado**: PROPUESTA — aprobada para implementación
**Feature ID**: #23
**Fecha**: 2026-03-20
**Autor**: Arquitectura SACDIA

---

## Resumen ejecutivo

Implementar el flujo completo de validación de investiduras en el backend de SACDIA. La infraestructura de base de datos existe en su totalidad (tablas, enums, campos en `enrollments`), pero no hay ningún módulo, controlador, servicio ni endpoint en runtime. El MVP consiste en 5 endpoints que cubren el ciclo completo: envío por parte del club, validación institucional por coordinador/admin, registro de la investidura y auditoría del proceso.

---

## Problema

SACDIA puede registrar el avance formativo de un miembro (clases progresivas, honores, especialidades), pero **no puede validarlo ni reconocerlo institucionalmente**. Sin este flujo, todo el progreso capturado queda sin cierre: no hay investidura, no hay reconocimiento formal, no hay trazabilidad del proceso de aprobación. El gap es crítico para la operación de los clubes al cierre del año eclesiástico.

---

## Solución propuesta

Crear `InvestitureModule` en el backend NestJS con los servicios, controladores y guards necesarios para ejecutar la máquina de estados de validación. El módulo orquesta las transiciones de estado en `enrollments`, registra cada acción en `investiture_validation_history` y expone una API REST versionada bajo `/api/v1/`.

---

## Estado actual (DB existente)

La base de datos ya tiene toda la infraestructura lista. No se requieren migraciones para el MVP.

**Campos relevantes en `enrollments`**:
- `investiture_status` — enum `investiture_status_enum`
- `locked_for_validation` — Boolean (bloqueo de edición durante revisión)
- `submitted_for_validation` — Boolean
- `submitted_at` — DateTime?
- `validated_by` — UUID?
- `validated_at` — DateTime?
- `rejection_reason` — String?
- `investiture_date` — DateTime?

**Tablas auxiliares**:
- `investiture_validation_history` — audit trail completo (enrollment_id, action, performed_by, comments, created_at)
- `investiture_config` — configuración por campo local y año eclesiástico (submission_deadline, investiture_date, active)

**Enums existentes**:
- `investiture_status_enum`: `IN_PROGRESS`, `SUBMITTED_FOR_VALIDATION`, `APPROVED`, `REJECTED`, `INVESTIDO`
- `investiture_action_enum`: `SUBMITTED`, `APPROVED`, `REJECTED`, `REINVESTITURE_REQUESTED`

---

## Máquina de estados

```
IN_PROGRESS
    │
    │ submit-for-validation (director / counselor)
    ▼
SUBMITTED_FOR_VALIDATION
    │
    ├─── APPROVED (admin / coordinator)
    │         │
    │         │ investiture (admin / coordinator)
    │         ▼
    │       INVESTIDO
    │
    └─── REJECTED (admin / coordinator, con comentarios)
              │
              │ edición habilitada — re-submit
              ▼
         SUBMITTED_FOR_VALIDATION  ← ciclo de corrección
```

**Reglas de transición**:
- Solo `IN_PROGRESS` puede enviarse a validación. Cualquier otro estado bloquea el envío.
- `REJECTED` desbloquea el enrollment para edición (`locked_for_validation = false`).
- El re-envío desde `REJECTED` transiciona a `SUBMITTED_FOR_VALIDATION` (no crea un nuevo enrollment).
- `INVESTIDO` es estado terminal — no hay retroceso en el MVP.

---

## Endpoints MVP

### 1. Enviar a validación
```
POST /api/v1/enrollments/:enrollmentId/submit-for-validation
```
- **Guard**: `ClubRolesGuard` — roles `director`, `counselor`
- **Precondición**: `investiture_status = IN_PROGRESS` o `REJECTED`
- **Efecto**: `investiture_status → SUBMITTED_FOR_VALIDATION`, `locked_for_validation = true`, `submitted_at = now()`
- **Registra en history**: action `SUBMITTED`

### 2. Validar (aprobar o rechazar)
```
POST /api/v1/enrollments/:enrollmentId/validate
Body: { action: "APPROVED" | "REJECTED", comments?: string }
```
- **Guard**: `GlobalRolesGuard` — roles `admin`, `coordinator`
- **Precondición**: `investiture_status = SUBMITTED_FOR_VALIDATION`
- **Efecto APPROVED**: `investiture_status → APPROVED`, `validated_by = actorId`, `validated_at = now()`
- **Efecto REJECTED**: `investiture_status → REJECTED`, `locked_for_validation = false`, `rejection_reason = comments`
- **Registra en history**: action `APPROVED` o `REJECTED`

### 3. Registrar investidura
```
POST /api/v1/enrollments/:enrollmentId/investiture
Body: { investiture_date: string (ISO date) }
```
- **Guard**: `GlobalRolesGuard` — roles `admin`, `coordinator`
- **Precondición**: `investiture_status = APPROVED`
- **Efecto**: `investiture_status → INVESTIDO`, `investiture_date = investiture_date`, auto-sync `users_classes.investiture = true`
- **Registra en history**: action `SUBMITTED` (acción de investidura final)

### 4. Listar pendientes de validación
```
GET /api/v1/investiture/pending
```
- **Guard**: `GlobalRolesGuard` — roles `admin`, `coordinator`
- **Scope**: filtrado por `local_field_id` del actor autenticado
- **Retorna**: enrollments con `investiture_status = SUBMITTED_FOR_VALIDATION`, paginados

### 5. Historial de investidura
```
GET /api/v1/enrollments/:enrollmentId/investiture-history
```
- **Guard**: `ClubRolesGuard` OR `GlobalRolesGuard`
- **Retorna**: registros de `investiture_validation_history` ordenados por `created_at ASC`

---

## Endpoints iteración 2

Los siguientes endpoints quedan fuera del MVP pero son necesarios para operación completa:

- `GET /api/v1/investiture/config` — listar configuraciones por campo local
- `POST /api/v1/investiture/config` — crear configuración (admin)
- `PUT /api/v1/investiture/config/:configId` — actualizar deadline/fecha de ceremonia
- Flujo `REINVESTITURE_REQUESTED` — re-investidura para casos de re-evaluación institucional
- Dashboard/reporte de investiduras por período, campo local y club

---

## Decisiones de diseño

| Decisión | Descripción |
|---|---|
| **REJECTED no descarta** | `REJECTED` conserva el enrollment con estado + unlock para edición. El re-envío reutiliza el mismo enrollment (no se crea uno nuevo). Historia completa preservada. |
| **submission_deadline es soft** | La fecha límite de envío emite advertencia ("tardío") pero no bloquea el envío. Las solicitudes tardías se marcan y requieren validación igualmente. |
| **investiture_date sincronizada** | `enrollment.investiture_date` siempre iguala a `investiture_config.investiture_date` — investidura grupal por ceremonia, no por miembro individual. |
| **Auto-sync users_classes** | Al alcanzar `INVESTIDO`, se sincroniza `users_classes.investiture = true` para compatibilidad con la app Flutter actual. TODO: migrar a lectura exclusiva de enrollments cuando la app toque el feature de clases. |
| **REINVESTITURE_REQUESTED fuera del MVP** | El enum ya existe en DB pero el flujo no se implementa en esta iteración. |

---

## Dependencias e integración

- **Módulo `EnrollmentsModule`**: El nuevo módulo depende de él para leer y actualizar `enrollments`.
- **Módulo `UsersClassesModule`**: Para el auto-sync de `users_classes.investiture` al investir.
- **`ClubRolesGuard` / `GlobalRolesGuard`**: Guards existentes — no requieren modificación.
- **Prisma**: Todos los modelos y enums ya están definidos en `schema.prisma`.
- **`ecclesiastical_years`**: Necesario para consultar `investiture_config` activa del período en curso.

---

## Riesgos

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Auto-sync `users_classes` puede romper app Flutter si se usa el campo para lógica de clases | Media | Alto | Documentar el TODO y no tocar la lectura de `users_classes` en Flutter hasta migrar |
| Un coordinator con scope incorrecto puede ver enrollments de otro campo local | Media | Alto | Filtrar siempre por `local_field_id` del actor en el endpoint `pending` |
| Investidura doble (ejecutar endpoint dos veces sobre el mismo enrollment) | Baja | Medio | Validar precondición estricta: solo `APPROVED` puede transicionar a `INVESTIDO` |
| `investiture_config` inexistente para un campo local al intentar investir | Alta | Medio | Manejo explícito: 404 descriptivo si no existe config activa para el campo/año |

---

## Criterios de aceptación

1. Un director o consejero puede enviar un enrollment `IN_PROGRESS` a `SUBMITTED_FOR_VALIDATION`; el enrollment queda bloqueado para edición.
2. Un admin o coordinador puede aprobar (`APPROVED`) o rechazar (`REJECTED`) un enrollment enviado; el rechazo incluye comentario obligatorio y desbloquea el enrollment.
3. Un enrollment rechazado puede ser reenviado a validación por el director/consejero, pasando nuevamente a `SUBMITTED_FOR_VALIDATION`.
4. Un admin o coordinador puede registrar la investidura de un enrollment `APPROVED`, llevándolo a `INVESTIDO` con fecha.
5. Al investir, `users_classes.investiture` se sincroniza a `true` para el usuario correspondiente.
6. Cada transición de estado genera un registro en `investiture_validation_history` con actor, acción, comentarios opcionales y timestamp.
7. El endpoint `pending` retorna solo enrollments del `local_field_id` del actor autenticado.
8. Todos los endpoints respetan los guards de roles documentados; requests con roles incorrectos retornan 403.
9. Una solicitud enviada después del `submission_deadline` se permite pero el enrollment queda marcado como tardío en la respuesta.
