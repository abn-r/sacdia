# Catalogos

**Estado**: IMPLEMENTADO

## Descripcion de dominio

Los catalogos son los datos de referencia del sistema SACDIA. Se dividen en dos grandes familias: catalogos geograficos (jerarquia organizacional de la iglesia) y catalogos de referencia (clasificadores de dominio). Ambas familias tienen dos niveles de acceso: lectura publica (sin autenticacion, para formularios de registro y consulta) y administracion CRUD (restringida a roles admin).

La jerarquia geografica sigue la estructura organizacional de la Iglesia Adventista: Pais > Union > Campo Local > Distrito > Iglesia. Esta cadena no es solo un catalogo de ubicaciones; es la estructura de autoridad institucional que determina jurisdiccion, supervision y alcance administrativo. Un coordinador de campo local, por ejemplo, tiene visibilidad sobre todos los clubs dentro de su campo local.

Los catalogos de referencia incluyen tipos de club (Aventureros, Conquistadores, Guias Mayores), tipos de actividad, tipos de relacion (para contactos de emergencia y representantes legales), alergias, enfermedades, medicamentos, anos eclesiasticos e ideales de club. Estos catalogos alimentan formularios en la app y el admin, estandarizando la informacion capturada entre todos los clubes.

Los anos eclesiasticos son un catalogo particularmente critico: definen los periodos operativos del club y son referenciados por enrollments, asignaciones de roles y progreso formativo.

## Que existe (verificado contra codigo)

### Backend — CatalogsModule (lectura publica)
- **Controller**: `src/catalogs/catalogs.controller.ts`
- **14 endpoints publicos** (`@Public` + JWT opcional). Sin token o sin rol territorial el directorio geográfico es completo (registro / post-registro). Con JWT territorial (`director-lf` / `director-union` / `director-dia` y asistentes) países, uniones, campos, distritos e iglesias se recortan al **país** del actor. El resto de catálogos (tipos, salud, roles) no se recorta:
  - `GET /api/v1/catalogs/club-types` — Tipos de club
  - `GET /api/v1/catalogs/activity-types` — Tipos de actividad (SIN documentacion API)
  - `GET /api/v1/catalogs/relationship-types` — Tipos de relacion
  - `GET /api/v1/catalogs/countries` — Paises
  - `GET /api/v1/catalogs/unions` — Uniones
  - `GET /api/v1/catalogs/local-fields` — Campos locales
  - `GET /api/v1/catalogs/districts` — Distritos
  - `GET /api/v1/catalogs/churches` — Iglesias
  - `GET /api/v1/catalogs/roles` — Roles disponibles
  - `GET /api/v1/catalogs/ecclesiastical-years` — Anos eclesiasticos
  - `GET /api/v1/catalogs/ecclesiastical-years/current` — Ano eclesiastico actual
  - `GET /api/v1/catalogs/club-ideals` — Ideales de club
  - `GET /api/v1/catalogs/allergies` — Catalogo de alergias
  - `GET /api/v1/catalogs/diseases` — Catalogo de enfermedades

### Backend — AdminModule (CRUD admin)
- **Controllers**:
  - `src/admin/admin-reference.controller.ts` — AdminReferenceController
  - `src/admin/admin-geography.controller.ts` — AdminGeographyController
- **Guards**: JwtAuthGuard, GlobalRoles (super_admin, admin)
- **20 endpoints de referencia**:
  - Relationship types: CRUD (4 endpoints)
  - Allergies: CRUD (4 endpoints)
  - Diseases: CRUD (4 endpoints)
  - Medicines: CRUD (4 endpoints, SIN documentacion API)
  - Ecclesiastical years: CRUD (4 endpoints)
- **20 endpoints de geografia**:
  - Countries: CRUD (4 endpoints)
  - Unions: CRUD (4 endpoints)
  - Local fields: CRUD (4 endpoints)
  - Districts: CRUD (4 endpoints)
  - Churches: CRUD (4 endpoints)
- **1 endpoint read-only admin**:
  - `GET /api/v1/admin/club-ideals` — Listar ideales de club

### Admin Panel
- **Páginas de catálogo** bajo `/dashboard/catalogs/*`.
- El editor CRUD de catálogos (geografía, referencia, Phase E, honores, tipos de evento camporee) está restringido a roles globales `admin` / `assistant-admin` / `super-admin`, alineado con `@GlobalRoles('admin', 'super-admin')` del backend.
- `catalogs:read` no abre esas pantallas: es un permiso de referencia compartido por roles de campo y de club (dropdowns y catálogos públicos).
- El sidebar y la paleta de comandos ocultan los editores si el usuario no tiene esos roles. Una URL directa no llama al API admin: el layout muestra un estado de sin permiso.
- Excepción: `/dashboard/catalogs/certifications` no usa GlobalRoles de admin; se filtra por `certifications:configure` / `certifications:publish` y `director-lf` sí puede administrarlo.
- Geografia CRUD: countries, unions, local-fields, districts, churches
- Referencia CRUD: allergies, diseases, relationship-types, ecclesiastical-years
- Phase E: classes, class-modules, class-sections, finance-categories, inventory-categories
- Honor categories y honors: CRUD admin

### App Movil
- Consume catalogos compartidos via `CatalogsRemoteDataSourceImpl`:
  - club-types, activity-types, districts, churches, roles, ecclesiastical-years
  - relationship-types, allergies, diseases (desde post-registration)

### Base de datos
- **Geografia**: `countries`, `unions`, `local_fields`, `districts`, `churches`
- **Referencia**: `club_types`, `club_ideals`, `relationship_types`, `allergies`, `diseases`, `medicines`, `ecclesiastical_years`, `activity_types`
- **Clasificacion**: `honors_categories`, `inventory_categories`, `finances_categories`

## Requisitos funcionales

1. Los catalogos de lectura siguen disponibles sin JWT para formularios de registro. Un JWT territorial recorta solo la geografía al país del actor; no abre CRUD admin.
2. La administracion CRUD de catalogos debe estar restringida a super_admin y admin
3. El panel admin no debe ofrecer entradas de UI (sidebar, paleta, URL que dispara el API) a editores de catalogo si el actor no tiene esos roles globales
4. La jerarquia geografica debe mantener integridad referencial (no eliminar un pais con uniones activas)
5. Las operaciones de eliminacion deben ser soft delete (campo `active = false`)
6. Los anos eclesiasticos deben tener fechas de inicio y fin, y el sistema debe poder resolver el ano actual
7. Los catalogos de salud (alergias, enfermedades, medicamentos) deben estar disponibles tanto en lectura publica como en CRUD admin
8. Los tipos de club deben ser inmutables desde el admin (read-only)
9. Los ideales de club deben ser consultables pero no modificables desde el admin

## Decisiones de diseno

- **Separacion publica/admin**: Dos controllers diferentes para la misma data; el publico sin guards, el admin con GlobalRoles
- **Soft delete estandar**: Todos los catalogos admin usan soft delete para preservar integridad referencial
- **Jerarquia con filtros cascada**: Los endpoints de geografia soportan filtros por parent (ej: uniones por pais, campos por union)
- **Ano eclesiastico como eje temporal**: Todas las operaciones anuales (enrollments, roles de club, progreso) referencian el ano eclesiastico, no el ano calendario
- **CatalogCrudPage en admin**: Patron generico reutilizable para todas las paginas CRUD de catalogos
- **Gating de UI alineado a GlobalRoles**: `catalogs:read` no autoriza el editor admin; el frontend combina permiso + rol `admin`/`super-admin` para nav y layout

## Gaps y pendientes

- **4 endpoints de `/admin/medicines` sin documentacion API** en ENDPOINTS-LIVE-REFERENCE
- **`GET /catalogs/activity-types` sin documentacion API**
- **Honor categories FANTASMA**: Admin consume `/admin/honor-categories` (CRUD completo) pero estos endpoints no existen en el backend — pendiente de implementacion
- **Club ideals FANTASMA**: Admin consume `/admin/club-ideals` como endpoint read-only pero no esta en backend audit — pendiente verificacion
- **Sin versionado de catalogos**: Los cambios en catalogos no tienen historial; un rename de alergia se pierde
- **Sin importacion masiva**: No hay endpoint para carga masiva de datos geograficos o de referencia

## Prioridad y siguiente accion

- **Prioridad**: Media — catalogos funcionales pero con endpoints fantasma pendientes
- **Siguiente accion**: Implementar endpoints de `/admin/honor-categories` en el backend. Documentar los 4 endpoints de medicines y activity-types en ENDPOINTS-LIVE-REFERENCE. Verificar estado real de `/admin/club-ideals`.
