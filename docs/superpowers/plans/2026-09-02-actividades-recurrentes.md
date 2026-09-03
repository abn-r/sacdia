# Actividades recurrentes — Implementation Plan

> **For agentic workers:** Execute inline in this session. Spec: `docs/superpowers/specs/2026-09-02-actividades-recurrentes-design.md`. No ramas nuevas. No commits salvo pedido del usuario. No `pnpm build` salvo pedido.

**Goal:** Crear N actividades independientes desde una receta (cada N días o un día de la semana), agrupadas en `activity_series`, en admin y app, con el diseño existente.

**Architecture:** Cabecera `activity_series` + copias `activities.activity_series_id`. Expansión pura de fechas (`activity-series-dates.ts`). `POST /activities` no cambia. Interruptor “Repetir” apagado por defecto.

**Tech Stack:** NestJS + Prisma, Next.js 16 + shadcn, Flutter + Riverpod + widgets `Sac*`.

---

## Files

### Backend
- Create: `sacdia-backend/src/activities/activity-series-dates.ts`
- Create: `sacdia-backend/src/activities/activity-series-dates.spec.ts`
- Create: `sacdia-backend/src/activities/activity-series.service.ts` (si el service de activities supera ~1200 líneas; si no, métodos en `activities.service.ts`)
- Create: `sacdia-backend/prisma/migrations/20260902180000_activity_series/migration.sql`
- Modify: `sacdia-backend/prisma/schema.prisma` (`activity_series`, `activity_series_sections`, FK en `activities`)
- Modify: `sacdia-backend/src/activities/dto/activities.dto.ts`
- Modify: `sacdia-backend/src/activities/activities.service.ts`
- Modify: `sacdia-backend/src/activities/activities.controller.ts`
- Modify: `sacdia-backend/src/activities/activities.service.spec.ts`
- Modify: `sacdia-backend/src/common/errors/error-codes.ts`
- Modify: `sacdia-backend/src/i18n/{en,es,fr,pt-BR}/errors.json`
- Modify: `sacdia-backend/src/common/decorators/authorization-resource.decorator.ts`
- Modify: `sacdia-backend/src/common/guards/permissions.guard.ts`

### Admin
- Modify: `sacdia-admin/src/lib/api/activities.ts`
- Modify: `sacdia-admin/src/lib/activities/helpers.ts`
- Modify: `sacdia-admin/src/components/activities/activity-form-dialog.tsx`
- Modify: `sacdia-admin/src/components/activities/activity-detail-actions.tsx`
- Modify: `sacdia-admin/src/app/(dashboard)/dashboard/clubs/activities/[id]/page.tsx`
- Modify: `sacdia-admin/src/app/(dashboard)/dashboard/clubs/activities/page.tsx` (query `seriesId`)
- Modify: `sacdia-admin/messages/{es,en,fr,pt-BR}.json`
- Create: `sacdia-admin/src/components/activities/activity-series-preview.tsx`

### App
- Modify: `sacdia-app/lib/core/constants/api_endpoints.dart`
- Modify: data/domain/presentation de `lib/features/activities/`
- Modify: `create_activity_view.dart`, `activity_detail_view.dart`, list widgets
- Tests de use case si el módulo ya los tiene

### Docs (mismo trabajo)
- `docs/features/actividades.md`
- `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- `docs/api/FRONTEND-INTEGRATION-GUIDE.md`
- `docs/database/SCHEMA-REFERENCE.md` + `docs/database/schema.prisma` si se mantiene copia

---

### Task 1: Expansión de fechas (puro)

- [ ] Tests en `activity-series-dates.spec.ts`: domingos inclusive; cada 3 días; miércoles→primer domingo; 0 fechas; tope 366; `calendarDateInTimeZone`.
- [ ] Implementar `expandActivitySeriesDates`, `isoWeekday`, `addCalendarDays`, constantes timezone y max 366.

### Task 2: Schema + errores

- [ ] Tablas `activity_series` y `activity_series_sections`; `activities.activity_series_id`; unique parcial `(activity_series_id, activity_date)`.
- [ ] `ErrorCode.ACTIVITY_SERIES_*` + i18n 4 locales.

### Task 3: API

- [ ] DTOs: `RecurrenceDto`, `CreateActivitySeriesDto` (campos de create + recurrence), `ExtendActivitySeriesDto`.
- [ ] `ActivityFiltersDto.seriesId`.
- [ ] Service: preview, create (transacción), get, cancel-future, extend. 1 notificación y 1 invalidación por sección.
- [ ] Controller + ClubRoles + permisos según spec.
- [ ] Guard `activity_series` resolviendo secciones de la cabecera (conjunta = joint scope).
- [ ] Tests de service con Prisma mockeado.

### Task 4: Admin UI

- [ ] Fecha de primera sesión en el formulario de crear (hoy faltaba `activity_date`).
- [ ] Switch “Repetir esta actividad” (shadcn `Switch`), default off. On: kind, N o weekday, until (default fin de año eclesiástico vía `getCurrentEcclesiasticalYear`), preview, botón “Crear N actividades”.
- [ ] Detalle: badge serie + ver serie (`?seriesId=`) + cancelar futuras + extender.
- [ ] Copy next-intl, español neutro, tokens SACDIA (`primary` coral, `Sac` no aplica; shadcn + PageHeader/Badge).
- [ ] Verificar en navegador el flujo crear suelta / crear serie / detalle.

### Task 5: App UI

- [ ] Mismo interruptor con widgets `Sac*` / `SwitchListTile` alineado al toggle conjunta.
- [ ] Preview sheet antes de persistir. Detalle: acciones de serie. Badge en lista.
- [ ] `firstDate` del date picker = hoy; `lastDate` = fin de año eclesiástico si el catálogo está en memoria.

### Task 6: Docs

- [ ] Actualizar features/API/database. Aclarar que `activity_instances` no es recurrencia.

---

## Notas de diseño UI

- Interruptor apagado: el formulario no menciona series.
- Preview: lista compacta de fechas (scroll, primeras/últimas + conteo), no un muro de 52 cards.
- Badge `Serie` con variant `soft` / color secondary verde, no púrpura.
- Confirmación destructiva para cancelar futuras (`AlertDialog`).
- Touch targets 44px en app; labels encima de inputs.
