# Ambiente nuevo: configuración y carga de datos por capas

**Estado**: ACTIVE (análisis 2026-10-13 sobre `development`)
**Alcance**: `sacdia-backend` + `sacdia-admin` + schema Prisma. La app móvil consume lo mismo; no agrega configuración propia.

Esta guía responde dos preguntas:

1. Qué hay que hacer para levantar un ambiente limpio (infra, variables, migraciones, seeds, primer super-admin).
2. Qué datos tienen que existir, en qué orden y quién los carga, organizados en capas según si bloquean o no el sistema.

Al final hay un inventario de huecos del panel admin detectados durante el análisis.

> [!IMPORTANT]
> Fuentes verificadas en código: `sacdia-backend/prisma/seed.ts`, `prisma/seeds/README.md`, `prisma/seeds/*.sql|*.ts`, los `INSERT` dentro de `prisma/migrations/**`, `src/config/env.validation.ts`, `src/rbac/rbac.service.ts` (`bootstrapAdmin`), `src/common/guards/permissions.guard.ts`, y el screen catalog del admin (`sacdia-admin/src/lib/auth/screen-catalog/`). Cuando algo no se verificó se dice explícitamente.

---

## Parte 1. Levantar el ambiente

### 1.1 Infraestructura externa

| Servicio | Obligatorio | Para qué | Nota |
|---|---|---|---|
| PostgreSQL (Neon) | Sí | Base de datos | Una rama Neon por ambiente. Pooled URL para la app, direct URL para migraciones |
| Redis | Sí en producción. En dev hay fallback a memoria | Cache de catálogos, contexto de autorización, BullMQ, locks distribuidos, throttling | Sin Redis no corren los workers de colas (emails, notificaciones, logros, OCR, master-honors). Data export responde 503 |
| Cloudflare R2 | Sí | Archivos | Joi exige bucket + URL pública para `HONORS_PDF`, `EVIDENCE_FILES`, `INSURANCE_EVIDENCE`, `DATA_EXPORTS`, `MONTHLY_REPORTS`, `RESOURCES_FILES`. Los demás buckets son opcionales pero las features que los usan fallan sin ellos |
| Resend | Solo si `EMAIL_ENABLED=true` | Correo transaccional (invitaciones, reset, investidura) | La invitación de usuario nuevo desde el admin manda un correo de reset; sin email el usuario no recibe contraseña |
| Firebase FCM | No | Push | Sin credenciales, push se omite |
| Google OAuth / Apple | No | Login social | Sin ellos, solo credenciales |
| Sentry, PostHog | No | Observabilidad | |
| Google Vision / OCR proxy | Solo producción (`OCR_MODE` obligatorio) | OCR de certificados | En dev el default es `direct` con ADC |

### 1.2 Variables de entorno del backend

Fuente de verdad: `sacdia-backend/.env.example`. Validación: `src/config/env.validation.ts`.

**Siempre obligatorias**

- `DATABASE_URL` (pooled) y `DATABASE_DIRECT_URL` (migraciones).
- `BETTER_AUTH_SECRET` (32+ chars). `QR_JWT_SECRET` (32+ chars, distinto del anterior).
- Pares `R2_BUCKET_*` + `R2_PUBLIC_URL_*` para los seis buckets listados arriba, más `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`.

**Obligatorias solo en producción**

- `ALLOWED_ORIGINS` (el boot falla sin ella).
- `REDIS_URL` (fail-fast si no conecta).
- `OCR_MODE` (`direct` | `remote`). Con `remote` también `OCR_PROXY_URL`, `OCR_PROXY_ENV`, `OCR_PROXY_KID`, `OCR_PROXY_SECRET`.
- `SWAGGER_ENABLED` debe ser `false` (el schema rechaza `true`).

**Condicionales**

- `EMAIL_ENABLED=true` exige `RESEND_API_KEY`, `RESEND_FROM_EMAIL` y `REDIS_URL`.
- `INVESTITURE_EMAIL_ENABLED=true` exige `ADMIN_PANEL_URL`.
- `BOOTSTRAP_SECRET` (32+ chars). Opcional, pero sin ella el endpoint de bootstrap del primer super-admin está deshabilitado. Retirarla después de usarla.

### 1.3 Variables de entorno del admin

No hay `.env.example` en el repo; existe `.env.local.example`. Variables leídas por el código:

- `NEXT_PUBLIC_API_URL` (obligatoria; URL del backend).
- `NEXT_PUBLIC_APP_URL`.
- `NEXT_PUBLIC_GOOGLE_MAPS_API_KEY` y opcional `NEXT_PUBLIC_GOOGLE_MAPS_MAP_ID` (el selector de ubicación de clubes no funciona sin la key; `clubs.coordinates` es NOT NULL).
- `NEXT_PUBLIC_SENTRY_DSN`, `SENTRY_RELEASE`, `NEXT_PUBLIC_POSTHOG_PROJECT_TOKEN`, `NEXT_PUBLIC_POSTHOG_HOST`, `NEXT_PUBLIC_RBAC_LEGACY_FALLBACK` (opcionales).

### 1.4 Secuencia de arranque

```bash
# 0. Infra
docker compose up -d redis            # solo dev local

# 1. Backend
cd sacdia-backend
pnpm install
cp .env.example .env                  # completar valores
pnpm prisma migrate deploy            # crea 300+ tablas y aplica los INSERT de la Capa 0

# 2. Seeds obligatorios (orden estricto, ver prisma/seeds/README.md)
npx tsx prisma/seed.ts                                       # roles, club_types, countries, relationship_types, ranking_tiers, admin@sacdia.com
psql "$DATABASE_DIRECT_URL" -f prisma/seeds/permissions.seed.sql
psql "$DATABASE_DIRECT_URL" -f prisma/seeds/role-permissions.seed.sql

# 3. Seeds recomendados
psql "$DATABASE_DIRECT_URL" -f prisma/seeds/system-config.seed.sql
psql "$DATABASE_DIRECT_URL" -f prisma/seeds/role-slot-limits.seed.sql

# 4. Arrancar
pnpm run start:dev

# 5. Admin
cd ../sacdia-admin && pnpm install && cp .env.local.example .env.local && pnpm dev
```

> [!WARNING]
> `prisma/seed.ts` crea `admin@sacdia.com` con contraseña fija (`Sacdia2026!`) y rol `super-admin`, más un usuario de prueba `testuser.gm@sacdia.test`, una clase `Guía Mayor - Nivel 1 (Seed)` y un año eclesiástico 2026 si no existe `year_id = 1`. Para producción: cambiar la contraseña al primer login o borrar ese bloque y usar el bootstrap del punto 1.5. Borrar el usuario y la clase de prueba.

> [!NOTE]
> `prisma/seeds/core.ts` (`pnpm prisma:seed:core`) es un seed **operativo de desarrollo** (60 miembros, unidades, inscripciones del club "ACV"). Se niega a correr fuera de la rama Neon de desarrollo salvo `SACDIA_CORE_SEED_ALLOW_ANY_DB=1`. Requiere que ya existan el club ACV con secciones, clases activas y un año activo. No es parte del arranque de producción.

### 1.5 Primer super-admin sin usar el seed

`POST /api/v1/admin/rbac/bootstrap-admin` con header `x-bootstrap-secret: $BOOTSTRAP_SECRET` y body `{ "user_id": "<uuid>" }`.

Qué hace y qué no:

- Solo inserta una fila en `users_roles` ligando un usuario **ya existente** al rol `super-admin` **ya existente**.
- No crea roles, permisos ni usuarios. Los seeds del paso 2 siguen siendo obligatorios.
- Falla con 409 si ya hay un super-admin activo, 404 si el usuario o el rol no existen, 403 si falta el secret.
- Flujo real: registrar el usuario por `/api/v1/auth/register` (requiere rol `user` sembrado), poner `users.access_panel = true` por SQL (el default es `false`), llamar al bootstrap, invalidar cache de autorización o esperar 5 minutos.

### 1.6 Trampas de arranque conocidas

- **PermissionsGuard fail-closed sin bypass de super-admin.** Con `permissions` o `role_permissions` vacías, TODO endpoint protegido devuelve 403, incluso para super-admin. Por eso el orden de seeds es estricto.
- **Cache de autorización 5 min** (`auth:context:v7:{userId}`). Después de sembrar roles o permisos, o se invalida (`POST /api/v1/admin/catalogs/cache/invalidate` para catálogos; para usuario, re-login o flush de Redis) o se espera.
- **Año eclesiástico "actual" cacheado 24 h.** Si se consultó cuando no había año, el null queda cacheado. Flush de Redis después de crear el primer año.
- **`local_fields.timezone` debe ser IANA válido.** Ventanas de investidura y umbrales de clase responden 503 `LOCAL_FIELD_TIMEZONE_UNAVAILABLE` si es null o inválido. El formulario de campo local no lo pide; hay un script `pnpm backfill:local-field-timezones`.
- **Defaults `active = false`** en `countries`, `unions`, `local_fields`, `districts`, `clubs`, `club_sections`, `club_types`, `ecclesiastical_years`, `honors_categories`, `master_honors`, `finances_categories`, `inventory_categories`, `folder_templates`. Lo que se inserte por SQL sin `active = true` queda invisible.
- **Columna `districlub_type_id`** es la PK/FK real de distritos (nombre heredado). No es un typo a corregir en seeds.
- **Las migraciones `INSERT INTO permissions`** (materiales, auditoría, instructor) dependen de que `roles` exista para los grants. En base fresca, `migrate deploy` corre antes que `seed.ts`, así que esos grants son no-op y los cubre `role-permissions.seed.sql` (verificado: incluye `materiales:*` y `audit:read`).

---

## Parte 2. Capas de datos

Criterio de clasificación:

| Capa | Definición | Quién la carga |
|---|---|---|
| **0 · Migraciones** | Filas que `migrate deploy` inserta solo. No requieren acción | Automático |
| **1 · Primera necesidad** | Sin esto el sistema no arranca funcionalmente: login, autorización, registro, estructura mínima | Equipo técnico, una vez |
| **2 · Intermedios** | Catálogos de dominio. Si faltan, módulos concretos quedan vacíos o lanzan 404, pero el resto funciona | Equipo técnico + super-admin/admin |
| **3 · Campo local / Unión / División** | Configuración territorial. Cada entidad la hace para sí misma. Sin ella, features de esa entidad quedan bloqueadas | director-lf, director-union, director-dia (y admin) |
| **4 · Usuario (club / persona)** | Datos operativos que el club o la persona crean al usar el sistema | director de club, miembros |

### Capa 0 · Lo que trae `migrate deploy`

Filas insertadas por migraciones (idempotentes con `ON CONFLICT`). No tocar, pero saber que existen:

| Tabla | Contenido | Migración |
|---|---|---|
| `divisions` | `DIA` / División Interamericana (`division_id = 1`, `code = 'DIA'`) | `20260527120000` |
| `scoring_categories` | Asistencia y Puntualidad (nivel DIVISION, `origin_id = 0`) | `20260409100000` |
| `ranking_weight_configs` | Default global 60/15/15/10 (`club_type_id = NULL`) | `20260428000100` |
| `enrollment_ranking_weights` | Default global 50/30/20 `is_default = true` | `20260429000002` |
| `award_categories` | AAA / AA / A (scope `member`) + categorías club | `20260429000003`, `20260501000000` |
| `system_config` | `ranking.finance_closing_deadline_day`, `ranking.recalculation_enabled`, `scoring.category_max_points_cap`, y otras | varias |
| `camporee_event_types` | `general` + otros | `20260520225303`, `20260521120000` |
| `material_categories` | Uniforme, Pañoletas, Libros, Distintivos, Insignias… | `20260514140000` |
| `role_slot_limits` | director 1, deputy-director 2, secretary 1, treasurer 1, secretary-treasurer 1 | `20260529195800` (no-op si `roles` vacío; por eso existe el SQL en seeds) |
| `roles` | `instructor` | `20260506100000` |
| `permissions` | `materiales:*`, `audit:read`, etc. | varias |

**Dependencias que esto resuelve**: la división `DIA` es obligatoria para `scoring_categories` de nivel división (`SCORING_DIVISION_NOT_FOUND` si falta) y es el default de `unions.division_id`. El peso default de `enrollment_ranking_weights` es obligatorio para rankings de miembros (`RANKING_WEIGHTS_DEFAULT_NOT_FOUND`).

### Capa 1 · Primera necesidad

Sin esto no hay login útil, ni registro, ni autorización.

| # | Tabla | Qué cargar | Fuente hoy | Qué rompe si falta |
|---|---|---|---|---|
| 1.1 | `roles` | 14 GLOBAL (`super-admin`, `admin`, `assistant-admin`, `coordinator`, `zone-coordinator`, `general-coordinator`, `director-lf`, `assistant-lf`, `director-union`, `assistant-union`, `director-dia`, `assistant-dia`, `pastor`, `user`) + 8 CLUB (`director`, `deputy-director`, `secretary`, `treasurer`, `secretary-treasurer`, `counselor`, `instructor`, `member`) | `prisma/seed.ts` | Registro lanza `AUTH_USER_ROLE_NOT_FOUND` sin `user`. Post-registro lanza `POST_REG_MEMBER_ROLE_NOT_FOUND` sin `member`. Designar director falla sin `director`. Bootstrap falla sin `super-admin` |
| 1.2 | `permissions` | ~124 nombres `recurso:accion` usados por `@RequirePermissions` | `permissions.seed.sql` | 403 global, incluso super-admin |
| 1.3 | `role_permissions` | Matriz rol → permiso | `role-permissions.seed.sql` (INSERT…SELECT, depende de 1.1) | 403 global |
| 1.4 | `users` + `account` + `users_roles` | Primer super-admin con `access_panel = true` | `seed.ts` o bootstrap (1.5) | Nadie entra al admin |
| 1.5 | `club_types` | `Aventureros`, `Conquistadores`, `Guías Mayores` (nombres exactos, con acento) | `seed.ts` | Crear club falla si el catálogo está vacío. Progresión de clases, elegibilidad de roles de club e investidura GM comparan por nombre literal |
| 1.6 | `ecclesiastical_years` | Un año que cubra la fecha de hoy, sin solapes, con `active = true` | **Nadie lo siembra bien.** `seed.ts` crea uno 2026 solo si no hay `year_id = 1`. UI: `/dashboard/catalogs/ecclesiastical-years` (solo super-admin crea) | Post-registro paso 3 (`POST_REG_NO_ACTIVE_YEAR`), creación de club (`CLUB_NO_ACTIVE_YEAR`), inscripciones anuales (`CE_NO_ACTIVE_YEAR`), clases, investidura, perfil de auth. Solapes dan 409 `ECCLESIASTICAL_YEAR_AMBIGUOUS` |
| 1.7 | `countries` | Al menos el país del territorio | `seed.ts` (8 países, `active = true`) | Post-registro escribe `users.country_id`; crear unión exige país |
| 1.8 | `divisions` | `DIA` | Capa 0 | Ver Capa 0 |
| 1.9 | `unions` → `local_fields` → `districts` → `churches` | La cadena territorial mínima del ambiente | **Solo UI** (`/dashboard/catalogs/*`, roles admin/super-admin) o `pnpm import:legacy-catalogs` desde respaldos SQL | Post-registro escribe `users.union_id` y `local_field_id`. Crear club exige campo, distrito e iglesia. Autorización territorial resuelve `clubs → local_fields → unions → divisions` por JOIN; cadena rota = `canManageClub` false |
| 1.10 | `relationship_types` | Padre, Madre, Tutor Legal, etc. | `seed.ts` | Contactos de emergencia y QR sin tipo de relación |
| 1.11 | `ranking_tiers` | Diamante, Oro, Plata, Bronce | `seed.ts` | Rankings anuales sin rangos (no rompe, pero queda vacío) |

**Hay dos nociones de "año actual" y deben coincidir.** El flag `active` (lo edita el catálogo; lo usan ventanas de investidura, camporees, rankings anuales) y el "current" por fechas `start_date <= hoy <= end_date` (lo usan creación de club, post-registro, inscripciones). Nada en la UI avisa si no coinciden. Regla práctica: un solo año cubre hoy y es el único `active`.

### Capa 2 · Intermedios (catálogos de dominio)

El sistema arranca sin ellos. Cada módulo concreto queda vacío o lanza 404 hasta que se cargan. Casi todos tienen CRUD en el admin bajo **Administración → Catálogos**, pero el volumen real (clases, especialidades) viene de importadores.

| Tabla | Para qué | Fuente hoy | Qué pasa si falta | UI admin |
|---|---|---|---|---|
| `classes` | Trayectoria formativa (Amigo…Guía, Aventureros, GM). `active` sin default: obligatorio enviarlo | **Solo** `pnpm import:legacy-catalogs` (respaldos SQL fuera del repo) o alta manual. `seed.ts` solo crea una clase GM de prueba | Post-registro paso 3 no resuelve clase. `core.ts` lanza "No active classes found" | `/dashboard/catalogs/classes` CRUD + prerequisitos |
| `class_modules`, `class_sections` | Requisitos por clase | `docs/working/seed-{conquistadores,aventureros,guia-mayor}-modules-sections.sql` (hardcodean `class_id` 7-12: dependen del orden de inserción de clases) | Progreso de clase vacío, investidura sin requisitos | `/dashboard/catalogs/class-modules`, `/class-sections` |
| `honors_categories`, `honors`, `honor_club_types`, `honor_requirements` | Especialidades | `import:legacy-catalogs` + `prisma/seeds/honor-requirements.seed.ts` (lee `docs/working/honors-especialidades/`) + `scripts/import-adventurer-specialties.ts` | Módulo de especialidades vacío | Categorías y especialidades CRUD. **Requisitos sin UI** |
| `master_honors` + reglas | Maestrías | `import:legacy-catalogs` + `pnpm import:master-honor-rules -- --file` | Maestrías vacías | `/dashboard/catalogs/master-honors` |
| `certifications` + versiones/módulos | Certificaciones GM | `prisma/seeds/certifications/basic-pathfinder-staff-training.seed.ts` (también lo ejecuta `core.ts`) | Módulo vacío | `/dashboard/catalogs/certifications` CRUD; la versión nace `DRAFT` y hay que publicarla |
| `achievement_categories`, `achievements` | Logros | `prisma/seeds/achievements.seed.ts` | Sin logros | `/dashboard/configuration/achievements` CRUD |
| `finances_categories`, `inventory_categories`, `resource_categories`, `activity_types`, `club_ideals`, `allergies`, `diseases`, `medicines` | Catálogos de referencia | `import:legacy-catalogs` (parcial), `inventory-categories.sql`, resto manual | Formularios con combos vacíos | CRUD en Catálogos |
| `system_config` | Parámetros operativos | `system-config.seed.sql` (5 llaves) + Capa 0 | Ninguna llave es obligatoria: todas tienen default en código. Pero `/dashboard/configuration/variables` es **solo edición**: una llave no sembrada no se puede crear desde la UI | `/dashboard/configuration/variables` |
| `role_slot_limits` | Cupos por rol de club | `role-slot-limits.seed.sql` | Fallback canónico en código (`clubs.service.ts`) | **Sin UI** |
| `MaterialCategory` | Categorías de materiales | Capa 0 | — | `/dashboard/materials/categories` |
| `camporee_event_types` | Tipos de evento | Capa 0 | — | `/dashboard/catalogs/camporee-event-types` |
| `notification` categorías | Lista fija de 9 en código | — | — | Solo toggles en `/configuration/notifications/categories` |

Llaves `system_config` leídas en runtime y su default si faltan (todas opcionales):

| Llave | Default en código | Sembrada |
|---|---|---|
| `investiture.min_approval_percentage` | 80 | Sí |
| `reports.auto_generate_enabled` | OFF (solo `'true'` activa) | Sí (`true`) |
| `reports.auto_generate_day` | 5 | Sí |
| `scoring.category_max_points_cap` | 20 | Sí (seed + migración) |
| `investiture.min_monthly_reports` | **sin lectura en `src/`** | Sí (llave muerta) |
| `membership.pending_timeout_days` | 8 | No |
| `ranking.finance_closing_deadline_day` | 5 | Migración |
| `ranking.recalculation_enabled` | ON | Migración |
| `ranking.activities_registered_target` | 12 | No |
| `member_ranking.recalculation_enabled` | ON | No |
| `member_ranking.member_visibility` | `self_only` | No |
| `member_ranking.top_n` | 5 | No |
| `reports.annual_auto_generate_enabled` | OFF | No |
| `reports.quarterly_auto_generate_enabled` | OFF | No |
| `reports.reminders_enabled` | ON | No |
| `activity_reminder_minutes_before` | 60 | No |
| `field_payment_orders_v1` | OFF para todos (JSON array de `local_field_id`) | No |
| `camporee_orders.expiry_days` | constante | No |

Recomendación: ampliar `system-config.seed.sql` para sembrar TODAS las llaves con su default, aunque sea redundante. Hoy la mitad de los parámetros no se pueden ajustar desde el admin porque la fila no existe.

### Capa 3 · Configuración territorial (Campo local / Unión / División)

Cada territorio la hace para sí. Sin ella, las features de ese territorio quedan bloqueadas o en default, pero el resto del sistema sigue.

**Orden sugerido para un campo local nuevo:**

| # | Qué | Tabla | Quién | Dónde en el admin | Si falta |
|---|---|---|---|---|---|
| 3.1 | Usuarios administrativos del campo (`director-lf`, `assistant-lf`) con `local_field_id` y `union_id` correctos | `users`, `users_roles` | admin / director-union | `/dashboard/users/new` | El director-lf sin `local_field_id` cae a scope `all` en la UI pero el backend devuelve 403/vacío. **Y no se puede corregir después desde la UI** |
| 3.2 | Distritos e iglesias del campo | `districts`, `churches` | admin / super-admin (director-lf **no puede**) | Catálogos → Geografía | No se pueden crear clubes |
| 3.3 | Timezone del campo | `local_fields.timezone` | técnico (script) | **Sin UI** | 503 en ventanas de investidura y umbrales |
| 3.4 | Zonas de coordinación y coordinadores | `coordination_zones`, `coordinator_assignments` | director-lf | `/dashboard/coordination` | Sin supervisión zonal; no bloquea |
| 3.5 | Ventana de investidura y porcentaje mínimo del año | `local_field_investiture_windows`, `local_field_class_thresholds` | director-lf / assistant-lf (requiere año `active` y hoy dentro del año) | `/dashboard/investiture-settings` | Sin ventana → `investitureWindowAllowsOperation` false → **investidura bloqueada**. Sin umbral → 80 % |
| 3.6 | Pastores por distrito | `district_investiture_pastors` | director-lf / assistant-lf | `/dashboard/investiture-pastors` | Nadie autoriza investiduras en ese distrito |
| 3.7 | Cupo global de pastores | `investiture_pastor_quota` (singleton) | super-admin | misma pantalla | Default 2 |
| 3.8 | Productos y ciclos de seguro | `insurance_products`, `insurance_cycle_configs` | **solo** director-lf / assistant-lf (super-admin y admin reciben 403) | `/dashboard/insurance/config` | Compra de seguros 404 `INSURANCE_CYCLE_CONFIG_NOT_FOUND` |
| 3.9 | Instrucciones de pago del campo | `field_payment_order_configs` (1 por campo) | director-lf | `/dashboard/insurance/config` pestaña pago | Pedidos de camporee 422 `CAMPOREE_ORDER_PAYMENT_CONFIG_REQUIRED`; PDF 404. Además el feature flag `field_payment_orders_v1` en `system_config` debe listar el campo |
| 3.10 | Datos bancarios y entrega de materiales | `MaterialConfig` (1 por campo) | director-lf (`materials:configure`) | `/dashboard/configuration/local-field/payment-methods` y `/delivery` | Envío cae a 0; GET devuelve placeholder. No bloquea |
| 3.11 | Catálogo de materiales del campo | `MaterialProduct` | director-lf (`materials:manage_inventory`) | `/dashboard/materials/inventory` | Sin pedidos de materiales |
| 3.12 | Plantilla de carpeta anual (por tipo de club × año, dueño unión **o** campo) | `folder_templates` + secciones | director-union o director-lf | `/dashboard/clubs/evidence-folders/templates` → publicar | 404 `ANNUAL_FOLDER_TEMPLATE_NO_MATCH`; la auto-creación de carpeta al inscribir falla silenciosamente (log) |
| 3.13 | Configuración de ranking anual (máximo, ejes, componentes) por año × tipo de club. Unión tiene precedencia sobre campo | `annual_ranking_configs` + hijos | director-union o director-lf | `/dashboard/annual-folders/ranking-config` | Sin ranking anual para ese territorio. La plantilla 3.12 solo se puede publicar si su suma de puntos coincide con el componente `annual_evidence_folder` de esta config |
| 3.14 | Categorías de scoring de unión / campo | `scoring_categories` (origin UNION / LOCAL_FIELD) | director-union / director-lf | **Sin UI montada** (los componentes existen, no están conectados). Solo DIVISION en `/dashboard/settings/scoring-categories` | Se usan las de división |
| 3.15 | Plantillas de eventos y sedes de camporee | `camporee_event_templates`, `camporee_venues` | director-lf / director-union | `/dashboard/campamentos/plantillas`, dentro del camporee | Sin eventos predefinidos |
| 3.16 | Catálogo de productos para pedidos de camporee | `camporee_order_products` (scope DIVISION/UNION/LOCAL_FIELD) | según scope | `/dashboard/campamentos/pedidos/catalogo` | Sin pedidos |
| 3.17 | Camporee local / de unión del año | `local_camporees`, `union_camporees` | director-lf / director-union | `/dashboard/campamentos`, `/union` | Requiere año `active` (`CAMPOREE_YEAR_NOT_ACTIVE`) |

Lo que **no** necesita acción (se autogenera): `*_folio_counters`, `MaterialFolioCounter`, `hierarchy_contexts`, `institutional_name_versions`, `*_history`.

**Nivel Unión / División específicamente:**

- División: hoy solo `DIA`. Sin pantalla de "configuración de división" más allá de scoring DIVISION y catálogos globales.
- Unión: `annual_ranking_configs` y `folder_templates` con dueño unión aplican a todos sus campos (precedencia sobre campo). Camporees de unión. Usuarios `director-union` se crean igual que los de campo, con `union_id` y sin `local_field_id`.

### Capa 4 · Usuario (club y persona)

Datos operativos. Los crea el club o la persona al usar el sistema. Se listan para que el guion de onboarding sea completo.

| # | Qué | Tabla | Quién | Dónde | Dependencias |
|---|---|---|---|---|---|
| 4.1 | Club con sus secciones | `clubs`, `club_sections` | admin o director-lf | `/dashboard/clubs/new` o `/clubs/import` | Campo, distrito, iglesia, `club_types`, año actual por fechas, Google Maps (coordenadas NOT NULL). Se crea una `club_sections` por cada tipo activo; GM forzado |
| 4.2 | Inscripción anual del club | `club_enrollments` (1 por sección × año) | director de club (app) | **Sin UI admin.** Endpoint `POST /clubs/:c/sections/:s/enrollments` | Año actual. Define directiva, cuota, horario |
| 4.3 | Directiva del club | `club_role_assignments` | director-lf aprueba / app | `/dashboard/requests/assignments` | Roles CLUB, `role_slot_limits` |
| 4.4 | Registro de persona + post-registro (país, unión, campo, club, clase) | `users`, `users_pr`, `club_role_assignments`, `enrollments` | la persona (app) | app móvil; admin aprueba membresía en `/dashboard/requests/membership` | Capa 1 completa, `classes` activas para el tipo de club, `club_sections` activa |
| 4.5 | Unidades y miembros | `units`, `unit_members` | director / consejero (app) | app | Sección con miembros |
| 4.6 | Actividades, finanzas, inventario, reportes mensuales, evidencias, especialidades, carpeta anual | tablas operativas | club | app + admin de supervisión | Catálogos de Capa 2 y config de Capa 3 |
| 4.7 | Contactos de emergencia, salud, representantes legales | `emergency_contacts`, `users_allergies`… | la persona | app | `relationship_types`, `allergies`, `diseases`, `medicines` |

---

## Parte 3. Huecos del panel admin detectados

Hallazgos verificados en código. Ordenados por impacto en el onboarding de un ambiente nuevo.

### 3.1 Bloqueantes para configurar sin tocar la base

1. **No hay pantalla ni checklist de "puesta en marcha".** El orden correcto solo vive en avisos de "gap" dispersos (`lib/prerequisites/club-create-gaps.ts`, `annual-folder-gaps.ts`). Un admin nuevo no sabe que necesita año → tipos de club → geografía → usuarios → plantilla publicada → ranking config.
2. **`system_config` es solo edición.** `/dashboard/configuration/variables` no crea llaves. Con tabla vacía muestra un EmptyState sin acción. Más de la mitad de las llaves leídas por el backend no están sembradas, así que no se pueden ajustar.
3. **`users.union_id` y `users.local_field_id` no se pueden editar después de crear el usuario** (`UpdateAdminUserPayload` solo tiene `access_app`, `access_panel`, `active`). Un director-lf mal creado hay que corregirlo por SQL. Además el formulario exige país y unión para todo rol pero deja campo local opcional incluso para `director-lf`.
4. **`local_fields.timezone` no se captura en el formulario de campo local.** Es obligatorio para investidura. Solo existe un script de backfill.
5. **Configuración de seguros inaccesible para super-admin y admin.** `insurance-config-scope.ts` solo acepta `director-lf` / `assistant-lf`; la pantalla ofrece un selector de campo que el backend rechaza con 403. Para pre-configurar un campo hay que impersonar a su director.
6. **`club_enrollments` sin pantalla admin.** La inscripción anual del club solo se hace desde la app. El admin no puede abrir el año de un club.
7. **Primer super-admin solo por seed o API.** Sin UI de bootstrap; el flujo requiere `BOOTSTRAP_SECRET` + SQL para `access_panel`.

### 3.2 Configuración regada / poco intuitiva

8. La configuración está en al menos seis menús distintos: Administración (Catálogos, Campo local, Config. campamentos, Configuración, Sistema), Operaciones → Seguros → Configuración, Validación → Autorización de investiduras (ventana, pastores) y Evidencias → Plantillas, Clasificaciones → Config. de clasificación y Pesos, Comunicaciones → Categorías, más `/dashboard/coordination`.
9. El hub `/dashboard/configuration` solo enlaza notificaciones, logros, variables, permisos, roles y matriz. No enlaza geografía, años, investidura, seguros, campo local ni ranking. Y no es hoja del sidebar.
10. **"Campo local" vs "Unión" en Config. campamentos son la misma pantalla** sobre el mismo catálogo global `camporee_event_types`; el scope es cosmético.
11. `field_payment_order_configs` (instrucciones de pago del campo) vive dentro de **Seguros → Configuración**, no en **Campo local**, donde están los datos bancarios de materiales (`MaterialConfig`). Dos configuraciones de pago del mismo campo en dos menús distintos.
12. Dos entradas del sidebar son redirects puros (`annual-folders/templates`, `annual-folders/categories`) y "Plantillas" aparece dos veces (carpetas anuales y evidencias).
13. Dos nociones de "año actual" (`active` vs fechas) sin aviso de inconsistencia.

### 3.3 Sin UI

14. `role_slot_limits` (solo SQL).
15. `honor_requirements` (solo seed TS que lee `docs/working/`).
16. `scoring_categories` de unión y campo: los componentes `union-scoring-categories-tab.tsx` y `local-field-scoring-categories-tab.tsx` existen pero no están montados en ninguna página.
17. `/dashboard/rbac/user-permissions` existe pero no tiene entrada en el sidebar ni enlace entrante.
18. `investiture_config` (legacy) sin editor y sus rutas responden 410; correcto, pero `permissions.seed.sql` sigue sembrando `investiture_config:*`.
19. Roles referenciados por nombre que **no existen**: `sub-director`, `directora`, `subdirector`, `secretario`, `tesorero` en `member-of-month.service.ts`, `annual-reports.service.ts`, `monthly-reports.service.ts`. La "directiva" de esos reportes sale vacía. Es un bug de código, no de datos.

### 3.4 Propuesta de reorganización (para discutir)

Un menú **Configuración** con tres niveles explícitos, alineado a las capas de esta guía:

- **Sistema** (super-admin): variables (con alta de llaves), roles, permisos, matriz, auditoría, jobs, cupo de pastores, pesos globales de ranking, rangos (`ranking_tiers`).
- **Catálogos** (admin): geografía, años, tipos de club, clases/módulos/secciones, especialidades, maestrías, certificaciones, salud, negocio, logros, tipos de evento, categorías de materiales.
- **Mi territorio** (director-dia / director-union / director-lf, auto-scoped): datos del campo (timezone, pagos, entrega), coordinación, investidura (ventana, umbral, pastores), seguros, plantilla de carpeta anual, ranking anual, scoring, camporees, catálogo de materiales y de pedidos.

Más una pantalla **Estado de configuración** que recorra las capas 1 a 3 y marque qué falta para el scope del usuario. La lógica ya existe parcialmente en `lib/prerequisites/*`.

---

## Anexo A. Orden completo de carga para un ambiente de producción nuevo

```text
 0. migrate deploy                         → Capa 0 automática
 1. seed.ts                                 → roles, club_types, countries, relationship_types, ranking_tiers
    (quitar/ajustar admin@sacdia.com y usuario/clase de prueba)
 2. permissions.seed.sql
 3. role-permissions.seed.sql
 4. system-config.seed.sql + role-slot-limits.seed.sql
 5. Primer super-admin (seed o bootstrap) → flush Redis
 6. Admin: año eclesiástico que cubra hoy, active = true → flush Redis
 7. Admin: uniones → campos locales (+ timezone por script) → distritos → iglesias
 8. Catálogos de dominio: classes (+ módulos/secciones), honors, master_honors,
    certifications (publicar versión), achievements, categorías varias
 9. Admin: usuarios director-union / director-lf con union_id y local_field_id
10. Cada campo: coordinación, investidura (ventana, umbral, pastores), seguros,
    pago del campo, materiales, plantilla carpeta anual (publicar), ranking config
11. Clubes (admin o director-lf) → inscripción anual (app) → directiva → miembros
```

## Anexo B. Scripts y seeds existentes

| Comando / archivo | Capa | Notas |
|---|---|---|
| `pnpm prisma migrate deploy` | 0 | Idempotente |
| `npx tsx prisma/seed.ts` (`prisma db seed`) | 1 | Incluye admin con contraseña fija |
| `prisma/seeds/permissions.seed.sql`, `role-permissions.seed.sql` | 1 | psql; orden estricto |
| `prisma/seeds/system-config.seed.sql`, `role-slot-limits.seed.sql` | 2 | psql idempotente |
| `pnpm import:legacy-catalogs` | 1–2 | Lee respaldos SQL de `~/Downloads/Sacdia/Respaldos` (fuera del repo). Único camino para geografía, clases, honors en bloque |
| `docs/working/seed-*-modules-sections.sql` | 2 | Hardcodean `class_id` 7-12 |
| `prisma/seeds/honor-requirements.seed.ts`, `honor-requirements-rescan.seed.ts` | 2 | Leen `docs/working/honors-especialidades/` |
| `scripts/import-adventurer-specialties.ts` | 2 | Lee `docs/working/aventureros-especialidades/` |
| `pnpm import:master-honor-rules -- --file` | 2 | |
| `prisma/seeds/achievements.seed.ts` | 2 | upsert |
| `prisma/seeds/certifications/basic-pathfinder-staff-training.seed.ts` | 2 | También lo corre `core.ts` |
| `prisma/seeds/folder-templates.seed.ts` | 3 | Crea borradores por tipo de club × año; hay que publicarlos |
| `pnpm backfill:local-field-timezones` | 3 | Timezone de campos |
| `pnpm prisma:seed:core` | dev | Datos operativos de prueba; bloqueado fuera de la rama dev |
| `prisma/seeds/test-users.seed.ts` | dev | Un usuario por rol administrativo |

## Anexo C. Pendientes técnicos derivados

- Sembrar todas las llaves `system_config` con defaults.
- Capturar `timezone` en el formulario de campo local y hacerlo obligatorio.
- Permitir editar `union_id` / `local_field_id` del usuario desde el admin.
- Abrir configuración de seguros a admin/super-admin con selector de campo (o documentar que es solo del campo).
- Montar las pestañas de scoring de unión y campo.
- Corregir nombres de rol inexistentes en reportes y miembro del mes.
- Mover `admin@sacdia.com` fuera de `seed.ts` o leer la contraseña de env.
- Script de seed de `classes` versionado en el repo (hoy depende de respaldos locales).
