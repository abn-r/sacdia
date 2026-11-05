# Matriz de Enforcement RBAC

**Status**: ACTIVE
**Fecha**: 2026-03-10 (actualizada 2026-11-05: policies por recurso, `@ExactGlobalRoles`, kinds de `bind`, allowlist de tenant a cero y consumo de capabilities por los clientes)
**Ambito**: backend enforced permissions

## Proposito

Esta matriz define como se traduce un permiso en enforcement real de backend y como deben consumirlo `sacdia-admin` y `sacdia-app`.

La regla principal es:

- JWT autentica;
- `PermissionsGuard` autoriza;
- el frontend nunca es barrera de seguridad.

## Tipos de Recurso

| Tipo | Descripcion | Resolucion |
|------|-------------|------------|
| `global` | Recurso administrativo o territorial | Permisos globales + scope territorial |
| `club` | Recurso de club padre | Permiso efectivo + bypass global o contexto club activo |
| `club_section` | Recurso de una seccion concreta | Permiso efectivo + asignacion activa de esa `sectionId` (no basta el club padre) |
| `club_instance` | Recurso de instancia exacta | Permiso efectivo + asignacion activa exacta |
| `active_assignment` | Recurso ligado al contexto operativo activo del actor | Permiso efectivo + asignacion activa exacta |
| `club_assignment` | Recurso de asignacion | Permiso efectivo + relacion con `assignment_id` |
| `user` | Recurso del propio usuario | Permiso global o fallback de ownership |

Autoridad exacta sobre cargos de club (`src/common/authorization/section-role-mutation.policy.ts`), aplicada a asignar, actualizar y revocar cargos, `director-assignment`, `director-succession` y `director-designation`: `super-admin` y `admin` (cualquier sección); `director-lf` y `assistant-lf` del mismo campo local que el club; `director` vigente de la misma sección, salvo sobre sí mismo o sobre el cargo `director`. El rol destino `member` está exento (lo rigen los flujos de membresía). Unión, DIA y `assistant-admin` no mutan cargos. Los nombres de rol se comparan literalmente, sin alias ni herencia. Rechazo: 403 `CLUB_ROLE_MUTATION_FORBIDDEN`.

Nota de implementacion:

- En codigo existen recursos derivados (`activity`, `finance`, `inventory_item`, `inventory_instance`) que resuelven finalmente a validacion de `club_instance`.
- Desde la fase 4 (backend PR #613, 2026-11-04) `PermissionsGuard` no resuelve el scope por sí mismo: despacha cada `type` a una policy de `src/common/authorization/policies/` (`ResourcePolicy.resolve(ctx)`); el registry es un tipo mapeado sobre `AuthorizationResourceType`, así que un tipo sin policy no compila. Policies: `global`, `user`, `active_assignment`; `club`, `club_section`, `activity`, `activity_series`, `finance`, `inventory_instance`, `inventory_item`, `club_assignment`, `class_counselor_assignment`, `investiture_enrollment`, `monthly_report`, `insurance_member`, `insurance_record`; `camporee`, `union_camporee`, `camporee_event`, `camporee_venue`, `camporee_payment`. Detalle en `docs/features/rbac.md`, «Policies por recurso y `ActorScope`».

### Tenant binding (`bind`)

Además del `type`, `@AuthorizationResource` puede declarar `bind` para atar la request a un tenant del path. `TenantBindingEnforcer` (`src/common/authorization/tenant-binding.enforcer.ts`) lo verifica antes del scope. `src/common/guards/tenant-binding-allowlist.ts` está vacía desde la fase 5 (backend PR #615, 2026-11-04) y su spec exige que siga vacía: toda ruta con tenant en el path declara `bind`.

| Kind | Qué exige | Estado |
|------|-----------|--------|
| `club` | el club del path está en el alcance del actor | `development` (antes de la fase 5) |
| `club_section` | la sección del path está en el alcance del actor | `development` (antes de la fase 5) |
| `local_field` | el campo local del path está en el territorio del actor | `development` (antes de la fase 5) |
| `union` | la unión del path está en el territorio del actor | `development` (antes de la fase 5) |
| `camporee` | el camporee local del path está en el ámbito del actor | `development` (antes de la fase 5) |
| `union_camporee` | solo la unión dueña del camporee de unión | `development` (antes de la fase 5) |
| `club_enrollment_territory` | la inscripción anual del path pertenece al territorio del actor | `development` (antes de la fase 5) |
| `union_camporee_participant` | unión dueña, o campo participante con fila activa en `union_camporee_local_fields`, o club con campo activo | `development` (fase 5, 2026-11-04) |
| `club_section_membership` | jerarquía o cualquier asignación de club operativa del actor en esa sección | `development` (fase 5, 2026-11-04) |
| `union_membership` | jerarquía o cualquier asignación de club operativa del actor en esa unión | `development` (fase 5, 2026-11-04) |
| `local_field_membership` | jerarquía o cualquier asignación de club operativa del actor en ese campo local | `development` (fase 5, 2026-11-04) |

El tenant que llega en body o query sin `bind` queda inventariado en `tenant-body-allowlist.ts` (55 rutas `global` / `user` / `active_assignment`, con ratchet propio; solo inventario).

## Reglas de Evaluacion

1. Para recursos globales, solo cuentan grants globales y `direct_permissions`.
2. Para recursos de club, puede entrar:
   - un permiso global suficiente dentro del territorio (incluye grant directo);
   - o la asignacion activa exacta del usuario.
3. Los permisos de club salen solo de `active_assignment`.
4. No se unen todas las asignaciones del usuario para una request.
5. JWT-only solo es aceptable con `@SkipPermissions` o `@Public`, y solo en self-service estricto, pickers post-registro o superficies `GlobalRoles` que no hablan el catalogo de permisos. Un handler JWT nuevo sin metadata falla cerrado.

## Matriz Operativa

| Permiso | Accion | Recurso | Enforcement backend | Cliente esperado |
|---------|--------|---------|---------------------|------------------|
| `users:read` | Listar usuarios | `global` | permiso global | Admin |
| `users:read_detail` | Ver detalle de usuario | `global` o `user` | permiso global o ownership segun ruta | Admin y self-service |
| `users:update` | Editar usuario | `global` o `user` | permiso global o guard de ownership | Admin y self-service |
| `club_roles:read` | Roles asignables a un miembro (`GET .../members/:userId/assignable-roles`) | `club` | permiso + seccion perteneciente al club | Admin y App |
| `club_roles:assign` | Asignar/actualizar cargo de club | `club` | permiso + regla de elegibilidad GM (403 `CLUB_ROLE_GUIDE_MAJOR_REQUIRED` / `CLUB_ROLE_MEMBER_REQUIRES_GUIDE_MAJOR_SECTION`) dentro de la transaccion | Admin y App |
| `clubs:read` | Ver club | `club` | permiso global territorial o contexto club | Admin y App |
| `clubs:create` | Crear club | `global` | permiso global; sin bypass de rol. Seed: admin, super-admin, assistant-admin. No director-lf/assistant-lf | Admin: `/dashboard/clubs/new` e import (`canCreateClubs` / `clubs.create`) |
| `clubs:update` | Editar club | `club` | permiso + ClubRoles director/deputy/secretary/secretary-treasurer o bypass territorial | Admin y App |
| `club_sections:update` | Editar seccion | `club` | permiso + ClubRoles director/deputy/secretary/secretary-treasurer o bypass territorial | Admin y App |
| `clubs:delete` | Desactivar club | `club` | permiso global territorial o active assignment compatible | Admin |
| `club_instances:read` | Ver instancias | `club` | permiso global territorial o contexto club | Admin y App |
| `club_instances:create` | Crear instancia | `club` | permiso global territorial o active assignment compatible | Admin |
| `club_instances:update` | Editar instancia | `club_instance` | permiso efectivo + asignacion activa exacta o bypass global | Admin y App |
| `club_roles:read` | Ver miembros y asignaciones | `club` | permiso global territorial o contexto club | Admin y App |
| `club_members:approve` | Listar no inscritos del año vigente (`GET /club-sections/:sectionId/annual-continuations`) | `club_section` | permiso + `@AuthorizationResource` club_section (idParam: sectionId) | Admin |
| `club_members:approve` | Inscribir no inscritos (`POST /club-sections/:sectionId/annual-continuations`) | `club_section` | permiso + `@AuthorizationResource` club_section (idParam: sectionId). Owner del perfil **no** autoriza. | Admin |
| `registration:complete` | Autoinscripción anual (`POST /users/:userId/membership/annual-enroll`) | `user` | Guard: permiso + owner bypass. Servicio: **403** `ANNUAL_ENROLL_REQUIRES_DIRECTIVE` (D01). Sin efectos. | App |
| `club_roles:assign` | Crear asignacion (`POST /clubs/:clubId/sections/:sectionId/roles`) | `club` | permiso + `@AuthorizationResource` club (`clubIdParam`) + `SectionRoleMutationPolicy` (autoridad exacta, abajo) + reglas complementarias en `ClubsService.assignRole`; `club_section_id` del body debe coincidir con `sectionId`; evento crítico `CLUB_ROLE_ASSIGNED` en la misma transacción | Admin y App |
| `club_roles:assign` | Preelegir / reemplazar / cancelar director N+1 (`POST`/`PATCH`/`DELETE /clubs/:clubId/sections/:sectionId/director-designation`) | `club` | permiso + `@AuthorizationResource` club + `SectionRoleMutationPolicy` (`super-admin`, `admin`, `director-lf`/`assistant-lf` del mismo campo local; 403 `CLUB_ROLE_MUTATION_FORBIDDEN`) + rol global `super-admin`/`admin`/`director-lf`/`assistant-lf` en el POST; sección ∈ club de la URL; solo año siguiente, ventana 1 oct–31 dic por fecha de negocio del campo | Admin |
| `club_roles:assign` | Leer programación de director (`GET /clubs/:clubId/sections/:sectionId/director-designation`) | `club` | mismos actores que POST (el permiso solo no basta; GET también pasa por `SectionRoleMutationPolicy` con el cargo `director`, por lo que un director de sección es rechazado) | Admin |
| `club_roles:assign` | Actualizar asignacion (`PATCH /club-roles/:assignmentId`) | `club_assignment` | permiso efectivo + active assignment o bypass global + `SectionRoleMutationPolicy` sobre el rol actual y el nuevo; evento crítico `CLUB_ROLE_UPDATED` | Admin y App |
| `club_roles:revoke` | Revocar asignacion (`DELETE /club-roles/:assignmentId`) | `club_assignment` | permiso efectivo + active assignment o bypass global + `SectionRoleMutationPolicy`; evento crítico `CLUB_ROLE_REVOKED` | Admin |
| `activities:read` | Ver actividades | `club` | permiso global territorial o contexto club | Admin y App |
| `activities:create` | Crear actividad | `club` | permiso + ClubRoles director/deputy/secretary/secretary-treasurer/counselor o bypass territorial | Admin y App |
| `activities:update` | Editar actividad | `club_instance` | permiso efectivo + instancia exacta o bypass global | Admin y App |
| `activities:delete` | Eliminar actividad | `club_instance` | permiso efectivo + instancia exacta o bypass global | Admin |
| `attendance:read` | Ver asistencia | `club_instance` | permiso efectivo + instancia exacta o bypass global | Admin y App |
| `attendance:manage` | Pasar asistencia | `club_instance` | permiso efectivo + instancia exacta o bypass global | Admin y App |
| `qr:issue_self` | Ver credencial QR propia | `global` | permiso global dedicado de self-service | Admin y App |
| `qr:validate` | Validar QR de un miembro | `active_assignment` | permiso efectivo + asignacion activa exacta o bypass global | Admin y App |
| `finances:read` | Ver finanzas | `club` | permiso global territorial o contexto club | Admin y App |
| `finances:create` | Crear movimiento | `club` | permiso + ClubRoles director/deputy/treasurer/secretary-treasurer o bypass territorial | Admin y App |
| `finances:update` | Editar movimiento | `club_instance` | permiso efectivo + instancia exacta o bypass global | Admin y App |
| `finances:delete` | Eliminar movimiento | `club_instance` | permiso efectivo + instancia exacta o bypass global | Admin |
| `inventory:read` | Ver inventario | `club` | permiso global territorial o contexto club | Admin y App |
| `inventory:create` | Crear item | `club_instance` | permiso efectivo + asignacion activa exacta o bypass global | Admin y App |
| `inventory:update` | Editar item | `club_instance` | permiso efectivo + asignacion activa exacta o bypass global | Admin y App |
| `inventory:delete` | Eliminar item | `club_instance` | permiso efectivo + asignacion activa exacta o bypass global | Admin |
| `notifications:send` | Enviar notificacion directa | `global` | permiso global explicito | Admin |
| `notifications:broadcast` | Enviar notificacion masiva | `global` | permiso global explicito | Admin |
| `notifications:club` | Enviar notificacion a club (`POST /notifications/club/:instanceType/:instanceId`) | `active_assignment` | permiso efectivo + asignacion activa exacta. Desde la fase 5 (2026-11-04) `bind: club_section` sobre `:instanceId` | Admin |
| `permissions:read` | Ver RBAC | `global` | permiso global | Admin |
| `permissions:assign` | Cambiar permisos | `global` | permiso + `@GlobalRoles('super-admin')` | Admin |
| `permissions:assign` | Asignar / revocar rol global (`POST`/`DELETE /admin/rbac/users/:userId/roles[/:roleId]`) | `global` | permiso + `@GlobalRoles('super-admin')` + `GlobalUserRoleWriteService` (`ExactSuperAdminWritePolicy`: fila activa `users_roles` `super-admin` GLOBAL, si no 403 `SUPER_ADMIN_WRITE_REQUIRED`; locks, `Idempotency-Key`, evento crítico `RBAC_GLOBAL_ROLE_ASSIGNED`/`REVOKED`) | Admin |
| `roles:read` | Ver roles globales de un usuario (`GET /admin/rbac/users/:userId/roles`) | `global` | permiso + `@GlobalRoles('admin', 'super-admin')` | Admin |
| `roles:read` | Ver roles | `global` | permiso global | Admin |
| `user_honors:create` | Alta de especialidad (`POST /users/:userId/honors`, `/bulk`) | `user` | permiso + ownership (`ownerParam: userId`). Servicio: una fila `APPROVED` o `PENDING_REVIEW` responde 400 `VALIDATION_HONOR_INVALID_STATUS` sin escribir (SEC-1) | App |
| `user_honors:delete` | Abandonar especialidad (`DELETE /users/:userId/honors/:honorId`) | `user` | permiso + ownership. Servicio: `APPROVED` y `PENDING_REVIEW` bloqueadas (SEC-2) | App |
| `user_honors:submit` | Proponer o retirar el instructor de una especialidad aprobada (`POST`/`DELETE /users/:userId/honors/:honorId/instructor-proposal`) | `user` | permiso + ownership en el guard. Servicio: solo el dueño (`req.user.sub === :userId`; si no, 403 `HONOR_INSTRUCTOR_PROPOSAL_FORBIDDEN`: el permiso sobre el usuario no basta). `POST` con throttle de 10 por minuto | App |
| `-` (`@SkipPermissions`, JWT) | Buscar instructores (`GET /instructor-candidates?q=`) | `global` | solo JWT. El alcance lo aplica el servicio: mismo `local_field_id` que quien consulta, activos, aprobados, mayores de edad, sin incluirlo y sin correo. Throttle de 30 por minuto | App |
| `-` (`@SkipPermissions`, JWT) | Catálogo de clases de la carga por certificado y borrado de borrador (`GET catalog/classes`, `DELETE /certificate-bulk-imports/:batchId`) | `user` | solo JWT. Servicio: el borrado exige dueño y lote `DRAFT` (si no, 404 o 409) | App |
| `-` (`@ExactGlobalRoles` + `@SkipPermissions`) | Revisar la carga por certificado (`/admin/certificate-bulk-imports/*`) | `global` | `super-admin`, `admin`, `assistant-admin`, `director-lf`, `assistant-lf`, **sin expansión de alias** (desde la fase 6, backend PR #614; antes `@GlobalRoles`, con el mismo resultado porque `reviewer-scope.ts` ya comparaba de forma exacta). Alcance por Campo Local del lote (`src/common/reviewer-scope`): quien tiene Campo Local solo ve el suyo | Admin |
| `-` (`@ExactGlobalRoles` + `@SkipPermissions`) | Cola de propuestas de instructor (`/admin/honor-instructor-proposals`: listar, `approve`, `reject`) | `global` | mismos cinco roles que la fila anterior, sin expansión de alias. Alcance por el Campo Local **actual del dueño** de la especialidad; fuera de él, 403 `HONOR_INSTRUCTOR_PROPOSAL_FORBIDDEN` | Admin |
| `camporee-orders:*`, `camporee-supplies:*`, `field-payment-orders:*`, `camporees:read` | 39 rutas de camporee: orders, offerings, payment-orders, configuración y planes de supplies, y `GET /camporees/union/:camporeeId` | `global` o `active_assignment` según la ruta (ver `ENDPOINTS-LIVE-REFERENCE.md`) | Fase 5 (backend PR #615, 2026-11-04): las rutas `global` conservan tipo y ganan `bind` (`camporee` o `union_camporee_participant`); las `active_assignment` pasan a tipo `camporee` / `union_camporee` con `idParam: 'camporeeId'`. Cambio de comportamiento: `GET .../order-offerings`, `GET .../supply-catalog`, `GET .../supply-plans`, `GET .../supply-reports/{kitchen,cash}`, `PATCH .../supply-plan/lines` (local y unión) y `GET /camporees/union/:camporeeId` responden 403 `GUARD_CLUB_SCOPE_REQUIRED` fuera del ámbito del camporee (404 `CAMPOREE_NOT_FOUND` / `CAMPOREE_UNION_CAMPOREE_NOT_FOUND` si no existe); los directores de una unión que no organiza pierden el bypass en planes de insumos; los códigos del guard preceden a `CAMPOREE_ORDER_*` / `CAMPOREE_SUPPLIES_*` en casos cross-tenant | Admin y App |
| `camporee-orders:offering-configure` | Ventana y ofertas del camporee de unión (`PATCH /union-camporees/:camporeeId/orders-settings`, `PUT /union-camporees/:camporeeId/order-offerings`) | `global` | permiso global. Desde la fase 5 (2026-11-04) `bind: union_camporee` (solo la unión dueña) | Admin |
| `coordination:manage` + `@GlobalRoles` | Zonas, asignaciones y backfill de un campo (`GET` y `POST /admin/coordination/local-fields/:localFieldId/{zones,assignments,backfill}`) | sin cambio de `type` | permiso + rol global (admin, campo, unión y división; ver `ENDPOINTS-LIVE-REFERENCE.md`). Desde la fase 5 (2026-11-04) `bind: local_field` sobre `:localFieldId` | Admin |
| `materiales:configure` | Config de materiales de un campo (`PATCH /materials/config/:localFieldId`) | sin cambio de `type` | permiso. Desde la fase 5 (2026-11-04) `bind: local_field` sobre `:localFieldId` | Admin |
| `rankings:*` / `section_rankings:*` (any) | Progreso anual de una sección (`GET /club-sections/:sectionId/annual-ranking-progress`) y miembros de un ranking de sección (`GET /section-rankings/:sectionId/members`) | sin cambio de `type` | permiso (any, ver `ENDPOINTS-LIVE-REFERENCE.md`). Desde la fase 5 (2026-11-04) `bind: club_section_membership` sobre `:sectionId` | Admin y App |
| `scoring_categories:read` / `manage` | Categorías de puntuación de unión (`/unions/:unionId/scoring-categories*`) y de campo (`/local-fields/:fieldId/scoring-categories*`) | sin cambio de `type` | permiso. Desde la fase 5 (2026-11-04) `bind: union_membership` sobre `:unionId` y `local_field_membership` sobre `:fieldId`. Decisión de producto conservada: un consejero de club puede crear categorías de puntuación de su unión | Admin |

## Decisiones de producto abiertas (alias amplio en mutaciones)

Detectadas al cerrar la fase 6 (`@ExactGlobalRoles`). No cambió el runtime; siguen con `@GlobalRoles` y, por tanto, con expansión de alias. Registradas en `docs/audit/DECISIONS-PENDING.md`.

- `PATCH local-fields/:id/investiture-windows/:yearId`.
- Las mutaciones de `district-investiture-pastors`.
- Las mutaciones de `admin/coordination`.
- Toda ruta `@GlobalRoles(admin, super-admin)` admite también `assistant-admin` (alias simétrico `admin ↔ assistant-admin`).

## Cobertura y Limites de Stage 1

- Esta matriz refleja enforcement activo de rutas sensibles priorizadas.
- El catalogo completo de permisos vive en `PERMISSIONS-SYSTEM.md`.
- No todo permiso del catalogo implica que su modulo ya este endurecido al 100% con metadata de recurso en esta etapa.

## Recursos `user` sensibles verificados

| Superficie | Rutas verificadas | Permiso runtime | Enforcement backend | Estado |
|------------|-------------------|-----------------|---------------------|--------|
| Perfil y derivados (fuera de scope) | `GET/PATCH /users/:userId`, `GET /age`, `GET /requires-legal-representative`, `POST/DELETE /profile-picture` | `users:read_detail` o `users:update_profile` | ownership o permiso global; metadata legacy `users:*` | Verificado |
| Salud | `GET/PUT /allergies`, `GET/PUT /diseases`, `GET/PUT /medicines`, `DELETE /allergies/:allergyId`, `DELETE /diseases/:diseaseId`, `DELETE /medicines/:medicineId` | `health:read` / `health:update` OR fallback `users:read_detail` / `users:update_profile` | ownership, permiso global, o lectura club-scoped (`health:read` del club activo + miembro activo de la sección); baseline activo limitado a `allergies` + `diseases` + `medicines` | Verificado |
| Contactos de emergencia | `GET/POST/PATCH/DELETE /emergency-contacts` | `emergency_contacts:read` / `emergency_contacts:update` OR fallback `users:read_detail` / `users:update_profile` | ownership, permiso global, o lectura club-scoped (miembro activo de la sección) | Verificado |
| Representante legal | `GET/POST/PATCH/DELETE /legal-representative` | `legal_representative:read` / `legal_representative:update` OR fallback `users:read_detail` / `users:update_profile` | ownership, permiso global, o lectura club-scoped (miembro activo de la sección) | Verificado |
| Post-registro (lectura) | `GET /post-registration/status` | `post_registration:read` OR fallback `users:read_detail` | ownership, permiso global, o lectura club-scoped (miembro activo de la sección) | Verificado runtime |
| Post-registro (completar) | `POST /step-1/complete`, `POST /step-2/complete`, `POST /step-3/complete` | `registration:complete` _(sin fallback)_ | ownership o permiso global dedicado; terceros quedan en modo administrativo minimo | Verificado runtime |

Notas:

- `PermissionsGuard` permite owner fallback antes de resolver permisos explicitos en recursos `user`.
- Para actores no owner, solo cuentan permisos globales; un `active_assignment` con permisos de club no abre acceso a datos `user` de terceros.
- OR transicional vigente en backend: permiso fino de familia o fallback legacy de la familia `users:*` (`users:read_detail` para lectura, `users:update_profile` para escritura). Excepcion: `registration:complete` no tiene fallback legacy.
- Sunset del OR: `USERS_LEGACY_OR_SUNSET_DATE = 2027-03-31` en `sensitive-user-subresource-policy.ts`. Hasta esa fecha el fallback sigue canonico; no se apaga el OR en runtime. Despues, terceros necesitan el permiso fino de familia. El self-service del owner no cambia.
- `registration:complete` es un permiso global dedicado asignado a roles de campo (super_admin, admin, assistant-lf, director-lf y equivalentes union/dia por herencia). El owner siempre puede completar su propio registro sin este permiso.
- Baseline health activo verificado: `allergies` + `diseases` + `medicines`.
- `medicines` se limita a catalogo + relacion sensible `user -> medicines`; no existe vinculo runtime `medicine <-> disease` en esta fase.
- Excepcion minima vigente: `post_registration` de terceros mantiene lectura administrativa minima y completion con `registration:complete`, sin feedback sensible detallado.
- Exclusiones fuera de scope del change: perfil base, foto de perfil y derivados de edad/representante legal siguen en metadata legacy `users:*`.

## Validacion Transversal Final (Batch 3)

| Capa | Evidencia verificada | Resultado |
|------|----------------------|-----------|
| Docs auth | `AUTHORIZATION-CANONICAL-CONTRACT.md` y esta matriz usan las mismas familias finas, fallback legacy y exclusiones fuera de scope | Alineado |
| Backend | `PermissionsGuard` mantiene ownership o permiso global para recurso `user`; permisos de club solo alcanzan terceros en lectura de perfil de sección y en `family:read` sensible sobre miembros activos de la sección activa (sin fallback legacy, nunca `update`) | Alineado |
| Admin | consumo canonico desde `authorization.effective.permissions` y `authorization.grants` | Alineado |
| Mobile | helpers separan `administrative completion` de acceso a datos sensibles y no tratan `users:update` como permiso sensible de lectura | Alineado |

## Endpoints que no deben quedar en JWT-only

Las siguientes categorias no deben confiar solo en autenticacion:

- administracion de usuarios;
- geografia y catalogos sensibles;
- clubes e instancias;
- miembros y asignaciones de rol;
- actividades;
- finanzas;
- inventario;
- notificaciones;
- cualquier mutacion compartida.

## Endpoints que si pueden vivir con ownership

JWT-only o ownership guard dedicado sigue siendo valido solo si:

- el recurso es exclusivamente del usuario autenticado;
- no altera datos compartidos del club;
- no eleva privilegios;
- no actua sobre informacion de terceros.

## Consumo por Cliente

### `sacdia-admin`

- Usa `authorization.effective.permissions` para pagina, accion y visibilidad operativa.
- Desde la fase 7 (admin #290, 2026-11-04/05) las decisiones que dependen de rol o territorio leen `authorization.capabilities` (gates `capabilityAccess`, slot `@modal`, Server Actions con `requireCapability`) y `authorization.territory`; ya no se derivan de listas de roles. `authorization.assignable_global_roles` alimenta los selectores de rol al crear usuarios.
- Puede usar `authorization.grants` para matrices, explicaciones y detalle.

### `sacdia-app`

- Usa `authorization.effective.permissions` para habilitar acciones.
- Desde la fase 7 (app #234, #236 y #238) usa `authorization.capabilities` (`hasCapability`) para lo que el backend ya calcula y el guard de ruta (`routeScreenIds` → `canViewScreen` → `/access-denied`). Un snapshot restaurado sin red queda stale y bloquea mutaciones (403 sintético `AUTHORIZATION_STALE`) hasta releer `/auth/me`. Quedan gates por nombre de rol en la app; ver `docs/features/rbac.md`, «Capabilities y clientes (fase 7)».
- Usa `authorization.effective.scope.club` para el club/instancia actual.
- Usa `authorization.grants.club_assignments` para selector de contexto.

## Referencias Relacionadas

- `docs/features/auth/AUTHORIZATION-CANONICAL-CONTRACT.md`
- `docs/features/auth/PERMISSIONS-SYSTEM.md`
- `docs/history/implementation/IMPLEMENTATION-SESSION-2026-03-07-rbac-hardening-stage-1.md`
