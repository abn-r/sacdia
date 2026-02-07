# Feature: Sistema de Certificaciones para Guías Mayores

## Feature ID: #21

## Overview
Sistema que permite a Guías Mayores **investidos** cursar certificaciones de especialización mediante inscripción simultánea en múltiples certificaciones sin secuencialidad.

## User Stories

### US-21.1: Inscripción en Certificaciones
**Como** Guía Mayor investido  
**Quiero** inscribirme en múltiples certificaciones simultáneamente  
**Para** desarrollar habilidades específicas de liderazgo y enseñanza

**Criterios de Aceptación**:
- Solo usuarios con `users_classes.investiture = true` para "Guía Mayor" pueden inscribirse
- Puede inscribirse en 1 a 6 certificaciones simultáneamente
- No hay requisito de completar una antes de inscribirse en otra

### US-21.2: Progreso en Certificaciones
**Como** Guía Mayor inscrito en certificaciones  
**Quiero** ver el progreso de todas mis certificaciones activas en un dashboard  
**Para** dar seguimiento a mi avance en cada una

**Criterios de Aceptación**:
- Dashboard muestra todas las certificaciones activas paralelamente
- Cada certificación tiene módulos y apartados como las clases
- Se puede subir evidencias por sección

### US-21.3: Validación de Certificaciones
**Como** consejero/director  
**Quiero** validar requisitos de certificaciones de GMs  
**Para** aprobar su avance de la misma forma que con clases

**Criterios de Aceptación**:
- Flujo de validación idéntico al de clases
- Se puede aprobar/rechazar cada apartado
- Al completar todos los módulos, obtiene reconocimiento

## Technical Requirements

### Database
- Nueva tabla: `certifications`
- Nueva tabla: `certification_modules`  
- Nueva tabla: `certification_sections`
- Nueva tabla: `users_certifications` (sin constraint único por usuario)
- Nueva tabla: `certification_module_progress`
- Nueva tabla: `certification_section_progress`

### Business Rules
1. **Elegibilidad**: Solo GMs investidos
2. **Inscripción múltiple**: Sin límite de certificaciones activas
3. **No secuencialidad**: Se pueden cursar en cualquier orden
4. **Validación**: Requiere aprobación de consejero/director por sección

## Dependencies
- Feature #11: Sistema de clases (reutiliza misma estructura)
- Users con investidura de Guía Mayor

## Success Metrics
- % de GMs investidos inscritos en al menos 1 certificación
- Promedio de certificaciones por GM
- Tasa de completitud de certificaciones
