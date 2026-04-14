# Validacion de Investiduras

**Estado**: IMPLEMENTADO

## Descripcion de dominio

La validacion de investiduras es el proceso institucional mediante el cual el avance formativo de un miembro recibe reconocimiento formal. Es el cierre del ciclo formativo: un miembro completa su clase progresiva durante el ano eclesiastico, su progreso es validado por las autoridades del club y del campo local, y finalmente es investido en una ceremonia oficial.

El proceso tiene multiples etapas definidas por el canon: (1) el miembro completa los requisitos de su clase, (2) el consejero o director envia el registro a validacion, (3) el registro queda bloqueado y pasa a revision institucional, (4) la autoridad competente aprueba o rechaza, (5) si es aprobado, se programa la investidura, (6) el miembro es investido formalmente. Este flujo es central para la identidad del sistema — sin validacion de investiduras, SACDIA puede registrar avance pero no puede reconocerlo institucionalmente.

La Decision 6 del canon establece que registrar y validar son actos distintos: la captura operativa (registrar progreso dia a dia) y la validacion institucional (aprobar y reconocer formalmente) tienen actores, momentos y reglas diferentes. Al entrar en validacion, el registro deja de ser editable — esto es un efecto de dominio critico que protege la integridad del proceso.

El schema de base de datos y el runtime ya sostienen investiduras como superficie activa. El backend expone flujo multietapa, compatibilidad legacy, operaciones bulk y CRUD de configuracion; el admin tiene pantallas ruteadas para pendientes, pipeline y configuracion; la app tiene pantallas ruteadas para pendientes e historial, pero la vista de envio a validacion existe en codigo y hoy NO esta ruteada.

## Que existe (verificado contra codigo)

### Backend (InvestitureModule)
- **InvestitureModule implementado** — `InvestitureController`, `InvestitureService`, DTOs de pipeline/config/bulk, registrado en `AppModule`
- **Superficie canonica activa**:
  - `POST /investiture/enrollments/:enrollmentId/submit`
  - `POST /investiture/enrollments/:enrollmentId/club-approve`
  - `POST /investiture/enrollments/:enrollmentId/coordinator-approve`
  - `POST /investiture/enrollments/:enrollmentId/field-approve`
  - `POST /investiture/enrollments/:enrollmentId/invest`
  - `POST /investiture/enrollments/:enrollmentId/reject`
  - `GET /investiture/pending`
  - `GET /investiture/enrollments/:enrollmentId/history`
  - `POST /investiture/enrollments/bulk-approve`
  - `POST /investiture/enrollments/bulk-reject`
  - `GET|POST|PATCH|DELETE /admin/investiture/config`
- **Compatibilidad legacy aun activa**:
  - `POST /enrollments/:enrollmentId/submit-for-validation`
  - `POST /enrollments/:enrollmentId/validate`
  - `POST /enrollments/:enrollmentId/investiture`
  - `GET /enrollments/:enrollmentId/investiture-history`
- El `enrollments` model en Prisma tiene campos de investidura expuestos via los endpoints anteriores:
  - `investiture_status` (investiture_status_enum)
  - `submitted_for_validation` (Boolean, default false)
  - `submitted_at` (DateTime?)
  - `validated_by` (UUID?)
  - `validated_at` (DateTime?)
  - `rejection_reason` (String?)
  - `investiture_date` (DateTime?)
  - `locked_for_validation` (Boolean, default false)

### Admin (sacdia-admin)
- **Implementado y ruteado** — paginas y navegacion activas en:
  - `/dashboard/investiture` — pendientes con acciones legacy de validar/marcar investido
  - `/dashboard/investiture/pipeline` — pipeline multietapa (`club-approve`, `coordinator-approve`, `field-approve`, `reject`, `invest`)
  - `/dashboard/investiture/config` — CRUD de `investiture_config`
  - Entry en sidebar bajo "Investiduras"

### App (sacdia-app)
- **Implementado parcialmente y con ruteo mixto**:
  - `InvestiturePendingListView` esta ruteada en GoRouter (`/investiture/pending`) y permite aprobar/rechazar/marcar investido segun rol
  - `InvestitureHistoryView` esta ruteada en GoRouter (`/investiture/enrollment/:enrollmentId/history`)
  - `InvestitureSubmitView` existe en codigo y ejecuta `submit-for-validation`, pero hoy NO tiene ruta registrada en GoRouter
  - Data layer, providers y widgets de estado existen para submit, pending e history

### Base de datos (schema y runtime alineados)

**Tabla `investiture_validation_history`**:
- `history_id` (INT, PK)
- `enrollment_id` (INT, FK -> enrollments)
- `action` (investiture_action_enum)
- `performed_by` (UUID, FK -> users)
- `comments` (String?)
- `created_at` (DateTime)
- Indice: idx_investiture_history_enrollment

**Tabla `investiture_config`**:
- `config_id` (INT, PK)
- `local_field_id` (INT, FK -> local_fields)
- `ecclesiastical_year_id` (INT, FK -> ecclesiastical_years)
- `submission_deadline` (Date) — fecha limite de envio a validacion
- `investiture_date` (Date) — fecha de ceremonia de investidura
- `active` (Boolean)
- UNIQUE: (local_field_id, ecclesiastical_year_id)

**Enum `investiture_status_enum`**:
- IN_PROGRESS, SUBMITTED_FOR_VALIDATION, CLUB_APPROVED, COORDINATOR_APPROVED, FIELD_APPROVED, APPROVED, REJECTED, INVESTIDO

**Enum `investiture_action_enum`**:
- SUBMITTED, CLUB_APPROVED, COORDINATOR_APPROVED, FIELD_APPROVED, APPROVED, REJECTED, REINVESTITURE_REQUESTED, INVESTIDO

**Enum `evidence_validation_enum`**:
- PENDING, VALIDATED, REJECTED

## Requisitos funcionales

1. Un consejero o director debe poder enviar un enrollment a validacion (cambiar status a SUBMITTED_FOR_VALIDATION)
2. Al enviar a validacion, el enrollment debe bloquearse (locked_for_validation = true) y dejar de ser editable
3. Las autoridades del flujo (director de seccion, coordinacion, admin/campo local) deben poder aprobar o rechazar segun la etapa correspondiente
4. Si se rechaza, se debe registrar la razon y el enrollment debe volver a estado editable
5. Si se aprueba, se debe poder programar la fecha de investidura
6. El acto de investidura debe marcar el status como INVESTIDO y registrar la fecha
7. Cada transicion de estado debe quedar registrada en investiture_validation_history con actor, accion, comentarios y timestamp
8. La configuracion de investidura (deadline de envio, fecha de ceremonia) debe ser configurable por campo local y ano eclesiastico
9. Debe existir una vista de administracion que muestre todos los enrollments pendientes de validacion para un campo local
10. El flujo debe respetar la jerarquia de autorizacion: consejero/director envia, director aprueba a nivel club, coordinacion aprueba su etapa y admin/campo local completa la autorizacion final
11. Debe soportarse reinvestidura (REINVESTITURE_REQUESTED) para casos de miembros que necesitan re-evaluacion

## Decisiones de diseno

- **Maquina de estados en enrollments**: El campo `investiture_status` define el pipeline vigente: IN_PROGRESS -> SUBMITTED_FOR_VALIDATION -> CLUB_APPROVED -> COORDINATOR_APPROVED -> FIELD_APPROVED -> INVESTIDO, con `REJECTED` como salida de correccion
- **Bloqueo en validacion**: `locked_for_validation` impide edicion de progreso mientras esta en revision — proteccion de integridad de dominio
- **Historia de validacion**: Tabla dedicada `investiture_validation_history` con audit trail completo de cada accion
- **Configuracion por campo local**: `investiture_config` permite que cada campo local defina sus propias fechas de deadline y ceremonia por ano eclesiastico
- **Separacion de registrar y validar** (Decision 6): Actores diferentes (consejero vs coordinador), momentos diferentes, reglas diferentes

## Gaps y pendientes

- `InvestitureSubmitView` existe en app pero no esta expuesta por una ruta registrada
- No hay notificaciones asociadas a cambios de estado de validacion — Iteracion 2
- No hay reportes de investiduras por periodo/campo local/club — Iteracion 2

## Implementacion completada

- ✅ Backend: modulo activo con pipeline multietapa, compat legacy, bulk ops y CRUD de configuracion
- ✅ Admin: pendientes, pipeline y configuracion accesibles desde rutas del dashboard y sidebar
- ✅ App: pending/history ruteados; submit view implementada pero no ruteada
- ✅ Bulk operations: hasta 200 enrollments por operacion; `club-approve` sigue siendo individual
