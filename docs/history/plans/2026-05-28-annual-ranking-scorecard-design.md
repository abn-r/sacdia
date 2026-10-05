# Diseño: Progreso anual por puntos y reconocimientos

**Estado**: DRAFT aprobado como base  
**Fecha**: 2026-05-28  
**Alcance**: `sacdia-backend`, `sacdia-admin`, `sacdia-app`, documentación canónica

## 1. Problema

La experiencia actual de ranking mezcla dos necesidades distintas:

- **Administración**: comparar clubes de un campo local por año y tipo de club.
- **App móvil**: ayudar al director/secretario/tesorero a entender el avance de su propia sección.

El comportamiento móvil actual muestra una lista competitiva de clubes, selector de tipos de club y posición de ranking. Eso no es el objetivo correcto para la app: puede desmotivar clubes pequeños, expone información que no ayuda a la acción diaria y obliga a descargar más datos de los necesarios.

## 2. Decisión de producto

Separar la experiencia:

```text
Admin web = leaderboard completo
App móvil = scorecard propio de progreso anual
Backend = cálculo compartido de puntos, rangos y pendientes
```

La app móvil no debe mostrar el listado global de clubes ni el puesto competitivo. Debe mostrar:

- puntos actuales;
- puntos máximos anuales;
- reconocimiento actual;
- siguiente reconocimiento;
- puntos faltantes;
- desglose por componentes;
- pendientes por entregar, validar, corregir o por vencer.

El admin web sí debe conservar la tabla completa para supervisión por jerarquía.

## 3. Modelo de rangos

Los rangos son **globales a nivel sistema** y se definen como bandas porcentuales acumuladas desde el puntaje máximo hacia abajo.

Ejemplo de configuración global:

| Orden | Rango | Banda |
|---:|---|---:|
| 1 | Diamante | 5% |
| 2 | Oro | 10% |
| 3 | Plata | 15% |
| 4 | Bronce | 20% |

Ejemplo con máximo anual de `10,000`:

| Rango | Desde | Hasta |
|---|---:|---:|
| Diamante | 9,500 | 10,000 |
| Oro | 8,500 | 9,499 |
| Plata | 7,000 | 8,499 |
| Bronce | 5,000 | 6,999 |

La regla es:

```text
upper = max_points * (1 - cumulative_previous_percentage)
lower = max_points * (1 - cumulative_current_percentage)
```

Para puntos enteros, el rango superior de una banda debe quedar justo debajo del mínimo de la banda anterior para evitar solapamientos.

## 4. Modelo de puntos máximos

Los puntos máximos no son globales. Cada campo local decide sus metas anuales por:

```text
local_field_id + ecclesiastical_year_id + club_type_id
```

Ejemplo:

| Campo local | Año | Tipo de club | Máximo anual |
|---|---|---|---:|
| Asociación Centro Veracruz | 2026 | Aventureros | 10,000 |
| Asociación Centro Veracruz | 2026 | Conquistadores | 12,000 |
| Asociación Centro Veracruz | 2026 | Guías Mayores | 9,000 |

El total anual debe componerse de rubros configurables. Ejemplo:

| Componente | Máximo |
|---|---:|
| Carpeta anual | 6,000 |
| Finanzas | 2,000 |
| Camporee | 2,000 |
| Evidencias / validaciones | 2,000 |
| **Total** | **12,000** |

El sistema debe validar que la suma de componentes coincida con el máximo anual configurado.

## 5. Modelo de datos propuesto

### `ranking_tiers`

Configuración global de rangos.

Campos sugeridos:

- `ranking_tier_id`
- `name`
- `slug`
- `band_percentage`
- `color`
- `icon`
- `sort_order`
- `active`
- `created_at`
- `updated_at`

Restricciones:

- `band_percentage > 0`
- `band_percentage <= 100`
- `slug` único
- `sort_order` único entre activos

### `annual_ranking_configs`

Configuración del máximo anual por campo local, año y tipo de club.

Campos sugeridos:

- `annual_ranking_config_id`
- `local_field_id`
- `ecclesiastical_year_id`
- `club_type_id`
- `max_points`
- `active`
- `created_by`
- `updated_by`
- `created_at`
- `updated_at`

Restricción:

- único por `(local_field_id, ecclesiastical_year_id, club_type_id)`

### `annual_ranking_component_configs`

Presupuesto de puntos por componente.

Campos sugeridos:

- `annual_ranking_component_config_id`
- `annual_ranking_config_id`
- `component_key`
- `label`
- `max_points`
- `sort_order`
- `active`

Componentes iniciales:

- `annual_folder`
- `finance`
- `camporee`
- `evidence`

Restricción:

- único por `(annual_ranking_config_id, component_key)`
- suma de componentes activos = `annual_ranking_configs.max_points`

## 6. Cálculo

### Cálculo de puntos por componente

Cada componente puede tener una fuente distinta:

- `annual_folder`: puntos de carpeta/evaluación anual.
- `finance`: score financiero existente convertido a puntos del presupuesto del componente.
- `camporee`: score de participación/eventos convertido a puntos.
- `evidence`: validaciones/evidencias convertidas a puntos.

La regla común:

```text
component_points = component_score_pct / 100 * component_max_points
```

Cuando un componente ya tiene puntos reales, se debe normalizar contra su máximo configurado para mantener consistencia.

### Cálculo de reconocimiento

Con `current_points` y `max_points`:

1. Calcular rangos derivados desde `ranking_tiers`.
2. Encontrar la banda donde cae `current_points`.
3. Calcular `points_to_next_tier` si existe un rango superior.

## 7. API propuesta

### App móvil: progreso propio

```http
GET /api/v1/club-sections/:sectionId/annual-ranking-progress?year_id=1
```

Autorización:

- requiere usuario autenticado;
- debe pertenecer a la sección activa o tener permiso jerárquico equivalente;
- pensado para director, secretario, secretario-tesorero y tesorero según permisos de club.

Respuesta:

```json
{
  "section_id": 2,
  "club_id": 1,
  "club_name": "Halcones",
  "club_type": {
    "club_type_id": 1,
    "name": "Aventureros"
  },
  "year": {
    "ecclesiastical_year_id": 1,
    "name": "2026"
  },
  "current_points": 8450,
  "max_points": 10000,
  "progress_percentage": 84.5,
  "current_tier": {
    "name": "Plata",
    "slug": "plata",
    "color": "#A8A8A8",
    "from_points": 7000,
    "to_points": 8499
  },
  "next_tier": {
    "name": "Oro",
    "slug": "oro",
    "from_points": 8500,
    "to_points": 9499,
    "points_to_reach": 50
  },
  "components": [
    {
      "key": "annual_folder",
      "label": "Carpeta anual",
      "earned_points": 4200,
      "max_points": 6000,
      "progress_percentage": 70
    }
  ],
  "pending_items": [
    {
      "type": "annual_folder_section",
      "title": "Evidencia de actividades misioneras",
      "status": "pending_validation",
      "due_date": "2026-08-15",
      "action_label": "Ver evidencia"
    }
  ]
}
```

### Admin web: leaderboard

Nuevo endpoint recomendado:

```http
GET /api/v1/annual-rankings?local_field_id=4&club_type_id=1&year_id=1
```

El endpoint legacy puede mantenerse temporalmente:

```http
GET /api/v1/annual-folders/rankings
```

pero debe quedar documentado como compatibilidad/deprecación si el ranking deja de ser solo de carpetas.

## 8. App móvil

Pantalla objetivo: **Progreso anual**.

Contenido:

1. Hero card:
   - reconocimiento actual;
   - puntos actuales / máximos;
   - barra de progreso;
   - puntos faltantes al siguiente rango.

2. Desglose:
   - tarjetas por componente;
   - puntos y porcentaje;
   - CTA contextual cuando haya pendientes.

3. Pendientes:
   - vencidos;
   - próximos a vencer;
   - pendientes de validación;
   - rechazados / requieren corrección.

Prohibido en móvil:

- lista de todos los clubes;
- selector manual de tipos de club cuando el usuario ya tiene sección activa;
- estados técnicos (`IN_PROGRESS`, `PENDING`, etc.);
- mensajes que centren la UX en puesto competitivo.

Todos los estados visibles deben pasar por i18n.

## 9. Admin web

Debe incluir:

- CRUD de rangos globales;
- configuración anual por campo local/año/tipo de club;
- presupuesto por componente;
- leaderboard completo con puntos, reconocimiento, posición y desglose;
- filtros por año, campo local, tipo de club y reconocimiento.

## 10. Permisos

Separar permisos conceptualmente:

- progreso propio de club/sección: permiso de rol activo de club;
- leaderboard de campo local: permiso jerárquico de campo local;
- configuración global de rangos: admin/super-admin;
- configuración anual del campo: campo local o rol autorizado.

La implementación debe mapear esto contra el RBAC existente antes de crear permisos nuevos.

## 11. Riesgos

- **Drift con `award_categories` existente**: hoy existen categorías con puntos fijos. Deben migrarse o convivir como legacy sin contaminar el nuevo modelo porcentual.
- **Cálculo de componentes**: algunos componentes ya tienen porcentaje, otros puntos reales. Hay que normalizar con cuidado.
- **Rounding**: rangos derivados deben evitar solapamientos y huecos.
- **Motivación móvil**: no reintroducir ranking competitivo en la app por accidente.
- **Performance**: móvil debe consumir un resumen compacto, no un leaderboard filtrado.

## 12. Criterios de aceptación

- La app móvil muestra solo el progreso de la sección activa.
- La app móvil no muestra ranking global ni selector de tipos ajenos.
- Los rangos se calculan desde porcentajes globales y máximo anual local.
- El admin puede configurar máximos por campo local/año/tipo de club.
- El admin puede ver leaderboard completo con reconocimientos derivados.
- No aparecen estados técnicos sin traducción en UI.
- Los endpoints validan permisos por alcance real.

