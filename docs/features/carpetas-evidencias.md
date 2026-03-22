# Carpetas de Evidencias (Folders)

**Estado**: IMPLEMENTADO

## Descripcion de dominio

Las carpetas de evidencias son instrumentos formativos estructurados que los miembros de los clubes deben completar como parte de su trayectoria institucional. Funcionan como un portafolio organizado donde el miembro recopila evidencias de actividades, proyectos y requisitos cumplidos a lo largo del ano eclesiastico.

Cada carpeta sigue una estructura jerarquica de template: carpeta -> modulos -> secciones. Cada seccion tiene un puntaje maximo asignable, y el progreso se registra seccion por seccion con puntos obtenidos y evidencias adjuntas. El sistema auto-completa modulos y carpetas cuando todas sus secciones alcanzan los criterios establecidos.

El backend implementa dos subsistemas paralelos para carpetas: el **FoldersModule** (rutas `/folders/*`) que gestiona templates y asignaciones de usuario con progreso detallado, y el **EvidenceFolderController** (rutas `/club-sections/:sectionId/evidence-folder`) que expone un flujo contextualizado por seccion de club con subida de archivos y submit de secciones. Esta dualidad genera un desacople que necesita resolucion.

Las carpetas son diferentes de las clases progresivas: mientras las clases tienen un camino secuencial determinado por edad, las carpetas son documentos de evidencia complementarios que se asignan segun el programa del club.

## Que existe (verificado contra codigo)

### Backend — FoldersModule (FoldersController)
- **7 endpoints** bajo `/folders/*` (JwtAuthGuard + PermissionsGuard):
  - `GET /folders/folders` — listar templates de carpetas con paginacion y filtro por club_type
  - `GET /folders/folders/:id` — detalle de template con modulos, secciones y puntos
  - `POST /folders/users/:userId/folders/:folderId/enroll` — inscribir usuario en carpeta (valida pertenencia a club del tipo requerido)
  - `GET /folders/users/:userId/folders` — listar carpetas asignadas del usuario con progreso
  - `GET /folders/users/:userId/folders/:folderId/progress` — progreso detallado por modulos y secciones con evidencias
  - `PATCH /folders/users/:userId/folders/:folderId/modules/:moduleId/sections/:sectionId` — actualizar progreso de seccion (puntos + evidencias, auto-completa modulo/carpeta)
  - `DELETE /folders/users/:userId/folders/:folderId` — abandonar carpeta (soft delete)
- **Servicio**: `FoldersService`
- **DTO**: UpdateSectionRecordDto
- **Permisos**: users:read_detail (lectura), users:update (escritura) con AuthorizationResource owner detection

### Backend — EvidenceFolderController (separado)
- **4 endpoints** bajo `/club-sections/:sectionId/evidence-folder` (JwtAuthGuard):
  - `GET /club-sections/:sectionId/evidence-folder` — obtener carpeta de evidencias por seccion de club
  - `POST /club-sections/:sectionId/evidence-folder/sections/:efSectionId/submit` — enviar seccion a revision
  - `POST /club-sections/:sectionId/evidence-folder/sections/:efSectionId/files` — subir archivo de evidencia (multipart)
  - `DELETE /club-sections/:sectionId/evidence-folder/sections/:efSectionId/files/:fileId` — eliminar archivo de evidencia
- **Servicio**: `EvidenceFolderService` con spec de tests
- **Nota**: Este controlador usa rutas diferentes a FoldersController y no aparece en ENDPOINTS-LIVE-REFERENCE.md

### Admin (sacdia-admin)
- 1 pagina read-only: listado de carpetas via ModuleListPage
- Consume: `GET /folders/folders`
- Sin gestion de progreso, inscripciones ni administracion de templates

### App (sacdia-app)
- 2 screens: EvidenceFolderView, EvidenceSectionDetailView
- Consume endpoints de evidence-folder via `/clubs/:clubId/sections/:sectionId/evidence-folder` — rutas que no coinciden exactamente con ninguno de los dos controladores del backend

### Base de datos
- `folders` — templates de carpetas (id, name, club_type_id, etc.)
- `folders_modules` — modulos por carpeta
- `folders_sections` — secciones por modulo con puntos maximos
- `folder_assignments` — asignacion usuario-carpeta
- `folders_modules_records` — progreso de modulo
- `folders_section_records` — progreso de seccion con evidencias

## Requisitos funcionales

1. Los templates de carpetas deben poder filtrarse por tipo de club
2. La inscripcion valida que el usuario pertenezca a un club del tipo requerido por la carpeta
3. Un usuario solo puede tener una asignacion activa por carpeta (constraint de unicidad con 409 en duplicado)
4. El progreso se registra por seccion con puntos obtenidos y evidencias
5. Los puntos no pueden exceder el maximo definido en el template de la seccion
6. Al completar todas las secciones de un modulo, el modulo se auto-completa
7. Al completar todos los modulos, la carpeta se auto-completa
8. Las evidencias deben poder subirse como archivos multipart y eliminarse individualmente
9. El submit de secciones debe marcar la seccion como enviada para revision

## Decisiones de diseno

- **Dos controladores coexistentes**: FoldersController (CRUD de asignaciones y progreso generico) y EvidenceFolderController (flujo contextualizado por seccion de club con archivos)
- **PermissionsGuard en FoldersController**: permisos finos users:read_detail y users:update con owner detection
- **JwtAuthGuard simple en EvidenceFolderController**: usa @CurrentUser() para resolver el usuario del token sin PermissionsGuard adicional
- **Auto-completado jerarquico**: al actualizar una seccion, el servicio verifica y auto-completa modulo y carpeta si corresponde
- **Soft delete en abandono**: la asignacion se desactiva pero no se elimina fisicamente

## Gaps y pendientes

- **Desacople de rutas**: La app consume `/clubs/:clubId/sections/:sectionId/evidence-folder` pero el backend tiene `/club-sections/:sectionId/evidence-folder` (sin clubId en la ruta). Las rutas no coinciden exactamente
- **EvidenceFolderController no documentado**: Los 4 endpoints del EvidenceFolderController no aparecen en ENDPOINTS-LIVE-REFERENCE.md ni en el backend audit original
- Las rutas canonicas post-consolidacion deberian usar `/clubs/:clubId/sections/:sectionId/evidence-folder` — el backend usa `/club-sections/:sectionId` que es un patron diferente
- Admin es solo lectura — no permite administrar templates, asignar carpetas ni revisar progreso de miembros
- No hay flujo de validacion/aprobacion institucional de carpetas completadas
- No hay endpoint para listar el progreso de todos los miembros de una seccion (vista de consejero/director)

## Prioridad y siguiente accion

- **Alta**: Alinear rutas del EvidenceFolderController con el patron canonico `/clubs/:clubId/sections/:sectionId/evidence-folder` y documentar los 4 endpoints
- **Media**: Resolver el desacople entre las rutas que consume la app y las que expone el backend
- **Siguiente accion concreta**: Auditar si la app puede conectar correctamente con `/club-sections/:sectionId/evidence-folder` o si necesita migration de rutas, y documentar los endpoints faltantes en ENDPOINTS-LIVE-REFERENCE.md
