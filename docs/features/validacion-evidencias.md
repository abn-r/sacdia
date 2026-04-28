# Validacion de Evidencias

**Estado**: IMPLEMENTADO

## Descripcion de dominio

La validacion de evidencias es el proceso mediante el cual un coordinador o administrador revisa las evidencias subidas por miembros para el cumplimiento de requisitos de clases progresivas, honores y carpetas anuales. Este modulo proporciona una vista unificada de todas las evidencias pendientes de revision, independientemente de su tipo.

Las evidencias pueden ser archivos (fotos, PDFs, documentos) que demuestran la realizacion de actividades, competencias evaluadas o logros alcanzados. El flujo de validacion incluye: (1) el miembro o consejero sube evidencias, (2) las evidencias quedan pendientes de revision, (3) el validador revisa el archivo y aprueba o rechaza con motivo, (4) se genera un audit trail de cada accion de validacion.

## Que existe (verificado contra codigo)

### Backend (EvidenceReviewModule)
- **Modulo nuevo**: `src/evidence-review/`
- **7 endpoints**:
  - `GET /api/v1/evidence-review/pending` — Listar evidencias pendientes (filters: type, page, limit)
  - `GET /api/v1/evidence-review/:type/:id` — Detalle de evidencia con archivos
  - `POST /api/v1/evidence-review/:type/:id/approve` — Aprobar evidencia
  - `POST /api/v1/evidence-review/:type/:id/reject` — Rechazar evidencia (reason required)
  - `POST /api/v1/evidence-review/bulk-approve` — Aprobacion masiva (mismo tipo)
  - `POST /api/v1/evidence-review/bulk-reject` — Rechazo masivo (mismo tipo)
  - `GET /api/v1/evidence-review/:type/:id/history` — Historial de validacion
- Guards: JwtAuthGuard, GlobalRolesGuard (admin, coordinator)

### Admin (sacdia-admin)
- **Pagina dedicada**: `/dashboard/evidence-review`
- **Componentes**: `src/components/evidence-review/`
- **Vista unificada**: Todos los tipos de evidencias (carpetas, clases, honores) en una sola interfaz
- **Filtros por tipo**: Selector para filtrar por tipo de evidencia
- **File gallery preview**: Visualizacion de archivos con preview de imagenes y PDFs
- **Bulk operations**: Seleccion multiple para aprobar/rechazar en lote (mismo tipo)
- **Audit trail**: Timeline de acciones de validacion por evidencia

### Base de datos
- **Nuevo campo**: `folders_section_records.rejection_reason` — VARCHAR para motivos de rechazo
- **Nuevo FK**: `evidence_files.user_honor_id` — FK a `users_honors(user_honor_id)` para evidencias de honores
- Reutiliza tablas existentes: `folders_section_records`, `evidence_files`

## Requisitos funcionales

1. Coordinadores deben poder ver todas las evidencias pendientes de validacion en una vista unificada
2. Las evidencias deben poder filtrarse por tipo (carpeta, clase, honor)
3. Cada evidencia debe poder visualizarse con preview de archivos antes de validar
4. La aprobacion requiere solo confirmacion; el rechazo requiere motivo obligatorio
5. Debe soportar operaciones masivas de aprobacion/rechazo (mismo tipo de evidencia)
6. Cada accion de validacion debe quedar registrada en un audit trail
7. El historial de validacion debe ser consultable por evidencia

## Decisiones de diseno

- **Modulo independiente**: EvidenceReviewModule separado de FoldersModule y HonorsModule para mantener responsabilidad unica
- **Vista unificada**: Un solo punto de entrada para todas las evidencias evita que el validador navegue entre modulos
- **Bulk por tipo**: Las operaciones masivas solo permiten evidencias del mismo tipo para evitar inconsistencias de flujo
- **File gallery**: Preview inline evita la necesidad de descargar archivos para validar

## Gaps y pendientes

- Sin metricas de tiempos promedio de validacion por tipo de evidencia
- Sin notificaciones push al miembro cuando su evidencia es validada/rechazada
- Sin exportacion de reportes de validacion

## Estado de implementacion

- Backend: EvidenceReviewModule con 7 endpoints
- Admin: Pagina dedicada con gallery preview, bulk ops y audit trail
