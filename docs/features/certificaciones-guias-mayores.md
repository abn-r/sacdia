# Certificaciones de Guias Mayores

**Estado**: PARCIAL

## Descripcion de dominio

Las certificaciones de Guias Mayores son programas formativos avanzados exclusivos para miembros investidos como Guias Mayores. Representan un camino de especializacion complementario a las clases progresivas, enfocado en capacitar lideres para funciones especificas dentro de la organizacion: liderazgo juvenil, instruccion, capellania, administracion, entre otros.

Cada certificacion sigue una estructura jerarquica similar a las clases y carpetas: certificacion -> modulos -> secciones. El progreso se registra por seccion (completada/no completada) y se auto-completa jerarquicamente: al completar todas las secciones de un modulo, el modulo se marca como completo; al completar todos los modulos, la certificacion se marca como completa.

A diferencia de las clases progresivas (determinadas por edad y secuenciales), las certificaciones son electivas y voluntarias. Un Guia Mayor investido elige que certificaciones cursar segun sus intereses y rol en el club. El backend valida la elegibilidad al momento de la inscripcion, rechazando usuarios que no son Guias Mayores investidos.

El modulo backend esta completamente implementado con CRUD de progreso. El admin tiene paginas de gestion y la app tiene screens completos, aunque quedan gaps en reportes y flujos institucionales avanzados.

## Que existe (verificado contra codigo)

### Backend (CertificationsModule)
- **Controlador**: `CertificationsController` — **7 endpoints** (JwtAuthGuard + PermissionsGuard):
  - `GET /certifications/certifications` — listar certificaciones disponibles con paginacion
  - `GET /certifications/certifications/:id` — detalle de certificacion con modulos y secciones
  - `POST /certifications/users/:userId/certifications/enroll` — inscribirse en certificacion (valida que sea Guia Mayor investido)
  - `GET /certifications/users/:userId/certifications` — listar certificaciones del usuario con progreso
  - `GET /certifications/users/:userId/certifications/:certificationId/progress` — progreso detallado por modulos y secciones
  - `PATCH /certifications/users/:userId/certifications/:certificationId/progress` — actualizar progreso de seccion (auto-completa modulo y certificacion)
  - `DELETE /certifications/users/:userId/certifications/:certificationId` — abandonar certificacion (soft delete)
- **Servicio**: `CertificationsService`
- **DTOs**: EnrollCertificationDto, UpdateCertificationProgressDto
- **Permisos**: users:read_detail (lectura), users:update (escritura) con AuthorizationResource owner detection
- **Todos los endpoints documentados** en ENDPOINTS-LIVE-REFERENCE.md y **ALINEADOS** en Reality Matrix

### Admin (sacdia-admin)
- Pagina de listado de certificaciones
- Pagina de detalle con arbol de modulos
- Panel de usuarios inscriptos
- Dialog de progreso con toggle de secciones

### App (sacdia-app)
- **4 screens**: CertificationsListScreen, CertificationDetailScreen, CertificationProgressScreen, MyCertificationsScreen
- Capa de datos completa: entities, models, datasource, repository, providers
- Rutas registradas en GoRouter

### Base de datos
- `certifications` — catalogo de certificaciones
- `certification_modules` — modulos por certificacion
- `certification_sections` — secciones evaluables por modulo
- `users_certifications` — inscripcion usuario-certificacion
- `certification_module_progress` — progreso por modulo
- `certification_section_progress` — progreso por seccion

## Requisitos funcionales

1. Solo Guias Mayores investidos pueden inscribirse en certificaciones (validacion de elegibilidad en enrollment)
2. Un usuario solo puede tener una inscripcion activa por certificacion (409 en duplicado)
3. El progreso se registra por seccion como completa/incompleta
4. Al completar todas las secciones de un modulo, el modulo se auto-completa
5. Al completar todos los modulos, la certificacion se auto-completa
6. La seccion y modulo deben ser validos para la certificacion (400 si son invalidos)
7. El abandono es soft delete — la inscripcion se desactiva pero no se elimina
8. El catalogo de certificaciones debe ser listable con paginacion

## Decisiones de diseno

- **Controlador unico**: A diferencia de honores y clases que separan catalogo y usuario, certificaciones usa un solo controlador con prefijo `/certifications`
- **Patron de rutas compartido**: Las rutas de usuario siguen `/certifications/users/:userId/certifications/...` con el mismo patron de PermissionsGuard + AuthorizationResource
- **Validacion de elegibilidad en enrollment**: El servicio valida que el usuario sea Guia Mayor investido antes de permitir inscripcion (403 si no cumple)
- **Auto-completado jerarquico**: Mismo patron que folders — al actualizar una seccion se evalua completitud de modulo y certificacion
- **Estructura DB espejo**: El schema sigue el mismo patron de clases (certifications -> modules -> sections -> progress) para consistencia

## Gaps y pendientes

- No hay endpoint para subida de archivos/evidencias de certificaciones (a diferencia de honores y clases que si tienen)
- No hay flujo de validacion institucional de certificaciones completadas
- No hay reporte administrativo de certificaciones por club o seccion
- La validacion de "Guia Mayor investido" debe validar contra `enrollments` con investiture_status = 'invested' (users_classes fue archivada)

## Prioridad y siguiente accion

- **Media**: Los gaps restantes son mejoras incrementales; la funcionalidad core esta disponible en admin y app.
- **Siguiente accion concreta**: Evaluar soporte de evidencias para certificaciones (alineando con el patron de honores y clases)
