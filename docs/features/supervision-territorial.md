# Supervisión territorial (Unión / División) en la app

**Estado**: IMPLEMENTADO (backend #683, admin #321 y app #286, integrados el 2026-11-25). Backend `src/supervision/` y los cambios de alcance en `src/reports/`, `src/analytics/` y `src/annual-folders/` (sacdia-backend), 11 pantallas `supervision-*` del catálogo del panel (sacdia-admin) y la feature `lib/features/supervision/` (sacdia-app). No se ejecutó contra un backend real ni se vio en un dispositivo; lo único verificado son las pruebas automatizadas listadas en «Pruebas».

**Rediseño de las pantallas**: pendiente de merge (PR #289 de sacdia-app, que necesita el PR #685 de sacdia-backend). Rediseña las 13 pantallas de supervisión con el lenguaje de las pantallas ya rediseñadas (Traslados, Mi familia, Reportes, Progreso anual del club), a partir de los mockups HTML aprobados (`mockups/supervision/` en el workspace). Ver «Rediseño de las pantallas». Ambos PR se probaron en el simulador de iOS con una cuenta de Unión contra un backend local con el PR #685.

## Descripción de dominio

Las cuentas de Unión (`director-union`, `assistant-union`) y de División (`director-dia`, `assistant-dia`) pueden revisar desde la app lo que ya hacían en el panel web, dentro de su territorio: inscripciones de club, carpetas anuales, solicitudes de traslado y de asignación de rol, aprobaciones de camporees de unión, operación, directorio de clubes, informes mensuales y progreso anual.

La app no compara nombres de rol ni envía su territorio como autoridad: pregunta capabilities (`hasCapability`) y cada endpoint recorta por el actor. Los servicios siguen siendo la autoridad y responden 403 o 404 cuando el objetivo concreto queda fuera del territorio.

## Quién y con qué capability

Las capabilities viven en `sacdia-backend/src/common/authorization/capabilities.ts` y se publican en `data.authorization.capabilities` de `GET /auth/me` (ver [rbac.md](rbac.md), «Capabilities y clientes»).

| Capability | Predicado (como lo define el código) | Función |
|---|---|---|
| `supervision.app_view` | rol global de Unión o de División, con cualquier territorio (también `unconfigured`) | Persona de supervisión y entrada al hub |
| `club_enrollments.validate` | ya existía; la tienen administración, Campo Local, Unión, División, coordinación y pastor | Inscripciones de club |
| `folders.evaluate` | territorio `all`, `division`, `union` o `local_field` | Carpetas anuales |
| `folders.confirm_union` | rol de Unión | Confirmación de Unión sobre una sección |
| `requests.review_territory` | `super-admin`/`admin` o rol de Campo Local, Unión o División, con territorio `all`, `division`, `union` o `local_field` | Traslados y asignaciones |
| `analytics.operations_dashboard` | lo mismo que `requests.review_territory`, o rol de coordinación | Operación |
| `clubs.view_territory` | lo mismo que `requests.review_territory` | Clubes |
| `reports.view_territory` | rol de Unión con `union_id`, o rol de División con `division_id` | Informes mensuales |
| `annual_progress.view_territory` | lo mismo que `requests.review_territory` | Progreso anual |
| `union_camporees.approve_registrations` | `super-admin`, o rol de Unión con territorio `union` | Aprobaciones de camporees de unión |
| `camporee_orders.configure_offering` | ya existía; territorio `all`, `local_field` o `union` | Pedidos de camporee de unión |
| `camporee_supplies.configure` | ya existía; `super-admin`, `admin`, Campo Local o Unión, con territorio `all`, `local_field` o `union` | Insumos de camporee de unión |

Cambian dos capabilities existentes:

- `app.clubless_surface` suma `supervision.app_view` a `admin_panel.pastor_only` y `coordination.hub_view`. Mueve a Unión y División de `panel_only` a `club_exempt` y nada más.
- `reports.view_all` deja de incluir a los roles de División: queda solo en `super-admin` y `admin`. División lee sus informes con `reports.view_territory`.

Con el territorio `unconfigured` (rol de Unión sin `union_id` o de División sin `division_id`) la cuenta conserva `supervision.app_view` y `app.clubless_surface`, pero ninguna clave por función que exija territorio. Algunas claves dependen solo del rol (`folders.confirm_union`, `club_enrollments.validate`): la app corta esa brecha con la redirección descrita en «Territorio sin configurar».

## Persona y navegación

Es la cuarta persona sin club de la app, junto a pastor, coordinación y solo tutor.

- **Modo de ingreso**: un rol de Unión o de División sin asignación de club visible (activa, pendiente, inactiva o vencida; las `designated` no cuentan) resuelve a `club_exempt`: post-registro de dos pasos, sin selección de club. Con una asignación visible resuelve a `club`. Un pastor que además tiene rol de Unión o División también resuelve a `club_exempt`. Ver [auth.md](auth.md), «Modo de ingreso».
- **Sin club** (`isSupervisorWithoutClub`: `supervision.app_view`, sin asignación visible y sin actuar por un dependiente): el inicio (`/home/dashboard`) es el hub de supervisión. Las pestañas son Supervisión y Perfil, más Coordinación si la cuenta también tiene `coordination.hub_view`.
- **Encabezado de los inicios sin club** (pendiente de merge, PR #289 de sacdia-app): los inicios de supervisión, coordinación y pastor abren con `ClubLessHomeHeader` (`lib/features/dashboard/presentation/widgets/`), que envuelve el `WelcomeHeader` del dashboard: saludo por hora, nombre, foto y campana, más una línea de contexto y el título de la sección. En supervisión la línea de contexto es `data.authorization.territory.name` de `GET /auth/me` (PR #685 de sacdia-backend); si falta, muestra «Unión» o «División».
- **Con club visible**: la persona es la de club y «Supervisión» es una pestaña extra (rama 5 del shell, `/supervision`), visible con `supervision.app_view`.
- **Precedencia del inicio sin club**: supervisión, luego coordinación, luego pastor. Un tutor conserva «Mi familia» desde el perfil. Mientras se actúa por un dependiente (`X-Acting-For`) la persona de supervisión no aplica.
- **Rutas permitidas** (`lib/core/config/supervision_route_access.dart`, `isSupervisionAllowedPath`): inicio, perfil, ficha médica, bandeja de avisos, `/access-denied`, todo `/supervision` y todo `/family`. Con `coordination.hub_view` se suman las rutas de coordinación; con `investiture.authorize_requests`, las de autorizaciones. El resto redirige al inicio. Ver [coordinacion.md](coordinacion.md).
- **Territorio sin configurar** (`territory.level == 'unconfigured'`): el hub muestra solo «Territorio sin configurar» con «Comprobar de nuevo» (`refreshAuthorization`); no pide conteos ni muestra funciones, y cualquier ruta bajo `/supervision/` vuelve al hub (`unconfiguredSupervisionRedirect`).

## Hub y conteos pendientes

El hub lista las colas por capability (inscripciones, carpetas, solicitudes y camporees de unión) y las vistas del territorio (operación, clubes, informes, progreso anual). Sin ninguna, muestra un estado vacío. Los conteos salen de una sola llamada, `GET /api/v1/supervision/pending-counts`, y se invalidan tras cada decisión, al refrescar y al volver al frente.

- **Permisos**: JWT; `PermissionsGuard` con recurso `global` y modo `any` sobre `club_enrollments:validate`, `annual_folders:evaluate`, `requests:review` y `attendance:approve_late`. Sin ninguno: 403.
- **Respuesta** `200`:

```json
{
  "status": "success",
  "data": {
    "territory_level": "union",
    "counts": {
      "club_enrollments": 4,
      "annual_folders": 0,
      "union_camporee_registrations": null,
      "transfers": 2,
      "role_assignments": 1
    }
  }
}
```

- **`null` frente a número**: cada conteo se calcula solo si el actor tiene la capability de su función (`club_enrollments.validate`, `folders.evaluate`, `union_camporees.approve_registrations`; `transfers` y `role_assignments` con `requests.review_territory`). `null` significa «sin esa función» y nunca «cero»; `0` es una cola vacía.
- **Territorio sin configurar**: responde `200` con `territory_level: "unconfigured"` y los cinco conteos en `null`; no es un error.
- **Sin caché de servidor**: los conteos deben bajar justo después de una decisión.
- **Qué cuenta cada uno**: `club_enrollments` y `annual_folders` usan el mismo alcance y filtro que su cola (`validation/queue` en `pending_validation`; `evaluation/queue` en `needs_review`); `union_camporee_registrations` suma clubes, miembros y pagos en `pending_approval` de los camporees de unión activos del territorio (mismo recorte que `GET /camporees/union`); `transfers` y `role_assignments` cuentan las solicitudes `pending` que el actor puede decidir, por sección.

## Las nueve funciones

Rutas de la app en `lib/core/config/route_names.dart`; cada ruta lleva una pantalla del catálogo (`supervision-*`, ver «Panel»). Los textos de las acciones solo aparecen si la capability está y el elemento sigue pendiente.

| # | Función | Ruta | Capability |
|---|---|---|---|
| 1 | Inscripciones de club | `/supervision/enrollments` | `club_enrollments.validate` |
| 2 | Carpetas anuales | `/supervision/folders`, `/supervision/folders/:folderId`, `/supervision/folders/:folderId/sections/:sectionId` (pendiente de merge, PR #289 de sacdia-app) | `folders.evaluate` (+ `folders.confirm_union`) |
| 3 | Camporees de unión: aprobaciones | `/supervision/union-camporees`, `/:camporeeId/approvals` | `union_camporees.approve_registrations` |
| 4 | Traslados y asignaciones | `/supervision/requests` | `requests.review_territory` |
| 5 | Operación | `/supervision/operations` | `analytics.operations_dashboard` |
| 6 | Clubes | `/supervision/clubs`, `/supervision/clubs/:clubId` | `clubs.view_territory` |
| 7 | Informes mensuales | `/supervision/reports` | `reports.view_territory` |
| 8 | Progreso anual | `/supervision/annual-progress` | `annual_progress.view_territory` |
| 9 | Camporees de unión: pedidos e insumos | `/supervision/union-camporees/:camporeeId/orders` | `camporee_orders.configure_offering` (+ `camporee_supplies.configure` para insumos) |

### 1. Inscripciones de club

Aprobar o rechazar la inscripción anual de las secciones del territorio. Rechazar pide motivo (5 a 500 caracteres, ver [club-enrollments.md](club-enrollments.md)). Con el rediseño (pendiente de merge, PR #289 de sacdia-app), aprobar ya no pide una segunda confirmación (decisión de producto); rechazar sigue pidiendo el motivo.

- Endpoints: `GET /club-enrollments/validation/queue`, `POST /club-enrollments/:enrollmentId/approve`, `POST /club-enrollments/:enrollmentId/reject`.
- División y Unión validan solo dentro de su alcance (canales por rol en `ReviewerScopeService`).

### 2. Carpetas anuales

Cola de evaluación, detalle de carpeta con evidencias, evaluar una sección con puntos y notas, reabrir una sección decidida, nota de revisor por evidencia y cerrar la carpeta.

- **Sección como pantalla propia** (pendiente de merge, PR #289 de sacdia-app): `/supervision/folders/:folderId/sections/:sectionId`, con evidencias grandes, notas de revisión y una acción fija abajo (evaluar, confirmar por la Unión o reabrir). La hoja de evaluar muestra los puntos en grande con atajos 0, mitad y máximo. Usa la pantalla `supervision-folders` del catálogo (`route_screen_policy.dart`), igual que el detalle de carpeta.

- Endpoints: `GET /annual-folders/evaluation/queue`, `GET /annual-folders/:folderId`, `POST /annual-folders/:folderId/sections/:sectionId/evaluate`, `.../reopen`, `.../confirm-union`, `POST /annual-folders/:folderId/close`, `PATCH /annual-folders/evidences/:evidenceId/reviewer-note`.
- **División** evalúa con puntos y no confirma. **Unión** confirma o rechaza (`confirm-union`) las secciones `PREAPPROVED_LF` de carpetas con `requires_union_confirmation`; el resto lo evalúa como cualquier revisor con `folders.evaluate`. Ver [annual-folders-scoring.md](annual-folders-scoring.md).

### 3. Camporees de unión: aprobaciones

Lista de camporees de unión activos del territorio y, por camporee, las pendientes de clubes, miembros y pagos. Rechazar un elemento exige motivo en la app (`rejection_reason`). Con el rediseño (pendiente de merge, PR #289 de sacdia-app), aprobar el registro de un club, de un miembro o un pago ya no pide una segunda confirmación (decisión de producto).

- Endpoints: `GET /camporees/union`, `GET /camporees/union/:camporeeId`, `GET /camporees/union/:camporeeId/pending`, `GET /camporees/union/:camporeeId/clubs?status=pending_approval`, `PATCH /camporees/union/:camporeeId/clubs/:camporeeClubId/(approve|reject)`, `PATCH /camporees/union/:camporeeId/members/:camporeeMemberId/(approve|reject)`, `PATCH /camporees/payments/:paymentId/(approve|reject)`.
- **Solo Unión** (y `super-admin`): las rutas de decisión exigen `attendance:approve_late`, que los roles de División no tienen (403 `GUARD_PERMISSION_DENIED`), y el hub no ofrece la entrada sin `union_camporees.approve_registrations`. Ver [aprobaciones-camporees.md](aprobaciones-camporees.md).

### 4. Traslados y asignaciones de rol

Lista por tipo y estado, y revisión (aprobar o rechazar con comentario opcional).

- Endpoints: `GET /requests/transfers`, `GET /requests/assignments` (filtro `status`), `POST /requests/transfers/:requestId/review`, `POST /requests/assignments/:requestId/review` con cuerpo `{ action: "approved" | "rejected", comment? }`. Contrato en [runtime-requests.md](../canon/runtime-requests.md).
- Los traslados se recortan por la sección de destino; las asignaciones, por su sección.

### 5. Operación

Dashboard operativo del territorio con baja de nivel (División → unión → campo local → club) en la misma ruta, con `?division_id=`, `?union_id=` o `?local_field_id=`. Muestra el periodo que el servidor elige por defecto; la app no pide otro.

- Endpoint: `GET /admin/analytics/operations-dashboard` (ver [operations-dashboard.md](operations-dashboard.md)).

### 6. Clubes

Directorio de clubes del territorio (búsqueda por club, iglesia o distrito; filtro activos o inactivos) y resumen de un club: ficha, cifras, secciones y directiva. Solo lectura. El resumen no muestra el `score` que devuelve el backend.

- Endpoints: `GET /clubs`, `GET /clubs/:clubId`, `GET /clubs/:clubId/overview`, `GET /clubs/:clubId/leadership`.

### 7. Informes mensuales

Cumplimiento por club y mes, y el PDF de cada informe. Usa su propia porción de datos: dos lecturas por mes (cumplimiento y lista de informes), sin compartir caché con la pestaña de Reportes de coordinación. Con el rediseño (pendiente de merge, PR #289 de sacdia-app) el mes se elige desde la barra superior y los clubes se agrupan en vencidos, pendientes, al día y sin informes esperados.

- Endpoints: `GET /reports/compliance`, `GET /monthly-reports/admin/list`, `GET /monthly-reports/:reportId/pdf` (el id es UUID). Ver [monthly-reports.md](monthly-reports.md).

### 8. Progreso anual

Avance anual de los clubes por territorio: División → unión → campo local → clubes. Un campo local sin configuración del año se muestra como «Aún sin configurar» (el backend responde 404 con el código de configuración inexistente y la app lo trata como estado, no como fallo).

- Endpoints: `GET /catalogs/unions?divisionId=`, `GET /catalogs/local-fields?unionId=`, `GET /annual-rankings?local_field_id=&club_type_id=&year_id=`. No usa las posiciones de sección ni muestra posiciones.
- **Con el rediseño** (pendiente de merge, PR #289 de sacdia-app y PR #685 de sacdia-backend): los selectores de unión y de campo local leen `GET /annual-rankings/territory-summary`: el de uniones sin parámetros (el servidor responde con las uniones de la división del actor; la ruta no acepta `division_id`) y el de campos locales con `?union_id=`. Muestran en cada fila «N clubes» o «Sin configurar» (campos `clubs_count` y `configured`; contrato en [ENDPOINTS-LIVE-REFERENCE.md](../api/ENDPOINTS-LIVE-REFERENCE.md), «Annual Rankings»). Si ese endpoint responde 404 (un servidor sin el PR #685), la app vuelve a los catálogos y solo muestra los nombres. En el campo local, cada club lleva su medalla y arriba hay un recuadro con la distribución de medallas; los clubes nunca se ordenan por puesto ni se numeran.

### 9. Camporees de unión: pedidos e insumos

Configuración de la oferta de pedidos y de los insumos de un camporee de unión.

- Pedidos: `GET /union-camporees/:id/order-offerings`, `GET /camporee-order-products?active=true`, `PATCH /union-camporees/:id/orders-settings`, `PUT /union-camporees/:id/order-offerings` (reemplazo completo). La ventana del pedido se edita en la zona horaria del dispositivo y se envía en UTC. Ver [camporee-orders.md](camporee-orders.md).
- Insumos (con `camporee_supplies.configure`): `GET /union-camporees/:id/supply-catalog`, `PATCH .../supply-settings`, `POST` y `PATCH .../supply-slots[/:slotId]`, `POST` y `PATCH .../supply-products[/:productId]`. Ver [camporee-supplies.md](camporee-supplies.md).

## Qué distingue a Unión de División

| Función | Unión | División |
|---|---|---|
| Inscripciones, solicitudes, operación, clubes, progreso anual | su unión | las uniones de su división |
| Carpetas | evalúa y confirma o rechaza la sección preaprobada | evalúa con puntos; no confirma |
| Aprobaciones de camporees de unión | sí | no |
| Pedidos e insumos de camporee de unión | sí | no |
| Informes mensuales | su unión | su división |

## Comportamiento nuevo del backend (afecta también al panel)

División pasa a quedar limitada a su propia división. Antes `ALL_REPORTS_ROLES` la trataba como alcance global en informes. Cambios (`src/reports/report-visibility-scope.ts`, `src/common/authorization/periodic-reports-access.ts`):

- Se reemplaza `ALL_REPORTS_ROLES` por `PLATFORM_REPORTS_ROLES` (`super-admin`, `admin`: todo) y `DIVISION_REPORTS_ROLES` (`director-dia`, `assistant-dia`: alcance `division`).
- **Informes mensuales** (`GET /monthly-reports/admin/list`) y **cumplimiento** (`GET /reports/compliance`): corte por la división del actor; los filtros `union_id` y `local_field_id` solo reducen dentro de ella y uno de otra división no amplía nada.
- **Informes trimestrales y anuales**: listados admin, lectura por id (`admin/{tipo}/:id`, fuera de la división: 404) y lecturas por club (`clubs/:clubId/{tipo}`, club fuera de la división: 403 `GUARD_PERMISSION_DENIED`). Ver [informes-trimestrales-anuales.md](informes-trimestrales-anuales.md).
- **Dashboard del campo local** (`GET /admin/analytics/local-field-dashboard`): un rol de División debe nombrar `local_field_id` de su división; sin él, o con uno de otra división, 403 `GUARD_PERMISSION_DENIED`.
- Un rol de División sin `division_id` derivable: 403 `ADMIN_USER_SCOPE_MISSING`.
- **Carpetas anuales** (`src/annual-folders/annual-folders.service.ts`): cola de evaluación, lectura de carpeta y nota de revisor resuelven al actor por la jerarquía institucional (campo local → unión → división) en lugar de las columnas `users.union_id` y `users.local_field_id`. Un rol de División ya no ve una cola vacía y un rol de Unión o de Campo Local se resuelve por su territorio efectivo. Ver [annual-folders-scoring.md](annual-folders-scoring.md).

Esto cambia lo que División ve en el panel web.

## Respuestas fuera del territorio y sin configurar

Resumen de lo que hace el código por endpoint para un actor de Unión o División.

| Endpoint | Fuera de territorio | Territorio sin configurar |
|---|---|---|
| `GET /club-enrollments/validation/queue` | el elemento no aparece; un `local_field_id` ajeno devuelve una lista vacía | cola vacía (no 403) |
| `POST /club-enrollments/:id/(approve\|reject)` | 404 `CE_ENROLLMENT_NOT_FOUND` | 404 |
| `GET /annual-folders/evaluation/queue` | no aparece | 403 `ADMIN_USER_SCOPE_MISSING` |
| `GET /annual-folders/:folderId` | 403 `ANNUAL_FOLDER_FOLDER_ACCESS_DENIED` | 403 |
| evidencias y nota de revisor; evaluar, reabrir y confirmar | 403 `ANNUAL_FOLDER_EVIDENCE_TERRITORY_DENIED` | 403 |
| `GET /camporees/union` | recortada a su unión (Unión) o a las uniones de su división (División); `union_id` ajeno no amplía | 403 `ADMIN_USER_SCOPE_MISSING` |
| `GET /camporees/union/:camporeeId` y rutas hijas | 403 `GUARD_CLUB_SCOPE_REQUIRED`; id inexistente: 404 `CAMPOREE_UNION_CAMPOREE_NOT_FOUND` | |
| `GET /requests/transfers`, `/requests/assignments` | lista recortada; una sección ajena en el filtro: 403 | 403 `ADMIN_USER_SCOPE_MISSING` |
| lectura por id y `POST .../review` de solicitudes | 404 `REQUEST_TRANSFER_NOT_FOUND` / `REQUEST_ASSIGNMENT_NOT_FOUND`; ya revisada: `REQUEST_*_ALREADY_REVIEWED` | 403 `ADMIN_USER_SCOPE_MISSING` en lista y revisión |
| `GET /admin/analytics/operations-dashboard` | `division_id`, `union_id` o `local_field_id` ajeno o inexistente: 403 `GUARD_PERMISSION_DENIED` (no se puede sondear ids); sin filtros, el nivel queda en su territorio | 403 `ADMIN_USER_SCOPE_MISSING`, también con filtro |
| `GET /clubs` | lista recortada; un distrito o campo ajeno: 403 `GUARD_PERMISSION_DENIED` | 403 `ADMIN_USER_SCOPE_MISSING` |
| `GET /clubs/:clubId`, `/overview` | 403 `GUARD_CLUB_SCOPE_REQUIRED` | |
| `GET /annual-rankings` | `local_field_id` ajeno o inexistente: 403 `GUARD_PERMISSION_DENIED` | 403 `GUARD_PERMISSION_DENIED` |
| `GET /annual-rankings/territory-summary` (pendiente de merge, PR #685 de sacdia-backend) | `union_id` ajeno o inexistente: 403 `GUARD_PERMISSION_DENIED` (no hay `division_id`: la división siempre es la del actor) | 403 `ADMIN_USER_SCOPE_MISSING` |
| lecturas de `section-rankings` | lista y detalle recortados; una sección ajena se deniega | lista vacía (no 403) |
| informes mensuales, trimestrales y anuales | ver «Comportamiento nuevo del backend» | 403 `ADMIN_USER_SCOPE_MISSING` |

Con el territorio sin configurar, la cola de inscripciones y las lecturas de `section-rankings` no responden 403 `ADMIN_USER_SCOPE_MISSING`: devuelven vacío o 404. Es una decisión aceptada; la app no llega a esas pantallas porque el hub las oculta y redirige.

## Panel (sacdia-admin)

No hay cambio de interfaz. El catálogo de pantallas (`src/lib/auth/screen-catalog/screens/app.ts`, superficie `app`) suma 11 pantallas, cada una con `viewAny` por capability y sin capabilities propias:

| id | Ruta | `viewAny` |
|---|---|---|
| `supervision-hub` | `/supervision` | `supervision.app_view` |
| `supervision-enrollments` | `/supervision/enrollments` | `club_enrollments.validate` |
| `supervision-folders` | `/supervision/folders` (sirve también `/:folderId`) | `folders.evaluate` |
| `supervision-requests` | `/supervision/requests` | `requests.review_territory` |
| `supervision-operations` | `/supervision/operations` | `analytics.operations_dashboard` |
| `supervision-clubs` | `/supervision/clubs` (sirve también `/:clubId`) | `clubs.view_territory` |
| `supervision-reports` | `/supervision/reports` | `reports.view_territory` |
| `supervision-annual-progress` | `/supervision/annual-progress` | `annual_progress.view_territory` |
| `supervision-union-camporees` | `/supervision/union-camporees` | `union_camporees.approve_registrations` |
| `supervision-union-camporee-approvals` | `/supervision/union-camporees/:camporeeId/approvals` | `union_camporees.approve_registrations` |
| `supervision-union-camporee-orders` | `/supervision/union-camporees/:camporeeId/orders` | `camporee_orders.configure_offering` |

Las claves de capability del panel (`src/lib/auth/generated/capability-keys.ts`) se regeneran del catálogo del backend; las 7 nuevas están en el panel, en el backend y en la app (`lib/core/authorization/generated/capability_keys.dart`). El snapshot de la app (`test/fixtures/screen-catalog.snapshot.json`) refleja el mismo catálogo.

## Se queda en el panel web

Biblioteca de productos y tallas de pedidos, cerrar o reabrir la inscripción de clubes de un camporee, planes y reportes de insumos, y toda configuración que no figura en la tabla de funciones.

## Convenciones de la app

- Errores de una acción se muestran dentro de la hoja (el snackbar queda detrás del modal); el éxito es `SacSnackBar` y cierre. Las escrituras devuelven `SupervisionActionResult` y la vista elige el texto por `errorCode`, con el mensaje del servidor como respaldo.
- Listas con `SupervisionLoadMoreFooter`; columna máxima de 640 (`kSupervisionMaxContentWidth`).
- Los providers de la feature son `autoDispose` y no están en `profile_scope_registry.dart`.

## Rediseño de las pantallas

Pendiente de merge (PR #289 de sacdia-app; el nombre del territorio y el resumen territorial vienen del PR #685 de sacdia-backend y, sin él, la app usa la etiqueta del nivel y los nombres de los catálogos). Cubre: inicio de supervisión (más los inicios sin club de coordinación y pastor), inscripciones, carpetas, detalle de carpeta, sección de carpeta (nueva), traslados y asignaciones, operación, clubes, resumen de club, informes mensuales, progreso anual, camporees de unión con sus aprobaciones, y pedidos e insumos.

- **Inicios sin club**: encabezado del dashboard con el nombre del territorio (ver «Persona y navegación»).
- **Listas**: una lista agrupada por bloque (`SacGroupedSection`) con algo a la izquierda (`SacListRowIcon` teñido con `SacTone`, logo del tipo de club, avatar o medalla), en lugar de pilas de tarjetas con sombra. Los filtros usan `SupervisionSegmentedControl` y solo muestran conteo cuando la API lo da.
- **Resúmenes**: recuadro gris (`SupervisionSummaryBox`) con «X de Y», barra de composición y su leyenda (colas pendientes, informes entregados, pendientes y vencidos, puntos de la carpeta, medallas del campo local).
- **Estados**: chips o paneles con ícono y texto (`SupervisionStatusChip`), nunca solo texto gris.
- **Decisiones**: la acción principal arriba y rechazar abajo en rojo (`SupervisionStackedActions`). Aprobar una inscripción o un registro o pago de camporee no pide segunda confirmación (decisión de producto); rechazar sigue pidiendo el motivo.
- **Sección de carpeta**: pantalla propia en `/supervision/folders/:folderId/sections/:sectionId` (ver «2. Carpetas anuales»).
- **Informes mensuales**: mes en la barra superior y clubes agrupados por estado (ver «7. Informes mensuales»).
- **Progreso anual**: medalla por club y distribución de medallas, sin puestos ni números; los selectores muestran «N clubes» o «Sin configurar» (ver «8. Progreso anual»).
- **Piezas compartidas nuevas**: `SacTone` y tono en `SacListRowIcon`; `subtitleWidget` en `SacListRow`; `titleTrailing` y `onTitleTap` en `SacTopBar`; `SacMoveBox` (también lo usa el detalle de traslado); `ClubLessHomeHeader`. En `lib/features/supervision/presentation/widgets/`: control segmentado, recuadro de resumen, chip de estado, contador, migas de pan, acciones apiladas, cita, tarjeta de cifras, mosaicos de identidad y tarjeta de comprobante.

## Pruebas

| Área | Pruebas |
|---|---|
| Capabilities y modo de ingreso | `sacdia-backend/src/common/authorization/capabilities.spec.ts`, `onboarding-mode.spec.ts`, `auth-me-additive.territory-coverage.spec.ts` |
| Hub | `src/supervision/supervision.controller.spec.ts`, `supervision.service.spec.ts` |
| Alcance territorial por función | `*.territory-coverage.spec.ts` en `src/club-enrollments/`, `src/requests/`, `src/camporees/`, `src/clubs/`, `src/rankings/`, `src/analytics/` y `src/common/guards/` (más `src/common/testing/territory-where.testing.ts`) |
| División en informes y dashboard | `src/reports/periodic-reports-access.spec.ts`, `report-visibility-scope.spec.ts`, `reports-compliance.service.spec.ts`; `monthly-reports.service.spec.ts`, `quarterly-reports.service.spec.ts`, `annual-reports.service.spec.ts`; `src/analytics/local-field-dashboard.service.spec.ts` |
| Carpetas | `src/annual-folders/__tests__/annual-folders-division-scope.service.spec.ts`, `annual-folders-count-evaluation-queue.service.spec.ts` y las específicas de cola, lectura y nota de revisor |
| Catálogo del panel | `sacdia-admin/src/lib/auth/screen-catalog/screen-catalog.app.test.ts` |
| App: rutas y navegación | `sacdia-app/test/core/config/supervision_route_access_test.dart`, `router_supervision_access_test.dart`, `router_coordination_tab_test.dart` |
| App: feature | `sacdia-app/test/features/supervision/` (datos, providers y vistas) |
| Resumen territorial y nombre del territorio (pendiente de merge, PR #685 de sacdia-backend) | `src/rankings/annual-ranking-progress/annual-ranking-territory-summary.service.spec.ts`, `annual-rankings.controller.spec.ts`; `capabilities.spec.ts`, `auth-me-additive.territory-coverage.spec.ts` y `src/auth/auth.service.spec.ts` para `name` |
| App: rediseño (pendiente de merge, PR #289 de sacdia-app) | pruebas de widget de cada pantalla tocada; nuevas para la sección de carpeta, las piezas compartidas, la lectura del nombre del territorio y la vuelta a los catálogos del resumen territorial |

## Gaps y pendientes

- Lo integrado el 2026-11-25 no se ha ejecutado contra un backend real ni se ha visto en un dispositivo. El rediseño (pendiente de merge, PR #289 de sacdia-app) sí se vio en el simulador de iOS con una cuenta de Unión contra un backend local con el PR #685; no con una cuenta de División.
- **Huecos del rediseño frente a los mockups** (datos que la API no devuelve): Operación no muestra la fecha límite de informes; en clubes y carpetas solo el filtro seleccionado muestra su conteo; las secciones del resumen de club muestran la meta de miembros, no el número de miembros; los miembros pendientes de camporee muestran el club sin su tipo; los informes tienen un mosaico de PDF, no una miniatura real.
- El resumen territorial no cuenta los clubes con Oro o mejor: los niveles no se guardan y calcularlos en vivo cuesta hasta 9 consultas por sección en toda una unión. Puede volver cuando el job nocturno de rankings guarde el nivel por inscripción.
- La app trata cualquier 404 de `GET /annual-rankings/territory-summary` como «servidor sin el endpoint» y vuelve a los catálogos, también el 404 `RECORD_NOT_FOUND` que el backend devuelve cuando no hay año eclesiástico activo (la app no envía `year_id`, así que el backend usa el año activo).
- Los informes mensuales de supervisión usan su propia porción de datos y no comparten caché con la pestaña de Reportes de coordinación.
- Operación muestra el periodo por defecto del servidor y no ofrece otro.
- El resumen de club no muestra el `score` del backend.
- Con el territorio sin configurar, la cola de inscripciones y las lecturas de `section-rankings` no responden 403 `ADMIN_USER_SCOPE_MISSING` (decisión aceptada).
- Biblioteca de productos y tallas, cierre o reapertura de inscripción de clubes de un camporee, y planes y reportes de insumos siguen solo en el panel.
