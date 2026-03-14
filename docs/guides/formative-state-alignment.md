# Formative State Alignment

**Estado**: ACTIVE

Lectura previa obligatoria:

- `docs/canon/dominio-sacdia.md`
- `docs/canon/runtime-sacdia.md`
- `docs/canon/decisiones-clave.md`

## Propósito

Este documento define el plan técnico de transición para alinear el estado formativo del sistema con el canon vigente.

Es un documento subordinado al canon. No redefine el dominio ni el runtime; traduce una decisión canónica a una secuencia de implementación segura.

## Problema

El runtime actual usa dos estructuras con semántica parcialmente superpuesta:

- `enrollments`
- `users_classes`

La intención de negocio distingue dos niveles válidos:

- `enrollments` para el ciclo anual operativo de una clase dentro de un año eclesiástico;
- `users_classes` para la trayectoria consolidada por clase a lo largo de la vida institucional del miembro.

El desalineamiento actual aparece porque distintas partes del sistema siguen tratando ambas estructuras como si fueran fuente primaria del mismo problema.

## Modelo objetivo

- `enrollments` es la fuente de verdad del ciclo anual operativo;
- `users_classes` es la fuente de verdad de la trayectoria consolidada por clase;
- la proyección va desde resultados consolidados de `enrollments` hacia `users_classes`;
- `users_classes` no debe seguir funcionando como punto de entrada operativo para onboarding, progreso o validación del ciclo actual.

## Puntos actuales de desalineación

- post-registro escribe verdad formativa en `users_classes`;
- el módulo de clases usa `enrollments` como verdad operativa;
- admin sigue leyendo `users_classes` como si fuera estado actual;
- certificaciones ya usa `enrollments` en parte de su lógica;
- las tablas de progreso todavía no están claramente acopladas al ciclo anual de `enrollments`.

## Estrategia por fases

### Fase 1: separar lecturas sin romper clientes

Crear un read model explícito con dos salidas:

- `current_operational_enrollment`
- `trajectory_classes`

Objetivo:

- dejar de devolver un genérico ambiguo como `classes`;
- hacer visible el modelo correcto antes de cambiar escrituras;
- permitir compatibilidad transicional en admin y mobile.

### Fase 2: mover la escritura operativa al ciclo anual

Cambiar post-registro para que cree o actualice el `enrollment` del año eclesiástico activo y deje de escribir verdad operativa primaria en `users_classes`.

Objetivo:

- alinear onboarding con la fuente de verdad anual;
- mantener idempotencia del flujo actual;
- no proyectar todavía a trayectoria en el momento de inscripción inicial.

### Fase 3: hacer el progreso dependiente del enrollment

Acoplar progreso de módulos y secciones al `enrollment` correspondiente.

Objetivo:

- evitar que intentos de años distintos compartan accidentalmente el mismo progreso;
- asegurar que el ciclo anual tenga una semántica cerrada de principio a fin.

### Fase 4: mover lecturas históricas a trayectoria consolidada

Refactorizar consumidores históricos para que lean `users_classes` como proyección consolidada y no como reflejo directo del ciclo actual.

Objetivo:

- que admin y certificaciones distingan con claridad entre estado actual y trayectoria histórica;
- reducir ambigüedad en UI y contratos.

### Fase 5: retirar semántica legacy

Eliminar el uso de `users_classes.current_class` como verdad operativa y retirar cualquier lectura que siga tratando trayectoria consolidada como si fuera inscripción anual vigente.

Objetivo:

- cerrar la frontera entre ciclo operativo y trayectoria;
- dejar un runtime consistente con el canon.

## Cambios backend requeridos

- separar respuestas entre estado operativo actual y trayectoria consolidada;
- cambiar post-registro para escribir `enrollments` en lugar de `users_classes` como verdad primaria del ciclo actual;
- volver enrollment-aware las lecturas y escrituras de progreso;
- proyectar resultados consolidados desde `enrollments` hacia `users_classes`;
- dejar compatibilidad temporal solo donde sea estrictamente necesario.

## Cambios admin requeridos

- dejar de interpretar `classes` como campo único ambiguo;
- mostrar por separado la clase actual del ciclo y la trayectoria histórica;
- dejar de asumir que `users_classes` representa la verdad operativa presente.

## Cambios mobile requeridos

- tratar la selección de clase del post-registro como creación de ciclo anual y no como escritura directa de historial;
- distinguir modelos de catálogo de clase y modelos de enrollment;
- consumir estado actual desde enrollment y no desde trayectoria consolidada.

## Estrategia de migración y sincronización

- crear enrollments faltantes para usuarios cuyo estado operativo solo exista hoy en `users_classes`;
- reconstruir o proyectar `users_classes` desde outcomes consolidados de `enrollments` cuando haya datos suficientes;
- reportar casos ambiguos para revisión manual en vez de inventar equivalencias silenciosas;
- usar proyección explícita desde eventos de consolidación, no escrituras ad hoc desde múltiples módulos.

## Riesgos y tradeoffs

- cambiar escrituras antes de separar lecturas puede romper clientes;
- mantener compatibilidad demasiado tiempo prolonga ambigüedad;
- parte del historial viejo puede requerir reconstrucción manual por falta de contexto anual;
- si certificaciones migra demasiado temprano, puede bloquear casos legítimos si la trayectoria consolidada no quedó bien proyectada.

## Primer slice recomendado

El primer slice recomendado es separar el read path antes de tocar escrituras.

Concretamente:

1. backend expone `current_operational_enrollment` y `trajectory_classes`;
2. admin y mobile dejan de leer una sola bolsa ambigua de `classes`;
3. documentación API deja explícita esta frontera;
4. recién después se mueve post-registro a `enrollments`.

## Criterio de cierre

Esta transición puede considerarse cerrada cuando:

- el ciclo anual operativo viva de forma consistente en `enrollments`;
- la trayectoria consolidada viva de forma consistente en `users_classes`;
- admin, mobile y backend lean el mismo modelo semántico;
- `docs/canon/runtime-sacdia.md` pueda dejar de tratar este punto como una brecha abierta.
