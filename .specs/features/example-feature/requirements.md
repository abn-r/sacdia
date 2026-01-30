# Requirements - Sistema de Notificaciones

> **Fase**: Requirements  
> **Fecha de Creación**: 2026-01-09  
> **Última Actualización**: 2026-01-09  
> **Estado**: Approved

## Resumen Ejecutivo

Este documento especifica un sistema de notificaciones para mantener a los usuarios informados sobre eventos importantes en la plataforma. Los usuarios podrán recibir notificaciones in-app y por email, con control sobre sus preferencias.

El sistema resolverá el problema actual donde los usuarios pierden información importante porque no tienen forma de ser notificados activamente de eventos relevantes.

## User Stories

### US-1: Recibir Notificación de Evento

**Como** usuario registrado  
**Quiero** recibir notificaciones cuando ocurran eventos importantes  
**Para** no perderme información relevante

#### Criterios de Aceptación (EARS)

1. **WHEN** se crea una nueva orden para el usuario  
   **THE SYSTEM SHALL** crear una notificación in-app visible en el header

2. **WHEN** se crea una nueva orden para el usuario  
   **THE SYSTEM SHALL** enviar un email de notificación en menos de 1 minuto

3. **WHEN** el usuario tiene notificaciones no leídas  
   **THE SYSTEM SHALL** mostrar un badge con el contador en el icono de notificaciones

4. **WHEN** el usuario hace click en una notificación  
   **THE SYSTEM SHALL** marcarla como leída automáticamente

5. **WHEN** el usuario hace click en una notificación  
   **THE SYSTEM SHALL** navegar al recurso relacionado (ej: la orden)

---

### US-2: Gestionar Preferencias

**Como** usuario  
**Quiero** controlar qué notificaciones recibo  
**Para** no ser molestado con información irrelevante

#### Criterios de Aceptación (EARS)

1. **WHEN** el usuario accede a configuración de notificaciones  
   **THE SYSTEM SHALL** mostrar una lista de tipos de notificaciones disponibles

2. **WHEN** el usuario desactiva notificaciones de email para un tipo  
   **THE SYSTEM SHALL** continuar enviando notificaciones in-app pero no emails

3. **WHEN** el usuario guarda preferencias  
   **THE SYSTEM SHALL** aplicar los cambios inmediatamente para nuevas notificaciones

---

### US-3: Ver Historial

**Como** usuario  
**Quiero** ver todas mis notificaciones pasadas  
**Para** revisar información que olvidé

#### Criterios de Aceptación (EARS)

1. **WHEN** el usuario abre el panel de notificaciones  
   **THE SYSTEM SHALL** mostrar las últimas 50 notificaciones ordenadas por fecha descendente

2. **WHEN** hay más de 50 notificaciones  
   **THE SYSTEM SHALL** implementar paginación para cargar más

3. **WHEN** el usuario filtra por "no leídas"  
   **THE SYSTEM SHALL** mostrar solo notificaciones con estado unread

---

## Requisitos No Funcionales

### Performance
- **THE SYSTEM SHALL** crear notificaciones in-app en menos de 5 segundos del evento
- **THE SYSTEM SHALL** enviar emails en menos de 1 minuto del evento
- **THE SYSTEM SHALL** soportar 1000 notificaciones por minuto

### Usabilidad
- **THE SYSTEM SHALL** mostrar notificaciones de forma no intrusiva
- **THE SYSTEM SHALL** usar iconos y colores para diferentes tipos de notificaciones

---

## Fuera de Alcance (v1)

- [ ] Push notifications móviles
- [ ] Notificaciones por SMS
- [ ] Notificaciones agrupadas/digest
- [ ] Notificaciones en tiempo real (WebSockets) - se usará polling

---

## Criterios de Éxito

### Métricas
- 80% de usuarios activan al menos un tipo de notificación
- <2% de usuarios desactivan todas las notificaciones
- 90% de emails entregan exitosamente

---

## Tipos de Notificaciones (v1)

1. **Nueva Orden**: Cuando se crea una orden
2. **Actualización de Orden**: Cambios en estado
3. **Nuevo Mensaje**: Mensaje de admin o soporte

---

## Control de Cambios

| Fecha | Versión | Cambios |
|-------|---------|---------|
| 2026-01-09 | 1.0 | Creación inicial - aprobado |
