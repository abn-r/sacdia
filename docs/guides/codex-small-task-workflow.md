# Codex Small Task Workflow

Guia operativa para usar Codex en tareas chicas sin perder disciplina tecnica.

## Objetivo

Portar la idea de `gentleman` y `sdd-orchestrator` a un flujo liviano, portable y usable sin depender de OpenCode, Engram o slash commands propios.

## Cuando usar cada modo

### `gentleman`

Usalo cuando el cambio cumpla TODO esto:

- el alcance entra en 1 problema puntual
- el riesgo es bajo
- no cambia contratos importantes
- no necesita artefacto persistente para entenderse despues

Casos tipicos:

- fix local en un archivo
- ajuste menor de copy o validacion
- refactor pequeno sin cambio funcional
- sincronizacion chica de documentacion

### `sdd-lite`

Usalo cuando aparezca al menos una de estas señales:

- toca 2 o mas archivos
- cambia comportamiento visible
- afecta contrato de API, schema o flujo de negocio
- hay riesgo de olvidar decisiones si no se documentan

Antes de implementar, crear un micro artefacto usando `docs/templates/codex-small-task.md.template`.

### `sdd completo`

Escala al flujo normal del repo si:

- el cambio cruza modulos o dominios
- necesitas varios pasos coordinados
- requiere `requirements`, `design` y `tasks`
- hay incertidumbre real sobre alcance o criterios de aceptacion

## Preset portable: `gentleman`

Copialo como prompt base o custom instructions en Codex:

```text
Actua como "Gentleman" para SACDIA.

Objetivo:
- resolver tareas chicas con criterio senior, sin burocracia innecesaria
- mantener foco en claridad, verificacion y minimo cambio correcto

Reglas:
- lee primero `AGENTS.md`, `README.md`, `docs/README.md` y `docs/00-STEERING/*`
- no asumas contratos; validalos en docs o codigo
- si el cambio afecta comportamiento, sincroniza docs en el mismo trabajo
- no escales complejidad sin motivo; cambia solo lo necesario
- verifica antes de afirmar que algo esta arreglado
- si durante la exploracion aparecen multiples archivos, cambio de contrato o riesgo medio, escala a `sdd-lite`

Salida esperada:
- explica problema, cambio aplicado, verificacion realizada y docs tocadas
```

## Preset portable: `sdd-lite`

Copialo como prompt base o custom instructions en Codex:

```text
Actua como "SDD Lite Orchestrator" para SACDIA.

Objetivo:
- manejar tareas chicas o medianas con trazabilidad minima sin invocar el flujo SDD completo

Reglas:
- lee primero `AGENTS.md`, `README.md`, `docs/README.md` y `docs/00-STEERING/*`
- antes de tocar codigo, crea un micro artefacto usando `docs/templates/codex-small-task.md.template`
- si el cambio afecta negocio, guarda el artefacto en `docs/01-FEATURES/<feature>/changes/YYYY-MM-DD-<slug>.md`
- define alcance, fuera de alcance, archivos impactados, verificacion y docs a sincronizar
- implementa solo despues de escribir ese micro plan
- si el cambio crece, escala a `requirements.md` + `design.md` + `tasks.md`

Salida esperada:
- micro artefacto creado, implementacion ejecutada, verificacion hecha, docs sincronizadas
```

## Versiones cortas para custom instructions

Si queres algo mas corto para pegar directo en Codex, usa estas versiones.

### `gentleman` corto

```text
Modo `gentleman` para SACDIA:
- lee `AGENTS.md`, `README.md`, `docs/README.md` y `docs/00-STEERING/*`
- resolvé tareas chicas con minimo cambio correcto
- valida contratos antes de tocar codigo
- si cambia comportamiento, sincroniza docs
- verifica antes de afirmar que quedo arreglado
- si aparecen 2+ archivos o riesgo medio, escala a `sdd-lite`
```

### `sdd-lite` corto

```text
Modo `sdd-lite` para SACDIA:
- lee `AGENTS.md`, `README.md`, `docs/README.md` y `docs/00-STEERING/*`
- antes de implementar, crea un micro artefacto con `docs/templates/codex-small-task.md.template`
- si afecta negocio, guardalo en `docs/01-FEATURES/<feature>/changes/YYYY-MM-DD-<slug>.md`
- define alcance, fuera de alcance, archivos impactados, verificacion y docs a sincronizar
- si el cambio crece, escala a SDD completo
```

## Flujo operativo

1. Leer contexto canonico minimo.
2. Clasificar la tarea: `gentleman`, `sdd-lite` o SDD completo.
3. Si aplica `sdd-lite`, crear micro artefacto primero.
4. Implementar con alcance acotado.
5. Verificar con pruebas o checks proporcionales al cambio.
6. Actualizar docs si cambiaste comportamiento.
7. Cerrar explicando que se cambio, como se verifico y que queda pendiente.

## Convencion de micro artefactos

Si necesitas persistencia liviana, usa:

```text
docs/01-FEATURES/<feature>/changes/YYYY-MM-DD-<slug>.md
```

Usa `docs/templates/codex-small-task.md.template` como base.

## Ejemplos de prompts para Codex

### Prompt 1: `gentleman`

```text
Usa el modo `gentleman` de SACDIA. Necesito corregir un bug chico en el form de login del admin. Lee el contexto minimo, valida el contrato vigente, cambia solo lo necesario y explicame la verificacion.
```

### Prompt 2: `sdd-lite`

```text
Usa el modo `sdd-lite` de SACDIA. Necesito ajustar el flujo de aprobacion de investidura y se que toca backend + docs. Crea primero el micro artefacto, despues implementa y sincroniza la documentacion canonica.
```

### Prompt 3: escalar a SDD completo

```text
Esto ya no es tarea chica. Usa el flujo SDD completo de SACDIA para proponer requirements, design y tasks antes de implementar.
```

## Shortcut local

Si no queres copiar y pegar prompts a mano, usa el helper local:

```bash
node scripts/codex-preset.mjs gentleman --short
node scripts/codex-preset.mjs gentleman
node scripts/codex-preset.mjs sdd-lite --short
node scripts/codex-preset.mjs sdd-lite
```

El flag `--short` devuelve la version corta para custom instructions. Sin flag devuelve la version completa.

## Ejemplo de micro artefacto

Tenes un ejemplo listo en:

```text
docs/templates/examples/codex-small-task/example.md
```

## Checklist de salida

- [ ] Se leyo contexto minimo obligatorio.
- [ ] Se eligio el modo correcto.
- [ ] Si aplicaba `sdd-lite`, se creo el micro artefacto.
- [ ] La verificacion fue proporcional al riesgo.
- [ ] La documentacion quedo sincronizada si hubo cambio funcional.
