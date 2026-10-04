# Canon and Documentation Update Plan

**Estado**: ACTIVE  
**Fecha**: 2026-04-12  
**Ámbito**: canon, baseline documental y documentación operativa subordinada

## Objetivo

Ejecutar una actualización ordenada del canon y la documentación activa de SACDIA para reducir drift documental, restaurar rutas de lectura confiables y consolidar una baseline técnica y de datos consistente con la realidad vigente del proyecto.

## Contexto / problema actual

Las auditorías previas confirman que el problema principal no es la falta de documentación sino el drift entre documentos activos que hoy compiten por describir el estado vigente.

Los puntos de mayor fricción identificados son:

- rutas legacy todavía visibles en documentos activos, especialmente referencias mezcladas entre taxonomías viejas y actuales;
- taxonomía editorial inconsistente entre canon, operación, trabajo e historia;
- `docs/canon/completion-matrix.md` desactualizada respecto del estado real esperado para guiar priorización;
- divergencia entre `docs/database/schema.prisma` y `sacdia-backend/prisma/schema.prisma`, lo que debilita la regla actual de fuente de verdad estructural;
- baseline técnica global desactualizada en `docs/steering/tech.md`;
- drift funcional alto en `auth`, `communications`, `inventario`, `gestion-seguros`, `validacion-investiduras` y posiblemente `finanzas`;
- features nuevas o subdocumentadas con cobertura insuficiente: `achievements/gamification`, `monthly-reports`, `membership-requests`, `member-of-month`, `weekly-records`.

## Principios de actualización

1. El canon debe conservar solo verdad vigente, estructural y normativa; no debe absorber detalle táctico innecesario.
2. Los documentos operativos pueden detallar runtime, integración o estructura, pero no redefinir semántica ni precedencia.
3. Los planes viven en `docs/plans/` y no deben convertirse en fuente de verdad permanente.
4. Todo documento histórico o reemplazado debe quedar marcado como `HISTORICAL` o `DEPRECATED`, con referencia explícita al documento activo que lo reemplaza.
5. Si dos documentos activos chocan, la actualización debe resolver la contradicción o dejar arbitraje explícito; no se sintetiza por intuición.
6. La actualización debe priorizar rutas de lectura y autoridad documental antes de expandir cobertura de dominios individuales.
7. Ninguna fase debe inventar comportamiento de producto: solo consolidar, aclarar o reconciliar evidencia ya validada.

## Backlog por fases

### P0 - Gobernanza y rutas de lectura

**Objetivo**: eliminar ambigüedad de navegación y precedencia antes de tocar baseline técnica o dominios.

**Tareas**:

- revisar y corregir rutas legacy todavía expuestas en documentos activos;
- normalizar la taxonomía editorial activa (`ACTIVE`, `DRAFT`, `HISTORICAL`, `DEPRECATED`) y su uso consistente;
- alinear `README.md`, `CLAUDE.md`, `AGENTS.md`, `docs/README.md` y `docs/canon/source-of-truth.md` para que apunten a la misma estructura vigente;
- verificar que `docs/canon/gobernanza-canon.md` siga siendo el documento rector de disciplina documental y actualizarlo solo si hace falta aclarar reglas ya aprobadas.

**Archivos objetivo**:

- `README.md`
- `CLAUDE.md`
- `AGENTS.md`
- `docs/README.md`
- `docs/canon/source-of-truth.md`
- `docs/canon/gobernanza-canon.md`

**Dependencias**:

- ninguna; esta fase abre el resto del trabajo.

**Criterio de cierre**:

- no quedan rutas legacy conflictivas en los documentos de entrada principales;
- la precedencia documental queda expresada de forma consistente en todos los entry points;
- la taxonomía editorial queda explícita y sin estados paralelos.

### P1 - Baseline técnica y fuente de verdad de datos

**Objetivo**: restablecer una baseline técnica confiable y resolver la debilidad actual en la autoridad del schema.

**Tareas**:

- actualizar `docs/steering/tech.md` para reflejar solo baseline vigente y remover o degradar contenido aspiracional/obsoleto que hoy compite con el runtime real;
- arbitrar la divergencia entre `docs/database/schema.prisma` y `sacdia-backend/prisma/schema.prisma`;
- una vez definida la fuente estructural efectiva, regenerar o reconciliar `docs/database/schema.prisma`, `docs/database/README.md` y `docs/database/SCHEMA-REFERENCE.md`;
- ajustar `docs/canon/source-of-truth.md` y `docs/README.md` si cambia la formulación operativa de la fuente de verdad de datos;
- actualizar `docs/canon/completion-matrix.md` para que deje de transmitir cierre artificial en baseline/documentación de datos.

**Archivos objetivo**:

- `docs/steering/tech.md`
- `docs/database/schema.prisma`
- `sacdia-backend/prisma/schema.prisma`
- `docs/database/README.md`
- `docs/database/SCHEMA-REFERENCE.md`
- `docs/canon/source-of-truth.md`
- `docs/canon/completion-matrix.md`
- `docs/README.md`

**Dependencias**:

- P0 cerrado, porque la definición de autoridad documental debe estar estable antes de corregir baseline.

**Criterio de cierre**:

- existe una única formulación clara de la fuente de verdad estructural de datos;
- `tech.md` describe baseline vigente sin mezclar alternativas no adoptadas como si fueran estado actual;
- completion matrix refleja el estado real de baseline y datos sin sobredeclarar completitud.

### P2 - Dominios con drift alto

**Objetivo**: reducir primero el drift documental con mayor impacto operativo para agentes, onboarding y decisiones funcionales.

**Tareas**:

- auditar y actualizar la documentación activa de `auth`;
- auditar y actualizar la documentación activa de `communications`;
- auditar y actualizar la documentación activa de `inventario`;
- auditar y actualizar la documentación activa de `gestion-seguros`;
- auditar y actualizar la documentación activa de `validacion-investiduras`;
- evaluar `finanzas` y tratarla como dominio P2 si la auditoría confirma drift material.

**Archivos objetivo**:

- `docs/features/auth/*`
- `docs/features/communications/*`
- `docs/features/inventario/*`
- `docs/features/gestion-seguros/*`
- `docs/features/validacion-investiduras/*`
- `docs/features/finanzas/*`
- documentos canónicos u operativos relacionados cuando un dominio dependa de ellos para quedar consistente

**Dependencias**:

- P1 cerrado, para que los dominios ya trabajen sobre baseline técnica y de datos estabilizada.

**Criterio de cierre**:

- cada dominio priorizado tiene documentación activa consistente con la autoridad vigente;
- se elimina contradicción material entre canon, features, runtime API y datos para esos dominios;
- cualquier incertidumbre pendiente queda registrada como arbitraje explícito, no escondida.

### P3 - Features nuevas o subdocumentadas

**Objetivo**: cubrir vacíos documentales que hoy dejan superficie funcional sin encuadre suficiente dentro del sistema.

**Tareas**:

- decidir el encuadre documental correcto para `achievements/gamification`;
- documentar o completar cobertura de `monthly-reports`;
- documentar o completar cobertura de `membership-requests`;
- documentar o completar cobertura de `member-of-month`;
- documentar o completar cobertura de `weekly-records`;
- asegurar que cada feature nueva quede ubicada en la taxonomía correcta y no nazca como documento huérfano.

**Archivos objetivo**:

- `docs/features/README.md`
- nuevos o existentes documentos en `docs/features/`
- índices o mapas de navegación afectados por las nuevas entradas

**Dependencias**:

- P0 y P1 cerrados;
- P2 avanzado o cerrado para no mezclar alta cobertura nueva con drift crítico todavía abierto.

**Criterio de cierre**:

- cada feature listada tiene ubicación documental explícita y cobertura mínima suficiente para no quedar fuera del mapa activo;
- `docs/features/README.md` refleja el inventario real de dominios y features activas;
- no se crean documentos nuevos sin rol claro dentro de canon, operación, trabajo o historia.

### P4 - Cierre, control y sostenimiento

**Objetivo**: dejar mecanismos mínimos para que el drift no reaparezca inmediatamente después de la actualización.

**Tareas**:

- consolidar una nueva lectura ejecutiva del estado documental tras P0-P3;
- actualizar `docs/canon/completion-matrix.md` como tablero de cobertura real, no como snapshot optimista;
- definir checklist operativo de mantenimiento documental para cambios futuros;
- identificar documentos activos que deban pasar a `HISTORICAL` o `DEPRECATED` con reemplazo explícito;
- dejar una secuencia recomendada de revisión periódica para baseline, datos y dominios críticos.

**Archivos objetivo**:

- `docs/canon/completion-matrix.md`
- `docs/README.md`
- `docs/canon/gobernanza-canon.md`
- `docs/history/README.md`
- documentos activos que requieran degradación o archivado controlado

**Dependencias**:

- P0-P3 cerrados o con estado suficientemente estable.

**Criterio de cierre**:

- existe un cierre ejecutivo verificable del trabajo;
- los documentos reemplazados quedan degradados correctamente y enlazados;
- queda definida una disciplina mínima para mantener consistencia después de esta ola.

## Riesgos

- la corrección de rutas y autoridad puede destapar contradicciones más profundas entre canon y documentación operativa, aumentando alcance real de P1 y P2;
- resolver el drift del schema puede requerir arbitraje explícito porque la regla documental actual declara una fuente de verdad que hoy no coincide con el backend;
- `completion-matrix.md` puede estar sobredeclarando completitud y su corrección puede afectar percepción de avance;
- si P3 se adelanta antes de cerrar P0-P1, se amplifica cobertura sobre una base todavía inestable;
- mover o degradar documentos sin reemplazo visible puede romper onboarding y volver a dispersar autoridad.

## Quick wins

- corregir entry points con rutas legacy en `README.md`, `docs/README.md`, `CLAUDE.md` y `AGENTS.md`;
- actualizar el estado y propósito de `docs/canon/completion-matrix.md` para que vuelva a ser útil como tablero de trabajo;
- agregar una nota explícita de arbitraje en la capa de datos mientras se resuelve la divergencia entre ambos `schema.prisma`;
- limpiar `docs/steering/tech.md` removiendo o degradando contenido que hoy se presenta como baseline vigente sin serlo.

## Recomendación de ejecución por olas

**Ola 1 - Control de autoridad**

- ejecutar P0 completo;
- cerrar quick wins de rutas, precedencia y taxonomía antes de tocar dominios.

**Ola 2 - Baseline confiable**

- ejecutar P1 completo;
- no abrir actualización masiva de features hasta resolver la autoridad técnica y de datos.

**Ola 3 - Reducción de drift crítico**

- ejecutar P2 por lotes de 2-3 dominios, empezando por `auth` y `communications`, luego `inventario`, `gestion-seguros`, `validacion-investiduras`, y `finanzas` si el drift se confirma.

**Ola 4 - Cobertura faltante**

- ejecutar P3 solo cuando la base ya no cambie de forma estructural;
- crear o completar documentación nueva con taxonomía consistente desde el inicio.

**Ola 5 - Cierre y guardrails**

- ejecutar P4 para consolidar matrix, degradar material reemplazado y dejar checklist de mantenimiento.

## Resultado esperado

Al finalizar estas olas, SACDIA debe volver a tener una ruta de lectura coherente, una baseline técnica y de datos confiable, dominios críticos sin contradicción material y un mecanismo mínimo para que el canon no vuelva a desalinearse con la documentación operativa.
