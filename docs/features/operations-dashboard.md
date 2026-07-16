# Dashboard operativo jerárquico

**Estado:** backend implementado en la rama de trabajo; consumo admin pendiente
**Endpoint:** `GET /api/v1/admin/analytics/operations-dashboard`
**Versión de definiciones:** `1`

El dashboard entrega un corte agregado para el alcance territorial autorizado y sus hijos inmediatos. Su objetivo es apoyar decisiones operativas sin confundir el estado administrativo de un registro, la operación anual de una sección y el estado técnico de una cuenta.

## Contrato rápido

```http
GET /api/v1/admin/analytics/operations-dashboard
  ?ecclesiastical_year_id=<int>
  &division_id=<int>
  &union_id=<int>
  &local_field_id=<int>
  &report_year=<int>
  &report_month=<1..12>
Authorization: Bearer <jwt>
```

- Todos los query params son opcionales y, cuando aparecen, son enteros positivos.
- `report_year` y `report_month` deben enviarse juntos.
- Sin `ecclesiastical_year_id`, el backend selecciona el año activo más reciente por `start_date`.
- Sin periodo mensual explícito, selecciona el último mes calendario cerrado dentro del año. Si el año todavía no tiene un mes cerrado, `meta.period.reporting_month` es `null`.
- Los filtros territoriales solo reducen el alcance efectivo; nunca lo amplían.
- La respuesta exitosa usa `{ "status": "ok", "data": { ... } }`.

El shape completo y los errores canónicos están en [ENDPOINTS-LIVE-REFERENCE.md](../api/ENDPOINTS-LIVE-REFERENCE.md). La matriz de autorización está en [SECURITY-GUIDE.md](../api/SECURITY-GUIDE.md).

## Jerarquía

La misma vista se reutiliza para todos los actores. `meta.scope` identifica el corte actual y `children` devuelve el nivel inmediato siguiente:

| Scope actual | `children[].level` |
| --- | --- |
| `all` | `division` |
| `division` | `union` |
| `union` | `local_field` |
| `local_field` | `club` |

Cada child incluye el mismo conjunto de familias métricas que `summary`, incluido `classes.by_class`. El cliente debe usar `summary` como total autoritativo y no reconstruirlo sumando children.

## Periodos

`meta.period.ecclesiastical_year` contiene `id`, fechas y el flag `active`. La condición de matrícula anual depende de ese flag:

- año vigente: `club_enrollments.status = 'active'`;
- año histórico: `club_enrollments.status IN ('active', 'closed')`.

Esta condición se usa para clubes/secciones operativas, denominador de informes, actividades y carpetas anuales pendientes. `report_year`/`report_month` afecta únicamente `monthly_reports`; las demás familias conservan el grano indicado en sus definiciones.

Un periodo explícito se acepta si su mes cae entre los meses inicial y final del año eclesiástico, inclusive. El contrato no expone un flag que asegure que ese periodo explícito ya esté cerrado.

## Definiciones y fórmulas

### Clubes administrativos

Fuente: `clubs` unido a la jerarquía territorial actual.

- `total`: `COUNT(DISTINCT clubs.club_id)`.
- `active`: clubes distintos con `clubs.active = true`.
- `inactive`: clubes distintos con `clubs.active = false`.

`clubs.active` es un estado administrativo. No determina si el club operó durante un año eclesiástico.

### Operación anual

Fuente: `club_enrollments → club_sections → clubs`.

- `operational_clubs`: clubes distintos con al menos una matrícula anual de sección elegible.
- `operational_sections`: secciones distintas con matrícula elegible.
- `non_operational_clubs = max(administrative_clubs.total - operational_clubs, 0)`.
- `operational_rate_pct = operational_clubs / administrative_clubs.total × 100`, redondeado a dos decimales; es `null` cuando el denominador es `0`.

No se agregan filtros por `clubs.active` ni `club_sections.active` a la definición operativa.

### Personas y cuentas de plataforma

Fuente: `club_role_assignments` del año, con `active = true` y `status = 'active'`.

- `people.institutionally_active`: personas distintas con una asignación institucional dentro del scope.
- `platform_accounts.active|inactive`: estado `users.active` dentro de ese mismo conjunto de personas.

“Persona institucionalmente activa” no equivale a “cuenta de usuario activa” ni a una definición general de membresía.

### Clases

Fuente: enrollments activos del año, relacionados con una asignación institucional activa del mismo usuario, año y tipo de club.

- `total_enrollments`: enrollments distintos.
- `distinct_people`: personas distintas con enrollment.
- `by_class[].enrollment_count`: enrollments distintos por clase y tipo de club.

La atribución territorial usa afiliaciones institucionales del mismo año, pero el schema no guarda un `section_id` en el enrollment. Una persona con afiliaciones compatibles en varios hijos puede aparecer en más de una fila hija; por eso clases tiene calidad `current_affiliation` y los children no son aditivos.

### Informes mensuales

Denominador: matrículas anuales de sección elegibles para el año. Se hace `LEFT JOIN` con `monthly_reports` por `club_enrollment_id`, año y mes.

- `expected_sections`: matrículas de sección esperadas.
- `submitted_sections`, `draft_sections`, `generated_sections`: matrículas distintas por estado del informe.
- `missing_sections`: matrículas sin registro mensual.
- `coverage_pct = submitted_sections / expected_sections × 100`, redondeado a dos decimales; es `null` con denominador `0`.

Si no existe un mes cerrado por defecto, no se ejecuta la consulta mensual: los cinco conteos son `0`, `coverage_pct` es `null` y `data_quality` marca `monthly_reports` como `not_applicable`. No debe interpretarse como incumplimiento.

### Especialidades

Solo se consultan cuando el año seleccionado tiene `active = true`. El scope se infiere desde las personas institucionales de ese año y `users_honors.active = true`.

- `in_progress`: `validation_status = 'IN_PROGRESS'`.
- `pending_review`: `validation_status = 'PENDING_REVIEW'`.
- `approved`: `validation_status = 'APPROVED'`.

Son stocks actuales por afiliación, no aprobaciones del mes reportado. Para un año histórico los tres valores son `null` y `attribution = 'unavailable'`; no se fabrican ceros históricos.

### Actividades

Fuente: `activities` activas dentro de las fechas inclusivas del año, con `activity_instances.active = true` y sección participante con matrícula anual elegible.

- `registered`: actividades distintas registradas.
- `joint_registered`: actividades distintas con `is_joint = true`.
- `distinct_participating_sections`: secciones participantes distintas.

Una actividad registrada no demuestra que se realizó ni representa asistencia.

### Colas operativas

| Campo | Definición runtime |
| --- | --- |
| `role_assignments_pending` | `role_assignment_requests.status = 'pending'` |
| `transfers_pending` | `club_transfer_requests.status = 'pending'`, atribuida a `to_section_id` |
| `class_validations_pending` | `class_section_progress.status = 'SUBMITTED'`, activo y con `submitted_at`, vinculado a un enrollment activo del año y a una sección del mismo tipo de club que la clase |
| `honors_review_pending` | especialidades activas en `PENDING_REVIEW` y con `submitted_at`; `null` en años históricos |
| `annual_folders_pending_union` | evaluación `PREAPPROVED_LF`, carpeta que exige confirmación de Unión y matrícula anual elegible |

Las colas de asignaciones y traslados no se limitan por año; usan el scope territorial actual. Las colas de clases, especialidades y carpetas aplican las relaciones temporales descritas arriba. La calidad agregada de `queues` es `current_affiliation`.

## Calidad de datos

`data_quality` usa cuatro estados:

| Estado | Significado |
| --- | --- |
| `exact` | El schema permite calcular la métrica con el grano declarado. |
| `current_affiliation` | La atribución depende de relaciones institucionales vigentes o no históricas. |
| `unavailable` | El schema no conserva los datos necesarios; los valores correspondientes son `null`. |
| `not_applicable` | La métrica no aplica al periodo resuelto, por ejemplo cuando aún no hay mes cerrado. |

Las notas de calidad forman parte del contrato y deben mostrarse o quedar disponibles para el consumidor; no son logs internos.

| Familia | Calidad runtime |
| --- | --- |
| `administrative_clubs` | `exact` |
| `operations` | `exact` |
| `people` | `exact` |
| `classes` | `current_affiliation` |
| `monthly_reports` | `exact` o `not_applicable` sin mes cerrado |
| `honors` | `current_affiliation` en año activo; `unavailable` en histórico |
| `activities` | `exact` para registros, no para ejecución |
| `queues` | `current_affiliation` |

## Caché

- Caché en memoria mediante `Map`, TTL de 60 segundos.
- Key: nivel/id del scope resuelto, año eclesiástico y mes de reporte o `none`.
- Primera resolución: `meta.cached = false`.
- Hit no vencido: `meta.cached = true` y conserva el `computed_at` original.
- La caché es local a cada réplica; no se comparte entre procesos.
- `cached = true` no significa stale. El endpoint no implementa stale-on-error ni devuelve `freshness`.

## Consumo previsto en `sacdia-admin`

El MVP del panel debe:

1. consumir únicamente este agregado para indicadores, sin fan-out ni métricas de negocio calculadas en cliente;
2. usar la misma vista para global, División, Unión y Campo local;
3. navegar la jerarquía con `children`, incluyendo la tabla de clubes al llegar a Campo local;
4. mostrar el año y mes resueltos por backend;
5. no exponer selector histórico en la primera versión, aunque el endpoint soporte `ecclesiastical_year_id`;
6. distinguir `0`, `null`, `not_applicable`, error HTTP y dato cacheado;
7. no convertir errores en un dashboard lleno de ceros;
8. etiquetar correctamente “club operativo”, “persona institucional”, “cuenta de plataforma”, “actividad registrada” y la atribución de especialidades.

Las rutas existentes de clubes, actividades y validaciones no conservan necesariamente el scope analítico División/Unión. Deben tratarse como navegación general salvo que el destino pueda representar el mismo corte.

## Límites conocidos

- **SQL todavía no validado contra una DB real:** las pruebas del repository usan un mock de `$queryRaw` y validan composición/parametrización, no el resultado de PostgreSQL con fixtures reales.
- **Jerarquía histórica mutable:** las consultas unen contra la jerarquía actual de clubes/campos/uniones/divisiones. Mover una entidad puede reatribuir cortes históricos.
- **Caché por réplica:** dos instancias pueden devolver snapshots calculados en momentos distintos dentro del TTL.
- **Children no aditivos:** especialmente personas, clases y actividades conjuntas. Siempre usar el `summary` recalculado.
- **Especialidades históricas no disponibles:** `users_honors` no conserva año ni territorio histórico.
- **Actividades no realizadas:** no hay indicador confiable de ejecución o asistencia.
- **Sin tendencias ni comparación:** el contrato entrega un snapshot, no series históricas ni deltas.
- **Sin personas institucionalmente inactivas:** esa población no tiene una definición formal en el contrato actual.

## Implementación runtime

- `sacdia-backend/src/analytics/analytics.controller.ts`
- `sacdia-backend/src/analytics/dto/operations-dashboard.dto.ts`
- `sacdia-backend/src/analytics/operations-dashboard-scope.service.ts`
- `sacdia-backend/src/analytics/operations-dashboard.service.ts`
- `sacdia-backend/src/analytics/operations-dashboard.repository.ts`
- `sacdia-backend/src/analytics/operations-dashboard.mapper.ts`
- `sacdia-backend/src/analytics/operations-dashboard.types.ts`
