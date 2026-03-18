# Certificaciones de Guias Mayores
Estado: PARCIAL

## Que existe (verificado contra codigo)
- **Backend**: CertificationsModule — 7 endpoints (list certifications, detail, enroll, list user certifications, progress read, progress update, abandon). Controller: CertificationsController. Guards: JwtAuthGuard, PermissionsGuard.
- **Admin**: 1 page read-only (certifications list via ModuleListPage). Consume GET /certifications/certifications. Sin gestion de progreso ni inscripciones.
- **App**: No implementado. No hay screens de certificaciones.
- **DB**: certifications, certification_modules, certification_sections, users_certifications, certification_module_progress, certification_section_progress

## Que define el canon
- Canon menciona certificaciones como parte del proceso formativo (formacion)
- Las certificaciones de Guias Mayores son un camino estructurado de avance complementario a las clases progresivas

## Gap
- App no tiene screens para certificaciones — backend tiene CRUD completo de progreso
- Admin es solo lectura
- No hay UI en ningun cliente para inscripcion, progreso o evidencias de certificaciones

## Prioridad
- A definir por el desarrollador
