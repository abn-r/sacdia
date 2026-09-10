# Pedidos de campamentos y camporees — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Estado:** READY FOR IMPLEMENTATION  
**Alcance:** `sacdia-backend`, `sacdia-app`, `sacdia-admin` y documentación canónica  
**Restricción:** No ejecutar builds. Verificar con pruebas focalizadas, lint, typecheck/analyze y `git diff --check`.

**Goal:** Permitir que una sección inscrita en un campamento o camporee consolide pedidos de artículos por miembro inscrito, pague una orden de materiales independiente y dé seguimiento a su validación y entrega.

**Architecture:** Evolucionar el bounded context existente `materials` en vez de crear otro sistema de catálogo, comprobantes y entrega. Se añadirán propiedad territorial del catálogo, ofertas configuradas por camporee y asignaciones de cada línea a `camporee_members`; las órdenes de inscripción y materiales seguirán separadas. Una proyección de solo lectura unificará ambas dentro de “Pagos pendientes” sin mezclar tablas, estados ni comprobantes.

**Tech Stack:** NestJS 11, Prisma 7, PostgreSQL, Cloudflare R2, Flutter/Riverpod, Next.js 16, React 19, TanStack Query y shadcn/ui.

---

## 0. Baseline verificada

### Ya existe y debe reutilizarse

- `MaterialProduct`, `MaterialVariant`, `MaterialVariantOption` y categorías.
- `MaterialOrder` + `MaterialOrderLine`, folios, totales y estados.
- `MaterialComprobante`, validación de archivos, almacenamiento privado R2 y URLs firmadas.
- Flujo `en_revision → aprobada → pagada → entregada`.
- Permisos `materiales:*` para directiva de sección y roles territoriales.
- `field_payment_orders` para inscripción/seguro, con órdenes grupales, folios y maker-checker.
- `camporee_members` como roster efectivo de inscritos locales y de unión.

### Gaps que este plan debe cerrar

1. `MaterialProduct` pertenece obligatoriamente a un `local_field_id`; no admite dueño Unión o División.
2. Las tallas se pueden leer, pero no existe un contrato completo para crear/reordenar opciones de variante desde API/admin.
3. `MaterialOrderLine` agrega cantidades, pero no conserva qué miembro pidió cada artículo.
4. `MaterialOrder` no identifica el camporee de origen.
5. El precio vive en el producto general; falta una oferta/precio por camporee.
6. El flujo siempre descuenta stock; las preventas para fabricar playeras necesitan modo `PREORDER`.
7. Las mutaciones de aprobación, entrega y comprobantes no afirman consistentemente el territorio del actor.
8. La app genera actualmente la cancelación con `/materials/orders//cancel`; debe corregirse antes de extender el flujo.
9. “Órdenes de pago” y “Materiales” se muestran por separado; falta una lectura agregada de obligaciones pendientes.

---

## 1. Decisiones cerradas

1. **Solo miembros inscritos:** una asignación debe apuntar a `camporee_members.active=true` y estado `registered|approved`. `pending_approval`, `rejected` e inactivos no son elegibles.
2. **Pagos separados:** la inscripción y los materiales conservan folio, total, comprobante y ciclo de vida propios.
3. **Integración financiera de lectura:** “Pagos pendientes” muestra ambas obligaciones, pero cada acción navega al dominio propietario.
4. **Orden global por sección:** el cliente captura artículos por persona; el backend consolida cantidades por oferta + variante en una sola `MaterialOrder`.
5. **Un pedido activo por sección/camporee:** cancelar permite reemitir; no hay pedidos suplementarios después de pago o entrega en v1.
6. **Cobro y revisión por Campo Local:** `MaterialOrder.local_field_id` sigue derivándose de la sección. Aun si el catálogo proviene de Unión/División, director/asistente del Campo Local valida el comprobante y entrega a la sección.
7. **Catálogo territorial:** un producto pertenece exactamente a Campo Local, Unión o División; nunca a varios a la vez.
8. **Oferta por camporee:** publicar un producto en un camporee fija precio, ventana de pedidos y política de inventario para ese evento.
9. **Tallas flexibles:** v1 mantiene una dimensión de variante por producto. Las opciones son etiquetas ordenadas (`CH`, `M`, `G`, `XG` o `10`, `12`, `14`); no se modelan sistemas de tallas rígidos.
10. **Precio confiable:** el cliente nunca envía precios. El backend toma `CamporeeMaterialOffering.price_centavos` y lo copia a la línea como snapshot.
11. **Sin parciales en v1:** un comprobante aprobado paga toda la orden; la entrega es global para la sección; no hay pagos, devoluciones ni entregas parciales automatizadas.
12. **Sin Finance ledger:** Materials continúa siendo dueño del comprobante y estado de pago.
13. **Admin contract-first:** Codex define backend, datos, app y contratos. La implementación visual del admin se entrega mediante handoff a Cursor, respetando `docs/steering/agent-ownership.md`.

### Fuera de alcance v1

- Pagos en línea o conciliación bancaria automática.
- Un solo comprobante para inscripción y materiales.
- Catálogo de proveedores, compras, producción o transporte.
- Distribución individual confirmada dentro del club.
- Precios distintos por talla.
- Carrito persistente en servidor antes de enviar el pedido.
- Transferencias contables Campo Local → Unión/División.

---

## 2. Arquitectura objetivo

```text
Territorio propietario                    Camporee concreto
Campo Local | Unión | División             local | union
          |                                      |
          v                                      v
 MaterialProduct ----------------> CamporeeMaterialOffering
 categoría + variante             precio + ventana + stock policy
                                             |
                        director captura por miembro inscrito
                                             |
                                             v
                                      MaterialOrder
                                      una por sección
                                             |
                       +---------------------+--------------------+
                       v                                          v
              MaterialOrderLine                      MaterialOrderAllocation
              agregado por producto/talla            camporee_member + qty
                       |
                       v
          comprobante → validación LF → pagada → entregada

Read model transversal:
field_payment_orders + material_orders → PaymentObligations (solo lectura)
```

### Regla de consolidación

Solicitud del cliente:

```json
{
  "club_section_id": 44,
  "camporee_type": "local",
  "camporee_id": 17,
  "entrega": "recoger",
  "items": [
    {
      "camporee_member_id": 801,
      "offering_id": "uuid-playera",
      "variant_option_id": "uuid-m",
      "qty": 1
    },
    {
      "camporee_member_id": 802,
      "offering_id": "uuid-playera",
      "variant_option_id": "uuid-m",
      "qty": 1
    },
    {
      "camporee_member_id": 802,
      "offering_id": "uuid-gorra",
      "qty": 1
    }
  ]
}
```

Persistencia resultante:

- Línea `playera / M / qty=2` con dos allocations de `qty=1`.
- Línea `gorra / sin variante / qty=1` con una allocation.
- Total calculado exclusivamente por servidor.

---

## 3. Modelo de datos propuesto

### 3.1 Propiedad territorial del producto

Evolucionar `MaterialProduct` con migración compatible:

```prisma
enum MaterialOwnerScope {
  LOCAL_FIELD
  UNION
  DIVISION
}

model MaterialProduct {
  // existentes
  id             String             @id @default(uuid()) @db.Uuid
  local_field_id Int?

  // nuevos
  owner_scope    MaterialOwnerScope @default(LOCAL_FIELD)
  union_id       Int?
  division_id    Int?

  union          unions?            @relation(fields: [union_id], references: [union_id])
  division       divisions?         @relation(fields: [division_id], references: [division_id])
  offerings      CamporeeMaterialOffering[]
}
```

La migración SQL debe:

- Backfill `owner_scope=LOCAL_FIELD` para todas las filas actuales.
- Convertir `local_field_id` a nullable después del backfill.
- Añadir `CHECK` que exija exactamente un owner compatible con `owner_scope`.
- Reemplazar `UNIQUE(local_field_id, sku)` por índices únicos parciales para cada scope.
- Conservar FKs y filas existentes sin recrear IDs.

### 3.2 Variantes ordenadas

```prisma
model MaterialVariantOption {
  // existentes
  id         String @id @default(uuid()) @db.Uuid
  variant_id String @db.Uuid
  label      String @db.VarChar(100)
  stock      Int    @default(0)

  // nuevo
  sort_order Int    @default(0)
}
```

El contrato de upsert reemplaza atómicamente la definición solo si el producto no tiene órdenes abiertas que referencien opciones eliminadas.

### 3.3 Configuración y ofertas del camporee

```prisma
enum MaterialStockPolicy {
  MANAGED
  PREORDER
}

model CamporeeMaterialConfig {
  id                  String    @id @default(uuid()) @db.Uuid
  local_camporee_id   Int?
  union_camporee_id   Int?
  ordering_opens_at   DateTime? @db.Timestamptz(6)
  ordering_closes_at  DateTime? @db.Timestamptz(6)
  active              Boolean   @default(false)
  created_by          String    @db.Uuid
  updated_by          String    @db.Uuid
  created_at          DateTime  @default(now()) @db.Timestamptz(6)
  updated_at          DateTime  @updatedAt @db.Timestamptz(6)

  offerings CamporeeMaterialOffering[]
}

model CamporeeMaterialOffering {
  id               String              @id @default(uuid()) @db.Uuid
  config_id        String              @db.Uuid
  product_id       String              @db.Uuid
  price_centavos   Int
  stock_policy     MaterialStockPolicy @default(MANAGED)
  max_per_member   Int?
  active           Boolean             @default(true)
  sort_order       Int                 @default(0)
  created_at       DateTime            @default(now()) @db.Timestamptz(6)
  updated_at       DateTime            @updatedAt @db.Timestamptz(6)

  config  CamporeeMaterialConfig @relation(fields: [config_id], references: [id])
  product MaterialProduct         @relation(fields: [product_id], references: [id])

  @@unique([config_id, product_id])
}
```

Invariantes SQL:

- Config referencia exactamente un camporee local o uno de unión.
- Una sola config por camporee.
- `price_centavos >= 0`, `max_per_member IS NULL OR max_per_member > 0`.
- No activar config sin ofertas activas.
- La ventana debe cumplir `ordering_opens_at < ordering_closes_at` cuando ambas existan.
- El owner territorial del producto debe ser ancestro o igual al organizador del camporee.

### 3.4 Contexto del pedido y asignaciones

```prisma
model MaterialOrder {
  // existentes
  id                 String  @id @default(uuid()) @db.Uuid
  local_field_id     Int
  club_section_id    Int

  // nuevos
  local_camporee_id  Int?
  union_camporee_id  Int?
  camporee_config_id String? @db.Uuid

  allocations MaterialOrderAllocation[]
}

model MaterialOrderLine {
  // existentes
  id                  String @id @default(uuid()) @db.Uuid
  order_id            String @db.Uuid
  product_id          String @db.Uuid
  variant_option_id   String? @db.Uuid

  // nuevo
  offering_id         String? @db.Uuid
  allocations         MaterialOrderAllocation[]
}

model MaterialOrderAllocation {
  id                 String @id @default(uuid()) @db.Uuid
  order_id           String @db.Uuid
  order_line_id      String @db.Uuid
  camporee_member_id Int
  qty                Int
  created_at         DateTime @default(now()) @db.Timestamptz(6)

  order           MaterialOrder     @relation(fields: [order_id], references: [id])
  order_line      MaterialOrderLine @relation(fields: [order_line_id], references: [id])
  camporee_member camporee_members  @relation(fields: [camporee_member_id], references: [camporee_member_id])

  @@unique([order_line_id, camporee_member_id])
  @@index([camporee_member_id])
}
```

Invariantes de servicio/transacción:

- `SUM(allocation.qty) = order_line.qty`.
- Todos los miembros pertenecen al mismo camporee y `club_section_id` de la orden.
- Cada option pertenece al producto de la oferta.
- Una partial unique index impide más de una orden no cancelada para sección + camporee.
- Órdenes Materials generales conservan `camporee_* = NULL` y allocations vacías.

---

## 4. Contratos API objetivo

### Catálogo territorial y variantes

```http
POST /api/v1/materials/inventory
PATCH /api/v1/materials/inventory/:productId
PUT /api/v1/materials/inventory/:productId/variant
```

`POST/PATCH inventory` acepta owner explícito solo para roles territoriales:

```json
{
  "owner": { "scope": "UNION", "union_id": 3 },
  "sku": "CAM-PLAYERA-2026",
  "title": "Playera oficial",
  "material_category_id": "uuid",
  "club_type_id": 2,
  "price_centavos": 18000
}
```

`PUT variant`:

```json
{
  "type": "talla",
  "options": [
    { "label": "CH", "sort_order": 10, "stock": 0 },
    { "label": "M", "sort_order": 20, "stock": 0 },
    { "label": "G", "sort_order": 30, "stock": 0 }
  ]
}
```

### Configuración de pedidos por camporee

```http
GET  /api/v1/local-camporees/:camporeeId/materials/config
PUT  /api/v1/local-camporees/:camporeeId/materials/config
GET  /api/v1/union-camporees/:camporeeId/materials/config
PUT  /api/v1/union-camporees/:camporeeId/materials/config
GET  /api/v1/local-camporees/:camporeeId/materials/catalog
GET  /api/v1/union-camporees/:camporeeId/materials/catalog
```

Mutación de config usa `materiales:configure`; backend valida ownership territorial del camporee y de cada producto.

### Pedido de sección

```http
POST /api/v1/local-camporees/:camporeeId/material-orders
POST /api/v1/union-camporees/:camporeeId/material-orders
GET  /api/v1/local-camporees/:camporeeId/material-orders
GET  /api/v1/union-camporees/:camporeeId/material-orders
GET  /api/v1/materials/orders/:folio
```

El POST requiere `materiales:create`. El backend deriva el Campo Local desde la sección y rechaza:

- sección no inscrita o de otro camporee;
- miembro no inscrito, inactivo, rechazado o de otra sección;
- oferta inactiva/fuera de ventana;
- talla omitida cuando el producto tiene variante;
- talla enviada para otro producto;
- cantidad mayor a `max_per_member`;
- orden activa existente;
- precio o total enviados por cliente.

### Obligaciones pendientes de pago

```http
GET /api/v1/payment-obligations/pending
GET /api/v1/payment-obligations/pending?camporee_id=17
GET /api/v1/payment-obligations/pending?union_camporee_id=8
```

Respuesta de read model:

```json
{
  "data": [
    {
      "source": "MATERIAL_ORDER",
      "source_id": "uuid",
      "purpose": "CAMPOREE_MATERIALS",
      "folio": "SOL20260042",
      "camporee": { "type": "local", "id": 17, "name": "Camporí 2026" },
      "total_centavos": 425000,
      "currency": "MXN",
      "status": "PAYMENT_DUE",
      "action_required": "UPLOAD_PROOF",
      "created_at": "2026-08-24T18:00:00Z"
    }
  ]
}
```

Mapeo mínimo:

| Fuente | Estado origen | Estado read model | Acción |
|---|---|---|---|
| Field order | `ISSUED` | `PAYMENT_DUE` | subir comprobante |
| Field order | `PROOF_SUBMITTED` | `UNDER_REVIEW` | esperar |
| Field order | `PROOF_REJECTED` | `PROOF_REJECTED` | corregir comprobante |
| Material order | `en_revision` | `ORDER_REVIEW` | esperar disponibilidad |
| Material order | `aprobada`, sin comprobante pendiente | `PAYMENT_DUE` | subir comprobante |
| Material order | `aprobada`, comprobante pendiente | `UNDER_REVIEW` | esperar |

Órdenes pagadas, entregadas, canceladas, expiradas o aprobadas no aparecen como pendientes.

---

## 5. Plan de implementación TDD

### Task 1: Congelar contrato funcional y API

**Files:**
- Create: `docs/features/pedidos-camporees.md`
- Modify: `docs/features/camporees.md`
- Modify: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- Modify: `docs/api/FRONTEND-INTEGRATION-GUIDE.md`
- Modify: `docs/database/SCHEMA-REFERENCE.md`

**Steps:**
1. Documentar decisiones de la sección 1 como requisitos EARS y criterios de aceptación.
2. Documentar estados, errores canónicos y permisos de la sección 4.
3. Marcar endpoints como `PLANNED`; no describirlos como runtime antes de implementarlos.
4. Verificar enlaces y formato con `git diff --check`.
5. Commit: `docs(camporees): define material orders contract`.

### Task 2: Cerrar riesgos de seguridad del Materials existente

**Files:**
- Create: `sacdia-backend/src/materials/orders/orders.service.spec.ts`
- Create: `sacdia-backend/src/materials/receipts/receipts.service.spec.ts`
- Modify: `sacdia-backend/src/materials/orders/orders.controller.ts`
- Modify: `sacdia-backend/src/materials/orders/orders.service.ts`
- Modify: `sacdia-backend/src/materials/receipts/receipts.controller.ts`
- Modify: `sacdia-backend/src/materials/receipts/receipts.service.ts`
- Modify: `sacdia-backend/src/materials/shared/actor-local-field.ts`
- Modify: `sacdia-app/lib/features/materials/data/datasources/materials_remote_data_source.dart`
- Create: `sacdia-app/test/features/materials/data/datasources/materials_remote_data_source_test.dart`

**Steps:**
1. Escribir tests que intenten aprobar, entregar, cancelar y validar comprobantes fuera del territorio.
2. Ejecutar `pnpm exec jest src/materials/orders/orders.service.spec.ts src/materials/receipts/receipts.service.spec.ts --runInBand`; esperar fallos de autorización.
3. Resolver y pasar `localFieldId | localFieldIds` autorizado a todas las mutaciones.
4. Afirmar scope antes de cambiar estado, stock o comprobantes.
5. Escribir el test Flutter que espere `/materials/orders/{folio}/cancel`.
6. Ejecutar `flutter test test/features/materials/data/datasources/materials_remote_data_source_test.dart`; comprobar el fallo por doble slash.
7. Corregir interpolación del folio y volver a ejecutar pruebas.
8. Commit backend: `fix(materials): enforce territorial scope on order mutations`.
9. Commit app: `fix(materials): include folio in cancel request`.

### Task 3: Migrar catálogo territorial y esquema de pedidos de camporee

**Files:**
- Create: `sacdia-backend/prisma/migrations/20260824090000_camporee_material_orders/migration.sql`
- Modify: `sacdia-backend/prisma/schema.prisma`
- Modify: `docs/database/schema.prisma`
- Create: `sacdia-backend/src/materials/shared/material-owner-scope.spec.ts`

**Steps:**
1. Escribir pruebas de helpers para scopes LF/Unión/División y ancestros permitidos.
2. Añadir enums, owner territorial, `sort_order`, configs, offerings, vínculos de orden y allocations.
3. Crear checks, partial unique indexes e índices de lectura definidos en la sección 3.
4. Backfill de productos existentes sin cambiar IDs ni SKUs.
5. Probar migración en PostgreSQL de test: backfill, checks, duplicados y rollback manual documentado.
6. Ejecutar `pnpm exec jest src/materials/shared/material-owner-scope.spec.ts --runInBand`.
7. Sincronizar el espejo documental solo después de validar el schema efectivo.
8. Commit: `feat(db): add territorial camporee material orders schema`.

### Task 4: Implementar ownership territorial y variantes configurables

**Files:**
- Create: `sacdia-backend/src/materials/shared/material-owner-scope.ts`
- Create: `sacdia-backend/src/materials/inventory/dto/upsert-product-variant.dto.ts`
- Modify: `sacdia-backend/src/materials/inventory/dto/create-product.dto.ts`
- Modify: `sacdia-backend/src/materials/inventory/dto/update-product.dto.ts`
- Modify: `sacdia-backend/src/materials/inventory/inventory.controller.ts`
- Modify: `sacdia-backend/src/materials/inventory/inventory.service.ts`
- Modify: `sacdia-backend/src/materials/catalog/catalog.service.ts`
- Create: `sacdia-backend/src/materials/inventory/inventory.service.spec.ts`
- Modify: `sacdia-admin/src/lib/types/materials.ts`
- Modify: `sacdia-admin/src/lib/api/materials.ts`

**Steps:**
1. Tests de creación/listado por LF, Unión y División; negar siblings y territorios ajenos.
2. Tests de upsert de tallas alfabéticas y numéricas preservando `sort_order`.
3. Tests que bloqueen eliminar opciones referenciadas por órdenes abiertas.
4. Implementar owner derivado/validado por backend; nunca confiar solo en IDs del body.
5. Implementar `PUT /inventory/:productId/variant` transaccional.
6. Actualizar DTOs Swagger y tipos admin.
7. Ejecutar `pnpm exec jest src/materials/inventory/inventory.service.spec.ts src/materials/shared/material-owner-scope.spec.ts --runInBand`.
8. Commit: `feat(materials): support territorial products and ordered variants`.

### Task 5: Configurar ofertas por camporee

**Files:**
- Create: `sacdia-backend/src/materials/camporees/camporee-materials.controller.ts`
- Create: `sacdia-backend/src/materials/camporees/camporee-materials.service.ts`
- Create: `sacdia-backend/src/materials/camporees/camporee-materials.service.spec.ts`
- Create: `sacdia-backend/src/materials/camporees/dto/camporee-material-config.dto.ts`
- Create: `sacdia-backend/src/materials/camporees/dto/upsert-camporee-material-config.dto.ts`
- Create: `sacdia-backend/src/materials/camporees/dto/camporee-material-catalog.query.dto.ts`
- Modify: `sacdia-backend/src/materials/materials.module.ts`

**Steps:**
1. Tests de configuración local y de unión con autorización territorial.
2. Tests que acepten productos del owner organizador o ancestro y rechacen catálogos ajenos.
3. Tests de ventana, precio, producto/variante activa y `MANAGED|PREORDER`.
4. Implementar GET/PUT config y GET catálogo visible.
5. Activación debe fallar sin ofertas válidas.
6. Emitir auditoría de altas, cambios de precio, activación y cierre.
7. Ejecutar `pnpm exec jest src/materials/camporees/camporee-materials.service.spec.ts --runInBand`.
8. Commit: `feat(materials): configure offerings per camporee`.

### Task 6: Crear el pedido consolidado por miembros inscritos

**Files:**
- Create: `sacdia-backend/src/materials/camporees/dto/create-camporee-material-order.dto.ts`
- Create: `sacdia-backend/src/materials/orders/camporee-order-builder.ts`
- Create: `sacdia-backend/src/materials/orders/camporee-order-builder.spec.ts`
- Modify: `sacdia-backend/src/materials/camporees/camporee-materials.controller.ts`
- Modify: `sacdia-backend/src/materials/camporees/camporee-materials.service.ts`
- Modify: `sacdia-backend/src/materials/orders/orders.service.ts`
- Modify: `sacdia-backend/src/materials/orders/dto/order.dto.ts`

**Steps:**
1. Test rojo: miembro activo `registered|approved` de la misma sección/camporee es elegible.
2. Tests rojos: miembro pendiente, rechazado, inactivo, de otra sección o de otro camporee.
3. Test rojo: dos personas con misma playera/talla producen una línea y dos allocations.
4. Tests de variante obligatoria, pertenencia de option, límite por miembro y ventana cerrada.
5. Test de idempotencia/unique: segunda orden activa para sección + camporee devuelve `CAMPOREE_MATERIAL_ORDER_ALREADY_EXISTS`.
6. Implementar validación y creación en una sola transacción.
7. Derivar precio, total, LF y folio exclusivamente en backend.
8. Exponer allocations solo a dueño de orden y roles territoriales autorizados.
9. Ejecutar `pnpm exec jest src/materials/orders/camporee-order-builder.spec.ts src/materials/camporees/camporee-materials.service.spec.ts --runInBand`.
10. Commit: `feat(materials): create camporee orders by enrolled member`.

### Task 7: Adaptar revisión, comprobante y entrega

**Files:**
- Modify: `sacdia-backend/src/materials/orders/stock.service.ts`
- Modify: `sacdia-backend/src/materials/orders/orders.service.ts`
- Modify: `sacdia-backend/src/materials/receipts/receipts.service.ts`
- Modify: `sacdia-backend/src/materials/orders/dto/order.dto.ts`
- Modify: `sacdia-backend/src/materials/orders/orders.service.spec.ts`
- Modify: `sacdia-backend/src/materials/receipts/receipts.service.spec.ts`

**Steps:**
1. Test que `MANAGED` descuente/restaure stock por variante.
2. Test que `PREORDER` no descuente stock, pero conserve revisión de disponibilidad.
3. Test maker-checker y scope LF para aprobar/rechazar comprobante.
4. Test que pago y entrega no alteren la orden de inscripción.
5. Test que allocations permanezcan inmutables después de `en_revision`.
6. Incluir desglose por producto/talla y miembro en el DTO de detalle.
7. Ejecutar suites Orders/Receipts completas.
8. Commit: `feat(materials): fulfill camporee material orders`.

### Task 8: Crear la proyección “Pagos pendientes”

**Files:**
- Create: `sacdia-backend/src/payment-obligations/payment-obligations.module.ts`
- Create: `sacdia-backend/src/payment-obligations/payment-obligations.controller.ts`
- Create: `sacdia-backend/src/payment-obligations/payment-obligations.service.ts`
- Create: `sacdia-backend/src/payment-obligations/payment-obligations.service.spec.ts`
- Create: `sacdia-backend/src/payment-obligations/dto/list-payment-obligations.query.dto.ts`
- Create: `sacdia-backend/src/payment-obligations/dto/payment-obligation.dto.ts`
- Modify: `sacdia-backend/src/app.module.ts`

**Steps:**
1. Tests del mapeo de estados de la tabla de la sección 4.
2. Tests de visibilidad: directiva ve su sección; LF/Unión/División solo su territorio.
3. Tests de filtros local/union camporee y orden descendente estable.
4. Implementar read model sin escrituras, joins polimórficos ni FK entre kernels.
5. No devolver URLs internas; usar `source/source_id` para que el cliente elija navegación.
6. Ejecutar `pnpm exec jest src/payment-obligations/payment-obligations.service.spec.ts --runInBand`.
7. Commit: `feat(payments): aggregate pending obligations`.

### Task 9: Implementar contratos y dominio móvil

**Files:**
- Modify: `sacdia-app/lib/core/constants/api_endpoints.dart`
- Modify: `sacdia-app/lib/core/config/route_names.dart`
- Modify: `sacdia-app/lib/core/config/router.dart`
- Create: `sacdia-app/lib/features/materials/domain/entities/camporee_material_config.dart`
- Create: `sacdia-app/lib/features/materials/domain/entities/camporee_order_draft.dart`
- Modify: `sacdia-app/lib/features/materials/domain/entities/order.dart`
- Create: `sacdia-app/lib/features/materials/data/models/camporee_material_config_model.dart`
- Modify: `sacdia-app/lib/features/materials/data/models/order_model.dart`
- Modify: `sacdia-app/lib/features/materials/data/datasources/materials_remote_data_source.dart`
- Modify: `sacdia-app/lib/features/materials/domain/repositories/materials_repository.dart`
- Modify: `sacdia-app/lib/features/materials/data/repositories/materials_repository_impl.dart`
- Create: `sacdia-app/lib/features/payment_orders/domain/entities/payment_obligation.dart`
- Create: `sacdia-app/lib/features/payment_orders/data/models/payment_obligation_model.dart`

**Steps:**
1. Tests de parsing de config, ofertas, allocations y obligaciones.
2. Tests de URLs local/union y payload sin precio.
3. Implementar datasource/repository respetando Clean Architecture.
4. Ejecutar pruebas de modelos y datasource focalizadas.
5. Commit: `feat(materials): add camporee order mobile domain`.

### Task 10: Implementar captura del pedido en app

**Files:**
- Create: `sacdia-app/lib/features/materials/presentation/providers/camporee_order_provider.dart`
- Create: `sacdia-app/lib/features/materials/presentation/views/camporee_order_catalog_view.dart`
- Create: `sacdia-app/lib/features/materials/presentation/views/camporee_member_order_view.dart`
- Create: `sacdia-app/lib/features/materials/presentation/views/camporee_order_review_view.dart`
- Modify: `sacdia-app/lib/features/camporees/presentation/views/camporee_detail_view.dart`
- Modify: `sacdia-app/lib/features/payment_orders/presentation/views/payment_orders_view.dart`
- Modify: `sacdia-app/assets/translations/es.json`
- Modify: `sacdia-app/assets/translations/en.json`
- Modify: `sacdia-app/assets/translations/fr.json`
- Modify: `sacdia-app/assets/translations/pt-BR.json`
- Create: `sacdia-app/test/features/materials/presentation/providers/camporee_order_provider_test.dart`
- Create: `sacdia-app/test/features/materials/presentation/views/camporee_order_review_view_test.dart`
- Create: `sacdia-app/test/features/payment_orders/data/models/payment_obligation_model_test.dart`

**Steps:**
1. Mostrar “Pedidos” solo con config activa y sección inscrita.
2. Seleccionar únicamente desde el roster inscrito del camporee.
3. Capturar artículos por miembro; exigir talla cuando aplique.
4. Mostrar revisión agrupada por producto/talla y desglose por persona.
5. Enviar una sola vez; bloquear doble tap y manejar conflicto de orden existente.
6. Reutilizar detalle, comprobante e historial Materials después de crear.
7. Convertir la lista actual de órdenes de pago en obligaciones pendientes con navegación por `source`.
8. Probar loading, vacío, error, ventana cerrada, sin ofertas y envío exitoso.
9. Ejecutar `flutter test test/features/materials test/features/payment_orders`.
10. Ejecutar `flutter analyze`.
11. Commit: `feat(camporees): add member-based material ordering flow`.

### Task 11: Preparar contratos y handoff del admin

**Files:**
- Modify: `sacdia-admin/src/lib/types/materials.ts`
- Modify: `sacdia-admin/src/lib/api/materials.ts`
- Create: `sacdia-admin/src/lib/payment-obligations/types.ts`
- Create: `sacdia-admin/src/lib/api/payment-obligations.ts`
- Create: `docs/plans/handoffs/camporee-material-orders-admin-handoff.md`

**Steps:**
1. Añadir tipos exactos para owner, config, offering, allocations y obligation.
2. Añadir funciones API sin inventar estados o rutas visuales.
3. Escribir tests de mapeo/formatos de dinero y estados.
4. Handoff debe incluir endpoints, DTOs, permisos, errores y estados loading/empty/error/success.
5. Indicar explícitamente que Cursor mantiene ownership del diseño visual.
6. Ejecutar Vitest focalizado de tipos/helpers.
7. Commit: `feat(admin): add camporee material order contracts`.

### Task 12: Implementar configuración y operación en admin

**Files:**
- Create: `sacdia-admin/src/components/camporees/camporee-materials-tab.tsx`
- Create: `sacdia-admin/src/components/materials/camporee-offerings-form.tsx`
- Create: `sacdia-admin/src/components/materials/camporee-order-allocations.tsx`
- Modify: `sacdia-admin/src/components/camporees/camporee-detail-tabs.tsx`
- Modify: `sacdia-admin/src/app/(dashboard)/dashboard/materials/inventory/_components/product-form-sheet.tsx`
- Modify: `sacdia-admin/src/app/(dashboard)/dashboard/materials/request/[folio]/page.tsx`
- Modify: `sacdia-admin/src/app/(dashboard)/dashboard/materials/request/[folio]/_components/lines-table.tsx`
- Create: `sacdia-admin/src/components/payment-orders/payment-obligations-client.tsx`
- Modify: `sacdia-admin/src/app/(dashboard)/dashboard/payment-orders/page.tsx`
- Modify: `sacdia-admin/messages/es.json`
- Modify: `sacdia-admin/messages/en.json`
- Modify: `sacdia-admin/messages/fr.json`
- Modify: `sacdia-admin/messages/pt-BR.json`
- Create: `sacdia-admin/src/components/camporees/camporee-materials-tab.test.tsx`
- Create: `sacdia-admin/src/components/materials/camporee-order-allocations.test.tsx`
- Create: `sacdia-admin/src/components/payment-orders/payment-obligations-client.test.tsx`

**Steps:**
1. Agregar tab “Pedidos” a camporee local y de unión.
2. Permitir publicar productos, precio, ventana, política de stock y orden visual.
3. Inventario debe configurar owner territorial y tallas ordenadas.
4. Detalle de orden debe mostrar totales por producto/talla y listado nominal para preparación.
5. Reutilizar acciones existentes de disponibilidad, aprobación, comprobante y entrega.
6. Cambiar la página `/dashboard/payment-orders` a bandeja agregada conservando deep links existentes.
7. Probar permisos, scope, estados vacíos/error y representación de ambas fuentes.
8. Ejecutar `pnpm exec vitest run` sobre las tres suites nuevas.
9. Ejecutar `pnpm typecheck` y `pnpm lint`; **no ejecutar `pnpm build`**.
10. Commit: `feat(admin): manage camporee material orders`.

### Task 13: Canonizar runtime y verificar integración

**Files:**
- Modify: `docs/features/pedidos-camporees.md`
- Modify: `docs/features/camporees.md`
- Modify: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- Modify: `docs/api/FRONTEND-INTEGRATION-GUIDE.md`
- Modify: `docs/api/SECURITY-GUIDE.md`
- Modify: `docs/api/TESTING-GUIDE.md`
- Modify: `docs/database/SCHEMA-REFERENCE.md`

**Steps:**
1. Promover endpoints `PLANNED` a `IMPLEMENTED` solo tras pruebas verdes.
2. Documentar modelo territorial, elegibilidad, pagos separados y read model agregado.
3. Ejecutar backend: Jest focalizado para Materials + PaymentObligations.
4. Ejecutar app: `flutter test` focalizado y `flutter analyze`.
5. Ejecutar admin: Vitest focalizado, `pnpm typecheck` y `pnpm lint`.
6. Ejecutar `git diff --check` en cada repositorio.
7. No ejecutar builds.
8. Commit por repositorio: `docs(camporees): document material orders runtime`.

---

## 6. Matriz mínima de aceptación

| Caso | Resultado esperado |
|---|---|
| Director abre camporee sin config activa | No aparece acción de pedidos |
| Director intenta incluir miembro no inscrito | 422/409 canónico; no se crea orden |
| Dos miembros piden misma playera/talla | Una línea agregada, dos allocations |
| Miembro pide playera y gorra | Dos líneas, ambas ligadas al mismo `camporee_member_id` |
| Producto exige talla y no se envía option | Rechazo de validación |
| Catálogo Unión se publica en camporee de otra Unión | 403 por scope |
| Orden `PREORDER` se aprueba | No descuenta stock |
| Orden `MANAGED` se aprueba/cancela | Descuenta/restaura stock atómicamente |
| Director sube comprobante | Aparece `UNDER_REVIEW` en Pagos pendientes |
| Asistente/Director LF aprueba comprobante | Materials pasa a `pagada`; inscripción no cambia |
| Orden se entrega | Desaparece de pendientes y conserva desglose nominal |
| Actor territorial consulta otro territorio | 403/404 fail-closed |
| Doble envío de pedido | No duplica; devuelve conflicto canónico |

---

## 7. Review Workload Forecast

- **Cambio estimado:** alto, cross-repo y claramente superior a 400 líneas.
- **Riesgo de presupuesto de revisión:** HIGH.
- **Chained/stacked PRs recomendados:** Sí.

### Slices recomendados

1. **Backend PR A:** hardening Materials + corrección de cancelación app como bug independiente.
2. **Backend PR B:** schema territorial + variantes + ofertas por camporee.
3. **Backend PR C:** orden consolidada + allocations + ciclo de pago/entrega.
4. **Backend PR D:** read model `payment-obligations` + contratos canónicos.
5. **App PR:** captura por miembro + obligaciones pendientes.
6. **Admin PR:** contratos primero; UI mediante handoff de ownership.

Cada slice debe mantener tests y documentación del comportamiento dentro del mismo work unit. No separar commits por tipo de archivo.

---

## 8. Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Romper catálogo LF existente al generalizar owner | Migración aditiva, backfill y compatibilidad de queries antes de nullable |
| Acceso cross-territory por folio conocido | Hardening obligatorio de Task 2 antes de exponer nuevos flujos |
| Doble conteo entre lines y allocations | Creación transaccional + test `SUM(allocation.qty)=line.qty` |
| Cambio de precio después del pedido | Snapshot en `MaterialOrderLine.price_centavos` |
| Borrar talla histórica | Bloquear eliminación si está referenciada; permitir desactivación futura |
| Preventa tratada como stock físico | `MaterialStockPolicy.PREORDER` explícito |
| Mezclar inscripción y materiales en UI | Read model con `source/purpose`; mutaciones quedan separadas |
| Camporee de unión con catálogo jerárquico ambiguo | Validar owner igual/ancestro y cobrar/revisar por LF de la sección |
| PR imposible de revisar | Aplicar slices de la sección 7 y medir diff antes de abrir cada PR |

---

## 9. Definition of Done

- Catálogo configurable por Campo Local, Unión o División con scope fail-closed.
- Camporee local/de Unión publica ofertas con precio, talla, ventana y política de stock.
- Solo inscritos elegibles pueden recibir artículos.
- El sistema genera una orden global de sección con desglose nominal auditable.
- Comprobante, validación y entrega reutilizan Materials y no alteran pagos de inscripción.
- “Pagos pendientes” muestra ambas fuentes sin fusionarlas.
- Backend, app y admin tienen pruebas de autorización, errores y happy path.
- Docs API, DB y feature reflejan el runtime final.
- No se ejecutaron builds.

