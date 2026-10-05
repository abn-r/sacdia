# Insumos de camporee — Diseño

**Estado:** APROBADO (diseño). Falta plan de implementación.
**Fecha:** 2026-08-26
**Bounded context:** `camporee-supplies` (nuevo)
**Alcance:** `sacdia-backend`, `sacdia-app`, `sacdia-admin`, docs canónicas
**UX:** Dentro de la ficha/flujo del camporee. No es un módulo de navegación aparte.

## Objetivo

Que una sección inscrita planifique, con anticipación, qué insumos consumirá en cada horario de entrega del camporee (garrafones, tortillas, hielo, etc.), pague un total antes del evento, pueda ajustar solo días aún no congelados, y que cocina/caja vean demanda y cobros sin mezclar este flujo con pedidos de mercancía ni con la inscripción.

## Receptor (no confundir con emisor)

Los insumos **no** son para el director o el secretario como personas.

| Rol | Qué hace | Para quién es el producto |
|-----|----------|---------------------------|
| Director / secretary / secretary-treasurer | Arman el plan, envían, recogen en el slot | Toda la sección (ej. 100 personas de Panteras) |
| LF / unión (`director-lf`, `assistant-lf`) | Configuran catálogo y horarios, cobran, marcan entrega | La sección como unidad logística |
| Miembro inscrito | No pide ni recibe línea nominada en v1 | Come/bebe lo que la sección pidió |

Contraste con mercancía (`camporee-orders`): allá cada línea es un `camporee_member_id` (la playera de Juan). Acá no hay “garrafón de Juan”: hay 3 garrafones de **la sección** en el slot de la tarde.

## Problema que no resuelve lo existente

| Dominio actual | Por qué no alcanza |
|----------------|-------------------|
| `camporee-orders` | Artículo nominado, ventana con kill switch, una entrega LF→sección→miembro, folio inmutable. No hay día/slot ni kg. |
| `MaterialOrder` | Catálogo LF general, sin camporee/día/horario. |
| `field_payment_orders` | Inscripción/seguro; purpose uniforme, no carrito de insumos. |
| `club_inventory` | Almacén del club, no demanda de cocina del evento. |

## Decisiones aprobadas

1. Bounded context nuevo. Tablas y permisos propios. Patrones (folio, territorial, caja LF, Pagos pendientes) sí; tablas de mercancía no.
2. Un **plan por sección inscrita** (`camporee_clubs` activo `registered|approved`). Secciones del mismo club son planes independientes.
3. El club pide **producto × horario de entrega**. El total del día y del camporee es **derivado**. El “3 kg el sábado” es la suma de los slots de ese sábado.
4. El organizador define los **slots** del camporee (hora + etiqueta). El club no inventa horarios; elige slot existente + producto + qty.
5. Emisión club: solo `director`, `secretary`, `secretary-treasurer`.
6. Config y operación de caja/entrega: `director-lf` y `assistant-lf` del campo local. Si el camporee es de unión, también director/asistente de unión. `admin` / `super-admin` pueden por rol; la operación diaria es LF.
7. Precios fijos del evento (snapshot en config). Un PATCH de precio se **bloquea** si ya existe algún plan `SUBMITTED` en ese camporee.
8. Cada producto declara su UOM (`KG`, `L`, `BAG`, `UNIT`, …). Qty decimal; costo en centavos. Total de línea = redondeo half-up de `qty × unit_cost_centavos`.
9. Hecho bajo pedido. Venta de no reclamado queda fuera de v1.
10. Entrega a la **sección**, check-in por línea/slot, **parcial** permitido. No hay `delivered_to_member`.
11. Reportes cocina y caja: vivo + cierre diario. Misma fuente que el plan.
12. Paquete físico de notas junto a inscripción: **hook futuro**, no v1. v1 emite la obligación de insumos con folio propio.

## Modelo

```text
Camporee (local XOR union)
  ├─ supply_edit_cutoff_local_time     default 21:00
  ├─ supply_slots[]                    time + label (07:00 Desayuno)
  ├─ supply_products[]                 name, uom, cost_centavos, active
  └─ supply_plans[]                    1 por club_section inscrita
        status: DRAFT | SUBMITTED
        ├─ lines[]                     date + slot_id + product_id + qty
        ├─ payment_docs[]              PRINCIPAL | CHARGE | REFUND
        └─ deliveries[]                line_id + qty + at + actor + note?
```

El cliente nunca envía pesos, `club_id` ni `local_field_id` como autoridad. El servidor deriva territorio, precios y totales.

### Freeze

Timezone = `camporee.timezone`. Corte = `supply_edit_cutoff_local_time` (configurable, default 21:00).

Para una línea con fecha `D`, el club puede editar solo si el plan ya está `SUBMITTED` y:

- `D` no es hoy ni pasado;
- si `D` es mañana, la hora local es **menor** que el corte;
- si `D` ≥ pasado mañana, sí.

`DRAFT`: sin freeze. Edición libre de todos los días hasta el primer envío.

Bypass de freeze: LF (y unión si aplica) + admin, con **motivo obligatorio** y audit.

Error club en día congelado: `CAMPOREE_SUPPLIES_DAY_LOCKED`.

### Pago: una principal + hijos

1. `DRAFT` → aún no hay cobro.
2. Primer “enviar” → `SUBMITTED` + documento **PRINCIPAL** (ej. $800), folio estable (`INS{yyyy}{####}` por LF y año). Esa es la nota pre-campo.
3. Recorte posterior (día no congelado) → **REFUND** hijo con `parent_id` = principal. Monto = delta (ej. $100), no el nuevo total. Texto: se restan $100 de `INS…` porque ya no se necesitan esos insumos.
4. Incremento posterior → **CHARGE** hijo de la misma principal, pagable en campamento.
5. La principal **no se reescribe ni se reemplaza**. Saldo neto = principal − refunds + cargos hijos.

No se mezcla con `camporee_orders` ni con purpose de inscripción. En Pagos pendientes: `source` nuevo (`CAMPOREE_SUPPLY_CHARGE` / `CAMPOREE_SUPPLY_REFUND` o equivalente), folios distintos.

Entrega v1 **no** exige principal `PAID` (el evento ya puede haber empezado). Caja persigue cargos y ejecuta devoluciones.

### Entrega parcial

Cada línea tiene `qty_ordered` y suma de `deliveries`. Check-ins sucesivos hasta completar. Estados derivados: `PENDING` | `PARTIAL` | `COMPLETE` | `OVERDUE` (el slot ya pasó y resta qty).

## Permisos

| Permiso | Actores | Uso |
|---------|---------|-----|
| `camporee-supplies:read` | Emisores club + LF (+ unión si aplica) + admin | Ver plan, catálogo, resumen |
| `camporee-supplies:plan` | director, secretary, secretary-treasurer | Borrador, enviar, ajustar días abiertos |
| `camporee-supplies:configure` | LF; unión si el evento es de unión | Slots, productos, precio, corte |
| `camporee-supplies:review-pay` | director-lf, assistant-lf (+ unión si aplica) | Cobro/devolución, bypass freeze |
| `camporee-supplies:deliver` | mismos de review-pay | Check-in parcial |

## Superficies

- **App:** tab/sección dentro del detalle de camporee. Cronograma de slots + plan de la sección activa + deudas hijas.
- **Admin:** tab Insumos en el camporee. Config, bandeja de planes, cocina, caja, check-in. No hay ítem de menú global “Insumos”.

## Reportes

1. Cocina (vivo): producto × slot × sección × día; pedido vs entregado.
2. Caja (vivo): por sección; principal + hijos; saldo; estado de pago.
3. Cierre diario: PDF/Excel del día, corte a las 00:00 del día siguiente hora local.

Una sola verdad: el plan y sus documentos. El reporte no persiste otra demanda.

## Fuera de v1

- Venta de insumos no reclamados.
- Enganche del folio principal al paquete físico de notas de inscripción.
- Kardex / stock de cocina.
- Pedido nominado por miembro.
- Consejero o tesorero suelto como emisor.

## Enfoque descartado

- Extender `camporee_orders` o `MaterialOrder`.
- Un folio nuevo e independiente de $800 cada vez que el club edita.
- Mini-pedido por día sin plan de camporee.
- Total del día que el sistema reparte a slots (el club elige el slot).
