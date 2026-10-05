# Configuración del sistema (`system_config`)

**Estado**: IMPLEMENTADO
**Verificado contra código**: 2026-10-04 (rama `development`)

## Descripcion de dominio

`system_config` es una tabla clave-valor para parámetros operativos y *feature flags* que se cambian sin desplegar: activar crons, días de vencimiento, topes de puntaje, visibilidad de rankings. Los módulos la leen directamente con Prisma o con `SystemConfigService.get(key)`. Desde el admin solo se editan valores de claves que ya existen.

## Que existe (verificado contra codigo)

### Backend (`src/system-config/`)

Controller con `JwtAuthGuard` + `GlobalRolesGuard` y `@SkipPermissions` (no usa permisos RBAC).

| Método | Ruta (`/api/v1`) | Rol global |
|---|---|---|
| GET | `/system-config` | `admin`, `super-admin` |
| GET | `/system-config/:key` | `admin`, `super-admin` |
| PATCH | `/system-config/:key` | `admin`, `super-admin` |

`admin` admite también `assistant-admin` por alias del guard.

Reglas verificadas:

- `PATCH` solo actualiza `config_value` (texto no vacío, máximo 500 caracteres). No crea claves: si no existe responde `SYSTEM_CONFIG_NOT_FOUND`.
- `config_value` siempre es texto; cada consumidor lo interpreta (`'true'`, número, JSON). `config_type` es descriptivo; el backend no lo valida al escribir.
- `SystemConfigService.get(key)` devuelve `null` si la clave no existe; los consumidores aplican su propio valor por defecto.
- No hay caché: cada lectura va a la base de datos.

### Claves leídas por el código

| Clave | Consumidor | Uso |
|---|---|---|
| `reports.auto_generate_enabled`, `reports.auto_generate_day` | `monthly-reports` | cron de generación del informe mensual |
| `reports.reminders_enabled` | `monthly-reports` | recordatorios de informe mensual |
| `reports.quarterly_auto_generate_enabled`, `reports.annual_auto_generate_enabled` | crons de informes trimestral y anual | ver [informes-trimestrales-anuales.md](informes-trimestrales-anuales.md) |
| `ranking.recalculation_enabled`, `ranking.finance_closing_deadline_day`, `ranking.activities_registered_target` | `annual-folders` (rankings y calculadores de puntaje) | clasificación de clubes |
| `member_ranking.recalculation_enabled`, `member_ranking.member_visibility`, `member_ranking.top_n` | `member-rankings` | ranking de miembros |
| `scoring.category_max_points_cap` (defecto 20) | `scoring-categories` | tope de puntos por categoría |
| `field_payment_orders_v1` (JSON con `local_field_id`), `field_payment_orders.expiry_days` (defecto 15) | `field-payment-orders` | ver [ordenes-de-pago.md](ordenes-de-pago.md) |
| `camporee_orders.expiry_days` | `camporee-orders` | vencimiento de pedidos |
| `notifications.category_settings` | `notifications` | ajustes por categoría de notificación |
| `membership.pending_timeout_days` | `membership-requests` | vencimiento de solicitudes |
| `activity_reminder_minutes_before` | `activities` | recordatorio de actividad |
| `investiture.min_approval_percentage` | `validation` | umbral de requisitos aprobados |

Origen de las filas: `prisma/seeds/system-config.seed.sql` y migraciones (`20260324021443_add_club_enrollments_and_config`, `20260427120000_quarterly_annual_reports`, `20260428000200_ranking_system_config`, `20260429000002_enrollment_rankings_seeds`, `20260601090000_scoring_category_cap`, `20260812220000_field_payment_orders`).

### Admin

- `/dashboard/configuration/variables`: lista las claves y edita su valor (`src/lib/api/system-config.ts`).

### App móvil

- Sin consumo.

### Base de datos

- `system_config`: `config_key` (PK), `config_value`, `description`, `config_type` (por defecto `string`), `updated_at`.

## Gaps y pendientes

- No se registra quién cambió un valor ni el valor anterior.
- No hay validación por tipo: un valor mal escrito (por ejemplo, JSON inválido en `field_payment_orders_v1`) se guarda y falla en el consumidor.
- `investiture.min_monthly_reports` está sembrada pero ningún código la lee en `development`.
- Varias claves leídas por el código no tienen fila sembrada en migraciones ni seeds: `reports.reminders_enabled`, `activity_reminder_minutes_before`, `membership.pending_timeout_days`, `camporee_orders.expiry_days` y `ranking.activities_registered_target`. Sin fila, el consumidor usa su valor por defecto y la clave no aparece en el admin para editarla. `notifications.category_settings` la crea su propio servicio al guardar ajustes.
