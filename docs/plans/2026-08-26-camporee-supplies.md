# Insumos de camporee — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Que una sección inscrita planifique insumos por horario de entrega, pague un folio principal y ajuste días no congelados con cargos/devoluciones hijas, sin mezclar mercancía ni inscripción.

**Architecture:** Bounded context nuevo `camporee-supplies`. UX dentro del camporee. Un plan por sección. Líneas `(date, slot, product, qty)`. Freeze configurable (default 21:00 TZ del evento). Pago: PRINCIPAL + CHARGE/REFUND hijos. Entrega parcial a la sección.

**Tech Stack:** NestJS 11, Prisma 7, PostgreSQL, Flutter/Riverpod, Next.js admin, pnpm.

**Estado:** IN PROGRESS (backend + app + admin tab + docs en rama; sin Neon)  
**Fecha:** 2026-08-26  
**Diseño:** `docs/plans/2026-08-26-camporee-supplies-design.md`  
**Rama:** `feat/camporee-supplies` desde `origin/development`  
**Restricción:** No Nest/Next/Flutter builds. Tests focalizados. Sin Co-Authored-By.

## Tasks

1. Schema + freeze puro (TDD) + error codes + i18n  
2. Permisos + actor (emisores: director, secretary, secretary-treasurer)  
3. Config: cutoff, slots, productos (bloqueo de precio si hay SUBMITTED)  
4. Plan DRAFT upsert + submit PRINCIPAL + adjust con hijos  
5. Entrega parcial + reportes cocina/caja  
6. Read model Pagos pendientes  
7. App: cronograma + plan en detalle de camporee  
8. Admin: tab Insumos en ficha de camporee  
9. Docs canónicas + feature stub  

Folio: `INS{yyyy}{####}` por LF y año (contador propio, no el de PED).
