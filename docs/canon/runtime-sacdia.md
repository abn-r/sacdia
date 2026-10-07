# Runtime SACDIA

**Estado**: ACTIVE
**Autoridad rectora**: `docs/canon/source-of-truth.md`
**Tipo de documento**: runtime canonizado, documented-as-built
**Ámbito**: topología, stack, superficie API, autorización, persistencia e integraciones del sistema completo

<!-- VERIFICADO contra código 2026-10-04 en la rama development de sacdia-backend (66f4ade), sacdia-admin y sacdia-app. Cifras recontadas sobre el código; ver §12 para cómo recontarlas. -->

> [!IMPORTANT]
> Este documento es la foto técnica base del runtime. Cada área con canon propio (`runtime-*.md`, `auth/runtime-auth.md`) manda en su detalle.
> Si este documento contradice el código de `development`, el documento está desactualizado y debe corregirse.

---

## 1. Regla de lectura

1. `docs/canon/source-of-truth.md` fija la precedencia.
2. `docs/canon/dominio-sacdia.md` manda en semántica; este documento manda en comportamiento técnico vigente.
3. Los `runtime-*.md` específicos y `auth/runtime-auth.md` mandan sobre este documento en su área.
4. Contratos de detalle: `docs/api/ENDPOINTS-LIVE-REFERENCE.md` (API) y `sacdia-backend/prisma/schema.prisma` (datos).
5. Estado funcional por dominio: `docs/features/README.md`.

---

## 2. Qué es el runtime actual de SACDIA

SACDIA es un sistema full-stack formado por repositorios independientes dentro de un mismo workspace:

- `sacdia-backend/`: API REST, reglas de negocio, seguridad, autorización y contratos;
- `sacdia-admin/`: panel administrativo web;
- `sacdia-app/`: app móvil (iOS y Android);
- `sacdia/` (este repo): documentación global y scripts de verificación documental;
- `sacdia-docs/`: portal de manuales (gitlink en este repo; pendiente de rediseño como portal sin permisos por rol).

El producto **todavía no está en producción**. El flujo de ramas de los repos runtime es `development` → `preproduction` (QA) → `main`; los workflows de CI de backend y app corren sobre esas tres ramas.

El runtime no se interpreta desde pantallas o CRUDs aislados, sino desde la trayectoria institucional del miembro, la operación por secciones de club, el periodo operativo y la validación institucional.

---

## 3. Topología y stack

### 3.1 Capas

- **Dominio**: semántica y reglas de interpretación (`docs/canon/dominio-sacdia.md`).
- **Backend**: lógica operativa, seguridad, autorización y contratos API.
- **Admin web**: gestión, supervisión y operación administrativa.
- **App móvil**: operación contextual del miembro, la directiva del club y los coordinadores.
- **Datos**: PostgreSQL con Prisma.

### 3.2 Stack verificado

| Capa | Tecnología (versión declarada) | Fuente |
|---|---|---|
| Backend | NestJS `^11.2`, TypeScript `^6.0`, Node.js `>=24 <25` (CI `24.13.1`), pnpm `10.29.3` | `sacdia-backend/package.json`, `.github/workflows/ci.yml` |
| ORM / datos | Prisma `^7.9.1` con `@prisma/adapter-pg`; PostgreSQL en **Neon** | `package.json`, `.env.example` |
| Autenticación | **Better Auth** `^1.6` self-hosted + JWT HS256 firmado por SACDIA | `src/better-auth/`, `src/auth/` |
| Cache, colas y rate limit | Redis (`REDIS_URL`; Upstash recomendado), `cache-manager` + `@keyv/redis`, **BullMQ**, `@nestjs/throttler` | `src/config/*.config.ts` |
| Admin web | Next.js `16.2.4` (App Router), React `19.2.3`, Tailwind CSS v4, shadcn/ui, TanStack Query, Zustand, next-intl, Vitest | `sacdia-admin/package.json` |
| App móvil | Flutter (CI `3.41.6`), Dart SDK `^3.6.1`, Riverpod `^2.6`, Dio, go_router `^15.2`, easy_localization, Hive, flutter_secure_storage | `sacdia-app/pubspec.yaml`, `.github/workflows/ci.yml` |
| Hosting | Backend en **Render** (blueprint `sacdia-backend/render.yaml`); admin en **Vercel** | `render.yaml`; `sacdia-admin/sentry.*.config.ts` (`VERCEL_GIT_COMMIT_SHA`) |

### 3.3 Convenciones HTTP del backend

- Prefijo global `/api` y versionado por URI con versión por defecto `1`: todas las rutas viven en `/api/v1/*` (`src/main.ts`).
- Puerto por defecto `3000` (`PORT`). El admin corre en `3001` (`next dev -p 3001`).
- Swagger en `/api` **solo** si `SWAGGER_ENABLED=true`; en producción está prohibido por validación de entorno.
- Health check público: `GET /api/v1/health` (lo usa Render como `healthCheckPath`).
- Respuestas admin con forma `{ status, data }`.
- Middleware global: `helmet`, `compression`, CORS con lista `ALLOWED_ORIGINS` (obligatoria en producción) y `trust proxy` según `TRUST_PROXY_HOPS`.

---

## 4. Fronteras canónicas del runtime

### 4.1 Lenguaje canónico vs naming técnico

- `Club` = raíz institucional (`clubs`);
- `Sección de club` = unidad operativa real (`club_sections`, tabla única diferenciada por `club_type_id`; Decisión 10);
- `user` = representación técnica del miembro;
- `role` / `assignment` = representación técnica que no sustituye el concepto canónico de cargo o vinculación institucional.

### 4.2 Verdad anual vs trayectoria consolidada
<!-- VERIFICADO contra código 2026-05-29: enrollments existe en schema.prisma; users_classes/users_classes_archive fueron retiradas -->

La frontera runtime vigente queda documentada así:

- `enrollments` = verdad operativa anual del cursado, progreso, validación e investidura del periodo; <!-- VERIFICADO -->
- la trayectoria histórica de clases se consulta desde `enrollments` con filtros por año eclesiástico y estado;
- `users_classes` y `users_classes_archive` no existen en el schema runtime actual.

Esta frontera está respaldada por `docs/canon/decisiones-clave.md` y por las notas runtime activas en `ENDPOINTS-LIVE-REFERENCE.md`.

---

## 5. Superficie API

### 5.1 Tamaño

Recuento sobre `sacdia-backend/src` en `development` (2026-10-04):

- **108** controllers (`*.controller.ts`);
- **866** handlers HTTP (`@Get/@Post/@Put/@Patch/@Delete`);
- **70** archivos `*.module.ts` (incluido `AppModule` y submódulos), en **66** carpetas de primer nivel.

El contrato detallado por endpoint vive en `docs/api/ENDPOINTS-LIVE-REFERENCE.md`. Su consistencia se comprueba con `node scripts/verify-api-docs-consistency.mjs` (workflow `docs-api-consistency.yml`).

### 5.2 Módulos por área

| Área | Carpetas en `sacdia-backend/src/` |
|---|---|
| Identidad y acceso | `auth`, `better-auth`, `rbac`, `users`, `post-registration`, `emergency-contacts`, `legal-representatives`, `qr` |
| Estructura institucional | `catalogs`, `clubs`, `club-enrollments`, `coordination`, `units`, `system-config`, `i18n` |
| Formación y reconocimiento | `classes`, `honors`, `certifications`, `investiture`, `validation`, `evidence-review`, `certificate-bulk-imports`, `achievements`, `member-of-month`, `weekly-records` vía `units` |
| Operación de club | `activities`, `finances`, `inventory`, `resources`, `materials`, `membership-requests`, `requests`, `annual-membership` |
| Carpetas, puntaje y clasificación | `annual-folders`, `scoring-categories`, `ranking-weights`, `rankings` (member/section/annual) |
| Camporees | `camporees`, `camporee-events`, `camporee-event-templates`, `camporee-scoring`, `camporee-staff`, `camporee-venues`, `camporee-orders`, `camporee-supplies` |
| Pagos y seguros | `field-payment-orders`, `payment-obligations`, `insurance` |
| Reportes y cierre de año | `monthly-reports`, `quarterly-reports`, `annual-reports`, `reports`, `year-end`, `year-cut` |
| Operación y soporte | `admin`, `analytics`, `dashboard`, `notifications`, `audit-logs`, `background-jobs`, `data-export`, `support`, `health` |
| Infraestructura interna | `common`, `config`, `prisma` |

Notas:

- `institutional-history` solo contiene el dominio y políticas del PR1 (sin controller); ver `docs/plans/2026-07-23-institutional-history-implementation-plan.md`.
- El módulo legacy `folders` no tiene controller; los modelos `folders*` siguen en el schema (ver `docs/history/canon/runtime-user-folders.md` y `decisiones-clave.md` §19).
- La autorización de investidura por umbral, las ventanas/solicitudes de investidura por campo local y el OCR de Vision con ADC/PDF están en la rama de backend `feat/investiture-authorization-ocr` (PR #448), **pendiente de merge**. No forman parte de `development`.

---

## 6. Capacidades runtime

### 6.1 Autenticación y sesión

Detalle canónico en `docs/canon/auth/runtime-auth.md`. Resumen:

- Better Auth autentica (email/contraseña, OAuth Google y Apple, MFA TOTP); SACDIA firma un JWT de acceso HS256 con `BETTER_AUTH_SECRET`, `iss=https://api.sacdia.app`, `aud=sacdia:access`, expiración 8 h;
- la sesión de Better Auth dura 7 días (refresh) y cada usuario tiene como máximo 5 sesiones concurrentes;
- los tokens QR de miembro usan otro secreto (`QR_JWT_SECRET`) y `aud=sacdia:qr-member`; el `JwtStrategy` los rechaza como token de API;
- el admin guarda los tokens en cookies httpOnly (`sacdia_admin_access_token`, `sacdia_admin_refresh_token`; `sameSite=strict`) a través de sus rutas `src/app/api/auth/*`;
- la app guarda los tokens en `flutter_secure_storage` (`core/auth/app_auth_service.dart`).

### 6.2 Perfil, salud y post-registro
<!-- VERIFICADO contra código 2026-03-14: users module ALINEADO -->

El runtime documenta:

- lectura y actualización del usuario;
- foto de perfil;
- edad calculada;
- requirement de representante legal;
- alergias, enfermedades y medicamentos como sub-recursos sensibles;
- contactos de emergencia;
- representante legal;
- estado y pasos de post-registro.

Notas runtime activas:

- las superficies sensibles de `user` usan autorización contextual sobre `userId`;
- el owner puede operar sus propias rutas sensibles;
- terceros requieren permisos globales o permisos finos transicionales según familia;
- `post-registration step 3` crea o reactiva alta anual en `enrollments`;
- `post-registration step 3` deriva la clase desde fecha de nacimiento, inicio del año eclesiástico y tipo de club seleccionado; si el cliente envía un `class_id` que no coincide, se rechaza;
- si el usuario re-ejecuta post-registro por corrección/cambio de club, se desactivan otros enrollments activos del año antes de resolver la clase derivada;
- si una transferencia de club/sección es aprobada, se aplica la misma regla de clase derivada para el `club_type_id` destino y se resuelve el enrollment anual activo.

### 6.3 Clubes, secciones y cargos

- CRUD operativo de clubes y secciones (`club_sections`);
- miembros por sección, asignación de cargos (`club_role_assignments`) y designación de director;
- solicitudes de membresía (`membership-requests`), transferencias y asignaciones de rol (`requests`, ver `runtime-requests.md`);
- inscripción anual de miembros (`annual-membership`) y continuidad anual de clubes (`club-enrollments`).

### 6.4 Formación, trayectoria y validación

- catálogo de clases, progreso por usuario y clase, prerequisitos y honores ligados a clases;
- honores, especialidades y honores maestros con requisitos;
- validación de progreso (`runtime-validation.md`) e investidura con pipeline multietapa (`investiture`);
- certificaciones configurables y su revisión (`runtime-user-certifications.md`);
- carga masiva de certificados con OCR asistido (`certificate-bulk-imports`; hoy Google Vision por API key, solo imágenes) y solicitudes de certificado institucional;
- logros (`runtime-achievements.md`) y miembro del mes (`runtime-member-of-month.md`).

Notas runtime activas:

- `GET/PATCH /users/:userId/classes/:classId/progress` operan sobre owner anual `enrollments.enrollment_id`;
- sin override, el backend resuelve una sola inscripción activa del año eclesiástico actual;
- si no existe inscripción resoluble devuelve `404`;
- si hay ambigüedad devuelve `409 CLASS_ENROLLMENT_AMBIGUOUS`;
- `GET /api/v1/admin/users/:userId` expone `current_operational_enrollment` como presente anual regular, `current_cross_type_enrollment` como cursado cruzado de GM investido, y `trajectory_classes` como histórico consolidado.

Notas runtime activas de carpetas anuales:

- El estado de cada sección de una carpeta anual vive en la columna `annual_folder_section_evaluations.status` del enum `annual_folder_section_status_enum` (`PENDING`, `SUBMITTED`, `PREAPPROVED_LF`, `VALIDATED`, `REJECTED`).
- Esa columna persistida es la **fuente única de verdad** del estado de la sección. Ningún consumidor — backend, admin o app — debe derivar el estado a partir de la presencia de filas de evaluación, timestamps LF/unión, o columnas de aprobación. La columna es el contrato.
- El flujo de revisión puede ser de **dos niveles** cuando la carpeta tiene `requires_union_confirmation = true`: LF pre-aprueba (`PREAPPROVED_LF`) y la unión confirma o hace override (`VALIDATED` | `REJECTED`). Cuando el flag es `false`, la aprobación LF transiciona directamente a `VALIDATED` y el servicio espeja columnas de unión con el actor LF para simetría de auditoría.
- El flag `requires_union_confirmation` se calcula en la creación del folder a partir de la vinculación con la carpeta de camporee y es históricamente inmutable.
- Los módulos consumidores del estado de la carpeta anual (scoring/rankings y la vinculación con camporees via `local_camporee_id` / `union_camporee_id`) leen el estado desde la columna `status`. Las filas terminales (`VALIDATED` o `REJECTED`) cuentan para decidir si el folder avanza a `evaluated`, pero sólo las filas `VALIDATED` contribuyen puntos al cálculo de totales; `REJECTED` aporta 0.
- Permisos vigentes: `evidence_folders:read/update` queda limitado a dirección/secretaría de club (`secretary`, `secretary-treasurer`, `deputy-director`, `director`); `member`, `counselor`, `instructor` y `treasurer` no leen/cargan esta carpeta. `annual_folders:submit` lo ejecuta `director`, `secretary` o `secretary-treasurer`; `assistant-lf` y `director-lf` supervisan/evalúan con lectura institucional y `annual_folders:evaluate`, pero no envían la carpeta completa en nombre del club.

### 6.5 Catálogos y administración

- catálogos públicos de geografía, tipos de club, tipos de relación, años eclesiásticos y roles;
- endpoints admin para geografía, catálogos de referencia y RBAC;
- 27 tablas `*_translations` para catálogos traducibles; los locales del sistema son `es` (base), `en`, `fr` y `pt-BR` en backend (`src/i18n`), admin (`messages/`) y app (`assets/translations/`);
- listado y detalle administrativo de usuarios por alcance territorial.

### 6.6 Operación de club, camporees y pagos

- actividades (incluidas conjuntas y recurrentes) y asistencia;
- finanzas con cierre de periodo, inventario, recursos y materiales;
- unidades y registros semanales de puntaje (`docs/features/weekly-records.md`);
- carpetas anuales de evidencias, evaluación LF/unión y rankings (`runtime-rankings.md`);
- camporees con inscripción de clubes, eventos, rúbricas y jueces, staff, sedes, pedidos e insumos (`runtime-camporees.md` y `docs/features/camporee-*.md`);
- órdenes de pago territoriales, obligaciones de pago y seguros.

### 6.7 Reportes, cierre de año y operación

- informes mensuales (con PDF en R2), trimestrales y anuales, generados por cron;
- cierre y corte de año (`year-end`, `year-cut`);
- notificaciones push y bandeja (`runtime-communications.md`), invalidación de cache por FCM silencioso (`runtime-resiliencia-red.md`);
- dashboards de SLA (`runtime-sla-dashboard.md`), operaciones y campo local en `analytics`;
- exportación de datos personales (`data-export`) y borrado de cuenta (`DELETE /auth/me`);
- auditoría HTTP global (`audit-logs`).

### 6.8 Trabajo en segundo plano

- Colas BullMQ: `emails`, `notifications`, `achievements`, `background-jobs`, `master-honors` y `certificate-import-ocr`.
- 15 jobs `@Cron` en el backend (informes, miembro del mes, rankings, recordatorios, limpieza, corte de año, entre otros).
- Sin Redis, los trabajos HTTP que encolan recálculos corren inline en desarrollo; en producción Redis es obligatorio.

---

## 7. Autorización runtime

### 7.1 Modelo

Detalle conceptual en `docs/canon/auth/modelo-autorizacion.md`. Guards globales registrados en `AppModule` (`APP_GUARD`), en este orden: `UserAwareThrottlerGuard`, `GlobalJwtAuthGuard`, `PermissionsGuard`.

`PermissionsGuard` es **deny-by-default**: cada handler debe declarar `@Public()`, `@SkipPermissions()` o `@RequirePermissions(...)` con su recurso de autorización; si falta, responde error de configuración RBAC. Además existen `GlobalRolesGuard` (`@GlobalRoles(...)`), `OwnerOrAdminGuard`, `ClubRolesGuard` y `MfaGuard`.

### 7.2 Estructuras y roles

- **roles globales** en `users_roles`;
- **roles de club** en `club_role_assignments` (por `club_section_id` y año eclesiástico);
- **catálogo de permisos** en `permissions` y relación en `role_permissions`;
- permisos directos en `users_permissions`.

Roles globales del seed (`prisma/seeds/role-permissions.seed.sql`):

- plataforma: `super-admin`, `admin`, `assistant-admin`, `user`;
- territorio: `director-dia`, `assistant-dia`, `director-union`, `assistant-union`, `director-lf`, `assistant-lf`, `pastor`;
- coordinación: `coordinator`, `general-coordinator`, `zone-coordinator`.

Roles de club del seed: `director`, `deputy-director`, `secretary`, `treasurer`, `secretary-treasurer`, `counselor`, `instructor`, `member`.

El contexto de autorización resuelto (`AuthorizationContextService`) se cachea en Redis con la key `auth:context:v7:{userId}` (TTL 5 min). Toda mutación de roles o permisos debe invalidar el cache de los usuarios afectados, tanto por `users_roles` como por `club_role_assignments`.

### 7.3 Autorización sensible

Las superficies sensibles del usuario (`health`, `emergency_contacts`, `legal_representative`, `post_registration`) se resuelven por owner o contexto sobre `userId`, con compatibilidad transicional con permisos `users:*`.

### 7.4 Política read-wider-than-write en `annual_folders:evaluate`

El módulo de evaluación de carpetas anuales aplica una política deliberada de lectura más amplia que escritura sobre el permiso `annual_folders:evaluate`:

- **Operaciones de escritura** (`POST .../evaluate`, `POST .../confirm-union`, `POST .../reopen`, `PATCH evidences/:evidenceId/reviewer-note`) requieren el permiso con `type: 'global'`. Solo actores LF y de unión con alcance global pueden mutar el estado de evaluación.
- **Operación de lectura** (`GET /annual-folders/:folderId/evaluations`) acepta `annual_folders:evaluate` o `evidence_folders:read`, pero el servicio vuelve a validar el recurso real: el usuario debe tener el permiso en el club dueño de la carpeta, o ser actor institucional con permiso global y territorio LF/Unión coincidente.

Esta asimetría es intencional: los usuarios club-scoped ven el estado de sus propias carpetas, mientras que la mutación queda restringida a actores LF y de unión. IMPORTANTE: una asignación/permisos en otro club no habilita lectura ni envío sobre la carpeta de este club; el chequeo final vive en `AnnualFoldersService`.

---

## 8. Persistencia

### 8.1 Fuente estructural

La autoridad estructural es **`sacdia-backend/prisma/schema.prisma`**. `docs/database/schema.prisma` y `docs/database/SCHEMA-REFERENCE.md` son material documental subordinado; si difieren, gana el schema del backend.

### 8.2 Rasgos

- PostgreSQL en Neon (`DATABASE_URL` con pooler; `DATABASE_DIRECT_URL` opcional para migraciones);
- Prisma Migrate (`prisma/migrations/`); en Render se aplica con `preDeployCommand: pnpm prisma migrate deploy`, nunca con `db push`;
- **248** modelos y **75** enums en el schema (recuento 2026-10-04);
- `active` como patrón frecuente de soft delete; timestamps automáticos;
- PKs con nombres propios por tabla (`user_id`, `club_section_id`, `user_pr_id`, `enrollment_id`…), no un `id` genérico, salvo en las tablas de Better Auth.

### 8.3 Grupos de modelos (no exhaustivo)

- **Identidad y Better Auth**: `users`, `users_pr`, `account`, `session`, `verification`, `legal_representatives`, `emergency_contacts`, `user_fcm_tokens`.
- **Organización**: `countries`, `unions`, `local_fields`, `districts`, `churches`, `ecclesiastical_years`, `coordination_zones`, `coordinator_assignments`.
- **Clubes**: `clubs`, `club_sections`, `club_role_assignments`, `units`, `weekly_records`.
- **Formación**: `classes`, `enrollments`, `honors`, `users_honors`, `master_honors`, `certifications` y `certification_versions`, `investiture_validation_history`.
- **Operación**: `activities`, `finances`, `club_inventory`, `annual_folders` y evaluaciones, `camporees` y `camporee_*`, `field_payment_orders`, `insurance_*`.
- **Comunicación y operación técnica**: `notification_logs`, `notification_deliveries`, `notification_preferences`, `audit_logs`, `data_export_requests`.
- **RBAC**: `roles`, `permissions`, `role_permissions`, `users_roles`, `users_permissions`.
- **Traducciones**: 27 tablas `*_translations`.
- **Legacy**: `folders*` (sin controller).

### 8.5 Lectura canónica de estructuras clave

#### Miembro y post-registro

- `users` conserva identidad operativa del usuario/miembro;
- `users_pr` conserva tracking granular de post-registro siguiendo `schema.prisma`: PK técnico `user_pr_id` y `user_id` único como vínculo al miembro;
- `legal_representatives` soporta representante legal;
- `emergency_contacts` soporta contactos de emergencia.

#### Club y sección

- `clubs` representa la raíz institucional;
- `club_sections` representa la realización técnica consolidada de secciones por tipo (reemplaza las antiguas tablas por tipo desde 2026-03-17);
- `club_role_assignments` expresa asignación contextual de cargo con año eclesiástico vía `club_section_id`.

#### Formación

- `classes` define catálogo de clases;
- `enrollments` define ciclo anual operativo y trayectoria histórica consultable por año eclesiástico/estado.

#### Autoridad y jerarquía

- `countries`, `unions`, `local_fields`, `districts` y `churches` materializan la cadena jerárquica documentada;
- `roles`, `permissions`, `role_permissions` y `users_roles` materializan RBAC global;
- `club_role_assignments` materializa responsabilidad contextual en club/sección y periodo.

---

## 9. Integraciones externas

| Servicio | Uso | Configuración |
|---|---|---|
| Neon (PostgreSQL) | Base de datos | `DATABASE_URL`, `DATABASE_DIRECT_URL` |
| Better Auth | Autenticación self-hosted dentro del backend | `BETTER_AUTH_SECRET`, `BETTER_AUTH_BASE_URL` |
| Google / Apple OAuth | Login social | `GOOGLE_CLIENT_*`, `APPLE_*`, `ALLOWED_OAUTH_REDIRECT_URLS` |
| Redis (Upstash recomendado) | Cache, BullMQ, rate limiting, blacklist JWT | `REDIS_URL` |
| Cloudflare R2 | Archivos (buckets por alias, URLs firmadas) | `R2_*`; convenciones en `docs/storage/r2-keyprefix-conventions.md` |
| Firebase Cloud Messaging | Push y mensajes silenciosos | `FIREBASE_*` |
| Resend | Correo transaccional | `EMAIL_ENABLED`, `RESEND_*` |
| Google Cloud Vision | OCR de certificados (imágenes) | `GOOGLE_VISION_API_KEY` (opcional) |
| Sentry | Errores en backend, admin y app | `SENTRY_DSN`; release por `RENDER_GIT_COMMIT` / `VERCEL_GIT_COMMIT_SHA` |
| PostHog | Analítica de producto en admin y app | `posthog-js`, `posthog_flutter` |
| Google Maps / Nominatim | Mapas y búsqueda de ubicación en la app | `GOOGLE_MAPS_API_KEY` (app) |
| Render / Vercel | Hosting de backend / admin | `render.yaml` / proyecto Vercel |

Detalle operativo de infraestructura (logging, rate limiting, seguridad global) en `docs/features/infrastructure.md`.

---

## 10. Resumen

- SACDIA opera como backend REST (NestJS, Render) + admin web (Next.js, Vercel) + app móvil (Flutter) sobre PostgreSQL en Neon;
- la autenticación es Better Auth + JWT HS256 propio; la autorización combina permisos globales, asignaciones de club y alcance territorial, con guard global deny-by-default;
- la operación anual formativa y la trayectoria se leen desde `enrollments`;
- el producto aún no está en producción; las ramas son `development` → `preproduction` → `main`.

---

## 11. Límites de este documento

- No reemplaza a `ENDPOINTS-LIVE-REFERENCE.md` para el contrato por endpoint ni al schema para la estructura de datos.
- No describe como vigente trabajo que vive fuera de `development` (por ejemplo, el PR #448 de sacdia-backend).
- No usa `docs/history/` como fuente.

---

## 12. Mantenimiento

Cuando cambie el runtime:

1. actualizar el canon o feature específico del área;
2. regenerar o corregir `docs/api/ENDPOINTS-LIVE-REFERENCE.md` si cambian endpoints;
3. actualizar este documento si cambia el stack, la topología, los roles o las cifras.

Recuento de cifras (desde `sacdia-backend/`):

```bash
find src -name "*.controller.ts" | wc -l                                         # controllers
grep -rE "^\s*@(Get|Post|Put|Patch|Delete)\(" src --include=*.controller.ts | wc -l  # handlers HTTP
grep -c "^model " prisma/schema.prisma                                           # modelos
grep -c "^enum " prisma/schema.prisma                                            # enums
```
