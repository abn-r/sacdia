# Runtime Coordination

## Estado
ACTIVE

## Propósito

Canoniza el modelo de coordinación institucional de SACDIA: zonas creadas por
campo local, coordinador general, coordinadores por zona y asignaciones directas
por sección de club.

Este documento corrige el modelo anterior implícito donde `coordinator` era un
rol global con alcance derivado de `users.local_field_id`. Ese modelo es
insuficiente para la operación real porque SACDIA es multirol y la autoridad de
coordinación termina en secciones concretas de club.

## Jerarquía institucional vigente

La jerarquía de datos existente ya sostiene el recorrido operativo:

```text
local_fields
  -> districts
    -> churches
      -> clubs
        -> club_sections
```

La unidad final de autoridad para coordinación es `club_sections`.

## Conceptos canónicos

### Zona de coordinación

Una zona de coordinación pertenece a un campo local y agrupa distritos.

```text
coordination_zone
  local_field_id
  name
  active
```

Una zona no agrupa clubes directamente. Los clubes entran por la cadena:

```text
zone -> districts -> churches -> clubs -> club_sections
```

### Coordinador general

Un campo local puede tener máximo un coordinador general activo.

El coordinador general ve y opera sobre todas las secciones de club del campo
local, sujeto a permisos del dominio.

### Coordinador de zona por sección

Un coordinador de zona se asigna a una zona y a un tipo/sección de club.

Ejemplo:

```text
Usuario A -> Zona 1 -> Aventureros
Usuario B -> Zona 1 -> Conquistadores
```

Si Zona 1 contiene distritos con 16 clubes, el Usuario A gestiona las secciones
de Aventureros de esos clubes, y el Usuario B gestiona las secciones de
Conquistadores de esos mismos clubes.

### Asignación directa por sección

Los campos locales pueden operar sin zonas o tener excepciones finas. En esos
casos, el coordinador se asigna directamente a una `club_section`.

Esto permite combinaciones diversificadas:

```text
Usuario C -> Club 1 / Aventureros
Usuario C -> Club 2 / Guías Mayores
Usuario C -> Club 3 / Conquistadores
```

## Modelo de asignación

El contrato canónico recomendado es una tabla de asignaciones de coordinación
con tres variantes:

```text
coordinator_assignments
  assignment_id
  user_id
  local_field_id
  assignment_type: GENERAL | ZONE | SECTION
  zone_id?
  club_type_id?
  club_section_id?
  active
  start_date
  end_date
  created_by
  created_at
  updated_at
```

Reglas por variante:

| Variante | Campos requeridos | Scope resultante |
|---|---|---|
| `GENERAL` | `local_field_id` | Todas las `club_sections` del campo local |
| `ZONE` | `zone_id`, `club_type_id` | Secciones de ese tipo dentro de distritos de la zona |
| `SECTION` | `club_section_id` | Solo esa sección concreta |

`local_field_id` se mantiene en la asignación como columna de scope/indexación,
pero el backend debe validar que coincida con el campo local derivado de la zona
o de la sección.

Los roles globales compatibles para habilitar la superficie de coordinación son:

- `coordinator`
- `zone-coordinator`
- `general-coordinator`

El rol habilita acceso; la asignación define el alcance operativo real.

La administración de zonas y asignaciones no queda habilitada por esos roles de
coordinador runtime. El panel administrativo y los endpoints
`/api/v1/admin/coordination/*` requieren un rol institucional administrativo
del alcance correspondiente y el permiso efectivo `coordination:manage`.

## Scope efectivo

El backend debe resolver el alcance del usuario coordinador como:

```text
coordinator_scope(user_id) -> club_section_ids[]
```

El scope se calcula como la unión de:

1. secciones del campo local si tiene asignación `GENERAL`;
2. secciones por zona + `club_type_id` si tiene asignaciones `ZONE`;
3. secciones explícitas si tiene asignaciones `SECTION`.

Los consumidores no deben reconstruir este alcance por su cuenta. Los módulos
deben depender de un resolver común de scope.

La API pública para clientes autenticados es:

```text
GET /api/v1/coordination/me/scope
```

La respuesta debe incluir `club_section_ids` efectivos y metadatos suficientes
para que la app móvil muestre la superficie coordinador junto con otras
superficies del usuario multirol.

## Multirol e incompatibilidad director/coordinador

SACDIA es multirol: un usuario puede ser director y coordinador al mismo tiempo.
Los clientes deben mostrar todas las funcionalidades correspondientes a sus
roles y permisos efectivos.

Pero existe una incompatibilidad de conflicto de interés:

> Un usuario que es director activo de una `club_section` no puede ser
> coordinador activo de esa misma `club_section`.

Ejemplo:

- puede ser director de Aventureros en Club A;
- puede coordinar Guías Mayores en Club A;
- puede coordinar Aventureros en Club B;
- no puede coordinar Aventureros en Club A mientras sea director activo de esa
  misma sección.

La validación debe ocurrir al crear o activar asignaciones de coordinación y
debe revisar roles activos de club para la misma `club_section`.

## Superficie funcional del coordinador

La superficie coordinador debe centrarse en:

- SLA y métricas operacionales de su alcance;
- evidencias pendientes de clases y especialidades dentro de su alcance;
- investiduras pendientes dentro de su alcance;
- clubes y secciones bajo su gestión.

Las aprobaciones de camporee quedan fuera del alcance del coordinador móvil en
este modelo. Cualquier operación futura de camporee para coordinación requiere
decisión explícita separada.

## Invariantes

- El rol global abre la puerta, pero no define alcance operativo por sí solo.
- La asignación define autoridad real.
- La autoridad final siempre se expresa como `club_section_ids`.
- No se debe usar `union_id` como scope de coordinador.
- No se debe confiar en query params manipulables para ampliar scope.
- No puede existir más de un coordinador general activo por campo local.
- Un distrito activo no debe pertenecer a más de una zona activa del mismo campo
  local.
- La app móvil debe respetar multirol: si el usuario es director y coordinador,
  debe ver ambas superficies.

## Relación con documentos existentes

- `runtime-validation.md`: coordinadores revisan, no envían progreso.
- `runtime-sla-dashboard.md`: los coordinadores usan `coordinator_scope(user_id)` /
  `club_section_ids`; roles administrativos conservan vista global o por jerarquía.
- `docs/features/validacion-evidencias.md`: las colas de revisión quedan filtradas
  por `club_section_ids` efectivos para coordinadores.
- `docs/features/validacion-investiduras.md`: los pendientes de investidura quedan
  filtrados por `club_section_ids` efectivos para coordinadores.
