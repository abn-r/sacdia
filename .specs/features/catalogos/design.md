---
title: Catálogos del Sistema
status: implemented
priority: high
---

# Catálogos del Sistema

## Descripción

Endpoints de solo lectura para acceder a los datos de referencia del sistema. Estos catálogos son utilizados por la aplicación móvil y el panel administrativo para poblar dropdowns y formularios.

## Catálogos Disponibles

### 1. Tipos de Club

```
GET /catalogs/club-types
```

Retorna: Aventureros, Conquistadores, Guías Mayores

### 2. Geografía (Jerárquico)

```
GET /catalogs/countries
GET /catalogs/unions?countryId={id}
GET /catalogs/local-fields?unionId={id}
GET /catalogs/districts?localFieldId={id}
GET /catalogs/churches?districtId={id}
```

La estructura jerárquica permite filtros en cascada:

- País → Unión → Campo Local → Distrito → Iglesia

### 3. Roles

```
GET /catalogs/roles?category={GLOBAL|CLUB}
```

- **GLOBAL**: Roles del sistema (super_admin, admin, user)
- **CLUB**: Roles de club (director, subdirector, member, etc.)

### 4. Años Eclesiásticos

```
GET /catalogs/ecclesiastical-years
GET /catalogs/ecclesiastical-years/current
```

El año eclesiástico va de agosto a julio.

### 5. Ideales de Club

```
GET /catalogs/club-ideals?clubTypeId={id}
```

Retorna: Voto, Ley, Himno, Objetivo, etc.

## Respuesta Tipo

```json
{
  "data": [{ "id": 1, "name": "Aventureros", "active": true }],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 3,
    "totalPages": 1,
    "hasNextPage": false,
    "hasPreviousPage": false
  }
}
```

## Archivos Clave

- `src/catalogs/catalogs.module.ts`
- `src/catalogs/catalogs.controller.ts`
- `src/catalogs/catalogs.service.ts`

## Notas

- Todos los endpoints son públicos (no requieren autenticación)
- Los datos están cacheados en el cliente por 1 hora
- Solo se retornan registros con `active: true`

---

**Implementado**: 2026-01-31
**Estado**: ✅ Completado
