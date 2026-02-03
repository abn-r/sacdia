---
title: Actividades de Club
status: implemented
priority: important
---

# Actividades de Club

## Descripción

Sistema para gestionar las actividades de club con registro de asistencia y geolocalización.

## Endpoints

```http
# Por club (autenticado)
GET    /clubs/:clubId/activities         # Listar actividades (paginado)
POST   /clubs/:clubId/activities         # Crear actividad

# Actividad individual
GET    /activities/:activityId           # Detalle
PATCH  /activities/:activityId           # Actualizar
DELETE /activities/:activityId           # Desactivar

# Asistencia
POST   /activities/:activityId/attendance  # Registrar asistencia
GET    /activities/:activityId/attendance  # Ver asistentes
```

## Archivos

- `src/activities/activities.module.ts`
- `src/activities/activities.controller.ts`
- `src/activities/activities.service.ts`
- `src/activities/dto/activities.dto.ts`

---

**Implementado**: 2026-01-31
**Estado**: ✅ Completado
