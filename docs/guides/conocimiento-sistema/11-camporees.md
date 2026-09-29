# 11 · Camporees: inscripción, aprobación, agenda y evaluación

**Estado:** DRAFT · **Revisión de código local:** 2026-09-14  
**Alcance:** el recorrido institucional que un director de Unión debe poder
explicar. Pedidos de artículos (`camporee-orders`) e insumos
(`camporee-supplies`) están **parciales / otra rama** y no entran al demo.

> No certifica despliegue ni un camporee real del piloto. Autoridad API:
> `docs/api/ENDPOINTS-LIVE-REFERENCE.md`. Seguros se mencionan como condición,
> no como ficha propia.

## Cinco mensajes para la presentación

1. **Hay dos camporees distintos.** Local (`local_camporees`, un campo) y de
   unión (`union_camporees`, territorio de la unión). No es el mismo registro
   ni el mismo cobro.
2. **Inscribir la sección no inscribe personas.** Primero la sección
   (`camporee_clubs`); después cada miembro (`camporee_members`) con seguro
   vigente. Cerrar clubes congela quién compite; el plazo de miembros es otro.
3. **El coordinador de zona no aprueba camporee.** Las inscripciones usan
   `attendance:*` y, si aplica, `attendance:approve_late`. El rol
   `coordinator` no es atajo de campo
   (`docs/canon/runtime-coordination.md`:190-191;
   `docs/features/aprobaciones-camporees.md`:8-9).
4. **Con órdenes de pago activas, nadie se “apunta gratis”.** El flag
   `field_payment_orders_v1` bloquea `POST .../register`
   (`FIELD_PAYMENT_ORDER_LEGACY_DISABLED`). Los asistentes nacen al **aprobar
   el comprobante**. Unión: cobra el campo; el dinero campo→unión es fuera
   del sistema.
5. **Puntuar no es pasar lista.** Scoring oficial sólo con inscripción de
   clubes cerrada, rúbricas y juez `primary`. No promedia. No suma al ranking
   anual.

## Cómo leer la evidencia

- **Canon/contrato:** `docs/canon/runtime-camporees.md`,
  `docs/canon/runtime-coordination.md`, features de camporee y referencia API.
- **Código:** backend (inscripción, lifecycle, late approval, scoring), app y
  panel. Demuestra existencia técnica, no un camporee de piloto.
- **Pruebas leídas:** specs de camporees y scoring; **no ejecutadas**.
- **Disponibilidad:** flag `field_payment_orders_v1` cambia el recorrido de
  personas. Pedidos de mercancía e insumos **no** están en el checkout
  principal ni en Neon.

## Vocabulario

| Término | Significado | No confundir con |
|---|---|---|
| Camporee local | Evento de un campo | Camporee de unión |
| Camporee de unión | Evento de la unión; campos participantes en `union_camporee_local_fields` | “El mismo camporee con otro nombre” |
| Inscripción de sección | `camporee_clubs` | Roster de personas |
| Inscripción de miembro | `camporee_members` + seguro | Pago / orden territorial |
| Disposición de clubes | `not_open_yet` / `open` / `late_approval_required` / `manually_frozen` | Fase calendario (`in_progress`, `finished`) |
| Agenda | Programa (todos los tipos de evento) | Eventos con `scoring_enabled` |
| Juez primary | Único que envía puntaje oficial de esa sección/evento | Staff de cocina/apoyo |

## Recorrido institucional

```text
Organizador crea camporee (local o unión)
  └─ abre inscripción de secciones (fecha o inmediata)
        └─ director de la sección activa inscribe su sección
              ├─ a tiempo → registered
              └─ tarde → pending_approval (attendance:approve_late)
                    └─ personas (seguro CAMPOREE o GENERAL_ACTIVITIES)
                          ├─ flag OFF: register directo (solo director)
                          └─ flag ON: orden de pago → approve → miembros
                                └─ cierre MANUAL de clubes
                                      → jueces, rúbricas, puntaje, leaderboard
```

### 1. Crear y situar

CRUD `camporees:*`. Local y unión son tablas distintas. Fechas, lugar,
timezone, costos, plazos de club/miembro/pago, `agenda_visible_from`.
Listado móvil filtra por tipo de la sección activa (`includes_adventurers` /
pathfinders / master_guides). Mixto: visible para cada tipo incluido.

### 2. Inscribir la sección

En la app, el director de la **sección activa** registra esa sección
(`registerActiveSection`). Otro cargo, aunque tenga permisos en el grant:
`CAMPOREE_ACTIVE_SECTION_REQUIRED`
(`camporees.service.ts`:162-175). Fuera de apertura o con cierre manual:
`CAMPOREE_CLUB_REGISTRATION_CLOSED`. Tras el deadline, queda
`pending_approval`.

Disposición
(`camporee-lifecycle.policy.ts`:87-110):

| Disposición | Qué implica |
|---|---|
| `not_open_yet` | Aún no abre; no se inscribe ni se aprueba tarde |
| `open` | Alta a tiempo → `registered` |
| `late_approval_required` | Alta queda pendiente |
| `manually_frozen` | Cierre explícito; prioridad sobre el deadline |

Cerrar clubes (`camporee_events:update`) exige al menos una sección
`registered` o `approved`
(`camporees.service.ts`:1470-1481, 1528-1534). Reabrir se bloquea si ya hay
jueces o puntajes activos (`CAMPOREE_CLUB_REGISTRATION_REOPEN_BLOCKED`).

### 3. Inscribir personas

Hace falta exactamente una inscripción de sección activa
(`CAMPOREE_SECTION_REGISTRATION_REQUIRED`,
`camporees.service.ts`:1100-1141). Seguro: `member_insurances` tipo
`CAMPOREE` o `GENERAL_ACTIVITIES`
(`camporees.service.ts`:88-91). El register legado también exige rol
**director** (`camporees.service.ts`:1050-1062).

**Flag ON** (lista JSON de `local_field_id` en `system_config`): el register
directo falla. Flujo: elegir beneficiarios → pagar → comprobante → el campo
aprueba (maker-checker) → se crean `camporee_members` aprobados y el ledger
de inscripción. Costo 0/null: error de configuración. Jueces y staff
institucional no pagan por este camino.

**Unión + flag:** emite el campo
(`POST /union-camporees/:id/payment-orders`). La unión ve el pago reflejado
en miembros; no hay transferencia electrónica LF→Unión.

Aprobaciones tardías de club/miembro/pago: `attendance:approve_late`.
Rechazo con motivo. Cascada documentada campo→unión en camporee de unión.

### 4. Agenda y eventos

Tipos: scoring, recreational, rest, spiritual, etc. Templates (unión o
campo) se clonan a instancia; los cambios no vuelven al template.

App: pestaña **Eventos** = solo puntuables; **Agenda** = cronología
completa. Antes de `agenda_visible_from` (o `start_date` si va vacío): sin
hora/sede/bloques. Especialidades ligadas al evento son informativas (ficha
09). Lectura operativa: director, subdirector, secretaría, tesorería,
consejero.

Staff operativo ≠ jueces de scoring.

### 5. Evaluación oficial

Sólo con clubes cerrados
(`ensureClubRegistrationClosedForEvent`,
`camporee-scoring.service.ts`:652-675 → `CAMPOREE_CLUB_REGISTRATION_NOT_CLOSED`).
Rúbricas cuya suma = `max_points` del evento. Un resultado activo por
evento+sección. Primary envía; assistant no
(`camporee-scoring.service.ts`:1456-1470). Override territorial:
`assistant-lf`, `director-lf`, `assistant-union`, `director-union`
(`manual_lf`). Global: `admin` / `assistant-admin` / `super-admin`
(`admin_override`). `camporee_events:update` no basta
(`camporee-scoring.service.ts`:859-884).

Leaderboard: `GET .../leaderboard`. Atajo “Evaluar camporee” sólo si hay
asignación `primary` con `can_submit_score`.

Inscribirse **no** da puntos al ranking anual del club.

## Matriz actor × acción (recorte)

| Acción | Quién (backend) | Superficie |
|---|---|---|
| Crear/editar camporee | `camporees:create/update` | Admin |
| Inscribir sección activa | Director de esa sección | App |
| Register miembro legado | Director; bloqueado si flag ON | App (solo flag OFF) |
| Emitir / aprobar orden | `field-payment-orders:*` + bandeja LF | App emisión; admin pestaña órdenes |
| Aprobar tarde | `attendance:approve_late` | Admin pendientes |
| Cerrar clubes | `camporee_events:update` | Admin detalle |
| Puntuar | Juez primary, o override LF/unión/admin | App juez; admin |
| Ver leaderboard | `camporee_events:read` (roles operativos de club) | App Eventos |

`coordinator` no aparece como aprobador de camporee. Un director que también
es coordinador actúa por su asignación de club.

## Fuera de esta ficha (y del demo)

| Tema | Estado declarado | Qué decir |
|---|---|---|
| Pedidos de playeras/gorras | `IMPLEMENTADO PARCIAL`, rama `feat/camporee-orders`, no Neon | “No es el recorrido de hoy” |
| Insumos de cocina | `IMPLEMENTADO PARCIAL` | Igual |
| Inventario/transporte/alojamiento | Gap explícito | El roster nombra responsables; no gestiona logística |
| Push de aprobación/rechazo | Gap | El club se entera en la app/panel, no por push garantizado |

## Excepciones que la demo debe nombrar

| Código / resultado | Significado |
|---|---|
| `CAMPOREE_ACTIVE_SECTION_REQUIRED` | No es director de la sección activa (o tipo no incluido) |
| `CAMPOREE_CLUB_REGISTRATION_CLOSED` | No abierto o congelado |
| `CAMPOREE_SECTION_REGISTRATION_REQUIRED` | Falta inscribir la sección antes que personas |
| `FIELD_PAYMENT_ORDER_LEGACY_DISABLED` | Hay que pagar con orden, no con register |
| `FIELD_PAYMENT_ORDER_COST_NOT_CONFIGURED` | Costo 0/null |
| `CAMPOREE_CLUB_REGISTRATION_NOT_CLOSED` | Jueces/rúbricas/puntaje sin cierre de clubes |
| `CAMPOREE_SCORING_FORBIDDEN` | Assistant o ajeno no puntúa |

Fechas `YYYY-MM-DD` se muestran por prefijo de calendario, no convirtiendo
a zona local (evita 21–23 → 20–22 en México).

## Disponibilidad

| Superficie | Trazado | Límite |
|---|---|---|
| Backend | CRUD, sección, miembros, late approval, cierre, eventos, scoring, órdenes (módulo field-payment-orders) | Flag por campo; orders/supplies no en checkout principal |
| App | Lista, detalle (Detalle/Asistentes/Eventos/Agenda), inscripción de sección, miembros o órdenes, juez | Register legado vs órdenes según flag |
| Admin | CRUD local/unión, staff, eventos, clubes, miembros, pendientes, jueces, puntajes, órdenes | Crear local no usa `GET /admin/local-fields` (403 director-lf) |
| Coordinador | Fuera de aprobaciones de camporee | No prometer bandeja de camporee al coordinador de evidencias |

## Guion de demo ficticio

Aclarar si el campo demo tiene **flag de órdenes ON u OFF**. No mezclar.

1. Lista: camporee local vs uno de unión. Tipo de sección filtra.
2. Como director: inscribir la sección. Decir: aún no hay personas.
3. Personas: seguro visible. Flag ON: “cómo inscribir” → orden → “aparecen
   al aprobar”. Flag OFF: register directo (solo director).
4. Admin: cerrar inscripción de clubes. Entonces jueces y puntajes.
5. Como juez primary: una prueba, un club, rúbricas. Leaderboard.
6. Verbalizar: esto no mueve ranking anual; unión no cobra en la app;
   coordinador de zona no es el aprobador.

Si no hay camporee publicado en el entorno: no improvisar scoring.

## Fuentes

- Dominio: `docs/features/camporees.md`,
  `docs/features/aprobaciones-camporees.md`,
  `docs/features/camporee-events.md`.
- Canon: `docs/canon/runtime-camporees.md`,
  `docs/canon/runtime-coordination.md`.
- API: secciones camporees, camporee-events, camporee-scoring.
- Código: `camporees.service.ts`, `camporee-lifecycle.policy.ts`,
  `camporee-late-approvals.service.ts`, `camporee-club-registration.controller.ts`.
- Relacionadas: seguros (condición), [09](09-honores.md) (especialidades de
  evento informativas).

**Relacionada:** [12](12-supervision-institucional.md) (informes, carpeta
anual, tableros). Inscripción de camporee no puntúa ranking anual.
