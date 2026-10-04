# Cierre P0 de incongruencias + D02 salto de tipo

**Fecha**: 2026-09-16  
**Estado**: DRAFT — reglas confirmadas por el usuario; no representa código desplegado.  
**Plan**: [2026-09-16-p0-d02-cierre.md](../../plans/2026-09-16-p0-d02-cierre.md)  
**Precedencia**: este documento **enmienda** [2026-09-08 inscripción anual](2026-09-08-inscripcion-anual-miembros-design.md) solo donde se indica. R01–R12 siguen vigentes salvo R05 en el salto de tipo (R13).

## 1. Objetivo

Eliminar incongruencias que hoy producen 403, clase incorrecta o pantallas ciegas, y habilitar el pase Aventureros → Conquistadores y Conquistadores → Guías Mayores con inscripción automática **y** manual.

No reabre D01 (autoinscripción del titular). No define clases GM con `max_duration_years > 1` (sigue bloqueado).

## 2. Fuera de este cierre

- C7 Neon / `SCHEMA-REFERENCE` / migración `investiture:mark_invested`
- C8 trampa `FIELD_ADMIN_ROLES` (no listar solo `director-lf` en `@GlobalRoles`)
- C9 pastor con territorio `open`
- C14 year-cut vs planes `scheduled` huérfanos
- Retorno de **directivo** AV/CQ a GM (R04): sigue no inscrito; inscribe la directiva de GM. No es este salto formativo.

## 3. Reglas confirmadas (2026-09-16)

| ID | Regla |
|---|---|
| R11 (sigue) | Avanzar de clase en el mismo tipo no exige investidura de la clase anterior. |
| R12 (sigue) | `cross_type_enrollment` (GM investido cursa AV/CQ) no crea membresía ni cargo en AV/CQ. |
| R13 | **Salto de tipo formativo** AV→CQ y CQ→GM: el sistema inscribe al año nuevo si hay elegibilidad; la directiva de la **sección destino** puede inscribir lo mismo a mano. |
| R14 | Elegibilidad del salto: (a) cursó la última clase del tipo origen (enrollment regular de un año ya cerrado; `investiture_status` irrelevante); (b) edad al **inicio** del año destino: CQ ≥ 10, GM ≥ 16; (c) mismo club; (d) sección destino `active`. |
| R15 | Primer alta de un tipo: clase por edad (`ClassAssignmentResolver`). Años siguientes **en el mismo tipo**: siguiente `display_order`. Cumpleaños a mitad de año no cambia la clase. |
| R16 | D01 sigue: `POST .../annual-enroll` siempre 403 `ANNUAL_ENROLL_REQUIRES_DIRECTIVE`. |
| R17 | Sucesión operativa (`director-succession`) ≠ preelección (`director-designation`). UI de sucesión en el tab de secciones. Actores: `super-admin`, `admin`, `director-lf`, `assistant-lf`. No `deputy-director`. |
| R18 | Roles territoriales, `zone-coordinator`, `general-coordinator` y `secretary-treasurer` existen en `prisma/seed.ts` y en `roles.constants.ts`. El SQL de grants deja de ser no-op en base fresca. |
| R19 | iOS expande los mismos `GLOBAL_ROLE_ALIASES` que el backend. |
| R20 | `assistant-admin` tiene grants explícitos (subconjunto, no wildcard total). El catálogo no muestra botones cuyo API exige un permiso que ese rol no tiene. |

## 4. C1 — Política de clase en dos fases

### 4.1 Alta / primer enrollment del tipo

Reutilizar `ClassAssignmentResolverService.resolveClassIdForUserClubType`: mayor `minimum_age` ≤ edad al `start_date` del año, tipo de la sección, clase activa y disponible.

Aplica cuando `NextClassResolver` no encuentra enrollment regular previo de ese `club_type_id` (año con `end_date` < inicio del año objetivo, `cross_type_enrollment=false`).

Hoy el resolver toma la primera clase por `display_order`. Eso se reemplaza.

### 4.2 Continuidad en el mismo tipo

Sin cambio de algoritmo: última clase regular → siguiente `display_order` activo del mismo tipo. No `+1` aritmético. Investidura de la previa no bloquea (ya cubierto por modo `annual` en `ClassEnrollmentPolicyService`).

### 4.3 Ejemplo canónico (cumpleaños 20 de marzo, año inicia 1 de enero)

Inscribe con 13, cumple 14 en marzo: clase del año 1 = Orientador (edad 13 en enero). 20 de marzo no cambia la clase. Enero año 2, edad 14 → Viajero por secuencia. No se atasca en Orientador.

## 5. D02 / R13 — Salto AV→CQ y CQ→GM

### 5.1 Qué es

Cambio de **tipo y sección** dentro del **mismo club**. No es otra clase de Conquistadores. No es cursado cruzado. No es el retorno de un director a GM (R04).

| Origen (última clase del catálogo) | Destino | Edad mínima en el 1 de enero destino |
|---|---|---|
| Última de Aventureros | Sección Conquistadores activa del mismo club | 10 |
| Guía (última de Conquistadores) | Sección Guías Mayores activa del mismo club | 16 |
| Última de Guías Mayores | Ninguno | — (sigue `ANNUAL_CLASS_POLICY_UNRESOLVED`) |

«Cursó la última clase»: existe `enrollments` regular (`cross_type_enrollment=false`) de esa clase en un año eclesiástico con `end_date` anterior al inicio del año destino. `INVESTIDO` / `IN_PROGRESS` / otros **no discriminan**.

### 5.2 Automático

Gancho: `YearCutService.applyCut`, después de cerrar cargos del año saliente y materializar planes de director, **antes** de dejar al graduado como `member inactive` en el origen.

Si R14 se cumple: crear en la sección destino, año vigente, `member` `status=active` **y** enrollment de la clase resuelta por edad en el tipo destino. Misma transacción por usuario que `continueUsers` / `ClassEnrollmentWriter`. Idempotente: reintento → ya inscrito, no duplica.

No copiar cargos. Invalidar caché de autorización del usuario.

### 5.3 Manual

`GET/POST /club-sections/:sectionId/annual-continuations` en la **sección destino**:

- La lista incluye candidatos R14 del mismo club que aún no están `member active` ni director activo ahí en el año vigente (aunque su CRA inactivo del corte haya quedado en el origen).
- El POST usa el mismo `continueUsers`; si el automático ya corrió → `already_enrolled`.
- Permiso: `club_members:approve` sobre esa sección. No el titular (D01).

### 5.4 No empujar

| Situación | Resultado |
|---|---|
| No hay sección destino activa | No inscribe. Queda no inscrito en origen (o incidencia). Manual cuando exista la sección. |
| Edad aún no entra a la banda | No inscribe en destino. Sigue el flujo del tipo origen si aún hay clase; si el catálogo origen está agotado y la edad no alcanza, no inscrito en origen hasta el año en que la edad califique. |
| Club/sección destino ambigua | No inventar. Incidencia, sin asignación. |
| Ya director o member active en destino | No duplicar. |

### 5.5 Contrato del resolver

`NextClassResult.crossed_type=true` y `club_section_id` = sección destino cuando hay salto. `kind: 'next_class'` (no `configuration_error`) si R14 se cumple.

Sigue `configuration_error` + `ANNUAL_CLASS_POLICY_UNRESOLVED` si: catálogo origen agotado y (no hay destino, o edad insuficiente, o tipo GM sin siguiente ministerio).

El test actual `D02 — exhausted AV catalog is configuration_error, not silent CQ enrollment` se **invierte** cuando hay sección CQ, edad ≥ 10 y birthday en el usuario. Conservar el caso negativo (sin sección / sin edad).

Copy de `blocked` en app/admin: texto de política (falta sección, edad, catálogo), no error genérico.

### 5.6 Enmienda a R05

R05 sigue para continuidad **dentro del tipo** y para retornados R04.  
**Excepción R13:** el cron puede inscribir el salto de tipo. La directiva destino sigue pudiendo hacerlo. El miembro no.

## 6. C2 — Seeds de roles

`prisma/seed.ts` debe `createMany` (skipDuplicates) además de lo actual:

GLOBAL: `zone-coordinator`, `general-coordinator`, `director-lf`, `assistant-lf`, `director-union`, `assistant-union`, `director-dia`, `assistant-dia`.  
CLUB: `secretary-treasurer`.

`roles.constants.ts` exporta los mismos nombres. Comentario del archivo deja de mentir.

Orden documentado (README backend o `prisma/seeds/README`): `seed.ts` → `permissions.seed.sql` → `role-permissions.seed.sql`. No fusionar el SQL a TypeScript.

El SQL de grants no crea roles; solo INSERT…SELECT. Con R18 el JOIN deja de devolver 0 filas.

## 7. C3 — Inscripción anual en admin; D01 muerto

Nueva superficie admin en detalle de club / tab de sección (año vigente): lista de no inscritos + lote, mismo contrato que la app (`annual_continuations_view.dart`).

Catálogo: pantalla o capability `annual_continuations` con `club_members:approve`. `surfaces: ["admin","app"]`.

Flutter: eliminar o dejar inalcanzable `AnnualEnrollNotifier` / `annualEnroll` del datasource usado por UI. El endpoint backend permanece 403.

## 8. C4 — Aliases iOS

Portar el mapa de `sacdia-backend/src/common/guards/global-roles.guard.ts` (`GLOBAL_ROLE_ALIASES`) a `AuthorizationContext`.

`canReviewEvidence` y cualquier gate de rol usa expansión: `@GlobalRoles('coordinator')` admite zone, general, `director-lf`, `assistant-lf`. `admin` ↔ `assistant-admin`.

No portar el screen catalog completo.

## 9. C5 — assistant-admin

Grants SQL explícitos: mismo conjunto que `admin` **excepto** `*:delete`, `audit:read`, y permisos de mutación RBAC (`permissions:assign` y equivalentes de crear/editar/desactivar roles). No wildcard `NOT LIKE '%:delete'` copiado ciegamente si eso incluye assign.

Catálogo: `viewAny` / capabilities con `@RequirePermissions` exigen esas claves. Alias de rol solo donde el API es `@SkipPermissions` (p. ej. `insurance-expiring`).

Jerarquía: no puede asignar `super-admin` (ya en `rbac.service`).

## 10. C6 — UI de sucesión

En `sections-tab.tsx`, segundo bloque junto a `DesignationBlock`:

- Título: dirección **de este año** (no «año que viene»).
- Acción: `succeedClubSectionDirectorAction` ya existente.
- Visibilidad: `canCapability(user, "clubs", "succeed_director")`.
- Confirmación: termina el director activo del año vigente y crea el nuevo CRA ahora.
- Copy i18n distinto de `designatedHeading` / `designateHint`.

## 11. Criterios verificables

| ID | Escenario |
|---|---|
| B01 | Sin historial del tipo: clase = edad, no la primera del catálogo si esa no corresponde a la edad. |
| B02 | Con historial mismo tipo: siguiente `display_order`; no investida la previa. |
| B03 | Cumpleaños marzo: no cambia clase a mitad de año; enero siguiente avanza. |
| B04 | Última AV + edad ≥ 10 + sección CQ activa: corte inscribe member+clase en CQ. `crossed_type=true`. |
| B05 | Igual B04 sin investidura de la última AV. |
| B06 | Última AV, edad 9 en enero: no pasa a CQ. |
| B07 | Última AV, sin sección CQ: no pasa; GET destino vacío o origen blocked con código de política. |
| B08 | Guía + edad ≥ 16 + GM activa: corte inscribe en GM. |
| B09 | POST destino sobre ya inscrito por corte: `already_enrolled`. |
| B10 | Directiva destino ve al graduado no inscrito y puede POST. Titular 403 D01. |
| B11 | Director AV que regresa a GM (R04): no inscrito, sin clase por el corte. |
| B12 | `prisma db seed` crea `director-lf` y `secretary-treasurer`. |
| B13 | iOS: `director-lf` satisface `canReviewEvidence` si también tiene el permiso de API. |
| B14 | assistant-admin: pantalla con `RequirePermissions` no visible sin el grant; insurance-expiring sí por SkipPermissions+alias. |
| B15 | Tab secciones: preelección no llama succession; suceder llama el POST de este año. |

## 12. Docs canónicas a actualizar en la misma entrega

- `docs/features/clases-progresivas.md`, `gestion-clubs.md`
- `docs/api/ENDPOINTS-LIVE-REFERENCE.md`, `FRONTEND-INTEGRATION-GUIDE.md`
- `docs/guides/conocimiento-sistema/05`, `07`, `08`
- `docs/audit/DECISIONS-PENDING.md` (D02 salto cerrado; GM multianual sigue abierto)
- Spec 2026-09-08: nota de enmienda R13 al inicio
- Ficha 05: LF en cola de evidencias vía alias coordinator (ya runtime 2026-09-15)

## 13. Límites

- Sin pagos, seguros, ni rediseño visual ajeno a continuaciones/sucesión.
- Sin `prisma migrate` a Neon en este trabajo.
- Sin builds salvo que el usuario lo pida después.
- Commits solo si el usuario los pide. Sin `Co-Authored-By`.
- No listar `director-lf` solo en un `@GlobalRoles` nuevo.
