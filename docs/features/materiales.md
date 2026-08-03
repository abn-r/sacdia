# Materiales y pedidos al Campo Local

**Estado**: PARCIAL
**Última actualización**: 2026-08-03

## Alcance de dominio

Materials es el catálogo comercial y el flujo de solicitud de material que un club realiza a su Campo Local. No es el inventario físico del club: `inventory_categories` y `club_inventory` permanecen en el dominio Inventario y no son modificados por este documento. Seguros también queda fuera de Materials.

## Estado real verificado: Materials W1-W2

La primera unidad terminada establece el aislamiento de categorías por Campo Local y el contrato de lectura/creación que lo consume:

- `material_categories.local_field_id` es obligatorio.
- El `slug` es único por Campo Local, no globalmente.
- Un producto sólo puede apuntar a una categoría de su mismo Campo Local por la FK compuesta `(material_category_id, local_field_id)`.
- `GET /api/v1/materials/catalog/categories`, `GET /api/v1/materials/catalog`, `GET /api/v1/materials/catalog/:id` y `GET|POST /api/v1/materials/categories` usan el alcance Materials implementado. La referencia completa está en [ENDPOINTS-LIVE-REFERENCE.md](../api/ENDPOINTS-LIVE-REFERENCE.md).

### Resolución de alcance implementada

1. `super-admin` puede operar todos los Campos, pero debe seleccionar `local_field_id` para listados y creación scopeados.
2. `admin`, `director-lf` y `assistant-lf` operan únicamente el Campo Local efectivo de su snapshot de autorización.
3. Sólo cuando no existe autoridad global de Campo Local, el sistema puede derivar el Campo desde la asignación activa de club. Un rol con autoridad territorial incompleta falla cerrado; no usa ese fallback.
4. Un `local_field_id` de query no amplía permisos: una discrepancia contra el alcance único devuelve 403.

### Identidad y lifecycle de categorías (W2)

`PATCH|DELETE /api/v1/materials/categories/:id` operan sobre el UUID estable de la categoría. La categoría conserva ese UUID durante actualizaciones y desactivaciones; estos endpoints tampoco permiten cambiar `slug` ni `local_field_id`. El ownership se toma de la fila persistida y se compara con el Campo Local efectivo del actor, por lo que conocer un UUID de otro Campo no autoriza su mutación.

- `PATCH` modifica `label`, `icon`, `sort_order` o `active`. Un actor con alcance único sólo puede modificar categorías activas de su Campo.
- `POST /api/v1/materials/categories/:id/reactivate` no recibe body y sólo permite reactivar a `super-admin`; rechaza a los demás roles antes de resolver el UUID. Para ellos, cualquier otra edición de una inactiva devuelve 409.
- Desactivar mediante `PATCH active=false` se bloquea mientras haya productos activos. `DELETE` es una desactivación lógica: si la categoría ya está inactiva devuelve 200 idempotente antes de contar productos; sólo una categoría activa se bloquea con `category_in_use` cuando existe cualquier producto asociado.
- El catálogo público omite categorías inactivas; el listado administrativo sigue siendo la superficie que las conserva visibles.
- La actualización y la desactivación verifican nuevamente ownership y lifecycle dentro de la operación atómica. Un cambio concurrente no puede convertir una validación previa en una escritura cross-Campo.

Errores de dominio estables: `local_field_scope_violation` (403), `material_reactivation_requires_super_admin` (403), `category_not_found` (404), `category_in_use`, `category_inactive` y `category_concurrent_change` (409). Un UUID o body inválido falla con 400 antes de la mutación.

## Migración y rollout

La migración `20260730233000_finalize_material_category_scope` requiere que el runtime scope-aware previo esté desplegado. Bajo una sola transacción toma locks fuertes, clona categorías globales de forma determinista para cada Campo Local, remapea productos del mismo Campo y después aplica `NOT NULL`, uniques y FK compuesta.

Antes de mutar, aborta sin estado parcial si no hay Campos Locales, existen colisiones de slug o un producto ya apunta a una categoría de otro Campo. El despliegue debe programarse en una ventana de mantenimiento por el `ACCESS EXCLUSIVE` de `material_categories` y `material_products`; un fallo hace rollback completo de la transacción.

## Límites vigentes

- El único endpoint nuevo de W2b es `POST /materials/categories/:id/reactivate`; no se modificó el flujo de pedidos, comprobantes, entregas o pagos.
- La autorización UUID y el lifecycle de categorías están cubiertos por W2. Auditoría de Materials y administración de pedidos siguen pendientes; no deben inferirse de este contrato.
- No se modificó Inventory ni el flujo de seguros.

## Referencias canónicas

- Datos: [SCHEMA-REFERENCE.md](../database/SCHEMA-REFERENCE.md) y [schema.prisma](../database/schema.prisma).
- API: [ENDPOINTS-LIVE-REFERENCE.md](../api/ENDPOINTS-LIVE-REFERENCE.md).
- Seguridad: [SECURITY-GUIDE.md](../api/SECURITY-GUIDE.md).
