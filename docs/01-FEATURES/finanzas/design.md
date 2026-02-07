---
title: Finanzas de Club
status: implemented
priority: important
---

# Finanzas de Club

## Descripción

Sistema de control financiero por club con categorías de ingresos/egresos y reportes.

## Endpoints

```http
# Categorías
GET    /finances/categories              # Listar categorías

# Por club (autenticado)
GET    /clubs/:clubId/finances           # Listar movimientos (paginado)
GET    /clubs/:clubId/finances/summary   # Resumen financiero
POST   /clubs/:clubId/finances           # Crear movimiento

# Movimiento individual
GET    /finances/:financeId              # Detalle
PATCH  /finances/:financeId              # Actualizar
DELETE /finances/:financeId              # Desactivar
```

## Permisos

La creación de movimientos financieros requiere rol de:

- Director
- Subdirector
- Tesorero

## Archivos

- `src/finances/finances.module.ts`
- `src/finances/finances.controller.ts`
- `src/finances/finances.service.ts`
- `src/finances/dto/finances.dto.ts`

---

**Implementado**: 2026-01-31
**Estado**: ✅ Completado
