# Gestion de Seguros (Insurance)

**Estado**: IMPLEMENTADO (modelo previo en `development`); modelo anual Pendiente de merge (sacdia-backend PR #664, sacdia-app PR #260, sacdia-admin PR #307)

## Descripcion de dominio

El seguro institucional cubre a las personas de una sección de club (miembros y directiva) en actividades de riesgo: campamentos, caminatas, orden cerrado y camporees. Desde la decisión de producto del 2026-11-17 el seguro es **anual por año eclesiástico y uno por persona**: lo cobra el Campo Local, el Campo Local fija el precio de cada año (`insurance_cycle_configs`) y la cobertura dura hasta el `ecclesiastical_years.end_date` del ciclo (no 12 meses desde el pago). La cobertura pertenece al club: si el titular se va, la directiva de la sección la reasigna directamente.

> **Pendiente de merge (sacdia-backend PR #664, sacdia-app PR #260, sacdia-admin PR #307).** Todo lo marcado «modelo anual» describe ramas sin integrar a `development`. La sección «Modelo previo (development)» al final conserva lo que sigue vigente hasta el merge.

## Modelo anual (Pendiente de merge)

### Reglas

- **Pago**: el director emite una orden de pago (`POST /insurance/payment-orders`) que nombra beneficiarios (miembros **y** directiva de la sección), paga al Campo Local (caja, pastor de distrito o transferencia), sube el comprobante y el Campo Local aprueba (maker-checker). Detalle de la orden en [ordenes-de-pago.md](ordenes-de-pago.md).
- **Vigencia**: `valid_until` = `end_date` del año eclesiástico del ciclo. Emitir sobre un ciclo cuyo año ya terminó responde 400 `FIELD_PAYMENT_ORDER_CYCLE_INVALID` (`cycle_year_ended`).
- **Una cobertura por persona y año**: nadie puede estar cubierto dos veces en el mismo año eclesiástico (en cualquier sección, club o Campo Local), ni figurar en dos órdenes vivas o pagadas del año (`ISSUED`, `PROOF_SUBMITTED`, `PROOF_REJECTED`, `APPROVED`). Las líneas de orden de seguro guardan `purpose_ref_id` = id del año eclesiástico para sostener la regla. Si se viola: 409 `FIELD_PAYMENT_ORDER_DUPLICATE_BENEFICIARY` con `data.conflicts[]` (`user_id`, `name`, `reason` = `already_covered` | `in_live_order`, `section_name`, `club_name`, `folio`, y `valid_until` u `order_status` según el caso).
- **Sin flag para seguros**: la emisión de órdenes de seguro ya no depende de `field_payment_orders_v1` (el flag solo rige camporees).
- **Cobertura** siempre significa una `insurance_assignments` `ACTIVE`; `member_insurances` es solo el puente que usa camporees (se hace upsert al aprobar y se mueve al reasignar).

### Reasignación directa

`POST /insurance/reassignments` (permiso `field-payment-orders:create`) la ejecuta de inmediato la directiva de la sección; no pasa por el Campo Local. La fila de `insurance_reassignment_requests` se guarda `APPROVED` (revisor = actor) solo como auditoría. Condiciones (400 `INSURANCE_REASSIGNMENT_INVALID` con `reason`): cobertura `ACTIVE` de un miembro y vigente (`assignment_not_active_member`, `assignment_expired`, `assignment_not_current_year`), titular distinto del destino (`same_user`), **el titular ya salió del club** (`holder_still_in_club`), destino activo en la misma sección (`destination_not_in_section`) y sin cobertura ni orden viva del año (409 `DUPLICATE_BENEFICIARY`). Mueve el assignment, registra el movimiento `REASSIGNED` y mueve el puente `member_insurances`. `approve` y `reject` quedan solo para filas `PENDING` heredadas. `GET /insurance/reassignments` ahora incluye `from_user_name`, `to_user_name`, `requested_by_name` y `reviewed_by_name`.

### Endpoints nuevos (`insurance-coverage.controller.ts`)

Ambos con `insurance:read` sobre `club_section`.

- `GET /club-sections/:sectionId/insurance/overview` -> `data`: `year` (`ecclesiastical_year_id`, `label`, `start_date`, `end_date`) o `null`; `cycle` (`insurance_cycle_config_id`, `unit_cost`, `purchase_deadline`, `currency`) o `null`; `counts` (`total`, `covered`, `in_process`, `uninsured`); `free_coverages_count`; `people[]` con `user_id`, `name`, `picture`, `role_label`, `is_staff`, `status` (`covered` | `in_order` | `in_review` | `proof_rejected` | `uninsured`), `coverage` (`source` = `paid_here` | `paid_elsewhere` | `reassigned`, sección/club de pago, folio, `approved_at`, `valid_until`, datos de reasignación) y `active_order` (`order_id`, `folio`, `status`, `expires_at`).
- `GET /club-sections/:sectionId/insurance/free-coverages` -> `data: { count, items[] }`; cada item trae `insurance_assignment_id`, `holder`, `valid_until`, `order_id`, `order_folio` y `left_at`: coberturas vigentes cuyo titular ya no está en el club (reasignables).

### Pendientes del dashboard

`GET /dashboard/pending` agrega, solo para quien tiene `field-payment-orders:create` y si el Campo Local tiene ciclo activo: `uninsured_members` (`count`, `due_date` = `purchase_deadline`, `days_left`; `warning` hasta el plazo inclusive, `urgent` después) y `free_insurance` (`count`, `info`).

### Retirado

- `POST /users/:memberId/insurance`, `PATCH /insurance/:insuranceId` y `POST /club-sections/:sectionId/insurance/purchases` responden siempre 409 `FIELD_PAYMENT_ORDER_LEGACY_DISABLED`. Ya no hay alta manual (póliza, aseguradora y fechas libres) ni compras por cantidad.
- Admin: la página «Por vencer» y el formulario/diálogo de alta, edición y borrado de seguros.
- App: el registro manual de seguros.
- Las lecturas `GET .../members/insurance`, `GET /users/:memberId/insurance` y `GET /insurance/expiring` siguen en backend.

### Superficies

- **Admin**: Seguros > «Por sección» es de solo lectura sobre `overview`; la pestaña de reasignaciones en `/dashboard/payment-orders` es un historial con nombres; el formulario de productos usa los enums correctos (`GENERAL` | `EVENT`, `FIXED_MONTHS` | `EVENT_DATES`).
- **App**: un solo flujo en `lib/features/insurance/`: resumen en inicio y «Por atender», lista de miembros y directiva, «Asegurar» (emisión de orden), detalle de orden que muestra solo el estado actual con una hoja con todos los estados, lista de órdenes, cobertura por persona y «Reasignar».
- Idempotency-Key de emisión debe ser UUID (400 `VALIDATION_FAILED`, `idempotency_key_not_uuid`); los ids de beneficiario y destino aceptan cualquier versión de UUID.

## Modelo previo (development, hasta el merge)

### Backend (InsuranceModule)
- **Controller**: `src/insurance/insurance.controller.ts`; service `src/insurance/insurance.service.ts`; DTOs en `src/insurance/dto/`.
- **Guards**: `JwtAuthGuard` + `PermissionsGuard`; `GET /api/v1/insurance/expiring` agrega `GlobalRolesGuard`.
- Alta y edición legacy: `POST /users/:memberId/insurance` y `PATCH /insurance/:insuranceId` (multipart, campo `evidence`), consumidos por admin y app. Compras por cantidad: `POST|GET /club-sections/:sectionId/insurance/purchases` + detalle/proof/confirm/reject/reverse (no nombran beneficiarios).
- Config por Campo Local (`insurance:configure`): `GET|POST /insurance/products`, `PATCH /insurance/products/:id`, `GET|POST /insurance/cycles`, `PATCH /insurance/cycles/:id`. Director y asistente de campo local configuran su propio campo (otro -> 403); super-admin y admin usan `?local_field_id=`.
- En `development` el flag `field_payment_orders_v1` bloquea el alta legacy por Campo Local; el modelo anual lo reemplaza por un bloqueo incondicional.

### Órdenes de pago territoriales (en development)

Módulo `src/field-payment-orders/`: emisión con beneficiarios nombrados, PDF con instrucciones de pago, comprobante, revisión LF con maker-checker y materialización (compra `CONFIRMED` + slot + assignment `ACTIVE` + upsert bridge a `member_insurances`), expiración perezosa (`field_payment_orders.expiry_days`, 15 por defecto) y eventos `field_payment_order.*`. Las reasignaciones en `development` son por solicitud con aprobación del Campo Local. Ver [ordenes-de-pago.md](ordenes-de-pago.md).

### Runbook piloto por Campo Local (operación humana)

1. Crear `insurance_products` + `insurance_cycle_configs` del Campo Local (admin > Seguros > Configuración, `insurance:configure`) con `unit_cost` y `purchase_deadline` del año vigente.
2. Capturar `field_payment_order_configs` (banco y/o caja). Sin config activa el PDF falla con `FIELD_PAYMENT_ORDER_CONFIG_NOT_FOUND`.
3. Verificar el seed de `field-payment-orders:*` (`prisma/seeds/permissions.seed.sql` + `role-permissions.seed.sql`).
4. En `development`: agregar el `local_field_id` a `system_config.field_payment_orders_v1`. Con el modelo anual este paso solo importa para camporees.
5. Resolver las `insurance_purchases` en `PENDING_CONFIRMATION` antes de migrar para no dejar compras huérfanas.

### Base de datos
- `member_insurances` — Seguros por miembro con campos:
  - `insurance_id` (PK INT), `user_id` (FK UUID), `insurance_type` (ENUM), `policy_number`, `provider`, `start_date`, `end_date`, `coverage_amount` (DECIMAL), `active`, `evidence_file_url`, `evidence_file_name`
  - Auditoria: `created_by_id` (FK UUID), `modified_by_id` (FK UUID)
- Relacion con `camporee_members` via `insurance_id`

### Storage
- Evidencia de seguros se almacena en Cloudflare R2, bucket `INSURANCE_EVIDENCE`

## Requisitos funcionales

1. Un seguro por persona (miembro o directiva) y año eclesiástico, con vigencia hasta el fin de ese año
2. El precio lo fija el Campo Local por año y tipo de club
3. Se paga con una orden que nombra beneficiarios y el Campo Local aprueba el comprobante
4. La cobertura pertenece al club y se reasigna directamente cuando el titular se va
5. La sección ve su estado anual (cubiertos, en proceso, sin seguro) y recibe avisos de plazo
6. Camporees sigue validando la cobertura vía `member_insurances` (puente)

## Decisiones de diseno

- **Modelo anual (2026-11-17)**: reemplaza el alta manual y las compras por cantidad; ver [DECISIONS-PENDING](../audit/DECISIONS-PENDING.md).
- **Cobertura = assignment `ACTIVE`**; `member_insurances` queda como puente para camporees.
- **Reasignación directa** sin aprobación del Campo Local; la auditoría queda en `insurance_reassignment_requests`.
- **Evidencia en R2** (bucket `INSURANCE_EVIDENCE`) solo aplica a los registros legacy existentes.

## Gaps y pendientes

- Sin notificaciones push ni correo de vencimiento o de plazo; solo el pendiente del dashboard.
- El plan [2026-07-23-insurance-capacity-redesign-design.md](../plans/2026-07-23-insurance-capacity-redesign-design.md) queda superado por el modelo anual donde difiera (cupos libres entre secciones, compras por cantidad, componente de ranking `insurance_purchase_timeliness` sin implementar).
- Falta decidir el destino de las tablas y endpoints de compras por cantidad (hoy solo lectura funcional).
