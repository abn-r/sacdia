# Handoff Admin — Órdenes de pago territoriales (field payment orders)

> Contrato REAL implementado en `sacdia-backend` (branch `feat/field-payment-orders`).
> Prefijo global: `/api/v1`. Todas las rutas requieren Bearer JWT + permisos RBAC.
> Fuente: `sacdia-backend/src/field-payment-orders/`.

## 1) Modelo funcional

Una **orden de pago** agrupa N beneficiarios de una sección de club para un
propósito (`INSURANCE` | `CAMPOREE`). El director la emite, imprime el PDF,
paga en banco **o en la caja del Campo Local**, sube el comprobante y el
liderazgo del Campo Local (director-lf / assistant-lf / admin) la aprueba o
rechaza. El approve ejecuta el fulfillment atómico (cobertura de seguro o
inscripción de camporee).

### Máquina de estados (`status`)

```
ISSUED ──► PROOF_SUBMITTED ──► APPROVED (terminal)
  │              │
  │              └──► PROOF_REJECTED ──► PROOF_SUBMITTED (re-upload, mismo folio)
  │                        └──► CANCELLED
  ├──► CANCELLED (terminal)
  └──► EXPIRED (terminal, lazy al pasar expires_at; default 15 días,
                configurable en system_config `field_payment_orders.expiry_days`)
```

- Transición inválida → **422** `FIELD_PAYMENT_ORDER_INVALID_TRANSITION`.
- Maker-checker: quien subió el comprobante NO puede aprobarlo → **403**
  `FIELD_PAYMENT_ORDER_MAKER_CHECKER`.
- Feature flag por LF: system_config `field_payment_orders_v1` = JSON array de
  `local_field_id` habilitados. Con flag OFF la emisión devuelve **403**
  `FIELD_PAYMENT_ORDER_FLAG_DISABLED` (los flujos legacy siguen intactos).

### Permisos

| Permiso | Roles (seed) | Uso |
|---|---|---|
| `field-payment-orders:read` | secretary, treasurer, secretary-treasurer, director (CLUB); director-lf, assistant-lf, admin, super-admin (GLOBAL) | listar/detalle/PDF/proof |
| `field-payment-orders:create` | mismos roles CLUB + LF leadership | emitir órdenes |
| `field-payment-orders:upload-proof` | mismos roles CLUB | subir comprobante |
| `field-payment-orders:cancel` | mismos roles CLUB | cancelar |
| `field-payment-orders:review` | director-lf, assistant-lf, admin, super-admin | bandeja, approve, reject |
| `field-payment-orders:configure` | director-lf, assistant-lf, admin, super-admin | instrucciones de pago del LF |

Alcance: directores ven órdenes de sus secciones; LF leadership ve todo su
campo local; admin/super-admin sin territorio ven todo (y deben mandar
`local_field_id` explícito en config).

## 2) Endpoints

### Emisión (superficie club — para referencia, el admin no la usa)

- `POST /insurance/payment-orders` — permiso `create`.
  Body: `{ insurance_cycle_config_id: number, beneficiary_user_ids: uuid[] }`.
  Header opcional `Idempotency-Key`.
- `POST /camporees/:camporeeId/payment-orders` — permiso `create`.
  Body: `{ beneficiary_user_ids: uuid[] }`. Header opcional `Idempotency-Key`.
  Respuesta 201: la orden completa con `lines[]`.

### Listado y detalle

- `GET /payment-orders?purpose=INSURANCE|CAMPOREE&status=<estado>&camporee_id=<n>`
  — permiso `read`. Devuelve `{ status: 'success', data: Order[] }` con
  `lines[]`, orden descendente por `created_at`.
- `GET /payment-orders/review-queue?purpose=&camporee_id=` — permiso `review`.
  Solo órdenes `PROOF_SUBMITTED` del LF efectivo (asc por antigüedad), incluye
  `proofs[]` (desc). Es la fuente de la bandeja del admin.
- `GET /payment-orders/:orderId` — permiso `read`. Detalle con `lines` y `proofs`.

### Documentos

- `GET /payment-orders/:orderId/document` — permiso `read`. Respuesta binaria
  `application/pdf` (`Content-Disposition: attachment; filename="orden-<folio>.pdf"`).
  Requiere config de pago del LF activa; si no existe → **404**
  `FIELD_PAYMENT_ORDER_CONFIG_NOT_FOUND`.
- `GET /payment-orders/:orderId/proof` — permiso `read`. URL firmada on-demand:
  `{ url, expires_in: 900, file_name, mime_type, status, uploaded_by_id, created_at }`.

### Mutaciones del club

- `POST /payment-orders/:orderId/proof` — permiso `upload-proof`. Multipart
  campo `file` (pdf/jpeg/png, máx 10 MB, magic bytes validados). Válido desde
  `ISSUED` o `PROOF_REJECTED`. Respuesta: `{ proof, order }`.
- `POST /payment-orders/:orderId/cancel` — permiso `cancel`.

### Revisión (admin / LF)

- `POST /payment-orders/:orderId/approve` — permiso `review`. Sin body.
  Ejecuta fulfillment en la misma TX; si la elegibilidad se rompió →
  **400** `FIELD_PAYMENT_ORDER_ELIGIBILITY_FAILED` y NO se aprueba nada.
  Carrera perdida → **409** `FIELD_PAYMENT_ORDER_INVALID_TRANSITION`.
- `POST /payment-orders/:orderId/reject` — permiso `review`.
  Body: `{ reason: string }` (obligatorio, máx 500). Deja la orden en
  `PROOF_REJECTED`; el club puede re-subir comprobante con el mismo folio.

### Configuración de instrucciones de pago por LF

- `GET /payment-orders/config?local_field_id=<n>` — permiso `configure`.
  LF leadership omite el query param (usa su LF); admin global DEBE enviarlo.
  404 `FIELD_PAYMENT_ORDER_CONFIG_NOT_FOUND` si aún no se configura.
- `POST /payment-orders/config` — permiso `configure` (upsert). Body:

```json
{
  "local_field_id": 7,
  "bank_name": "Banco Norte",
  "bank_account": "1234567890",
  "bank_clabe": "012345678901234567",
  "bank_holder": "Asociación ...",
  "cash_instructions": "Pagar en la caja del Campo Local, L-V 9:00-17:00",
  "extra_notes": "...",
  "active": true
}
```

  Regla: al menos UNA vía (banco = `bank_account` o `bank_clabe`; caja =
  `cash_instructions`), si no → **400** `FIELD_PAYMENT_ORDER_CONFIG_INVALID`.

### Reasignaciones de seguro

Base: `/insurance/reassignments`.

- `POST /` — permiso `insurance:create`.
  Body: `{ insurance_assignment_id: number, to_user_id: uuid, reason?: string }`.
  Solo mismo club; destino sin cobertura activa.
- `GET /?status=PENDING|APPROVED|REJECTED` — permiso `insurance:read`.
- `POST /:requestId/approve` — permiso `insurance:review`. TX: cierra la
  assignment origen y abre una nueva para el destino.
- `POST /:requestId/reject` — permiso `insurance:review`. Body `{ reason }`.

## 3) Shape de la orden (respuesta real)

```jsonc
{
  "field_payment_order_id": "uuid",
  "purpose": "CAMPOREE",              // o INSURANCE
  "local_field_id": 7,
  "club_id": 5,
  "club_section_id": 11,
  "folio": 9,
  "folio_reference": "ORD20260009",   // ORD{year}{seq4}, único por LF+año
  "insurance_cycle_config_id": null,  // set si INSURANCE
  "local_camporee_id": 40,            // set si CAMPOREE
  "currency": "MXN",
  "unit_cost_centavos": 25000,
  "total_centavos": 50000,
  "status": "ISSUED",
  "expires_at": "2026-08-27T…",
  "issued_by_id": "uuid",
  "approved_by_id": null,
  "cancelled_by_id": null,
  "created_at": "…",
  "lines": [
    {
      "field_payment_order_line_id": "uuid",
      "sequence": 1,
      "beneficiary_user_id": "uuid",
      "unit_cost_centavos": 25000,
      "purpose": "CAMPOREE",
      "purpose_ref_id": 40,
      "insurance_assignment_id": null, // set tras approve INSURANCE
      "camporee_member_id": null       // set tras approve CAMPOREE
    }
  ],
  "proofs": [
    {
      "field_payment_order_proof_id": "uuid",
      "file_name": "comprobante.pdf",
      "mime_type": "application/pdf",
      "status": "SUBMITTED",           // SUBMITTED | APPROVED | REJECTED
      "reject_reason": null,
      "uploaded_by_id": "uuid",
      "reviewed_by_id": null,
      "created_at": "…"
    }
  ]
}
```

Los montos SIEMPRE en centavos (`unit_cost_centavos`, `total_centavos`).

## 4) Errores relevantes para UI

| Código | HTTP | Cuándo |
|---|---|---|
| `FIELD_PAYMENT_ORDER_NOT_FOUND` | 404 | orden inexistente |
| `FIELD_PAYMENT_ORDER_FORBIDDEN` | 403 | fuera de alcance (sección/LF) |
| `FIELD_PAYMENT_ORDER_FLAG_DISABLED` | 403 | LF sin rollout |
| `FIELD_PAYMENT_ORDER_INVALID_TRANSITION` | 422/409 | transición inválida / carrera |
| `FIELD_PAYMENT_ORDER_MAKER_CHECKER` | 403 | uploader == approver |
| `FIELD_PAYMENT_ORDER_PROOF_NOT_FOUND` | 404 | approve/reject sin proof SUBMITTED |
| `FIELD_PAYMENT_ORDER_EXPIRED` | 400 | subir proof a orden vencida |
| `FIELD_PAYMENT_ORDER_ELIGIBILITY_FAILED` | 400 | fulfillment revalidó y falló (payload: `reason`, `user_ids`) |
| `FIELD_PAYMENT_ORDER_REJECT_REASON_REQUIRED` | 400 | reject sin comentario |
| `FIELD_PAYMENT_ORDER_CONFIG_NOT_FOUND` | 404 | LF sin instrucciones de pago |
| `FIELD_PAYMENT_ORDER_CONFIG_INVALID` | 400 | config sin banco ni caja |
| `FIELD_PAYMENT_ORDER_LEGACY_DISABLED` | 409 | flujo legacy bloqueado con flag ON |

Shape de error: `{ status: 'error', code, statusCode, message, details?, timestamp, path }`.

## 5) Alcance UI admin (plan Fase 4)

1. **Config seguros** (`/dashboard/insurance/config`): products/cycles contra
   endpoints `insurance:configure` existentes + formulario de instrucciones de
   pago del LF (`GET/POST /payment-orders/config`).
2. **Bandeja de órdenes**: página con filtro purpose (INSURANCE/CAMPOREE)
   sobre `GET /payment-orders/review-queue`; detalle con líneas/beneficiarios,
   visor de comprobante vía `GET .../proof` (URL firmada on-demand),
   approve/reject con comentario obligatorio, aviso maker-checker cuando
   `proof.uploaded_by_id === currentUser`.
3. **Reasignaciones**: bandeja `GET /insurance/reassignments?status=PENDING`
   con approve/reject.
4. **Integración camporee**: acceso desde `camporee-detail-tabs.tsx` a
   `GET /payment-orders?purpose=CAMPOREE&camporee_id=<id>`.
5. i18n 4 locales + `messages.d.ts` regenerado; tests vitest de componentes nuevos.
