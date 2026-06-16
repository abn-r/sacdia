# Validacion de Evidencias

**Estado**: IMPLEMENTADO

## Descripcion de dominio

La validacion de evidencias es el proceso mediante el cual un coordinador o administrador revisa las evidencias subidas por miembros para el cumplimiento de requisitos de clases progresivas y honores. Las carpetas anuales no pasan por esta cola generica: mantienen carga de archivos e imagenes y se revisan dentro del flujo propio de Annual Folders.

Las evidencias pueden ser archivos (fotos, PDFs, documentos) que demuestran la realizacion de actividades, competencias evaluadas o logros alcanzados. El flujo de validacion incluye: (1) el miembro o consejero sube evidencias, (2) las evidencias quedan pendientes de revision, (3) el validador revisa el archivo y aprueba o rechaza con motivo, (4) se genera un audit trail de cada accion de validacion.

## Que existe (verificado contra codigo)

### Backend (EvidenceReviewModule)
- **Modulo nuevo**: `src/evidence-review/`
- **7 endpoints**:
  - `GET /api/v1/evidence-review/pending` — Listar evidencias pendientes (filters: `type=class|honor`, page, limit)
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
- **Vista unificada**: Evidencias de clases y honores en una sola interfaz
- **Filtros por tipo**: Selector para filtrar por tipo de evidencia
- **File gallery preview**: Visualizacion de archivos con preview de imagenes y PDFs
- **URLs firmadas**: El detalle de revision devuelve URLs firmadas de corta duracion para archivos privados de clases y honores; el admin no debe consumir rutas R2 privadas crudas.
- **Visor PDF local**: Los PDFs se abren mediante `/api/evidence-review/pdf`, una ruta del admin que valida la sesion, recupera el detalle en backend, selecciona el archivo por `fileId` y transmite el PDF como `inline` para evitar iframes rotos con URLs privadas/cross-origin.
- **Zoom de imagenes**: El visor de imagenes agranda el tamano real del elemento, no usa `transform: scale`, para que el contenedor scrollable permita recorrer toda la imagen ampliada.
- **Modo de trabajo de honores**: En evidencias de honores, el panel muestra si la especialidad fue trabajada dentro de la app (`IN_APP`) o fuera de la app (`EXTERNAL`) antes de revisar archivos/requisitos.
- **Bulk operations**: Seleccion multiple para aprobar/rechazar en lote (mismo tipo)
- **Audit trail**: Timeline de acciones de validacion por evidencia

### Base de datos
- **Nuevo campo**: `folders_section_records.rejection_reason` — VARCHAR para motivos de rechazo
- **Nuevo FK**: `evidence_files.user_honor_id` — FK a `users_honors(user_honor_id)` para evidencias de honores
- Reutiliza tablas existentes: `class_section_progress`, `users_honors`, `evidence_files`

## Requisitos funcionales

1. Coordinadores deben poder ver evidencias pendientes de clases y honores en una vista unificada
2. Las evidencias deben poder filtrarse por tipo (`class` u `honor`)
3. Cada evidencia debe poder visualizarse con preview de archivos antes de validar
4. La aprobacion requiere solo confirmacion; el rechazo requiere motivo obligatorio
5. Debe soportar operaciones masivas de aprobacion/rechazo (mismo tipo de evidencia)
6. Cada accion de validacion debe quedar registrada en un audit trail
7. El historial de validacion debe ser consultable por evidencia

## Decisiones de diseno

- **Modulo independiente**: EvidenceReviewModule separado de Annual Folders y HonorsModule para mantener responsabilidad unica
- **Vista unificada limitada**: Un solo punto de entrada para clases y honores evita mezclar la cola generica con el scoring anual de carpetas
- **Bulk por tipo**: Las operaciones masivas solo permiten evidencias del mismo tipo para evitar inconsistencias de flujo
- **File gallery**: Preview inline evita la necesidad de descargar archivos para validar
- **Nombre visible normalizado**: Las evidencias subidas por usuarios se muestran como `Evidencia 01`, `Evidencia 02`, etc. El contexto (usuario, fecha, sección/requisito) queda como metadata; las claves técnicas de storage siguen siendo únicas y no se usan como nombre visible.
- **No exponer storage privado**: La cola de revision debe resolver archivos mediante URLs firmadas generadas por backend. Mostrar `file_url` crudo de R2 en `<img>`, `<iframe>` o links rompe previews y expone errores XML de autorización.
- **Proxy PDF autenticado**: El iframe del admin no carga directamente URLs R2; usa una ruta server-side del admin para transmitir el PDF con `Content-Disposition: inline` luego de validar token y pertenencia del archivo al detalle solicitado.

## Gaps y pendientes

- Sin metricas de tiempos promedio de validacion por tipo de evidencia
- Sin notificaciones push al miembro cuando su evidencia es validada/rechazada
- Sin exportacion de reportes de validacion

## Estado de implementacion

- Backend: EvidenceReviewModule con 7 endpoints
- Admin: Pagina dedicada con gallery preview, bulk ops y audit trail
