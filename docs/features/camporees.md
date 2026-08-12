# Camporees

**Estado**: IMPLEMENTADO

## Descripcion de dominio

Los camporees son eventos institucionales centrales en la vida de los clubes de Conquistadores y Aventureros. Son campamentos competitivos organizados a nivel de campo local (camporees locales) o de union (camporees de union) donde los clubes participan en actividades de evaluacion: orden cerrado, nudos, primeros auxilios, cocina al aire libre, orientacion, campismo, conocimiento biblico y otras disciplinas. Los camporees representan la culminacion del trabajo formativo del club durante un periodo.

El modelo de datos contempla dos niveles de camporees: locales (`local_camporees`) organizados por el campo local, y de union (`union_camporees`) que agrupan clubes de todo el territorio de la union. Los camporees de union pueden referenciar campos locales participantes (`union_camporee_local_fields`). Cada camporee admite inscripcion de clubes (`camporee_clubs`), registro de miembros individuales (`camporee_members`), pagos (`camporee_payments`), fechas limite opcionales (`club_registration_deadline`, `member_registration_deadline`, `payment_deadline`), cierre explicito de inscripción de clubes (`club_registration_closed_at/by`), apertura configurable de clubes (`club_registration_opens_at`, nula para apertura inmediata), timezone IANA auditable, apertura configurable de agenda (`agenda_visible_from`) y ubicación con dirección textual más coordenadas opcionales (`lat`, `long`) para vista de mapa.

La fase operativa se resuelve por calendario local en la timezone del camporee: `preparation`, `registration_open`, `registration_closed`, `in_progress` y `finished`. Durante y después del evento prevalecen `in_progress`/`finished`; para inscripción de clubes se conserva la disposición independiente `not_open_yet | open | late_approval_required | manually_frozen`. El deadline es inclusivo, el cierre manual tiene prioridad y la aprobación tardía no se habilita antes de la apertura.

La inscripcion de miembros en camporees tiene implicaciones directas con el modulo de seguros: para participar en un camporee, los miembros generalmente requieren un seguro activo de tipo CAMPOREE o GENERAL_ACTIVITIES. Esta relacion esta modelada en la tabla `camporee_members` que referencia `member_insurances`.

## Que existe (verificado contra codigo)

### Backend (CamporeesModule)

- **Controller**: `src/camporees/camporees.controller.ts`
- **Service**: `src/camporees/camporees.service.ts`
- **Guards**: JwtAuthGuard, PermissionsGuard, ClubRolesGuard
- **Endpoints principales**:
  - `GET /api/v1/camporees` — Listar camporees
  - `POST /api/v1/camporees` — Crear camporee local; body admite `local_camporee_place`, `lat?`, `long?`, `club_registration_deadline?`, `member_registration_deadline?`, `payment_deadline?`, `agenda_visible_from?`
  - `GET /api/v1/camporees/:camporeeId` — Obtener camporee por ID
  - `PATCH /api/v1/camporees/:camporeeId` — Actualizar camporee local; body admite `lat?`, `long?`, fechas limite opcionales y `agenda_visible_from?`
  - `DELETE /api/v1/camporees/:camporeeId` — Desactivar camporee (roles: director)
  - `GET|POST /api/v1/camporees/union` — Listar/crear camporees de union; body admite fechas limite opcionales y `agenda_visible_from?`
  - `GET|PATCH|DELETE /api/v1/camporees/union/:camporeeId` — Obtener, actualizar o desactivar camporee de union
  - `POST /api/v1/camporees/:camporeeId/register` — Registrar miembro en camporee; el backend infiere `camporee_type='local'` desde el endpoint
  - `GET /api/v1/camporees/:camporeeId/members` — Listar miembros del camporee
  - `DELETE /api/v1/camporees/:camporeeId/members/:userId` — Remover miembro del camporee (roles: director, subdirector)
  - `POST /api/v1/camporees/:camporeeId/members/:memberId/payments` — Registrar pago. Body usa `paid_at` y `payment_type` en `inscription|materials|other`
  - `PATCH /api/v1/camporees/payments/:camporeePaymentId/approve|reject` — Aprobar o rechazar pago tardio; usa `camporee_payment_id` UUID
  - `POST /api/v1/camporees/:camporeeId/club-registration/close|reopen` — Cerrar o reabrir inscripción de clubes de camporee local
  - `POST /api/v1/union-camporees/:camporeeId/club-registration/close|reopen` — Cerrar o reabrir inscripción de clubes de camporee de unión
  - `GET|POST /api/v1/local-camporees/:camporeeId/staff` — Listar o agregar personal del camporee local
  - `GET /api/v1/local-camporees/:camporeeId/staff-candidates` — Listar candidatos de personal del camporee local
  - `GET|POST /api/v1/union-camporees/:camporeeId/staff` — Listar o agregar personal del camporee de unión
  - `GET /api/v1/union-camporees/:camporeeId/staff-candidates` — Listar candidatos de personal del camporee de unión
  - `PATCH|DELETE /api/v1/camporee-staff/:staffMemberId` — Editar o desactivar una persona del roster
  - `GET /api/v1/local-camporees/:camporeeId/events` — Listar eventos registrados del camporee local
  - `GET /api/v1/union-camporees/:camporeeId/events` — Listar eventos registrados del camporee de unión

### Admin

- **CRUD completo**: Lista con creacion/eliminacion, pagina de detalle con tarjeta de info y tabs de personal, eventos, clubes y miembros, dialog de creacion/edicion, registro de miembros con validacion de seguro, remocion de miembros
- Los formularios de camporee local y de unión capturan dirección textual, fechas limite opcionales y coordenadas opcionales (`lat`, `long`) como par obligatorio: se guardan ambas o ninguna.
- El admin carga primero el roster operativo del camporee y luego asigna personas específicas a cada actividad/evento; no se fuerza que cada actividad tenga cocina/admin/apoyo/jueces.
- El cierre de inscripción de clubes congela las secciones que podrán recibir puntajes y asignaciones de jueces; la inscripción de miembros sigue controlada por `member_registration_deadline`.
- Reutiliza el cliente API existente (`lib/api/camporees.ts`) y las server actions (`lib/camporees/actions.ts`)

### App Movil

- **4 screens**: lista de camporees, detalle con preview de miembros, selector/registro múltiple de miembros desde la sección activa, lista de miembros con opcion de remocion
- La lista móvil de camporees muestra directamente las tarjetas disponibles, sin hero/resumen decorativo superior, para ahorrar espacio útil.
- La UI móvil muestra las fechas como rango único y los montos con el símbolo de moneda antes de la cantidad (ej. `$450`) tanto en lista como en detalle.
- El detalle muestra banner de Camporí, dirección primero y preview 16:9 del mapa con pin cuando hay coordenadas. Al tocar el bloque abre opciones de mapas externos.
- Directores, subdirectores, secretarios, secretarios-tesoreros, tesoreros y consejeros pueden ver los eventos registrados del Camporí desde el detalle móvil.
- En el detalle móvil se prioriza primero la sección de miembros inscritos y después los eventos del Camporí.
- La lista móvil de eventos es mínima: icono, nombre del evento y puntaje total. Al entrar al evento se muestra el detalle completo con tipo, día/hora si la agenda está liberada, puntaje, lugar, descripción, personal asignado y horarios/bloques cuando existan.
- Capa de datos completa: entidades, modelos, datasource, repositorio, providers
- Rutas configuradas en GoRouter

### Base de datos

- `local_camporees` — Camporees a nivel de campo local; incluye `local_camporee_place`, `lat`, `long`
- `union_camporees` — Camporees a nivel de union; incluye `union_camporee_place`, `lat`, `long`
- `union_camporee_local_fields` — Campos locales participantes en camporees de union
- `camporee_clubs` — Clubs inscritos en camporees
- `camporee_members` — Miembros inscritos en camporees (referencia `member_insurances`)
- `camporee_payments` — Pagos de miembros inscritos; PK runtime `camporee_payment_id` UUID, `paid_at` como fecha de pago y `payment_type` en `inscription|materials|other`
- `camporee_staff_members` — Roster operativo del camporee con categorías descriptivas (`judge`, `administrative`, `kitchen`, `support`, `spiritual`, `leadership`, `other`)
- `camporee_event_staff_assignments` — Asignaciones flexibles de personas a eventos/actividades (`responsible`, `assistant`, `evaluator`, `support`)

## Requisitos funcionales

1. Directores y subdirectores deben poder crear y gestionar camporees
2. Los camporees deben tener nombre, fechas, ubicacion, tipo (local/union) y descripcion
3. El sistema debe permitir inscribir miembros individualmente en un camporee
4. Debe ser posible listar los miembros inscritos en cada camporee
5. El registro de miembros debe validar requisitos (seguro activo, membresia vigente)
6. Los camporees deben poder desactivarse (soft delete) sin perder datos historicos
7. El panel admin debe permitir CRUD completo de camporees con gestion de miembros
8. La app movil permite ver camporees disponibles, inscribirse y gestionar miembros inscritos
9. El campo local o la unión debe poder cargar el personal operativo del camporee antes de configurar actividades.
10. Cada actividad/evento puede tener un responsable y apoyos/evaluadores sólo si aplica.
11. La configuración de scoring oficial se habilita sólo después de cerrar la inscripción de clubes.

## Decisiones de diseno

- **Dos niveles de camporees**: El modelo distingue camporees locales y de union con tablas separadas, permitiendo diferente estructura organizativa
- **Inscripcion individual**: Los miembros se registran individualmente, no como club completo, permitiendo control granular de participacion
- **Vinculacion con seguros**: `camporee_members` referencia `member_insurances`; un seguro activo `CAMPOREE` o `GENERAL_ACTIVITIES` es elegible para camporees. La app muestra el estado de seguro del miembro en el selector, pero no solicita capturar manualmente `insurance_id`
- **Inscripción sin puntaje anual**: `camporee_clubs` y `camporee_members` conservan asistencia/participación como registro operativo e histórico; ya no otorgan puntos al ranking anual.
- **Cierre explícito de clubes**: `club_registration_closed_at` no reemplaza `club_registration_deadline`; el cierre congela secciones competitivas para scoring, mientras `member_registration_deadline` controla participantes/personas.
- **Personal operativo separado de jueces de scoring**: `camporee_staff_members` describe capacidades generales del camporee; `camporee_event_staff_assignments` asigna personas a la agenda; `camporee_judges` y `camporee_event_judge_assignments` siguen siendo la autoridad de scoring por sección/evento.
- **Autorizacion estricta**: Solo director puede eliminar camporees; director y subdirector pueden crearlos y gestionarlos. La lectura de eventos en app se habilita para roles operativos de club: director, subdirector, secretario, secretario-tesorero, tesorero y consejero.
- **Apertura de agenda**: `agenda_visible_from` controla cuándo la app puede mostrar día/hora/sede/bloques de eventos. Si está vacío, la agenda completa se abre al iniciar el camporee (`start_date`). Antes de esa fecha, el endpoint preview sólo expone listado, tipo, descripción/requisitos y puntos.

## Gaps y pendientes

- **Sin logística de inventario/compras**: El roster permite asignar responsables de cocina/apoyo/administración a actividades, pero no gestiona inventario, compras, transporte o alojamiento.

## Órdenes de pago territoriales (rollout en curso)

Plan `docs/plans/2026-08-05-insurance-camporee-payment-orders-plan.md` (+ addendum 2026-08-12): la inscripción de miembros pasa a ser payment-first mediante `field_payment_orders` grupales.

- **Ningún camporee es gratis**: clubes y personal de apoyo siempre pagan inscripción; `registration_cost` null/0 es error de configuración. Solo jueces (`camporee_judges`) y staff del Campo Local/Unión (`camporee_staff_members`) no pagan; sus flujos son independientes del register de miembros y no cambian.
- **Flag `field_payment_orders_v1`** (`system_config`, lista JSON de `local_field_id`): ON → `POST /camporees/:id/register` de miembros exige orden de pago aprobada; los `camporee_members` se crean al aprobar el comprobante, no antes. OFF → register directo legacy intacto.
- **Expiración de órdenes**: `field_payment_orders.expiry_days` (`system_config`), default 15 días.
- `camporee_payments` por miembro queda legado (histórico/unión).

## Estado de implementacion

- **Prioridad**: Completo — backend, admin y app implementados con CRUD completo; el admin incluye detalle de camporee local y de unión, con eventos/agenda por scope; la app registra miembros desde una lista de la sección activa y el backend infiere el tipo de camporee
- ✅ Approval UI: Aprobacion/rechazo de inscripciones de clubes, miembros y pagos desde el admin panel (ver [aprobaciones-camporees](aprobaciones-camporees.md))


## Scoring oficial por rúbricas

El puntaje competitivo del camporee se registra por evento y sección de club. Un evento puntuable usa `camporee_events.scoring_enabled=true` y debe tener rúbricas activas en `camporee_event_rubrics`; la suma de `max_points` de las rúbricas debe igualar `camporee_events.max_points`. Los templates reutilizables pueden definir rúbricas en `camporee_event_template_rubrics`; al clonar un template puntuable, esas rúbricas se copian al evento.

Reglas vigentes:

- La inscripción/asistencia no puntúa ranking anual; queda como operación e historia.
- El resultado oficial vive en `camporee_event_section_results` y se deriva de `camporee_event_score_submission_items`.
- Si hay varios jueces para la misma sección/evento, no se promedia: sólo el juez `primary` activo puede enviar puntaje oficial desde app.
- Jueces `assistant` quedan como apoyo/auditoría y no envían puntaje oficial.
- En admin, el roster de jueces se carga seleccionando usuarios desde un buscador con foto, nombre, rol y cargo; no se debe pedir al operador capturar UUIDs manualmente.
- Sólo pueden agregarse al roster usuarios elegibles: mayores de 18 años, usuarios con rol global `pastor`, o usuarios con investidura activa en clase de Guías Mayores. La UI filtra candidatos y el backend vuelve a validar antes de crear el juez.
- Las mutaciones de rúbricas, asignaciones de jueces y captura de puntaje oficial requieren que la inscripción de clubes esté cerrada (`club_registration_closed_at`), porque las secciones competitivas ya deben estar congeladas.
- Reabrir inscripción de clubes sólo es válido si todavía no existen asignaciones de jueces ni resultados activos de scoring.
- La app móvil muestra la bandeja de evaluaciones sólo para asignaciones `primary` activas del juez autenticado y envía un ítem por rúbrica.
- `assistant-lf`, `director-lf`, `assistant-union` y `director-union` pueden registrar puntaje manual dentro de su scope; `admin`, `assistant-admin` y `super-admin` generan override administrativo auditado. El permiso genérico `camporee_events:update` no basta.
- `camporee_event_section_results` mantiene un único resultado activo por `camporee_event_id + club_section_id`; submissions anteriores quedan auditables.
- El juez principal sólo puede enviar una calificación oficial por evento/sección. `source` se deriva en servidor: una intención `admin_override` enviada por un gestor territorial queda `manual_lf`; sólo admins globales permitidos producen `admin_override`.
- Si la suma enviada queda bajo `camporee_events.min_points` y el mínimo es mayor que cero, el backend guarda el total ajustado al mínimo; si no hay mínimo, conserva el total enviado.
- El estado `no_show` marca "club no se presentó": se guarda `score_status='no_show'`, `is_no_show=true`, no requiere ítems de rúbrica y asigna el mínimo del evento; si no hay mínimo configurado, asigna `0`.
- La captura con `Idempotency-Key` usa un lock bigint basado en hash de 64 bits para actor+clave y luego `pg_advisory_xact_lock(eventId::integer, clubSectionId::integer)`. Los casts explícitos son necesarios porque Prisma enlaza números JavaScript como `INT8` y PostgreSQL debe resolver el overload `(integer, integer)`. Los keyspaces quedan separados; una colisión teórica del hash sólo sobre-serializa. Si aun así aparece P2002, el backend relee y devuelve replay o conflicto canónico.
- Cada submission conserva la suma cruda (`raw_awarded_points`), el ajuste del mínimo (`minimum_adjustment_points`) y el total oficial. Una clave usada con payload canónico diferente devuelve `IDEMPOTENCY_KEY_REUSED`.
- Una corrección manual contra un resultado existente debe comparar `expected_active_result_id` y guardar motivo no vacío en `notes`; si falta devuelve `CAMPOREE_SCORING_OVERRIDE_REASON_REQUIRED`, y si cambió el resultado devuelve `CAMPOREE_SCORING_RESULT_STALE` sin desactivar nada.
- En un receipt, `active=true` es el snapshot de emisión y se mantiene en replays; el estado actual del resultado puede ser inactivo si luego fue reemplazado.
