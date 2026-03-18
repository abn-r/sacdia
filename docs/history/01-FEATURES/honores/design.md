---
title: Honores/Especialidades
status: implemented
priority: critical
---

# Honores/Especialidades

## Descripción

Sistema para gestionar el catálogo de especialidades y el progreso de los usuarios en cada honor.

## Endpoints

```http
# Catálogo (público)
GET    /honors                           # Listar honores (paginado)
GET    /honors/:honorId                  # Detalle del honor
GET    /honors/categories                # Categorías de honores

# Progreso de usuario (autenticado)
GET    /users/:userId/honors             # Honores del usuario
GET    /users/:userId/honors/stats       # Estadísticas
POST   /users/:userId/honors/:honorId    # Iniciar honor
PATCH  /users/:userId/honors/:honorId    # Actualizar progreso
DELETE /users/:userId/honors/:honorId    # Abandonar honor
```

## Archivos

- `src/honors/honors.module.ts`
- `src/honors/honors.controller.ts`
- `src/honors/honors.service.ts`
- `src/honors/dto/honors.dto.ts`

---

**Implementado**: 2026-01-31
**Estado**: ✅ Completado
