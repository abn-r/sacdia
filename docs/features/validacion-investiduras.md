# Validacion de Investiduras

**Estado**: IMPLEMENTADO

## Descripcion de dominio

La validacion de investiduras es el proceso institucional mediante el cual el avance formativo de un miembro recibe reconocimiento formal. Es el cierre del ciclo formativo: un miembro completa su clase progresiva durante el ano eclesiastico, su progreso es validado por las autoridades del club y del campo local, y finalmente es investido en una ceremonia oficial.

El proceso tiene multiples etapas definidas por el canon: (1) el miembro completa los requisitos de su clase, (2) el consejero o director envia el registro a validacion, (3) el registro queda bloqueado y pasa a revision institucional, (4) la autoridad competente aprueba o rechaza, (5) si es aprobado, se programa la investidura, (6) el miembro es investido formalmente. Este flujo es central para la identidad del sistema — sin validacion de investiduras, SACDIA puede registrar avance pero no puede reconocerlo institucionalmente.

La Decision 6 del canon establece que registrar y validar son actos distintos: la captura operativa (registrar progreso dia a dia) y la validacion institucional (aprobar y reconocer formalmente) tienen actores, momentos y reglas diferentes. Al entrar en validacion, el registro deja de ser editable — esto es un efecto de dominio critico que protege la integridad del proceso.

El schema de base de datos tiene toda la infraestructura preparada (tablas, enums, campos en enrollments). El backend ya implementa el flujo con 5 endpoints via InvestitureModule, pero **ningun cliente (admin ni app) tiene UI para validaciones** — el runtime existe pero es inaccesible para usuarios finales.

## Que existe (verificado contra codigo)

### Backend (InvestitureModule)
- **InvestitureModule implementado** — InvestitureController, InvestitureService, 3 DTOs, registrado en AppModule
- **5 endpoints**:
  - `POST /enrollments/:enrollmentId/submit-for-validation` — enviar a validacion
  - `POST /enrollments/:enrollmentId/validate` — aprobar o rechazar (con body: action + comments)
  - `POST /enrollments/:enrollmentId/investiture` — registrar investidura
  - `GET /admin/investiture/pending` — listar enrollments pendientes de validacion por scope del actor
  - `GET /admin/investiture/history` — historial de validaciones
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
- **Implementado** — Pagina de validaciones con:
  - Tabla de enrollments pendientes de validacion con filtros (estado, año)
  - Botones de accion: Aprobar, Rechazar, Marcar Investido
  - Dialogs de confirmacion con campos de comentarios
  - Timeline de historial de validaciones
  - Badges de estado (SUBMITTED_FOR_VALIDATION, APPROVED, REJECTED, INVESTIDO)
  - Entry en sidebar nav bajo "Administración"

### App (sacdia-app)
- **Implementado** — 3 screens principales:
  - **PendingInvestituresScreen**: lista de enrollments pendientes para coordinadores (filtro por rol)
  - **SubmitInvestitureView**: vista para que directores/consejeros envien a validacion (con confirmation)
  - **InvestitureHistoryScreen**: timeline del historial de validaciones por miembro
  - Data layer con entities, models, datasource, repository, providers
  - Status badge widget reutilizable
  - Routes integradas en GoRouter con transiciones animadas

### Base de datos (schema completo, cero runtime)

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
- IN_PROGRESS, SUBMITTED_FOR_VALIDATION, APPROVED, REJECTED, INVESTIDO

**Enum `investiture_action_enum`**:
- SUBMITTED, APPROVED, REJECTED, REINVESTITURE_REQUESTED

**Enum `evidence_validation_enum`**:
- PENDING, VALIDATED, REJECTED

## Requisitos funcionales

1. Un consejero o director debe poder enviar un enrollment a validacion (cambiar status a SUBMITTED_FOR_VALIDATION)
2. Al enviar a validacion, el enrollment debe bloquearse (locked_for_validation = true) y dejar de ser editable
3. La autoridad validadora (coordinador, admin) debe poder aprobar o rechazar con comentarios
4. Si se rechaza, se debe registrar la razon y el enrollment debe volver a estado editable
5. Si se aprueba, se debe poder programar la fecha de investidura
6. El acto de investidura debe marcar el status como INVESTIDO y registrar la fecha
7. Cada transicion de estado debe quedar registrada en investiture_validation_history con actor, accion, comentarios y timestamp
8. La configuracion de investidura (deadline de envio, fecha de ceremonia) debe ser configurable por campo local y ano eclesiastico
9. Debe existir una vista de administracion que muestre todos los enrollments pendientes de validacion para un campo local
10. El flujo debe respetar la jerarquia de autorizacion: consejero envia, coordinador/admin valida
11. Debe soportarse reinvestidura (REINVESTITURE_REQUESTED) para casos de miembros que necesitan re-evaluacion

## Decisiones de diseno

- **Maquina de estados en enrollments**: El campo `investiture_status` con enum define las transiciones validas: IN_PROGRESS -> SUBMITTED_FOR_VALIDATION -> APPROVED/REJECTED -> INVESTIDO
- **Bloqueo en validacion**: `locked_for_validation` impide edicion de progreso mientras esta en revision — proteccion de integridad de dominio
- **Historia de validacion**: Tabla dedicada `investiture_validation_history` con audit trail completo de cada accion
- **Configuracion por campo local**: `investiture_config` permite que cada campo local defina sus propias fechas de deadline y ceremonia por ano eclesiastico
- **Separacion de registrar y validar** (Decision 6): Actores diferentes (consejero vs coordinador), momentos diferentes, reglas diferentes

## Gaps y pendientes

- No hay UI para configurar investiture_config (deadlines y fechas por campo local) — Iteracion 2
- No hay notificaciones asociadas a cambios de estado de validacion — Iteracion 2
- No hay reportes de investiduras por periodo/campo local/club — Iteracion 2

## Implementacion completada

- ✅ Backend: InvestitureModule con 7 endpoints (5 individuales + 2 bulk), 23 tests
- ✅ Admin: Tabla de validaciones, dialogs de accion, historial, filtros, bulk operations con checkboxes y floating action bar
- ✅ App: 3 screens (pending list, submit view, history timeline), data layer completa, GoRouter integration
- ✅ Bulk operations: Hasta 200 enrollments por operacion, partial success handling, race condition protection (ver [aprobaciones-masivas](aprobaciones-masivas.md))
