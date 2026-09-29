# 13 · Operación de la sección (recorte de demo)

**Estado:** DRAFT · **Revisión de código local:** 2026-09-14  
**Alcance:** solo lo que un ensayo de 15 minutos puede mostrar de la
operación cotidiana. Finanzas, inventario y seguros **existen** en código;
no se profundizan. Rankings, comunicaciones y SLA: fuera
([12](12-supervision-institucional.md) ya cubre el SLA).

> No es auditoría de tesorería ni de logística. Autoridad API:
> `docs/api/ENDPOINTS-LIVE-REFERENCE.md`. Ingreso y año: [06](06-ingreso-inicial.md),
> [07](07-inscripcion-anual.md). Camporee: [11](11-camporees.md).

## Cinco mensajes para la presentación

1. **La operación vive en la sección, no en el club suelto.** Roster,
   cargos, unidades y actividades se atan a `club_sections`. El club es
   identidad; la etiqueta es `{club.name} · {tipo}`
   (`docs/features/gestion-clubs.md`:104-105).
2. **Unidad ≠ sección ≠ clase.** La unidad es un grupo menor (capitán,
   consejero, planilla semanal). La clase es formación ([08](08-clases-progresivas.md)).
   El cargo pedagógico (`class_counselor_assignments`) no es el cargo
   operativo.
3. **Registrar una actividad no prueba que se realizó.** Hay calendario
   (`activities`) y, aparte, asistencia de esa actividad. La planilla
   semanal de la unidad es **otro** circuito (puntos por categoría).
4. **Finanzas, inventario y seguros no entran al recorrido de hoy.** Si
   preguntan: “está en el sistema; no es esta sesión”. Seguro sí es
   **condición** para inscribir personas a camporee ([11](11-camporees.md)).
5. **Cupos de directiva son duros.** Un director, dos subdirectores, un
   secretario, un tesorero; `secretary-treasurer` excluye los dos cargos
   separados (`gestion-clubs.md`:98-99).

## Cómo leer la evidencia

- **Canon/contrato:** `docs/features/gestion-clubs.md`, `actividades.md`,
  `weekly-records.md`. Seguros/finanzas/inventario: solo la tabla de
  “existe / no entra”.
- **Código:** clubs, units, activities. Pruebas **no ejecutadas**.
- **Disponibilidad:** app y panel tienen superficies; el ensayo usa datos
  ficticios, no un club real de la UMI.

## Vocabulario

| Término | Significado | No confundir con |
|---|---|---|
| Club | Identidad permanente (una iglesia) | Cada tipo como club aparte |
| Sección | Slot tipado `active` (AV / CQ / GM) | Unidad |
| Unidad | Subgrupo de la sección (`units`) | Clase progresiva |
| Planilla semanal | Puntos por categoría de la unidad | Asistencia de una actividad |
| Actividad | Evento del calendario del club | Camporee / evento puntuable |

## Recorte que sí se puede enseñar

```text
Sección activa
  ├─ miembros (cargo anual + current_class)
  ├─ unidades (una activa por persona en la sección)
  ├─ actividades (calendario; asistencia la registra la directiva, no el miembro)
  └─ planilla semanal (solo semana vigente, America/Mexico_City)
```

**Miembros.** Listado por sección con rol y clase del año
(`GET .../sections/:sectionId/members`). No inferir “sin clase” en el
cliente si el backend no mandó `current_class`. Perfil básico: misma
sección, asignación activa o pendiente.

**Unidades.** Pertenecen a una sección. Alta exige `club_section_id`
(`units.service.ts`:207-218). Un miembro debe tener cargo activo en esa
sección (`UNIT_USER_NOT_IN_SECTION`) y **una sola** unidad activa ahí
(`UNIT_MEMBER_ALREADY_IN_SECTION`, `units.service.ts`:300-329). App:
lista filtrada por sección activa; no mostrar unidades de Aventureros
al operar Conquistadores.

**Actividades.** Crean director, subdirector, secretaría o consejero
(`activities:create` o roles legacy). Asistencia: no es auto-servicio;
QR / panel con `attendance:manage` o roles operativos
(`actividades.md`:103). Serie recurrente ≠ actividad conjunta
(varias secciones). Registrada ≠ ejecutada
([12](12-supervision-institucional.md) dashboard).

**Planilla semanal.** Semana domingo–sábado, hora México. Escritura
solo semana vigente. `attendance` / `punctuality` en tabla son
**legado**; los puntos salen de categorías del campo
(`weekly-records.md`:9). No es “pasar lista del camporee”.

## Existe / no entra hoy

| Dominio | Estado declarado | En el demo |
|---|---|---|
| Finanzas del club | `IMPLEMENTADO` | No. Informe mensual puede mostrar un snapshot; no abrir tesorería |
| Inventario | `IMPLEMENTADO` | No. No es logística de camporee |
| Seguros | `IMPLEMENTADO` | Solo si se ensaya inscripción de **personas** a camporee |
| Rankings / miembro del mes | `IMPLEMENTADO` | No |
| Comunicaciones | `IMPLEMENTADO` | No |

## Excepciones útiles si la demo toca operación

| Código | Significado |
|---|---|
| `UNIT_USER_NOT_IN_SECTION` | No tiene cargo en esa sección |
| `UNIT_MEMBER_ALREADY_IN_SECTION` | Ya está en otra unidad activa de la misma sección |
| `UNIT_WEEKLY_RECORD` periodo cerrado | No se edita semana anterior |
| Cupo de rol | Directiva llena; no “otro director extra” |

## Guion mínimo (si hay tiempo tras el núcleo)

Núcleo del ensayo: ingreso → año → evidencia ([ensayo](presentacion/ensayo-cuentas-ficticias.md)).
Esto es **opcional**:

1. App, sección activa: lista de miembros. Decir: cargo anual, no el club entero.
2. Una unidad: “grupo de trabajo; no es la clase”.
3. Una actividad del calendario. Decir: esto no puntúa camporee ni ranking
   por sí solo.

Si el tiempo se acaba: saltar este bloque. Unión no viene a ver tesorería.

## Fuentes

- `docs/features/gestion-clubs.md`, `actividades.md`, `weekly-records.md`.
- Código: `units.service.ts`, `clubs.service.ts`.
- Relacionadas: [01](01-fundamentos.md), [07](07-inscripcion-anual.md),
  [11](11-camporees.md), [12](12-supervision-institucional.md).
