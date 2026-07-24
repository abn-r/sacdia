# Diseño: Alineación de nombres y ranking anual institucional

**Estado**: DRAFT aprobado como dirección de producto  
**Fecha**: 2026-05-31  
**Alcance**: `sacdia-backend`, `sacdia-admin`, `sacdia-app`, documentación canónica  
**Continúa / corrige**: `docs/plans/2026-05-28-annual-ranking-scorecard-design.md`

## 1. Problema

Hoy SACDIA mezcla dos discusiones que deben separarse:

1. **Lenguaje de dominio**: la app dice "carpeta de evidencias", backend/DB usa
   `annual_folders`, admin habla de "carpeta anual". Esto da la impresión de que
   existen conceptos distintos cuando, para el flujo actual, se trata de la misma
   unidad funcional.
2. **Ranking anual**: la configuración real consultada para ACV / 2026 /
   Conquistadores usa tres componentes (`annual_folder`, `finance`, `camporee`),
   pero producto quiere que el ranking mida tanto cumplimiento administrativo como
   vida operativa del club. Solo carpeta + finanzas + camporee queda corto.

El ranking debe ser explicable. Si el sistema solo devuelve un total sin mostrar
qué eje lo compone, se vuelve una caja negra y pierde valor formativo.

## 2. Decisiones de producto

### 2.1 Nombre canónico

El término visible y documental será:

> **Carpeta Anual de Evidencias**

Uso esperado:

| Capa | Nombre recomendado |
|---|---|
| App móvil | Carpeta Anual de Evidencias |
| Admin | Carpeta Anual de Evidencias |
| Docs/API | Carpeta Anual de Evidencias |
| Backend servicios/DTO nuevos | `annualEvidenceFolder` |
| DB física existente | mantener `annual_folders` por compatibilidad |
| Ranking component key nuevo | `annual_evidence_folder` |
| Alias legacy aceptado temporalmente | `annual_folder` |

No se recomienda renombrar tablas físicas ahora. Renombrar DB agrega riesgo alto
y poco valor inmediato. El cambio importante es alinear UI/API/docs y exponer un
alias claro en servicios nuevos.

### 2.2 Ranking por ejes

El ranking anual medirá dos ejes principales:

```text
Ranking anual = 100%
├─ Cumplimiento Administrativo = 50% default configurable
└─ Vida Operativa del Club = 50% default configurable
```

Ambos ejes pesan igual por defecto, pero deben ser configurables dentro del
sistema por:

```text
local_field_id + ecclesiastical_year_id + club_type_id
```

El campo local debe poder ajustar:

- máximo anual total;
- presupuesto/peso de cada eje;
- componentes activos dentro de cada eje;
- puntos máximos de cada componente.

## 3. Modelo de scoring propuesto

### 3.1 Configuración anual

`annual_ranking_configs` sigue representando el máximo anual por campo/año/tipo.

Ejemplo default:

| Config | Puntos |
|---|---:|
| Máximo anual | 10,000 |
| Cumplimiento Administrativo | 5,000 |
| Vida Operativa | 5,000 |

### 3.2 Ejes

Nuevo concepto lógico: **axis**.

| Campo lógico | Ejemplo |
|---|---|
| `axis_key` | `administrative`, `operational` |
| `label` | Cumplimiento Administrativo |
| `max_points` | 5,000 |
| `sort_order` | 1 |
| `active` | true |

Validación:

```text
SUM(active axis.max_points) = annual_ranking_configs.max_points
```

### 3.3 Componentes iniciales

#### Cumplimiento Administrativo

| Component key | Nombre | Fuente esperada | Nota |
|---|---|---|---|
| `annual_evidence_folder` | Carpeta Anual de Evidencias | `annual_folders` + evaluaciones | Reemplaza alias legacy `annual_folder` |
| `monthly_reports_timeliness` | Informes mensuales a tiempo | `monthly_reports` | Debe considerar deadline configurable |
| `finance_compliance` | Cumplimiento financiero | cierres/reportes financieros | Reusa lógica actual de finanzas |
| `institutional_data_completeness` | Datos institucionales completos | club/enrollment/roles/schedule | Mide completitud, no volumen |

#### Vida Operativa del Club

| Component key | Nombre | Fuente esperada | Nota |
|---|---|---|---|
| `activities_registered` | Actividades registradas | `activities` / `activity_instances` | Debe medir realizadas vs meta, no solo creadas |
| `attendance_participation` | Asistencia y participación | fuente de asistencia canónica | Requiere confirmar fuente única |
| `camporee_events` | Camporee y eventos | `camporee_clubs` aprobado | Reemplaza alias legacy `camporee` |
| `class_investiture_progress` | Clases e investiduras | clases/investidura por sección | Agregado por sección/club |
| `sacdia_operational_usage` | Uso operativo de SACDIA | acciones útiles | No medir logins/sesiones como vanity metric |

### 3.4 Regla de cálculo

Cada calculador devuelve un porcentaje `0–100`.

```text
component_points = component_score_pct / 100 * component_max_points
axis_points = SUM(component_points)
axis_progress_pct = axis_points / axis_max_points * 100
total_points = SUM(axis_points)
progress_percentage = total_points / annual_max_points * 100
```

El ranking competitivo administrativo ordena por `total_points DESC` con dense
ranking. La app móvil no muestra leaderboard: muestra su propio scorecard.

## 4. Compatibilidad y migración

### 4.1 Alias de componentes actuales

| Actual | Nuevo | Eje |
|---|---|---|
| `annual_folder` | `annual_evidence_folder` | administrative |
| `finance` | `finance_compliance` | administrative |
| `camporee` | `camporee_events` | operational |
| `evidence` | no usar por defecto | pendiente de redefinir |

`evidence` no debe reactivarse sin una definición precisa porque puede duplicar
lo que ya mide la Carpeta Anual de Evidencias.

### 4.2 Datos existentes

Para configuraciones existentes:

- crear eje `administrative`;
- crear eje `operational`;
- mover `annual_folder` y `finance` a `administrative`;
- mover `camporee` a `operational`;
- si existe `evidence`, dejarlo inactivo o migrarlo solo con decisión explícita;
- preservar puntajes máximos existentes para no alterar resultados históricos sin
  aprobación.

### 4.3 Carpetas actuales

Los puntajes de secciones no se cambian. Ejemplo verificado:

```text
Sección 2 / ACV / Conquistadores / 2026:
7 secciones = 500 puntos máximos de carpeta
annual ranking config = 10,000 puntos
annual_folder actual = 6,000 puntos
```

Esto está alineado por normalización:

```text
carpeta_score_pct = earned_folder_points / max_folder_points
annual_evidence_folder_points = carpeta_score_pct * component_max_points
```

## 5. API/DTO esperado

### App móvil

`GET /api/v1/club-sections/:sectionId/annual-ranking-progress?year_id=1`

Respuesta extendida:

```json
{
  "current_points": 7420,
  "max_points": 10000,
  "progress_percentage": 74.2,
  "axes": [
    {
      "key": "administrative",
      "label": "Cumplimiento Administrativo",
      "earned_points": 3600,
      "max_points": 5000,
      "progress_percentage": 72,
      "components": [
        {
          "key": "annual_evidence_folder",
          "label": "Carpeta Anual de Evidencias",
          "earned_points": 2400,
          "max_points": 3000,
          "progress_percentage": 80
        }
      ]
    }
  ],
  "pending_items": []
}
```

### Admin

El admin debe poder:

- listar configuraciones por campo/año/tipo;
- editar máximo anual;
- editar ejes y componentes;
- validar suma de ejes = máximo anual;
- validar suma de componentes = máximo del eje;
- ver leaderboard con desglose por eje y componente.

## 6. UI esperada

### App

Pantalla de ranking anual propio:

```text
Progreso anual
Total: 7,420 / 10,000

Cumplimiento Administrativo
- Carpeta Anual de Evidencias
- Informes mensuales a tiempo
- Finanzas
- Datos institucionales

Vida Operativa del Club
- Actividades registradas
- Asistencia
- Camporee/eventos
- Clases/investiduras
- Uso operativo SACDIA
```

### Admin

Configuración tipo scorecard:

```text
Configuración anual: ACV / 2026 / Conquistadores
Máximo: 10,000

Eje Administrativo: 5,000
  - Carpeta Anual de Evidencias: 2,500
  - Informes mensuales: 1,250
  - Finanzas: 750
  - Datos institucionales: 500

Eje Operativo: 5,000
  - Actividades: 1,500
  - Asistencia: 1,000
  - Camporee/eventos: 1,000
  - Clases/investiduras: 1,000
  - Uso operativo: 500
```

Los valores anteriores son defaults sugeridos, no regla inmutable.

## 7. Riesgos y controles

| Riesgo | Control |
|---|---|
| Doble conteo de evidencias | No usar `evidence` genérico hasta redefinirlo |
| Vanity metrics de app | Medir acciones útiles, no logins |
| Ranking caja negra | Respuesta y UI deben mostrar ejes/componentes |
| Drift entre DB/docs/UI | Validar component keys contra catálogo canónico |
| Cambio rompe configs existentes | Migrar aliases y preservar puntajes históricos |
| Fuentes operativas incompletas | Activar componentes por fase, con fallback explícito |

## 8. Criterios de aceptación

- La UI usa "Carpeta Anual de Evidencias" en app/admin.
- El backend acepta/migra `annual_folder` como alias, pero expone
  `annual_evidence_folder` en contratos nuevos.
- Ranking anual tiene ejes `administrative` y `operational`.
- Default inicial: 50/50.
- Los pesos son configurables por campo local/año/tipo de club.
- El scorecard móvil muestra ejes y componentes; no muestra leaderboard global.
- El admin muestra leaderboard con desglose por ejes/componentes.
- Tests cubren validación de sumas, alias legacy y cálculo de puntos.

