# Carpetas de Evidencias (Folders)
Estado: IMPLEMENTADO

## Que existe (verificado contra codigo)
- **Backend**: FoldersModule — 7 endpoints (list templates, template detail, enroll, list user folders, progress, update section progress, abandon). Controller: FoldersController. Guards: JwtAuthGuard, PermissionsGuard.
- **Admin**: 1 page read-only (folders list via ModuleListPage). Consume GET /folders/folders.
- **App**: 2 screens (EvidenceFolderView, EvidenceSectionDetailView). Consume endpoints de evidence folder via /clubs/:clubId/sections/:sectionId/evidence-folder (endpoints FANTASMA — no en backend audit). La app usa rutas diferentes a las del FoldersModule del backend.
- **DB**: folders, folders_modules, folders_sections, folders_modules_records, folders_section_records, folder_assignments

## Que define el canon
- Canon menciona carpetas de evidencias como parte del proceso formativo (formacion)
- Las carpetas son un camino estructurado de evidencia institucional

## Gap
- App consume endpoints de evidence-folder que son FANTASMA (no existen en backend audit) — pendiente de implementacion
- Las URLs deben usar el patron canonico `/clubs/:clubId/sections/:sectionId/evidence-folder` (consolidación club_sections 2026-03-17)
- El backend tiene FoldersModule con rutas /folders/*, pero la app consume rutas diferentes — desacople a resolver en implementacion
- Admin es solo lectura

## Prioridad
- Media — evidence-folder endpoints pendientes de implementacion con naming canonico `/clubs/:clubId/sections/:sectionId/evidence-folder`
