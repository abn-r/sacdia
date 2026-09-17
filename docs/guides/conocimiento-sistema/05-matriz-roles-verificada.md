# 05 · Matriz de roles verificada (corte de código)

**Estado**: DRAFT  
**Tipo de corte**: corte documental de código — no certifica cuentas ni una base desplegada  
**Fecha del corte**: 2026-09-14  
**Audiencia**: presentación ejecutiva para la Dirección de Jóvenes de la Unión Mexicana Interoceánica (UMI)

## 1. Qué se verificó

Se contrastaron nombres de roles, categorías, permisos declarados en seeds, metadata
de controladores y resolución de autorización del backend. El alcance se acotó a:

1. gestión de miembros e inscripción anual;
2. finanzas: lectura y creación de movimientos;
3. revisión de evidencias (cola de revisión, validación y carpeta anual);
4. configuración de permisos/RBAC;
5. alcance Unión–Campo Local–sección y cambio de contexto.

No se revisaron los cientos de endpoints ni se consultó una base real. No se ejecutaron
tests, builds ni seeds. Por tanto, una cuenta de la UMI solo puede habilitarse después
de verificar sus grants efectivos, alcance territorial y asignación activa.

### Leyenda

| Marca | Significado en esta ficha |
|---|---|
| **SÍ** | El camino de permiso/rol está declarado para esa familia. |
| **COND.** | Puede operar, pero depende de alcance territorial, sección/club activo, vigencia, asignación de coordinación u otra regla explícita. |
| **NO-B** | No aparece en los grants del baseline SQL revisado. No significa denegación absoluta: un grant dinámico podría cambiarlo. |
| **NO-G** | Una guardia de rol explícita excluye la combinación en esa ruta; un grant de permiso por sí solo no la salta. |
| **NO DET.** | No se puede concluir sin consultar la configuración/DB o la ruta no forma parte del corte. |

## 2. Inventario de nombres: dónde hay divergencia

El seed TypeScript de Prisma declara como **GLOBAL** `super-admin`, `admin`,
`assistant-admin`, `coordinator`, `pastor`, `user`, y como **CLUB** `director`,
`deputy-director`, `secretary`, `treasurer`, `counselor`, `instructor`, `member`
([`prisma/seed.ts:58-150`](../../../sacdia-backend/prisma/seed.ts#L58-L150)).

El código de autorización también reconoce los roles territoriales
`director-lf`/`assistant-lf`, `director-union`/`assistant-union` y
`director-dia`/`assistant-dia` ([`global-roles.decorator.ts:5-19`](../../../sacdia-backend/src/common/decorators/global-roles.decorator.ts#L5-L19)).
El SQL de permisos los usa y copia desde `assistant-lf` ([`role-permissions.seed.sql:1604-1742`](../../../sacdia-backend/prisma/seeds/role-permissions.seed.sql#L1604-L1742)).

Como esos roles territoriales tampoco son creados por `prisma/seed.ts`, su
existencia efectiva en una base es **NO DET.** (pueden haber sido creados por una
migración, bootstrap o administración RBAC). La misma cautela aplica a
`zone-coordinator`, `general-coordinator` y `secretary-treasurer`.

Hay dos divergencias importantes que deben quedar visibles al director:

- `secretary-treasurer` es aceptado por la guardia y tiene bloque de permisos,
  pero no aparece en `prisma/seed.ts` ni en `roles.constants.ts`. No se debe asumir
  que existe en una base recién inicializada ([`club-roles.guard.ts:14-23`](../../../sacdia-backend/src/common/guards/club-roles.guard.ts#L14-L23), [`role-permissions.seed.sql:672-817`](../../../sacdia-backend/prisma/seeds/role-permissions.seed.sql#L672-L817), [`roles.constants.ts:7-36`](../../../sacdia-backend/src/common/constants/roles.constants.ts#L7-L36)).
- `prisma.config.ts` ejecuta únicamente `prisma/seed.ts`; los SQL de permisos se
  ejecutan aparte. Por eso **no existe un seed único, automático y canónico de
  rol × permiso** dentro del flujo `prisma db seed`. El SQL se describe a sí mismo
  como fuente única, pero tiene bloques `DELETE+INSERT`, copias posteriores y
  parches adicionales ([`prisma.config.ts:6-15`](../../../sacdia-backend/prisma.config.ts#L6-L15), [`role-permissions.seed.sql:4-12`](../../../sacdia-backend/prisma/seeds/role-permissions.seed.sql#L4-L12), [`role-permissions.seed.sql:1791-1873`](../../../sacdia-backend/prisma/seeds/role-permissions.seed.sql#L1791-L1873)).

Las formas humanas/legacy de ciertos roles (`secretario`, `tesorero`,
`secretario-tesorero`, `subdirector`) solo se normalizan dentro de
`ClubRolesGuard`; el valor persistido canónico sigue siendo el nombre con guiones
([`club-roles.guard.ts:25-40`](../../../sacdia-backend/src/common/guards/club-roles.guard.ts#L25-L40)).

## 3. Matriz ejecutiva: acción × familia × alcance

**Interpretación**: “SÍ” en una familia global significa que el permiso existe en
el SQL de grants. El acceso efectivo sigue siendo “COND.” si el recurso debe caer
dentro de Unión/Campo Local, o si se exige la sección activa. Los grants directos
de `users_permissions` pueden cambiar una celda para una persona, por lo que esta
tabla no sustituye la lectura de `authorization.effective`.

### 3.1 Miembros e inscripción anual

La ruta canónica `GET/POST /club-sections/:sectionId/annual-continuations` exige
`club_members:approve` y recurso `club_section` de la sección destino; usa el año
eclesiástico vigente y no autoriza al dueño del perfil ([`annual-continuations.controller.ts:35-118`](../../../sacdia-backend/src/annual-membership/annual-continuations.controller.ts#L35-L118)).

| Familia/roles exactos | Permiso sembrado | Acceso efectivo | Alcance verificable |
|---|---:|---:|---|
| `member`, `counselor`, `instructor` | NO-B | **NO-B** | No tienen el grant en el baseline revisado; no es una auditoría de grants directos. |
| `secretary` | SÍ | **COND.** | Sección activa exacta con `club_members:approve`; el seed lo declara en [`role-permissions.seed.sql:495-541`](../../../sacdia-backend/prisma/seeds/role-permissions.seed.sql#L495-L541). |
| `treasurer` | NO-B | **NO-B** | Tiene finanzas, no `club_members:approve` en el baseline ([`role-permissions.seed.sql:638-670`](../../../sacdia-backend/prisma/seeds/role-permissions.seed.sql#L638-L670)). |
| `secretary-treasurer` | SÍ | **COND.** | Sección activa exacta; existencia del rol en DB es **NO DET.** por la divergencia del seed. |
| `deputy-director` | SÍ | **COND.** | Sección activa exacta ([`role-permissions.seed.sql:911-950`](../../../sacdia-backend/prisma/seeds/role-permissions.seed.sql#L911-L950)). |
| `director` | SÍ | **COND.** | Sección activa exacta; además representa la directiva de destino ([`role-permissions.seed.sql:1087-1103`](../../../sacdia-backend/prisma/seeds/role-permissions.seed.sql#L1087-L1103)). |
| `coordinator`, `zone-coordinator`, `general-coordinator` | NO-B | **NO-B** | No tienen el grant en el baseline; su coordinación se usa para cola de revisión, no para esta aprobación. |
| `director-lf`, `assistant-lf`, `director-union`, `assistant-union`, `director-dia`, `assistant-dia` | SÍ | **COND.** | Permiso global, pero la sección debe estar dentro del Campo/Unión/División del grant y pasar `AuthorizationResource`. El grupo de Campo Local es la fuente copiada ([`role-permissions.seed.sql:1462-1465`](../../../sacdia-backend/prisma/seeds/role-permissions.seed.sql#L1462-L1465), [`role-permissions.seed.sql:1604-1742`](../../../sacdia-backend/prisma/seeds/role-permissions.seed.sql#L1604-L1742)). |
| `pastor`, `user` | NO-B | **NO-B** | No tienen el permiso en el baseline revisado. |
| `admin` | SÍ por wildcard (sin `:delete`) | **COND.** | Solo dentro del alcance configurado; precedencia Unión → Campo → División. |
| `assistant-admin` | NO-B | **NO-B** | `GlobalRolesGuard` lo trata como alias de `admin`, pero el wildcard de permisos no se declara para este rol. |
| `super-admin` | SÍ | **COND.** | Bypass global de alcance; sigue aplicando la regla de negocio del año vigente. |

### 3.2 Finanzas: lectura y creación

Lectura requiere `finances:read` sobre el club. Creación requiere además
`finances:create` y `ClubRolesGuard` con `director`, `deputy-director`, `treasurer`
o `secretary-treasurer` ([`finances.controller.ts:90-267`](../../../sacdia-backend/src/finances/finances.controller.ts#L90-L267)).

| Familia/roles exactos | Lectura | Creación | Alcance |
|---|---:|---:|---|
| `member`, `counselor`, `instructor` | NO-B | NO-B | No tienen `finances:*` en el baseline. |
| `secretary` | NO-B | NO-B/NO-G | No tiene `finances:read` en el baseline y tampoco está en `ClubRoles` de creación. |
| `treasurer` | **COND.** | **COND.** | Sección/club activo compatible; grants CRUD en [`role-permissions.seed.sql:638-655`](../../../sacdia-backend/prisma/seeds/role-permissions.seed.sql#L638-L655). |
| `secretary-treasurer` | **COND.** | **COND.** | Igual que tesorería; existencia efectiva del rol: **NO DET.** por divergencia de seed. |
| `deputy-director` | **COND.** | **NO-B** | Está admitido por `ClubRolesGuard`, pero solo tiene `finances:read` en el baseline ([`role-permissions.seed.sql:911-933`](../../../sacdia-backend/prisma/seeds/role-permissions.seed.sql#L911-L933)). |
| `director` | **COND.** | **COND.** | Sección activa exacta y club administrable; grants CRUD en [`role-permissions.seed.sql:1072-1077`](../../../sacdia-backend/prisma/seeds/role-permissions.seed.sql#L1072-L1077). |
| `director-lf`/`assistant-lf` | **COND.** | **COND.** | Alcance Campo Local; bypass territorial con permiso global. |
| `director-union`/`assistant-union` | **COND.** | **COND.** | Alcance Unión; no se reduce al `local_field_id` de origen. |
| `director-dia`/`assistant-dia` | **COND.** | **COND.** | Alcance División. |
| `coordinator`, `zone-coordinator`, `general-coordinator`, `pastor`, `user` | NO-B | NO-B | No tienen grants `finances:*` en el SQL inspeccionado. |
| `admin` | **COND.** | **COND.** | Wildcard de `admin` (sin `:delete`), limitado por ancla territorial. |
| `assistant-admin` | NO-B | NO-B | El alias de rol no implica heredar el wildcard de permisos; requeriría grant explícito. |
| `super-admin` | **COND.** | **COND.** | Permiso total; la guardia mantiene validación de recurso. |

### 3.3 Revisión de evidencias: no mezclar tres flujos

| Flujo | Requisito de backend | Familias con camino declarado | Alcance/limitación |
|---|---|---|---|
| Cola `/evidence-review` (clases/honores, aprobar/rechazar) | `validation:review` **y** `GlobalRoles(admin, super-admin, coordinator)` ([`evidence-review.controller.ts:35-42`](../../../sacdia-backend/src/evidence-review/evidence-review.controller.ts#L35-L42)) | `coordinator`, `zone-coordinator`, `general-coordinator`, `admin`, `assistant-admin` (alias de `admin`), `super-admin`, `director-lf`/`assistant-lf` (alias de `coordinator`, runtime 15-sep) | Coordinadores quedan recortados a las secciones de `coordinator_assignments`; admin/assistant-admin/superadmin sin ese recorte de coordinación ([`evidence-review.service.ts:1307-1354`](../../../sacdia-backend/src/evidence-review/evidence-review.service.ts#L1307-L1354)). Unión/DIA con `validation:review` siguen **NO-G** en esta cola: el alias de `coordinator` no incluye union/dia. |
| Validación `/validation/:entityType/:entityId/review` | `validation:review`, recurso `active_assignment` ([`validation.controller.ts:74-120`](../../../sacdia-backend/src/validation/validation.controller.ts#L74-L120)) | `counselor`, `instructor`, `secretary`, `treasurer`, `secretary-treasurer`, `deputy-director`, `director`; coordinadores, LF/Unión/DIA y admin/superadmin según grant | **COND.** por asignación activa y entidad; no equivale a revisión universal. |
| Evaluar/reabrir carpeta anual | `annual_folders:evaluate` global ([`evaluation.controller.ts:33-73`](../../../sacdia-backend/src/annual-folders/evaluation.controller.ts#L33-L73)) | LF/Unión/DIA, admin/superadmin; club roles y coordinadores: NO-B en grants revisados | **COND.** por territorio y estado de carpeta. `confirm-union` aplica además un **NO-G** para roles no `director-union`/`assistant-union` en servicio ([`evaluation.service.ts:306-335`](../../../sacdia-backend/src/annual-folders/evaluation.service.ts#L306-L335)). |

### 3.4 Configuración de permisos y roles

| Acción | Familias | Resultado |
|---|---|---|
| Ver catálogo/roles RBAC (`permissions:read`, `roles:read`) | `admin`, `super-admin` por wildcard; `assistant-admin` por subconjunto (incluye `roles:read`/`permissions:read`, no `permissions:assign`) | **COND.**: la ruta de lectura exige permiso. |
| Crear/editar/desactivar permisos o roles | Solo `super-admin` | **SÍ**, pero exclusivamente con `GlobalRoles('super-admin')` + `permissions:assign` ([`rbac.controller.ts:143-204`](../../../sacdia-backend/src/rbac/rbac.controller.ts#L143-L204)). |
| Asignar/quitar permisos a rol o usuario | Solo `super-admin` | **SÍ**, mismo doble control ([`rbac.controller.ts:199-299`](../../../sacdia-backend/src/rbac/rbac.controller.ts#L199-L299)). |
| Asignar/quitar roles globales a usuarios | `admin`/`super-admin` como actor de la ruta; `assistant-admin` es alias de `admin` en `GlobalRolesGuard` y **no** recibe `permissions:assign` en el seed de subconjunto | **COND.**: además aplican límites de jerarquía y política del servicio; no convertir cargo humano en `admin` automáticamente. |

La DB puede apartarse de los SQL porque RBAC es dinámico: `role_permissions` y
`users_permissions` se pueden modificar desde las rutas anteriores. El backend arma
los permisos globales con roles globales + grants directos, y solo toma permisos de
la asignación activa para el lado club ([`permissions.guard.ts:313-343`](../../../sacdia-backend/src/common/guards/permissions.guard.ts#L313-L343), [`permissions.guard.ts:371-401`](../../../sacdia-backend/src/common/guards/permissions.guard.ts#L371-L401)). Un grant directo modifica la comprobación de permiso, pero no salta una guardia de rol duro como `ClubRolesGuard` ni una exigencia `GlobalRoles`.

## 4. Alcance territorial y multi-contexto

| Familia | Alcance resuelto por código | Lectura ejecutiva |
|---|---|---|
| `super-admin` | `all` | Control técnico global; no es el rol recomendado para una dirección territorial. |
| `director-dia`/`assistant-dia` | `division` | Todas las Uniones de la División, con `division_id` configurado. |
| `director-union`/`assistant-union` | `union` | Todas las áreas de la Unión; el campo local de origen no cambia este nivel. |
| `director-lf`/`assistant-lf` | `local_field` | Solo el Campo Local del grant. |
| `admin`/`assistant-admin` | Unión, luego Campo Local, luego División | La resolución de alcance es simétrica. Permisos: `admin` wildcard menos delete y `audit:read`; `assistant-admin` el mismo recorte **más** sin `permissions:assign`. Sin ancla queda `unconfigured` y se deniega. |
| `coordinator`/`zone-coordinator`/`general-coordinator` | No usan el recorte genérico territorial; secciones efectivas por `coordinator_assignments` en flujos de coordinación | No presentar como “acceso a toda la Unión” sin revisar las asignaciones de coordinación. |
| `pastor` | Documentado como distrito read-only, pero no tiene rama en `resolveActorTerritoryScope` | **NO DET.** para una autorización genérica; requiere validar endpoint específico. |
| Roles CLUB | `active_assignment` exacta (club/sección/instancia) | Un cargo en otra sección no habilita esta operación. |

La implementación resuelve el nivel territorial por rol antes que por el campo de
origen ([`actor-territory-scope.ts:146-213`](../../../sacdia-backend/src/common/authorization/actor-territory-scope.ts#L146-L213)). El cambio de contexto solo acepta una asignación propia,
`status=active` y del año eclesiástico vigente; después invalida caché y recalcula
autorización ([`auth.service.ts:621-697`](../../../sacdia-backend/src/auth/auth.service.ts#L621-L697)).
Aunque existan varias asignaciones, solo una aporta permisos de club; las demás no se
fusionan ([`authorization-context.service.ts:470-545`](../../../sacdia-backend/src/common/services/authorization-context.service.ts#L470-L545)).

## 5. Interpretación humana para la UMI

- **Dirección de Unión** no equivale a administrador técnico: puede tener alcance de
  Unión y permisos operativos, pero la configuración de RBAC queda reservada a
  `super-admin`.
- Para inscripción anual, la capacidad útil es `club_members:approve` sobre la
  sección destino; “ver miembros” o tener un cargo territorial no basta por sí solo.
- Para finanzas, **leer no implica crear**. El tesorero sí puede crear si su asignación
  está activa; el subdirector puede leer pero el seed no le da creación.
- Revisar evidencias de la cola central, evaluar carpetas anuales y aprobar una
  validación son flujos distintos y tienen actores distintos.
- Una persona con varias responsabilidades debe elegir contexto; cambiarlo no crea
  permisos nuevos.

## 6. Riesgos y preguntas operativas antes de una demostración

1. ¿La base que usará la demostración contiene los roles territoriales y
   `secretary-treasurer`, o solo los roles creados por `prisma/seed.ts`?
2. ¿Cuál es el `union_id` real de la UMI y qué `local_field_id`/`division_id` trae el
   grant de la cuenta del director?
3. ¿La cuenta tiene `club_members:approve`, `finances:read` y/o `finances:create` en
   `authorization.effective.permissions`, o solo un cargo humano documentado?
4. ¿Qué secciones de coordinación están asignadas para la cola de evidencias? No
   usar una cuenta de coordinador como sustituto de un director de Unión.
5. ¿El entorno aplicó en orden `permissions.seed.sql` y `role-permissions.seed.sql`,
   y luego invalidó `auth:context`? El flujo Prisma por sí solo no aplica ambos SQL.
6. ¿Se probará una sección ajena como caso denegado? Es el control que demuestra que
   el alcance no depende del ID enviado por la pantalla.

## 7. Cinco mensajes breves para slides

1. **“El backend decide: identidad, permiso, recurso y territorio.”**
2. **“Dirección de Unión no es super-administración técnica.”**
3. **“Inscribir al miembro del año vigente exige autorización sobre la sección destino.”**
4. **“Finanzas: leer y crear son permisos distintos.”**
5. **“Cambiar de sección cambia el contexto; no inventa permisos.”**

## 8. Evidencia y cobertura de pruebas (sin ejecutar)

Se localizaron pruebas estáticas/de unidad para metadata de inscripción anual
([`annual-continuations.controller.spec.ts:34-50`](../../../sacdia-backend/src/annual-membership/annual-continuations.controller.spec.ts#L34-L50)), guardias de permisos y contexto activo
([`permissions.guard.spec.ts`](../../../sacdia-backend/src/common/guards/permissions.guard.spec.ts), [`authorization-context.service.spec.ts:600-640`](../../../sacdia-backend/src/common/services/authorization-context.service.spec.ts#L600-L640)) y limpieza/forma de los seeds
([`permissions-cleanup.spec.ts`](../../../sacdia-backend/src/common/seeds/__tests__/permissions-cleanup.spec.ts)). Se investigaron sus ubicaciones,
pero no se ejecutaron por la restricción de este corte.

### Archivos principales y hash SHA-1 del corte local

| Archivo | Hash |
|---|---|
| `sacdia-backend/prisma/seed.ts` | `6654c2b90e97cbba1807d001f9608ec9c869039d` |
| `sacdia-backend/prisma/seeds/permissions.seed.sql` | `efb504a3d74e35ecb6304f843cfb77c18fb50b51` |
| `sacdia-backend/prisma/seeds/role-permissions.seed.sql` | `01c109be4d836cbc33e83ee4ac44765f0cbde2d7` |
| `sacdia-backend/src/common/guards/permissions.guard.ts` | `5b4494072be95132acc4fd64daecd625114774cf` |
| `sacdia-backend/src/common/authorization/actor-territory-scope.ts` | `23f75cd5ac0b455acf0c3040c30da89eeffec71e` |
| `sacdia-backend/src/annual-membership/annual-continuations.controller.ts` | `22bb36c08179565061c579a0f3322b8c636f24a0` |
| `sacdia-backend/src/finances/finances.controller.ts` | `92c36502942af8d3942b1be358f33bdc9e5a5c70` |
| `sacdia-backend/src/evidence-review/evidence-review.controller.ts` | `feb78f86a396a2823d327fe7736c97dc1616819e` |
| `sacdia-backend/src/rbac/rbac.controller.ts` | `79fcef979a17b344b8112c2929f069fecc6d79ad` |

**Conclusión del corte**: la ficha define controles y condiciones que deben
verificarse para una demostración territorial; no es una auditoría integral de
seguridad. La cuenta del director de la UMI debe verificarse en runtime y esta
ficha no certifica que una persona concreta tenga hoy esos roles o permisos.
