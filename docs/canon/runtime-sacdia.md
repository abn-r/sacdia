# Runtime SACDIA

**Estado**: ACTIVE
**Autoridad rectora**: `docs/canon/source-of-truth.md`
**Tipo de documento**: runtime canonizado, documented-as-built
**Ámbito**: backend, clientes, contratos API, persistencia e integraciones documentadas

<!-- VERIFICADO contra código 2026-03-14. Claims cruzados con Reality Matrix. Actualizado 2026-03-18: club_sections consolidation. -->

> [!IMPORTANT]
> Este documento describe el runtime permitido por la autoridad congelada de Wave 0.
> No descubre una verdad nueva del repo, no usa código fuente como autoridad primaria y no completa vacíos con supuestos.

---

## 1. Regla de lectura

La precedencia para interpretar este documento es:

1. `docs/canon/source-of-truth.md`
2. `docs/canon/dominio-sacdia.md`
3. `docs/canon/identidad-sacdia.md`
4. `docs/canon/arquitectura-sacdia.md`
5. `docs/canon/decisiones-clave.md`
6. `docs/02-API/ENDPOINTS-LIVE-REFERENCE.md`
7. `docs/02-API/ARCHITECTURE-DECISIONS.md`
8. `docs/03-DATABASE/schema.prisma`
9. `docs/03-DATABASE/README.md`
10. `docs/canon/completion-matrix.md`

Si una fuente autorizada de menor jerarquía contradice otra superior, este documento no fuerza síntesis y debe escalar el punto.

---

## 2. Qué es el runtime actual de SACDIA

SACDIA opera hoy como un sistema full-stack con:

- `sacdia-backend/` como backend principal de reglas, seguridad, autorización y contratos;
- `sacdia-admin/` como panel administrativo web;
- `sacdia-app/` como app móvil;
- una base de datos relacional PostgreSQL con Prisma;
- una capa documental canónica en `docs/`.

El runtime no se interpreta desde pantallas o CRUDs aislados, sino desde la trayectoria institucional del miembro, la operación por secciones de club, el periodo operativo y la validación institucional.

---

## 3. Topología runtime documentada

### 3.1 Capas activas

Las capas documentadas del runtime son:

- **Dominio**: fija semántica y reglas de interpretación.
- **Backend**: concentra lógica operativa, seguridad, autorización y contratos API.
- **Admin web**: soporta gestión, supervisión y operación administrativa.
- **App móvil**: soporta interacción contextual y continuidad de uso.
- **Datos**: persiste memoria estructural, integridad relacional y trazabilidad histórica.

### 3.2 Stack documentado

Según la baseline técnica activa:

- **Backend**: NestJS 10.x + Node.js 20.x + TypeScript 5.x <!-- VERIFICADO contra código 2026-03-14 -->
- **Admin web**: Next.js 14+ + TypeScript + Tailwind + shadcn/ui <!-- VERIFICADO contra código 2026-03-14 -->
- **App móvil**: Flutter 3.19+ <!-- VERIFICADO contra código 2026-03-14 -->
- **Datos**: PostgreSQL 15.x en Supabase + Prisma v5 <!-- VERIFICADO contra código 2026-03-14 -->
- **Arquitectura técnica**: Backend REST API + múltiples clientes <!-- VERIFICADO contra código 2026-03-14 -->

---

## 4. Fronteras canónicas del runtime

### 4.1 Lenguaje canónico vs naming técnico

El runtime actual conserva naming técnico heredado en varios puntos, pero debe leerse así:

- `Club` = raíz institucional;
- `Sección de club` = unidad operativa real;
- `club_sections` = tabla consolidada que representa secciones de club (desde consolidación 2026-03-17; naming canónico y técnico alineados);
- `user` = representación técnica del miembro;
- `role` / `assignment` = representación técnica que no sustituye el concepto canónico de cargo o vinculación institucional.

### 4.2 Verdad anual vs trayectoria consolidada
<!-- VERIFICADO contra código 2026-03-14: enrollments y users_classes existen en schema.prisma y son ALINEADO -->

La frontera runtime vigente queda documentada así:

- `enrollments` = verdad operativa anual del cursado, progreso, validación e investidura del periodo; <!-- VERIFICADO -->
- `users_classes` = trayectoria consolidada por clase a lo largo del tiempo; <!-- VERIFICADO -->
- `users_classes.current_class` = compatibilidad legacy, no verdad operativa anual. <!-- VERIFICADO -->

Esta frontera está respaldada por `docs/canon/decisiones-clave.md` y por las notas runtime activas en `ENDPOINTS-LIVE-REFERENCE.md`.

---

## 5. Superficie API runtime vigente

### 5.1 Fuente runtime

La fuente runtime API vigente es `docs/02-API/ENDPOINTS-LIVE-REFERENCE.md`.

Características documentadas:

- **Base URL**: `/api/v1` <!-- VERIFICADO contra código 2026-03-14 -->
- **Fecha de generación documentada**: `2026-03-10`
- **Total documentado**: `180 endpoints` (de 198 implementados; 18 sin documentar en ENDPOINTS-LIVE-REFERENCE) <!-- VERIFICADO contra código 2026-03-14 -->

### 5.2 Módulos API documentados

El runtime documenta actualmente estos módulos: <!-- VERIFICADO contra código 2026-03-14: 22 módulos en backend, 18 documentados -->

- `auth` <!-- VERIFICADO -->
- `users` <!-- VERIFICADO -->
- `activities` <!-- VERIFICADO -->
- `admin` <!-- VERIFICADO -->
- `camporees` <!-- VERIFICADO -->
- `catalogs` <!-- VERIFICADO -->
- `certifications` <!-- VERIFICADO -->
- `classes` <!-- VERIFICADO -->
- `club-roles` <!-- VERIFICADO -->
- `clubs` <!-- VERIFICADO -->
- `fcm-tokens` <!-- VERIFICADO -->
- `finances` <!-- VERIFICADO -->
- `folders` <!-- VERIFICADO -->
- `health` <!-- VERIFICADO -->
- `honors` <!-- VERIFICADO -->
- `inventory` <!-- VERIFICADO -->
- `notifications` <!-- VERIFICADO -->
- `root` <!-- VERIFICADO -->

### 5.3 Naturaleza del contrato

El contrato runtime documenta por endpoint:

- método HTTP;
- path;
- requisito de autenticación;
- roles explícitos cuando están documentados;
- descripción funcional;
- controlador fuente para trazabilidad documental.

---

## 6. Capacidades runtime documentadas

### 6.1 Autenticación y sesión
<!-- VERIFICADO contra código 2026-03-14: auth module ALINEADO en todas las capas -->

El runtime documenta:

- login;
- refresh de sesión;
- logout best effort;
- perfil autenticado;
- cambio de contexto activo;
- enrolamiento, verificación, listado y baja de MFA;
- OAuth con Google y Apple;
- recuperación de contraseña;
- estado de completion del perfil;
- gestión de sesiones activas.

Notas runtime activas:

- `login` y `refresh` responden tokens en camelCase;
- el body oficial de refresh usa `refreshToken`;
- existe una ventana legacy documentada hasta el **18 de marzo de 2026** para aceptar `refresh_token`;
- `logout` acepta bearer opcional y `refreshToken` opcional;
- el callback OAuth mantiene `access_token` y `refresh_token` en query por compatibilidad de proveedor.

### 6.2 Perfil, salud y post-registro
<!-- VERIFICADO contra código 2026-03-14: users module ALINEADO -->

El runtime documenta:

- lectura y actualización del usuario;
- foto de perfil;
- edad calculada;
- requirement de representante legal;
- alergias, enfermedades y medicamentos como sub-recursos sensibles;
- contactos de emergencia;
- representante legal;
- estado y pasos de post-registro.

Notas runtime activas:

- las superficies sensibles de `user` usan autorización contextual sobre `userId`;
- el owner puede operar sus propias rutas sensibles;
- terceros requieren permisos globales o permisos finos transicionales según familia;
- `post-registration step 3` crea o reactiva alta anual en `enrollments`;
- si el usuario cambia de clase en el mismo año, se desactivan otros enrollments activos del año antes de resolver el seleccionado.

### 6.3 Clubes, secciones y cargos
<!-- VERIFICADO contra código 2026-03-14: clubs module ALINEADO en todas las capas -->

El runtime documenta:

- CRUD operativo de clubes;
- lectura y creación de secciones por club;
- lectura de miembros de una sección;
- asignación y actualización/remoción de roles de club.

Interpretación canónica:

- `clubs` representa la raíz institucional;
- `club_sections` representa la realización técnica de `Sección de club` (consolidado desde 2026-03-17, Decisión 10);
- la operación concreta documentada ocurre sobre estas secciones, diferenciadas por `club_type_id`.

### 6.4 Formación, trayectoria y validación
<!-- VERIFICADO contra código 2026-03-14: classes ALINEADO, honors ALINEADO, certifications PARCIAL (backend+admin read-only, app sin screens), folders ALINEADO -->

El runtime documenta:

- catálogo público de clases;
- inscripción de usuarios a clases;
- progreso de clase por usuario y clase;
- honores del usuario y catálogo de honores;
- certificaciones y su progreso;
- folders y progreso por carpetas;
- transición explícita entre trayectoria consolidada y enrollment operativo actual en admin user detail.

Notas runtime activas:

- `GET/PATCH /users/:userId/classes/:classId/progress` operan sobre owner anual `enrollments.enrollment_id`;
- sin override, el backend resuelve una sola inscripción activa del año eclesiástico actual;
- si no existe inscripción resoluble devuelve `404`;
- si hay ambigüedad devuelve `409 ENROLLMENT_RESOLUTION_AMBIGUOUS`;
- `GET /api/v1/admin/users/:userId` expone `current_operational_enrollment` como presente anual y `trajectory_classes` como histórico consolidado.

### 6.5 Operación administrativa y catálogos
<!-- VERIFICADO contra código 2026-03-14: catalogs ALINEADO, admin geography ALINEADO, admin RBAC ALINEADO, admin reference (allergies/diseases/relationship-types/ecclesiastical-years) implementado pero SIN CANON explícito -->

El runtime documenta:

- catálogos públicos de geografía, tipos de club, tipos de relación, años eclesiásticos y roles;
- endpoints admin para geografía y catálogos de referencia (alergias, enfermedades, medicamentos, tipos de relación, años eclesiásticos);
- endpoints admin RBAC para permisos y roles;
- listado administrativo de usuarios y detalle administrativo por alcance.

Los catálogos de referencia son catálogos de trayectoria: soportan la operación y trazabilidad de la trayectoria institucional del miembro. No requieren endpoints separados para admin y usuario; el acceso se controla mediante RBAC y alcance territorial.

### 6.6 Operación de club
<!-- VERIFICADO contra código 2026-03-14: actividades PARCIAL (admin placeholder), finanzas PARCIAL (admin placeholder), camporees PARCIAL (app sin screens), inventario PARCIAL (admin placeholder), notifications ALINEADO -->

El runtime documenta superficies para:

- actividades y asistencia; <!-- VERIFICADO: backend+app completos, admin placeholder -->
- finanzas y resumen financiero; <!-- VERIFICADO: backend+app completos, admin placeholder -->
- camporees y registro/remoción de miembros; <!-- VERIFICADO: backend+admin read-only, app sin screens -->
- inventario del club; <!-- VERIFICADO: backend+app completos, admin placeholder -->
- notificaciones y tokens FCM. <!-- VERIFICADO -->

### 6.7 Salud operativa
<!-- VERIFICADO contra código 2026-03-14 -->

El runtime documenta un endpoint público `GET /api/v1/health` para estado básico de API.

---

## 7. Autorización runtime documentada
<!-- VERIFICADO contra código 2026-03-14: RBAC module ALINEADO, guards y decorators confirmados -->

### 7.1 Modelo documentado

La autorización runtime documentada combina:

- autenticación JWT; <!-- VERIFICADO -->
- permisos globales; <!-- VERIFICADO -->
- asignaciones contextuales de club; <!-- VERIFICADO -->
- recursos sensibles resueltos por owner/contexto. <!-- VERIFICADO -->

### 7.2 Estructuras de roles documentadas

Desde `ARCHITECTURE-DECISIONS.md` y `schema.prisma`, el runtime documenta:

- **roles globales** en `users_roles`;
- **roles de club** en `club_role_assignments`;
- **catálogo de permisos** en `permissions`;
- **relación rol-permiso** en `role_permissions`.

Roles globales documentados:

- `super_admin`
- `admin`
- `assistant_admin`
- `coordinator`
- `user`

Roles de club documentados:

- `director`
- `subdirector`
- `secretary`
- `treasurer`
- `counselor`
- `member`

### 7.3 Alcance documentado de autorización sensible

El runtime documenta explícitamente autorización sensible sobre:

- `health`
- `emergency_contacts`
- `legal_representative`
- `post_registration`

Y mantiene compatibilidad transicional con permisos legacy `users:*` en ciertas superficies.

---

## 8. Persistencia runtime documentada
<!-- VERIFICADO contra código 2026-03-14: 72 modelos en schema.prisma, 24 ALINEADO, 41 SIN CANON, 7 SIN DOCS -->

### 8.1 Fuente estructural

La fuente de verdad estructural de datos es `docs/03-DATABASE/schema.prisma`.

La guía operativa subordinada es `docs/03-DATABASE/README.md`.

### 8.2 Rasgos documentados de persistencia

La persistencia documentada usa:

- PostgreSQL 15.x en Supabase;
- Prisma como capa ORM;
- `active` como patrón frecuente de soft delete;
- timestamps automáticos;
- constraints relacionales para integridad.

### 8.3 Categorización del universo de modelos

El schema de persistencia contiene 72 modelos. Se categorizan así:

- **Modelos core de trayectoria**: `users`, `enrollments`, `users_classes`, `users_honors`, `member_insurances`, `legal_representatives`, `emergency_contacts`, `users_pr`, `users_roles`, `club_role_assignments`, `unit_members`, `units`, `weekly_records`.
- **Modelos de catálogo (trayectoria)**: `classes`, `honors`, `honors_categories`, `master_honors`, `club_types`, `club_ideals`, `relationship_types`, `allergies`, `diseases`, `medicines`, `ecclesiastical_years`, `activity_types`, `inventory_categories`, `finances_categories`.
- **Modelos operativos**: `clubs`, `club_sections`, `folders`, `folders_modules`, `folders_sections`, `folders_modules_records`, `folders_section_records`, `folder_assignments`, `certifications` y tablas relacionadas, `club_inventory`, `finances` y tablas relacionadas, `activities` y tablas relacionadas, `camporees` y tablas relacionadas, `notifications`.
- **Modelos de infraestructura**: `error_logs`, `user_fcm_tokens`.
- **Modelos RBAC**: `roles`, `permissions`, `role_permissions`, `users_permissions`.
- **Modelos de organización**: `countries`, `unions`, `local_fields`, `districts`, `churches`.

### 8.4 Módulos de datos confirmados por autoridad usada

El runtime documenta al menos estos grupos de persistencia:

- **Users & Auth**: `users`, `users_pr`, `users_roles`, `legal_representatives`, `emergency_contacts`
- **Organization**: `countries`, `unions`, `local_fields`, `districts`, `churches`, `ecclesiastical_years`
- **Clubs**: `clubs`, `club_sections`, `club_role_assignments`
- **Formación**: `classes`, `users_classes`, `enrollments`
- **RBAC**: `roles`, `permissions`, `role_permissions`
- **Catálogos**: `club_types`, `relationship_types`, `inventory_categories`

### 8.5 Lectura canónica de estructuras clave

#### Miembro y post-registro

- `users` conserva identidad operativa del usuario/miembro;
- `users_pr` conserva tracking granular de post-registro siguiendo `schema.prisma`: PK técnico `user_pr_id` y `user_id` único como vínculo al miembro;
- `legal_representatives` soporta representante legal;
- `emergency_contacts` soporta contactos de emergencia.

#### Club y sección

- `clubs` representa la raíz institucional;
- `club_sections` representa la realización técnica consolidada de secciones por tipo (reemplaza `club_adventurers`, `club_pathfinders`, `club_master_guilds` desde 2026-03-17);
- `club_role_assignments` expresa asignación contextual de cargo con año eclesiástico vía `club_section_id`.

#### Formación

- `classes` define catálogo de clases;
- `enrollments` define ciclo anual operativo;
- `users_classes` define trayectoria consolidada por clase.

#### Autoridad y jerarquía

- `countries`, `unions`, `local_fields`, `districts` y `churches` materializan la cadena jerárquica documentada;
- `roles`, `permissions`, `role_permissions` y `users_roles` materializan RBAC global;
- `club_role_assignments` materializa responsabilidad contextual en club/sección y periodo.

---

## 9. Integraciones y dependencias externas documentadas

Las integraciones documentadas por la autoridad usada son:

- **Supabase Auth** para autenticación; <!-- VERIFICADO contra código 2026-03-14 -->
- **PostgreSQL en Supabase** para persistencia; <!-- VERIFICADO contra código 2026-03-14 -->
- **Cloudflare R2 (S3-compatible)** como storage de archivos (profile pictures, evidencias); <!-- VERIFICADO contra código 2026-03-14 — el backend usa R2FileStorageService, no Supabase Storage -->
- **Firebase Cloud Messaging** para push notifications; <!-- VERIFICADO contra código 2026-03-14 -->
- **OAuth Google y Apple** como proveedores de autenticación soportados por runtime; <!-- VERIFICADO contra código 2026-03-14 -->
- **Upstash Redis** como dependencia documentada en baseline técnica; <!-- VERIFICADO contra código 2026-03-14 -->
- **Sentry** para monitoreo y error tracking (condicional); <!-- VERIFICADO contra código 2026-03-14 — configurado activamente pero no documentado en canon previo -->
- **Vercel** como hosting documentado para admin web y backend en la baseline técnica.

Este documento no afirma más detalle operativo sobre proveedores externos que el expresamente documentado por las fuentes autorizadas.

### 9.1 Infraestructura operativa

Los componentes de infraestructura (health check, logging, Sentry, rate limiting, seguridad global) no forman parte del canon de dominio de negocio. Son infraestructura operativa del runtime documentada aquí por referencia. Su detalle operativo se encuentra en `docs/features/infrastructure.md`.

---

## 10. Estado runtime canonizado de Wave 0

El runtime canonizado de Wave 0 queda resumido así:

- SACDIA opera como backend REST + admin web + app móvil + persistencia relacional;
- la API vigente es la publicada en `ENDPOINTS-LIVE-REFERENCE.md`;
- la semántica del sistema se interpreta desde trayectoria, club, sección, vinculación, periodo y validación; <!-- ASPIRACIONAL: no implementado — validación de investiduras existe como tablas (investiture_config, investiture_validation_history) pero sin módulo backend, endpoints ni screens -->
- la operación anual formativa se lee desde `enrollments`;
- la trayectoria consolidada histórica se lee desde `users_classes`;
- la autorización runtime combina JWT, permisos globales y asignaciones contextuales;
- las superficies documentadas cubren autenticación, perfil, post-registro, clases, honores, certificaciones, folders, clubes, roles, finanzas, actividades, camporees, inventario y notificaciones.

---

## 11. Límites explícitos de este documento

Este runtime canonizado:

- **no** usa `docs/03-IMPLEMENTATION-ROADMAP.md`;
- **no** usa código fuente como desempate;
- **no** usa `docs/history/`;
- **no** afirma estructura de datos desde `SCHEMA-REFERENCE.md` cuando `schema.prisma` o la matrix reportan drift;
- **no** completa con supuestos las zonas no cubiertas por autoridad autorizada.

---

## 12. Mantenimiento

Cuando cambie el contrato runtime documentado:

1. se actualiza primero `docs/02-API/ENDPOINTS-LIVE-REFERENCE.md`;
2. se revalida contra `docs/canon/source-of-truth.md`;
3. se ajusta `docs/canon/completion-matrix.md` si cambia cobertura o aparece drift nuevo;
4. recién entonces se actualiza este `runtime-sacdia.md`.

Este documento existe para canonizar el runtime documentado, no para reemplazar la fuente primaria de endpoints ni la fuente estructural de datos.
