# Feature: Gestión de Seguros

## Feature ID: #16

## Overview
Sistema para controlar que miembros cuenten con seguro activo antes de participar en actividades de riesgo y camporees.

## User Stories

### US-16.1: Registro de Seguro
**Como** director del club  
**Quiero** registrar el seguro de un miembro  
**Para** tener control de quién está cubierto

**Criterios de Aceptación**:
- Se registra tipo, póliza, proveedor, fechas, monto
- Tipos: GENERAL_ACTIVITIES, CAMPOREE, HIGH_RISK
- Se puede tener múltiples seguros activos (diferentes tipos)

### US-16.2: Validación de Seguro en Registro a Actividades
**Como** sistema  
**Quiero** verificar seguro activo antes de permitir registro a camporee  
**Para** garantizar que todos estén protegidos

**Criterios de Aceptación**:
- Al registrar a camporee, valida `member_insurances` activo
- Bloquea registro si no tiene seguro o está vencido
- Muestra alerta si seguro vence antes de fecha del camporee

### US-16.3: Alertas de Vencimiento
**Como** director del club  
**Quiero** recibir alertas de seguros próximos a vencer  
**Para** renovarlos a tiempo

**Criterios de Aceptación**:
- Dashboard muestra seguros que vencen en 30 días
- Notificación 15 días antes de vencimiento
- Lista de miembros sin seguro activo

## Technical Requirements

### Database
- Nueva tabla: `member_insurances`
- Nuevo enum: `insurance_type_enum`
- Modificar: `attending_members_camporees` (2 campos)

### Business Rules
1. **Validación obligatoria**: Para camporees y actividades riesgo
2. **Múltiples seguros**: Usuario puede tener varios tipos activos
3. **Verificación automática**: Sistema valida fechas automáticamente

## Success Metrics
- % de miembros con seguro activo
- Número de registros bloqueados por falta de seguro
- Tasa de renovación antes de vencimiento
