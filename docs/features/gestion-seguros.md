# Gestion de Seguros (Insurance)

**Estado**: IMPLEMENTADO

## Descripcion de dominio

El seguro institucional es un requisito administrativo para la participacion de miembros en actividades de riesgo dentro de los clubes de Conquistadores, Aventureros y Guias Mayores. Los clubes operan en contextos donde los miembros (muchos de ellos menores de edad) realizan actividades al aire libre que implican riesgo: campamentos, caminatas, escalada, actividades acuaticas, orden cerrado, y especialmente camporees competitivos.

El sistema contempla tres tipos de seguro segun el enum `insurance_type_enum`: GENERAL_ACTIVITIES (cobertura general para reuniones y actividades regulares), CAMPOREE (cobertura especifica para participacion en camporees), y HIGH_RISK (cobertura para actividades de alto riesgo como rapel, escalada, etc.). Cada seguro documenta la poliza, aseguradora, vigencia, monto de cobertura y puede incluir evidencia documental adjunta (archivo de poliza escaneado).

La vinculacion de seguros con camporees es directa: la tabla `camporee_members` referencia `member_insurances`, lo que permite validar que un miembro tiene cobertura vigente al momento de inscribirse en un evento. El modulo forma parte de la dimension administrativa de la trayectoria del miembro dentro de la institucion.

## Que existe (verificado contra codigo)

### Backend (InsuranceModule)
- **Controller**: `src/insurance/insurance.controller.ts`
- **Service**: `src/insurance/insurance.service.ts`
- **Module**: `src/insurance/insurance.module.ts`
- **DTOs**: `src/insurance/dto/`
- **Guards**: `JwtAuthGuard` + `PermissionsGuard` en toda la superficie; `GET /api/v1/insurance/expiring` agrega `GlobalRolesGuard`
- **5 endpoints**:
  - `GET /api/v1/clubs/:clubId/sections/:sectionId/members/insurance` — Requiere `insurance:read` y `AuthorizationResource({ type: 'club' })`
  - `GET /api/v1/insurance/expiring` — Seguros proximos a vencer; requiere rol global `admin` o `coordinator` y acepta `days_ahead` / `local_field_id`
  - `GET /api/v1/users/:memberId/insurance` — Requiere `insurance:read` y `AuthorizationResource({ type: 'active_assignment' })`
  - `POST /api/v1/users/:memberId/insurance` — Requiere `insurance:create`; crea seguro con evidencia opcional (multipart, campo `evidence`)
  - `PATCH /api/v1/insurance/:insuranceId` — Requiere `insurance:update`; actualiza seguro existente con evidencia opcional (multipart)

### Admin
- **UI funcional**: `/dashboard/insurance` y `/dashboard/insurance/expiring`
- **Capacidades verificadas**: seleccion de club/seccion, tabla de miembros con estado del seguro, alta/edicion/desactivacion de seguros, alerta de vencimientos y vista dedicada de proximos vencimientos
- **Consumo verificado**: `GET /clubs/:clubId/sections/:sectionId/members/insurance`, `POST /users/:memberId/insurance`, `PATCH /insurance/:insuranceId`, `GET /insurance/expiring`

### App Movil
- **3 screens principales**: InsuranceView, InsuranceDetailView, InsuranceFormSheet
- Consume listado/detalle/alta/actualizacion; el datasource remoto conserva `GET /insurance/expiring`, pero la alerta actual de vencimientos se deriva localmente desde la lista ya cargada
- Soporta carga de evidencia documental
- Espera campos `evidence_file_url` y `evidence_file_name` en las respuestas

### Backend — capacity model (dual-path, verificado 2026-08-12)

Además del flujo legacy `member_insurances`, el backend tiene un **modelo de capacidad** completo sin UI:

- **Config por Campo Local**: `insurance_products` + `insurance_cycle_configs` (costo unitario por producto/año/tipo de club) vía `InsuranceConfigService` con permiso `insurance:configure`. Endpoints: `GET|POST /insurance/products`, `PATCH /insurance/products/:id`, `GET|POST /insurance/cycles`, `PATCH /insurance/cycles/:id`.
- **Compras qty**: `POST|GET /club-sections/:sectionId/insurance/purchases` + detalle/proof/confirm/reject/reverse (`InsurancePurchasesService`). Compra anónima por cantidad → comprobante → `PENDING_CONFIRMATION` → confirm materializa `insurance_coverage_slots` `AVAILABLE`. **No nombra beneficiarios**.
- **Asignaciones**: `insurance_assignments` existe en schema con domain helpers (`src/insurance/domain/insurance-policy.ts`), pero **sin API HTTP de assign**.

**Dual-path vigente**:

| Vía | Tablas | Estado |
|-----|--------|--------|
| Legacy directa | `member_insurances` | Activa; app/admin la usan; camporees exige su FK |
| Capacity model | products/cycles/purchases/slots/assignments | Backend-only; purchases qty **legado a reemplazar** por órdenes de pago con beneficiarios nombrados (`field_payment_orders`) |

El plan `docs/plans/2026-08-05-insurance-camporee-payment-orders-plan.md` cierra el gap: órdenes grupales con beneficiarios → aprobación LF → slot + assignment ACTIVE + upsert bridge a `member_insurances`.

### Órdenes de pago territoriales (IMPLEMENTADO 2026-08-12)

Módulo `src/field-payment-orders/` (branch `feat/field-payment-orders` en los tres repos):

- **Emisión**: `POST /insurance/payment-orders` (ciclo + beneficiarios nombrados, permiso `field-payment-orders:create`). Valida ciclo activo del LF/club_type, membresía activa en la sección, sin cobertura activa duplicada y sin otra orden activa del mismo beneficiario (unique parcial `active_guard`). Folio secuencial `ORD{year}{####}` por LF con `FOR UPDATE`.
- **Documento**: `GET /payment-orders/:id/document` genera PDF (PDFKit) con beneficiarios, totales e instrucciones de pago del LF (`field_payment_order_configs`: banco y/o caja del campo; se configura en admin → Seguros → Configuración).
- **Comprobante**: `POST /payment-orders/:id/proof` (multipart, PDF/JPG/PNG ≤10 MB con magic bytes, R2). Estado `ISSUED → PROOF_SUBMITTED`.
- **Revisión LF**: bandeja `GET /payment-orders/review-queue`; `approve` exige maker-checker (quien subió el comprobante no puede aprobar) y materializa en la misma transacción: `insurance_purchases` CONFIRMED + `insurance_coverage_slots` + `insurance_assignments` ACTIVE + slot movements + **upsert bridge a `member_insurances`** (camporees sigue funcionando). `reject` requiere motivo y permite re-subir.
- **Expiración**: lazy expiry al listar/leer; órdenes `ISSUED` vencidas pasan a `EXPIRED` y liberan `active_guard`.
- **Reasignaciones**: `POST/GET /insurance/reassignments` + approve/reject. Transferencia de cobertura activa entre miembros del mismo club; aprueba LF; mueve el assignment y registra slot movement.
- **Superficies**: admin (`/dashboard/payment-orders` bandeja + reasignaciones; `/dashboard/insurance/config` productos/ciclos/instrucciones de pago) y app (emitir orden con multi-selección de elegibles, PDF, subir comprobante, timeline de estados; FAB de seguros redirige al flujo nuevo con flag ON).
- **Observabilidad**: eventos estructurados `field_payment_order.{issued,proof_submitted,approved,rejected,cancelled,expired,fulfill_fail}` con `approve_latency_ms` en logs del backend.

### Feature flags (rollout órdenes de pago)

- `field_payment_orders_v1` (`system_config`): value JSON con lista de `local_field_id` habilitados. Flag ON en un LF: alta directa legacy y submit de purchases qty quedan bloqueados; el flujo nuevo es la única vía de alta.
- `field_payment_orders.expiry_days` (`system_config`): días para expirar órdenes `ISSUED` sin comprobante. Default **15**.

### Runbook — piloto por Campo Local (operación humana post-merge)

Pasos para habilitar el flujo en un LF piloto (NO ejecutar como parte del deploy automático):

1. **Seed de catálogo**: crear `insurance_products` + `insurance_cycle_configs` del LF (admin → Seguros → Configuración, permiso `insurance:configure`), con `unit_cost` y `purchase_deadline` del año vigente.
2. **Instrucciones de pago**: capturar `field_payment_order_configs` del LF (banco y/o caja del campo). Sin config activa, el PDF de la orden falla con `FIELD_PAYMENT_ORDER_CONFIG_NOT_FOUND`.
3. **Permisos**: verificar que el seed de `field-payment-orders:*` está aplicado (`prisma/seeds/permissions.seed.sql` + `role-permissions.seed.sql`).
4. **Flag ON**: agregar el `local_field_id` a `system_config.field_payment_orders_v1` (JSON array). Desde ese momento el alta directa legacy y el submit de purchases qty quedan bloqueados en ese LF.
5. **Drain de purchases pendientes**: resolver (confirmar/rechazar) las `insurance_purchases` en `PENDING_CONFIRMATION` del LF antes del flag ON, para no dejar compras huérfanas.
6. **Rollback**: quitar el `local_field_id` del flag restaura el flujo legacy sin tocar datos; las órdenes ya aprobadas conservan su cobertura materializada.

### Base de datos
- `member_insurances` — Seguros por miembro con campos:
  - `insurance_id` (PK INT), `user_id` (FK UUID), `insurance_type` (ENUM), `policy_number`, `provider`, `start_date`, `end_date`, `coverage_amount` (DECIMAL), `active`, `evidence_file_url`, `evidence_file_name`
  - Auditoria: `created_by_id` (FK UUID), `modified_by_id` (FK UUID)
- Relacion con `camporee_members` via `insurance_id`

### Storage
- Evidencia de seguros se almacena en Cloudflare R2, bucket `INSURANCE_EVIDENCE`

## Requisitos funcionales

1. Debe ser posible crear un seguro para cualquier miembro activo de una seccion de club
2. El seguro debe registrar: tipo (GENERAL_ACTIVITIES, CAMPOREE, HIGH_RISK), numero de poliza, aseguradora, fechas de vigencia, monto de cobertura
3. Debe ser posible adjuntar evidencia documental (PDF, imagen) al seguro via upload multipart
4. El listado de seguros por seccion debe mostrar cada miembro con su seguro activo mas reciente
5. Los seguros deben poder actualizarse (renovar vigencia, cambiar aseguradora, actualizar evidencia)
6. La evidencia se almacena en Cloudflare R2 y se expone como URL firmada
7. El modulo debe registrar quien creo y quien modifico cada seguro (auditoria)
8. El panel admin debe permitir gestion de seguros por seccion/club y monitoreo de vencimientos proximos

## Decisiones de diseno

- **Multipart para evidencia**: La creacion y actualizacion de seguros aceptan upload multipart con campo `evidence`, no requiere un endpoint separado para archivos
- **Seguro activo mas reciente**: El listado por seccion resuelve el seguro activo vigente de cada miembro, no el historico completo
- **Tres tipos de seguro**: El enum `insurance_type_enum` distingue cobertura por contexto de uso, no por nivel de proteccion
- **Auditoria integrada**: Los campos `created_by_id` y `modified_by_id` registran el actor que gestiona el seguro, que puede ser diferente del miembro asegurado (directores gestionan seguros de sus miembros)
- **Almacenamiento R2**: La evidencia se guarda en Cloudflare R2 siguiendo el mismo patron que fotos de perfil y evidencias de honores

## Gaps y pendientes

- **Sin notificaciones de vencimiento**: No hay mecanismo para alertar cuando un seguro esta por vencer
- **Sin historial**: Solo se muestra el seguro activo mas reciente; no hay endpoint para consultar seguros historicos de un miembro
- **Validacion de camporee acotada al flujo de registro**: `camporees.service.ts` valida tipo `CAMPOREE`, titularidad, vigencia y estado activo cuando se envia `insurance_id`, pero no existe una superficie general de historial o auditoria de coberturas
- **REALITY-MATRIX desactualizada**: La Reality Matrix marcaba seguros como "SIN CANON" y sin backend module, pero el modulo `src/insurance/` existe con 5 endpoints funcionales documentados en ENDPOINTS-LIVE-REFERENCE

## Prioridad y siguiente accion

- **Prioridad**: Media — backend, admin y app cubren la operacion base; faltan alertas/notificaciones e historial
- **Siguiente accion**: Actualizar REALITY-MATRIX.md para reflejar que el InsuranceModule y la UI admin existen. Considerar notificaciones de vencimiento e historial de seguros por miembro.
