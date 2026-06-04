# Diseño: requisitos configurables para maestrías de especialidades

**Estado**: IMPLEMENTADO — infraestructura runtime, admin y app; importación oficial de reglas pendiente
**Fecha**: 2026-06-04
**Dominio**: Honores / Maestrías (`master_honors`)  

## Resumen

Las maestrías de especialidades son parches/logros de la banda del usuario. El
sistema ya tiene el catálogo `master_honors` y una relación simple
`honors.master_honors_id`, pero esa relación no alcanza para modelar los
requisitos reales de obtención.

La decisión de diseño es crear un motor propio de reglas de maestrías:

- configurable desde admin/super-admin;
- basado solo en especialidades ya aprobadas;
- con otorgamiento automático;
- con revocación automática cuando los criterios vigentes dejan de cumplirse;
- con historial visible aunque una maestría quede **No vigente**.

## Estado de implementación

Este diseño ya fue llevado al runtime en los tres frentes principales:

- Backend: schema, evaluador, recálculo, historial, endpoints de usuario/admin y notificaciones `master_honor_changed`.
- Admin: editor de reglas, divisiones aplicables, grupos/opciones y acción de recálculo.
- App móvil: consumo de maestrías de usuario, banda con `Vigente`/`No vigente`, historial de perfil y modal global de cambios.

Pendiente: carga inicial/importación de reglas oficiales. Mientras no exista una fuente curada, `honors.master_honors_id` no debe usarse como verdad de requisitos.

## Contexto verificado

- `master_honors` existe como catálogo de maestrías.
- `honors.master_honors_id` relaciona una especialidad con una maestría, pero no
  representa mínimos, listas, equivalencias ni requisitos compuestos.
- `users_honors.validation_status = APPROVED` representa especialidades ya
  validadas.
- Existe un motor genérico de `achievements`, pero las maestrías son dominio de
  especialidades; por eso no deben depender de `achievements` como fuente
  primaria. Pueden emitir eventos/notificaciones similares.

## Objetivos

1. Permitir configurar requisitos de maestrías desde el panel admin.
2. Otorgar automáticamente una maestría cuando el usuario cumple los criterios.
3. Revocar o marcar como **No vigente** cuando los criterios actuales dejan de
   cumplirse.
4. Mantener visibilidad histórica en banda digital e historial.
5. Notificar al usuario cuando obtiene, recupera o pierde vigencia de una
   maestría.

## No objetivos

- No crear un segundo flujo de revisión manual para maestrías.
- No usar `achievements` como fuente primaria de elegibilidad.
- No permitir configuración por Unión/Campo Local en esta fase.
- No modelar reglas distintas por división. Las reglas son globales; solo la
  aplicabilidad de la maestría puede variar por división.

## Reglas de negocio aprobadas

### Fuente de verdad de elegibilidad

Solo cuentan especialidades activas y aprobadas previamente:

```text
users_honors.validation_status = APPROVED
users_honors.active = true
```

Como estas especialidades ya fueron aprobadas por campo local o coordinadores,
la maestría se otorga directamente sin revisión adicional.

### Tipos de requisitos

El modelo debe cubrir estos casos:

1. **Mínimo desde lista explícita**
   - Ejemplo: desarrollar 7 especialidades de una lista definida.
2. **Mínimo desde categoría**
   - Ejemplo: desarrollar 7 especialidades de la categoría Actividades
     agropecuarias.
3. **Bloques compuestos**
   - Ejemplo: desarrollar 2 obligatorias y, además, 5 de una lista.
4. **Equivalencias manuales**
   - Ejemplo: “Natación III y/o avanzado” cuenta como una sola opción, aunque el
     usuario tenga ambas especialidades.

### Semántica de grupos

Una maestría tiene uno o más grupos de requisitos. Todos los grupos activos deben
cumplirse.

```text
Maestría = Grupo A AND Grupo B AND Grupo C
```

Cada grupo define un mínimo:

```text
Grupo explícito: cumplir N opciones de una lista.
Grupo por categoría: cumplir N especialidades de una categoría.
Grupo obligatorio: mínimo = cantidad total de opciones.
```

### Opción computable

Una opción computable puede contener una o varias especialidades equivalentes.
La opción cuenta máximo 1.

```text
Opción: Natación III
  - Natación III
  - Natación III Avanzado

Si el usuario tiene una o ambas, la opción cuenta como 1.
```

Las equivalencias se configuran manualmente dentro de cada maestría porque pueden
cambiar.

### Vigencia

Los criterios actuales mandan.

- Si el usuario cumple: `AWARDED`.
- Si deja de cumplir criterios: `REVOKED`.
- Si la maestría se desactiva/retira: `RETIRED`.

`REVOKED` y `RETIRED` se muestran como **No vigente**.

La maestría no desaparece de la banda ni del historial. Se muestra con estado
visual claro.

## Aplicabilidad por división

Las reglas son globales, pero una maestría puede aplicar a:

- todas las divisiones;
- divisiones específicas.

Para el primer otorgamiento:

```text
usuario -> club activo -> división actual -> validar aplicabilidad
```

Se guarda `awarded_division_id` como contexto histórico.

Cambios posteriores de club/división no revocan la maestría por sí solos. La
reevaluación usa la división histórica del otorgamiento para determinar si la
maestría sigue aplicando.

## Modelo de datos propuesto

### `master_honors`

Agregar campos de configuración:

```text
applicability_scope: ALL | SELECTED_DIVISIONS
philosophy: text?
notes: text?
```

`active = false` significa que la maestría ya no está vigente ni otorgable, pero
los usuarios que la obtuvieron deben conservar el registro histórico como
**No vigente**.

### `master_honor_divisions`

Lista de divisiones donde aplica una maestría cuando
`applicability_scope = SELECTED_DIVISIONS`.

```text
master_honor_id
division_id
active
created_at
modified_at
```

### `master_honor_requirement_groups`

Bloques de reglas de una maestría.

```text
group_id
master_honor_id
group_type: EXPLICIT_OPTIONS | CATEGORY_COUNT
title
description
minimum_required
honors_category_id?        -- solo para CATEGORY_COUNT
display_order
active
created_at
modified_at
```

### `master_honor_requirement_options`

Opciones computables dentro de un grupo explícito.

```text
option_id
group_id
label
display_order
active
created_at
modified_at
```

### `master_honor_requirement_option_honors`

Especialidades equivalentes que satisfacen una opción.

```text
option_honor_id
option_id
honor_id
active
created_at
modified_at
```

### `users_master_honors`

Estado actual e histórico de la maestría por usuario.

```text
user_master_honor_id
user_id
master_honor_id
status: AWARDED | REVOKED | RETIRED
awarded_at
revoked_at
recovered_at
evaluated_at
awarded_division_id
source: AUTO
status_reason:
  - CRITERIA_CHANGED
  - USER_NO_LONGER_QUALIFIES
  - MASTER_HONOR_INACTIVE
  - RECOVERED
evaluation_snapshot JSON
active
created_at
modified_at
```

`evaluation_snapshot` debe guardar qué grupos, opciones y especialidades
contaron para la decisión. Esto permite explicar por qué se otorgó, revocó o
recuperó una maestría.

### `master_honor_evaluation_history`

Historial auditable de cada cambio de estado.

```text
history_id
user_master_honor_id
user_id
master_honor_id
from_status
to_status
reason
evaluation_snapshot JSON
created_at
created_by_job_id?
```

## Evaluador automático

### Disparadores

El evaluador debe ejecutarse cuando:

1. una especialidad del usuario pasa a `APPROVED`;
2. una especialidad aprobada deja de estar aprobada o se desactiva;
3. se editan reglas de una maestría;
4. se activa/desactiva una maestría;
5. se cambia la aplicabilidad por división;
6. se ejecuta un backfill/recalculo administrativo.

### Flujo de evaluación por usuario

1. Obtener especialidades aprobadas del usuario.
2. Obtener maestrías activas o históricamente relevantes.
3. Resolver aplicabilidad:
   - primer otorgamiento: división del club activo;
   - reevaluación: `awarded_division_id` si ya existe registro.
4. Evaluar todos los grupos activos.
5. Crear o actualizar `users_master_honors`.
6. Registrar `master_honor_evaluation_history`.
7. Emitir notificación si cambia el estado.

### Recalculo por edición de reglas

Editar reglas en admin debe disparar un recálculo automático. Para no bloquear el
panel, el backend debe encolar un job de recálculo:

```text
admin guarda reglas -> backend persiste cambios -> encola recálculo -> UI muestra estado
```

## Admin

Solo `admin` y `super-admin` pueden configurar reglas.

Superficie recomendada:

```text
Catálogos -> Maestrías
  - datos básicos
  - filosofía / notas
  - divisiones aplicables
  - grupos de requisitos
  - opciones computables
  - equivalencias por opción
  - vista previa de impacto / recálculo
```

El admin puede editar reglas aunque ya existan usuarios con la maestría. El
sistema recalcula y actualiza estados según los criterios actuales.

## App móvil y banda digital

La app debe mostrar:

- maestrías vigentes;
- maestrías **No vigente**;
- historial de maestrías;
- sello/leyenda visual para `REVOKED` y `RETIRED`.

La banda digital muestra ambas, pero diferenciadas:

```text
Vigente: parche normal.
No vigente: parche visible + sello “No vigente”.
```

## Notificaciones

Se debe notificar cuando:

1. el usuario obtiene una maestría;
2. el usuario recupera vigencia;
3. la maestría queda marcada como **No vigente**.

### Copy neutral

El copy del producto debe usar español neutral, sin voseo ni modismos
regionales.

Obtenida:

```text
¡Nueva maestría obtenida!
Has obtenido la maestría {nombre}.
```

Recuperada:

```text
Maestría vigente nuevamente
La maestría {nombre} vuelve a estar vigente en tu perfil.
```

No vigente:

```text
Maestría marcada como No vigente
Las validaciones requeridas para la maestría {nombre} cambiaron. Actualmente no cumples con los requisitos, por lo que quedó marcada como No vigente.
```

## Modal elegante

La app debe mostrar un modal elegante global en cualquier pantalla para los tres
casos:

- obtenida;
- recuperada;
- No vigente.

El modal debe estar implementado como overlay/cola a nivel aplicación para evitar
apilar diálogos.

Si varias maestrías cambian al mismo tiempo, se muestra un solo modal resumido
con los nombres de las maestrías.

Ejemplo:

```text
¡Nuevas maestrías obtenidas!
Has obtenido:
- Maestría en Acuática
- Maestría en Artesanía
- Maestría en Actividades agrícolas
```

## Relación con achievements

Las maestrías no deben depender de `achievements` para determinar elegibilidad.

Opcionalmente, el cambio de estado de una maestría puede emitir eventos o
notificaciones con una UX similar a logros, pero la fuente de verdad debe ser:

```text
master_honors + reglas + users_master_honors
```

## Migraciones y datos

La implementación requiere migraciones de base de datos.

También requiere una carga inicial de reglas oficiales de maestrías. Antes de
usar `honors.master_honors_id` como insumo, hay que auditarlo porque puede
contener asignaciones incorrectas, por ejemplo especialidades apuntando
masivamente a `master_honors_id = 1`.

`honors.master_honors_id` no debe ser la fuente de verdad para requisitos. Puede
quedar como relación de catálogo o eliminarse en una fase posterior si se vuelve
redundante.

## Testing mínimo

### Backend

- evalúa mínimo desde lista explícita;
- evalúa mínimo desde categoría;
- evalúa grupos compuestos;
- cuenta equivalencias como una sola opción;
- otorga automáticamente;
- revoca cuando deja de cumplir;
- marca `RETIRED` cuando la maestría se desactiva;
- usa división de club activo para primer otorgamiento;
- no revoca por cambio posterior de división;
- recalcula después de editar reglas;
- emite notificaciones correctas.

### Admin

- solo admin/super-admin pueden editar reglas;
- builder de grupos/opciones valida mínimos;
- edición de reglas dispara recálculo;
- muestra advertencia de impacto.

### App

- muestra vigente y No vigente en banda;
- muestra histórico;
- muestra modal global en cualquier pantalla;
- agrupa múltiples maestrías en un solo modal;
- usa español neutral.

## Riesgos

- Reglas oficiales incompletas o mal cargadas.
- Asignaciones actuales de `honors.master_honors_id` incorrectas.
- Recalcular muchos usuarios puede ser costoso si se hace sin cola.
- Mostrar No vigente sin explicación puede parecer castigo; el copy debe ser
  claro y neutral.

## Decisión final

Implementar maestrías como un dominio propio con reglas configurables,
otorgamiento automático, recalculo continuo, estado histórico visible y
notificaciones elegantes. Los criterios vigentes mandan, pero el historial del
usuario nunca se borra.
