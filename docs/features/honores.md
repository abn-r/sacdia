# Honores (Especialidades)

**Estado**: IMPLEMENTADO

## Descripcion de dominio

Los honores (especialidades) son unidades formativas independientes que los miembros de clubes de Aventureros, Conquistadores y Guias Mayores pueden cursar para profundizar en areas de conocimiento especificas. Cada honor pertenece a una categoria tematica (naturaleza, artes domesticas, actividades misioneras, etc.) y tiene un nivel de dificultad (basico, avanzado, master).

El sistema de honores es uno de los pilares del proceso formativo institucional. A diferencia de las clases progresivas que siguen un camino secuencial, los honores pueden cursarse en cualquier orden y representan especializacion tematica. Un miembro puede tener multiples honores activos simultaneamente, y su progreso se registra individualmente con evidencias (certificados, documentos, imagenes).

El modelo de honores soporta el ciclo completo: catalogo publico de consulta, inscripcion del usuario, registro de progreso con evidencias, validacion, y abandono. El catalogo esta segmentado por tipo de club, lo que permite filtrar honores relevantes para cada seccion (Aventureros solo ve honores de Aventureros).

## Que existe (verificado contra codigo)

### Backend (HonorsModule)
- **Controladores**: `HonorsController` (catalogo publico, 4 endpoints) + `UserHonorsController` (honores de usuario, 8 endpoints) = **12 endpoints totales**
- **Catalogo publico** (OptionalJwtAuthGuard):
  - `GET /honors` — listar honores con paginacion y filtros (categoryId, clubTypeId, skillLevel)
  - `GET /honors/categories` — listar categorias de honores
  - `GET /honors/grouped-by-category` — honores agrupados por categoria con filtros
  - `GET /honors/:honorId` — detalle de un honor
- **Honores de usuario** (JwtAuthGuard + OwnerOrAdminGuard):
  - `GET /users/:userId/honors` — listar honores del usuario (filtro por validated)
  - `GET /users/:userId/honors/stats` — estadisticas de honores
  - `POST /users/:userId/honors` — registrar honor con datos iniciales (CreateUserHonorDto)
  - `POST /users/:userId/honors/bulk` — registro masivo de honores (BulkCreateUserHonorsDto)
  - `POST /users/:userId/honors/:honorId/files` — subir evidencias (certificate, document, images via multipart)
  - `POST /users/:userId/honors/:honorId` — iniciar un honor (StartHonorDto)
  - `PATCH /users/:userId/honors/:honorId` — actualizar progreso (UpdateUserHonorDto)
  - `DELETE /users/:userId/honors/:honorId` — abandonar honor (soft delete)
- **Servicio**: `HonorsService` con spec de tests (`honors.service.spec.ts`)
- **DTOs**: StartHonorDto, UpdateUserHonorDto, CreateUserHonorDto, BulkCreateUserHonorsDto

### Admin (sacdia-admin)
- 2 paginas funcionales: listado de honores con CRUD y detalle por honor
- Consume: `GET /honors`, `GET /honors/categories`, `GET /catalogs/club-types`, `POST /honors`, `PATCH /honors/:id`
- CRUD de categorias en `/admin/honor-categories` — **5 endpoints FANTASMA** (no existen en backend)

### App (sacdia-app)
- 4 screens: HonorsCatalogView, HonorDetailView, MyHonorsView, AddHonorView
- Consume 10 endpoints incluyendo catalogo, categorias, grouped-by-category, user honors CRUD con progreso y evidencias

### Base de datos
- `honors` — catalogo de especialidades (id, name, honors_category_id, club_type_id, difficulty, honor_image, material_url, master_honors_id)
- `honors_categories` — categorias tematicas (honor_category_id, name)
- `master_honors` — honores master (master_honor_id, name)
- `users_honors` — relacion usuario-honor con progreso (user_honor_id, user_id, honor_id, validated, evidences, etc.). Unique: (user_id, honor_id)

## Requisitos funcionales

1. El catalogo de honores debe ser consultable sin autenticacion (OptionalJwtAuthGuard)
2. Los honores deben poder filtrarse por categoria, tipo de club y nivel de dificultad
3. Un usuario solo puede tener un registro activo por honor (unique constraint user_id + honor_id)
4. El registro masivo (bulk) debe permitir carga inicial rapida sin duplicados
5. Las evidencias se suben a Cloudflare R2 en multipart (certificate, document, hasta 10 imagenes)
6. El abandono de un honor es soft delete (desactivacion, no eliminacion)
7. El progreso debe ser actualizable parcialmente (evidencias, validacion, certificado)
8. Solo el owner del recurso o un admin pueden operar sobre honores de usuario

## Decisiones de diseno

- **Dos controladores separados**: HonorsController (catalogo publico) y UserHonorsController (operaciones de usuario) con guards diferentes
- **OptionalJwtAuthGuard en catalogo**: permite consulta anonima pero enriquece respuesta si hay JWT
- **OwnerOrAdminGuard en user honors**: patron self-service con escalacion admin
- **Reactivacion en lugar de duplicacion**: startHonor y createUserHonor reactivan registros inactivos existentes en vez de crear duplicados
- **Upload separado de registro**: las evidencias se suben en un endpoint dedicado (POST files) independiente del registro inicial

## Gaps y pendientes

- **CRITICO**: Admin consume CRUD completo de `/admin/honor-categories` (5 endpoints) que son **FANTASMA** — no existen en backend. Pendiente de implementacion
- 3 endpoints de user honors sin documentacion API: POST bulk, POST files, POST register (marcados SIN DOCS en Reality Matrix)
- `GET /honors/grouped-by-category` existe en backend pero sin documentacion API
- No hay validacion cruzada entre honor y tipo de club del usuario al momento de inscripcion
- No existe flujo de aprobacion/validacion institucional de honores completados

## Prioridad y siguiente accion

- **Alta**: Implementar endpoints `/admin/honor-categories` CRUD en backend — el admin ya los consume y falla silenciosamente
- **Media**: Documentar los 4 endpoints SIN DOCS en ENDPOINTS-LIVE-REFERENCE.md
- **Siguiente accion concreta**: Crear `AdminHonorCategoriesController` en backend con CRUD para honor_categories con GlobalRolesGuard (super_admin, admin)
