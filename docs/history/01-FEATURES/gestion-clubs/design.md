---
title: Gestión de Clubs
status: implemented
priority: critical
---

# Gestión de Clubs

## Descripción

El módulo de clubs permite gestionar la estructura organizacional de los clubes SACDIA, incluyendo sus instancias (Aventureros, Conquistadores, Guías Mayores), asignación de roles y membresías.

## Requisitos Implementados

### 1. Estructura de Clubs

- [x] CRUD completo de clubs
- [x] Asociación con campos locales, distritos e iglesias
- [x] Coordenadas geográficas opcionales

### 2. Instancias de Club

Cada club puede tener hasta 3 instancias:

- **Aventureros**: Para niños de 6-9 años
- **Conquistadores**: Para jóvenes de 10-15 años
- **Guías Mayores**: Para jóvenes y adultos de 16+ años

Cada instancia incluye:

- Meta de almas
- Cuota de membresía
- Días y horarios de reunión (JSON flexible)
- Estado activo/inactivo

### 3. Roles y Permisos

Los usuarios pueden tener roles específicos en cada instancia:

- Director
- Subdirector
- Secretario
- Tesorero
- Consejero
- Instructor
- Capitán
- Miembro

#### Permisos por Rol

| Acción               | Director | Subdirector | Secretario | Otros |
| -------------------- | -------- | ----------- | ---------- | ----- |
| Actualizar club      | ✅       | ✅          | ❌         | ❌    |
| Desactivar club      | ✅       | ❌          | ❌         | ❌    |
| Crear instancia      | ✅       | ✅          | ❌         | ❌    |
| Actualizar instancia | ✅       | ✅          | ✅         | ❌    |
| Asignar roles        | ✅       | ✅          | ✅         | ❌    |
| Ver miembros         | ✅       | ✅          | ✅         | ✅    |

### 4. Año Eclesiástico

Las asignaciones de roles están vinculadas al año eclesiástico, permitiendo:

- Histórico de membresías
- Renovación anual de cargos
- Reportes por período

## Endpoints

```
GET    /clubs                      # Listar clubs (paginado)
GET    /clubs/:clubId              # Obtener club
POST   /clubs                      # Crear club
PATCH  /clubs/:clubId              # Actualizar club
DELETE /clubs/:clubId              # Desactivar club

GET    /clubs/:clubId/instances/:type        # Obtener instancia
POST   /clubs/:clubId/instances              # Crear instancia
PATCH  /clubs/:clubId/instances/:type/:id    # Actualizar instancia

GET    /clubs/:clubId/instances/:type/:id/members  # Listar miembros
POST   /clubs/:clubId/instances/:type/:id/roles    # Asignar rol

PATCH  /club-roles/:assignmentId   # Actualizar asignación
DELETE /club-roles/:assignmentId   # Remover rol
```

## Archivos Clave

- `src/clubs/clubs.module.ts`
- `src/clubs/clubs.controller.ts`
- `src/clubs/clubs.service.ts`
- `src/clubs/dto/`
- `src/common/guards/club-roles.guard.ts`
- `src/common/decorators/club-roles.decorator.ts`

## Dependencias

- `PrismaModule`
- `JwtAuthGuard`
- `ClubRolesGuard`

---

**Implementado**: 2026-01-31
**Estado**: ✅ Completado
