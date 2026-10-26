# SACDIA — Deployment Guide

**Estado**: ACTIVE
**Actualizado**: 2026-10-20
**Fuentes**: `sacdia-backend/render.yaml`, `sacdia-backend/src/config/env.validation.ts`, `.github/workflows/ci.yml` de cada repo, el dashboard de Render y Neon (topología informada por el responsable de infraestructura el 2026-10-13) y `docs/guides/ocr-proxy-preprod-infra.md`.

> [!IMPORTANT]
> Hoy existe **un solo entorno en línea**, y se despliega desde la rama `development`: el servicio de Render "API Sacdia" y el admin de Vercel construyen `development` y usan la rama `development` de Neon como base viva. Las ramas `staging` y `production` de Neon existen pero **no se usan**. La sección 0 describe esa topología real. Las secciones 1 a 10 son la receta de referencia para levantar entornos separados cuando se creen; donde difieren de la topología actual, manda la sección 0. Si algo contradice `render.yaml` o `env.validation.ts`, mandan esos archivos y esta guía se corrige (ojo: `render.yaml` ya no describe el servicio real, ver 0.2).

**Infraestructura:**

| Pieza | Servicio |
|---|---|
| Backend (NestJS) | Render, web service "API Sacdia" (Free) |
| Admin (Next.js) | Vercel, `https://admin.sacdia.com` |
| Base de datos | Neon (PostgreSQL), un proyecto con 3 ramas |
| Proxy OCR | Cloud Run (proxy keyless hacia Google Vision) |
| Cache, colas y rate limit | Redis (Upstash recomendado) |
| Archivos | Cloudflare R2 |
| Auth | Better Auth dentro del backend (JWT HS256) |
| Push | Firebase Cloud Messaging |
| Correo | Resend |
| Monitoreo | Sentry |
| App | Flutter → App Store y Play Store |

---

## 0. Topología actual (2026-10-13)

```text
GitHub (rama development)
   ├─ push ─► Render "API Sacdia" (auto-deploy) ─► Neon rama development  ◄── base viva
   │              └─ OCR firmado ─► Cloud Run (proxy OCR) ─► Google Vision
   └─ push ─► Vercel (admin.sacdia.com)
Neon ramas staging y production: existen y ningún servicio las usa. `staging` está migrada al nivel de `development` (2026-10-21); `production` sigue en `20261014100000` (ver §0.6).
```

| Pieza | Estado real |
|---|---|
| Backend | Render web service **"API Sacdia"**, plan **Free**, rama **`development`**, auto-deploy **activado** |
| Admin | Vercel, `https://admin.sacdia.com`, despliega **`development`** |
| Base de datos | Neon. `DATABASE_URL` del backend apunta a la rama **`development`** (endpoint `ep-rough-hill-anztwk76`): es la base viva. Las ramas `staging` y `production` existen, pero ningún servicio las usa. `staging` tiene las mismas migraciones que `development` (2026-10-21); `production` sigue en `20261014100000` y le faltan 9 (ver §0.6) |
| OCR | Proxy keyless en Cloud Run; runbook en `docs/guides/ocr-proxy-preprod-infra.md` |
| Otros servicios | Redis, R2, Firebase, Resend y Sentry según la tabla 4.2; su cuenta y plan concretos no se documentan aquí |

> No hay entorno de preproducción separado: cada merge a `development` de backend o admin llega a la instancia en línea. Y como el build command de Render termina con `prisma migrate deploy` contra la base viva, **cada migración que se mergea se aplica de inmediato a datos reales**. Revisar migraciones con ese criterio antes de mergear (ver 0.4).

### 0.1 Render "API Sacdia"

| Campo | Valor |
|---|---|
| Tipo / plan | web service / **Free** (512 MB de RAM) |
| Rama | `development`, auto-deploy activado |
| Build | `corepack pnpm install --frozen-lockfile && NODE_OPTIONS=--max-old-space-size=4096 corepack pnpm run build && corepack pnpm exec prisma migrate deploy` |
| Pre-deploy | **No disponible**: el plan Free de Render no admite pre-deploy command. Las migraciones corren al final del build (nunca `db push`) |
| Start | `node --max-old-space-size=320 --max-semi-space-size=2 dist/src/main.js` |
| Health check | endpoint `GET /api/v1/health` (recomendado fijarlo como Health Check Path, ver abajo) |

- **Start con límites de memoria.** El comando de arranque salta `pnpm start:prod` (que es `node dist/src/main.js`) y limita el heap de V8 a 320 MiB y el semi-espacio a 2 MiB para dejar margen bajo los 512 MB del plan Free. Si el proceso supera el límite de memoria de la instancia, Render lo reinicia.
- **Health Check Path (recomendado).** Configurar en Render → Settings → Health Check Path el valor `/api/v1/health`. Así Render solo pasa el tráfico al deploy nuevo cuando responde `{"status":"ok"}` y reinicia la instancia si deja de responder. El servicio real difiere del blueprint (ver más abajo), así que lo que declara `render.yaml` (`healthCheckPath`) no se aplica solo.
- **Diferencias con `render.yaml`.** El blueprint del repo define otro servicio (`sacdia-backend`, plan `starter`, start `pnpm start:prod`). El servicio real se llama "API Sacdia", es Free y usa el start de arriba. Los cambios de nombre, plan, start o health se hacen en el dashboard; cambiar `render.yaml` no los toca. Alinear el blueprint con la realidad (o documentar que es solo referencia) es un pendiente.
- **Plan Free.** Según la documentación de Render, los web services Free se suspenden tras un periodo sin tráfico y la primera petición posterior paga un arranque en frío. Es esperable en este entorno. Consecuencia para los crones: corren dentro del proceso de la API, así que **mientras el servicio duerme no corre ninguno** (observado el 2026-10-21: no hubo ninguna corrida en `cron_run_log` desde el 2026-10-20 20:30 UTC hasta que se despertó). Para ejecutarlos en desarrollo, un super-admin usa «Ejecutar ahora» (`/dashboard/system/jobs` o `POST /api/v1/admin/cron-jobs/:jobName/run`; ver `docs/features/cron-automation.md`). En producción esto no es aceptable: ver 0.6, punto 10.
- **Registro de memoria.** El backend escribe una línea estructurada con el mensaje `Process memory` al arrancar (`phase: boot`) y luego cada `PROCESS_MEMORY_LOG_INTERVAL_MINUTES` minutos (`phase: interval`). Por defecto 15; `0` desactiva el intervalo y deja la línea de arranque; valor entero ≥ 0. Campos: `rss_mib`, `heap_used_mib`, `heap_total_mib`, `external_mib`, `array_buffers_mib`, `heap_size_limit_mib`, `uptime_seconds`; sin datos personales. Para ver la presión real de memoria, filtrar los logs de Render por `Process memory` y comparar `rss_mib` con los 512 MB del plan (código: `sacdia-backend/src/common/observability/process-memory-logger.service.ts`).
- **Variables.** Las secretas se cargan en el dashboard (tabla 4.2). Las de OCR remoto, en 0.3.

### 0.2 Neon

- Un proyecto, tres ramas: `development`, `staging`, `production`.
- **`development` es la base viva**: `DATABASE_URL` de "API Sacdia" apunta a su endpoint (`ep-rough-hill-anztwk76`, cadena pooled). Es lo que el servicio en línea lee y escribe.
- `staging` y `production` existen, pero **ningún servicio las consume**. `staging` está al nivel de `development` (2026-10-21); `production` sigue en `20261014100000` (ver §0.6). No tratarlas como respaldo de `development`: no reciben sus datos.
- Las migraciones se aplican al final del build de Render contra la rama que indique `DATABASE_URL`. Como esa cadena es pooled, el servicio necesita también `DATABASE_DIRECT_URL` (misma rama, host sin `-pooler`) para que `prisma migrate deploy` use una conexión directa. `staging` y `production` no las reciben solas: se aplican a mano, con aprobación, como indica el §3.
- **Historia (2026-10-13):** hasta esa fecha el build no migraba y el servicio no tenía pre-deploy (el plan Free no lo admite), así que todas las migraciones de octubre se aplicaron a mano. Antes de un deploy con migración, confirmar en el log del build que aparezca `All migrations have been successfully applied` o `No pending migrations to apply`.
- Nunca incluir cadenas de conexión completas ni contraseñas en docs, tickets o chats; el endpoint (`ep-…`) identifica la rama, el resto es secreto.

### 0.3 Admin y OCR

- **Admin (Vercel).** `https://admin.sacdia.com`, desplegando la rama `development`. Variables en el §5; el dominio del admin debe estar en `ALLOWED_ORIGINS` del backend.
- **OCR (Cloud Run).** El OCR de certificados no usa llave de API: el backend firma la solicitud (HMAC) hacia un proxy en Cloud Run que habla con Vision con identidad de servicio, sin claves. Procedimiento, rollback y costos en `docs/guides/ocr-proxy-preprod-infra.md` (el documento conserva el estado "propuesto" de su redacción del 2026-10-07; el proxy ya está desplegado según el responsable). En Render, con `NODE_ENV=production`, `OCR_MODE` es obligatorio; con `OCR_MODE=remote` también `OCR_PROXY_URL` (URL completa del endpoint, `https://<host>/v1/ocr`), `OCR_PROXY_ENV`, `OCR_PROXY_KID` y `OCR_PROXY_SECRET`. Si falta alguna, el arranque falla (no hay fallback a credenciales por defecto). Solo nombres aquí; los valores viven en Render y Secret Manager.

### 0.4 Reglas de migraciones

- **Nunca `CREATE INDEX CONCURRENTLY` en una migración que también tenga bloques `DO`.** Prisma ejecuta el archivo como un solo lote; Postgres rechaza `CONCURRENTLY` dentro de una transacción y `migrate deploy` falla con **P3018** (error de base de datos **25001**). Pasó con `20261013100000_honor_instructor_proposals` y se corrigió en sacdia-backend (PR #485: índices sin `CONCURRENTLY` y una prueba que lo exige).
- Para tablas nuevas y vacías (el caso habitual), un `CREATE INDEX` normal es instantáneo. Escribir las migraciones **re-ejecutables** (`IF NOT EXISTS`, `DROP CONSTRAINT IF EXISTS`, manejo de `duplicate_object`) para que un reintento tras un fallo parcial no tropiece.
- Si de verdad hace falta un índice concurrente sobre una tabla grande y existente, hacerlo fuera de `migrate deploy` (a mano con `psql`, con aprobación) y dejar la migración sin ese índice o con `IF NOT EXISTS`.
- Una migración fallida queda registrada en `_prisma_migrations` y bloquea los deploys siguientes (**P3009**) hasta resolverla (corregir y `prisma migrate resolve`). Con auto-deploy sobre la base viva, un fallo así hace fallar el build y el deploy no sale (el servicio sigue con la versión anterior): vigilar el log del build tras cada merge con migraciones.
- **Migrar en el build tiene un costo:** la migración corre después de compilar pero antes de arrancar la versión nueva. Si el deploy falla después (por ejemplo, el arranque), la migración ya quedó aplicada y la versión anterior sigue corriendo contra el esquema nuevo. Por eso cada migración debe ser **compatible con el código anterior** (aditiva; borrar columnas o tablas en un deploy posterior al que dejó de usarlas).
- La shadow DB no es fiable en este proyecto: las migraciones se escriben a mano y se aplican con `migrate deploy`.

### 0.5 Migraciones de instructor de especialidad y carga por certificado (2026-10-13)

Cuatro migraciones aditivas del backend, mergeadas el 2026-10-12 y 2026-10-13. Detalle de columnas y tabla en `docs/database/SCHEMA-REFERENCE.md`.

| # | Directorio (`sacdia-backend/prisma/migrations/`) | Usa `CONCURRENTLY` | `development` | `staging` | `production` |
|---|---|---|---|---|---|
| M1 | `20261010120000_certificate_import_honor_instructor` | Sí (2 índices) | Aplicada | Aplicada | Aplicada |
| M2 | `20261010130000_certificate_import_ocr_pages` | Sí (1 índice) | Aplicada | Aplicada | Aplicada |
| M5 | `20261012130000_honors_completed_at` | No | Aplicada | Aplicada | Aplicada |
| M4 | `20261013100000_honor_instructor_proposals` | No (desde #485) | Aplicada | Aplicada (recuperada) | Aplicada (recuperada) |

> [!NOTE]
> Verificado el 2026-10-13 con consultas de solo lectura en las tres ramas: las cuatro migraciones tienen una fila terminada en `_prisma_migrations` con el checksum del archivo actual de `origin/development`, no hay migraciones sin terminar, las 8 columnas y la tabla `honor_instructor_proposals` existen, los 20 constraints están validados y los 6 índices son válidos. En `staging` y `production`, M4 tiene además una fila previa con `rolled_back_at` (el intento con `CONCURRENTLY` que falló con P3018 / 25001) y una segunda fila terminada tras la recuperación manual. Para volver a comprobarlo: `SELECT migration_name, left(checksum, 12), finished_at, rolled_back_at FROM _prisma_migrations WHERE migration_name IN ('20261010120000_certificate_import_honor_instructor','20261010130000_certificate_import_ocr_pages','20261012130000_honors_completed_at','20261013100000_honor_instructor_proposals') ORDER BY migration_name, started_at;`

**Código nuevo sobre una base sin estas migraciones falla** (columnas y tabla inexistentes). Las tres ramas ya las tienen; para una rama nueva, aplicar las cuatro **antes** de apuntarle un servicio.

**Procedimiento para `staging` y `production`** (con aprobación; cadena **directa**, sin `-pooler`, tomada de una variable de entorno; no pegar cadenas de conexión en docs, tickets ni chats):

1. Orden: M1, M2, M5 y M4. M1 y M2 son independientes entre sí; M4 necesita M1 porque aprobar una propuesta escribe `users_honors.instructor_*`.
2. M1 y M2: `psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f prisma/migrations/<directorio>/migration.sql`, **sin** `-1` ni `--single-transaction` y sin envolver el archivo en `BEGIN/COMMIT`: `CREATE INDEX CONCURRENTLY` no corre dentro de una transacción. Con `-f` cada sentencia corre en la suya. **No usar `prisma migrate deploy` para M1 y M2**: ejecuta el archivo como un solo lote y fallaría con P3018 / 25001, como le pasó a M4 antes de #485.
3. M5 y M4 no usan `CONCURRENTLY`: se pueden aplicar con el mismo `psql -v ON_ERROR_STOP=1 -f` o con `prisma migrate deploy`.
4. Todas son re-ejecutables (`IF NOT EXISTS`, `DROP CONSTRAINT IF EXISTS`). Si un `CREATE INDEX CONCURRENTLY` falla a medias queda un índice `INVALID`: `DROP INDEX CONCURRENTLY <nombre>;` y volver a correr el archivo.
5. Registrar cada una en `_prisma_migrations` si se aplicó con `psql`: `corepack pnpm exec prisma migrate resolve --applied <directorio>` con `DATABASE_URL` y `DATABASE_DIRECT_URL` de esa rama. Sin este paso, un `migrate deploy` posterior intentaría correrla de nuevo.
6. Verificar: `SELECT indexrelid::regclass FROM pg_index WHERE NOT indisvalid;` debe estar vacío para los índices nuevos, y `SELECT conname, convalidated FROM pg_constraint WHERE conname ~ '(instructor|source_|page_count|completed_at)';` debe mostrar todo validado. Para M5: `SELECT count(*) FILTER (WHERE completed_at IS NOT NULL) AS con_fecha, count(*) AS total FROM users_honors WHERE validation_status = 'APPROVED';`
7. Rollback: solo hacia adelante. Antes de que haya datos reales, `DROP INDEX`, `DROP CONSTRAINT` y `DROP COLUMN` en orden inverso (M4: `DROP TABLE honor_instructor_proposals; DROP TYPE honor_instructor_proposal_status_enum;`).

### 0.6 Checklist de promoción: perfiles familiares (Fase 2 y Fase 3)

> [!WARNING]
> Estado: **BORRADOR de proceso**, redactado antes de que la Fase 3 se mergee. Las cuatro primeras migraciones de la Fase 3 ya existen con su nombre real y están aplicadas en Neon `development` (2026-10-20) y `staging` (2026-10-21); falta promoverlas a `preproduction` y `main`. La quinta (`20261023120000_grant_consent_verify_to_coordinators`, seguimiento de coordinadores, ya mergeada en sacdia-backend por el PR #532) y la sexta (`20261024120000_allow_coordinator_paper_form`, rama `feat/coordinator-pending-consents`, mergeada en `development` por el PR #534 de sacdia-backend) están aplicadas en Neon `development` y `staging` (2026-10-21) y **pendientes en `production`**. El texto legal 2.0.0-family es un **borrador pendiente de revisión** (`docs/legal/README.md`). Rama de trabajo del backend: `feat/family-profiles-phase3`, Pendiente de merge (PR #531 de sacdia-backend).

> [!NOTE]
> Estado de aplicación (2026-10-22): las 9 migraciones de esta lista (`20261015120000` a `20261024120000`) están aplicadas en `development` y en `staging` (2026-10-21, a mano con psql, cada una en su transacción y registrada en `_prisma_migrations`). `production` sigue en `20261014100000`: las 9 están pendientes y deben aplicarse en ese orden junto con el deploy del backend. `20261016100000` quita los permisos cruzados del rol base `user`, un cambio de comportamiento para el backend que corre hoy en producción; `20261024120000` debe estar aplicada antes del backend que escribe `coordinator_paper_form`.

**Regla de producción.** `production` (Neon) y `main` se alcanzan **solo** por la promoción `development` → `preproduction` → `main`, y **`prisma migrate deploy` es quien aplica las migraciones** en cada deploy. Nada de `psql` a mano sobre producción (esto tiene prioridad, para estas fases, sobre el procedimiento manual del §3, punto 3). El `psql` a mano queda para la rama `development` de Neon con aprobación explícita (QA), siguiendo el flujo de migraciones de Neon. Hoy solo `development` está en línea (§0): un merge a esa rama ya aplica las migraciones a datos reales, así que esta lista también aplica antes de ese merge.

**1. Bloqueantes de la Fase 2 (primero).** Perfiles familiares Fase 2 (PR #530 de sacdia-backend) ya está mergeada en `development`; sus tres migraciones tienen que estar aplicadas en la rama de destino antes de promover la Fase 3, porque la 3a ya las supone (en `staging` están aplicadas desde el 2026-10-21; en `production` están pendientes, ver la nota de arriba):

| # | Migración (`sacdia-backend/prisma/migrations/`) | Qué hace |
|---|---|---|
| P2-1 | `20261015120000_legal_acceptances` | Tabla `legal_acceptances` (solo aditiva) |
| P2-2 | `20261016100000_base_user_role_drop_cross_user_grants` | Solo datos: quita permisos cruzados del rol base `user` (corrección de seguridad) |
| P2-3 | `20261016120000_family_profiles` | `users.email` admite NULL, columnas de edad en `countries` y las 4 tablas de perfiles familiares |

- Bucket **privado** de R2 para las fichas de consentimiento: `R2_BUCKET_GUARDIANSHIP_EVIDENCE` apuntando a un bucket **privado** (el nombre se configura en Render, no se documenta aquí). Sin él, las rutas de ficha responden 503 `GUARDIANSHIP_EVIDENCE_UNAVAILABLE` (el resto de la API sigue). Condición que el código no puede comprobar: el bucket no debe tener dominio personalizado ni acceso `r2.dev` habilitados. Se sirve solo por URL firmada de 15 minutos.
- Backend y app de la Fase 2 se despliegan juntos (el backend retiró las rutas del representante legal que la app anterior sigue llamando).

**2. Migraciones de la Fase 3, en este orden** (todas escritas a mano, re-ejecutables, sin `CONCURRENTLY`; el guard `family-profiles-phase3.migration.spec.ts` las comprueba):

| # | Migración | Sub-fase | Contenido |
|---|---|---|---|
| 1 | `20261020120000_family_teen_login` | 3a | `supervised_logins` y dos reemplazos de CHECK (`guardianship_link_codes` y `guardianships`). Sin DML |
| 2 | `20261021120000_family_linked_devices` | 3b | `linked_devices`, `device_pairing_tokens` y ampliación de un CHECK de `supervised_logins`. Sin DML |
| 3 | `20261022120000_family_director_minors` | 3c | `dependent_profiles.teen_login_nudged_at` (una sentencia, aditiva) |
| 4 | `20261022130000_seed_family_permissions` | 3c | Solo DML: permisos y asignaciones por rol (ver abajo) |
| 5 | `20261023120000_grant_consent_verify_to_coordinators` | 3c (seguimiento) | Solo DML: `consent:verify` para `coordinator`, `zone-coordinator` y `general-coordinator`. Rama `feat/coordinator-consent-verify` (PR #532 de sacdia-backend, ya mergeado). Aplicada en Neon `development` y `staging` (2026-10-21); **pendiente de aplicar** en `production`. Va después de la 4 (usa el permiso que esa crea) |
| 6 | `20261024120000_allow_coordinator_paper_form` | 3c (seguimiento) | Solo DDL: `DROP` y `ADD` del CHECK `guardianships_verification_method_ck` para admitir `coordinator_paper_form` (los valores existentes siguen siendo válidos). Rama `feat/coordinator-pending-consents`, mergeada en `development` (PR #534 de sacdia-backend, 2026-10-21). Aplicada en Neon `development` y `staging` (2026-10-21); **pendiente de aplicar** en `production`. **Aplicarla antes de desplegar el backend de esa rama**: sin ella, el `UPDATE` de una verificación hecha por un coordinador falla con una violación del CHECK. Re-ejecutable; sin reversión una vez que existan filas con `coordinator_paper_form` |

Antes de promover cada rama: `prisma migrate status` contra la base del entorno debe mostrar como únicas pendientes las de la lista que correspondan, y en el log del build debe aparecer `All migrations have been successfully applied`. Las migraciones son compatibles con el código anterior (aditivas; los CHECK solo se amplían), así que un deploy que falla después de migrar no rompe la versión previa. No hay migración *down*: la reversión de esquema es manual y solo antes de que existan datos reales.

**3. Seeds de permisos.** Las migraciones 4 y 5 los aplican con `migrate deploy`; los mismos registros viven en `prisma/seeds/permissions.seed.sql` y `prisma/seeds/role-permissions.seed.sql` (pasos del §3.4 para una base nueva). Debe coincidir lo uno con lo otro.

| Permiso | Roles |
|---|---|
| `dependents:create` | Director y subdirector de club |
| `consent:verify` | Director, subdirector, secretario y secretario-tesorero de club; `coordinator`, `zone-coordinator` y `general-coordinator` (migración 5) |

La migración da además **ambos** permisos a `admin`, `assistant-admin` y `super-admin` de forma explícita (una migración no puede apoyarse en los comodines de los seeds). Los coordinadores (`coordinator`, `zone-coordinator`, `general-coordinator`) los recibe la migración 5, no la 4 (la tarea T3c-B11 los había dejado fuera porque `PermissionsGuard` no resolvía su territorio). Ahora el guard los admite, ruta por ruta, solo en las secciones que cubren sus `coordinator_assignments` activas y como revisores solo-verificación (nunca aprueban); detalle en `docs/api/ENDPOINTS-LIVE-REFERENCE.md`, «Revisor solo-verificación». `assistant-lf` ya verifica por `club_members:approve`.

Ambas son idempotentes (`ON CONFLICT`). Verificar tras aplicar la 4: un director tiene `dependents:create`; un coordinador y un miembro no. Tras aplicar la 5: un coordinador tiene `consent:verify` (y sigue sin `dependents:create` ni `club_members:approve`). Hasta aplicarla, el hub de coordinador de la app y la pantalla del panel no aparecen, porque `/auth/me` no trae el permiso. La migración 5 une solo roles globales activos que existan; el recuento de asignaciones nuevas depende de los roles de cada rama y no está registrado aquí (se aplicó en `development` el 2026-10-21, pero no se anotó cuántas filas insertó). En Neon `development` (2026-10-20), la migración 4 dejó **10** asignaciones y no 12, porque esa rama no tiene el rol `assistant-admin`; en `staging` y `production` el número depende de los roles que existan allí, y las migraciones unen solo roles activos que existan.

**4. Banderas** (variables de Render; por defecto `false`; se habilitan **por entorno**, una a la vez, empezando por `development` y `preproduction`):

| Variable | Gobierna |
|---|---|
| `FAMILY_TEEN_LOGIN_ENABLED` | Acceso supervisado de 13 a 17 años con usuario generado y las rutas del tutor para gestionarlo |
| `FAMILY_LINKED_DEVICE_ENABLED` | Vinculación por QR y autenticación del teléfono de un menor de 13 años |
| `FAMILY_DIRECTOR_CREATE_MINOR_ENABLED` | `POST /club-sections/:clubSectionId/dependents` (3c; el director registra un menor). Solo gobierna el registro: verificar, reclamar y vencer lo ya creado no dependen de ella |

- Se leen **al arrancar**: cambiar el valor exige reiniciar el servicio (en Render, guardar la variable redeploya).
- **No tienen bandera**, y por eso llegan con el primer deploy aunque todas estén en `false`: la compuerta de consentimiento para todo menor de edad, el modo "pendiente de tutor", los avisos y el resumen del tutor, los crones (recordatorios y purga de adolescentes sin tutor, barrido de dispositivos, avisos de cumpleaños) y la versión legal. Las banderas **no** deshacen el punto 6.
- `GET /auth/me` expone el estado en `family_features`; la app oculta lo que esté apagado.

**5. Aprobación legal antes de promover a `main`.** El commit que sube la versión legal del backend a `2.0.0-family` (`86d3717a`, el último de la 3a) es independiente y **revertible por sí solo**. Orden obligatorio: (a) el usuario o un abogado aprueba el texto y se quitan los avisos «BORRADOR»; (b) se publica en `https://sacdia.com/terms` y `https://sacdia.com/privacy`; (c) solo entonces se promueve. Si no se aprueba, se revierte ese commit y la rama puede promoverse sin él (la versión publicada sigue siendo `1.0.0-store`). Subir la versión obliga a **todos** los usuarios a volver a aceptar. Detalle en `docs/legal/README.md` y `docs/legal/store-submission-privacy-checklist.md` (declaraciones de las tiendas, incluida la pregunta abierta sobre la eliminación de cuentas de menores).

**6. Impacto en producción que hay que comunicar a los directores de club** (decisión «opción A»):

- Los miembros de **13 a 17 años que ya tienen una membresía activa** pasan a modo «pendiente de tutor» en cuanto se despliega el backend: pierden su **credencial QR** y su **contexto de club** en la app hasta que haya un tutor vinculado y verificado. La membresía no se borra; es la compuerta de consentimiento, que no depende de ninguna bandera.
- El director (o una persona con `consent:verify`, ver arriba; los cuatro roles de club con ese permiso ya tienen `club_members:approve`, y los coordinadores lo tienen solo para verificar en sus secciones, sin aprobar) puede **verificar el consentimiento sobre la asignación ya activa** sin crear una nueva: es una verificación sin aprobación. La ficha firmada la sube el tutor o el director; en los menores que crea un director (3c), la verifica **otra persona** distinta de quien lo creó, de quien subió la ficha y del tutor.
- Pedir antes del deploy el recuento de miembros de 13 a 17 años con rol activo, para saber a cuántos afecta y avisar con anticipación.
- Los adolescentes que se registren solos reciben recordatorios a los 7, 30 y 83 días sin tutor; se congelan a los 90 y se purgan 90 días después. En cuentas que ya existen, el plazo empieza en la primera evaluación del cron tras el deploy: nadie se congela ese día.
- Las apps anteriores a la Fase 3 no entienden el modo restringido: un adolescente con una versión vieja vería errores 403 en las pantallas de club. Publicar la app nueva antes de abrir el backend a los usuarios, o junto con él (deducido del comportamiento del servidor; no probado con una app antigua).

**7. Limpieza de PostHog (P3-A12).** La analítica de los 13 a 17 pasa a ser anónima, pero las **personas ya identificadas** en PostHog con versiones anteriores de la app siguen ahí. Tarea de operaciones, una vez publicada la app nueva: obtener (consulta de solo lectura) los `user_id` de las personas de 13 a 17 años y de las cuentas sin fecha de nacimiento, y **eliminar sus personas y eventos** en PostHog. Dejar constancia de la fecha y el responsable. El procedimiento exacto en el panel de PostHog está pendiente de documentar.

**8. Reversión por bandera** (ninguna borra datos; volver a encender restaura el acceso):

| Bandera | Al apagarla y reiniciar |
|---|---|
| `FAMILY_TEEN_LOGIN_ENABLED` | El inicio de sesión con usuario generado responde el 401 uniforme; las sesiones ya abiertas de cuentas con usuario generado se cortan en la siguiente petición; las rutas del tutor para activar, desactivar, reactivar y cambiar la contraseña responden 404 `FAMILY_FEATURE_DISABLED`. Los adolescentes con correo no cambian. |
| `FAMILY_LINKED_DEVICE_ENABLED` | La vinculación responde 404 (generar token) o 400 uniforme (canjear); todo teléfono ya vinculado recibe 401 `AUTH_DEVICE_REVOKED` en su siguiente petición, **sin** revocar filas ni borrar sesiones. Al volver a encender, los teléfonos que no hayan vencido ni sido revocados vuelven a funcionar |
| `FAMILY_DIRECTOR_CREATE_MINOR_ENABLED` | La ruta de registro responde 404 `FAMILY_FEATURE_DISABLED` (después de los guards); los menores ya creados, sus solicitudes pendientes y su custodia siguen su curso (verificación, reclamo por el padre o vencimiento a los 30 días) |

Lo que **no** se revierte con banderas: la compuerta de consentimiento, el modo pendiente y los crones. Para quitarlos hace falta revertir el código (el commit legal puede revertirse aparte). Si se revierte el backend a una versión sin 3b, un token de dispositivo (audiencia `sacdia:device`) falla cerrado con 401 y las tablas nuevas quedan sin uso.

**9. Verificación posterior al deploy.** `GET /api/v1/health` en verde; `GET /auth/me` de un adulto con `family_features` en `false`; el log del build con las migraciones aplicadas; un adolescente de prueba en modo pendiente y un director verificando consentimiento sobre una asignación activa; en el panel de PostHog, el adolescente y el teléfono vinculado sin identificar.

**10. Los crones exigen un plan de Render de pago, siempre encendido (decisión del 2026-10-21).** Los `@Cron` corren dentro del proceso de la API; con el plan Free el servicio se suspende por inactividad y **ningún cron corre mientras duerme** (purgas, recordatorios, vencimientos de solicitudes, el reloj de 90 días de los adolescentes sin tutor, el barrido de cambios de edad). En desarrollo se acepta y se resuelve con el botón «Ejecutar ahora» (super-admin; `POST /api/v1/admin/cron-jobs/:jobName/run`). **Producción necesita un plan de pago always-on**: añádelo a esta checklist antes de promover a `main`, junto con la advertencia de que ejecutar a mano un job con avisos (`activities-reminder`, `cron-alert-check` y los de la fase 3) envía notificaciones reales. Si algún día hiciera falta fiabilidad en desarrollo sin pagar: un ping externo de keep-alive, o mover los crones a Render Cron Jobs o GitHub Actions que llamen a endpoints internos protegidos.

### 0.7 Migración de campos extendidos de inventario (2026-10-26)

Una migración aditiva del backend, rama `fix/inventory-extended-fields`, **Pendiente de merge**. Añade a `club_inventory` los campos `condition`, `serial_number`, `purchase_date`, `estimated_value`, `location`, `assigned_to` y `notes`, más dos CHECK. Detalle en `docs/database/SCHEMA-REFERENCE.md`.

| Directorio (`sacdia-backend/prisma/migrations/`) | Usa `CONCURRENTLY` | `development` | `staging` | `production` |
|---|---|---|---|---|
| `20261026130000_inventory_extended_fields` | No | Aplicada (2026-10-26) | **Pendiente** | **Pendiente** |

**Aplicarla antes de desplegar el backend de esa rama** en cada entorno: el código nuevo lee y escribe las columnas, así que sobre una base sin ellas falla. Es compatible con el código anterior (solo `ADD COLUMN` y `ADD CONSTRAINT`; las filas existentes quedan con `condition = 'bueno'`). En `development` el merge del backend ya no necesita aplicarla: `prisma migrate deploy` la encontrará registrada. En `staging` y `production` aplican las reglas del §0.4 y del §0.6 (`production` solo por la promoción `development` → `preproduction` → `main`); recuerda que `staging` ya no está al nivel de `development` mientras esta migración siga pendiente.

---

## 1. Entornos y ramas

> **Hoy** solo la rama `development` está conectada a un entorno en línea (ver sección 0). Lo que sigue es el flujo objetivo, para cuando existan los demás entornos.

Los tres repos runtime siguen el mismo flujo:

```text
development  →  preproduction (QA)  →  main (release)
```

| Rama | Uso |
|---|---|
| `development` | Integración diaria. **Hoy también es el entorno en línea**; base de datos: rama `development` de Neon |
| `preproduction` | QA antes de release |
| `main` | Release |

Reglas:

- Cada entorno tiene su propia base Neon, su propio Redis y sus propios secretos. No compartir `BETTER_AUTH_SECRET`, `QR_JWT_SECRET` ni la base de Redis entre entornos (`.env.example` lo exige para Upstash).
- Se promueve código mergeando `development` → `preproduction` → `main`; las migraciones viajan con el código y se aplican en el deploy.
- La CI de backend y app corre en las tres ramas; la del admin, en sus workflows `build`, `tests` y `typecheck`.

---

## 2. Requisitos

```bash
node --version     # 24.x (backend: engines >=24 <25; CI 24.13.1)
pnpm --version     # 10.x (backend fija pnpm@10.29.3 en packageManager)
flutter --version  # estable; el CI de la app usa 3.41.6
```

Cuentas: Neon, Render, Vercel, Upstash (o Redis compatible con TLS), Cloudflare (R2), Firebase, Google Cloud (OAuth y Maps), Apple Developer, Resend y Sentry.

---

## 3. Neon (PostgreSQL)

1. Crear una base por entorno (o una rama de Neon por entorno).
2. Anotar dos cadenas de conexión:
   - **pooled** (host con `-pooler`): `DATABASE_URL`, la usa la app;
   - **direct** (sin `-pooler`): `DATABASE_DIRECT_URL`, la usan las migraciones (`prisma.config.ts`).
3. En el servicio real ("API Sacdia", Free) las migraciones corren al final del build command (0.1); el `preDeployCommand` del blueprint solo aplica a planes pagos. Para aplicarlas a mano (por ejemplo a `staging` o `production`, con aprobación):

   ```bash
   cd sacdia-backend
   DATABASE_URL="<pooled>" DATABASE_DIRECT_URL="<direct>" pnpm prisma migrate deploy
   ```

   Nunca usar `prisma db push` contra un entorno compartido.

4. Base nueva: cargar catálogos, roles y permisos en este orden (`prisma/seeds/README.md`):

   ```bash
   pnpm prisma db seed                                   # prisma/seed.ts: catálogos y roles
   psql "$DATABASE_URL" -f prisma/seeds/permissions.seed.sql
   psql "$DATABASE_URL" -f prisma/seeds/role-permissions.seed.sql
   ```

   El SQL de grants no crea roles: si `seed.ts` no corrió antes, los grants no se aplican. Los seeds de datos de prueba (`core.ts`, `test-users.seed.ts`) son solo para desarrollo.

---

## 4. Render (backend)

### 4.1 Blueprint

El servicio se define en `sacdia-backend/render.yaml`:

| Campo | Valor |
|---|---|
| Tipo / runtime | `web` / `node` |
| Nombre | `sacdia-backend` |
| Región / plan | `oregon` / `starter` |
| Build | `pnpm install --frozen-lockfile && pnpm prisma generate && pnpm build` |
| Pre-deploy | `pnpm prisma migrate deploy` (aplica migraciones antes de servir tráfico; requiere plan pago, el Free no lo ejecuta) |
| Start | `pnpm start:prod` (`node dist/src/main.js`) |
| Health check | `/api/v1/health` |

Variables fijadas en el blueprint: `NODE_ENV=production`, `TRUST_PROXY_HOPS=1`, `SWAGGER_ENABLED=false`, `AUTH_REJECT_SNAKE_CASE=true`. Las secretas (`sync: false`) se cargan en el dashboard de Render: `ALLOWED_ORIGINS`, `DATABASE_URL`, `BETTER_AUTH_SECRET`, `QR_JWT_SECRET`, `REDIS_URL` y el resto de la tabla 4.2.

> **Solo referencia.** El servicio real ("API Sacdia", Free) no sale de este blueprint y difiere en nombre, plan y comando de arranque (ver 0.1). Usar esta tabla para crear un servicio nuevo, no para describir el actual.

Crear el servicio: Render → New → Blueprint → repo `abn-r/sacdia-backend`, y elegir la rama que despliega cada entorno.

### 4.2 Variables de entorno

Catálogo completo y comentado: `sacdia-backend/.env.example`. Las marcadas como obligatorias impiden el arranque si faltan (`env.validation.ts`).

| Grupo | Variables | Obligatoria en producción |
|---|---|---|
| App | `NODE_ENV`, `PORT` (3000), `TRUST_PROXY_HOPS`, `FRONTEND_URL`, `REQUEST_TIMEOUT_MS`, `LOG_LEVEL`, `LOG_PRETTY` | — |
| CORS y OAuth | `ALLOWED_ORIGINS` (lista separada por comas de orígenes del admin/app), `ALLOWED_OAUTH_REDIRECT_URLS` | `ALLOWED_ORIGINS` sí |
| Seguridad | `SWAGGER_ENABLED` (debe ser `false`), `AUTH_REJECT_SNAKE_CASE`, `BOOTSTRAP_SECRET` (opcional, habilita `POST /admin/rbac/bootstrap-admin`) | — |
| Base de datos | `DATABASE_URL`, `DATABASE_DIRECT_URL`, `DATABASE_APPLICATION_NAME`, `PRISMA_POOL_*` | `DATABASE_URL` sí |
| Auth | `BETTER_AUTH_SECRET` (≥ 32 caracteres), `QR_JWT_SECRET` (≥ 32, distinto del anterior), `BETTER_AUTH_BASE_URL` | Los dos secretos sí |
| OAuth | `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `APPLE_CLIENT_ID`, `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY` | Si se usa el proveedor |
| Redis | `REDIS_URL` (`redis://` o `rediss://`), `CACHE_DEFAULT_TTL_MS`, `CACHE_REDIS_CONNECTION_TIMEOUT_MS` | Sí (cache, rate limit y colas fallan al arrancar sin Redis) |
| R2 | `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_REGION=auto`, `R2_SIGNED_URL_EXPIRES_SECONDS` y, por alias, `R2_BUCKET_*`, `R2_PUBLIC_URL_*`, `R2_KEY_PREFIX_*` | `HONORS_PDF`, `EVIDENCE_FILES`, `INSURANCE_EVIDENCE`, `DATA_EXPORTS`, `MONTHLY_REPORTS` y `RESOURCES_FILES` sí; el resto, al usarse |
| Carga de certificados y OCR | `CERTIFICATE_IMPORT_ALLOWED_FILE_HOSTS`, `OCR_MODE` (`direct` o `remote`), y con `remote`: `OCR_PROXY_URL`, `OCR_PROXY_ENV`, `OCR_PROXY_KID`, `OCR_PROXY_SECRET` | `OCR_MODE` sí en producción; las `OCR_PROXY_*` si es `remote` |
| Observabilidad | `PROCESS_MEMORY_LOG_INTERVAL_MINUTES` (entero ≥ 0, por defecto 15; `0` solo desactiva el intervalo), `POSTHOG_PROJECT_TOKEN`, `POSTHOG_HOST` | — |
| Firebase | `FIREBASE_SERVICE_ACCOUNT_JSON_BASE64` (recomendado) o `FIREBASE_SERVICE_ACCOUNT_JSON` o `FIREBASE_PROJECT_ID` + `FIREBASE_PRIVATE_KEY` + `FIREBASE_CLIENT_EMAIL` | Para push |
| Correo | `EMAIL_ENABLED`, `RESEND_API_KEY`, `RESEND_FROM_EMAIL`, `RESEND_REPLY_TO` | Si `EMAIL_ENABLED=true`, también `RESEND_API_KEY`, `RESEND_FROM_EMAIL` y `REDIS_URL` |
| Perfiles familiares (Fase 3) | `FAMILY_TEEN_LOGIN_ENABLED`, `FAMILY_LINKED_DEVICE_ENABLED`, `FAMILY_DIRECTOR_CREATE_MINOR_ENABLED` (booleanos, por defecto `false`; se leen al arrancar). Ver 0.6 | — |
| Sentry | `SENTRY_DSN`, `SENTRY_RELEASE` (si no se define, se usa `RENDER_GIT_COMMIT`, que inyecta Render) | — |

Buckets, prefijos y acceso de cada alias: `docs/storage/r2-keyprefix-conventions.md`. Operación del correo: `docs/guides/domain-email-operations.md`.

Generar secretos:

```bash
openssl rand -hex 32   # BETTER_AUTH_SECRET
openssl rand -hex 32   # QR_JWT_SECRET (otro valor)
```

> `GOOGLE_VISION_API_KEY` ya no existe en la validación de entorno. El OCR directo usa credenciales por defecto de Google (`GOOGLE_APPLICATION_CREDENTIALS`, `GOOGLE_CLOUD_PROJECT`, `GOOGLE_CLOUD_QUOTA_PROJECT`) y el remoto usa el proxy de Cloud Run (0.3). Ver `docs/guides/google-vision-certificate-ocr.md`.

### 4.3 Verificar

```bash
curl https://<backend>/api/v1/health
# {"status":"ok","timestamp":"..."}
```

En "API Sacdia" (plan Free) la primera llamada tras un periodo inactivo puede tardar por el arranque en frío (0.1); repetirla antes de dar el servicio por caído.

`GET /api/v1/health/details` (solo admin, con JWT) devuelve el estado de base de datos, cache, FCM y Sentry; `status` es `ok` si base de datos y cache responden y `degraded` si no.

---

## 5. Vercel (admin)

1. Vercel → Add New → Project → repo `abn-r/sacdia-admin` (framework Next.js autodetectado).
2. Elegir la rama de cada entorno (por ejemplo, `main` como producción y `preproduction` como preview de QA).
3. Variables:

| Variable | Uso |
|---|---|
| `NEXT_PUBLIC_API_URL` | URL del backend. Acepta `https://<host>`, `https://<host>/api` o `https://<host>/api/v1` (el cliente normaliza a `/api/v1`). Sin valor cae a `http://localhost:3000/api/v1` |
| `NEXT_PUBLIC_APP_URL` | URL pública del admin |
| `NEXT_PUBLIC_GOOGLE_MAPS_API_KEY`, `NEXT_PUBLIC_GOOGLE_MAPS_MAP_ID` | Mapas |
| `NEXT_PUBLIC_SENTRY_DSN` | Sentry (release por `VERCEL_GIT_COMMIT_SHA`, que inyecta Vercel) |
| `NEXT_PUBLIC_POSTHOG_PROJECT_TOKEN`, `NEXT_PUBLIC_POSTHOG_HOST` | Analítica |
| `NEXT_PUBLIC_RBAC_LEGACY_FALLBACK` | Opcional |

4. Añadir el dominio del admin a `ALLOWED_ORIGINS` del backend del mismo entorno.
5. Verificar: la URL debe mostrar el login; tras iniciar sesión, `/dashboard` carga con las cookies `sacdia_admin_access_token` y `sacdia_admin_refresh_token`.

---

## 6. Google OAuth

1. Google Cloud Console → APIs & Services → Credentials → OAuth client ID (Web application).
2. Authorized redirect URIs: la callback de Better Auth en cada backend, `https://<backend>/api/auth/callback/google` (y `http://localhost:3000/api/auth/callback/google` para desarrollo).
3. Cargar `GOOGLE_CLIENT_ID` y `GOOGLE_CLIENT_SECRET` en Render.
4. Pantalla de consentimiento: tipo External, scopes `email`, `profile`, `openid`.
5. Registrar en `ALLOWED_OAUTH_REDIRECT_URLS` las URLs de retorno exactas de admin y app.

## 7. Apple Sign In

Requiere Apple Developer Program.

1. App ID de la app (bundle `com.sacdia.app` en `ios/Runner.xcodeproj`) con "Sign in with Apple".
2. Services ID (es el valor de `APPLE_CLIENT_ID`, no el bundle ID) con dominio del backend y Return URL `https://<backend>/api/auth/callback/apple`.
3. Key de "Sign in with Apple": descargar el `.p8` y anotar el Key ID.
4. Cargar `APPLE_CLIENT_ID`, `APPLE_TEAM_ID`, `APPLE_KEY_ID` y `APPLE_PRIVATE_KEY` (contenido del `.p8`, saltos de línea como `\n`) en Render.

---

## 8. App móvil (Flutter)

La URL del backend se inyecta en compilación; `AppConstants.resolveBaseUrl` lanza error en release si `API_BASE_URL` falta o no es HTTPS.

```bash
cd sacdia-app
flutter pub get

# Android (Play Store)
flutter build appbundle --release \
  --obfuscate --split-debug-info=build/app/outputs/symbols \
  --dart-define=API_BASE_URL=https://<backend>/api/v1 \
  --dart-define=GOOGLE_MAPS_API_KEY=<key> \
  -P GOOGLE_MAPS_API_KEY=<key>

# iOS (App Store / TestFlight)
flutter build ipa --release \
  --dart-define=API_BASE_URL=https://<backend>/api/v1 \
  --dart-define=GOOGLE_MAPS_API_KEY=<key>
```

- Identificadores: Android `applicationId = com.sacdia.app`; iOS `com.sacdia.app`. El esquema de deep link para OAuth es `io.sacdia.app` (`Info.plist`).
- Archivos de Firebase (`android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`) no están en el repo.
- CI (`sacdia-app/.github/workflows/ci.yml`): con los secrets `API_BASE_URL`, `GOOGLE_SERVICES_JSON_BASE64`, `GOOGLE_MAPS_API_KEY` y `ANDROID_KEYSTORE_*` genera el AAB firmado y sube símbolos a Sentry (`SENTRY_AUTH_TOKEN`, `dart run sentry_dart_plugin`). Sin keystore solo genera un APK de verificación firmado con la clave debug.
- Subida: Play Console (Internal testing) y App Store Connect (TestFlight). Antes del envío a tiendas revisar `docs/legal/store-submission-privacy-checklist.md`.

---

## 9. Verificación de extremo a extremo

```bash
API="https://<backend>/api/v1"

curl -s "$API/health"

LOGIN=$(curl -s -X POST "$API/auth/login" -H "Content-Type: application/json" \
  -d '{"email":"<usuario>","password":"<contraseña>"}')
AT=$(echo "$LOGIN" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['accessToken'])")
RT=$(echo "$LOGIN" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['refreshToken'])")

curl -s "$API/auth/me" -H "Authorization: Bearer $AT"
curl -s -X POST "$API/auth/refresh" -H "Content-Type: application/json" -d "{\"refreshToken\":\"$RT\"}"
curl -s -X POST "$API/auth/logout" -H "Authorization: Bearer $AT" -H "Content-Type: application/json" -d "{\"refreshToken\":\"$RT\"}"
curl -s -o /dev/null -w "%{http_code}\n" "$API/auth/me" -H "Authorization: Bearer $AT"   # esperado 401
```

Usuarios de prueba (solo desarrollo): `docs/testing/TEST-USERS.md`.

Checklist:

- [ ] `/api/v1/health` responde `ok` y `/health/details` muestra base de datos y cache OK.
- [ ] Login, `GET /auth/me`, refresh y logout funcionan.
- [ ] El admin inicia sesión y carga `/dashboard`.
- [ ] La app conecta con el `API_BASE_URL` del entorno.
- [ ] Sentry recibe eventos con el release correcto.

---

## 10. Troubleshooting

| Síntoma | Causa probable | Solución |
|---|---|---|
| El arranque falla con error de validación de entorno | Falta una variable obligatoria (por ejemplo `ALLOWED_ORIGINS`, `QR_JWT_SECRET`, un `R2_BUCKET_*` requerido) o `SWAGGER_ENABLED=true` en producción | Revisar el mensaje de Joi y la tabla 4.2 |
| `REDIS_URL is required ... in production` | Producción sin Redis | Configurar `REDIS_URL` del entorno |
| `QR_JWT_SECRET must be distinct from BETTER_AUTH_SECRET` | Mismo valor en ambos | Generar otro secreto |
| Error de Prisma al final del build (`prisma migrate deploy`) | Migración que no aplica sobre la base del entorno | Revisar la migración en local contra una rama de Neon; si el host de `DATABASE_URL` es `-pooler`, confirmar que `DATABASE_DIRECT_URL` exista; no usar `db push` |
| `Property X does not exist on type PrismaService` al compilar | No se generó el cliente | El build del blueprint ya ejecuta `pnpm prisma generate`; en local, `pnpm prisma generate` |
| El registro responde que no existe el rol `user` | Base sin `prisma/seed.ts` | Ejecutar los seeds del §3 |
| `redirect_uri_mismatch` en OAuth | URL de callback no registrada | Añadir `https://<backend>/api/auth/callback/<provider>` en el proveedor |
| `prisma migrate deploy` falla con P3018 / 25001 (`CREATE INDEX CONCURRENTLY cannot run inside a transaction block`) | Migración con `CONCURRENTLY` junto a bloques `DO` | Quitar `CONCURRENTLY` (ver 0.4), dejar la migración re-ejecutable y resolver el registro fallido (P3009) antes de redeplegar |
| El navegador bloquea las llamadas del admin (CORS) | Origen del admin fuera de `ALLOWED_ORIGINS` | Añadirlo y redeplegar |
| La app release se cierra al abrir | Falta `API_BASE_URL` HTTPS en el build | Compilar con `--dart-define=API_BASE_URL=https://...` |
