# i18n Strings Inventory — Fase 0

**Fecha auditoría**: 2026-04-23
**Scope**: sacdia-backend, sacdia-admin, sacdia-app
**Autoridad rectora**: [docs/plans/i18n-multilenguaje-roadmap.md](../plans/i18n-multilenguaje-roadmap.md)

## Resumen ejecutivo

- **Total strings con acentos detectados (proxy conservador)**: ~2,565
  - `sacdia-backend/src`: 975 strings en 149 archivos
  - `sacdia-admin/src`: 704 strings en 185 archivos
  - `sacdia-app/lib`: 886 strings en 201 archivos
- Volumen real migrable **estimado mayor** (~3,500-4,500) porque el grep por acentos subestima. Strings sin acentos (ej. "Login", "Guardar", "Club") no entran en este proxy — se detectan por anclas en secciones dedicadas.
- **Ya traducidos (es-MX / es-ES / en-US parcial)**: 17 claves en `sacdia-admin/src/lib/i18n/messages.ts` (solo pantalla de login). Descontables de Fase 1.
- **Drift detectado**: backend mezcla errores en ES y EN en el mismo archivo (ver discoveries).

## Metodología

### Patterns usados
1. Strings con acentos/ñ: `['\"\`][^'\"\`]*[áéíóúñÁÉÍÓÚÑ][^'\"\`]*['\"\`]`
2. Decoradores Swagger `@ApiOperation`, `@ApiProperty` con `summary` / `description`.
3. `throw new *Exception('...')` en backend.
4. `toast.error/success(...)` en admin.
5. `Text('...')`, `title:`, `labelText:`, `SnackBar` en Flutter.
6. Densidad por archivo con `rg -c | sort -rn`.

### Falsos positivos descartados
- Nombres de variables / keys / enum values (`'pendiente'` como status enum — decisión separada).
- Comentarios `//`, `/* */`, `///` — excluidos con filtros `rg -v`.
- Tests (`.spec.ts`, `_test.dart`, `__mocks__/`) — filtrados.
- Doc strings `*.md`, scripts, prisma, seeds — fuera de scope.

### Límites del audit
- El proxy por acentos **subestima** el volumen real (30-40% de strings UI son sin acentos).
- No cuenta plurales/interpolaciones duplicados (ej. `${count} miembros` vs `un miembro`).
- No verifica **calidad** de la traducción; solo presencia.
- Catálogos institucionales en DB (`club_types.name`, `ecclesiastical_years.name`) — descartados por decisión pendiente del roadmap.
- Swagger decorators contados aparte (descriptores API, no UI end-user).

---

## Backend (sacdia-backend)

**Total**: ~975 strings ES en 149 archivos (proxy acentos). Exceptions totales: 696 (mixto ES/EN).

### Error messages & validation

| File | Density | Surface |
|------|--------:|---------|
| `src/camporees/camporees.service.ts` | 22 exceptions | BadRequest/NotFound validation |
| `src/evidence-review/evidence-review.service.ts` | 16 exceptions | Validación evidencias |
| `src/admin/admin-reference.service.ts` | 16 exceptions | Admin CRUD |
| `src/rbac/rbac.service.ts` | 15 exceptions | RBAC validation |
| `src/admin/admin-geography.service.ts` | 15 exceptions | Geography admin |
| `src/insurance/insurance.service.ts` | 12 exceptions | Insurance flow |
| `src/auth/auth.service.ts` | 11 exceptions | Login/register |
| `src/activities/activities.service.ts` | 10 exceptions | Activities CRUD |
| `src/users/users.service.ts` | 9 exceptions | User CRUD |
| `src/common/guards/permissions.guard.ts` | 9 exceptions | Authorization errors |
| `src/better-auth/better-auth.service.ts` | 9 exceptions | BetterAuth bridge |
| `src/scoring-categories/scoring-categories.service.ts` | 8 exceptions | CRUD |
| `src/legal-representatives/legal-representatives.service.ts` | 8 exceptions | Legal reps |
| `src/folders/evidence-folder.service.ts` | 8 exceptions | Folders |
| `src/resources/resources.service.ts` | 7 exceptions | Resources |

**Samples**:
- `throw new BadRequestException('El honor ya se encuentra validado')` — `src/validation/validation.service.ts:149`
- `throw new NotFoundException('Clase no encontrada')` — `src/classes/classes.service.ts:228`
- `throw new NotFoundException(\`Class with ID ${classId} not found\`)` — **EN** `src/classes/classes.service.ts:199`

### Swagger API descriptions (controllers)

| File | Density | Surface |
|------|--------:|---------|
| `src/camporees/camporees.controller.ts` | 91 strings | API docs |
| `src/investiture/investiture.controller.ts` | 49 | API docs |
| `src/scoring-categories/scoring-categories.controller.ts` | 37 | API docs |
| `src/certifications/certifications.controller.ts` | 30 | API docs |
| `src/catalogs/catalogs.controller.ts` | 25 | API docs |
| `src/auth/auth.controller.ts` | 22 | API docs |

**Nota**: 48 decoradores Swagger con `summary` en español. Total `@ApiOperation/@ApiProperty`: 3,247 — mayoría dev-facing. **Recomendación**: dejar en inglés técnico (convención Swagger/OpenAPI) o mantener en ES; NO priorizar Fase 1.

### Notification templates (push + email)

| File | Line | Sample | Surface |
|------|-----:|--------|---------|
| `src/activities/activities-reminder.service.ts` | 128 | `title: 'Recordatorio de actividad'` | Push title |
| `src/activities/activities-reminder.service.ts` | 129 | `body: \`${activity.name} comienza a las ${activity.activity_time}\`` | Push body (interpolado) |
| `src/dashboard/dashboard.controller.ts` | 41 | `title: 'Campamento de Verano'` | Seed data — ignorar |

**Hallazgo**: **la mayoría de títulos/bodies se construyen en los callers** (ej. `membership-requests.service.ts`, `activities.service.ts`) via argumentos a `NotificationsService.sendNotification()`. La API service en sí no contiene strings hardcoded. **Volumen bajo**: <10 templates hardcoded; migración sencilla.

### Logs & observability

Total backend logs con acentos: 1 caso detectado (INFO/WARN/ERROR). **Casi todos los logs están en inglés** — descartable para Fase 1. Ejemplo ES encontrado:
- `src/notifications/notifications.processor.ts` — logs mayormente EN, drift menor.

### PDFs

| File | Strings ES | Surface |
|------|-----------:|---------|
| `src/monthly-reports/monthly-reports-pdf.service.ts` | ~35+ | PDF informe mensual (labels, headers, secciones) |

**Samples**:
- `'INFORME MENSUAL DEL CLUB'` (línea 273)
- `'Club de ${clubType}'` (284), `'Distrito: '` (295), `'Iglesia: '` (298), `'Directiva:'` (350), `'No hay directiva registrada'` (359), `'Juntas y reuniones:'` (379), `'Especialidades iniciadas este mes'` (408), `'Bautizados este mes'` (623), `'Participacion del club:'` (656), `'Balance del mes'` (559).
- Subject email: `'Informe Mensual del Club'` (194).

**Total en este archivo ~60 strings UI-like (labels + headers + subjects)**. Alto esfuerzo relativo (requiere fuentes con tildes en PDF engine).

---

## Admin (sacdia-admin)

**Total**: ~704 strings ES en 185 archivos.
- `src/app/` (pages): 151 strings
- `src/components/`: 345 strings
- `src/lib/`: 150 strings (actions, permissions, entities)
- `src/hooks/`: marginal

### UI labels (JSX inline + config)

Detectadas **159 strings** en JSX `>texto<` + **132 strings** en props estructurados (`label:`, `title:`, `placeholder:`, `description:`).

| File | Strings | Surface |
|------|--------:|---------|
| `src/components/layout/nav-config.ts` | 19 | Sidebar/nav labels |
| `src/lib/auth/permissions.ts` | 41 | RBAC permission human-readable labels |
| `src/lib/catalogs/entities.ts` | 32 | Catalog entity display names |
| `src/app/(dashboard)/dashboard/catalogs/page.tsx` | 16 | Catalogs landing page |
| `src/components/finances/transaction-form-dialog.tsx` | 18 | Transaction form labels |
| `src/components/investiture/config-form-dialog.tsx` | 17 | Investiture config form |
| `src/components/resources/resources-crud-page.tsx` | 17 | Resources CRUD copy |
| `src/components/insurance/expiring-dashboard.tsx` | 11 | Insurance dashboard |
| `src/components/annual-folders/templates-client-page.tsx` | 10 | Annual folder templates |
| `src/app/(dashboard)/dashboard/classes/[classId]/page.tsx` | 9 | Class detail page |

### Toast/error messages

- Total `toast.*()` calls: 235
- Con texto Spanish-ES detectado: 33 (acentos); +muchos sin acentos (ej. `toast.success("Seguro actualizado correctamente")`, `"Guardar"`, `"Datos actualizados."`).
- Pattern helper: `getActionErrorMessage(error, "No se pudo enviar la notificación", ...)` — fallback messages hardcoded en `src/lib/*/actions.ts`.

**Samples**:
- `src/components/reports/report-detail-client.tsx:163` — `toast.success("Reporte generado correctamente. Los datos quedaron congelados.")`
- `src/components/insurance/delete-insurance-dialog.tsx:52` — `toast.success("Seguro desactivado correctamente")`
- `src/components/finances/transaction-form-dialog.tsx:123` — `toast.error("No se pudieron cargar las categorías")`
- Densidad alta en: `src/lib/notifications/actions.ts`, `src/lib/clubs/actions.ts`, `src/lib/honor-categories/actions.ts`, `src/lib/achievements/actions.ts`.

### Form validation (Zod)

Patterns `z.string().min/max/email/regex(..., { message: "..." })`: **10+ casos** con ES.

**Samples**:
- `src/components/evidence-review/evidence-reject-dialog.tsx:27` — `.max(1000, "Máximo 1000 caracteres")`
- `src/components/investiture/config-form-dialog.tsx:43` — `.min(1, "Seleccioná un campo local")`
- `src/components/system-config/system-config-edit-dialog.tsx:26` — `z.string().min(1, "El valor no puede estar vacío")`
- `src/components/camporees/union-camporee-form-dialog.tsx:40` — `.min(1, "La unión es obligatoria")`

**Nota**: voseo rioplatense mezclado (`Seleccioná`, `Ingresá`) con imperativo neutro (`Máximo`, `Seleccione`) — inconsistente. Recomendación: normalizar antes de Fase 1.

### Ya traducido (parcial — fuera de scope Fase 1)

- `src/lib/i18n/messages.ts` (68 líneas) — solo **17 claves de login**:
  - `login_brand_subtitle`, `login_panel_description`, `login_panel_feature_1-3`, `login_welcome_title`, `login_welcome_description`, `login_security_badge`, `login_email_label`, `login_password_label`, `login_password_hint`, `login_submit_idle`, `login_submit_loading`, `login_show_password`, `login_hide_password`, `login_access_notice`, `login_footer`.
- Locales: `es-MX`, `es-ES`, `en-US` (100% cobertura en estas 17 claves).
- `src/lib/i18n/locale.ts` — normalizador de locales (11 líneas).
- `src/lib/i18n/client.ts` — `getLocale` helper (hardcoded default?).

**Brecha**: el resto del admin (>99% de strings UI) **no usa este catálogo**. No hay convención adoptada.

---

## App (sacdia-app Flutter)

**Total**: ~886 strings ES en 201 archivos.
- `lib/features/`: 809 (96% del volumen)
- `lib/core/`: 71
- `lib/shared/`: 6

`flutter_localizations` y `intl ^0.20.1` declarados en `pubspec.yaml` pero **sin catálogo ARB ni `l10n.yaml`**. `main.dart` sin `supportedLocales` / `localizationsDelegates`. Efectivamente **monolenguaje hardcoded**.

### Screen titles & widget labels

- `Text('...')` con Spanish: **38 casos** con acentos (muchos más sin acentos).
- Props `title:`, `label:`, `hint:`, `labelText:`, `appBar:`: **147 casos** con acentos.

| File | Strings | Surface |
|------|--------:|---------|
| `lib/features/auth/data/datasources/auth_remote_data_source.dart` | 29 | Auth exceptions + logs |
| `lib/features/profile/presentation/views/settings_view.dart` | 23 | Settings screen + password change dialog |
| `lib/features/inventory/presentation/views/add_inventory_item_sheet.dart` | 21 | Inventory form |
| `lib/features/honors/data/datasources/honors_remote_data_source.dart` | 21 | Honors API error messages |
| `lib/features/profile/data/datasources/data_export_remote_data_source.dart` | 16 | Data export flow |
| `lib/features/post_registration/presentation/views/club_selection_step_view.dart` | 14 | Post-register step |
| `lib/features/honors/presentation/views/honor_detail_view.dart` | 14 | Honor detail |
| `lib/features/club/presentation/views/club_view.dart` | 14 | Club view |
| `lib/features/enrollment/presentation/views/enrollment_form_view.dart` | 13 | Enrollment form |
| `lib/features/auth/presentation/providers/auth_providers.dart` | 13 | Auth error mapping |
| `lib/features/profile/presentation/views/active_sessions_view.dart` | 11 | Sessions list |
| `lib/features/members/presentation/views/member_profile_view.dart` | 11 | Member profile |
| `lib/features/activities/data/datasources/activities_remote_data_source.dart` | 11 | Activities API |
| `lib/core/notifications/push_notification_service.dart` | 11 | Push notif routing messages |

### Dialog & error messages

- `SnackBar / showDialog / AlertDialog`: ~4 directos con acentos — la mayoría usan widgets custom (`ErrorSnackBar`, helpers). Verificar en `shared/presentation/widgets/`.
- `ServerException(message: '...')`: **29 casos** con ES.
  - Ej. `'Error al obtener años eclesiásticos'` (catalogs_remote_data_source.dart:184).
  - Ej. `'Error de conexión'` (repetido 5+ veces).
- `AuthException(message: 'No se recibió ID de usuario')`, `'Respuesta del servidor inválida'`, `'Token inválido'`, `'No hay sesión activa'` — auth_remote_data_source.dart.

### Push notification content (client-side)

- `lib/core/notifications/push_notification_service.dart` — 11 strings con acentos: mensajes de log + messages de error routing (ej. `'Ruta de notificación rechazada (no está en el allowlist): "$route"'`, `'Tipo de notificación no manejado: $type'`).
- **Payload real** (título + body) viene del **backend** (FCM), no de Flutter. Flutter solo renderiza.
- `firebase_options.dart:23,37` — error msgs `'DefaultFirebaseOptions no está configurado...'` (cold error, raro user-facing).

---

## Priorización Fase 1 (recomendada)

| Surface | Volume (estimado) | Esfuerzo | Recomendación |
|---------|------------------:|----------|---------------|
| Admin UI labels (nav + pages + components) | ~500-700 | Alto | **Migrate first** — mayor superficie user-facing, ya hay andamiaje `next-intl` parcial |
| App Flutter screen labels (features/) | ~700-900 | Alto | Migrate segundo batch — requiere adoptar `easy_localization` o `flutter_gen_l10n` desde cero |
| Backend error messages (exceptions) | ~400-500 | Medio | Migrate tercer batch — decidir strategy (Accept-Language vs client-side mapping) |
| App Flutter error messages (Exceptions) | ~50-80 | Bajo | Quick win — alineado con backend strategy |
| Admin toast messages | ~100-150 | Bajo | Quick win — 235 toast calls, ~50% Spanish |
| PDF templates (monthly report) | ~60 | Alto | **Migrate last** — requiere font loading, no bloqueante para pt-BR admin |
| Push notification templates (backend) | ~10 | Bajo | Muy bajo volumen — migrate junto con backend errors |
| Swagger `@ApiOperation` descriptions | ~48 | N/A | **No migrar** — dev-facing API docs, mantener en ES o cambiar a EN técnico |
| Zod validation messages (admin) | ~40-60 | Bajo | Quick win — batch con form labels |
| Logs backend | ~1 | N/A | **Descartar** — ya en EN |

---

## Decisiones pendientes

1. **Catálogos institucionales** (`club_types.name`, `section_types`, `ecclesiastical_years`): ¿traducir en DB (columnas `name_es`, `name_pt`, `name_en`) o en client-side mapping? Ver roadmap §4.
2. **Locale prioritario post-ES**: `pt-BR` (mercado regional DIA) vs `en` (global). Roadmap §3 menciona ambos; definir MVP de Fase 1.
3. **Biblioteca admin**: `next-intl` (adopción estándar Next.js 15+) vs `react-intl` (FormatJS) vs mantener approach custom de `messages.ts`. Roadmap §4 sugiere `next-intl`.
4. **Biblioteca Flutter**: `easy_localization` (runtime, JSON/ARB, simple) vs `flutter_gen_l10n` (build-time, AOT, ARB-only, oficial). Roadmap §4 sugiere cualquiera.
5. **Backend strategy**: `Accept-Language` header + templates servidor, o backend devuelve error codes y cliente mapea? **Rec.**: códigos + client mapping (evita endpoint i18n y reduce carga backend).
6. **Convención copy**: normalizar voseo (`Seleccioná`) vs imperativo neutro (`Seleccione`) vs tuteo (`Selecciona`) antes de extraer. Ver inconsistencia detectada en admin forms.
7. **Swagger docs**: ¿migrar a EN técnico (convención OpenAPI internacional) o mantener ES?

---

## Archivos con mayor densidad (hotspots — Top 10 cross-repo)

Candidatos a primer batch de extracción:

| # | File | Repo | Strings | Surface |
|--:|------|------|--------:|---------|
| 1 | `src/camporees/camporees.controller.ts` | backend | 91 | Swagger (diferir) |
| 2 | `src/investiture/investiture.controller.ts` | backend | 49 | Swagger (diferir) |
| 3 | `src/lib/auth/permissions.ts` | admin | 41 | RBAC labels |
| 4 | `src/scoring-categories/scoring-categories.controller.ts` | backend | 37 | Swagger (diferir) |
| 5 | `src/lib/catalogs/entities.ts` | admin | 32 | Catalog UI entity names |
| 6 | `src/certifications/certifications.controller.ts` | backend | 30 | Swagger (diferir) |
| 7 | `lib/features/auth/data/datasources/auth_remote_data_source.dart` | app | 29 | Auth errors — prime candidate |
| 8 | `src/lib/clubs/actions.ts` | admin | 25 | Club CRUD actions + toasts |
| 9 | `lib/features/profile/presentation/views/settings_view.dart` | app | 23 | Settings screen — prime candidate |
| 10 | `src/monthly-reports/monthly-reports-pdf.service.ts` | backend | ~35+ | PDF templates |

**Excluyendo Swagger** (diferible), el **primer batch real Fase 1** debería atacar:
1. `sacdia-admin/src/components/layout/nav-config.ts` (nav sidebar — highest UX visibility)
2. `sacdia-admin/src/lib/auth/permissions.ts` + `src/lib/catalogs/entities.ts` (RBAC + catalog labels reused across app)
3. `sacdia-app/lib/features/auth/data/datasources/auth_remote_data_source.dart` (login/register errors)
4. `sacdia-app/lib/features/profile/presentation/views/settings_view.dart` (complete screen as pilot)
5. `sacdia-backend/src/auth/auth.service.ts` + `src/better-auth/better-auth.service.ts` (auth errors alignment cross-repo)

---

## Discoveries / Edge cases

1. **Drift ES/EN en backend**: mismo archivo mezcla exceptions en ES y EN (ej. `classes.service.ts` — linea 199 EN `"Class with ID ${classId} not found"`, linea 228 ES `"Clase no encontrada"`). Auditoría de normalización pre-Fase 1 recomendada.
2. **Voseo inconsistente en admin forms**: mezcla rioplatense (`"Seleccioná"`, `"Ingresá"`) con neutro (`"Seleccione"`, `"Máximo"`). Decidir registro único antes de extraer.
3. **Helper `getActionErrorMessage`** (`src/lib/api/action-error.ts`) acepta fallback strings hardcoded en callers — buen punto de extracción centralizado con wrapper i18n.
4. **Notifications payload**: contenido ES **NO está en** `NotificationsService`; viene de los callers (services que disparan notifs). Volumen real bajo (<10 templates) — migración rápida si se ataca junto con senders.
5. **Flutter sin base i18n**: `flutter_localizations + intl` instalados pero sin `l10n.yaml` ni catálogo ARB — arranque Fase 1 requiere setup full (no parcial como admin).
6. **Status enums con strings en ES** (`'pendiente'`, `'validada'`, `'rechazada'`): **ya migrados a enum** `evidence_validation_enum` (PENDING/VALIDATED/REJECTED) según `sacdia-backend/CLAUDE.md`. Decisión resuelta — no re-abrir.
7. **PDF Helvetica**: el PDF service usa `Helvetica` y `Helvetica-Bold` — soporta tildes pero **no caracteres pt-BR con acentos circunflejos correctamente en todos los casos**. Validar fonts antes de PDF i18n.
8. **Admin `en-US` locale ya declarado** en `messages.ts` pero sin consumo real fuera de login — base lista para expandir.
9. **Swagger 3,247 decorators** — si se decide traducir, volumen enorme. Mejor dejar EN técnico (convención OpenAPI).
10. **Push routing logs en Flutter** (`push_notification_service.dart`): mensajes en ES en logs dev — user nunca los ve, pueden excluirse si se filtran por `AppLogger.d/v`. Confirmar nivel.
