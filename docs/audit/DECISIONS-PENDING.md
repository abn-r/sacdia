# Decisiones Pendientes para el Desarrollador

Generado: 2026-03-14
Fuente: Reality Matrix + Canon verification
**Estado: TODAS LAS DECISIONES RESUELTAS**

---

## Consolidación club_sections (2026-03-17)

| Item | Detalle | Resolucion |
|---|---|---|
| 3 tablas idénticas → 1 | `club_adventurers`, `club_pathfinders`, `club_master_guilds` → `club_sections` | RESUELTO: consolidado en tabla única con `club_type_id` como discriminador. Decisión 10 en `decisiones-clave.md`. |
| 3 FK nullables → 1 FK directa | `club_adv_id`/`club_pathf_id`/`club_mg_id` → `club_section_id` en 10 tablas dependientes | RESUELTO: implementado en DB, backend, admin y app. |
| Naming convergencia | `instance` → `section` en URLs y código | RESUELTO: `/clubs/:id/sections/:sectionId`. Permisos: `club_sections:*`. |

---

## Canon aspiracional — mantener como objetivo?

| Claim canon | Archivo | Detalle | Resolucion |
|---|---|---|---|
| Validacion de investiduras como acto institucional | `decisiones-clave.md` (decision 6), `dominio-sacdia.md` | Tablas existen (`investiture_validation_history`, `investiture_config`, `investiture_status_enum` en enrollments) pero no hay modulo backend, endpoints, pages ni screens. Es FANTASMA. | RESUELTO: se mantiene como aspiracional. Ya marcado ASPIRACIONAL en decisiones-clave.md. |
| Supabase Storage | `runtime-sacdia.md` seccion 9 (CORREGIDO) | Ya corregido a Cloudflare R2 en esta actualizacion. No requiere decision adicional. | RESUELTO: corregido a R2 en actualizacion previa. |

---

## Codigo sin canon — agregar al negocio?

### Modulos sin canon
| Modulo | Estado | Detalle | Resolucion |
|---|---|---|---|
| gestion-seguros (insurance) | PARCIAL | App tiene 3 screens completas + datasource. Tabla `member_insurances` existe. No hay backend module dedicado ni endpoints. | RESUELTO: seguros ES canon — parte de la trayectoria institucional del miembro. Agregado a dominio-sacdia.md como "seguro institucional". Backend pendiente de implementacion. |
| infrastructure (health, logging) | NO CANON | Backend CommonModule + Sentry configurado. No mencionado en canon como dominio. | RESUELTO: NO es canon de negocio. Es infraestructura operativa. Documentado por referencia en runtime-sacdia.md seccion 9.1. |

### Endpoints admin de catalogos sin canon (16+ endpoints)
| Endpoints | Resolucion |
|---|---|
| `/admin/allergies` (CRUD completo) | RESUELTO: son catalogos de trayectoria — ES canon. Documentados en runtime-sacdia.md seccion 6.5. Acceso controlado via RBAC, no endpoints separados. |
| `/admin/diseases` (CRUD completo) | Idem |
| `/admin/relationship-types` (CRUD completo) | Idem |
| `/admin/ecclesiastical-years` (CRUD completo) | Idem |
| `/admin/medicines` (CRUD completo, SIN DOCS en ENDPOINTS-LIVE-REFERENCE) | Idem |

### Catalogos publicos sin canon
| Endpoints | Resolucion |
|---|---|
| `GET /catalogs/relationship-types` | RESUELTO: catalogos de trayectoria — ES canon. Soportan la trayectoria institucional del miembro. |
| `GET /catalogs/club-ideals` | Idem |
| `GET /catalogs/allergies` | Idem |
| `GET /catalogs/diseases` | Idem |

### Modelos de datos sin canon (41 de 72)
| Resolucion |
|---|
| RESUELTO: los 72 modelos han sido categorizados en runtime-sacdia.md seccion 8.3 como: core de trayectoria, catalogos de trayectoria, operativos, infraestructura, RBAC y organizacion. |

---

## Drift detectado — cual es la verdad?

| Item | Documentacion decia | Codigo dice | Resolucion |
|---|---|---|---|
| Storage provider | Supabase Storage | Cloudflare R2 (R2FileStorageService) | RESUELTO: canon actualizado a R2 |
| `users.id` vs `users.user_id` | SCHEMA-REFERENCE usaba `id UUID` | schema.prisma usa `user_id` | RESUELTO: SCHEMA-REFERENCE actualizado |
| `users.birthdate` vs `birthday` | SCHEMA-REFERENCE usaba `birthdate` | schema.prisma usa `birthday` | RESUELTO: SCHEMA-REFERENCE actualizado |
| `users.avatar` vs `user_image` | SCHEMA-REFERENCE usaba `avatar` | schema.prisma usa `user_image` | RESUELTO: SCHEMA-REFERENCE actualizado |
| `users_pr` PK | SCHEMA-REFERENCE mostraba `user_id` como PK | schema.prisma tiene `user_pr_id` INT como PK | RESUELTO: SCHEMA-REFERENCE actualizado |
| `users_pr.active_club_assignment_id` | No existia en SCHEMA-REFERENCE | Existe en backend schema.prisma | RESUELTO: agregado a SCHEMA-REFERENCE |
| `club_master_guild` naming | SCHEMA-REFERENCE decia singular | schema.prisma usa `club_master_guilds` (plural) | RESUELTO: SCHEMA-REFERENCE actualizado |
| SCHEMA-REFERENCE cobertura | Cubria ~25 tablas | schema.prisma tiene 72 modelos | RESUELTO: fuera de scope para SCHEMA-REFERENCE. Modelos categorizados en runtime-sacdia.md seccion 8.3 |
| Roles globales en canon | runtime-sacdia.md lista: super_admin, admin, coordinator, user | SCHEMA-REFERENCE lista: super_admin, admin, assistant_admin, coordinator, user | RESUELTO: `assistant_admin` agregado a runtime-sacdia.md seccion 7.2 |

---

## Endpoints FANTASMA detectados

### Consumidos por admin panel
| Endpoint | Nota | Resolucion |
|---|---|---|
| `PATCH /admin/users/:userId/approval` | Usado en admin para aprobar usuarios | RESUELTO: pendiente de implementacion en backend. Documentado en features/auth.md |
| `PATCH /admin/users/:userId` | Fallback de approval en admin | RESUELTO: pendiente de implementacion en backend |
| `GET /admin/honor-categories` | CRUD completo en admin (5 endpoints) | RESUELTO: pendiente de implementacion en backend. Documentado en features/honores.md |
| `POST /admin/honor-categories` | Idem | Idem |
| `PATCH /admin/honor-categories/:id` | Idem | Idem |
| `DELETE /admin/honor-categories/:id` | Idem | Idem |
| `GET /admin/honor-categories/:id` | Idem | Idem |
| `GET /admin/club-ideals` | Read-only en admin | RESUELTO: pendiente de implementacion en backend. Documentado en features/catalogos.md |

### Consumidos por app movil
| Endpoint | Nota | Resolucion |
|---|---|---|
| `POST /auth/update-password` | Llamado por app pero no existe en backend | RESUELTO: pendiente de implementacion en backend. Documentado en features/auth.md |
| `GET /clubs/:clubId/sections/:sectionId/evidence-folder` | Evidence folder feature sin backend | RESUELTO: pendiente de implementacion. Naming canonico consolidado (2026-03-17). Documentado en features/carpetas-evidencias.md |
| `POST /clubs/:clubId/sections/:sectionId/evidence-folder/sections/:efSectionId/submit` | Idem | Idem |
| `POST /clubs/:clubId/sections/:sectionId/evidence-folder/sections/:efSectionId/files` | Idem | Idem |
| `DELETE /clubs/:clubId/sections/:sectionId/evidence-folder/sections/:efSectionId/files/:fileId` | Idem | Idem |
| `GET /clubs/:clubId/sections/:sectionId/members/insurance` | Insurance listing sin backend | RESUELTO: pendiente de implementacion. Seguros es canon de trayectoria. Documentado en features/gestion-seguros.md |
| `GET /users/:memberId/insurance` | Insurance detail sin backend | Idem |
| `POST /users/:memberId/insurance` | Create insurance sin backend | Idem |
| `PATCH /insurance/:insuranceId` | Update insurance sin backend | Idem |

**Nota**: Ninguno de estos endpoints estaba en ENDPOINTS-LIVE-REFERENCE.md, por lo que no se removio nada de ese documento. El gap es entre lo que los clientes consumen y lo que el backend expone. Todos marcados como pendientes de implementacion en sus respectivos archivos de features.

---

## Gaps de implementacion — Wave 2 (2026-03-20)

Descubiertos durante auditoría Wave 2. Fuente: docs de features bajo `docs/features/` y `docs/canon/completion-matrix.md` (OPEN).

### GAP-W2-01: Validacion de Investiduras — RESUELTO

| Item | Detalle |
|---|---|
| Infraestructura DB | Completa: `investiture_validation_history`, `investiture_config`, 3 enums, campos de investidura en `enrollments` |
| Runtime backend | IMPLEMENTADO: InvestitureModule con 5 endpoints, 23 tests. |
| Runtime frontend - Admin | IMPLEMENTADO: Tabla de validaciones, dialogs de accion (aprobar/rechazar/investido), historial timeline, filtros por estado/año, entry en sidebar nav. 9 archivos. |
| Runtime frontend - App | IMPLEMENTADO: 3 screens principales (pending list, submit view, history timeline), data layer completa (entities, models, datasource, repository, providers), status badge widget, GoRouter integration. 16 archivos. |
| Severidad | Gap funcional completamente resuelto |
| Estado | RESUELTO 2026-03-20: UI implementada en Flutter (16 archivos, 3 screens) y admin (9 archivos, pending table + history + dialogs). Commits 2f4ac49 + 7199ab0. |
| Descubierto | Wave 2 (2026-03-20) |

### GAP-W2-02: Actividades — hardcoded clubId=1 — RESUELTO

| Item | Detalle |
|---|---|
| Problema | El controller/service de actividades tiene `clubId=1` hardcodeado en vez de usar el contexto real del club |
| Tipo | Bug directo |
| Estado | RESUELTO 2026-03-20: Fix aplicado: ActivitiesListView resuelve clubId desde clubContextProvider. Commit dbb14eb. |
| Descubierto | Wave 2 (2026-03-20) |

### GAP-W2-03: Finanzas — campos de auditoria faltantes — RESUELTO

| Item | Detalle |
|---|---|
| Problema | Los registros financieros carecen de campos `created_by`/`modified_by` que otros modulos si tienen |
| Tipo | Gap de consistencia / auditoria |
| Estado | RESUELTO 2026-03-20: modified_by_id agregado a finances (migration + schema + service). Commit 69b4b3e. |
| Descubierto | Wave 2 (2026-03-20) |

### GAP-W2-04: Inventario — typo en PK de DB — RESUELTO

| Item | Detalle |
|---|---|
| Problema | La tabla `inventory_categories` tiene un typo en su columna PK: `inventory_categoty_id` en vez de `inventory_category_id` |
| Impacto | Prisma lo mapea correctamente, pero el nombre subyacente en la columna es incorrecto |
| Estado | RESUELTO 2026-03-20: Migration creada para rename. Commit d690a57. Pendiente: prisma migrate deploy. |
| Descubierto | Wave 2 (2026-03-20) |

### GAP-W2-05: Certificaciones Guias Mayores — cero UI cliente — RESUELTO

| Item | Detalle |
|---|---|
| Backend | Completamente implementado: 7 endpoints verificados y funcionales |
| Admin panel | UI implementada: list + detail + progress |
| App movil | UI implementada: 4 screens en Flutter |
| Estado | RESUELTO 2026-03-20: UI implementada en Flutter (4 screens) y admin (list + detail + progress). Commits 69cb026 + 37e5929. |
| Descubierto | Wave 2 (2026-03-20) |

---

## Wave 3 — Spike Findings (W3-000) — 2026-03-22

### W3-000: Better Auth Token Format Spike — COMPLETADO

Spike ejecutado el 2026-03-22. Script en `sacdia-backend/scripts/spike-better-auth.ts`.
Fuente: análisis del código fuente de better-auth@1.5.6.

#### Q1 — Tipo de token: OPAQUE SESSION TOKEN (no JWT)

| Item | Detalle |
|---|---|
| Tipo | Token opaco — string random de 32 bytes (`generateId(32)`) |
| Fuente | `better-auth/dist/db/internal-adapter.mjs:156` |
| Respuesta signInEmail | `{ token: session.token, user: {...} }` |
| Conclusion | El token devuelto por `signInEmail` NO es un JWT. Es un identificador opaco almacenado en la tabla `session`. No tiene estructura header.payload.signature. |

#### Q2 — Algoritmo: N/A para token primario

| Item | Detalle |
|---|---|
| Token primario | No aplica — es un string opaco, no JWT |
| JWT plugin (opt-in) | EdDSA (Ed25519) por defecto. Tambien soporta ES256, ES512, RSA256, PS256, ECDH-ES |
| HS256 | NO soportado por el JWT plugin de better-auth |
| Fuente | `better-auth/dist/plugins/jwt/sign.mjs` |

#### Q3 — Claims JWT (solo si se usa el JWT plugin)

| Claim | Valor |
|---|---|
| `sub` | `user.id` = `users.user_id` (UUID, despues del field mapping) |
| `iat` | Timestamp actual |
| `exp` | `iat + expirationTime` (default: 15 minutos) |
| `iss` | `baseURL` |
| `aud` | `baseURL` |
| Payload adicional | Objeto usuario completo (name, email, emailVerified, image) |
| Fuente | `better-auth/dist/plugins/jwt/sign.mjs` (funcion `getJwtToken`) |

#### Q4 — Alcance de `usePlural: true`

| Item | Detalle |
|---|---|
| Tablas afectadas | TODAS las cuatro tablas core: user→users, session→sessions, account→accounts, verification→verifications |
| Fuente | `@better-auth/core/dist/db/adapter/get-model-name.mjs` |
| Recomendacion | Usar `modelName` por tabla en vez de `usePlural: true` para control preciso |
| Config recomendada | `user: { modelName: "users" }` — las otras tres quedan como `session`, `account`, `verification` |

#### Q5 — Columnas SACDIA extras (additionalFields)

| Item | Detalle |
|---|---|
| Comportamiento | BA ignora completamente columnas desconocidas |
| Mecanismo | `transformInput()` itera solo `schema[model].fields` — construye `transformedData` exclusivamente de campos BA conocidos |
| Fuente | `@better-auth/core/dist/db/adapter/factory.mjs:102-144` |
| Conclusion | NO se necesita declarar `additionalFields` para columnas SACDIA (paternal_last_name, gender, blood, birthday, approval_status, etc.). BA nunca las lee ni las escribe. |

#### Q6 — Server API sin HTTP handler

| Item | Detalle |
|---|---|
| auth.api disponible | Si — BA endpoints son funciones, no solo HTTP routes |
| Llamadas server-side | `auth.api.signInEmail({ body: { email, password } })` funciona directo |
| HTTP handler requerido | Solo para callbacks OAuth (redirect flow a `/auth/callback/*`) |
| Fuente | Documentacion BA + verificado en spike (auth.api disponible post-init) |

---

### IMPLICACION CRITICA: Redesign de W3-009 requerido

**El diseño actual de W3-009 (JwtStrategy HS256 con BETTER_AUTH_SECRET) es INVALIDO.**

Better Auth NO emite HS256 JWTs. El token primario es opaco. El JWT plugin usa EdDSA/JWKS.

El `JwtStrategy` actual de NestJS (`passport-jwt` + `secretOrKey: BETTER_AUTH_SECRET`) NO funcionará con Better Auth sin cambios fundamentales.

#### Opciones de validación (para decidir antes de W3-009):

| Opción | Descripción | Pros | Contras |
|---|---|---|---|
| **A — Session validation (recomendada)** | Guard NestJS que llama `auth.api.getSession({ headers })` en cada request | Idiomático BA, revocación nativa, sin key management | DB lookup por request (cacheable con Redis) |
| **B — JWT plugin + JWKS** | Usar plugin `jwt()`, cliente llama `GET /auth/token` para obtener JWT EdDSA, JwtStrategy valida contra JWKS | Stateless, similar al patrón actual Supabase ES256 | Requiere tabla `jwk`, JWT expira en 15 min por defecto, más complejidad |
| **C — Custom HS256 signing** | BetterAuthService firma manualmente un JWT HS256 con `@nestjs/jwt` después del login, sin usar el JWT plugin de BA | Mantiene JwtStrategy actual prácticamente sin cambios | No idiomático BA, manual de manejar refresh/revocación |

**Recomendación**: Opción A. Reemplazar PassportStrategy con un NestJS Guard que valide via `auth.api.getSession()`. Cachear el resultado en Redis con TTL = min(session.expiresAt, 5min).

**Impacto en el plan de tareas**:
- W3-009 debe ser rediseñado antes de implementarse
- W3-007 y W3-008 permanecen válidos (BetterAuthService interface es correcta)
- El token que se devuelve al cliente es el opaque session token, no un JWT
- `buildAuthTokenResponse()` debe actualizarse — ya no hay `access_token` JWT

| Estado | Detalle |
|---|---|
| Spike completado | 2026-03-22 |
| Script | `sacdia-backend/scripts/spike-better-auth.ts` |
| better-auth instalado | `package.json` + `pnpm-lock.yaml` actualizados |
| Preguntas 1-6 | Todas respondidas con evidencia de código fuente |
| Accion requerida | Equipo debe decidir Opcion A/B/C antes de iniciar W3-009 |

---

## DEUDA TÉCNICA — Legacy Column Naming: `districts.districlub_type_id` (2026-04-12)

### Contexto

La tabla `districts` en `sacdia-backend/prisma/schema.prisma` tiene una PK con nombre heredado confuso: `districlub_type_id` en vez de `district_id`. El nombre mezcla "district" y "club_type", aparentemente un typo histórico o naming accidental que quedó consolidado.

La tabla `churches` propaga este error: usa `districlub_type_id` como FK hacia `districts`, multiplicando el impacto del nombre legacy por toda la relación.

### Impacto

**En la BD y Prisma:**
- Columna subyacente: `districlub_type_id` (incorrecto, confuso)
- Propagación: FK en `churches`, y por referencia indirecta en cualquier service que cargue relaciones (ej: `admin-geography.service.ts`, `clubs.service.ts`)
- Riesgo: future developers confunden el nombre con club_type

**Antes de la mitigación (commits 2026-04-12):**
- API público exponía nombre legacy: `{ "districlub_type_id": 123 }`
- Clientes (admin, app) consumían directamente el nombre confuso

### Mitigación Actual

**Commits 2026-04-12:**
- `d082d9e` (sacdia-backend): mappers en `catalogs.service.ts` (`mapDistrict`, `mapChurch`) aliasean la columna como `district_id` en responses
- `62786ee` (sacdia-admin): UI consume el alias público `district_id`
- `036ee2d` (sacdia-app): Flutter datasources mapean hacia `district_id`

**Resultado:**
- Contrato API público ya expone el nombre correcto: `{ "district_id": 123 }`
- Clientes aislados del nombre legacy
- Costo: cero migraciones complejas, mitigación pura en mappers

### Por qué NO migramos la BD

1. **Rename de columna complicado**: requiere `ALTER TABLE districts RENAME COLUMN` seguido de actualizar todas las FKs (`churches.districlub_type_id`, y cualquier otra tabla que lo use como FK)
2. **Locking en vivo**: en una BD con datos de producción, el rename genera locks que pueden afectar operaciones
3. **Propagación de cambios**: Prisma schema, migrations, y todas las queries directas que leen `districlub_type_id` necesitarían actualización (riesgo de inconsistencias transitorias)
4. **Bajo ROI**: el alias en la API ya expone el nombre correcto externamente. El beneficio cosmético no justifica el riesgo operativo

### Cuándo revisitar

- **Major schema refactor**: cuando se planee reestructuración más amplia (ej: consolidación de tablas de geografía, índices, particionamiento)
- **Window de mantenimiento**: si se abre una ventana de downtime programado para cambios grandes
- **Contexto adicional**: si emergen FKs nuevas o cambios en `club_type` que hagan el nombre aún más confuso

### Referencia de commits

- **Backend mitigación**: `d082d9e` — mappers con alias `district_id` en CatalogsService
- **Admin mitigación**: `62786ee` — UI actualizada a consumir alias
- **App mitigación**: `036ee2d` — Flutter datasources mapean alias
