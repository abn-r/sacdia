# Data Guidelines

**Estado**: ACTIVE
**Actualizado**: 2026-10-04

> Reglas de manejo de datos que el código de `development` aplica. Autoridad estructural: `sacdia-backend/prisma/schema.prisma`. Precedencia documental: `docs/canon/source-of-truth.md`.

---

## 1. Modelo y schema

- Motor: PostgreSQL en Neon, accedido solo con Prisma (`@prisma/adapter-pg`).
- Nombres en `snake_case`; PK con nombre propio por tabla (`user_id`, `club_section_id`, `enrollment_id`...), salvo las tablas de Better Auth (`account`, `session`, `verification`), que usan `id`.
- Baja lógica con la columna `active`; no borrar físicamente filas con historial institucional.
- Timestamps `created_at` y `modified_at`/`updated_at` según la tabla; las columnas nuevas de fecha y hora usan `@db.Timestamptz(6)`.
- Catálogos traducibles: tabla `<catálogo>_translations` con FK `ON DELETE CASCADE`, `UNIQUE (<fk>, locale)` y `CHECK ("locale" <> 'es')`. El español vive en la tabla base.
- La sección de club es una sola tabla, `club_sections`, diferenciada por `club_type_id`.
- La verdad anual del cursado es `enrollments`; no crear tablas paralelas de trayectoria.

## 2. Migraciones y seeds

- Todo cambio de schema se hace con `pnpm prisma migrate dev` y se versiona en `prisma/migrations/`.
- En Render las migraciones se aplican con `preDeployCommand: pnpm prisma migrate deploy` antes de servir tráfico. Nunca `prisma db push` contra entornos compartidos.
- `DATABASE_URL` usa el endpoint con pooler de Neon; las migraciones usan `DATABASE_DIRECT_URL`.
- Orden de seeds en base nueva: `prisma/seed.ts` (catálogos y roles) → `permissions.seed.sql` → `role-permissions.seed.sql`. El SQL de grants no crea roles. Detalle en `sacdia-backend/prisma/seeds/README.md`.
- Los seeds de datos de prueba (`core.ts`, `test-users.seed.ts`) son solo para la rama de desarrollo de Neon.

## 3. Validación y sanitización

- Toda entrada pasa por `SanitizePipe` (XSS) y por `I18nValidationPipe` con `whitelist` y `forbidNonWhitelisted`: los campos no declarados en el DTO se rechazan.
- Query params numéricos con `@Type(() => Number)` e `@IsInt()`; IDs UUID con `@IsUUID()`.
- Las variables de entorno se validan al arrancar con Joi (`src/config/env.validation.ts`); una variable obligatoria ausente impide el arranque.

## 4. Consultas

- Usar el query builder de Prisma. `$queryRaw` solo con plantillas etiquetadas (parámetros enlazados).
- `$queryRawUnsafe`/`$executeRawUnsafe` existen en pocos puntos controlados (por ejemplo el folio de `camporee-orders`); no se usan con texto que venga del usuario.
- Operaciones que tocan varias tablas dependientes van en `prisma.$transaction`.
- Listados con `PaginationDto` (`page` ≥ 1, `limit` 1–100, por defecto 20) y respuesta `PaginatedResult` (`data` + `meta`).
- Las consultas lentas se registran como `WARN` en desarrollo a partir de `SLOW_QUERY_WARN_MS` (400 ms).

## 5. Alcance y datos sensibles

- La autorización no termina en el permiso: los servicios validan el recurso real (club dueño, alcance territorial del rol, owner del usuario).
- Datos de salud (alergias, enfermedades, medicamentos, tipo de sangre), contactos de emergencia, representante legal y post-registro son subrecursos sensibles: se resuelven por owner o por permisos específicos.
- Contraseñas: las gestiona Better Auth (tabla `account`); el backend nunca las guarda ni las devuelve en claro.
- Logs: pino elimina (`redact` con `remove: true`) `authorization`, `cookie`, `password`, `refreshToken`, `birthday`, `blood`, `allergies`, `diseases` y `medicines`. No añadir PII nueva a los logs.
- Derechos del titular: exportación de datos propios (`POST /users/me/data-export`, descarga firmada) y borrado de cuenta (`DELETE /auth/me`: baja lógica, anonimización de PII, revocación de sesiones, desactivación de tokens FCM y borrado de la foto en R2).

## 6. Archivos (Cloudflare R2)

- Cada tipo de archivo tiene su alias de bucket y prefijo (`R2_BUCKET_*`, `R2_KEY_PREFIX_*`); convenciones en `docs/storage/r2-keyprefix-conventions.md`.
- Los buckets privados se sirven con URLs firmadas (`R2_SIGNED_URL_EXPIRES_SECONDS`, 300 s por defecto). No exponer la URL pública de un bucket privado.
- Las URLs de archivo que llegan del cliente en la carga masiva de certificados solo se aceptan si su host está en `R2_PUBLIC_URL_*` o en `CERTIFICATE_IMPORT_ALLOWED_FILE_HOSTS`.

## 7. Cache

- Redis con `cache-manager`. Claves por dominio (`cache:catalogs:*`, `auth:context:v7:{userId}`...).
- Toda mutación que cambie datos cacheados invalida su clave (los catálogos tienen además `POST /api/v1/admin/catalogs/cache/invalidate`).
- Los dashboards de analytics usan cache en memoria del proceso (TTL 60 s), no Redis.

## 8. Fechas y zonas horarias

- Las zonas horarias son identificadores IANA (`local_fields.timezone`, `local_camporees.timezone`). La CI verifica la versión de tzdata (`pnpm verify:iana-timezones`).
- La semana de puntaje de unidades es domingo 00:00 a sábado 23:59 en `America/Mexico_City` (`docs/canon/decisiones-clave.md` §25).
- El periodo operativo es el año eclesiástico (`ecclesiastical_year_id`).

## 9. Servicios externos

- Correo (Resend), push (FCM) y OCR (Google Vision) pasan por servicios del backend con reintentos en BullMQ; un fallo externo no rompe la operación principal.
- El OCR propone datos; la persona confirma y el campo local valida. Nunca se escribe un dato institucional solo a partir del OCR.
- Si se añade un proveedor que recibe datos personales, actualizar `docs/legal/aviso-de-privacidad.md` y `docs/legal/store-submission-privacy-checklist.md`.
