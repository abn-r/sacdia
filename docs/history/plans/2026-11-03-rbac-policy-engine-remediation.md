# Plan de remediación RBAC: de guard monolítico a motor de políticas

**Fecha**: 2026-11-03
**Estado**: Propuesta (sin implementar)
**Origen**: Auditoría externa de solo lectura del RBAC en backend, admin y app. Hallazgos completos en Engram, topic `architecture/rbac-audit`.

## Diagnóstico en una línea

El modelo (roles GLOBAL/CLUB, permisos `resource:action` resueltos en DB, guard fail-closed, JWT sin claims) es correcto. La implementación creció a un motor de autorización por atributos y relaciones sin lenguaje de políticas: 26 tipos de recurso en un guard de 2.377 líneas, 201 rutas sin tenant validado en guard, 69 rutas congeladas en allowlist, 611 literales de nombre de rol fuera de guards, tres espejos manuales en clientes.

## Principios del plan

1. **Primero red de seguridad, luego bugs de seguridad, luego estructura, al final clientes.** Nada de refactor estructural sin tests que fijen el comportamiento actual.
2. **Un PR por fase.** Si la fase toca backend, admin y app, cada repo lleva su PR. Sin presupuesto de líneas. Fases que no chocan entre sí pueden ir juntas en un PR; se decide al llegar a ellas.
3. **Cada fase cierra con un test que la vuelve irreversible.** Si no hay test de salida, la fase no está cerrada.
4. **El backend es la autoridad.** Los clientes consumen capabilities; no reconstruyen reglas.
5. **No se cambia el modelo de datos salvo donde ya está diseñado** (vigencia temporal, diseño P0 de julio).

## Resumen de fases

| Fase | Nombre | Repos (un PR por repo) | Riesgo que cierra |
|---|---|---|---|
| 0 | Red de seguridad y limpieza | backend | Drift silencioso catálogo↔código |
| 1 | Predicado temporal único | backend | Grants futuros/vencidos con permisos |
| 2 | Autoridad exacta y auditoría | backend | Auto-asignación, auditoría con actor falso |
| 3 | Catálogo generado | backend, admin, app | Tres copias manuales, permisos fantasma |
| 4 | Policy por recurso | backend | Guard monolítico, 11 resolvers de scope |
| 5 | Allowlist a cero | backend | 69 rutas sin tenant en guard |
| 6 | Literales de rol | backend | 611 strings en 93 archivos |
| 7 | Capabilities y clientes | backend, admin, app | Semántica distinta entre clientes, `@modal`, router Flutter |
| 8 | Sucesión programada del director | backend, admin | Sucesión inmediata que deja la sección sin director de octubre a diciembre |

Las fases 0 a 2 son independientes entre sí tras la 0. La 3 habilita la 6 y la 7. La 4 habilita la 5. La 8 necesita la 1 y la 2.

---

## Fase 0: Red de seguridad y limpieza

**Objetivo**: que el drift que hoy pasa en silencio rompa el CI.

**Entregables (backend)**

- Spec `permission-catalog-parity.spec.ts`: extrae todo literal `x:y` de `@RequirePermissions`, `@SensitiveUserSubresource` y de `permissions.includes('...')` en `src/`, y falla si no existe en `prisma/seeds/permissions.seed.sql` o en una migración. Hoy detectaría `rankings:read_lf` y `rankings:read_global`.
- Spec `tenant-binding-allowlist.freeze.spec.ts`: falla si `tenant-binding-allowlist.ts` tiene más entradas que un número fijado en el spec. Se baja el número en cada fase que retire rutas.
- (El spec `audit-actor` se escribe en la fase 2 junto con el fix: hoy fallaría y bloquearía el PR.)
- Corregir `rankings:read_lf|read_global`: decidir si se siembran o se reemplazan por `member_rankings:*`/`section_rankings:*`. Recomendado: reemplazar en código, no sembrar más permisos.
- Borrar `src/common/authorization/authorization-context-cache-v4.ts` y su spec, `AuthorizationContextVersionService` y sus llamadas `bump` en 7 servicios. La cache v7 lo reemplazó. El modelo Prisma y la tabla `authorization_context_versions` se dejan; su drop es una migración aparte.
- No borrar `GlobalUserRoleWriteService`: se cablea en la fase 2.

**Criterio de salida**: los tres specs nuevos pasan en CI y el de paridad detecta un permiso inventado a propósito.

**Riesgo**: bajo. Solo tests y un bugfix de nombres.

---

## Fase 1: Predicado temporal único

**Objetivo**: ninguna asignación futura, vencida o fuera de año aporta permisos ni contexto activo. Es el slice 1 del diseño P0 de julio (`sdd/authorization-and-director-succession-p0/design`).

**Entregables (backend, un PR)**

- `ClubAssignmentEffectivityPolicy` como única definición de "vigente":
  `active && status='active' && start_date <= business_date && (end_date IS NULL || business_date <= end_date) && (expires_at IS NULL || now < expires_at)`.
  Inyectar `Clock`. Aplicar en `AuthorizationContextService.buildClubGrant` (hoy `operational` ignora las tres fechas), en `ClubRolesGuard`, en `AuthService.setActiveClubContext` y en los listados "current" de `ClubsService`.
- Cache consciente de fronteras. TTL = `min(5 min, próxima frontera temporal de los grants consultados)`. Subir clave a `auth:context:v8`. Si `users_pr.active_club_assignment_id` apunta a un grant no vigente, el snapshot lo ignora y cae a otro vigente o `null`.
- Spec de inventario: `grep` de `club_role_assignments` + `active: true` en `src/` fuera de la policy falla. Fuerza que toda lectura pase por el predicado.

**Criterio de salida**: tests de frontera (start mañana no, start hoy sí, end hoy sí, end ayer no, `expires_at` pasado no) en contexto, guard y `/auth/me`. Cache creado antes de una frontera expira en la frontera.

**Riesgo**: medio. Puede dejar sin permisos a usuarios con filas inconsistentes en Neon. Antes de desplegar: correr preflight SQL de filas `active=true` con fechas fuera de rango y reportar, no corregir en silencio.

---

## Fase 2: Autoridad exacta y auditoría

**Objetivo**: quién puede asignar qué queda en el servicio, no en el permiso genérico; toda mutación de rol queda auditada con el actor real.

**Entregables (backend, un PR)**

- `ClubsService.assignRole/updateRoleAssignment/removeRoleAssignment` reciben `actor` desde el controller. Policy `SectionRoleMutationPolicy.assert(actor, section, targetRole)`:
  - cargos de sección los asigna el director vigente exacto de esa sección, o un rol territorial del mismo campo local;
  - nadie se asigna un cargo a sí mismo salvo `member` por post-registro;
  - `super-admin` pasa, `admin` pasa; `canManageClub()` deja de ser autoridad para mutar cargos.
- Cablear `GlobalUserRoleWriteService` en `RbacModule` y hacer que `RbacController` POST/DELETE de roles globales lo use. Ya tiene transacción, idempotencia y `ExactSuperAdminWritePolicy`. `RbacService.assignRoleToUser/removeRoleFromUser` quedan como delegados o se eliminan.
- Writer de auditoría transaccional para eventos de seguridad (`ROLE_ASSIGNED`, `ROLE_REVOKED`, `GLOBAL_ROLE_ASSIGNED/REVOKED`, `ROLE_PERMISSIONS_CHANGED`). Corre dentro de la transacción; si falla, rollback. `actor_user_id` = autenticado, `actor_role_name`, `actor_scope`, before/after en `changes`. Todos los cargos, no solo director/deputy/secretary.

**Criterio de salida**: tests negativos por rol (deputy, secretary, director de otra sección, LF de otro campo) en asignación; test de que un fallo del writer de auditoría hace rollback; spec de fase 0 `audit-actor` sigue verde.

**Riesgo**: medio. Cambia quién puede asignar cargos. Validar con la matriz de `docs/features/auth/RBAC-ENFORCEMENT-MATRIX.md` y anunciar el cambio en QA antes de `preproduction`.

---

## Fase 3: Catálogo generado desde una sola fuente

**Objetivo**: permisos, roles y alias se definen una vez y se generan para backend, admin y app. Se acaban los comentarios "keep in sync by hand".

**Entregables (un PR por repo)**

- Backend: `prisma/authz/catalog.ts` (o YAML) como fuente: lista de permisos con `key`, `description`, `surfaces`, `deprecated`; lista de roles con `name`, `category`, `aliases`. Script `pnpm authz:generate` que emite:
  - `prisma/seeds/permissions.seed.sql` (reemplaza la edición manual);
  - `src/common/authorization/generated/permission.ts` (`export const Permission = { ... } as const`, tipo `PermissionKey`);
  - `src/common/authorization/generated/role.ts` (`GlobalRole`, `ClubRole`, `ROLE_ALIASES`).
  `@RequirePermissions` acepta solo `PermissionKey`. Regla ESLint `no-restricted-syntax` prohíbe literales `x:y` fuera de `generated/`.
- Admin: el mismo script emite `src/lib/auth/generated/permissions.ts` y `role-aliases.ts`. Se borran `permissions.ts`, `seeded-permission-keys.ts` y `role-aliases.ts` manuales. El test que compara contra `../sacdia-backend` deja de ser condicional: compara contra el archivo generado, que se commitea en ambos repos.
- App: emite `lib/core/authorization/generated/permissions.dart` y `role_aliases.dart`. Se borran `club_role_names.dart` y `role_aliases.dart` manuales.
- Decisión sobre `super-admin`: mantener el CROSS JOIN explícito en seed (auditable), pero el generador produce el bloque y un spec verifica que super-admin tiene todo permiso activo. No se agrega wildcard en runtime.
- Normalizar naming: `camporee-orders:*`, `camporee-supplies:*`, `field-payment-orders:*` y `materiales:*` quedan como alias deprecados en el catálogo con migración de renombre. Opcional; puede diferirse.

**Criterio de salida**: CI de los tres repos falla si el archivo generado no coincide con el catálogo (`authz:generate --check`). Cero literales `x:y` en `src/` fuera de `generated/`.

**Riesgo**: bajo-medio. Mucho diff mecánico, pero un solo PR por repo.

---

## Fase 4: Policy por recurso

**Objetivo**: el switch de 26 casos en `PermissionsGuard` se convierte en 26 clases pequeñas y testeables; los 11 resolvers de scope de servicios convergen en un solo value object.

**Entregables (backend, un PR)**

- Interfaz `ResourcePolicy { type; resolve(ctx: AuthzRequest): Promise<PolicyDecision> }` y `PolicyRegistry` (Map por `type`). `PermissionsGuard.validateResourceScope` despacha al registry. Mover 3 tipos simples (`global`, `user`, `active_assignment`) como prueba. Specs existentes (`permissions.guard.spec.ts`, 79 casos) deben seguir verdes sin cambios.
- Mover el resto por familias: club (`club`, `club_section`, `club_assignment`, `activity*`, `finance`, `inventory_*`, `monthly_report`, `insurance_*`, `class_counselor_assignment`, `investiture_enrollment`), camporee (`camporee`, `union_camporee`, `camporee_event`, `camporee_venue`, `camporee_payment`). Cada policy con su spec. El guard termina bajo 500 líneas.
- `ActorScope` value object (`src/common/authorization/actor-scope.ts`) con `coversClub(id)`, `coversSection(id)`, `coversLocalField(id)`, `coversUser(id)`. Los resolvers `actor-section-scope`, `actor-territory-scope`, `coordinator-section-scope`, `target-user-scope`, `member-territory-scope`, `report-visibility-scope`, `class-progress-scope`, `operations-dashboard-scope`, `actor-local-field`, `camporee-supply-actor`, `camporee-order-actor` se reescriben como adaptadores sobre `ActorScope` o se eliminan.

**Criterio de salida**: `permissions.guard.ts` < 500 líneas; `rg "private validate.*Scope" permissions.guard.ts` vacío; spec de arquitectura que falla si un servicio consulta `club_role_assignments` o `users.local_field_id` para decidir acceso fuera de `src/common/authorization/`.

**Riesgo**: medio. Es refactor puro; el riesgo es regresión. Mitigación: no tocar comportamiento, solo mover; los 112 casos de spec del guard son la red.

---

## Fase 5: Allowlist a cero

**Objetivo**: cada una de las 69 rutas congeladas declara `bind` o pasa por una policy de recurso. Las 201 rutas `global`/`active_assignment` con tenant en body o query quedan inventariadas.

**Entregables (backend, un PR)**

- Extender `tenant-binding-inventory.ts` para detectar tenant en DTOs de body (`club_id`, `club_section_id`, `local_field_id`, `union_id`, `camporee_id`) además del path. Hoy dice "stay a review concern".
- Migrar por grupo: `PENDING_REVIEW` (coordination, materials, notifications, rankings, scoring-categories), `PENDING_CAMPOREE` (~40: orders, supplies, field-payment-orders; su scope vive en el servicio y pasa a policy `camporee_*` de la fase 4), geografía y annual-folders (`FOLDER_SECTION`).
- Bajar el número del spec de congelación de la fase 0 hasta cero.

**Criterio de salida**: `tenant-binding-allowlist.ts` vacío y el spec exige que siga vacío.

**Riesgo**: medio-alto por volumen. Cada ruta migrada necesita un test de 403 cross-tenant. Es la fase más larga.

---

## Fase 6: Literales de rol

**Objetivo**: los 611 literales de rol fuera de guards desaparecen; los checks `if (role === 'director')` en servicios pasan a policies nombradas.

**Entregables (backend, un PR)**

- Regla ESLint que prohíbe literales de nombre de rol fuera de `generated/role.ts` y de policies. Entra como `error` en el mismo PR que el reemplazo.
- Reemplazo mecánico por módulo (notifications, clubs, camporees, requests, annual-membership, investiture...). Donde el literal expresa una regla (`activeGrant.role_name !== 'director'` en `camporees.service.ts`), se extrae a una policy con nombre (`isSectionDirector(actor, section)`).
- Eliminar las copias privadas de `isSuperAdmin` en `district-investiture-pastors.service.ts` e `investiture-authorization-requests.service.ts`.
- `GlobalRolesGuard`: separar `@GlobalRoles` (con alias, para superficies amplias) de `@ExactGlobalRoles` (sin alias, para mutaciones). Hoy un rol de unión satisface `@GlobalRoles('director-lf')`.

**Criterio de salida**: regla ESLint en `error`; `rg "'(super-admin|director-lf|...)'" src --glob '!generated/**' --glob '!**/policies/**'` vacío.

**Riesgo**: bajo. Diff grande pero mecánico.

---

## Fase 7: Capabilities y clientes

**Objetivo**: los clientes dejan de replicar reglas. El backend publica qué puede hacer el actor; admin y app solo lo leen.

**Entregables (un PR por repo)**

- Backend: `GET /auth/me` agrega `authorization.capabilities: string[]` calculadas por las policies de la fase 2 y 4 (`club_roles.assign_section`, `club_roles.succeed_director`, `rbac.mutate_global_roles`, `users.create_in_scope`, ...). Es la misma información que hoy el admin deriva con `roleOnlyAccess` y listas de roles. Las `capabilities` del screen catalog con `exactRoles` o `roleOnlyAccess` se mapean a una capability del backend.
- Admin:
  - `extractRoles` pasa a usar solo `global_roles` + rol del `active_assignment`, igual que la app. Hoy agrega roles de todos los clubs.
  - El slot `@modal` se renderiza solo si `canOpenPage`, y cada page interceptada llama a `canCapability` igual que su page completa (16 pages).
  - Los 10 archivos de Server Actions sin gate reciben `canCapability` antes de reenviar `user_id`/`role_id`/`club_id`.
  - `roleOnlyAccess` (12 usos) y los sets de roles en `lib/` (`territory-scope.ts`, `admin-users/scope.ts`, `catalog-editor-access.ts`, etc.) se reemplazan por capabilities.
  - Eliminar `NEXT_PUBLIC_RBAC_LEGACY_FALLBACK`, `extractLegacyRoles/Permissions` y `canByPermissionOrRole`.
  - Un solo clasificador de 403 en `lib/api/action-error.ts`; los 12 clasificadores por módulo lo reutilizan.
- App:
  - Guard de ruta en GoRouter: cada `GoRoute` de una pantalla del catálogo declara `screenId`; el `redirect` global llama a `canViewScreen` y manda a una vista `AccessDenied` común. Hoy 113 rutas, 1 chequeo.
  - Las tres copias del set de roles de directiva y los ~13 `roleName ==` pasan a capabilities.
  - Refrescar `/auth/me` en `AppLifecycleState.resumed` (hoy solo `refreshSupervision`) y al recibir FCM de invalidación de `authorization`.
  - El snapshot offline restaurado desde `secureStorage` se marca `stale` y bloquea mutaciones hasta re-validar.
  - `SacErrorState.forbidden` como único estado de 403 (hoy 7 usos, todos en coordinator).

**Criterio de salida**: cero listas de roles en `sacdia-admin/src/components` y `sacdia-app/lib/features`; test de paridad admin↔app sobre capabilities en vez de sobre el catálogo de pantallas.

**Riesgo**: medio. Es la fase con más superficie visible; hacer QA por rol con las capturas en `qa-capturas-admin/` y `qa-capturas/`.

---

## Fase 8: Sucesión programada del director

**Objetivo**: entre octubre y diciembre el campo local deja anotado al director del año siguiente. El director vigente conserva el rol hasta el último día del año; el sucesor no tiene permisos hasta el primer día del año siguiente. La activación es automática, idempotente y auditada. Es la alternativa B del diseño P0 de julio (`sdd/authorization-and-director-succession-p0/design`).

**Corrección (2026-11-03, al iniciar la fase)**: la sucesión programada YA EXISTE desde septiembre y la auditoría inicial no la vio (buscó "succession", no "designation"). `director_succession_plans` con idempotencia, `version`, índice único de plan abierto; endpoints `POST/GET/PATCH/DELETE .../director-designation`; activación dentro del corte de año (`YearCutService.activateScheduledPlans`) con `pg_advisory_xact_lock`, ledger `club_year_transitions`, re-chequeo de elegibilidad GM y consentimiento, y notificación al campo si se omite un plan. `director-succession` es la destitución del año vigente, no la herramienta de diciembre. El admin ya tiene el bloque de designación. La fase queda reducida a cerrar brechas:

1. Auditoría durable (`CriticalAuditWriterService`) en designar, reemplazar, cancelar, activar y destituir.
2. Elegibilidad GM y consentimiento al designar y reemplazar, no solo al activar.
3. Autoridad exacta al designar/reemplazar/cancelar/destituir vía `SectionRoleMutationPolicy` (target `director`): admin, super-admin, LF del mismo campo; unión y división fuera; el director de la sección no.
4. Registrar `attempt_count`, `last_attempt_at` y `block_code` cuando el corte omite un plan; el GET los expone.
5. Ventana octubre-diciembre y año objetivo exactamente el siguiente (`EcclesiasticalYearService.getNextYear`).
6. Notificar al sucesor y al saliente cuando un plan se activa.

Lo que sigue abajo es el diseño original; vale como referencia de intención, no como lista de trabajo.

**Comportamiento previo documentado** (`ClubsService.succeedSectionDirector`): el saliente pasa a `active=false, status='ended', end_date=hoy` y el sucesor se crea `active` en la misma transacción. Es destitución del año vigente; para el año siguiente se usa designation.

**Entregables (backend, un PR)**

- Tabla `director_succession_plans`: `succession_id`, `club_section_id`, `outgoing_assignment_id`, `successor_user_id`, `target_ecclesiastical_year_id`, `effective_date`, `status` (`scheduled | activated | blocked | cancelled`), `scheduled_by_id`, `scheduled_at`, `activated_assignment_id`, `activated_at`, `failure_code`, timestamps. Constraint única por `(club_section_id, target_ecclesiastical_year_id)` mientras `status='scheduled'`. El plan NO es un grant: no aparece en `club_role_assignments` y ningún query de autorización puede verlo como vigente.
- `POST /clubs/:clubId/sections/:sectionId/director-succession` cambia de semántica: deja de reemplazar y pasa a programar. Body: `current_assignment_id`, `successor_user_id`, `target_ecclesiastical_year_id`; el servidor deriva `effective_date` del `start_date` del año objetivo. Acepta `Idempotency-Key`. Valida: ventana octubre-diciembre, año objetivo = siguiente, actor exacto `director-lf` o `assistant-lf` del mismo campo local (sin alias de unión ni DIA; `super-admin` pasa), sección activa, saliente vigente, sucesor elegible (Guía Mayor cursando o investido, vía `LeadershipEligibilityService`). Al programar acota `end_date` del saliente al día anterior al año objetivo; hoy no lo revoca.
- `GET .../director-succession` para que el admin muestre el plan vigente sin reconstruir reglas. `DELETE .../director-succession/:successionId` para cancelar, mismo actor exacto.
- Reconciliador: cron diario con lock distribuido (reusar `CronRunLogger` y advisory lock como en otros jobs). Toma planes `scheduled` con `effective_date <= fecha de negocio`; por cada uno, en transacción y bajo advisory lock por sección+año: relee plan, saliente y sucesor, revalida elegibilidad y que no haya otro director vigente, termina al saliente, crea el assignment anual del sucesor (`start_date=year.start_date, end_date=year.end_date, status='active'`), marca `activated` y escribe UN evento de auditoría con el writer transaccional de la fase 2. Replay devuelve el mismo `activated_assignment_id`. Si la elegibilidad o el saliente cambiaron, marca `blocked`, no concede nada y genera notificación al campo local. Tras commit invalida cache de saliente y sucesor.
- `LeadershipEligibilityService` como servicio único (hoy la regla vive duplicada en `ClassCounselorAssignmentsService`, `CertificationsService` y `ClubsService.getMembers`). `APPROVED` no cuenta como investido; solo `INVESTIDO` o enrollment activo no terminal.
- Capability `clubs.schedule_director_succession` en `/auth/me` (fase 7).

**Entregables (admin, un PR)**

- Ficha de sección: card "Sucesión programada" con sucesor, fecha efectiva, estado y quién lo programó. Botón programar/cancelar gateado por la capability. El flujo actual de "suceder ahora" desaparece de la UI.
- Mensajes de error por código: ventana cerrada, año inválido, plan ya existe, sucesor no elegible, actor fuera de su campo, saliente ya no vigente.

**App**: sin cambios. La app no gestiona sucesión.

**Criterio de salida**: tests de que programar no cambia permisos de nadie; de que el saliente sigue con permisos el 31 de diciembre y sin ellos el 1 de enero; de que el sucesor no tiene permisos el 31 y sí el 1; doble ejecución del job produce un assignment y un evento; pérdida de elegibilidad bloquea y notifica; `admin`, `super-admin` (salvo bypass explícito), unión y DIA reciben 403 al programar.

**Riesgo**: medio-alto. Cambia la semántica de un endpoint existente (breaking para el admin, que se actualiza en el mismo bloque). Si el job falla el 1 de enero, la sección queda sin director hasta el reintento: fail-closed a propósito, con alerta. Depende de la fecha de negocio por campo local (zona horaria), decisión pendiente del P0.

---

## Qué NO está en este plan

- **Migrar a OpenFGA/SpiceDB.** Se reevalúa solo si tras la fase 4 el número de policies sigue creciendo más rápido que el de módulos, o si aparece un requisito de "quién tiene acceso a X" (reverse lookup) que las policies no responden bien.
- **Rollover anual de miembros y clases.** La fase 8 solo cubre al director; la continuidad del resto de cargos y de `member` es otro flujo.
- **Renombrar permisos con guion o en español.** Queda como opcional en la fase 3.

## Orden recomendado y paralelismo

```
Fase 0 ──► Fase 1 ──┬──► Fase 8 (necesita 1 y 2)
       └─► Fase 2 ──┼──► Fase 4 ──► Fase 5
       └─► Fase 3 ──┼──► Fase 6
                    └────────────────► Fase 7 (necesita 2, 3 y 4)
```

Un solo desarrollador: 0 → 1 → 2 → 8 → 3 → 4 → 6 → 5 → 7. La 8 va justo después de la 2 porque tiene fecha límite real: debe estar en `preproduction` antes de octubre del año en que se quiera usar. La fase 5 va después de la 6 porque es la más larga y la 6 reduce el ruido para hacerla.

## Métricas de seguimiento

| Métrica | Hoy | Meta |
|---|---|---|
| Líneas `permissions.guard.ts` | 2.377 | < 500 |
| Entradas `tenant-binding-allowlist.ts` | 69 | 0 |
| Literales de rol fuera de guards/policies | 611 | 0 |
| Literales de permiso fuera de `generated/` | ~690 | 0 |
| Copias manuales de catálogo/alias en clientes | 3 | 0 |
| Rutas Flutter con gate de permiso en router | 1 de 113 | todas las del catálogo |
| Cargos de club auditados con actor real | 3 roles, actor = objetivo | todos, actor = autenticado |
| Días sin director tras programar sucesión en octubre | ~90 | 0 |
