# Idea to Spec Guide

Guía compacta para convertir una idea en una especificación ejecutable.

## Paso 1: Claridad de problema

Define en 5 líneas:
- problema actual
- usuario afectado
- resultado esperado
- límites del alcance
- métricas de éxito

## Paso 2: Requirements

Escribe requisitos con formato EARS:
- `WHEN ... THE SYSTEM SHALL ...`
- incluye casos felices, errores y bordes.

## Paso 3: Design

Documenta:
- arquitectura propuesta
- contratos API (request/response/errores)
- impacto en DB (tablas, índices, migración)
- decisiones y tradeoffs

## Paso 4: Tasks

Divide en tareas pequeñas con:
- criterio de terminado
- pruebas por tarea
- dependencias explícitas

## Entregables mínimos por iniciativa

- `requirements` (qué)
- `design` (cómo)
- `tasks` (orden de ejecución)

## Regla de oro

Si la implementación cambia el comportamiento, actualiza la documentación en el mismo trabajo.

