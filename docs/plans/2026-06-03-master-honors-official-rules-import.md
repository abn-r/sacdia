# Plan de importación de reglas oficiales de maestrías

**Estado**: DRAFT  
**Fecha**: 2026-06-03  
**Dominio**: Honores / Maestrías

## Objetivo

Definir cómo auditar las asignaciones actuales de `honors.master_honor_id` y cómo preparar la carga controlada de reglas oficiales configurables para `master_honors`.

## Contexto

Las maestrías no deben depender de una relación plana `honors.master_honor_id`. La obtención se evalúa con reglas configurables por maestría:

- grupos explícitos de especialidades equivalentes;
- grupos por conteo dentro de una categoría de especialidades;
- mínimo requerido por grupo;
- filosofía y notas visibles para administración;
- aplicabilidad global o por divisiones.

Solo cuentan especialidades aprobadas institucionalmente (`users_honors.validation_status = APPROVED`) y activas.

## Datos oficiales requeridos

Cada maestría necesita una fuente curada con estos campos:

| Campo | Requerido | Descripción |
|---|---:|---|
| `master_honor_id` o clave externa estable | Sí | Identificador de la maestría existente o clave para resolverla por nombre. |
| `name` | Sí | Nombre oficial de la maestría. |
| `philosophy` | No | Texto de filosofía cuando aplique. |
| `notes` | No | Notas oficiales, sustituciones o exclusiones. |
| `applicability_scope` | Sí | `ALL` o `SELECTED_DIVISIONS`. |
| `division_ids` | Condicional | Requerido si `applicability_scope = SELECTED_DIVISIONS`. |
| `groups[].group_type` | Sí | `EXPLICIT_OPTIONS` o `CATEGORY_COUNT`. |
| `groups[].minimum_required` | Sí | Cantidad mínima requerida dentro del grupo. |
| `groups[].honors_category_id` | Condicional | Requerido para grupos `CATEGORY_COUNT`. |
| `groups[].options[].label` | Condicional | Nombre oficial de la opción para grupos explícitos. |
| `groups[].options[].honor_ids` | Condicional | Especialidades equivalentes que satisfacen una opción explícita. |
| `groups[].active` / `options[].active` | No | Permite conservar historia al retirar opciones. |

## Auditoría de asignaciones actuales

La auditoría debe confirmar cuántas especialidades siguen asignadas por la columna legacy `honors.master_honor_id`.

Salida mínima recomendada:

```text
master_honor_id | master_honor_name | assigned_honor_count
1               | ...               | 999
2               | ...               | 0
```

Para cada maestría con asignaciones, la auditoría debe listar también:

```text
honor_id | honor_name | category_id | category_name | master_honor_id | master_honor_name
```

Uso esperado:

1. Detectar especialidades asignadas incorrectamente a la maestría 1.
2. Separar asignaciones útiles de relaciones legacy accidentales.
3. Preparar una matriz manual de equivalencias antes de importar reglas.

## Formato recomendado de importación

Usar JSON curado bajo una ruta controlada, por ejemplo:

```text
sacdia-backend/prisma/data/master-honor-rules.official.json
```

Ejemplo de forma:

```json
{
  "version": "2026-06-official-draft",
  "master_honors": [
    {
      "master_honor_id": 2,
      "name": "Maestría en Acuática",
      "philosophy": "Las especialidades de la Maestría en Acuática enfatizan la recreación acuática.",
      "notes": "Seguridad Básica en el Agua, Natación I y su nivel avanzado no se incluyen en esta lista.",
      "applicability_scope": "ALL",
      "division_ids": [],
      "groups": [
        {
          "group_type": "EXPLICIT_OPTIONS",
          "title": "Especialidades acuáticas",
          "minimum_required": 7,
          "display_order": 1,
          "options": [
            {
              "label": "Buceo",
              "display_order": 1,
              "honor_ids": [101]
            },
            {
              "label": "Buceo con escafandra y/o avanzado",
              "display_order": 2,
              "honor_ids": [102, 103]
            }
          ]
        }
      ]
    }
  ]
}
```

## Reglas de importación

- El importador debe correr en modo `dry-run` por defecto.
- Debe validar que todos los `master_honor_id`, `division_ids`, `honors_category_id` y `honor_ids` existan.
- Debe rechazar grupos explícitos donde `minimum_required` sea mayor que la cantidad de opciones activas.
- Debe mantener historia desactivando grupos/opciones retiradas en lugar de borrarlas, salvo migración inicial aprobada.
- Debe disparar recálculo de usuarios afectados después de aplicar cambios reales.
- No debe cambiar `users_master_honors` directamente; el evaluador es la fuente de estado.

## Scripts propuestos

### Auditoría

Ruta sugerida:

```text
sacdia-backend/scripts/audit-master-honor-assignments.ts
```

Responsabilidades:

- reportar conteo por maestría;
- listar especialidades asignadas a la maestría 1;
- exportar CSV/JSON para revisión manual;
- no modificar datos.

### Importación

Ruta sugerida:

```text
sacdia-backend/scripts/import-master-honor-rules.ts
```

Responsabilidades:

- leer JSON oficial curado;
- validar integridad referencial;
- hacer upsert de maestrías, divisiones aplicables, grupos y opciones;
- reportar diferencias antes de aplicar;
- en modo real, encolar recálculo por maestría modificada.

## Estado actual y bloqueo

La implementación técnica ya permite reglas configurables, pero la importación oficial queda bloqueada hasta tener una fuente curada y revisada de requisitos por maestría.

Mientras no exista esa fuente, no se debe inferir automáticamente que todas las especialidades con `master_honor_id = 1` pertenecen a esa maestría.
