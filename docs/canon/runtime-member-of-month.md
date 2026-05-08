# Runtime — Miembro del mes (Member of the Month)

**Estado**: ACTIVE
**Autoridad rectora**: `docs/canon/source-of-truth.md`
**Tipo de documento**: runtime canonizado, documented-as-built
**Ámbito**: reconocimiento institucional mensual del miembro con mayor puntaje dentro de una sección de club, evaluación automática por cron, evaluación manual por director y notificación a ganadores + liderazgo

<!-- VERIFICADO contra código 2026-04-22: member-of-month.controller.ts, member-of-month.service.ts, member-of-month-cron.service.ts, schema Prisma y superficie admin multi-sección cruzados con implementación real. -->

---

## 1. Propósito

Canoniza el subsistema de **Miembro del Mes** (MoM) como capa operativa vigente del runtime de SACDIA. Es un acto institucional recurrente que reconoce trayectoria dentro del periodo operativo, alimentado por el scoring semanal (`weekly_record_scores`) y articulado con comunicaciones (notificación al ganador + directores de la sección).

El subsistema es conceptualmente distinto de:
- **achievements** (`docs/canon/runtime-achievements.md`) — logros individuales evaluados por eventos, con tiers estáticos;
- **rankings institucionales** (`docs/canon/runtime-rankings.md`) — clasificación anual de clubes.

MoM es reconocimiento **mensual**, **por sección**, **del miembro**. Tres dimensiones ortogonales a los otros subsistemas.

---

## 2. Alcance canonizado

Dentro del canon:
- contrato de evaluación (automática vs manual);
- política de empates (todos los miembros con el puntaje máximo son ganadores del periodo);
- idempotencia del periodo (borrar e insertar);
- fuente del scoring (`weekly_record_scores`);
- permisos propios del dominio (ver §7);
- emisión de notificaciones a ganadores y directores.

Fuera del canon:
- UI específica (cards, diálogos);
- políticas de comunicación pública (ceremonias, premios físicos);
- integración con rankings de clubes.

---

## 3. Modelo de datos

Modelo `member_of_month` (`sacdia-backend/prisma/schema.prisma:1469-1484`):

| Campo | Tipo | Nota |
|-------|------|------|
| `member_of_month_id` | `int` (autoincrement, PK) | |
| `club_section_id` | `int` | FK a `club_sections` |
| `user_id` | `uuid` | FK a `users` |
| `month` | `int` | 1–12 |
| `year` | `int` | |
| `total_points` | `int` | agregado desde `weekly_record_scores` |
| `notified` | `boolean` | default `false` |
| `created_at` | `timestamptz` | |

Uniqueness: `(club_section_id, user_id, month, year)`. Índice: `(club_section_id, month, year)`.

El modelo es intencionalmente **plano y minimalista**. No existe `evaluated_by`, `evaluated_at`, ni discriminador manual/auto. La evaluación (automática o manual) es indistinguible a nivel de datos — la autoría queda en logs del servidor.

---

## 4. Política de empates

Un periodo `(club_section_id, month, year)` puede tener **múltiples ganadores** si varios miembros tienen el mismo `total_points` máximo. La constraint `@@unique([club_section_id, user_id, month, year])` permite múltiples filas por periodo siempre que sean usuarios distintos.

Regla canonizada: **todos los miembros con el máximo puntaje son ganadores del periodo**. No hay desempate adicional. La decisión es consciente — el reconocimiento institucional no penaliza empates.

---

## 5. Pipeline de evaluación

Servicio: `sacdia-backend/src/member-of-month/member-of-month.service.ts`.

### 5.1 Evaluación automática (cron)

- `sacdia-backend/src/member-of-month/member-of-month-cron.service.ts:24` — `@Cron('5 0 1 * *', { name: 'member-of-month-auto-evaluate', timeZone: 'UTC' })`.
- Ejecuta el día 1 de cada mes a las 00:05 UTC (offset de 5 minutos para evitar race conditions con midnight).
- Llama `runEvaluation(sectionId, month, year)` para el mes anterior, iterando sobre secciones activas en lotes de 10.
- Timeout interno de 5 minutos por corrida; si lo supera, deja log y termina sin propagar error.

### 5.2 Evaluación manual

- Endpoint: `POST /api/v1/clubs/:clubId/sections/:sectionId/member-of-month/evaluate` (`member-of-month.controller.ts:77`).
- Body: `{ month, year }`.
- Guard: `JwtAuthGuard` + `PermissionsGuard` + `@AuthorizationResource({ type: 'club', clubIdParam: 'clubId' })`.
- Validación adicional: `assertIsDirector` (`service.ts:443`) — solo director, sub-director, secretario o directora activos de la sección pueden disparar.
- Rate limit: 5 requests por minuto.

### 5.3 Idempotencia

Tanto la evaluación automática como la manual son **idempotentes**: antes de insertar ganadores, el servicio borra todas las filas existentes para `(club_section_id, month, year)` y reinserta. Esto permite re-ejecutar la evaluación cuando cambien datos de scoring sin estados intermedios.

---

## 6. Fuente del scoring

La agregación se hace sobre `weekly_record_scores` de miembros activos de unidades activas de la sección durante el periodo `(month, year)` (cruce por semana ISO).

Referencia feature: `docs/features/weekly-records.md` + canon `runtime-sacdia.md` §unit operation. El scoring semanal es el eje; MoM es un agregado mensual derivado.

Invariante: cualquier cambio en la agregación de `weekly_record_scores` (fórmula, categorías, caps) impacta directamente el resultado de MoM. Cambios de scoring deben coordinarse con este canon.

---

## 7. Permisos canonizados

Permisos vigentes (dominio propio, migrados desde `units:*` en 2026-04-22):

- `mom:read` — consulta de ganadores vigentes e historial por sección;
- `mom:supervise` — supervisión multi-sección (admin/coordinator field-level+);
- `mom:evaluate` — disparar evaluación manual (mantiene validación adicional de rol director activo en la sección).

Distribución inicial tras migración:
- `mom:read` — todos los roles de club (member, counselor, secretary, treasurer, secretary-treasurer, deputy-director, director) + globales field-level+ (assistant-lf y copias JOIN) + admin/super_admin.
- `mom:evaluate` — mismo listado que `mom:read` excepto `member` (evaluación manual requiere rol con `units:update` histórico).
- `mom:supervise` — solo globales field-level+ (assistant-lf, director-lf, assistant-union, director-union, assistant-dia, director-dia) + admin/super_admin.

El permiso anterior `units:read`/`units:update` ya no rige en los 4 handlers de MoM. La migración es cambio duro (sin compat window) porque el seed otorga `mom:*` a todos los roles que tenían `units:*` antes de que los handlers conmuten — garantizando continuidad de acceso sin ventana de deprecación necesaria.

---

## 8. Superficie API canonizada

| Path | Método | Scope | Permiso |
|------|--------|-------|---------|
| `/clubs/:clubId/sections/:sectionId/member-of-month` | GET | ganador vigente por sección | `mom:read` |
| `/clubs/:clubId/sections/:sectionId/member-of-month/history` | GET | historial paginado | `mom:read` |
| `/clubs/:clubId/sections/:sectionId/member-of-month/evaluate` | POST | evaluación manual | `mom:evaluate` |
| `/member-of-month/admin/list` | GET | supervisión multi-sección (admin/coordinator) | `mom:supervise` |

Scope del endpoint admin: admin/super_admin ve todo; coordinator es forzado a su `local_field_id` derivado via `AuthorizationContextService.resolveUserAuthorization(userId)` (ver `docs/canon/runtime-sla-dashboard.md` §5 por pattern análogo).

---

## 9. Notificaciones canonizadas

Al completar una evaluación (automática o manual), el servicio emite dos comunicaciones visibles vía `NotificationsService` (ver `docs/canon/runtime-communications.md`):

1. notificación al usuario ganador — `notifySafe` o `sendToUser` con `source = 'member-of-month:winner'`;
2. notificación a directores/liderazgo de la sección — `sendToSectionRole` con `source = 'member-of-month:section'`.

Marca `member_of_month.notified = true` tras emitir.

Invariante: los empates emiten una notificación por ganador individual; los directores reciben una sola notificación agregada por sección-periodo.

---

## 10. Admin de supervisión multi-sección

Página: `sacdia-admin/src/app/(dashboard)/dashboard/member-of-month/page.tsx` (agregada 2026-04-22).

- Server Component con `revalidate=60`;
- filtros URL-searchParams: `club_type_id`, `local_field_id`, `club_id`, `section_id`, `year`, `month`, `notified`, `page`;
- tabla con columnas: Miembro, Sección, Tipo, Club, Campo Local, Período, Puntos, Notificado, Acciones;
- acción "Re-evaluar" por fila que reutiliza `EvaluateDialog` existente.

Navegación: entry en nav-config bajo "Solicitudes y Reportes" con icon `Trophy`.

---

## 11. Relación con otros canones

- `docs/canon/runtime-sacdia.md` — scoring semanal como eje operativo.
- `docs/canon/runtime-communications.md` — emisión de notificaciones con `source` trazable.
- `docs/canon/runtime-achievements.md` — sistema de tiers del miembro; distinto subsistema.
- `docs/canon/runtime-rankings.md` — clasificación anual de clubes; distinto subsistema.
- `docs/canon/decisiones-clave.md` — decisión 16 (canonización del dominio MoM).

---

## 12. Invariantes

- ninguna evaluación de MoM puede mutar datos de `weekly_record_scores`; es lector puro del scoring;
- un periodo `(club_section_id, month, year)` puede tener múltiples ganadores por empate — ninguna regla debe forzar desempate;
- la evaluación (auto o manual) es idempotente: borra e inserta; no muta filas existentes ni rechaza re-evaluación;
- la notificación a ganador y liderazgo es obligatoria al completar evaluación; `notified=false` con ganadores presentes indica fallo previo, no un estado operativo válido;
- el `AuthorizationContextService` es la única fuente canónica para derivar scope del coordinador en el endpoint admin;
- los permisos vigentes son `mom:read`, `mom:supervise`, `mom:evaluate` (dominio propio canonizado). Reutilizar `units:*` en nuevos endpoints de MoM rompe la frontera de concerns — si hace falta otro permiso, agregar a `mom:*` o justificar con decisión explícita.
