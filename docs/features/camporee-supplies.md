# Feature: Insumos de camporee

**Estado**: IMPLEMENTADO PARCIAL
**Fecha**: 2026-08-26 (estado actualizado 2026-10-04)
**Módulo backend**: `CamporeeSuppliesModule` (`src/camporee-supplies/`) + fuentes en `PaymentObligationsModule`
**ADR**: [#10 — Bounded context `camporee-supplies`](../api/ARCHITECTURE-DECISIONS.md#10-bounded-context-camporee-supplies-independiente-de-camporee-orders)

> Integrado en `development` en los tres repos: backend `src/camporee-supplies` (migración `20260826120000_camporee_supplies`, permisos en `prisma/seeds/permissions.seed.sql` y `role-permissions.seed.sql`), admin (tab Insumos en la ficha de camporee, `src/components/camporee-supplies`; sin nav global) y app `lib/features/camporee_supplies`.

---

## Descripción

Permite que una **sección inscrita** (`registered|approved`) planifique insumos de cocina (hielo, tortillas, garrafones) por **producto × horario de entrega**, pague un folio **PRINCIPAL** `INS{yyyy}{####}` y ajuste días no congelados con hijos **CHARGE** / **REFUND**. La unidad logística es la sección, no el miembro.

En la app, el plan abre con la **orden de pago** (estimado en borrador; neto y folios INS al enviar). Debajo, **Agregar insumo** (icono +, texto y chevron) abre el sheet de alta; el formulario no vive en la lista. Luego hay un bloque por cada día del camporee y, dentro, los insumos agrupados por horario de entrega.

No reutiliza tablas, folios PED ni permisos de mercancía (`camporee-orders`). Contraste: allá cada línea es un `camporee_member_id`; acá no hay “garrafón de Juan”.

### Superficies

| Superficie | Estado | Evidencia |
|------------|--------|-----------|
| Backend Nest (catálogo, plan, freeze, folio INS, entrega, reportes, PaymentObligations) | En `development` | `src/camporee-supplies` (29 rutas); Jest `src/camporee-supplies` + `src/payment-obligations` |
| Schema / migración | En `development` | `prisma/migrations/20260826120000_camporee_supplies/` |
| Admin (tab Insumos en ficha) | En `development` | `camporee-supplies-tab.tsx`: config, planes, caja, cocina, mark-paid, entrega parcial. **No** impersona submit del club |
| App (plan en detalle de camporee) | En `development` | `CamporeeSupplyPlanView`: orden de pago; CTA Agregar insumo; insumos por día y horario; alta en sheet |

---

## Requisitos EARS (v1)

1. **WHEN** una sección inscrita abre el plan
   **THE SYSTEM SHALL** exponer un único plan DRAFT o SUBMITTED para esa sección y camporee (secciones del mismo club son independientes).

2. **WHEN** el club arma líneas
   **THE SYSTEM SHALL** exigir `date` + `slot_id` del catálogo del evento + `product_id` + `qty` decimal. El club no inventa horarios. Totales de día y de camporee son derivados.

3. **WHEN** el club envía el plan por primera vez
   **THE SYSTEM SHALL** emitir un único folio PRINCIPAL `INS{yyyy}{####}` (contador propio por LF/año, no PED) y no reescribirlo después.

4. **WHEN** el plan ya está SUBMITTED y cambia una cantidad
   **THE SYSTEM SHALL** crear un hijo CHARGE (aumento) o REFUND (reducción). Qty 0 elimina la línea si no hay entregas.

5. **WHILE** el plan está SUBMITTED
   **THE SYSTEM SHALL** congelar edición de días hoy/pasados; mañana solo si la hora local del camporee es menor que `supply_edit_cutoff_local_time` (default 21:00). DRAFT no congela.

6. **IF** el club intenta editar un día congelado
   **THEN THE SYSTEM SHALL** responder `CAMPOREE_SUPPLIES_DAY_LOCKED`. LF/unión/admin pueden bypasear con `bypass_reason` obligatorio y audit.

7. **WHEN** existe al menos un plan SUBMITTED en el camporee
   **THE SYSTEM SHALL** rechazar PATCH de `unit_cost_centavos` con `CAMPOREE_SUPPLIES_PRICE_LOCKED`.

8. **WHEN** caja registra entrega
   **THE SYSTEM SHALL** aceptar qty parcial a la sección. No exige PRINCIPAL PAID. No hay `delivered_to_member`.

9. **WHEN** un director consulta Pagos pendientes
   **THE SYSTEM SHALL** listar folios INS (CHARGE/PRINCIPAL ISSUED y REFUND) como filas distintas de PED, inscripción y materiales.

10. **IF** el cliente envía pesos, `club_id` o `local_field_id` como autoridad
    **THEN THE SYSTEM SHALL** ignorarlos; el servidor deriva territorio, snapshot de precio y `line_total_centavos` (half-up `qty × unit_cost`).

---

## Permisos

| Permiso | Quién | Uso |
|---------|-------|-----|
| `camporee-supplies:read` | Emisores club + LF (+ unión) + admin | Catálogo, planes, reportes |
| `camporee-supplies:plan` | `director`, `secretary`, `secretary-treasurer` | DRAFT, submit, adjust días abiertos |
| `camporee-supplies:configure` | LF organizador; unión si el evento es de unión; admin | Slots, productos, corte |
| `camporee-supplies:review-pay` | `director-lf`, `assistant-lf`, admin | Mark-paid, bypass freeze |
| `camporee-supplies:deliver` | Mismos de review-pay | Check-in parcial |

Emisores de club **no** incluyen deputy-director, treasurer ni counselor.

---

## HTTP (prefijo `/api/v1`)

Rutas duales `camporees/:id` y `union-camporees/:id` salvo mark-paid.

- `GET …/supply-catalog`
- `PATCH …/supply-settings`
- `POST|PATCH …/supply-slots`, `POST|PATCH …/supply-products`
- `GET|PUT …/supply-plan` (club, `active_assignment`)
- `POST …/supply-plan/submit`
- `PATCH …/supply-plan/lines` (club o LF; `bypass_reason` si freeze)
- `GET …/supply-plans`
- `POST …/supply-lines/:lineId/deliveries`
- `GET …/supply-reports/kitchen?date=`
- `GET …/supply-reports/cash`
- `POST /camporee-supply-payments/:paymentId/mark-paid`

Ver [`ENDPOINTS-LIVE-REFERENCE.md`](../api/ENDPOINTS-LIVE-REFERENCE.md) §camporee supplies.

---

## Fuera de v1

Paquete físico de notas junto a inscripción, venta de no reclamado, líneas nominadas a miembro, nav global “Insumos” en admin.
