# Runtime — SLA dashboard (analíticas operacionales)

**Estado**: ACTIVE
**Autoridad rectora**: `docs/canon/source-of-truth.md`
**Tipo de documento**: runtime canonizado, documented-as-built
**Ámbito**: panel unificado de métricas operacionales de SLA sobre pipelines de aprobación y validación del sistema (investiduras, validación, camporees)

<!-- VERIFICADO contra código 2026-04-22: analytics.controller.ts, analytics.service.ts, sla-dashboard.dto.ts, admin page y componentes SLA cruzados con implementación real. -->

---

## 1. Propósito

Canoniza el **SLA dashboard** como capa de analíticas operacionales centralizada para coordinadores y administradores. Agrega métricas de pendientes, overdue, tiempos promedio, tasas de aprobación y throughput sobre tres pipelines del runtime (investiduras, validación de clases/honores y camporees) en un único endpoint con cache, sin introducir tablas dedicadas.

No es un sistema de monitoreo de infraestructura ni un reemplazo para observabilidad (logs, métricas de proceso). Es una superficie de producto para el rol de coordinación institucional.

---

## 2. Alcance canonizado

Dentro del canon:
- endpoint único `GET /api/v1/admin/analytics/sla-dashboard`;
- módulo independiente `AnalyticsModule` y `AnalyticsService`;
- política de cache in-memory con TTL;
- cobertura de 3 pipelines (investiture, validation, camporee);
- scoping por `local_field_id` del coordinador vs vista global del admin;
- ventanas temporales canonizadas (30/90 días, 12 semanas).

Fuera del canon:
- gráficos específicos, iconografía o layout de la página admin;
- alertas, exportaciones o drill-downs (no implementados todavía);
- vista móvil (no existe).

---

## 3. Arquitectura

- módulo: `AnalyticsModule` en `sacdia-backend/src/analytics/` — separado de los módulos operacionales (investiture, validation, camporees) para evitar acoplamiento inverso;
- service: `AnalyticsService` (`analytics.service.ts:46-631`);
- controller: `AnalyticsController` (`analytics.controller.ts:25-49`);
- DTO: `SlaDashboardDto` (`sacdia-backend/src/analytics/dto/sla-dashboard.dto.ts:177-225`).

Decisión estructural: el módulo lee de tablas existentes (enrollments, investiture_validation_history, class_section_progress, users_honors, camporee_*) sin introducir persistencia propia. Todas las métricas son **calculadas on-demand con cache**.

---

## 4. Superficie API canonizada

Endpoint único:

- `GET /api/v1/admin/analytics/sla-dashboard`;
- guards: `JwtAuthGuard`, `GlobalRolesGuard`;
- roles permitidos: `admin`, `coordinator`;
- query params: ninguno (el scope se deriva del usuario autenticado);
- response shape: `{ status: "ok", data: SlaDashboardDto }`.

El DTO raíz (`SlaDashboardDto`) lleva:

- `investiture: InvestitureSummaryDto` — pendientes, in_review, overdue, pipeline breakdown;
- `validation: ValidationSummaryDto` — class_sections_pending + honors_pending + total;
- `camporee: CamporeeSummaryDto` — clubs_pending, members_pending, payments_pending;
- `timing: TimingMetricsDto` — avg días por etapa (submit, club, coordinator, field approval) + total;
- `throughput: ThroughputWeekDto[]` — 12 semanas con approved/rejected por semana;
- `approval_rate: ApprovalRateDto` — porcentaje sobre últimos 90 días;
- `computed_at: string` (ISO);
- `cached: boolean`.

---

## 5. Política de scope

- **Coordinador**: las métricas se filtran por `local_field_id` de su asignación activa. No ve datos de otros campos locales;
- **Admin**: ve vista global (agregada sobre todos los campos locales);
- **Otros roles**: no admitidos; `GlobalRolesGuard` bloquea.

El scope se deriva del JWT + asignaciones del usuario (`club_role_assignments` / global roles), no de query params. Esto evita que un coordinador pueda solicitar datos de otro campo manipulando la URL.

---

## 6. Política de cache

- **Tipo**: cache in-memory (Map) dentro del `AnalyticsService`. **No usa Redis**.
- **TTL**: `CACHE_TTL_MS = 60_000` (60 segundos, `analytics.service.ts:49`).
- **Clave**: `local_field_id` o `'global'` para admins.
- **Evicción**: eviction automática cuando el Map supera 50 entradas (`analytics.service.ts:50`).
- **Consecuencia de múltiples instancias**: cada instancia mantiene su propio cache. No hay coordinación entre nodos — un admin puede recibir respuestas con `computed_at` hasta 60s de antigüedad según la instancia que responde. Aceptable por diseño: el dashboard no requiere consistencia fuerte.

---

## 7. Ventanas temporales canonizadas

| Métrica | Ventana | Fuente |
|---------|---------|--------|
| Overdue investiture | `submitted_at < now() - 30 días` sin `field_approved` | `enrollments` + `investiture_validation_history` |
| Approval rate | últimos 90 días | `investiture_validation_history` |
| Throughput | últimas 12 semanas (84 días) | agregado por semana ISO |
| Timing metrics | sobre pipeline cerrado (submit → field approved) | LAG + EXTRACT en SQL |

Estas ventanas son constantes del código (`analytics.service.ts:107-109`). Cualquier cambio debe reflejarse aquí y en `docs/features/sla-dashboard.md`.

---

## 8. Cobertura de pipelines

### 8.1 Investiture
- estados pendientes: `PENDING_STATUSES` (`analytics.service.ts:30-36`);
- estados en revisión: `IN_REVIEW_STATUSES` (línea 39-43);
- fuente timing: `investiture_validation_history` con enum de acciones (`SUBMITTED`, `CLUB_APPROVED`, `COORDINATOR_APPROVED`, `FIELD_APPROVED`, `REJECTED`, `INVESTIDO`);
- pipeline breakdown por status con counts.

### 8.2 Validation
- `class_sections_pending`: `class_section_progress.status = PENDING`;
- `honors_pending`: `users_honors.validation_status = PENDING_REVIEW`;
- total = suma de ambos.

### 8.3 Camporee
- `clubs_pending`: `camporee_clubs.status = 'registered'`;
- `members_pending`: `camporee_members.status = 'registered'`;
- `payments_pending`: `camporee_payments.status = 'registered'`.

Todos los conteos respetan el scope del caller (ver §5).

---

## 9. Fuentes de datos canonizadas

Tablas leídas, sin mutación:

- `enrollments` (`schema.prisma:456`) — estado de investidura, `submitted_at`;
- `investiture_validation_history` (`schema.prisma:1347`) — audit trail para timing y throughput;
- `class_section_progress` (`schema.prisma:191`);
- `users_honors` (`schema.prisma:1527`);
- `camporee_clubs`, `camporee_members`, `camporee_payments`;
- `club_role_assignments` — derivación de scope.

Invariante: **el SLA dashboard nunca muta datos**. Es un lector puro. Cualquier acción correctiva sobre items pendientes se hace desde su pipeline operacional.

---

## 10. Cliente (admin)

- página: `sacdia-admin/src/app/(dashboard)/dashboard/sla/page.tsx`;
- guard: `requireAdminUser()` server-side;
- revalidación: `export const revalidate = 60` (alineado con el TTL del backend);
- fetch: Server Component via `getSlaDashboard()` en `sacdia-admin/src/lib/api/analytics.ts:63-68`;
- componentes: `SlaDashboardClient`, `SlaRefreshButton`, `SlaStatCards`, `SlaPipelineChart`, `SlaThroughputChart`, `SlaValidationCard`, `SlaCamporeeCard`.

No existe vista SLA en la app móvil (Flutter). Si se requiere en el futuro, corresponde evaluarse como feature separada.

---

## 11. Relación con otros canones

- `docs/canon/runtime-sacdia.md` — topología general del runtime;
- `docs/canon/runtime-communications.md` — el SLA no emite notificaciones automáticas hoy; si se agregan alertas, respetar el canon de comunicaciones;
- `docs/canon/dominio-sacdia.md` — validación institucional es un acto distinto del registro (decisión §6);
- `docs/canon/decisiones-clave.md` — decisión 15 (SLA dashboard canonizado).

---

## 12. Invariantes

- el SLA dashboard nunca muta datos de los pipelines que observa;
- el scope del coordinador se deriva del JWT, nunca de query params manipulables;
- el cache in-memory con TTL 60s es aceptable; no debe migrarse a Redis sin evaluar beneficio real;
- las ventanas temporales (30d overdue, 90d approval rate, 12w throughput) son canon — cambios requieren actualizar este documento y `docs/features/sla-dashboard.md`;
- ninguna métrica puede calcularse a partir de una tabla `sla_*` dedicada; el subsistema permanece como lector puro de datos operacionales existentes;
- roles admitidos: solo `admin` y `coordinator`; cualquier otro acceso debe rechazarse en el guard.
