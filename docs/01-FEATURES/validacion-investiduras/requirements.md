# Feature: Proceso de Validación de Investiduras

## Feature ID: #23

## Overview
Workflow completo para validar investiduras al final del año eclesiástico, incluyendo envío por director, revisión por coordinador, y bloqueo de edición durante validación.

## User Stories

### US-23.1: Envío a Validación
**Como** director del club  
**Quiero** enviar miembros que completaron requisitos a validación  
**Para** que el coordinador los revise antes de la ceremonia de investidura

**Criterios de Aceptación**:
- Solo se puede enviar si todos los módulos están completos
- Al enviar, `enrollments.locked_for_validation = true`
- Estado cambia a `SUBMITTED_FOR_VALIDATION`
- Se registra en `investiture_validation_history`

### US-23.2: Revisión por Coordinador
**Como** coordinador de campo local  
**Quiero** revisar y aprobar/rechazar solicitudes de investidura  
**Para** mantener estándares de calidad antes de investir

**Criterios de Aceptación**:
- Lista de miembros enviados a validación
- Puede ver todos los requisitos completados
- Puede APROBAR (estado → `APPROVED`) o RECHAZAR con comentarios
- Si rechaza, requisitos se desbloquean para corrección

### US-23.3: Corrección y Reenvío
**Como** miembro rechazado en validación  
**Quiero** ver los comentarios del coordinador y corregir  
**Para** volver a enviar mi solicitud

**Criterios de Aceptación**:
- Puede ver `rejection_reason` del coordinador
- Requisitos desbloqueados permiten edición
- Director puede reenviar a validación después de correcciones

## Technical Requirements

### Database
- Modificar `enrollments` (10 nuevos campos)
- Nuevo enum: `investiture_status_enum`
- Nuevo enum: `investiture_action_enum`
- Nueva tabla: `investiture_validation_history`
- Nueva tabla: `investiture_config`

### Business Rules
1. **Bloqueo automático**: Al enviar a validación, no se puede editar
2. **Fechas configurables**: Por campo local y año eclesiástico
3. **Auditoría completa**: Todo cambio se registra en history
4. **Un solo validador**: coordinator de campo local

## Success Metrics
- % de solicitudes aprobadas en primera validación
- Tiempo promedio de revisión
- % de investiduras realizadas a tiempo
