# Carpetas de Evidencias (legacy)

**Estado**: DEPRECATED — retirado antes de producción

## Decisión vigente

El flujo legacy de carpetas (`FoldersModule`, rutas `/folders/*`, `EvidenceFolderController` bajo `/club-sections/:sectionId/evidence-folder` y el apartado admin `/dashboard/folders`) fue retirado para evitar dos modelos paralelos.

El flujo canónico es **Carpeta Anual de Evidencias** (`annual-folders`):

- Carga/lectura por sección: `evidence_folders:read` / `evidence_folders:update`.
- Creación de carpeta desde club: `POST /club-sections/:sectionId/annual-folder`, resolviendo la inscripción anual aprobada (`club_enrollments.status = active`) sin pedir `club_enrollment_id` al usuario.
- Envío de sección: `POST /annual-folders/:folderId/sections/:sectionId/submit`.
- Evaluación de sección: `POST /annual-folders/:folderId/sections/:sectionId/evaluate`; la sección debe estar enviada y la carpeta puede seguir `open` mientras otras secciones continúan su carga.
- Envío de carpeta completa: `POST /annual-folders/:folderId/submit` con `annual_folders:submit`, limitado a dirección/secretaría del club.
- Supervisión/evaluación institucional: `annual_folders:evaluate`.
- UX de panel/app: no se pide `folder_id` ni `club_enrollment_id` manual al usuario. El club carga o crea su carpeta por sección activa (`GET/POST /club-sections/:sectionId/annual-folder`) y la supervisión usa la cola legible (`GET /annual-folders/evaluation/queue`).

## Alcance de permisos vigente

- Carga/lectura de evidencias: `secretary`, `secretary-treasurer`, `deputy-director`, `director`.
- Envío de carpeta completa: `secretary`, `secretary-treasurer`, `director`.
- Lectura/supervisión institucional: `assistant-lf`, `director-lf` y roles superiores por herencia de permisos institucionales.
- `member`, `counselor`, `instructor` y `treasurer` no cargan ni leen la carpeta anual por permisos de evidencia.

## Nota de datos

Las tablas legacy (`folders*`, `folder_assignments`, `folders_section_records`) pueden existir todavía por compatibilidad histórica y porque algunas consultas antiguas de scoring/rankings aún las referencian como fallback técnico. No exponen flujo funcional nuevo; cualquier evolución debe integrarse al módulo `annual-folders`.

Ver contrato operativo en `docs/features/annual-folders-scoring.md` y endpoints vigentes en `docs/api/ENDPOINTS-LIVE-REFERENCE.md`.
