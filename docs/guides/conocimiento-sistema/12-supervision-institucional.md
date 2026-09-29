# 12 · Supervisión institucional: informes, carpeta anual y tableros

**Estado:** DRAFT · **Revisión de código local:** 2026-09-14  
**Alcance:** qué ve y qué **no** decide un director de Unión. Tres circuitos
distintos. Rankings anuales se nombran como consecuencia, no como auditoría
de fórmulas.

> No certifica despliegue ni un corte real de la UMI. Autoridad API:
> `docs/api/ENDPOINTS-LIVE-REFERENCE.md`. Revisión de clases/honores sigue
> en [02](02-revision-evidencias.md); investidura en [08](08-clases-progresivas.md);
> camporee en [11](11-camporees.md).

## Cinco mensajes para la presentación

1. **Supervisar no es un solo tablero.** Informe mensual, carpeta anual y
   dashboard operativo son circuitos distintos. No se “aprueban” igual.
2. **El informe mensual no tiene VoBo de campo ni de unión en backend.**
   Estados: `draft → generated → submitted`. La unión **consulta cobertura y
   PDF**; no existe `approved` / `rejected`
   (`monthly-reports.md`:141;
   `monthly-reports.service.ts`:573-596).
3. **La carpeta anual no es la cola de clases.** Vive en `annual-folders`.
   El campo califica secciones; la unión confirma **solo** si el folder nació
   con `requires_union_confirmation` (ligado a camporee de unión).
   `ANNUAL_FOLDER_UNION_ROLE_REQUIRED` si el actor no es
   `director-union` / `assistant-union`
   (`evaluation.service.ts`:318-335).
4. **El home del director-unión es el dashboard operativo, no el SLA.**
   `GET /admin/analytics/operations-dashboard` admite
   `director-union` (`analytics.controller.ts`:126-137). El SLA
   (`GET /admin/analytics/sla-dashboard`) admite `admin` y `coordinator`
   (alias: zone/general + `director-lf`/`assistant-lf`; LF recorta al campo)
   (`analytics.controller.ts`:63-65). En el panel, `/dashboard` consume
   operaciones; **no hay página `/dashboard/sla` en el sidebar**.
5. **Club “activo” en catálogo no es club operativo del año.** Operativo =
   tiene matrícula anual de sección elegible. `clubs.active` es otro dato
   (`docs/features/operations-dashboard.md`:57-74).

## Cómo leer la evidencia

- **Canon/contrato:** SLA (`docs/canon/runtime-sla-dashboard.md` — partes
  desactualizadas, ver excepciones), operations-dashboard, annual-folders,
  monthly-reports.
- **Código:** analytics, monthly-reports, annual-folders/evaluation.
- **Pruebas leídas:** no ejecutadas. El propio operations-dashboard declara
  SQL no validado contra DB real (`operations-dashboard.md`:193).
- **Disponibilidad:** superficies de panel/app existen; no se ensayó un
  territorio UMI.

## Vocabulario

| Término | Significado | No confundir con |
|---|---|---|
| Informe mensual | Snapshot por `club_enrollment` + mes + año | Carpeta anual |
| Carpeta anual | Expediente de evidencias de la **sección** en el año | Cola `evidence-review` (clases/honores) |
| Dashboard operativo | Corte territorial en `/dashboard` | SLA de colas |
| SLA | Conteos de investidura / validación / (camporee en admin) | Compromiso contractual de tiempos |
| Club administrativo | Fila en `clubs` | Club con matrícula del año |
| Club operativo | Al menos una matrícula anual de sección | `clubs.active = true` |
| Confirmación de unión | `confirm-union` sobre sección `PREAPPROVED_LF` | Aprobar camporee (ficha 11) |

## Tres circuitos

```text
A. Informe mensual (matrícula del año)
   preview en vivo → draft (manual) → generate (snapshot+PDF) → submitted
   Unión: lista jerárquica + PDF. No hay paso de aprobación.

B. Carpeta anual de evidencias (sección)
   template PUBLISHED → folder (al activar matrícula o a mano)
   → club sube y submitSection → LF evaluate
        ├─ requires_union = false → VALIDATED (atajo)
        └─ requires_union = true  → PREAPPROVED_LF → confirm-union
   App: carga. Admin: evalúa. Ranking usa puntos VALIDATED + otros ejes.

C. Tableros
   director-unión → operations-dashboard (home /dashboard)
   coordinator/admin → sla-dashboard (API; app hub del coordinador)
   coordinator NO ve pendientes de camporee en SLA (conteo forzado a 0)
```

### A. Informe mensual

Dueño: `club_enrollments`, no el club aislado. Un informe por
`(club_enrollment_id, month, year)`.

Preview auto: miembros, directiva, honores, actividades, finanzas, días de
reunión. Manual: reuniones, misión, textos. Generate congela `snapshot_data`
y encola PDF (202; hay que poll). Submit solo desde `generated`.

Cron 23:00: si `reports.auto_generate_enabled` y coincide el día, genera el
mes anterior. Recordatorios 09:00 `America/Mexico_City` a director,
secretario y secretary-treasurer (no subdirector). Cierre anual también
crea `draft`.

**Supervisión:** `GET /monthly-reports/admin/list` con
`reports:read`. Scope: unión forzada para `director-union` /
`assistant-union`; campo para LF; coordinador a
`club_section_ids` (`monthly-reports.service.ts`:682-707).

El sidebar del panel exige `reports:read` para
“Supervisión territorial” (`sidebar-item-access.ts`). La API de lista
pide el mismo permiso. `reports:supervise` no existe en el backend.

**Drift para no improvisar en demo:** campos manuales del admin/app no
calzan 1:1 con el DTO backend (`monthly-reports.md`:94-98). PDF sí nace del
snapshot. Plantilla `/reports/monthly-preview` es HTML local, no el
informe real.

### B. Carpeta anual

Legacy `/folders/*` **retirado** (`carpetas-evidencias.md`). Canónico:
`annual-folders`.

Carga/lectura: `evidence_folders:read/update` — director, subdirector,
secretaría. **No** member, counselor, instructor, tesorero. Envío de
carpeta completa: `annual_folders:submit` — director / secretary /
secretary-treasurer. Evaluación: `annual_folders:evaluate` — LF y
superiores; el coordinador **no** evalúa en los grants revisados
([05](05-matriz-roles-verificada.md)).

Al aprobar la matrícula anual (`pending_validation → active`) el backend
intenta crear la carpeta si hay template `PUBLISHED`. UX de club:
`GET/POST /club-sections/:sectionId/annual-folder` — sin UUID a mano.

Sección: `PENDING → SUBMITTED → (PREAPPROVED_LF) → VALIDATED | REJECTED`.
Se puede evaluar una sección `SUBMITTED` con la carpeta aún `open`.
`closing_date` bloquea envíos del club, no la evaluación institucional.
Solo `VALIDATED` suma puntos. `REJECTED` cierra el flujo con 0.

`requires_union_confirmation` se **congela al crear** el folder: si hay
`union_camporee_id`, `true` (`annual-folders.service.ts`:2582-2693). No
cambia después. Unión confirma con
`POST .../sections/:sectionId/confirm-union`
(`APPROVED` | `REJECTED_OVERRIDE`).

App: lectura, banners, puntos. **Sin** UI de evaluación.

Cola admin: `/dashboard/annual-folders` (listado operativo). El ítem
“Evaluación” del sidebar apunta a `/dashboard/annual-folders/evaluate`,
que **redirige** a ese listado
(`annual-folders/evaluate/page.tsx`:3-5).

### C. Tableros

**Operaciones** (`/dashboard`): misma vista para división, unión, campo.
`children` = nivel siguiente (unión → campos). KPI: clubes administrativos
vs operativos, cobertura de informes del mes cerrado, personas
institucionales vs cuentas, colas con pendientes > 0
(`annual_folders_pending_union` = `PREAPPROVED_LF` con flag de unión).

Sin mes cerrado: cobertura mensual `not_applicable`, no “cero de
incumplimiento”.

**SLA:** colas de investidura, validación de clases (`PENDING`) y honores
(`PENDING_REVIEW`). Cache 60s, no muta datos. Coordinador: scope por
`club_section_ids` (`analytics.controller.ts`:312-330), **no** por
`local_field_id` (el canon 2026-04-22 está atrasado). Con ese scope, los
tres conteos de camporee del SLA son **0**
(`analytics.service.ts`:195-222). Admin global cuenta
`camporee_* .status = 'registered'`, que en ficha 11 es inscripción a
tiempo, **no** `pending_approval`. No usar el SLA para “aprobaciones de
camporee”.

App del coordinador llama el mismo endpoint y mapea `evidence` /
`pipeline`, claves que el DTO actual no envía (`validation` / `timing`).
Los tiles de evidencia pueden salir en 0 aunque haya cola real.

`director-unión` **no** entra al SLA por guard. No prometarlo en la demo
con esa cuenta.

Dashboard de campo (`local-field-dashboard`): otro agregado, roles LF y
también unión; no reemplaza el home operativo.

## Matriz actor × acción (recorte)

| Acción | Quién | Superficie |
|---|---|---|
| Completar / enviar informe | Director / secretaría de la sección | App `/home/reports`; admin “Mis reportes” |
| Ver informes del territorio | `reports:read` | `/dashboard/reports/supervision` |
| Aprobar informe | Nadie en runtime | No existe |
| Cargar carpeta anual | Dirección / secretaría / subdirector | App sección; admin club |
| Enviar carpeta completa | Director / secretaría | App / admin |
| Evaluar sección | `annual_folders:evaluate` (LF) | Admin `/dashboard/annual-folders` |
| Confirmar sección | `director-union` / `assistant-union` | Admin, si el flag lo pide |
| Ver corte territorial | `director-union` y roles del guard | `/dashboard` |
| Ver SLA | `admin` / `coordinator` | API; hub coordinador en app |

## Ranking anual (una frase, no el demo)

No es “la carpeta”. Ejes configurables incluyen carpeta, puntualidad de
informes, finanzas, datos institucionales, actividades, asistencia,
**resultados oficiales de camporee** (no la inscripción), investiduras y
uso operativo (`annual-folders-scoring.md`:170-182). Inscribirse a
camporee no puntúa ([11](11-camporees.md)). Fórmulas y pesos: fuera de
esta ficha.

## Excepciones que la demo debe nombrar

| Código / resultado | Significado |
|---|---|
| `MONTHLY_REPORT_NOT_GENERATED` | Submit sin snapshot congelado |
| `MONTHLY_REPORT_NOT_DRAFT` | Editar o generar fuera de `draft` |
| `ANNUAL_FOLDER_REQUIRED_SECTIONS_PENDING` | Falta enviar secciones requeridas |
| `ANNUAL_FOLDER_SECTION_NO_EVIDENCE` | Sección requerida sin archivo |
| `ANNUAL_FOLDER_UNION_ROLE_REQUIRED` | Confirmación de unión con rol incorrecto |
| `ANNUAL_FOLDER_UNION_CONFIRMATION_NOT_REQUIRED` | Folder sin flag de unión |
| Cobertura mensual `not_applicable` | Aún no hay mes cerrado; no es fallo del club |
| SLA 403 para `director-union` | Guard: solo admin/coordinator |
| SLA camporee = 0 en coordinador | Diseño: no se calculan esos conteos en su scope |

## Disponibilidad

| Superficie | Trazado | Límite |
|---|---|---|
| Backend | Informes, carpeta, evaluate/confirm-union, operations, SLA | SLA camporee engañoso; operations SQL no contrastado en DB real |
| Admin | Home operativo, supervisión de informes, listado de carpetas | Sin página SLA; drift de campos del informe; `/evaluate` redirige al listado |
| App | Informes del club; carpeta en lectura; hub coordinador SLA | Coordinador no evalúa carpeta; mapeo SLA desfasado |
| Push | Recordatorios de informe (si config) | Sin push al evaluar carpeta |

## Guion de demo ficticio

Cuenta: **director-unión** (la del destinatario). No usar coordinador ni
admin global salvo para contrastar.

1. `/dashboard`: decir “operativo ≠ activo”. Cobertura de informes del mes
   cerrado. Si aparece cola de carpetas de unión, ese es el trabajo de
   confirmación.
2. Supervisión de informes: un `submitted`, PDF. Verbalizar: **no hay
   botón aprobar**.
3. Carpetas anuales (`/dashboard/annual-folders`): una sección
   `PREAPPROVED_LF`. Confirmar o explicar el atajo si el folder no pide
   unión.
4. No abrir SLA. Si alguien pregunta: “eso es del coordinador/admin, y
   además no refleja aprobaciones de camporee”.
5. No mezclar con evidencias de clase ([02](02-revision-evidencias.md)).

Si no hay folder `PREAPPROVED_LF` en el entorno: no improvisar
confirmación.

## Fuentes

- Dominio: `docs/features/monthly-reports.md`,
  `docs/features/annual-folders-scoring.md`,
  `docs/features/carpetas-evidencias.md` (legacy retirado),
  `docs/features/operations-dashboard.md`,
  `docs/features/sla-dashboard.md`.
- Canon: `docs/canon/runtime-sla-dashboard.md` (contrastar con código 2026-09-14).
- Código: `monthly-reports.service.ts`, `annual-folders.service.ts`,
  `evaluation.service.ts`, `analytics.controller.ts`,
  `analytics.service.ts`.
- Relacionadas: [02](02-revision-evidencias.md), [05](05-matriz-roles-verificada.md),
  [07](07-inscripcion-anual.md), [11](11-camporees.md).

**Semana 2 de análisis cerrada.** Siguiente del plan: semana 3 (recorte
operativo de club para demo, congelar PPTX, guía del expositor, ensayo con
cuentas ficticias).
