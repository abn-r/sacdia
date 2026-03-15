# Clases Progresivas
Estado: IMPLEMENTADO

## Que existe (verificado contra codigo)
- **Backend**: ClassesModule — 7 endpoints (list classes, class by ID, class modules, user enrollments, enroll, progress read/update). Controllers: ClassesController, UserClassesController. Service: ClassesService.
- **Admin**: 1 page read-only (classes list via ModuleListPage). Consume GET /classes y GET /catalogs/club-types. Sin CRUD de clases ni gestion de progreso.
- **App**: 6 screens (ClassesListView, ClassDetailView, ClassDetailWithProgressView, ClassModulesView, SectionDetailView, RequirementDetailView). Consume 8 endpoints incluyendo listado, detalle, modulos, inscripcion, progreso y subida/borrado de archivos de evidencia.
- **DB**: classes, class_modules, class_sections, class_module_progress, class_section_progress, users_classes, enrollments

## Que define el canon
- Proceso formativo: camino estructurado de avance institucional del miembro dentro de una seccion (dominio-sacdia.md)
- Regla de edad y etapa: la clase se determina por la edad al inicio del ano eclesiastico y no cambia durante ese ciclo
- Decision 9: la verdad formativa se separa entre ciclo anual (enrollments) y trayectoria consolidada (users_classes)
- Investidura como acto de reconocimiento asociado al cierre exitoso de una etapa

## Gap
- La frontera de autoridad entre enrollments y users_classes no esta implementada de forma consistente (Decision 9 advierte cautela)
- App consume endpoints de archivos por seccion (POST/DELETE files) que no aparecen en backend audit
- Admin es solo lectura — no permite gestionar inscripciones ni progreso
- /home/grouped-class tiene classId hardcodeado a 1

## Prioridad
- A definir por el desarrollador
