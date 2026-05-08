# Logros — Borrador para Seed

Editá esta lista como quieras. Cuando estés listo, avisame y la leo para actualizar el seed script.

## Formato de criterios por tipo

```
THRESHOLD:  { event: "...", operator: "gte|lte|eq", target: N, filters?: { key: value } }
STREAK:     { event: "...", operator: "streak", target: N, streak_unit: "day|week|month", grace_period?: N }
COLLECTION: { event: "...", operator: "distinct_count", distinct_field: "campo", target: N }
MILESTONE:  { event: "...", field: "campo", operator: "eq", target: valor }
COMPOUND:   { logic: "AND|OR", conditions: [ ...sub-criterios tipo THRESHOLD... ] }
```

## Eventos disponibles

| Evento | Descripción | Payload |
|--------|-------------|---------|
| `honor.started` | Usuario inicia un honor | honor_id, category_id, honor_name, club_type_id |
| `honor.validated` | Instructor valida un honor | honor_id, category_id, honor_name, club_type_id |
| `activity.attended` | Usuario asiste a actividad | activity_id, activity_type, club_id |
| `class.started` | Usuario se inscribe en clase | class_id, class_name, club_type_id |
| `class.completed` | Usuario completa investidura **(⚠️ PENDIENTE — evento definido pero NO emitido todavía)** | class_id, class_name, club_type_id |
| `camporee.participated` | Miembro registrado en camporee | camporee_id, camporee_name |
| `member_of_month.awarded` | Reconocido como miembro del mes | awarded: true |
| `ranking.calculated` | Ranking anual calculado | award_category, rank_position |

## Club Types (IDs confirmados)

| ID | Nombre | Clases |
|----|--------|--------|
| 1 | Aventureros | 6: Abejas, Castores, Constructor, Corderitos, Manos Ayudadoras, Rayos de Sol |
| 2 | Conquistadores | 6: Amigo, Compañero, Explorador, Orientador, Viajero, Guía |
| 3 | Guías Mayores | 1: Guía Mayor |

---

## Categorías

| # | Nombre | Ícono (lucide) | Descripción |
|---|--------|----------------|-------------|
| 1 | Progresión | graduation-cap | Logros relacionados con la finalización de clases e investiduras |
| 2 | Especialidades | award | Logros relacionados con honores y especialidades obtenidas |
| 3 | Asistencia | calendar-check | Logros basados en la asistencia a actividades del club |
| 4 | Exploración | compass | Logros relacionados con la participación en camporees y eventos |
| 5 | Liderazgo | users | Logros relacionados con roles de liderazgo y reconocimientos |
| 6 | Dedicación | flame | Logros de racha y compromiso a largo plazo |

---

## Logros

> ⚠️ Los logros que usan `class.completed` no se desbloquearán automáticamente hasta que se implemente la emisión de ese evento en `classes.service.ts`. Ya están definidos para cuando se active.

### Categoría: Progresión — Aventureros

| Nombre | Tipo | Tier | Puntos | Secreto | Repetible | Prerequisito | Criterio |
|--------|------|------|--------|---------|-----------|--------------|----------|
| Primer Paso | THRESHOLD | BRONZE | 10 | No | No | — | `{ "event": "class.started", "operator": "gte", "target": 1 }` |
| Primera Investidura Aventurero | THRESHOLD | BRONZE | 20 | No | No | — | `{ "event": "class.completed", "operator": "gte", "target": 1, "filters": { "club_type_id": 1 } }` |
| Aventurero Avanzado | THRESHOLD | SILVER | 40 | No | No | Primera Investidura Aventurero | `{ "event": "class.completed", "operator": "gte", "target": 3, "filters": { "club_type_id": 1 } }` |
| Aventurero Completo | THRESHOLD | GOLD | 75 | No | No | Aventurero Avanzado | `{ "event": "class.completed", "operator": "gte", "target": 6, "filters": { "club_type_id": 1 } }` |

### Categoría: Progresión — Conquistadores

| Nombre | Tipo | Tier | Puntos | Secreto | Repetible | Prerequisito | Criterio |
|--------|------|------|--------|---------|-----------|--------------|----------|
| Primera Investidura Conquistador | THRESHOLD | BRONZE | 20 | No | No | — | `{ "event": "class.completed", "operator": "gte", "target": 1, "filters": { "club_type_id": 2 } }` |
| Conquistador Avanzado | THRESHOLD | SILVER | 40 | No | No | Primera Investidura Conquistador | `{ "event": "class.completed", "operator": "gte", "target": 3, "filters": { "club_type_id": 2 } }` |
| Conquistador Completo | THRESHOLD | GOLD | 75 | No | No | Conquistador Avanzado | `{ "event": "class.completed", "operator": "gte", "target": 6, "filters": { "club_type_id": 2 } }` |

### Categoría: Progresión — Guías Mayores

| Nombre | Tipo | Tier | Puntos | Secreto | Repetible | Prerequisito | Criterio |
|--------|------|------|--------|---------|-----------|--------------|----------|
| Guía Mayor Investido | THRESHOLD | PLATINUM | 100 | No | No | — | `{ "event": "class.completed", "operator": "gte", "target": 1, "filters": { "club_type_id": 3 } }` |

### Categoría: Progresión — Transiciones

| Nombre | Tipo | Tier | Puntos | Secreto | Repetible | Prerequisito | Criterio |
|--------|------|------|--------|---------|-----------|--------------|----------|
| De Aventurero a Conquistador | COMPOUND | GOLD | 60 | No | No | Aventurero Completo | `{ "logic": "AND", "conditions": [{ "event": "class.completed", "operator": "gte", "target": 6, "filters": { "club_type_id": 1 } }, { "event": "class.completed", "operator": "gte", "target": 1, "filters": { "club_type_id": 2 } }] }` |
| De Conquistador a Guía Mayor | COMPOUND | PLATINUM | 100 | No | No | Conquistador Completo | `{ "logic": "AND", "conditions": [{ "event": "class.completed", "operator": "gte", "target": 6, "filters": { "club_type_id": 2 } }, { "event": "class.completed", "operator": "gte", "target": 1, "filters": { "club_type_id": 3 } }] }` |

### Categoría: Especialidades

| Nombre | Tipo | Tier | Puntos | Secreto | Repetible | Prerequisito | Criterio |
|--------|------|------|--------|---------|-----------|--------------|----------|
| Primer Honor | THRESHOLD | BRONZE | 10 | No | No | — | `{ "event": "honor.validated", "operator": "gte", "target": 1 }` |
| Coleccionista | THRESHOLD | SILVER | 25 | No | No | — | `{ "event": "honor.validated", "operator": "gte", "target": 15 }` |
| Maestro de Especialidades | THRESHOLD | GOLD | 50 | No | No | — | `{ "event": "honor.validated", "operator": "gte", "target": 30 }` |
| Explorador de Categorías | COLLECTION | SILVER | 30 | No | No | — | `{ "event": "honor.validated", "operator": "distinct_count", "distinct_field": "category_id", "target": 3 }` |
| Diversificado | COLLECTION | GOLD | 50 | No | No | — | `{ "event": "honor.validated", "operator": "distinct_count", "distinct_field": "category_id", "target": 5 }` |

### Categoría: Asistencia

| Nombre | Tipo | Tier | Puntos | Secreto | Repetible | Prerequisito | Criterio |
|--------|------|------|--------|---------|-----------|--------------|----------|
| Primera Actividad | THRESHOLD | BRONZE | 10 | No | No | — | `{ "event": "activity.attended", "operator": "gte", "target": 1 }` |
| Participante Activo | THRESHOLD | SILVER | 25 | No | No | — | `{ "event": "activity.attended", "operator": "gte", "target": 10 }` |

### Categoría: Exploración

| Nombre | Tipo | Tier | Puntos | Secreto | Repetible | Prerequisito | Criterio |
|--------|------|------|--------|---------|-----------|--------------|----------|
| Primer Camporee | THRESHOLD | BRONZE | 15 | No | No | — | `{ "event": "camporee.participated", "operator": "gte", "target": 1 }` |
| Veterano de Camporees | THRESHOLD | SILVER | 35 | No | No | Primer Camporee | `{ "event": "camporee.participated", "operator": "gte", "target": 5 }` |
| Explorador Total | COMPOUND | PLATINUM | 100 | No | No | — | `{ "logic": "AND", "conditions": [{ "event": "honor.validated", "operator": "gte", "target": 5 }, { "event": "camporee.participated", "operator": "gte", "target": 1 }, { "event": "activity.attended", "operator": "gte", "target": 20 }] }` |

### Categoría: Liderazgo

| Nombre | Tipo | Tier | Puntos | Secreto | Repetible | Prerequisito | Criterio |
|--------|------|------|--------|---------|-----------|--------------|----------|
| Miembro del Mes | MILESTONE | GOLD | 50 | No | No | — | `{ "event": "member_of_month.awarded", "field": "awarded", "operator": "eq", "target": true }` |

### Categoría: Dedicación

| Nombre | Tipo | Tier | Puntos | Secreto | Repetible | Prerequisito | Criterio |
|--------|------|------|--------|---------|-----------|--------------|----------|
| Fiel | STREAK | SILVER | 30 | No | No | — | `{ "event": "activity.attended", "operator": "streak", "target": 4, "streak_unit": "week" }` |
| Inquebrantable | STREAK | GOLD | 60 | No | No | — | `{ "event": "activity.attended", "operator": "streak", "target": 8, "streak_unit": "week" }` |
| Leyenda | STREAK | PLATINUM | 100 | No | No | — | `{ "event": "activity.attended", "operator": "streak", "target": 16, "streak_unit": "week" }` |
| Leyenda Viviente | COMPOUND | DIAMOND | 200 | **Sí** | No | — | `{ "logic": "AND", "conditions": [{ "event": "honor.validated", "operator": "gte", "target": 10 }, { "event": "activity.attended", "operator": "streak", "target": 16, "streak_unit": "week" }, { "event": "camporee.participated", "operator": "gte", "target": 2 }] }` |
