# Achievements / Gamification

**Estado**: NO CANON

> Feature operativa documentada con enfoque feature-first.
> No redefine canon de negocio. La autoridad operativa para esta superficie vive en runtime backend y Prisma.

## Descripcion de dominio

Achievements / gamification reconoce hitos de progresion y participacion a partir de eventos emitidos por el runtime. El backend expone catalogo, progreso del usuario, detalle protegido para logros secretos y una superficie administrativa para CRUD, estadisticas, carga de badge y evaluacion retroactiva.

La feature existe hoy en backend, admin, app movil y base de datos, pero la documentacion operativa venia con drift: `docs/api/ENDPOINTS-LIVE-REFERENCE.md` omite el modulo y `docs/database/SCHEMA-REFERENCE.md` solo lo menciona en el inventario resumido. Este documento fija la capa primaria de referencia operativa sin promover el dominio al canon.

## Que existe (verificado contra codigo)

### Backend
- **User controller**: `sacdia-backend/src/achievements/achievements.controller.ts`
- **Admin controller**: `sacdia-backend/src/achievements/admin/admin-achievements.controller.ts`
- **Service**: `sacdia-backend/src/achievements/achievements.service.ts`
- **Public user surface bajo JWT**:
  - `GET /api/v1/achievements` - catalogo agrupado por categoria, paginado, con masking de logros secretos no completados
  - `GET /api/v1/achievements/me` - resumen del usuario + logros agrupados con progreso por logro
  - `GET /api/v1/achievements/categories` - categorias activas ordenadas por `display_order`
  - `GET /api/v1/achievements/:achievementId` - detalle de un logro con progreso del usuario y masking de secretos si corresponde
- **Admin surface bajo JWT + `GlobalRoles(admin|super_admin)` + permiso `achievements:manage`**:
  - `GET /api/v1/admin/achievements/stats`
  - `GET|POST /api/v1/admin/achievements/categories`
  - `PATCH|DELETE /api/v1/admin/achievements/categories/:categoryId`
  - `GET|POST /api/v1/admin/achievements`
  - `GET|PATCH|DELETE /api/v1/admin/achievements/:achievementId`
  - `POST /api/v1/admin/achievements/:achievementId/image` - multipart con campo `file`, maximo 2 MB, PNG/SVG/WebP
  - `POST /api/v1/admin/achievements/retroactive/:achievementId`
- **Notas runtime verificadas**:
  - el catalogo agrupa por categoria y devuelve `meta` paginada
  - `GET /me` devuelve `summary` con `total_completed`, `total_points` y `completion_percentage`
  - los logros secretos se enmascaran con `name = "???"`, `description = "???"` y `badge_image_key = null` hasta completarse
  - la evaluacion de eventos persiste primero en `achievement_event_log` y luego intenta encolar evaluacion en BullMQ; sin cola, deja el evento persistido pero no encola

### Base de datos
- **Enums activos**:
  - `achievement_type`: `THRESHOLD`, `STREAK`, `COMPOUND`, `MILESTONE`, `COLLECTION`
  - `achievement_scope`: `GLOBAL`, `CLUB_TYPE`, `ECCLESIASTICAL_YEAR`
  - `achievement_tier`: `BRONZE`, `SILVER`, `GOLD`, `PLATINUM`, `DIAMOND`
- **Modelos activos**:
  - `achievement_categories` - categoria editable con `display_order`, `icon`, `active` y unicidad por `name`
  - `achievements` - definicion del logro con `criteria` JSON, `scope`, `tier`, `secret`, `repeatable`, `max_repeats`, `club_type_id` opcional y prerequisito opcional por auto-relacion
  - `user_achievements` - progreso por `user_id + achievement_id + ecclesiastical_year_id`, con `progress_value`, `progress_target`, `completed`, `times_completed`, `notified` y `progress_metadata`
  - `achievement_event_log` - journal de eventos consumidos por el evaluador con payload JSON, flag `processed` e indices por usuario/tipo/fecha y por cola pendiente

### Superficie de usuario y consumo cliente
- **App movil**: `sacdia-app/lib/features/achievements/data/datasources/achievements_remote_data_source.dart`
  - consume catalogo, `me`, detalle y categorias
  - el contrato esperado para catalogo y `me` coincide con el grouping verificado en backend
  - el detalle hoy se parsea como si el backend devolviera directamente un `AchievementModel`, pero runtime responde `{ achievement, userProgress }`; esto es drift de cliente, no contrato documental
- **Admin web**: `sacdia-admin/src/lib/api/achievements.ts`
  - evidencia que el panel intenta operar CRUD, estadisticas, upload y evaluacion retroactiva
  - no debe usarse como fuente primaria porque hoy tiene drift visible contra runtime en metodos HTTP, enums, query params y multipart field

### Eventos emitidos que alimentan achievements
- **Verificados en runtime**:
  - `honor.started` desde `sacdia-backend/src/honors/honors.service.ts`
  - `honor.validated` desde `sacdia-backend/src/evidence-review/evidence-review.service.ts`
  - `class.started` desde `sacdia-backend/src/classes/classes.service.ts`
  - `class.completed` desde `sacdia-backend/src/investiture/investiture.service.ts`
  - `activity.attended` desde `sacdia-backend/src/activities/activities.service.ts`
  - `camporee.participated` desde `sacdia-backend/src/camporees/camporees.service.ts`
- **Definidos pero no emitidos en la auditoria corta**:
  - `activity.completed`
  - `camporee.completed`
  - `ranking.calculated`
  - `member_of_month.awarded`

## Gaps y drift verificados

- `docs/api/ENDPOINTS-LIVE-REFERENCE.md` no registra hoy ningun endpoint de achievements pese a existir controllers activos.
- `docs/database/SCHEMA-REFERENCE.md` solo lista el dominio en el inventario resumido y no explica relaciones ni semantica operativa.
- El cliente admin hoy deriva contratos que no coinciden con runtime, por ejemplo:
  - usa `PUT` para updates donde el controller expone `PATCH`
  - usa `scope` con valores `GLOBAL|CLUB|UNIT`, pero Prisma/runtime define `GLOBAL|CLUB_TYPE|ECCLESIASTICAL_YEAR`
  - envia `category_id`, `tier`, `search` y otros params no visibles en el controller auditado
  - envia multipart field `image`, pero runtime exige `file`
- El cliente movil tiene drift puntual en detalle de logro: espera un objeto plano cuando el backend devuelve wrapper con `achievement` y `userProgress`.

## Referencias subordinadas y exclusiones

- `docs/achievements-seed-draft.md` se usa solo como contexto subordinado; mezcla contenido seed y narrativa aspiracional.
- `docs/achievements-ui-redesign-spec.md` se usa solo como referencia de UI; no fija contrato backend ni de datos.
- Todo comportamiento no verificado en runtime o Prisma queda fuera de esta documentacion o debe leerse como `Por verificar`.

## Prioridad y siguiente accion

- **Prioridad**: Media - la feature existe y tiene superficie real multi-cliente, pero la capa documental operativa estaba incompleta.
- **Siguiente accion**: resincronizar `docs/api/ENDPOINTS-LIVE-REFERENCE.md` y `docs/database/SCHEMA-REFERENCE.md` solo con la superficie ya verificada, dejando explicitado el drift de clientes sin copiarlo como contrato.
