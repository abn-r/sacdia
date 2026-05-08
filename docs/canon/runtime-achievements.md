# Runtime — Achievements y sistema de tiers

**Estado**: ACTIVE
**Autoridad rectora**: `docs/canon/source-of-truth.md`
**Tipo de documento**: runtime canonizado, documented-as-built
**Ámbito**: sistema de logros, progresión y niveles (tiers) del miembro

<!-- VERIFICADO contra código 2026-04-22: enums, modelos, controllers, procesador y emisores de eventos cruzados con implementación real. -->

---

## 1. Propósito

Canoniza el sistema de **achievements** como capa operativa vigente del runtime de SACDIA: catálogo de logros, progreso por miembro, evaluación por eventos y niveles (tiers) institucionales.

Se separa conceptualmente del sistema de ranking anual de clubes, que vive en `docs/canon/runtime-rankings.md`. Un achievement es individual y reconoce trayectoria del miembro; un ranking es institucional y compara clubes.

---

## 2. Alcance canonizado

Dentro del canon:
- enums `achievement_tier`, `achievement_type`, `achievement_scope`;
- modelo de datos (`achievements`, `achievement_categories`, `user_achievements`, `achievement_event_log`);
- contrato de evaluación por eventos (journal + BullMQ);
- política de logros secretos;
- integración con scope (GLOBAL, CLUB_TYPE, ECCLESIASTICAL_YEAR).

Fuera del canon:
- UI y textos;
- badges visuales (imagen, íconos);
- políticas comerciales o de gamificación de producto.

Esos aspectos viven en `docs/features/achievements.md` y en los clientes.

---

## 3. Tiers canonizados

Enum `achievement_tier` en `sacdia-backend/prisma/schema.prisma:2244-2250`:

| Tier | Orden | Default |
|------|-------|---------|
| `BRONZE` | 1 | sí |
| `SILVER` | 2 | |
| `GOLD` | 3 | |
| `PLATINUM` | 4 | |
| `DIAMOND` | 5 | |

Reglas:

- el tier es **atributo estático** del achievement, persistido en `achievements.tier` (`schema.prisma:2274`). No se calcula dinámicamente;
- el tier puede editarse vía `PATCH /api/v1/admin/achievements/:achievementId` sin validación de transición. No existe política de congelar tier tras publicación;
- la jerarquía de tiers es ordinal, no otorga privilegios adicionales automáticos;
- la asociación con categorías y scope es ortogonal al tier.

---

## 4. Tipos (`achievement_type`)

Enum en `schema.prisma:2230-2236`:

- `THRESHOLD` — meta numérica simple (ej. 10 actividades);
- `STREAK` — racha consecutiva;
- `COMPOUND` — combinación de múltiples condiciones;
- `MILESTONE` — hito único;
- `COLLECTION` — colección de items.

La evaluación por tipo vive en `sacdia-backend/src/achievements/achievements.processor.ts`. El campo `criteria` (JSON) en `achievements` lleva los parámetros específicos de cada tipo.

---

## 5. Scope (`achievement_scope`)

Enum en `schema.prisma:2238-2242`:

- `GLOBAL` — aplica a cualquier miembro en cualquier contexto;
- `CLUB_TYPE` — acotado al `club_type_id` declarado;
- `ECCLESIASTICAL_YEAR` — acotado al año eclesiástico del progreso.

Interacción:
- `user_achievements.ecclesiastical_year_id` es nullable. Cuando el achievement tiene scope `ECCLESIASTICAL_YEAR`, el progreso se particiona por año;
- el filtrado efectivo por scope ocurre dentro de los handlers de evaluación (`achievements.processor.ts`) usando el campo `criteria`, no en un filtro central del servicio.

---

## 6. Journal de eventos (`achievement_event_log`)

Modelo en `schema.prisma:2326-2339`:

| Campo | Tipo | Nota |
|-------|------|------|
| `event_id` | `Int` (autoincrement, PK) | |
| `user_id` | `uuid` | FK a `users` |
| `event_type` | `varchar(100)` | ej. `activity.attended` |
| `event_payload` | `jsonb` | datos arbitrarios del evento |
| `processed` | `boolean` | default `false` |
| `created_at` | `timestamptz` | |

Índices: `(user_id, event_type, created_at)` y `(processed, created_at)` para drenado de cola pendiente.

Contrato: el journal es **always-on**. Todo evento entrante se persiste antes de intentar el enqueue. Si el backend cae entre persist y evaluación, la cola pendiente puede reprocesarse posteriormente.

---

## 7. Pipeline de evaluación

1. El productor llama a `AchievementsService.recordEvent(...)` desde un feature emisor.
2. El servicio persiste el evento en `achievement_event_log`.
3. El servicio intenta encolar un job en la cola BullMQ `achievements`:
   - nombre de cola: constante `ACHIEVEMENTS_QUEUE = 'achievements'` (`achievements.constants.ts:1`);
   - módulo: `BullModule.registerQueue({ name: ACHIEVEMENTS_QUEUE })` (`achievements.module.ts:32`), registrado condicional según disponibilidad de Redis.
4. Si la cola no está disponible (Redis caído o no configurado), el comportamiento es **degradación documentada** (`achievements.service.ts:69-74`): el evento queda persistido con `processed=false` y el servicio retorna `{ queued: false }`. No hay fallback a evaluación síncrona.
5. El procesador `achievements.processor.ts` consume jobs, resuelve `findMatchingAchievements()` usando `criteria.event` (JSON path + raw SQL COMPOUND), actualiza `user_achievements` y marca `achievement_event_log.processed = true`.

Política canonizada: **el journal es fuente de verdad de lo ocurrido; la cola es el mecanismo de evaluación**. Si la cola se reconstruye, la evaluación puede drenar eventos pendientes por índice `(processed, created_at)`.

---

## 8. Emisores de eventos vigentes

Features del runtime que emiten eventos al journal (fire-and-forget, try/catch sin throw):

| Feature | Archivo | Línea | Evento |
|---------|---------|-------|--------|
| Activities | `sacdia-backend/src/activities/activities.service.ts` | 787 | `activity.attended` |
| Honors | `sacdia-backend/src/honors/honors.service.ts` | 294, 335 | `honor.started` |
| Camporees | `sacdia-backend/src/camporees/camporees.service.ts` | 778 | `camporee.participated` |
| Investiture | `sacdia-backend/src/investiture/investiture.service.ts` | 496 | `class.completed` |
| Evidence review | `sacdia-backend/src/evidence-review/evidence-review.service.ts` | 636 | `honor.validated` |

Cualquier nuevo emisor debe seguir este patrón (persistir → try enqueue → no lanzar en fallo).

---

## 9. Logros secretos

Política en `achievements.controller.ts:30-44` (`maskSecretAchievement`) y `achievements.service.ts:238-240`:

- si `achievements.secret = true` y `user_achievements.completed = false`:
  - `name → '???'`
  - `description → '???'`
  - `badge_image_key → null`
- al completarse (`completed = true`), el masking se levanta y los campos se devuelven reales en el siguiente fetch.

El masking se aplica en la capa de lectura, no en la capa de datos. La tabla `achievements` conserva los valores reales siempre.

---

## 10. Superficie API canonizada

User-facing (JWT requerido):

- `GET /api/v1/achievements` — catálogo agrupado por categoría, paginado, con masking;
- `GET /api/v1/achievements/me` — resumen + logros con progreso;
- `GET /api/v1/achievements/categories` — categorías activas ordenadas por `display_order`;
- `GET /api/v1/achievements/:achievementId` — detalle con progreso y masking.

Admin (JWT + `GlobalRoles(admin|super_admin)` + permiso `achievements:manage`):

- stats, categorías CRUD, achievements CRUD, upload de badge (`POST /:achievementId/image`, multipart, ≤2 MB, PNG/SVG/WebP), evaluación retroactiva.

Contrato exacto vive en `docs/features/achievements.md` y `docs/api/ENDPOINTS-LIVE-REFERENCE.md`.

---

## 11. Relación con otros canones

- `docs/canon/dominio-sacdia.md` — trayectoria institucional del miembro es el eje rector.
- `docs/canon/runtime-rankings.md` — ranking anual de clubes; conceptualmente distinto (institucional, no individual).
- `docs/canon/arquitectura-sacdia.md` — el módulo `achievements` es parte del backend principal.
- `docs/canon/decisiones-clave.md` — decisión 11 (canonización de achievements y tiers).

---

## 12. Invariantes

- ningún evento emitido puede perderse sin persistirse en el journal;
- ningún logro secreto puede filtrar campos reales antes de completarse;
- el tier es atributo del achievement, no del usuario;
- la caída de BullMQ no puede propagarse como error al feature emisor.
